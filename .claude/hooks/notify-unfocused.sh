#!/usr/bin/env bash
# notify-unfocused-version: 2
# Hyprland banner, suppressed when the terminal hosting this session is focused.
# Usage: notify-unfocused.sh <icon> <message>
#
# Detection, in order:
#   1. Ancestor chain — hooks run as descendants of the terminal process, so if
#      the focused window's PID is an ancestor of this process, the user is
#      already looking at this session. Works for plain terminals.
#   2. Zellij fallback — inside zellij the ancestor chain dead-ends at the mux
#      server (ppid 1), so instead check whether the focused window has a
#      descendant zellij client attached to $ZELLIJ_SESSION_NAME.
# tmux/screen are not handled and fail open (always notify).

ICON="${1:-5}"
MSG="${2:-Claude Code}"

command -v hyprctl &>/dev/null || exit 0
command -v jq &>/dev/null || exit 0

ACTIVE_PID=$(hyprctl activewindow -j 2>/dev/null | jq -r '.pid // empty')

if [[ -n "$ACTIVE_PID" ]]; then
  pid=$$
  for _ in $(seq 1 30); do
    [[ "$pid" -le 1 ]] && break
    if [[ "$pid" == "$ACTIVE_PID" ]]; then
      exit 0
    fi
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ') || break
    [[ -n "$pid" ]] || break
  done

  if [[ -n "${ZELLIJ:-}" ]]; then
    if ps -e -o pid=,ppid=,args= | awk -v root="$ACTIVE_PID" -v sess="${ZELLIJ_SESSION_NAME:-}" '
      { pid[NR]=$1; ppid[NR]=$2; $1=""; $2=""; cmd[NR]=$0 }
      END {
        seen[root]=1; changed=1
        while (changed) {
          changed=0
          for (i=1; i<=NR; i++)
            if (!(pid[i] in seen) && (ppid[i] in seen)) { seen[pid[i]]=1; changed=1 }
        }
        for (i=1; i<=NR; i++) {
          if (!(pid[i] in seen)) continue
          if (cmd[i] !~ /(^|[ \/])zellij( |$)/ || cmd[i] ~ /--server/) continue
          # client with an explicit session arg must match ours; bare client assumed ours
          if (sess == "" || cmd[i] !~ /attach/ || index(cmd[i], sess) > 0) { found=1; break }
        }
        exit found ? 0 : 1
      }'; then
      exit 0
    fi
  fi
fi

hyprctl notify "$ICON" 5000 0 "$MSG" || true
