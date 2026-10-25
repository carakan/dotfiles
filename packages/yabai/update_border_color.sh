#!/usr/bin/env bash
# update_border_color.sh — border color follows the space's real occupancy.
#
# Exactly 1 visible managed window -> border hidden (transparent)
# Otherwise                        -> gray border on the focused window
#
# Border changes are pure `borders` IPC: window geometry is never touched,
# so there is no resize and no kitty/tmux redraw flicker. (An earlier
# version also stripped padding/gap on space entry for a fullscreen look —
# that resize was the flicker source; padding/gap now stay at the global
# yabairc values.) `borders` here is Homebrew's borders(1), not yabai.
#
# Triggered by yabai signals: window_created, window_destroyed,
# window_focused, space_changed.

# yabai runs this script from inside its own signal handler, so neither IPC
# call is guaranteed to return: at startup a burst of window_created signals
# arrives while yabai is still applying rules, and both `yabai -m query` and
# the `borders` client then block (idle copies of this script survived for
# hours on Oct 21). Bound every call; a dropped update is harmless because
# the next signal reapplies it.
if command -v gtimeout >/dev/null 2>&1; then
    ipc() { gtimeout 3 "$@"; }
else
    ipc() { "$@"; }
fi

# Count real occupancy: the space query also lists hidden windows macOS
# keeps around (invisible helpers, cached windows), so a raw .windows count
# never reaches 1. is-visible is the real test; floating windows excluded.
n=$(ipc yabai -m query --windows --space \
    | jq '[.[] | select(."is-visible" == true and ."is-floating" == false)] | length')

if [ -z "$n" ]; then
    exit 0
fi

if [ "$n" -eq 1 ]; then
    ipc borders inactive_color=0x00000000 active_color=0x00000000
else
    ipc borders inactive_color=0x00000000 active_color=0xffcccccc
fi