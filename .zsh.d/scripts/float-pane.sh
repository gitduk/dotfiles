#!/bin/sh
# C-o: new floating pane in the first free quadrant (TR, BR, TL, BL).

cur=$1
[ -n "$cur" ] || { echo "usage: $0 <pane-id>" >&2; exit 1; }
set -- $("$(dirname "$0")/float-slot.sh" "$cur") # width height x y quadrant

dir=$(tmux display -p -t "$cur" '#{pane_current_path}')
pane=$(tmux new-pane -t "$cur" -c "$dir" -x "$1" -y "$2" -X "$3" -Y "$4" -P -F '#{pane_id}')
tmux set -p -t "$pane" @float_quadrant "$5"
