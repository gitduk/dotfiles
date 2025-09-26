#!/usr/bin/env bash

# 获取当前窗口编号
CUR_WINDOW=$(tmux display-message -p "#I")

# 获取右边第一个窗口编号
NEXT_WINDOW=$((CUR_WINDOW + 1))

# 获取最右边的窗口编号
LAST_WINDOW=$(tmux list-windows -F '#{window_index}' | sort -n | tail -n 1)

[[ $LAST_WINDOW -eq $CUR_WINDOW ]] && tmux display-message "No window on the right" && exit 0
for ((i=LAST_WINDOW; i>=NEXT_WINDOW; i--)); do
	tmux kill-window -t "$i"
done

tmux display-message "Kill window $NEXT_WINDOW-$LAST_WINDOW"
