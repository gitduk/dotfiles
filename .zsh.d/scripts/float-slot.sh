#!/bin/sh
# Print "width height x y quadrant" for the first free floating quadrant of the
# window holding $1: top right, bottom right, top left, bottom left.

cur=$1
[ -n "$cur" ] || { echo "usage: $0 <pane-id>" >&2; exit 1; }
win=$(tmux display -p -t "$cur" '#{window_id}')
sx=$(tmux display -p -t "$cur" '#{window_width}')
sy=$(tmux display -p -t "$cur" '#{window_height}')

# quadrant each floating pane belongs to: the recorded one, else the half its
# centre falls in
used=$(tmux list-panes -t "$win" -F '#{pane_floating_flag} #{@float_quadrant} #{pane_x} #{pane_y} #{pane_width} #{pane_height}' |
	awk -v sx="$sx" -v sy="$sy" '$1 == 1 {
		if ($2 != "")
			print $2;
		else
			print 1 + (2 * ($3 + $5 / 2 < sx / 2)) + ($4 + $6 / 2 > sy / 2);
	}')

pick=1
for c in 1 2 3 4; do
	case " $(echo $used) " in
	*" $c "*) ;;
	*) pick=$c; break ;;
	esac
done

case $pick in
1) x=$(( sx - sx / 2 )); y=0 ;;                  # top right
2) x=$(( sx - sx / 2 )); y=$(( sy - sy / 2 )) ;; # bottom right
3) x=0; y=0 ;;                                   # top left
4) x=0; y=$(( sy - sy / 2 )) ;;                  # bottom left
esac

echo $(( sx / 2 )) $(( sy / 2 )) "$x" "$y" "$pick"
