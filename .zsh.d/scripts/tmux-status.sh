#!/usr/bin/env bash

barcolor="#[fg=colour8,bold]"
barsymb="|"
bar_left="$barcolor$barsymb "
bar_right=" $barcolor$barsymb"

function battery_meter() {
  if [ "$(which acpi)" ]; then

    if [ "$(cat /sys/class/power_supply/AC/online)" == 1 ]; then
      local charging='+'
    else
      local charging='-'
    fi
    # Check for existence of a battery.
    if [ -x /sys/class/power_supply/BAT0 ]; then
      local batt0
      batt0=$(acpi -b 2>/dev/null | awk '/Battery 0/{print $4}' | cut -d, -f1)
      case $batt0 in
        100% | 9[0-9]% | 8[0-9]% | 7[5-9]%) fgcolor='#[fg=colour118]' ;;
        7[0-4]% | 6[0-9]% | 5[0-9]%) fgcolor='#[fg=colour118]' ;;
        4[0-9]% | 3[0-9]% | 2[5-9]%) fgcolor='#[fg=colour226]' ;;
        2[0-4]% | 1[0-9]% | [0-9]%) fgcolor='#[fg=colour196]' ;;
      esac
      [ "$charging" == "+" ] && fgcolor='#[fg=colour118]'
      # Display the percentage of charge the battery has.
      printf "$bar_right %s" "${fgcolor}b${charging}${batt0}"
    fi
  fi
}

function cpu_usage() {
  percent=$(lscpu | awk '/^CPU\(s\):\s*[0-9]/ { ncore = $2 }; END { getline load <"/proc/loadavg"; printf("%.2f", 100 * load / ncore) }')
  case $percent in
    [1-9][0-9][0-9].[0-9][0-9]) fgcolor='#[fg=colour196,bold]' ;;
    [8-9][0-9].[0-9][0-9]) fgcolor='#[fg=colour196,bold]' ;;
    [5-7][0-9].[0-9][0-9]) fgcolor='#[fg=colour226,bold]' ;;
    [0-4][0-9].[0-9][0-9]) fgcolor='#[fg=colour118,bold]' ;;
    *) fgcolor='#[fg=colour118,bold]' ;;
  esac
  printf " %s" "$fgcolor$percent%"

}

function memory_usage() {
  local time

  if [ "$(which bc)" ]; then
    read total used <<<"$(free -m | awk '/Mem/{printf $2" "$3}')"
    read vtotal vused <<<"$(free -m | awk '/Swap/{printf $2" "$3}')"
    if [ "$(echo "$used > 1000" | bc)" -eq 1 ]; then
      used_mem="$(echo $used | awk '{printf "%.2f", $1/1024}')"
      unit="G"
    else
      unit="M"
      used_mem="$(echo $used | awk '{printf "%s", $1}')"
    fi
    if [ "$vtotal" != "0" ];then
      if [ "$(echo "$vused > 1000" | bc)" -eq 1 ]; then
        vused_mem="$(echo $vused | awk '{printf "%.2f", $1/1024}')"
        vunit="G"
      else
        vunit="M"
        vused_mem="$(echo $vused | awk '{printf "%s", $1}')"
      fi
    fi
    percent=$(echo $used $total| awk '{printf "%.2f", 100*$1/$2}')
    case $percent in
      1[0-9][0-9].[0-9][0-9]) fgcolor='#[fg=colour196,bold]' ;;
      [8-9][0-9].[0-9][0-9]) fgcolor='#[fg=colour196,bold]' ;;
      [5-7][0-9].[0-9][0-9]) fgcolor='#[fg=colour226,bold]' ;;
      [0-4][0-9].[0-9][0-9]) fgcolor='#[fg=colour118,bold]' ;;
    *) fgcolor='#[fg=colour118,bold]' ;;
    esac
    if [ "$vtotal" != "0" ];then
      printf " $fgcolor$used_mem$unit/$vused_mem$vunit/$percent%s$bar_right" "%"
    else
      printf " $fgcolor$used_mem$unit/$percent%s$bar_right" "%"
    fi
  fi
}

