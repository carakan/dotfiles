# fzf.zsh — all fzf configuration, sourced by zshrc.
# Includes: keybindings (fzf --zsh), theme (FZF_COLORS spliced into
# FZF_DEFAULT_OPTS — fzf has no FZF_COLORS variable of its own), default opts,
# completion, Ctrl-T / Alt-C / Ctrl-R. tmux-fzf inherits FZF_DEFAULT_OPTS via
# tmux's update-environment, so this file styles the plugin's pickers too.

# clipboard used by fzf bindings (platform-agnostic name)
case "$(uname -s)" in
  Darwin) _DOTFILES_CLIP="pbcopy" ;;
  Linux)  command -v wl-copy >/dev/null && _DOTFILES_CLIP="wl-copy" || _DOTFILES_CLIP="xclip -selection clipboard" ;;
esac

# load fzf
source <(fzf --zsh)

# fzf theme — harmonized with the kitty palette (bg #1e1e1e, fg #b8bcb9).
# Typography: bold = interactive, italic = informational, dim = tertiary.
export FZF_COLORS="dark,\
fg:-1,\
hl:italic:#ecb90f,\
bg:-1,\
list-fg:-1,\
list-bg:-1,\
preview-fg:#b8bcb9,\
preview-bg:#202020,\
input-bg:-1,\
header-bg:-1,\
footer-bg:-1,\
selected-fg:#fcffb8,\
selected-bg:#3a3e44,\
hl:bold:#ecb90f,\
selected-hl:bold:#ecb90f,\
fg+:#FEF9E1,\
bg+:#292c31,\
hl+:bold:#f2bd09,\
gutter:#232529,\
alt-bg:#232529,\
alt-gutter:#242629,\
query:bold:-1,\
ghost:italic:dim:#6e7681,\
disabled:dim:#6e7681,\
info:dim:#6e7681,\
prompt:bold:#568ea3,\
pointer:bold:#2cc55d,\
marker:bold:#855b8d,\
spinner:#568ea3,\
border:#6e7681,\
list-border:#6e7681,\
input-border:#6e7681,\
header-border:#6e7681,\
footer-border:#6e7681,\
preview-border:dim:#6e7681,\
separator:dim:#6e7681,\
gap-line:dim:#6e7681,\
scrollbar:#6e7681,\
preview-scrollbar:dim:#6e7681,\
label:italic:#b8bcb9,\
list-label:italic:#b8bcb9,\
input-label:italic:#b8bcb9,\
header-label:italic:#ad9c8b,\
footer-label:italic:#b8bcb9,\
preview-label:italic:#ad9c8b,\
header:italic:#ad9c8b,\
footer:dim:#6e7681,\
nth:italic,\
nomatch:dim:strip"

