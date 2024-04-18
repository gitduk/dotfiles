#!/usr/bin/env zsh

while read -r path
do
  [[ ! -d "$path" ]] && continue
  for cmd in $(/usr/bin/find "$path" -maxdepth 1 -type f -follow); do
    echo $cmd
  done
done <<< "`echo ${PATH//:/ } | xargs -n 1 | sort | uniq`" | fzf

