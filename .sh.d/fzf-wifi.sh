#!/usr/bin/env zsh

ssid="$(nmcli dev wifi list | sed '1d' \
  | fzf --prompt='wifi> ' --bind 'R:reload(nmcli dev wifi rescan && nmcli dev wifi list | sed '1d')' \
  | awk '{print $2}')"

if [[ -n "$ssid" ]] && [[ "$ssid" != "--" ]]; then
  nmcli dev wifi connect "$ssid"
fi

