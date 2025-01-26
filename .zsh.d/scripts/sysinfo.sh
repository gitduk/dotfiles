#!/usr/bin/env zsh

function main {
  echo "主板"
  echo " " | sudo -S dmidecode -t system 2>/dev/null | sed '1,4d'

  echo "处理器"
  sudo dmidecode -t processor 2>/dev/null | sed '1,4d'

  echo "内存"
  sudo dmidecode -t memory 2>/dev/null | sed '1,4d'

  echo "网卡"
  lspci -vnn | grep -i eth -A 10 2>/dev/null

  echo "声卡"
  lspci -vnn | grep -i audio -A 10 2>/dev/null

  echo "\n显卡"
  lspci -vnn | grep -i vga -A 10 2>/dev/null

  echo "\nPCI 设备"
  lspci 2>/dev/null

  echo "\nUSB 设备"
  lsusb 2>/dev/null

  echo "\n显示器"
  hwinfo --monitor --short 2>/dev/null
  xrandr -q 2>/dev/null
}

main | cat -n | fzf

