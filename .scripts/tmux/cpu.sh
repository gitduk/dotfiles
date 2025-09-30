#!/usr/bin/env bash

red="#ff0000"
yellow="#ffff00"
green="#00ff00"
blue="#61afef"

style="${1:-none}"

get_stat() {
  read _ user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
  total=$((user + nice + system + idle + iowait + irq + softirq + steal + guest + guest_nice))
  echo "$total $idle"
}

read prev_total prev_idle < <(get_stat)
sleep 1
read total idle < <(get_stat)

time_delta=$((total - prev_total))
idle_delta=$((idle - prev_idle))

usage=$(awk -v t=$time_delta -v i=$idle_delta 'BEGIN {printf "%.2f", 100*(t-i)/t}')

fgcolor=$(awk -v u="$usage" -v red="$red" -v yellow="$yellow" -v blue="$blue" -v style="$style" '
  BEGIN {
    if (u >= 80)       printf "#[fg=%s %s]", red, style;
    else if (u >= 60)  printf "#[fg=%s %s]", yellow, style;
    else               printf "#[fg=%s %s]", blue, style;
  }')

printf "%s%02.0f%" "$fgcolor" "$usage"
