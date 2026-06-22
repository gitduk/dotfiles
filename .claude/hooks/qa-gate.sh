#!/usr/bin/env bash
# qa-gate-version: 6
# QA gate — blocks `git commit` unless all required qa categories for the
# project's language have been observed as passing since the last code edit.
#
# rules/languages.md is the canonical QA definition; this script can't read
# prose, so required_for/hint_for_cat duplicate it — keep them in sync.
#
# Required categories per language (aligned with rules/languages.md):
#   rust    -> clippy (+ test only when a test suite is detected)
#   python  -> check, typecheck (+ test only when a test suite is detected)
#   js      -> test   (lint/typecheck enforced per-project via project CLAUDE.md)
#   unknown -> not gated
#
# NOTE: fmt is intentionally NOT required here. Formatting is owned by the
# global git pre-commit hook (~/.config/git/hooks/pre-commit), which runs
# cargo fmt / ruff format on staged files at commit time. Gating fmt here would
# block `git commit` before that hook ever runs. classify_qa still RECORDS a
# fmt run if one happens (harmless); it is simply never in required_for.
#
# Categories accumulate across separate Bash commands — checks do NOT need
# to be chained into one command.
#
# Events:
#   PostToolUse Edit|Write|MultiEdit|NotebookEdit -> clear accumulated state
#       (doc-only edits .md/.txt/.rst exempt; caveat: a Rust doctest reading
#        docs via include_str! won't be re-gated — cargo test still covers it)
#   PostToolUse Bash (qa cmd, not errored)        -> record category passed
#   PreToolUse  Bash (git commit)                 -> deny if any required missing;
#                                                    hint lists only what's missing
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

# Walk up from $1 looking for a project marker; echo "<lang> <root>".
detect_lang() {
  local cur="$1"
  local i
  for i in 1 2 3 4 5 6 7 8; do
    if [ -f "$cur/Cargo.toml" ]; then echo "rust $cur"; return; fi
    if [ -f "$cur/pyproject.toml" ] || [ -f "$cur/uv.lock" ] || [ -f "$cur/requirements.txt" ]; then echo "python $cur"; return; fi
    if [ -f "$cur/package.json" ]; then echo "js $cur"; return; fi
    [ "$cur" = "/" ] && break
    cur=$(dirname "$cur")
  done
  echo "unknown $1"
}

# Does the project at $2 (lang $1) have a test suite? Cheap heuristics only.
has_tests() {
  local lang="$1" root="$2"
  case "$lang" in
    rust)
      [ -d "$root/tests" ] && return 0
      grep -rqm1 --include='*.rs' --exclude-dir=target -e '#\[test\]' -e '#\[cfg(test)' "$root" 2>/dev/null
      ;;
    python)
      [ -d "$root/tests" ] && return 0
      [ -n "$(find "$root" -maxdepth 3 \( -name 'test_*.py' -o -name '*_test.py' \) -not -path '*/.venv/*' -print -quit 2>/dev/null)" ]
      ;;
    *) return 0 ;;
  esac
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
  local lang="$1" root="$2"
  case "$lang" in
    rust)
      if has_tests rust "$root"; then echo "rust:clippy rust:test"
      else echo "rust:clippy"; fi ;;
    python)
      if has_tests python "$root"; then echo "python:check python:typecheck python:test"
      else echo "python:check python:typecheck"; fi ;;
    js)      echo "js:test" ;;
    unknown) echo "" ;;
  esac
}

# Suggested command for one missing category.
hint_for_cat() {
  case "$1" in
    rust:fmt)         echo "cargo fmt" ;;
    rust:clippy)      echo "cargo clippy -- -D warnings" ;;
    rust:test)        echo "cargo test" ;;
    python:fmt)       echo "uv run ruff format --check ." ;;
    python:check)     echo "uv run ruff check ." ;;
    python:typecheck) echo "uv run basedpyright ." ;;
    python:test)      echo "uv run pytest" ;;
    js:test)          echo "bun test (or npm/pnpm/yarn test)" ;;
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
  local lang="$1" root="$2"
  local required; required=$(required_for "$lang" "$root")
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

# Returns 0 (true) if no staged file is a code file for the given language.
# Rust  -> *.rs; Python -> *.py; JS -> *.js *.ts *.jsx *.tsx; unknown -> always has code.
has_no_code_staged() {
  local lang="$1" root="$2"
  local staged
  staged=$(git -C "$root" diff --cached --name-only 2>/dev/null) || return 1
  [ -z "$staged" ] && return 1
  local pat
  case "$lang" in
    rust)   pat='\.rs$' ;;
    python) pat='\.py$' ;;
    js)     pat='\.\(js\|ts\|jsx\|tsx\|mjs\|cjs\)$' ;;
    *)      return 1 ;;  # unknown lang: don't skip gate
  esac
  grep -qm1 "$pat" <<< "$staged" && return 1
  return 0
}

case "$EVENT" in
  PostToolUse)
    case "$TOOL" in
      Edit|Write|MultiEdit|NotebookEdit)
        FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')
        case "$FILE" in
          *.md|*.txt|*.rst) ;;  # doc-only edits can't break compile/lint/test state
          *) clear_state ;;
        esac
        ;;
      Bash)
        CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
        IS_ERR=$(echo "$INPUT" | jq -r '(.tool_response.is_error // .tool_response.interrupted // false) | tostring')
        [ "$IS_ERR" = "true" ] && exit 0
        DETECTED=$(detect_lang "$CWD")
        PROJ_LANG=${DETECTED%% *}
        while IFS= read -r CAT; do
          [ -n "$CAT" ] && add_passed "$CAT"
        done < <(classify_qa "$CMD" "$PROJ_LANG")
        ;;
    esac
    ;;

  PreToolUse)
    [ "$TOOL" = "Bash" ] || exit 0
    CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
    is_git_commit "$CMD" || exit 0
    has_skip_token "$CMD" && exit 0

    DETECTED=$(detect_lang "$CWD")
    PROJ_LANG=${DETECTED%% *}
    PROJ_ROOT=${DETECTED#* }
    has_no_code_staged "$PROJ_LANG" "$PROJ_ROOT" && exit 0
    MISSING=$(missing_required "$PROJ_LANG" "$PROJ_ROOT")
    [ -z "$MISSING" ] && exit 0

    HINT=""
    for CAT in $MISSING; do
      C=$(hint_for_cat "$CAT")
      [ -z "$C" ] && continue
      [ -n "$HINT" ] && HINT+=" && "
      HINT+="$C"
    done
    REASON="QA gate [${PROJ_LANG}]: 缺少通过记录 -> ${MISSING}. 只需补跑: ${HINT}. 紧急跳过在命令里加 QA-SKIP (例: git commit -m 'msg  QA-SKIP').\n被拦截的完整命令（需重跑）:\n${CMD}"
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
