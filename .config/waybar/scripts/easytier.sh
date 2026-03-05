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
    echo '{"text":"󰌙 离线","tooltip":"easytier 未运行","class":"disconnected"}'
    return
  fi

  local peer_count=0
  local tooltip="easytier 连接状态\n---"

  while IFS='|' read -r host ip loss; do
    ((peer_count++))
    tooltip="$tooltip\n✓ $host ($ip, $loss)"
  done <<< "$parsed"

  local icon text class

  if [[ $peer_count -eq 0 ]]; then
    icon="󰌙"
    text="$icon 无连接"
    class="warning"
    tooltip="$tooltip\n无活动连接"
  else
    icon="󰀂"
    text="$icon $peer_count"
    class="connected"
  fi

  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$class"
}

main
