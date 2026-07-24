#!/usr/bin/env bash
# cmd-gate-version: 1
# PreToolUse(Bash) gate: block commands starting with a deprecated prefix
# configured in cmd-gate.conf, suggest the replacement instead.
#
# Rules are advisory-text, not auto-rewritten: replacement syntax often isn't
# a literal word swap (curl flags vs xh's httpie-style args, find vs fd), so
# the caller re-derives the actual command from the suggestion.
#
# Escape: include literal token ALIAS-SKIP anywhere in the bash command.

set -euo pipefail

command -v jq &>/dev/null || exit 0

CONF="$HOME/.claude/hooks/cmd-gate.conf"
[ -f "$CONF" ] || exit 0

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
[ "$TOOL" = "Bash" ] || exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$CMD" ] && exit 0
[[ "$CMD" == *"ALIAS-SKIP"* ]] && exit 0

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$CWD" ] && CWD="$PWD"

trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; echo -n "$s"; }

while IFS= read -r LINE; do
  LINE="${LINE%%#*}"
  [[ -z "${LINE// }" ]] && continue
  [[ "$LINE" != *'=>'* ]] && continue

  RULE="${LINE%%'|'*}"
  COND=""
  [[ "$LINE" == *'|'* ]] && COND=$(trim "${LINE#*'|'}")

  FROM=$(trim "${RULE%%'=>'*}")
  TO=$(trim "${RULE#*'=>'}")
  [ -z "$FROM" ] && continue

  ESC_FROM=$(printf '%s' "$FROM" | sed -e 's/[][\.^$*+?(){}|]/\\&/g')
  # Boundary must be a real command separator (or newline/start), not plain
  # whitespace — otherwise "update npm run docs" in a commit message would
  # false-positive just because a space precedes the trigger word.
  NL=$'\n'
  PATTERN="(^|[;\&|(]|${NL})[[:space:]]*${ESC_FROM}([[:space:]]|\$)"

  if [[ "$CMD" =~ $PATTERN ]]; then
    if [ -n "$COND" ] && (cd "$CWD" 2>/dev/null && eval "$COND") 2>/dev/null; then
      continue
    fi
    REASON="命令别名策略: 用 \`${TO}\` 代替 \`${FROM}\`.\n拦截的命令: ${CMD}\n临时跳过在命令里加 ALIAS-SKIP."
    jq -n --arg r "$REASON" '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": $r
      }
    }'
    exit 0
  fi
done < "$CONF"

exit 0
