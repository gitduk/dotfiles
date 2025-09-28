#!/usr/bin/env bash

killsession() {
  [[ "$1" == *\* ]] && return 0
  tmux kill-session -t "$1"
}

current=$(tmux display-message -p '#S')

case "$1" in
  -o|--others)
    sessions=$(tmux list-sessions -F '#S')
    for session in ${sessions[@]}; do
      if [[ ! "$session" == "$current" ]]; then
        killsession "$session"
      fi
    done
    ;;
  *) killsession $current
esac

