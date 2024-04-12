#!/usr/bin/env zsh

local ip_address=$(cat /tmp/ip_address)

while true; do
  if [[ ! "$(cat /tmp/ip_address)" == "$ip_address" ]]; then
    resend.sh "IP变动通知" "$(bat /tmp/ip_address)"
    ip_address=$(cat /tmp/ip_address)
  else
    print -n $'\r''监听中... '
  fi
  sleep 1
done

