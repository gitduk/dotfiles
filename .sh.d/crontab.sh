#!/usr/bin/env zsh

crontab -l | grep -Ev "^#|^$|^[a-zA-Z]" | sort | fzf | while read -r raw
do
  raw=${raw//\*/\\*}
  task="$(echo $raw | sed -n 's/\\\*/*/g;p')"
  read _ _ _ _ _ command <<< $task
  [[ -z "$command" ]] && continue
  zsh <<< $command
done

