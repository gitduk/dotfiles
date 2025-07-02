#!/usr/bin/env zsh

ROFI_ERROR_FILE="/tmp/rofi_error"

if [[ -f "$ROFI_ERROR_FILE" ]]; then
  tofi-drun | xargs hyprctl dispatch exec --
else
  if ! rofi -show combi -combi-modes "drun,ssh,run" -modes combi; then
    touch "$ROFI_ERROR_FILE"
    tofi-drun | xargs hyprctl dispatch exec --
  fi
fi
