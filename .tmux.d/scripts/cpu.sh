#!/usr/bin/env zsh

# style
local red="#ff0000"
local yellow="#ffff00"
local green="#00ff00"
local blue="#61afef"

sytle="${1:-none}"

function get_stat {
  cat /proc/stat | grep '^cpu ' | awk '{printf "%s %s", $2 + $3 + $4 + $5 + $6 + $7 + $8 + $9 + $10, $5}'
}

# 获取总时间和空闲时间
read prev_total prev_idle < <(get_stat)
sleep 0.1
read total idle < <(get_stat)

# 计算时间间隔和使用率
time_delta=$((total - prev_total))
usage=$(echo $time_delta $idle $prev_idle | awk '{printf "%.2f", 100*($1-($2-$3))/$1}')

case $usage in
  [8-9][0-9].*|100.*) fgcolor="#[fg=$red $sytle]" ;;
  [6-7][0-9].*) fgcolor="#[fg=$yellow $sytle]" ;;
  [0-9].*|[1-5][0-9].*) fgcolor="#[fg=$blue $sytle]" ;;
  *) fgcolor="#[fg=$red $sytle]" ;;
esac

printf "%s%05.2f" $fgcolor $usage

