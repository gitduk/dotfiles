#!/usr/bin/env bash

STATE_FILE="/tmp/breath_state_478"

# 4s inhale, 7s hold, 8s exhale = 19 total frames
# 每秒一帧

frames=(
  # --- Inhale 4s (0~3)
  "󰪞 |INHALE"
  "󰪠 |INHALE"
  "󰪢 |INHALE"
  "󰪤 |INHALE"

  # --- Hold 7s (4~10)
  "󰪥 |HOLDON"
  "󰪥 |HOLDON"
  "󰪥 |HOLDON"
  "󰪥 |HOLDON"
  "󰪥 |HOLDON"
  "󰪥 |HOLDON"
  "󰪥 |HOLDON"

  # --- Exhale 8s (11~18)
  "󰪥 |EXHALE"
  "󰪤 |EXHALE"
  "󰪣 |EXHALE"
  "󰪢 |EXHALE"
  "󰪡 |EXHALE"
  "󰪠 |EXHALE"
  "󰪟 |EXHALE"
  "󰪞 |EXHALE"
  "󰪞 |EXHALE"
)

TOTAL=${#frames[@]}

# Init state
if [[ ! -f "$STATE_FILE" ]]; then
    echo 0 > "$STATE_FILE"
fi

index=$(cat "$STATE_FILE")

# 输出当前帧
current="${frames[$index]}"
icon="${current%%|*}"
text="${current##*|}"

echo "$icon $text"

# 下一个
next=$(( (index + 1) % TOTAL ))
echo "$next" > "$STATE_FILE"
