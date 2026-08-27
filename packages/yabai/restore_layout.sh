#!/usr/bin/env bash
# restore_layout.sh — restore a saved window layout for the active space.
#
# yabai does not have a built-in "restore layout" command, so this script
# attempts to reconstruct the saved arrangement by warping windows into place
# and adjusting split ratios. It works best when the same apps are still open.
#
# Usage: restore_layout.sh [input_file]
#   input_file defaults to /tmp/yabai_layout_<space_index>.json

set -euo pipefail

SPACE_INDEX=$(yabai -m query --spaces --space | jq '.index')
INPUT_FILE="${1:-/tmp/yabai_layout_${SPACE_INDEX}.json}"

if [ ! -f "$INPUT_FILE" ]; then
    echo "No saved layout found at ${INPUT_FILE}" >&2
    exit 1
fi

# Read the saved layout
saved_count=$(jq '.windows | length' "$INPUT_FILE")
current_count=$(yabai -m query --windows --space | jq 'length')

echo "Restoring layout from ${INPUT_FILE} (saved ${saved_count} windows, current ${current_count})"

# For each saved window, try to find the matching current window and restore
# its frame. This is a best-effort approach since yabai cannot fully restore
# a BSP tree from scratch.
jq -c '.windows[]' "$INPUT_FILE" | while read -r win; do
    app=$(echo "$win" | jq -r '.app')
    frame=$(echo "$win" | jq -r '.frame')
    x=$(echo "$frame" | jq -r '.x')
    y=$(echo "$frame" | jq -r '.y')
    w=$(echo "$frame" | jq -r '.w')
    h=$(echo "$frame" | jq -r '.h')
    is_floating=$(echo "$win" | jq -r '."is-floating"')
    is_sticky=$(echo "$win" | jq -r '."is-sticky"')

    # Find the current window for this app (first match)
    current_id=$(yabai -m query --windows --space | jq -r \
        --arg app "$app" 'map(select(.app == $app))[0].id // empty')

    if [ -n "$current_id" ] && [ "$current_id" != "null" ]; then
        if [ "$is_floating" = "true" ]; then
            # Floating window: set exact frame
            yabai -m window "$current_id" --move "abs:${x}:${y}" 2>/dev/null || true
            yabai -m window "$current_id" --resize "abs:${w}:${h}" 2>/dev/null || true
        else
            # Managed window: warp to approximate position
            # (yabai will re-tile it; exact frame restore is not possible
            # for BSP-managed windows without reconstructing the tree)
            yabai -m window "$current_id" --move "abs:${x}:${y}" 2>/dev/null || true
        fi
    fi
done

echo "Layout restore attempted."
