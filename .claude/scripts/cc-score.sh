#!/usr/bin/env bash
# cc-score: the single health check for the Claude Code environment.
# Score = passed/total binary assertions, no weights. Trend: ~/.claude/cc-score.log.
# Manifests (TOOLS, phrase pairs, duplicate stacks) are contract — update on dependency changes.

set -uo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
MEM_DIR="$CLAUDE_DIR/projects/-home-wukaige/memory"
LAYERS="rules hooks skills plugins mcp memory"
declare -A LP LF

pass() { printf '  ok  [%s] %s\n' "$1" "$2"; LP[$1]=$(( ${LP[$1]:-0} + 1 )); }
fail() { printf 'FAIL  [%s] %s\n' "$1" "$2"; LF[$1]=$(( ${LF[$1]:-0} + 1 )); }

echo "== rules: referenced tools installed and still mentioned"
TOOLS="rtk atuin xh wl-copy bun uv cargo jq podman ast-grep basedpyright ruff git pgrep"
for t in $TOOLS; do
  if ! command -v "$t" >/dev/null 2>&1; then
    fail rules "tool not installed: $t"
  elif ! grep -rqFw "$t" "$CLAUDE_DIR/rules" "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/RTK.md"; then
    fail rules "manifest entry no longer mentioned in any rule: $t (drop it here)"
  else
    pass rules "tool: $t"
  fi
done

# forward heuristic: backticked first-words that exist as commands but aren't in TOOLS
mentioned=$(grep -rhoE '`[a-z][a-z0-9_ -]*`' "$CLAUDE_DIR/rules" "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/RTK.md" \
  | tr -d '\`' | awk '{print $1}' | sort -u)
suggest=""
for m in $mentioned; do
  case " $TOOLS " in *" $m "*) continue ;; esac
  if type -P "$m" >/dev/null 2>&1; then suggest="$suggest $m"; fi
done
[ -n "$suggest" ] && echo "  info: mentioned in rules, runnable, but not in TOOLS manifest — add real dependencies:$suggest"

echo "== rules: file references resolve"
while IFS=: read -r src ref; do
  case "$ref" in *://*|*'$'*|*'*'*) continue ;; esac
  base="${ref##*/}"
  if [ -e "$CLAUDE_DIR/rules/$base" ] || [ -e "$CLAUDE_DIR/$base" ] \
     || [ -e "$CLAUDE_DIR/hooks/$base" ] || [ -e "$CLAUDE_DIR/scripts/$base" ] \
     || [ -e "${ref/#\~/$HOME}" ]; then
    pass rules "$(basename "$src") -> $ref"
  else
    fail rules "dead reference in $(basename "$src"): $ref"
  fi
done < <(grep -roE '[A-Za-z0-9_~/.-]*[A-Za-z0-9_-]+\.(md|sh)' "$CLAUDE_DIR/rules" "$CLAUDE_DIR/CLAUDE.md" | sort -u)

echo "== rules: shared phrases stay verbatim"
while IFS='|' read -r phrase f1 f2; do
  [ -z "$phrase" ] && continue
  drift=0
  for f in "$f1" "$f2"; do
    if ! grep -qF "$phrase" "$CLAUDE_DIR/$f"; then
      fail rules "phrase drift: \"$phrase\" missing from $f"; drift=1
    fi
  done
  if [ "$drift" = 0 ]; then pass rules "phrase: \"$phrase\""; fi
done <<'EOF'
default to none|rules/comments.md|hooks/comment-gate.sh
would refactoring the adjacent code force this comment to change|rules/comments.md|hooks/comment-gate.sh
compress to at most two short lines|rules/comments.md|hooks/comment-gate.sh
EOF

echo "== hooks: commands wired in settings.json exist"
while IFS= read -r cmd; do
  [ -z "$cmd" ] && continue
  first=${cmd%% *}
  case "$first" in
    "~/"*|/*)
      f="${first/#\~/$HOME}"
      if [ -x "$f" ]; then pass hooks "wired: $first"; else fail hooks "wired but missing/not executable: $first"; fi
      ;;
    *)
      if command -v "$first" >/dev/null 2>&1; then pass hooks "wired: $first"; else fail hooks "wired but not found: $first"; fi
      ;;
  esac
done < <(jq -r '.hooks[][]?.hooks[]?.command // empty' "$CLAUDE_DIR/settings.json" | sort -u)

echo "== hooks: scripts syntax-clean and executable"
for f in "$CLAUDE_DIR"/hooks/*.sh; do
  b=$(basename "$f")
  if bash -n "$f" 2>/dev/null; then pass hooks "syntax: $b"; else fail hooks "syntax error: $b"; fi
  if [ -x "$f" ]; then pass hooks "executable: $b"; else fail hooks "not executable: $b"; fi
done

echo "== skills: every directory is a loadable skill"
for d in "$CLAUDE_DIR"/skills/*/; do
  b=$(basename "$d")
  if [ -f "$d/SKILL.md" ] && grep -q '^description:' "$d/SKILL.md"; then
    pass skills "$b"
  else
    fail skills "$b: no SKILL.md with description — never loads"
  fi
