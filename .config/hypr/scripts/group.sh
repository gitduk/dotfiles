#!/usr/bin/env bash

ACTIVE=$(hyprctl activewindow -j)
ACTIVE_ADDR=$(echo "$ACTIVE" | jq -r '.address')
WORKSPACE_ID=$(echo "$ACTIVE" | jq '.workspace.id')

ALL_CLIENTS=$(hyprctl clients -j)
WS_WINDOWS=$(echo "$ALL_CLIENTS" | jq -c "[.[] | select(.workspace.id == $WORKSPACE_ID and .mapped == true)]")
WIN_COUNT=$(echo "$WS_WINDOWS" | jq 'length')
GROUP_LEN=$(echo "$ACTIVE" | jq '.grouped | length')

# Single window in a group → ungroup it
if [ "$WIN_COUNT" -eq 1 ] && [ "$GROUP_LEN" -ge 1 ]; then
  hyprctl dispatch togglegroup
  exit 0
fi

# All workspace windows already in one group → ungroup all
ALL_GROUPED=$(echo "$WS_WINDOWS" | jq "[.[] | select((.grouped | length) == $WIN_COUNT)] | length")
if [ "$ALL_GROUPED" -ge 1 ]; then
  hyprctl dispatch togglegroup
  hyprctl dispatch focuswindow "address:$ACTIVE_ADDR"
  exit 0
fi

# --- Group all windows on this workspace ---

# Find or create a group anchor
EXISTING_GROUP_ADDR=$(echo "$WS_WINDOWS" | jq -r "
  [.[] | select((.grouped | length) > 0)]
  | .[0].address // empty
")

if [ -n "$EXISTING_GROUP_ADDR" ]; then
  # Use existing group as anchor — do NOT toggle (would ungroup)
  hyprctl dispatch focuswindow "address:$EXISTING_GROUP_ADDR"
else
  # Create a new group on the leftmost window
  LEFTMOST_ADDR=$(echo "$WS_WINDOWS" | jq -r 'sort_by(.at[0]) | .[0].address')
  if [ "$ACTIVE_ADDR" != "$LEFTMOST_ADDR" ]; then
    hyprctl dispatch focuswindow "address:$LEFTMOST_ADDR"
  fi
  hyprctl dispatch togglegroup
fi

ANCHOR_DATA=$(hyprctl activewindow -j)
ANCHOR_ADDR=$(echo "$ANCHOR_DATA" | jq -r '.address')
ANCHOR_X=$(echo "$ANCHOR_DATA" | jq '.at[0]')
ANCHOR_GROUP_ADDRS=$(echo "$ANCHOR_DATA" | jq -r '.grouped[].address')

# Pull every ungrouped window into the anchor group, sorted by x so
# the group's internal order matches the original spatial layout.
echo "$WS_WINDOWS" | jq -r 'sort_by(.at[0]) | .[].address' | while read -r addr; do
  [ "$addr" = "$ANCHOR_ADDR" ] && continue
  echo "$ANCHOR_GROUP_ADDRS" | grep -qF "$addr" && continue

  TARGET_X=$(echo "$WS_WINDOWS" | jq -r ".[] | select(.address == \"$addr\") | .at[0]")
  hyprctl dispatch focuswindow "address:$addr"
  if [ "$TARGET_X" -ge "$ANCHOR_X" ]; then
    hyprctl dispatch moveintogroup l
  else
    hyprctl dispatch moveintogroup r
  fi
done

hyprctl dispatch focuswindow "address:$ACTIVE_ADDR"
