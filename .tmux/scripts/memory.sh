#!/usr/bin/env zsh

# color
local red="#ff0000"
local yellow="#ffff00"
local green="#00ff00"
local blue="#61afef"

sytle="${1:-none}"

mem=$(free | awk '/Mem/{printf "%.2f", $3/$2 * 100.0}')

case $mem in
  8[6-9].*|9[0-9].*|100.*) fgcolor="#[fg=$red $sytle]" ;;
  7[0-9].*|8[0-5].*) fgcolor="#[fg=$yellow $sytle]" ;;
  [0-9].*|[1-6][0-9].*) fgcolor="#[fg=$blue $sytle]" ;;
  *) fgcolor="#[fg=$red $sytle]" ;;
esac

printf "%s" "$fgcolor$mem%"

