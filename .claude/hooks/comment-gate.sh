#!/usr/bin/env bash
# comment-gate: flags long runs of plain comments added via Edit/Write.
#
# rules/code_quality.md says comments default to none; a genuine WHY gets
# compressed to one line. That's a prose rule the model competes against its
# own generation prior on, and loses (see memory tool-pref-enforcement-via-hook
# for the same failure mode with tool preferences). This hook gives it a
# mechanical nudge at write time instead.
#
# Detection: a run of >= THRESHOLD consecutive plain-comment lines in the
# newly-written text triggers a PostToolUse "block" (advisory, not a real
# block — it just re-injects the reason for the model to act on). Run-length,
# not comment/code ratio, so a long comment block can't be diluted by pairing
# it with a big pile of unrelated code in the same Edit/Write call.
#
# Exemptions (checked per run, not per file):
#   - doc comments (rust /// //! , JS/TS /** */) — transparent, don't count
#   - shebang line (sh/bash/zsh line 1)
#   - license/header blocks (Copyright / SPDX-License-Identifier)
#   - Write calls, run starting within the first 5 lines (file header)
#   - escape hatch: literal token comment-gate:allow anywhere in the run
#
# Unknown file extensions are not gated (miss over false-positive).

set -euo pipefail

command -v jq &>/dev/null || exit 0

THRESHOLD=4

INPUT=$(cat)
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')
[ "$EVENT" = "PostToolUse" ] || exit 0

TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
case "$TOOL" in
  Edit)  TEXT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty') ;;
  Write) TEXT=$(echo "$INPUT" | jq -r '.tool_input.content // empty') ;;
  *) exit 0 ;;
esac
[ -z "$TEXT" ] && exit 0

FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

case "$FILE" in
  *.rs) FAMILY=rust ;;
  *.js|*.ts|*.jsx|*.tsx|*.mjs|*.cjs|*.c|*.h|*.cpp|*.cc|*.hpp|*.go|*.java|*.html|*.htm) FAMILY=cstyle ;;
  *.py|*.sh|*.bash|*.zsh|*.toml|*.yaml|*.yml) FAMILY=hash ;;
  *) exit 0 ;;
esac

RESULT=$(printf '%s\n' "$TEXT" | awk -v family="$FAMILY" -v tool="$TOOL" -v threshold="$THRESHOLD" '
  function eval_run() {
    if (count >= threshold) {
      header_exempt = (tool == "Write" && run_start <= 5) ? 1 : 0
      if (!run_license && !run_allow && !header_exempt && !triggered) {
        triggered = 1; trig_line = run_start; trig_count = count
      }
    }
    count = 0; run_license = 0; run_allow = 0
  }
  {
    line = $0
    t = line
    sub(/^[ \t]+/, "", t)

    if (line ~ /Copyright/ || line ~ /SPDX-License-Identifier/) run_license_line = 1
    else run_license_line = 0
    if (line ~ /comment-gate:allow/) run_allow_line = 1
    else run_allow_line = 0

    is_comment = 0
    is_transparent = 0

    if (family == "rust") {
      if (t ~ /^\/\/\// || t ~ /^\/\/!/) is_transparent = 1
      else if (t ~ /^\/\//) is_comment = 1
    } else if (family == "cstyle") {
      if (in_docblock) {
        is_transparent = 1
        if (line ~ /\*\//) in_docblock = 0
      } else if (in_block) {
        is_comment = 1
        if (line ~ /\*\//) in_block = 0
      } else if (t ~ /^\/\*\*/) {
        is_transparent = 1
        in_docblock = 1
        if (line ~ /\*\//) in_docblock = 0
      } else if (t ~ /^\/\*/) {
        is_comment = 1
        in_block = 1
        if (line ~ /\*\//) in_block = 0
      } else if (t ~ /^\/\//) {
        is_comment = 1
      }
    } else if (family == "hash") {
      if (NR == 1 && t ~ /^#!/) is_transparent = 1
      else if (t ~ /^#/) is_comment = 1
    }

    if (is_transparent) next

    if (is_comment) {
      if (count == 0) run_start = NR
      count++
      if (run_license_line) run_license = 1
      if (run_allow_line) run_allow = 1
    } else {
      eval_run()
    }
  }
  END {
    eval_run()
    if (triggered) print "BLOCK\t" trig_line "\t" trig_count
    else print "OK"
  }
')

STATUS="${RESULT%%$'\t'*}"
[ "$STATUS" = "OK" ] && exit 0

LINE=$(echo "$RESULT" | cut -f2)
CNT=$(echo "$RESULT" | cut -f3)

REASON="comment-gate: 检测到连续 ${CNT} 行注释块（${FILE}:${LINE} 起）。规则（code_quality.md）：注释默认不写；确属 non-obvious 的 WHY 压缩为一行（<80 chars 单子句）；完整推理写进 commit message，不留在代码里。请把该注释块改写为至多一行，或确认属豁免场景（doc comment / license / 用户明确要求，则在块内加 comment-gate:allow）。"

jq -n --arg r "$REASON" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: $r
  }
}'
