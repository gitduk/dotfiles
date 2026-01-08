#!/usr/bin/env bash

# style
red="#ff0000"
yellow="#ffff00"
green="#00ff00"
blue="#61afef"

style="${1:-none}"

# 获取CPU核心数
cores=$(cat /proc/cpuinfo | grep '^processor' | wc -l)

# 读取并计算负载平均值
loadavg=$(cut -d ' ' -f 1-3 /proc/loadavg)
avg=$(echo $loadavg | awk '{printf "%.2f", ($1 + $2 + $3) / 3}')

# 将平均负载除以核心数，得到每核的平均负载
normalized_load=$(echo "$avg / $cores" | bc -l)

# 根据每核的负载平均值设置颜色
case 1 in
  $(echo "$normalized_load >= 1.5" | bc)) fgcolor="#[fg=$red $style]" ;;
  $(echo "$normalized_load >= 1.0" | bc)) fgcolor="#[fg=$yellow $style]" ;;
  *) fgcolor="#[fg=$blue $style]" ;;
esac

# 输出格式化后的平均负载
printf "%s" "$fgcolor$avg"

