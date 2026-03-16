#!/usr/bin/env bash

main() {
  local parsed

  parsed=$(easytier-cli peer 2>/dev/null | awk -F'|' '
    NR<=2 { next }

    {
      # trim
      for(i=1;i<=NF;i++){
        gsub(/^[ \t]+|[ \t]+$/, "", $i)
      }

      ip=$2
      host=$3
      loss=$6

      # 只要有 IP 的行（过滤 relay）
      if(ip!="" && host!=""){
        printf "%s|%s|%s\n", host, ip, loss
      }
    }
  ')

  if [[ -z "$parsed" ]]; then
    echo '{"text":"󰌙 Offline","tooltip":"easytier not running","class":"disconnected"}'
    return
  fi

  local peer_count=0
  local tooltip="easytier connection status\n---"

  while IFS='|' read -r host ip loss; do
    ((peer_count++))
    tooltip="$tooltip\n✓ $host ($ip, $loss)"
  done <<< "$parsed"

  local icon text class

  if [[ $peer_count -eq 0 ]]; then
    icon="󰌙"
    text="$icon No connections"
    class="warning"
    tooltip="$tooltip\nNo active connections"
  else
    icon="󰀂"
    text="$icon $peer_count"
    class="connected"
  fi

  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$class"
}

main

