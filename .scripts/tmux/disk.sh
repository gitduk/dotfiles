#!/usr/bin/env bash

# Disk usage
disk_usage=$(df -h --output=source,pcent | awk '/^\/dev/{print $2}' | sed 's/%//g' | sort -nr | head -1)

# color
red="#ff0000"
yellow="#ffff00"
green="#00ff00"
blue="#61afef"

style="${1:-none}"

case $disk_usage in
  9[0-9]|100) fgcolor="#[fg=$red $style]" ;;
  [7-8][0-9]) fgcolor="#[fg=$yellow $style]" ;;
  *) fgcolor="#[fg=$blue $style]" ;;
esac

printf "%s" "$fgcolor$disk_usage"