# Modern fzf full style. Requires fzf >= 0.75.0 (Homebrew: 0.75.0) for: raw
# mode + toggle-raw + nomatch strip (0.66), word wrap (0.68), --id-nth and
# walker follow (0.71), inline footer border (0.72), next preview position +
# every(N)/FZF_IDLE_TIME (0.73), non-modal floating pane (0.74), mode-2026
# sync rendering + separator auto-suppression (0.74.1), info-command actions
# (0.75). All flags are literal; only vars expand.
#
# 0.75.0 (2026-11-07) changed two semantics this file relies on:
#   * transform-nth / transform-with-nth no longer split their output at the
#     pipe character. Only change-nth / change-with-nth rotate through
#     pipe-separated values. Nothing here uses the nth family, so no action
#     is needed.
#   * change-nth / change-with-nth now apply the value AFTER the current one
#     in the list and skip values equal to the current one.
#
# The label transforms below are the bg- variants on purpose: the plain
# transform-* actions run SYNCHRONOUSLY, so fzf freezes the UI while the
# command runs (man page: can make the interface sluggish). The list label
# is recomputed on every result change and the preview label on every cursor
# move, so the synchronous form costs a shell spawn per keystroke. The bg-
# form runs the same command in the background and applies the result when it
# arrives; fzf tracks a background version counter and discards results from
# superseded runs, so a stale label cannot overwrite a fresh one.
#
# The list label fires on result-final, not result. result also fires on
# every INTERMEDIATE snapshot while the input stream is still loading, so a
# slow producer (a large `rg --files`, a tmux list over many panes) spawns
# the transform dozens of times for a label nobody can read yet - it is
# overwritten before it is ever displayed. result-final fires once, when the
# stream closes, and then on every query change: same live label, one spawn.
#
# The transform bodies use POSIX test ([ ... ]) rather than bash's [[ ... ]].
# fzf runs bind commands through $SHELL -c, and $SHELL is whatever the
# session has - dash on a plain /bin/sh, which has no [[ operator and fails
# with "[[: not found", taking the whole label down with it. The [ ... ] form
# works under bash, zsh and dash alike. $FZF_QUERY is quoted because it can
# contain spaces, which would otherwise split into extra test operands.
#
# The new {change,transform,bg-transform}-info-command actions in 0.75.0 are
# NOT wired into the default opts, on purpose: --info-command runs
# synchronously and blocks the UI until completion (man page), so a permanent
# one would re-introduce the per-keystroke stall the bg- variants just
# removed. They are exposed as an opt-in toggle instead (alt-i / alt-u below):
# alt-i adds the cursor position to the info line, alt-u restores the plain
# counter. That way the new feature is available without taxing every
# keystroke.
#
# alt-u passes an EMPTY value, which resets --info-command to unset and
# restores fzf's native counter. The alternative - change-info-command with
# "echo $FZF_INFO" - looks equivalent and is not: the info command stays
# installed, so fzf keeps running a shell to produce the counter on every
# single keystroke. Empty means fzf renders the counter itself, with no
# spawn at all.
export FZF_DEFAULT_OPTS='--ansi
  --cycle
  --style full
  --layout=reverse
  --info=inline-right
  --border=rounded
  --padding=1,2
  --border-label=" fzf "
  --border-label-pos=3
  --input-label=" Input "
  --prompt="❯ "
  --pointer="▶"
  --marker="✓"
  --gutter=" "
  --gutter-raw=" "
  --filepath-word
  --preview-window=right:60%:wrap-word
  --footer=" C-a select-all · C-/ preview · C-d/u scroll · C-s sort · Alt-w wrap · Alt-i pos "
  --footer-border
  --bind="result-final:bg-transform-list-label:
      if [ -z \"$FZF_QUERY\" ]; then
        echo \" $FZF_MATCH_COUNT items \"
      else
        echo \" $FZF_MATCH_COUNT matches for [ $FZF_QUERY ] \"
      fi
      "
  --bind="focus:bg-transform-preview-label:[ -n {} ] && printf \" Previewing [ %s ] \" {}"
  --bind="ctrl-d:half-page-down"
  --bind="ctrl-u:half-page-up"
  --bind="ctrl-b:page-up"
  --bind="ctrl-f:page-down"
  --bind="pgup:preview-half-page-up"
  --bind="pgdn:preview-half-page-down"
  --bind="shift-up:preview-up"
  --bind="shift-down:preview-down"
  --bind="alt-up:preview-half-page-up"
  --bind="alt-down:preview-half-page-down"
  --bind="ctrl-/:change-preview-window(next:wrap-word|down:50%:wrap-word|hidden|)"
  --bind="ctrl-a:toggle-all"
  --bind="ctrl-s:toggle-sort"
  --bind="alt-w:toggle-wrap-word"
  --bind="alt-r:toggle-raw"
  --bind="alt-i:change-info-command:printf \" %s | pos %s \" \"$FZF_INFO\" \"$FZF_POS\""
  --bind="alt-u:change-info-command:"
  '"--color='$FZF_COLORS' --history='$HOME/.local/state/fzf'"

# Keep the tmux server in sync with this file. The tmux-fzf pickers run in the
# server's environment as run-shell jobs, which read the SESSION environment —
# so a session-level entry (or its absence after an update-environment removal)
# masks the global one. Push to the global environment AND every session, from
# the very file that defines the variable: no ordering dependency, and nothing
# strips it afterwards (nothing else manages it).
if [ -n "$TMUX" ]; then
  tmux set-environment -g FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS"
  tmux list-sessions -F '#S' 2>/dev/null | while IFS= read -r s; do
    tmux set-environment -t "$s" FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS"
  done
fi
# tmux note (live server 3.8, verified 2026-11-08; corrected 2026-11-20):
# --border and --popup must NOT be combined. The earlier note here claimed
# the explicit --border kept --popup as the classic modal popup - that is
# wrong for fzf 0.75: with both set, fzf exits immediately with no UI and
# no message (verified 2026-11-20: `FZF_DEFAULT_OPTS="--border=rounded
# --popup=center,60%,60%" fzf` exits 0 and draws nothing; either option
# alone is fine). Every picker died that way - Ctrl-T, Ctrl-R, Alt-C and the
# tmux-fzf plugin's pickers - because they all inherit this variable.
# --popup is the one that goes: it selects the 0.74 non-modal floating pane,
# which on tmux 3.7.x unzooms a zoomed window when opened over one (0.74.5
# fixed it for tmux 3.8+; tmux 3.7b crashes outright), and this config is
# shared with the Linux box whose tmux may still be 3.7. Without --popup
# fzf is the classic full-screen modal picker, with the rounded border and
# the labels above - correct on every tmux version. To get the centered
# floating picker back instead, drop --border and keep --popup.
#
# Check the option set after any fzf upgrade: fzf reports a bad option on
# stderr, but a fatal combination can exit silently, and the pickers are the
# only place it shows up. packages/fzf/check-fzf.sh is the repo's checker
# for this (it parses each option set with --filter).

# File walker (Ctrl-T source)
export FZF_DEFAULT_COMMAND="rg --files --no-ignore-vcs --hidden --follow --ignore-file $HOME/.ignore"
export BAT_CONFIG_PATH="$HOME/.bat.conf"

# Completion (tab-completion in shell)
export FZF_COMPLETION_OPTS="--preview-window=border-none --preview '(bat {} || cat {} || tree -C {}) 2> /dev/null | head -200'"
export FZF_COMPLETION_PATH_OPTS="--walker=file,dir,hidden,follow"
export FZF_COMPLETION_DIR_OPTS="--walker=dir,hidden,follow"
# FZF_COMPLETION_TRIGGER removed: '**' is the completion-script default.

# Ctrl-T: file picker. Multi-select + file-type header + named labels.
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--multi
  --keep-right
  --border-label=' Files '
  --preview-window='right:60%:wrap-word'
  --preview '(bat {} || cat {} || tree -C {}) 2> /dev/null | head -200'
  --bind='focus:+bg-transform-header:file --brief {} 2>/dev/null || echo \"No file selected\"'"

# Alt-C: directory jumper (tree preview)
export FZF_ALT_C_OPTS="--walker=dir,hidden,follow
  --border-label=' Dirs '
  --preview-window='right:60%:nowrap'
  --preview '(eza --icons=always --color=always --tree --level=2 {} 2>/dev/null || tree -C {} 2>/dev/null || ls -la {} 2>/dev/null) | head -200'"

# Ctrl-R: history. Wrapped preview, copy, open-in-vim, delete-aware footer.
# --gap (0.70+) spaces multi-line entries apart; gap-line color is in FZF_COLORS.
export FZF_CTRL_R_OPTS="--wrap=word
  --no-sort
  --gap=1
  --gap-line='┈'
  --border-label=' History '
  --preview 'echo {2..} | bat --color=always --plain --language=sh'
  --preview-window='up:30%:nowrap'
  --bind='ctrl-/:toggle-preview'
  --bind='ctrl-y:execute-silent(echo -n {2..} | ${_DOTFILES_CLIP})+abort'
  --bind='ctrl-v:execute(echo {2..} | nvim -R --clean - > /dev/tty)'
  --bind='ctrl-t:track+clear-query'
  --footer=' Enter: run · C-y: copy · C-v: view · C-/: preview · C-t: jump to latest '"
