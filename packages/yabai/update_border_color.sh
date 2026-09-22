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
# yabairc values.)
#
# Triggered by yabai signals: window_created, window_destroyed,
# window_focused, space_changed.

# Count real occupancy: the space query also lists hidden windows macOS
# keeps around (invisible helpers, cached windows), so a raw .windows count
# never reaches 1. is-visible is the real test; floating windows excluded.
n=$(yabai -m query --windows --space \
    | jq '[.[] | select(."is-visible" == true and ."is-floating" == false)] | length')

if [ "$n" -eq 1 ]; then
    borders inactive_color=0x00000000 active_color=0x00000000
else
    borders inactive_color=0x00000000 active_color=0xffcccccc
fi
