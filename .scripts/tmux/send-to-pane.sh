#!/usr/bin/env bash

for w in $(tmux list-windows -F '#{window_index}'); do
	for p in $(tmux list-pane -t :$w -F '#{pane_index}'); do
		tmux send-keys -t :$w.$p "$*"
		tmux send-keys -t :$w.$p Enter
	done
done

