#!/usr/bin/env bash

kill_current() {
  window_name="$(tmux display-message -p '#W')"
  window_nums="$(tmux list-windows | wc -l)"
  
  [[ $window_nums -eq 1 ]] && exit 0
  [[ "$window_name" == *\* ]] && exit 0
  
  tmux kill-window
}

kill_right() {
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
}

case "$1" in
  -r|--right) kill_right ;;
  *) kill_current ;;
esac
