#!/usr/bin/env bash
# Enhanced Temperature Script - Compatible with Ubuntu, RedHat, and other Linux distributions
# Supports multiple temperature sources: thermal_zone, hwmon, coretemp, and sensors command

cpu_temp=0

# Method 1: Try /sys/class/thermal/thermal_zone*
if [ "$cpu_temp" = 0 ] && ls /sys/class/thermal/thermal_zone*/temp >/dev/null 2>&1; then
  for temp_file in /sys/class/thermal/thermal_zone*/temp; do
    if [ -f "$temp_file" ] && [ -r "$temp_file" ]; then
      current_temp=$(cat "$temp_file" 2>/dev/null)
      if [ -n "$current_temp" ] && [ "$current_temp" -gt 0 ] 2>/dev/null; then
        current_temp=$((current_temp / 1000))
        if [ "$current_temp" -gt "$cpu_temp" ]; then
          cpu_temp=$current_temp
        fi
      fi
    fi
  done
fi

# Method 2: Try /sys/class/hwmon/hwmon*
if [ "$cpu_temp" = 0 ] && ls /sys/class/hwmon/hwmon*/temp*_input >/dev/null 2>&1; then
  for temp_file in /sys/class/hwmon/hwmon*/temp*_input; do
    if [ -f "$temp_file" ] && [ -r "$temp_file" ]; then
      current_temp=$(cat "$temp_file" 2>/dev/null)
      if [ -n "$current_temp" ] && [ "$current_temp" -gt 0 ] 2>/dev/null; then
        current_temp=$((current_temp / 1000))
        if [ "$current_temp" -gt "$cpu_temp" ]; then
          cpu_temp=$current_temp
        fi
      fi
    fi
  done
fi

# Method 3: Try coretemp specifically
if [ "$cpu_temp" = 0 ] && ls /sys/devices/platform/coretemp.*/hwmon/hwmon*/temp*_input >/dev/null 2>&1; then
  for temp_file in /sys/devices/platform/coretemp.*/hwmon/hwmon*/temp*_input; do
    if [ -f "$temp_file" ] && [ -r "$temp_file" ]; then
      current_temp=$(cat "$temp_file" 2>/dev/null)
      if [ -n "$current_temp" ] && [ "$current_temp" -gt 0 ] 2>/dev/null; then
        current_temp=$((current_temp / 1000))
        if [ "$current_temp" -gt "$cpu_temp" ]; then
          cpu_temp=$current_temp
        fi
      fi
    fi
  done
fi

# Method 4: Try k10temp for AMD processors
if [ "$cpu_temp" = 0 ] && ls /sys/devices/pci*/*/hwmon/hwmon*/temp*_input >/dev/null 2>&1; then
  for temp_file in /sys/devices/pci*/*/hwmon/hwmon*/temp*_input; do
    if [ -f "$temp_file" ] && [ -r "$temp_file" ]; then
      current_temp=$(cat "$temp_file" 2>/dev/null)
      if [ -n "$current_temp" ] && [ "$current_temp" -gt 0 ] 2>/dev/null; then
        current_temp=$((current_temp / 1000))
        if [ "$current_temp" -gt "$cpu_temp" ]; then
          cpu_temp=$current_temp
        fi
      fi
    fi
  done
fi

# Method 5: Try sensors command as fallback
if [ "$cpu_temp" = 0 ] && command -v sensors >/dev/null 2>&1; then
  # Try to get CPU temperature from sensors (works with lm_sensors)
  temp_output=$(sensors 2>/dev/null | grep -E "Core 0|Package id 0|Tdie|Tctl" | head -1 | grep -oP '\+\K[0-9]+' | head -1)
  if [ -n "$temp_output" ] && [ "$temp_output" -gt 0 ] 2>/dev/null; then
    cpu_temp=$temp_output
  fi
fi

# Method 6: Try ACPI thermal zone
if [ "$cpu_temp" = 0 ] && [ -f /proc/acpi/thermal_zone/THM0/temperature ]; then
  temp_output=$(cat /proc/acpi/thermal_zone/THM0/temperature 2>/dev/null | grep -oP '[0-9]+' | head -1)
  if [ -n "$temp_output" ] && [ "$temp_output" -gt 0 ] 2>/dev/null; then
    cpu_temp=$temp_output
  fi
fi

# Set to N/A if no temperature was found
[ "$cpu_temp" = 0 ] && cpu_temp="N/A"

# Color definitions
red="#ff0000"
yellow="#ffff00"
green="#00ff00"
blue="#61afef"
style="${1:-none}"

# Format temperature output with color based on temperature
if [ "$cpu_temp" = "N/A" ]; then
  fgcolor="#[fg=$blue $style]"
else
  case $cpu_temp in
    [8-9][0-9]|[1-9][0-9][0-9]) fgcolor="#[fg=$red $style]" ;;      # 80°C and above - Critical
    [6-7][0-9]) fgcolor="#[fg=$red $style]" ;;                       # 60-79°C - High
    5[0-9]) fgcolor="#[fg=$yellow $style]" ;;                        # 50-59°C - Warm
    *) fgcolor="#[fg=$blue $style]" ;;                               # Below 50°C - Normal
  esac
fi

printf "%s" "$fgcolor$cpu_temp"
