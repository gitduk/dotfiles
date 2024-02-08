#!/usr/bin/env zsh

urls=(
  "https://raw.githubusercontent.com/gitduk/clash-rules/main/custom/chat.txt"
  "https://raw.githubusercontent.com/gitduk/clash-rules/release/openai.txt"
  "https://raw.githubusercontent.com/gitduk/clash-rules/release/proxy.txt"
  "https://raw.githubusercontent.com/gitduk/clash-rules/release/gfw.txt"
  "https://raw.githubusercontent.com/gitduk/clash-rules/release/lan_cidr.txt"
  "https://raw.githubusercontent.com/gitduk/clash-rules/release/direct.txt"
  "https://raw.githubusercontent.com/gitduk/clash-rules/release/cn_cidr.txt"
)

for url in "${urls[@]}"; do
  file="${url##/}"
  [[ -e "$file" ]] && rm -rf $file
  wget "$url"
done
