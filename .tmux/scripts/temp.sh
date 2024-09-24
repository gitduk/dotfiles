#!/usr/bin/env zsh

# Temperature - using /sys/class/thermal
cpu_temp=0
for temp_file in /sys/class/thermal/thermal_zone*/temp; do
  current_temp=$(cat "$temp_file")
  current_temp=$((current_temp / 1000)) # Convert from millidegree to degree
  if [[ $current_temp -gt $cpu_temp ]]; then
    cpu_temp=$current_temp
  fi
done
[[ $cpu_temp = 0 ]] && cpu_temp="N/A"

# color
local red="#ff0000"
local yellow="#ffff00"
local green="#00ff00"
local blue="#61afef"

style="${1:-none}"

# Format temperature output
case $cpu_temp in
  [6-9][0-9]|100) fgcolor="#[fg=$red $style]" ;;
  5[0-9]) fgcolor="#[fg=$yellow $style]" ;;
  *) fgcolor="#[fg=$blue $style]" ;;
esac

printf "%s" "$fgcolor$cpu_temp"

