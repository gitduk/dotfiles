#!/usr/bin/env zsh

# read urls from rules.txt
urls=(
  https://raw.githubusercontent.com/gitduk/clash-rules/main/custom/chat.txt
  https://raw.githubusercontent.com/gitduk/clash-rules/release/openai.txt
  https://raw.githubusercontent.com/gitduk/clash-rules/release/proxy.txt
  https://raw.githubusercontent.com/gitduk/clash-rules/release/gfw.txt
  https://raw.githubusercontent.com/gitduk/clash-rules/release/lan_cidr.txt
  https://raw.githubusercontent.com/gitduk/clash-rules/release/direct.txt
  https://raw.githubusercontent.com/gitduk/clash-rules/release/cn_cidr.txt
  https://raw.githubusercontent.com/gitduk/clash-rules/release/reject-uniq.txt
  https://raw.githubusercontent.com/gitduk/clash-rules/main/custom/force-direct.txt
  https://raw.githubusercontent.com/gitduk/clash-rules/main/custom/force-proxy.txt
)

# download rules
wget -P ./rules/ -N "${urls[@]}"
