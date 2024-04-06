#!/usr/bin/env zsh

echo ${PATH//:/\\n} | grep -Ev "^$" | sort | uniq | while read -r path; do
  [[ ! -e "$path" ]] && continue
  for cmd in $(/usr/bin/fdfind . --max-depth=1 --type=f --follow $path); do
    echo $cmd
  done
done | fzf --exact

