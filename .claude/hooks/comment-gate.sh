#!/usr/bin/env bash
# comment-gate: flags long runs of plain comments added via Edit/Write.
# Design rationale: ~/.claude/plans/comment-gate-hook.md
#
# For Edit, lines already in old_string are subtracted — only fresh output is judged.
# Unknown file extensions are not gated (miss over false-positive).

set -euo pipefail

command -v jq &>/dev/null || exit 0

THRESHOLD=3
# position alone isn't proof of a real header — raise the room, keep a cap.
HEADER_THRESHOLD=9

INPUT=$(cat)
IFS=$'\t' read -r EVENT TOOL FILE \
  <<<"$(jq -r '[.hook_event_name, .tool_name, .tool_input.file_path] | @tsv' <<<"$INPUT")"
[ "$EVENT" = "PostToolUse" ] || exit 0

# resolve the family before reading the payload text: most writes are to
# ungated extensions and can bail here without a second jq spawn
case "${FILE##*/}" in
  Dockerfile|Dockerfile.*|Containerfile|Makefile|makefile|GNUmakefile|.env|.env.*|.gitignore|.dockerignore) FAMILY=hash ;;
  *.rs) FAMILY=rust ;;
  *.html|*.htm|*.xml|*.svg|*.vue|*.svelte) FAMILY=html ;;
  *.css|*.scss|*.sass|*.less) FAMILY=css ;;
  *.sql|*.lua) FAMILY=dash ;;
  *.php) FAMILY=php ;;
  *.tf|*.tfvars|*.hcl) FAMILY=hcl ;;
  *.conf|*.ini|*.cfg) FAMILY=ini ;;
  *.js|*.ts|*.jsx|*.tsx|*.mjs|*.cjs|*.c|*.h|*.cpp|*.cc|*.hpp|*.go|*.java) FAMILY=cstyle ;;
  *.py|*.sh|*.bash|*.zsh|*.toml|*.yaml|*.yml|*.rb|*.fish|*.nix) FAMILY=hash ;;
  *) exit 0 ;;
esac

case "$TOOL" in
  Edit)  TEXT=$(jq -r '.tool_input.new_string // empty' <<<"$INPUT")
         PRIOR=$(jq -r '.tool_input.old_string // empty' <<<"$INPUT") ;;
  Write) TEXT=$(jq -r '.tool_input.content // empty' <<<"$INPUT")
         PRIOR="" ;;
  *) exit 0 ;;
esac
[ -z "$TEXT" ] && exit 0

RESULT=$(awk -v family="$FAMILY" -v tool="$TOOL" -v threshold="$THRESHOLD" -v header_threshold="$HEADER_THRESHOLD" '
  function eval_run(   eff) {
    eff = (run_is_header ? header_threshold : threshold)
    if (count >= eff && !run_exempt && !triggered) {
      triggered = 1; trig_line = run_start; trig_count = count
    }
    count = 0; run_exempt = 0; run_is_header = 0
  }
  function nopen(s) { return gsub(/\/\*/, "", s) }
  function nclose(s) { return gsub(/\*\//, "", s) }
  function close_block(s) {
    if (blk == BLK_ALT) {
      if (s ~ curclose) blk = 0
    } else if (nest) {
      depth += nopen(s) - nclose(s)
      if (depth <= 0) blk = 0
    } else if (nclose(s) > 0) blk = 0
  }
  BEGIN {
    BLK_PLAIN = 1; BLK_ALT = 2
    linecmt = "^//"
    if (family == "rust")        { nest = 1 }
    # php and hcl take # as a line comment too; C-family does not (#include)
    # php8 attributes start #[ and must not read as comments
    else if (family == "php")    { linecmt = "^(//|#($|[^[]))" }
    else if (family == "hcl")    { linecmt = "^(#|//)" }
    else if (family == "hash")   { linecmt = "^#" }
    else if (family == "ini")    { linecmt = "^(#|;)" }
    else if (family == "html")   { altopen = "^<!--"; altclose = "-->" }
    # lua long brackets carry a variable = run that the closer must mirror
    else if (family == "dash")   { linecmt = "^--"
                                   altopen = "^--\\[=*\\["; altvar = 1 }
  }
  NR == FNR { if ($0 != "") prior[$0]++; next }
  {
    # a preserved line is real content, so it breaks any run it sits between
    if (($0 in prior) && prior[$0] > 0) { prior[$0]--; eval_run(); next }

    t = $0
    sub(/^[ \t]+/, "", t)

    is_comment = 0
    is_transparent = 0
    entering = !blk

    if (t == "" || (FNR == 1 && t ~ /^#!/)) {
      is_transparent = 1
    } else if (family == "hash" || family == "ini") {
      if (t ~ linecmt) is_comment = 1
    } else {
      if (blk) {
        is_comment = 1
      } else if (t ~ /^\/\*/) {
        is_comment = 1
        blk = BLK_PLAIN
      } else if (altopen != "" && t ~ altopen) {
        is_comment = 1
        blk = BLK_ALT
        curclose = altclose
        # RLENGTH spans --[ and [ around the = run the closer has to mirror
        if (altvar) { match(t, altopen); curclose = "\\]" substr(t, RSTART + 3, RLENGTH - 4) "\\]" }
      } else if (t ~ linecmt) {
        is_comment = 1
      }
      if (blk) { if (entering) depth = 0; close_block($0) }
    }

    if (is_transparent) next

    if (is_comment) {
      if (count == 0) { run_start = FNR; run_is_header = (tool == "Write" && !seen_content) }
      count++
      if ($0 ~ /Copyright|SPDX-License-Identifier|comment-gate:allow/) run_exempt = 1
    } else {
      eval_run()
      seen_content = 1
    }
  }
  END {
    eval_run()
    if (triggered) print trig_line "\t" trig_count
  }
' <(printf '%s\n' "$PRIOR") <(printf '%s\n' "$TEXT"))

[ -z "$RESULT" ] && exit 0
IFS=$'\t' read -r LINE CNT <<<"$RESULT"

REASON="comment-gate: this write to ${FILE} added a ${CNT}-line comment run (from line ${LINE} of the written text). Rule (comments.md): default to none; public API doc comments are interface contract and exempt from the default, but long runs still get trimmed. File-header docs (script/module level) get a relaxed threshold of ${HEADER_THRESHOLD} lines — not unlimited. Test each line: would refactoring the adjacent code force this comment to change? Yes → it restates the implementation, drop it. No → it describes a constraint outside the code — compress to at most two short lines, each a single clause under ~80 chars; move the fuller explanation to the commit message. Legitimate exemptions (real file-header docs / license / explicit user request): add comment-gate:allow inside the block."

jq -n --arg r "$REASON" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: $r
  }
}'
