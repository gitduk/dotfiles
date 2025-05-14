#!/usr/bin/env zsh

# 从 cliphist 列表中选择或输入新文本
selection=$(cliphist list \
  | fzf --no-sort \
    --bind "D:execute-silent(echo {+} | cliphist delete)+reload(cliphist list)" \
    --bind "C:execute-silent(cliphist wipe)+reload(cliphist list)" \
    --print-query \
    --expect=ctrl-y)

# 提取查询和键
query=$(echo "$selection" | sed -n '1p')
key=$(echo "$selection" | sed -n '2p')
result=$(echo "$selection" | sed -n '3p')

if [[ "$key" == "ctrl-y" ]]; then
  # 用户按了 ctrl-y，使用输入的查询文本，并去掉前后换行符
  echo -n "$query" | tr -d '\n' | wl-copy
elif [[ -n "$result" ]]; then
  # 用户选择了剪贴板历史中的项目
  echo "$result" | cliphist decode | wl-copy
else
  # 如果用户只输入了文本但直接按了回车
  echo -n "$query" | tr -d '\n' | wl-copy
fi
