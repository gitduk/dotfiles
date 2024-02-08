#/usr/bin/env zsh

number=$(tmux display-message -p "#I")

case $number in
  1) icon="󰎦" ;;
  2) icon="󰎩" ;;
  3) icon="󰎬" ;;
  4) icon="󰎮" ;;
  5) icon="󰎰" ;;
  6) icon="󰎵" ;;
  7) icon="󰎸" ;;
  8) icon="󰎻" ;;
  9) icon="󰎾" ;;
  *) icon="󰏁" ;;
esac

printf "%s" "$icon"

