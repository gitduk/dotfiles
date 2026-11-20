#!/bin/sh
# Re-place floating panes in their recorded quadrant after the window resizes,
# so shrinking and growing back does not leave them clamped at the top left.
# With no argument, every window is reflowed.

reflow() {
	win=$1
	sx=$(tmux display -p -t "$win" '#{window_width}' 2>/dev/null)
	sy=$(tmux display -p -t "$win" '#{window_height}' 2>/dev/null)
	[ -n "$sx" ] && [ "$sx" -ge 8 ] && [ "$sy" -ge 6 ] || return

	tmux list-panes -t "$win" -F '#{pane_floating_flag} #{pane_id} #{@float_quadrant}' 2>/dev/null |
		while read -r flt id q; do
			[ "$flt" = 1 ] || continue
			case $q in 1 | 2 | 3 | 4) ;; *) continue ;; esac
			case $q in
			1) x=$(( sx - sx / 2 )); y=0 ;;                  # top right
			2) x=$(( sx - sx / 2 )); y=$(( sy - sy / 2 )) ;; # bottom right
			3) x=0; y=0 ;;                                   # top left
			4) x=0; y=$(( sy - sy / 2 )) ;;                  # bottom left
			esac
			tmux resize-pane -t "$id" -x $(( sx / 2 )) -y $(( sy / 2 ))
			tmux move-pane -t "$id" -X "$x" -Y "$y"
		done
}

if [ -n "$1" ]; then
	reflow "$1"
else
	tmux list-windows -a -F '#{window_id}' 2>/dev/null | while read -r w; do
		reflow "$w"
	done
fi
