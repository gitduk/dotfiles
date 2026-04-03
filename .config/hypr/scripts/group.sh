#!/usr/bin/env bash

# 获取当前窗口信息
ACTIVE=$(hyprctl activewindow -j)
ACTIVE_ADDR=$(echo "$ACTIVE" | jq -r '.address')
WORKSPACE_ID=$(echo "$ACTIVE" | jq '.workspace.id')
GROUPED=$(echo "$ACTIVE" | jq '.grouped | length')

# 统计当前 workspace 的窗口总数
WIN_COUNT=$(hyprctl clients -j | jq "[.[] | select(.workspace.id == $WORKSPACE_ID and .mapped == true)] | length")

if [ "$WIN_COUNT" -eq 1 ] && [ "$GROUPED" -eq 1 ]; then
  hyprctl dispatch togglegroup
  exit 0
fi

if [ "$GROUPED" -gt 0 ]; then
  # 判断 group 内窗口数是否等于 workspace 总窗口数
  GROUP_COUNT=$(echo "$ACTIVE" | jq '.grouped | length')
  if [ "$GROUP_COUNT" -eq "$WIN_COUNT" ]; then
    hyprctl dispatch togglegroup
    hyprctl dispatch focuswindow "address:$ACTIVE_ADDR"
    exit 0
  fi
  # 还有窗口不在 group 中，循环把剩余窗口拉进来
  REMAINING=$((WIN_COUNT - GROUP_COUNT))
  for ((i=0; i<REMAINING; i++)); do
    hyprctl --batch "dispatch movefocus r ; dispatch moveintogroup l"
  done
  exit 0
fi

# 找同 workspace 内 x 坐标最小的窗口（最左）
LEFTMOST_ADDR=$(hyprctl clients -j | jq -r "
  [ .[] | select(.workspace.id == $WORKSPACE_ID and .mapped == true) ]
  | sort_by(.at[0])
  | .[0].address
")

# 移到最左侧窗口并建 group
if [ "$ACTIVE_ADDR" != "$LEFTMOST_ADDR" ]; then
  hyprctl dispatch focuswindow "address:$LEFTMOST_ADDR"
fi

hyprctl dispatch togglegroup

# 循环把其余所有窗口并入 group（共 WIN_COUNT-1 次）
for ((i=1; i<WIN_COUNT; i++)); do
  hyprctl --batch "dispatch movefocus r ; dispatch moveintogroup l"
done

# 聚焦回原来的窗口
hyprctl dispatch focuswindow "address:$ACTIVE_ADDR"
