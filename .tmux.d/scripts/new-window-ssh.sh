#!/usr/bin/env zsh

_pane_info() {
  echo here
	pane_pid="$1"
	pane_tty="${2##/dev/}"

	ps -t "$pane_tty" --sort=lstart -o user=$USER -o pid= -o ppid= -o command= | awk -v pane_pid="$pane_pid" '
      ((/ssh/ && !/-W/ && !/tsh proxy ssh/ && !/sss_ssh_knownhostsproxy/) || !/ssh/) && !/tee/ {
        user[$2] = $1; if (!child[$3]) child[$3] = $2; pid=$2; $1 = $2 = $3 = ""; command[pid] = substr($0,4)
      }
      END {
        pid = pane_pid
        while (child[pid])
          pid = child[pid]

        print pid":"user[pid]":"command[pid]
      }
    '
}

pane_pid=$(tmux display -p '#{pane_pid}')
pane_tty=$(tmux display -p '#{b:pane_tty}')

pane_info=$(_pane_info "$pane_pid" "$pane_tty")
command=${pane_info#*:}
command=${command#*:}

case "$command" in
*mosh-client*)
	# shellcheck disable=SC2046
	tmux new-window "$@" mosh $(echo "$command" | sed -E -e 's/.*mosh-client -# (.*)\|.*$/\1/')
	;;
*ssh*)
	# shellcheck disable=SC2046
	tmux new-window "$@" $(echo "$command" | sed -e 's/;/\\;/g')
	;;
*)
	tmux new-window "$@"
	;;
esac
