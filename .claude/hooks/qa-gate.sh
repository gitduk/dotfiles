#!/usr/bin/env bash
# qa-gate-version: 2
# QA gate — blocks `git commit` unless all required qa categories for the
# project's language have been observed as passing since the last edit.
#
# Required categories per language (aligned with rules/languages.md):
#   rust    -> fmt, clippy, test
#   python  -> fmt, check, typecheck, test
#   js      -> test   (lint/typecheck enforced per-project via project CLAUDE.md)
#   unknown -> any single qa command (fallback for non-standard projects)
#
# Events:
#   PostToolUse Edit|Write|MultiEdit|NotebookEdit -> clear accumulated state
#   PostToolUse Bash (qa cmd, not errored)        -> record category passed
#   PreToolUse  Bash (git commit)                 -> deny if any required missing
#
# Escape: include literal token `QA-SKIP` anywhere in the bash command.
#
# State file: ~/.claude/session-env/qa-gate/<session_id>.state
# Contents  : space-separated "lang:category" tokens, e.g. "rust:fmt rust:clippy"
# Absent/empty: nothing has passed since last edit.

set -euo pipefail

command -v jq &>/dev/null || exit 0

INPUT=$(cat)
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$CWD" ] && CWD="$PWD"

STATE_DIR="$HOME/.claude/session-env/qa-gate"
mkdir -p "$STATE_DIR"
STATE_FILE="$STATE_DIR/${SESSION_ID}.state"

# Walk up from $1 looking for a project marker; echo rust|python|js|unknown.
detect_lang() {
  local cur="$1"
  local i
  for i in 1 2 3 4 5 6 7 8; do
    if [ -f "$cur/Cargo.toml" ]; then echo rust; return; fi
    if [ -f "$cur/pyproject.toml" ] || [ -f "$cur/uv.lock" ] || [ -f "$cur/requirements.txt" ]; then echo python; return; fi
    if [ -f "$cur/package.json" ]; then echo js; return; fi
    [ "$cur" = "/" ] && break
    cur=$(dirname "$cur")
  done
  echo unknown
}

# Map a bash command to a "lang:category" token, or empty if not a qa command.
# Emit one line per matched category; compound commands (&&/;) match multiple.
classify_qa() {
  local cmd="$1"
  local lang="$2"
  local matched=0
  case "$lang" in
    rust)
      [[ "$cmd" =~ cargo[[:space:]]+fmt ]]             && { echo "rust:fmt";    matched=1; }
      [[ "$cmd" =~ cargo[[:space:]]+clippy ]]          && { echo "rust:clippy"; matched=1; }
      [[ "$cmd" =~ cargo[[:space:]]+(test|nextest) ]]  && { echo "rust:test";   matched=1; }
      ;;
    python)
      [[ "$cmd" =~ ruff[[:space:]]+format ]]           && { echo "python:fmt";      matched=1; }
      [[ "$cmd" =~ ruff[[:space:]]+check ]]            && { echo "python:check";    matched=1; }
      [[ "$cmd" =~ (basedpyright|pyright|mypy) ]]      && { echo "python:typecheck"; matched=1; }
      [[ "$cmd" =~ (^|[^[:alnum:]_])pytest([^[:alnum:]_]|$) ]] && { echo "python:test"; matched=1; }
      ;;
    js)
      [[ "$cmd" =~ (^|[[:space:]])(bun|npm|pnpm|yarn)[[:space:]]+(run[[:space:]]+)?test ]] && { echo "js:test"; matched=1; }
      ;;
    unknown)
      if [[ "$cmd" =~ cargo[[:space:]]+(clippy|fmt|test|check) ]] \
         || [[ "$cmd" =~ ruff[[:space:]]+(check|format) ]] \
         || [[ "$cmd" =~ (basedpyright|pyright|mypy) ]] \
         || [[ "$cmd" =~ (^|[^[:alnum:]_])pytest([^[:alnum:]_]|$) ]] \
         || [[ "$cmd" =~ (^|[[:space:]])(bun|npm|pnpm|yarn)[[:space:]]+(run[[:space:]]+)?test ]]; then
        echo "any:qa"; matched=1
      fi
      ;;
  esac
  [ "$matched" -eq 0 ] && echo ""; return 0
}

required_for() {
  case "$1" in
    rust)    echo "rust:fmt rust:clippy rust:test" ;;
    python)  echo "python:fmt python:check python:typecheck python:test" ;;
    js)      echo "js:test" ;;
    unknown) echo "any:qa" ;;
  esac
}

has_passed() {
  [ -f "$STATE_FILE" ] || return 1
  [ -s "$STATE_FILE" ] || return 1
  [[ " $(cat "$STATE_FILE") " == *" $1 "* ]]
}

add_passed() {
  has_passed "$1" && return 0
  if [ -s "$STATE_FILE" ] 2>/dev/null; then
    printf ' %s' "$1" >>"$STATE_FILE"
  else
    printf '%s' "$1" >"$STATE_FILE"
  fi
}

clear_state() { : >"$STATE_FILE"; }

# Echo space-separated missing categories; empty if all required are present.
missing_required() {
  local lang="$1"
  local required; required=$(required_for "$lang")
  local missing="" cat
  for cat in $required; do
    if ! has_passed "$cat"; then
      missing+=" $cat"
    fi
  done
  echo "${missing## }"
}

is_git_commit() {
  [[ "$1" =~ (^|[[:space:]\;\&\|])((rtk[[:space:]]+)?git[[:space:]]+commit)([[:space:]\;\&\|]|$) ]]
}

has_skip_token() {
  [[ "$1" == *"QA-SKIP"* ]]
}

case "$EVENT" in
  PostToolUse)
    case "$TOOL" in
      Edit|Write|MultiEdit|NotebookEdit)
        clear_state
        ;;
      Bash)
        CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
        IS_ERR=$(echo "$INPUT" | jq -r '(.tool_response.is_error // .tool_response.interrupted // false) | tostring')
        [ "$IS_ERR" = "true" ] && exit 0
        LANG=$(detect_lang "$CWD")
        while IFS= read -r CAT; do
          [ -n "$CAT" ] && add_passed "$CAT"
        done < <(classify_qa "$CMD" "$LANG")
        ;;
    esac
    ;;

  PreToolUse)
    [ "$TOOL" = "Bash" ] || exit 0
    CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
    is_git_commit "$CMD" || exit 0
    has_skip_token "$CMD" && exit 0

    LANG=$(detect_lang "$CWD")
    MISSING=$(missing_required "$LANG")
    [ -z "$MISSING" ] && exit 0

    HINT=""
    case "$LANG" in
      rust)    HINT="cargo fmt && cargo clippy -- -D warnings && cargo test" ;;
      python)  HINT="uv run ruff format --check . && uv run ruff check . && uv run basedpyright . && uv run pytest" ;;
      js)      HINT="bun test  (or npm/pnpm/yarn test)" ;;
      unknown) HINT="run any recognized qa command (cargo clippy / ruff / pytest / bun test ...)" ;;
    esac
    REASON="QA gate [${LANG}]: 缺少通过记录 -> ${MISSING}. 请先跑: ${HINT}. 紧急跳过在命令里加 QA-SKIP (例: git commit -m 'msg  QA-SKIP')."

    jq -n --arg r "$REASON" '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": $r
      }
    }'
    ;;
esac

exit 0