function load_average() {

  core_num=$(grep -c 'model name' /proc/cpuinfo)
  avg_5=$(cat /proc/loadavg | cut -d ' ' -f2)
  avg_5_avg=$(awk 'BEGIN{printf "%.2f\n",('$avg_5'/'$core_num')}')
  case $avg_5_avg in
    [1-9].[0-9][0-9]) avg_5_fgcolor='#[fg=colour196,bold]' ;;
    0.[7-9][0-9]) avg_5_fgcolor='#[fg=colour202,bold]' ;;
    0.[4-6][0-9]) avg_5_fgcolor='#[fg=colour226,bold]' ;;
    0.[0-3][0-9]) avg_5_fgcolor='#[fg=colour118,bold]' ;;
  esac
  printf " %s" "#[fg=colour118,bold][$avg_5_fgcolor$avg_5#[fg=colour118,bold]]"

}

function time_info() {
  dc="#[fg=colour$((($(date +'%M') + 170))),bold]"
  time=$(date +'%H:%M:%S')
  printf "%s$bar_right " "$dc$time"
}

function net_speed() {

  up_start=$(cat /proc/net/dev | tail -n 1 | cut -d ':' -f 2 | awk '{printf "%.2f", $9/1024}')
  down_start=$(cat /proc/net/dev | tail -n 1 | cut -d ':' -f 2 | awk '{printf "%.2f", $1/1024}')
  sleep 0.5
  up_end=$(cat /proc/net/dev | tail -n 1 | cut -d ':' -f 2 | awk '{printf "%.2f", $9/1024}')
  down_end=$(cat /proc/net/dev | tail -n 1 | cut -d ':' -f 2 | awk '{printf "%.2f", $1/1024}')

  up_speed=$(echo $up_end $up_start | awk '{printf "%.2f", ($1-$2)*2}')
  down_speed=$(echo $down_end $down_start | awk '{printf "%.2f", ($1-$2)*2}')

  if [ "$(echo "$up_speed > 1024" | bc)" == 1 ]; then
    up_speed=$(echo $up_speed | awk '{ printf "%.2f ms", $1/1024}')
    u_fg_color='#[fg=colour118,bold]'
  else
    up_speed=$(printf "%.2f ks" $up_speed)
    u_fg_color="#[fg=colour15,bold]"
  fi

  if [ "$(echo "$down_speed > 1024" | bc)" == 1 ]; then
    down_speed=$(echo $down_speed | awk '{ printf "%.2f ms", $1/1024}')
    d_fg_color='#[fg=colour118,bold]'
  else
    down_speed=$(printf "%.2f ks" $down_speed)
    d_fg_color="#[fg=colour15,bold]"
  fi

  essid=$(iwconfig 2>/dev/null |grep ESSID|cut -d ':' -f2)

  if [ ! -n "$(echo $essid|grep 'off')" ]; then
    printf "$u_fg_color%s $d_fg_color%s$bar_right " "⇡ $up_speed" "⇣ $down_speed"
  fi
}

function sync() {
  if [ -n "$(tmux show-window-options|grep 'synchronize-panes on')" ];then
    printf "$bar_left#[fg=colour15,bold]%s " "sync"
  fi
}

function main() {
  if [ $1 == left ]; then

    printf "%s" "$(ip_address)"
    # printf "%s" "$(proxy_port)"
    # printf "%s" "$(date_info)"
    printf "%s" "$(disk_usage)"
    printf "%s" "$(sync)"
    printf "%s" "$(wifi)"

  elif [ $1 == right ]; then

    # printf "%s" "$(net_speed)"
    # printf "%s" "$(time_info)"
    printf "%s" "$(memory_usage)"
    printf "%s" "$(cpu_usage)"
    printf "%s" "$(battery_meter)"
    printf "%s" "$(load_average)"

  fi
}

function cpu_temperature() {

  # Display the temperature of CPU core 0 and core 1.
  sensors -f | awk '/Core 0/{printf $3" "}/Core 1/{printf $3" "}'

}

main $1

