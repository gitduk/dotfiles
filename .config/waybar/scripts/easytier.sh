#!/usr/bin/env bash

# 获取 easytier peer 状态
get_peer_status() {
  local output
  output=$(easytier-cli peer 2>/dev/null)

  if [[ $? -ne 0 ]] || [[ -z "$output" ]]; then
    echo "{\"text\":\"󰌙 离线\",\"tooltip\":\"easytier 未运行\",\"class\":\"disconnected\"}"
    return
  fi

  # 解析 peer 信息（跳过表头）
  local peer_count=0
  local connected_peers=()
  local line_num=0

  while IFS='|' read -r col1 col2 col3 col4 col5 col6 col7 col8 col9 col10; do
    ((line_num++))

    # 跳过表头和分隔线
    [[ $line_num -le 2 ]] && continue

    # 清理空格
    for i in {1..10}; do
      eval "col$i=\$(echo \"\$col$i\" | xargs)"
    done

    # 第一行：ipv4 | hostname | cost | ...
    # 如果 col2 包含 IP 地址（有斜杠），说明是本地节点
    if [[ "$col2" =~ / ]]; then
      # 本地节点，跳过
      continue
    fi

    # 第二行：空 | 空 | hostname | cost | lat | loss | rx | tx | tunnel | ...
    # hostname 在 col3, cost 在 col4, lat 在 col5, tunnel 在 col9
    local hostname="$col3"
    local cost="$col4"
    local lat="$col5"
    local tunnel="$col9"

    # 跳过空行
    [[ -z "$hostname" ]] && continue

    # 统计连接的 peer
    ((peer_count++))
    connected_peers+=("$hostname ($tunnel, ${lat}ms)")
  done <<< "$output"

  # 生成输出
  local text icon class
  if [[ $peer_count -eq 0 ]]; then
    icon="󰌙"
    text="$icon 无连接"
    class="warning"
  else
    icon="󰀂"
    text="$icon $peer_count"
    class="connected"
  fi

  # 生成 tooltip
  local tooltip="easytier 连接状态\\n---"
  if [[ $peer_count -gt 0 ]]; then
    for peer in "${connected_peers[@]}"; do
      tooltip="$tooltip\\n✓ $peer"
    done
  else
    tooltip="$tooltip\\n无活动连接"
  fi

  echo "{\"text\":\"$text\",\"tooltip\":\"$tooltip\",\"class\":\"$class\"}"
}

main() {
  get_peer_status
}

main "$@"
