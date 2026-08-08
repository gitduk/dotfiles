#!/usr/bin/env bash
# stash-gate-version: 1
# PreToolUse(Bash) gate: block git ops that permanently destroy uncommitted
# working-tree changes (checkout pathspec, restore, reset --hard, clean -f)
# while the target repo is dirty; stash drop|clear always.
# "never discard directly": stash first, or the user explicitly confirms.
# Escape: literal token STASH-SKIP in the command, only after that confirmation.
# Known gap: pathspec forms without `--` (`git checkout HEAD f`, `checkout ./d`).

set -euo pipefail
command -v jq &>/dev/null || exit 0

INPUT=$(cat)
[ "$(jq -r '.tool_name // empty' <<<"$INPUT")" = "Bash" ] || exit 0
CMD=$(jq -r '.tool_input.command // empty' <<<"$INPUT")
[ -z "$CMD" ] && exit 0
[[ "$CMD" != *git* ]] && exit 0
[[ "$CMD" == *STASH-SKIP* ]] && exit 0

# Subcommand must directly follow git (+ passthrough opts) — a bare
# `.*` bridge would false-positive on words inside commit messages.
GITPRE='(^|[^[:alnum:]_-])git[[:space:]]+((-C|-c)[[:space:]]+[^[:space:]]+[[:space:]]+|--[[:alnum:]-]+=[^[:space:]]+[[:space:]]+)*'

has() { grep -qE "$1" <<<"$CMD"; }

deny() {
  jq -n --arg r "$1"$'\n'"拦截的命令：$CMD" '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": $r
    }
  }'
  exit 0
}

if has "${GITPRE}stash[[:space:]]+(drop|clear)([[:space:]]|\$)"; then
  deny "stash 里可能是内容的唯一副本，drop/clear 会永久销毁。需要用户明确确认；确认后在命令中加 STASH-SKIP 重试。"
fi

destructive=0
has "${GITPRE}checkout([[:space:]][^;&|]*)?[[:space:]]--([[:space:]]|\$)" && destructive=1
has "${GITPRE}checkout[[:space:]]+\.[[:space:]]*(\$|[;&|])" && destructive=1
has "${GITPRE}reset[[:space:]]([^;&|]*[[:space:]])?--hard([[:space:]]|\$)" && destructive=1
has "${GITPRE}clean[[:space:]]([^;&|]*[[:space:]])?(-[[:alnum:]]*f|--force)" && destructive=1
if has "${GITPRE}restore([[:space:]]|\$)"; then
  # --staged-only restore leaves the working tree untouched
  if ! has "${GITPRE}restore[^;&|]*--staged" || has "${GITPRE}restore[^;&|]*(--worktree|-W)([[:space:]]|\$)"; then
    destructive=1
  fi
fi
[ "$destructive" = 1 ] || exit 0

CRE='git[[:space:]]+-C[[:space:]]+([^[:space:]]+)'
CDRE='(^|[;&|
][[:space:]]*)cd[[:space:]]+([^[:space:];&|]+)'
repo=""
if [[ "$CMD" =~ $CRE ]]; then
  repo="${BASH_REMATCH[1]}"
elif [[ "$CMD" =~ $CDRE ]]; then
  repo="${BASH_REMATCH[2]}"
else
  repo=$(jq -r '.cwd // empty' <<<"$INPUT")
fi
[ -z "$repo" ] && repo="$PWD"
repo="${repo#[\"\']}"; repo="${repo%[\"\']}"; repo="${repo/#\~/$HOME}"

dirty=$(git -C "$repo" status --porcelain 2>/dev/null | head -c 1 || true)
[ -n "$dirty" ] || exit 0

deny "目标仓库（$repo）有未提交改动，此命令会把它们永久丢弃。先分开两步看清楚：git status 与 git diff <target>；要保留就先 git stash push -m \"<why>\"（可逆）再重试。仅当用户明确确认丢弃时，在命令中加 STASH-SKIP。"
