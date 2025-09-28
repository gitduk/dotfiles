#!/usr/bin/env bash

tmux swap-pane -d -t 1
panes=($(tmux list-panes -F '#{pane_index}' | wc -l)-1)
for ((i = 1; i <= $panes; i++)); do
	tmux break-pane -d -s 2
done

