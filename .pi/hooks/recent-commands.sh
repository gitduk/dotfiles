#!/usr/bin/env bash
# pi `run.start` hook: tell the model which shell commands the user ran in the
# workspace since the last run started (at most an hour back), oldest first.
set -euo pipefail

limit=10
history=${ZHIS_FILE:-$HOME/.local/share/zhis/history.jsonl}
workspace=$(jq -r '.workspace // empty')
workspace=${workspace:-$PWD}
key=$(printf %s "$workspace" | sha1sum | cut -c1-12)
state=${PI_HOOK_STATE:-$HOME/.pi/hooks}/.recent-commands.$key
now=$((${EPOCHREALTIME/./} / 1000))
since=$(cat "$state" 2>/dev/null || true)
[[ $since =~ ^[0-9]+$ ]] && ((since > now - 3600000)) || since=$((now - 3600000))
mkdir -p "${state%/*}"
echo "$now" >"$state"

# A command counts once it has finished, so it is told by when it ended.
new=$(jq -rs --arg dir "$workspace" --argjson since "$since" --argjson limit "$limit" '
    [.[] | select(.d == $dir and .t * 1000 + .m > $since)
         | select(.c | test("^\\s*(zhis|pi)(\\s|$)|/pi(\\s|$)") | not)]
    | reduce .[] as $e ([];
        if length > 0 and .[-1].c == $e.c and .[-1].x == $e.x
        then .[-1].n += 1 else . + [$e + {n: 1}] end) as $all
    | $all[-$limit:] as $shown
    | ($all[:-$limit] | map(.n) | add // 0) as $hidden
    | [$shown[] | if .x == 0 then "ok" else "exit \(.x)" end] as $status
    | ($status | map(length) | max) as $width
    | (if $hidden > 0 then "  (\($hidden) earlier not shown)" else empty end),
      ($shown | to_entries[]
        | ($status[.key] + ((" " * ($width - ($status[.key] | length))) // "")) as $s
        | "  \($s)  \(.value.c | gsub("\\s*\n\\s*"; " ⏎ "))\(if .value.n > 1 then "  (×\(.value.n))" else "" end)")
' "$history")

[ -n "$new" ] || exit 0
echo "For context, not a request: commands the user ran in their own terminal in this workspace since the last message, oldest first, with how each exited; (×N) marks a command run N times in a row."
echo "$new"
