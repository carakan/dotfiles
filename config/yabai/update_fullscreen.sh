#!/usr/bin/env bash
# update_fullscreen.sh — auto fullscreen look when only 1 window in a space.
#
# When a space has exactly 1 window, removes padding/gap and hides borders so
# the window fills the screen like native fullscreen. When a second window
# appears, restores padding/gap and borders.
#
# Triggered by yabai signals: window_created, window_destroyed, window_moved,
# window_resized, space_changed.

# Get the number of windows in the current space
n=$(yabai -m query --spaces --space | jq '.windows | length')
space_index=$(yabai -m query --spaces --space | jq '.index')

# Store default padding/gap values so we can restore them
DEFAULT_PADDING=2
DEFAULT_GAP=2

if [ "$n" -eq 1 ]; then
    # Single window: fullscreen look
    yabai -m space "${space_index}" --padding abs:0:0:0:0
    yabai -m space "${space_index}" --gap abs:0
    borders active_color=0x00000000
else
    # Multiple windows: restore padding/gap and borders
    yabai -m space "${space_index}" --padding "abs:${DEFAULT_PADDING}:${DEFAULT_PADDING}:${DEFAULT_PADDING}:${DEFAULT_PADDING}"
    yabai -m space "${space_index}" --gap "abs:${DEFAULT_GAP}"
    borders active_color=0xffcccccc
fi