done

echo "== plugins: enabled installed; project installs not orphaned"
while IFS= read -r p; do
  if jq -e --arg k "$p" '.plugins[$k]' "$CLAUDE_DIR/plugins/installed_plugins.json" >/dev/null 2>&1; then
    pass plugins "enabled+installed: $p"
  else
    fail plugins "enabled but not installed: $p"
  fi
done < <(jq -r '.enabledPlugins | to_entries[] | select(.value==true) | .key' "$CLAUDE_DIR/settings.json")
while IFS=$'\t' read -r k path; do
  [ -z "$k" ] && continue
  if [ -d "$path" ]; then
    pass plugins "project install alive: $k ($path)"
  else
    fail plugins "orphaned project install (project gone): $k ($path)"
  fi
done < <(jq -r '.plugins | to_entries[] | .key as $k | .value[] | select(.scope=="project") | "\($k)\t\(.projectPath)"' "$CLAUDE_DIR/plugins/installed_plugins.json")
dormant=$(jq -r --slurpfile s "$CLAUDE_DIR/settings.json" \
  '.plugins | to_entries[] | select(any(.value[]; .scope=="user")) | .key | select(($s[0].enabledPlugins[.] // false) | not)' \
  "$CLAUDE_DIR/plugins/installed_plugins.json" | tr '\n' ' ')
[ -n "$dormant" ] && echo "  info: user-scope installed but disabled (dormant): $dormant"

echo "== mcp: manual servers minimal and alive"
n=$(jq -r '.mcpServers // {} | length' "$HOME/.claude.json")
if [ "$n" = 0 ]; then
  pass mcp "no manual MCP servers (plugins own capabilities)"
else
  while IFS=$'\t' read -r name cmd; do
    [ -z "$name" ] && continue
    if command -v "$cmd" >/dev/null 2>&1; then pass mcp "$name (command: $cmd)"; else fail mcp "$name: command not found: $cmd"; fi
  done < <(jq -r '.mcpServers // {} | to_entries[] | "\(.key)\t\(.value.command)"' "$HOME/.claude.json")
fi
while IFS='|' read -r srv plg; do
  [ -z "$srv" ] && continue
  if jq -e --arg k "$srv" '.mcpServers[$k]' "$HOME/.claude.json" >/dev/null 2>&1 \
     && jq -e --arg k "$plg" '.enabledPlugins[$k] == true' "$CLAUDE_DIR/settings.json" >/dev/null 2>&1; then
    fail mcp "duplicate stack: mcpServers[$srv] duplicates plugin $plg"
  else
    pass mcp "no duplicate: $srv vs $plg"
  fi
done <<'EOF'
chrome-devtools-debug|chrome-devtools-mcp@chrome-devtools-plugins
EOF
echo "  info: runtime liveness (plugin MCP server died) not checkable offline — use /mcp in a session"

echo "== memory: single location, index complete"
if [ ! -e "$HOME/.claude/memory" ]; then
  pass memory "no stranded legacy directory (~/.claude/memory)"
else
  fail memory "legacy ~/.claude/memory exists again — data stranded outside recall path"
fi
if [ -f "$MEM_DIR/MEMORY.md" ]; then
  pass memory "MEMORY.md index exists"
  for f in "$MEM_DIR"/*.md; do
    b=$(basename "$f"); [ "$b" = "MEMORY.md" ] && continue
    if grep -qF "($b)" "$MEM_DIR/MEMORY.md"; then pass memory "indexed: $b"; else fail memory "unindexed memory file: $b"; fi
  done
  while IFS= read -r t; do
    [ -z "$t" ] && continue
    if [ -f "$MEM_DIR/$t" ]; then pass memory "link resolves: $t"; else fail memory "dead index link: $t"; fi
  done < <(grep -oP '\]\(\K[^)]+' "$MEM_DIR/MEMORY.md")
else
  fail memory "MEMORY.md index missing"
fi

echo
echo "== score"
TOTAL_P=0; TOTAL_F=0
for l in $LAYERS; do
  p=${LP[$l]:-0}; f=${LF[$l]:-0}
  printf '%-8s %d/%d\n' "$l" "$p" "$((p+f))"
  TOTAL_P=$((TOTAL_P+p)); TOTAL_F=$((TOTAL_F+f))
done
TOTAL=$((TOTAL_P+TOTAL_F))
PCT=$(( TOTAL_P * 100 / TOTAL ))
if   [ "$PCT" -ge 95 ]; then BAND="healthy"
elif [ "$PCT" -ge 80 ]; then BAND="needs attention"
else BAND="rotting"; fi
printf 'overall  %d/%d (%d%%) — %s\n' "$TOTAL_P" "$TOTAL" "$PCT" "$BAND"
printf '%s %d%% %d/%d\n' "$(date +%F)" "$PCT" "$TOTAL_P" "$TOTAL" >> "$CLAUDE_DIR/cc-score.log"
[ "$TOTAL_F" = 0 ]
