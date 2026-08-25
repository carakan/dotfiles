#!/usr/bin/env bash
# save_layout.sh — snapshot the current window tree for the active space.
#
# Saves window positions, sizes, and split ratios to a JSON file so the layout
# can be restored later with restore_layout.sh.
#
# Usage: save_layout.sh [output_file]
#   output_file defaults to /tmp/yabai_layout_<space_index>.json

set -euo pipefail

SPACE_INDEX=$(yabai -m query --spaces --space | jq '.index')
OUTPUT_FILE="${1:-/tmp/yabai_layout_${SPACE_INDEX}.json}"

# Capture the full window tree for this space
yabai -m query --windows --space | jq '{
  space: .[0].space,
  captured_at: now | todate,
  windows: [ .[] | {
    id,
    app,
    title,
    frame,
    "split-type",
    "split-child",
    "stack-index",
    "is-floating",
    "is-sticky",
    "is-minimized",
    "has-parent-zoom",
    "has-fullscreen-zoom",
    layer,
    "sub-layer",
    opacity
  } ]
}' > "$OUTPUT_FILE"

echo "Layout saved to ${OUTPUT_FILE}"
