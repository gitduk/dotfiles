#!/usr/bin/env zsh

local uptime_str="$(uptime -p)"
local days=0
local hours=0
local mins=0

# 提取天数、小时数和分钟数
if [[ $uptime_str =~ '(up )?([0-9]+) days?, ([0-9]+) hours?, ([0-9]+) minutes?' ]]; then
    days=${match[1]}
    hours=${match[2]}
    mins=${match[3]}
elif [[ $uptime_str =~ '(up )([0-9]+) hours?, ([0-9]+) minutes?' ]]; then
    hours=${match[1]}
    mins=${match[2]}
fi

echo "$days $hours $mins"

# 计算总小时数和总分钟数
local total_hours=$((days * 24 + hours))
local total_mins=$((days * 24 * 60 + hours * 60 + mins))

# 格式化输出
if (( total_hours >= 24 )); then
    printf "%d:%02d:%02d" $days $((total_hours % 24)) $((total_mins % 60))
else
    printf "%02d:%02d" $hours $mins
fi
