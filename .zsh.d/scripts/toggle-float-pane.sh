#!/bin/sh
# C-S-o: float the current pane into the first free quadrant, or tile it back
# on the side it floats over, at the size it had before.

cur=$1
[ -n "$cur" ] || { echo "usage: $0 <pane-id>" >&2; exit 1; }
win=$(tmux display -p -t "$cur" '#{window_id}')

if [ "$(tmux display -p -t "$cur" '#{pane_floating_flag}')" = 1 ]; then
	set -- $(tmux display -p -t "$cur" '#{pane_x} #{pane_y} #{pane_width} #{pane_height}')
	fx=$1 fy=$2 fw=$3 fh=$4
	cx=$(( fx + fw / 2 )); cy=$(( fy + fh / 2 ))

	# tile back onto the tiled pane nearest the floating one
	target=$(tmux list-panes -t "$win" -F '#{pane_id} #{pane_floating_flag} #{pane_x} #{pane_y} #{pane_width} #{pane_height}' |
		awk -v cx="$cx" -v cy="$cy" '$2 == 0 {
			x = $3 + $5 / 2; y = $4 + $6 / 2;
			d = (x - cx) * (x - cx) + (y - cy) * (y - cy);
			if (best == "" || d < best) { best = d; id = $1 }
		}
		END { print id }')
	if [ -z "$target" ]; then
		# nothing tiled is left: a floating pane tiles into its own window
		# when source and target are the same
		tmux join-pane -s "$cur" -t "$cur"
		tmux set -p -u -t "$cur" @float_w
		tmux set -p -u -t "$cur" @float_h
		tmux set -p -u -t "$cur" @float_quadrant
		exit
	fi

	set -- $(tmux display -p -t "$target" '#{pane_x} #{pane_y} #{pane_width} #{pane_height}')
	tw=$3 th=$4
	dx=$(( cx - $1 - tw / 2 )); dy=$(( cy - $2 - th / 2 ))
	ax=$dx; [ "$ax" -lt 0 ] && ax=$(( -ax ))
	ay=$dy; [ "$ay" -lt 0 ] && ay=$(( -ay ))

	# split on the axis the floating pane sits furthest along; ties go horizontal
	# a remembered size that no longer fits leaves the split even
	if [ "$ax" -ge "$ay" ]; then
		size=$(tmux display -p -t "$cur" '#{@float_w}')
		[ -n "$size" ] && [ "$size" -lt "$tw" ] || size=
		[ "$dx" -lt 0 ] && side='-h -b' || side='-h'
	else
		size=$(tmux display -p -t "$cur" '#{@float_h}')
		[ -n "$size" ] && [ "$size" -lt "$th" ] || size=
		[ "$dy" -lt 0 ] && side='-b' || side=
	fi
	tmux join-pane -s "$cur" -t "$target" ${size:+-l "$size"} $side
	tmux set -p -u -t "$cur" @float_w
	tmux set -p -u -t "$cur" @float_h
	tmux set -p -u -t "$cur" @float_quadrant
	exit
fi

if [ "$(tmux display -p -t "$cur" '#{window_zoomed_flag}')" = 1 ]; then
	tmux resize-pane -Z -t "$cur"
fi

tmux set -p -t "$cur" @float_w "$(tmux display -p -t "$cur" '#{pane_width}')"
tmux set -p -t "$cur" @float_h "$(tmux display -p -t "$cur" '#{pane_height}')"

set -- $("$(dirname "$0")/float-slot.sh" "$cur") # width height x y quadrant
pane=$(tmux break-pane -W -s "$cur" -x "$1" -y "$2" -X "$3" -Y "$4" -P -F '#{pane_id}')
tmux set -p -t "$pane" @float_quadrant "$5"
