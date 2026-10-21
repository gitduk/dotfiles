#!/usr/bin/env bash
# notify-unfocused-version: 6
# Hyprland banner, suppressed when the terminal hosting this session is focused.
# Usage: notify-unfocused.sh <icon> <message>
#
# Detection, in order:
#   1. Ancestor chain — hooks run as descendants of the terminal process, so if
#      the focused window's PID is an ancestor of this process, the user is
#      already looking at this session. Works for plain terminals.
#   2. tmux fallback — inside tmux the ancestor chain dead-ends at the tmux
#      server (ppid 1), so instead check whether any tmux client of this
#      session is a descendant of the focused window's PID.
# Other multiplexers are not handled and fail open (always notify).

ICON="${1:-5}"
MSG="${2:-pi}"

command -v hyprctl &>/dev/null || exit 0
command -v jq &>/dev/null || exit 0

ACTIVE_PID=$(hyprctl activewindow -j 2>/dev/null | jq -r '.pid // empty')

# Returns 0 if ACTIVE_PID is an ancestor of $1 (within 30 hops).
is_focused_ancestor() {
  local pid=$1
  for ((i = 0; i < 30; i++)); do
    [[ "$pid" -le 1 ]] && return 1
    [[ "$pid" == "$ACTIVE_PID" ]] && return 0
    read -r pid < <(ps -o ppid= -p "$pid" 2>/dev/null) || return 1
    [[ -n "$pid" ]] || return 1
  done
  return 1
}

if [[ -n "$ACTIVE_PID" ]]; then
  is_focused_ancestor $$ && exit 0

  if [[ -n "${TMUX:-}" ]]; then
    # List clients attached to THIS session only, then walk each client's
    # ancestor chain upward — tmux client is a direct child of the terminal,
    # so ACTIVE_PID will appear within a few hops if the user is looking here.
    cur_session=$(tmux display-message -p '#S' 2>/dev/null)
    mapfile -t client_pids < <(tmux list-clients -t "$cur_session" -F '#{client_pid}' 2>/dev/null)
    for cpid in "${client_pids[@]}"; do
      is_focused_ancestor "$cpid" && exit 0
    done
  fi
fi

hyprctl notify "$ICON" 5000 0 "$MSG" || true
