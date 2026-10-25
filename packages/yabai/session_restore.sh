#!/bin/sh
# session_restore.sh — auto-load the saved yabai workspace session at login.
#
# Launched by com.carakan.yabai-session.plist (RunAtLoad). Waits for the yabai
# socket and for the post-login app flock to stop growing, then applies the
# session saved with `yabai -m space --save-session` (skhd: ctrl+alt-s).
#
# Saves are manual-only (no automatic snapshots): the session file is whatever
# you last saved; re-save after curating to update the login baseline.

SESSION="$HOME/.local/state/yabai/session.json"
LOG="$HOME/.local/state/yabai/restore.log"
# LaunchAgents get a bare PATH (/usr/bin:/bin) — brew binaries live in /usr/local/bin
PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }
notify() { osascript -e "display notification \"$1\" with title \"yabai session\"" 2>/dev/null; }

log "--- session_restore start (pid $$)"

# 1. Wait for the yabai socket. At login the machine is still bringing apps
#    back, so allow 5 minutes (was 120s, which expired on every login in
#    Oct 18-21 because yabai itself had not been started yet).
#    After 20s of nothing, nudge launchd: the yabai agent lives in
#    ~/Library/LaunchAgents, but a stale `disabled` flag (persisted in
#    /var/db/com.apple.xpc.launchd/disabled.$UID.plist) or an earlier
#    bootout can stop launchd from loading it at login. Re-enable and start
#    it ourselves instead of leaving the user with no window manager.
i=0
healed=""
until yabai -m query --spaces >/dev/null 2>&1; do
    i=$((i + 1))
    if [ "$i" -eq 10 ] && [ -z "$healed" ]; then
        healed=yes
        log "no yabai socket after 20s - re-enabling and starting com.asmvik.yabai"
        launchctl enable "gui/$(id -u)/com.asmvik.yabai" 2>/dev/null
        if ! launchctl kickstart "gui/$(id -u)/com.asmvik.yabai" 2>/dev/null; then
            log "job not loaded, bootstrapping from ~/Library/LaunchAgents"
            launchctl bootstrap "gui/$(id -u)" \
                "$HOME/Library/LaunchAgents/com.asmvik.yabai.plist" 2>&1 | sed 's/^/  bootstrap: /' >> "$LOG"
        fi
    fi
    if [ "$i" -ge 150 ]; then
        log "yabai socket never appeared after $((i * 2))s, aborting"
        log "hint: yabai is started by com.asmvik.yabai.plist - check"
        log "      ~/.local/state/yabai/yabai.err.log and: launchctl"
        log "      print gui/\$(id -u)/com.asmvik.yabai"
        exit 1
    fi
    sleep 2
done
log "yabai reachable after $((i * 2))s"

# 2. Wait until the post-login window count stops growing (2 stable polls,
#    max 180s) so apps relaunched by macOS have arrived and rules placed them.
prev=-1
stable=0
i=0
while [ "$i" -lt 60 ]; do
    cur=$(yabai -m query --windows 2>/dev/null | jq 'length' 2>/dev/null)
    cur=${cur:-0}
    if [ "$cur" -eq "$prev" ] && [ "$cur" -gt 0 ]; then
        stable=$((stable + 1))
        if [ "$stable" -ge 2 ]; then
            break
        fi
    else
        stable=0
    fi
    prev=$cur
    i=$((i + 1))
    sleep 3
done
log "window count stable at $prev after ~$((i * 3))s"

# 3. Apply.
if [ ! -f "$SESSION" ]; then
    log "no session file at $SESSION, nothing to restore"
    exit 0
fi
if yabai -m space --load-session "$SESSION" >> "$LOG" 2>&1; then
    log "session restored from $SESSION"
    notify "workspace restored"
else
    log "ERROR: load-session failed"
    notify "restore FAILED - see restore.log"
fi
