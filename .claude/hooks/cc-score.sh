#!/usr/bin/env bash
# cc-score: the single health check for the Claude Code environment.
# Score = layers passed/6 for the statusline; assertion detail in interactive dump.
# Trend: per-project log in the cache dir: ~/.cache/claude/cc-score-<slug>.log.
# Manifests (TOOLS, phrase pairs, duplicate stacks) are contract — update on dependency changes.
#
# Usage: cc-score.sh [--hook] [project_dir]  (project_dir default: $PWD)

set -uo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CACHE_DIR="$HOME/.cache/claude"
LAYERS="rules hooks skills plugins mcp memory"
declare -A LP LF

HOOK=0
if [ "${1:-}" = "--hook" ]; then HOOK=1; shift; fi
PROJECT_DIR="${1:-$PWD}"

# Project slug: same encoding statusline.sh uses (alnum kept, rest -> '-'), so
# the log key matches what statusline.sh reads back for its refresh throttle.
ENC=$(printf '%s' "$PROJECT_DIR" | sed 's|[^a-zA-Z0-9]|-|g')
SLUG="${ENC#-}"
SCORE_LOG="$CACHE_DIR/cc-score-${SLUG}.log"
mkdir -p "$CACHE_DIR" 2>/dev/null

pass() { [ "$HOOK" = 1 ] || printf '  ok  [%s] %s\n' "$1" "$2"; LP[$1]=$(( ${LP[$1]:-0} + 1 )); }
fail() { printf 'FAIL  [%s] %s\n' "$1" "$2"; LF[$1]=$(( ${LF[$1]:-0} + 1 )); }
sect() { [ "$HOOK" = 1 ] || echo "$1"; }
info() { [ "$HOOK" = 1 ] || echo "  info: $1"; }

sect "== rules: referenced tools installed and still mentioned"
TOOLS="rtk atuin xh wl-copy bun uv cargo jq podman basedpyright ruff git pgrep"
# Machine-local exceptions: TOOLS entries this host legitimately lacks.
# Untracked by dotfiles, so each machine states its own.
TOOLS_SKIP=""
[ -f "$CLAUDE_DIR/cc-score.local" ] && . "$CLAUDE_DIR/cc-score.local"
# Which rules cite this tool — empty means the manifest entry has gone orphan.
tool_citers() {
  grep -rlFw "$1" "$CLAUDE_DIR/rules" "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/RTK.md" 2>/dev/null \
    | sed "s|^$CLAUDE_DIR/||" | sort | paste -sd' ' - || true
}
for t in $TOOLS; do
  skipped=0
  case " $TOOLS_SKIP " in *" $t "*) skipped=1 ;; esac
  citers=$(tool_citers "$t")
  if ! command -v "$t" >/dev/null 2>&1; then
    if [ "$skipped" = 1 ]; then
      info "absent by local policy: $t (cc-score.local)"
    else
      fail rules "tool not installed: $t — cited in ${citers:-nothing; drop it here}"
    fi
  else
    # A skip whose tool is present rots exactly like a stale TOOLS entry.
    [ "$skipped" = 1 ] && info "stale local skip: $t is installed — drop from cc-score.local"
    if [ -z "$citers" ]; then
      fail rules "manifest entry no longer mentioned in any rule: $t (drop it here)"
    else
      pass rules "tool: $t <- $citers"
    fi
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
[ -n "$suggest" ] && info "mentioned in rules, runnable, but not in TOOLS manifest — add real dependencies:$suggest"

sect "== rules: file references resolve"
while IFS=: read -r src ref; do
  case "$ref" in *://*|*'$'*|*'*'*) continue ;; esac
  base="${ref##*/}"
  if [ -e "$CLAUDE_DIR/$ref" ] \
     || [ -e "$CLAUDE_DIR/rules/$base" ] || [ -e "$CLAUDE_DIR/$base" ] \
     || [ -e "$CLAUDE_DIR/hooks/$base" ] \
     || [ -e "${ref/#\~/$HOME}" ]; then
    pass rules "$(basename "$src") -> $ref"
  else
    fail rules "dead reference in $(basename "$src"): $ref"
  fi
done < <(grep -roE '[A-Za-z0-9_~/.-]*[A-Za-z0-9_-]+\.(md|sh)' "$CLAUDE_DIR/rules" "$CLAUDE_DIR/CLAUDE.md" | sort -u)

sect "== rules: shared phrases stay verbatim"
while IFS='|' read -r phrase f1 f2; do
  [ -z "$phrase" ] && continue
  drift=0
  for f in "$f1" "$f2"; do
    if [ ! -f "$CLAUDE_DIR/$f" ]; then
      fail rules "phrase-table target file missing: $f (update pairs table)"; drift=1
    elif ! grep -qF "$phrase" "$CLAUDE_DIR/$f"; then
      fail rules "phrase drift: \"$phrase\" missing from $f"; drift=1
    fi
  done
  if [ "$drift" = 0 ]; then pass rules "phrase: \"$phrase\""; fi
done <<'EOF'
default to none|CLAUDE.md|hooks/comment-gate.sh
would refactoring the adjacent code force this comment to change|CLAUDE.md|hooks/comment-gate.sh
compress to at most two short lines|CLAUDE.md|hooks/comment-gate.sh
Stdlib does it|CLAUDE.md|skills/rule-audit/SKILL.md
≥2 variants or any variant carries a|rules/rust.md|skills/rule-audit/SKILL.md
not a reason to skip a rung|CLAUDE.md|skills/rule-audit/SKILL.md
if the sentence is still Chinese|CLAUDE.md|skills/rule-audit/SKILL.md
default to none|CLAUDE.md|skills/rule-audit/SKILL.md
full construction in a 2nd test file|CLAUDE.md|skills/rule-audit/SKILL.md
permanently destroy uncommitted working-tree changes|CLAUDE.md|skills/rule-audit/SKILL.md
never discard directly|CLAUDE.md|hooks/stash-gate.sh
Write code comments in English|CLAUDE.md|skills/rule-audit/SKILL.md
cargo clippy -- -D warnings|rules/rust.md|hooks/qa-gate.sh
cargo test|rules/rust.md|hooks/qa-gate.sh
uv run ruff check|rules/python.md|hooks/qa-gate.sh
basedpyright|rules/python.md|hooks/qa-gate.sh
uv run pytest|rules/python.md|hooks/qa-gate.sh
EOF

sect "== rules: rule IDs resolve and stay unique"
ID_SRC=("$CLAUDE_DIR/rules" "$CLAUDE_DIR/CLAUDE.md")
mapfile -t ID_FILES < <(find "${ID_SRC[@]}" -name '*.md' | sort)
# A definition is the ID at the end of a heading, or bold at line start.
# Anything else on the same line is a reference — extract by position, not per line.
# The trailing /dev/null keeps grep off stdin when the file list comes back empty.
# Fenced code blocks may show ID syntax as an example; strip them before
# scanning for definitions/references so an example doesn't count as real.
strip_fences() { awk '/^```/{f=!f;next} !f' "$@" /dev/null; }
id_defs_in() {
  local stripped
  stripped=$(strip_fences "$@")
  { grep -E '^#{1,6} ' <<< "$stripped" | grep -oE '\[R[0-9]+ [a-z][a-z0-9-]*\]$'
    grep -oE '^[[:space:]]*(- )?\*\*\[R[0-9]+ [a-z][a-z0-9-]*\]' <<< "$stripped" \
      | grep -oE '\[R[0-9]+ [a-z][a-z0-9-]*\]'
  }
}
id_defs=$(id_defs_in "${ID_FILES[@]}" | sort)
# Line-by-line read: an unquoted slug is a bracket glob a stray file could expand.
# The R-number prefix disambiguates on its own — no lookarounds needed.
while IFS= read -r id; do
  [ -z "$id" ] && continue
  if grep -qxF "$id" <<< "$id_defs"; then
    pass rules "ID resolves: $id"
  else
    fail rules "ID referenced but never defined: $id — cited in $(grep -lF "$id" \
      "${ID_FILES[@]}" | sed "s|^$CLAUDE_DIR/||" | paste -sd' ' - || true)"
  fi
done < <(strip_fences "${ID_FILES[@]}" | grep -oE '\[R[0-9]+ [a-z][a-z0-9-]*\]' | sort -u)
# Number and slug are separate identities — either one colliding breaks grep-by-ID.
# A whole-string compare catches neither, since the strings differ by construction.
dupe_msg=""
for n in $(sed -E 's/^\[(R[0-9]+) .*/\1/' <<< "$id_defs" | sort | uniq -d); do
  dupe_msg+="number $n reused by $(grep -F "[$n " <<< "$id_defs" | paste -sd' ' -); "
done
for s in $(sed -E 's/^\[R[0-9]+ (.*)\]$/\1/' <<< "$id_defs" | sort | uniq -d); do
  dupe_msg+="slug $s reused by $(grep -E "^\[R[0-9]+ $s\]\$" <<< "$id_defs" | paste -sd' ' -); "
done
if [ -n "$dupe_msg" ]; then
  fail rules "duplicate ID definition: ${dupe_msg%; }"
else
  pass rules "no duplicate ID definitions"
fi
# A heading ID must sit last; anywhere else it is dropped with no trace, so flag
# the position instead of silently under-counting definitions.
stray_heads=$(grep -nE '^#{1,6} .*\[R[0-9]+ [a-z][a-z0-9-]*\]' "${ID_FILES[@]}" /dev/null \
                | grep -vE '\[R[0-9]+ [a-z][a-z0-9-]*\]$' \
                | sed "s|^$CLAUDE_DIR/||" | cut -d: -f1,2 | tr '\n' ' ' || true)
if [ -n "$stray_heads" ]; then
  fail rules "heading ID must be last on its line: $stray_heads"
else
  pass rules "heading IDs sit at line end"
fi
# A nested ID asserts a containment the IDs deny: an indivisible section cannot
# hold a separately-violable clause. Track heading scope, flag both forms.
nested_ids=$(awk '
  FNR==1 { split("", lvl); split("", sid); top=0; fence=0 }
  /^```/ { fence = !fence; next }
  fence  { next }
  /^#+[ \t]/ {
    match($0, /^#+/); l = RLENGTH
    while (top > 0 && lvl[top] >= l) top--
    if (match($0, /\[R[0-9]+ [a-z][a-z0-9-]*\][ \t]*$/)) {
      id = substr($0, RSTART, RLENGTH); sub(/[ \t]+$/, "", id)
      if (top > 0) printf "%s:%d(%s in %s) ", FILENAME, FNR, id, sid[top]
      top++; lvl[top] = l; sid[top] = id
    }
    next
  }
  /^[ \t]*(- )?\*\*\[R[0-9]+ [a-z][a-z0-9-]*\]/ {
    match($0, /\[R[0-9]+ [a-z][a-z0-9-]*\]/); id = substr($0, RSTART, RLENGTH)
    if (top > 0) printf "%s:%d(%s in %s) ", FILENAME, FNR, id, sid[top]
    else if ($0 ~ /^[ \t]/) printf "%s:%d(%s indented) ", FILENAME, FNR, id
  }
' "${ID_FILES[@]}" </dev/null | sed "s|$CLAUDE_DIR/||g" || true)
if [ -n "$nested_ids" ]; then
  fail rules "ID definition nested inside another ID's scope: $nested_ids"
else
  pass rules "no nested ID definitions"
fi
# Resident set = CLAUDE.md alone; rules/ holds only `paths:`-scoped conditionals.
# A resident cite of a conditional ID resolves on disk but is absent at runtime.
cond_files=(); res_files=("$CLAUDE_DIR/CLAUDE.md")
for f in "$CLAUDE_DIR"/rules/*.md; do
  [ -e "$f" ] || continue
  if awk 'NR==1 && $0!="---"{exit} NR>1 && /^---/{exit} NR>1 && /^paths:/{p=1; exit} END{exit !p}' "$f"; then
    cond_files+=("$f")
    pass rules "conditional (paths-scoped): $(basename "$f")"
  else
    fail rules "resident content in rules/ (no paths: frontmatter) — belongs in CLAUDE.md: $(basename "$f")"
  fi
done
dangling_ids=""
if [ ${#cond_files[@]} -gt 0 ]; then
  cond_ids=$(id_defs_in "${cond_files[@]}" | sort -u)
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    citers=$(grep -lF "$id" "${res_files[@]}" 2>/dev/null \
               | sed "s|^$CLAUDE_DIR/||" | tr '\n' ',' || true)
    [ -n "${citers%,}" ] && dangling_ids="$dangling_ids $id<-${citers%,}"
  done <<< "$cond_ids"
fi
if [ -n "$dangling_ids" ]; then
  fail rules "resident file cites conditional ID (absent at runtime):$dangling_ids"
else
  pass rules "no resident->conditional ID references"
fi

sect "== rules: no rule file has grown past the size limit"
RULES_SIZE_LIMIT=50
for f in "$CLAUDE_DIR"/rules/*.md; do
  [ -f "$f" ] || continue
  b=$(basename "$f")
  lines=$(grep -c '[^[:space:]]' "$f" || true)
  if [ "$lines" -gt "$RULES_SIZE_LIMIT" ]; then
    fail rules "$b: $lines non-blank lines, limit $RULES_SIZE_LIMIT — split or trim"
  else
    pass rules "size ok: $b ($lines/$RULES_SIZE_LIMIT)"
  fi
done

sect "== hooks: commands wired in settings.json exist"
if [ ! -f "$CLAUDE_DIR/settings.json" ]; then
  WIRED_CMDS=""
  fail hooks "settings.json missing — cannot verify wired hooks"
else
  WIRED_CMDS=$(jq -r '.hooks[][]?.hooks[]?.command // empty' "$CLAUDE_DIR/settings.json" | sort -u)
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
  done <<< "$WIRED_CMDS"
fi

sect "== hooks: scripts syntax-clean and executable"
for f in "$CLAUDE_DIR"/hooks/*.sh; do
  b=$(basename "$f")
  if bash -n "$f" 2>/dev/null; then pass hooks "syntax: $b"; else fail hooks "syntax error: $b"; fi
  if [ -x "$f" ]; then pass hooks "executable: $b"; else fail hooks "not executable: $b"; fi
done

sect "== hooks: every hooks/*.sh script is referenced by settings.json"
# Scoped to *.sh so an unwired script can't hide here (scripts/ retired 2026-08-03).
# Non-.sh config (e.g. cmd-gate.conf) needs no exemption — never a wired command.
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  for f in "$CLAUDE_DIR"/hooks/*.sh; do
    b=$(basename "$f")
    # Leading slash anchors to the path component: bare "$b" lets gate.sh match
    # cmd-gate.sh and pass an orphan off as wired.
    if grep -qF "/$b" <<< "$WIRED_CMDS"; then
      pass hooks "registered: $b"
    else
      fail hooks "orphaned in hooks/, not referenced in settings.json: $b"
    fi
  done
fi

sect "== skills: every directory is a loadable skill"
for d in "$CLAUDE_DIR"/skills/*/; do
  b=$(basename "$d")
  if [ -f "$d/SKILL.md" ] && grep -q '^description:' "$d/SKILL.md"; then
    pass skills "$b"
  else
    fail skills "$b: no SKILL.md with description — never loads"
  fi
done

sect "== plugins: enabled installed; project installs not orphaned"
if [ ! -f "$CLAUDE_DIR/settings.json" ] || [ ! -f "$CLAUDE_DIR/plugins/installed_plugins.json" ]; then
  fail plugins "settings.json or installed_plugins.json missing — cannot verify plugins"
else
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
  [ -n "$dormant" ] && info "user-scope installed but disabled (dormant): $dormant"
fi

sect "== mcp: manual servers minimal and alive"
if [ ! -f "$HOME/.claude.json" ]; then
  fail mcp "~/.claude.json missing — cannot check MCP servers"
else
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
fi
info "runtime liveness (plugin MCP server died) not checkable offline — use /mcp in a session"

sect "== memory: single location, index complete, bounded size (project: $PROJECT_DIR)"
if [ ! -e "$HOME/.claude/memory" ]; then
  pass memory "no stranded legacy directory (~/.claude/memory)"
else
  fail memory "legacy ~/.claude/memory exists again — data stranded outside recall path"
fi

resolve_mem_dir() {
  [ -d "$PROJECT_DIR" ] || { fail memory "project dir does not exist: $PROJECT_DIR"; return 1; }
  [[ "$PROJECT_DIR" == /* ]] \
    || { fail memory "project dir is not absolute: $PROJECT_DIR"; return 1; }
  MEM_DIR="$CLAUDE_DIR/projects/-${SLUG}/memory"
  [[ "$MEM_DIR" == "$CLAUDE_DIR/projects/"* ]] \
    || { fail memory "derived memory path escapes projects/: $MEM_DIR"; return 1; }
  return 0
}
if resolve_mem_dir; then MEM_OK=1; else MEM_OK=0; fi

reject_symlink() {  # path label display-name -> fails+reports if symlink; caller does its own `continue`
  [ -L "$1" ] || return 0
  fail memory "$2 (not plain): $3"
  return 1
}
to_basename_csv() { xargs -n1 basename | paste -sd,; }

if [ "$MEM_OK" = 1 ] && [ -d "$MEM_DIR" ] && [ ! -L "$MEM_DIR" ]; then
  if [ -f "$MEM_DIR/MEMORY.md" ]; then
    pass memory "MEMORY.md index exists"
    # Both halves of "is it indexed" read the same parsed link targets — a bare
    # substring test would accept prose "(foo.md)" and reject "[t](./foo.md)".
    index_targets=$(grep -oP '\]\(\K[^)]+' "$MEM_DIR/MEMORY.md" | sed -e 's|^\./||' -e 's/#.*//')

    file_count=0
    for f in "$MEM_DIR"/*.md; do
      [ -f "$f" ] || continue
      reject_symlink "$f" "symlinked memory file" "$(basename "$f")" || continue
      b=$(basename "$f"); [ "$b" = "MEMORY.md" ] && continue
      ((file_count++)) || true
      if grep -qxF "$b" <<< "$index_targets"; then pass memory "indexed: $b"; else fail memory "unindexed memory file: $b"; fi
    done
    if [ "$file_count" -gt 30 ]; then
      fail memory "file bloat: $file_count memory files, limit 30"
    else
      pass memory "file count within bound: $file_count/30"
    fi

    while IFS= read -r t; do
      [ -z "$t" ] && continue
      case "$t" in *://*) continue ;; esac
      if [[ "$t" == *'../'* || "$t" == /* ]]; then
        fail memory "path traversal in MEMORY.md index target: $t"
        continue
      fi
      if [ -f "$MEM_DIR/$t" ]; then
        reject_symlink "$MEM_DIR/$t" "index target is a symlink" "$t" || continue
        pass memory "link resolves: $t"
      else
        fail memory "dead index link: $t"
      fi
    done <<< "$index_targets"

    # Wiki links are memory-to-memory: [[name]] dies silently when its target goes.
    # Stricter than the harness, which tolerates forward refs; else use plain text.
    wiki_n=0; wiki_bad=0
    while IFS= read -r ln; do
      [ -z "$ln" ] && continue
      ((wiki_n++)) || true
      [ -f "$MEM_DIR/${ln#*:}.md" ] && continue
      fail memory "dangling wiki link in ${ln%%:*}: [[${ln#*:}]]"
      wiki_bad=1
    done < <(grep -oHP '\[\[\K[a-z0-9-]+(?=\]\])' "$MEM_DIR"/*.md 2>/dev/null \
               | sed "s|^$MEM_DIR/||" | sort -u)
    [ "$wiki_bad" = 0 ] && pass memory "wiki links resolve ($wiki_n checked)"

    line_count=$(wc -l < "$MEM_DIR/MEMORY.md")
    if [ "$line_count" -gt 120 ]; then
      entry_count=$(grep -c '^- \[' "$MEM_DIR/MEMORY.md" || echo 0)
      fail memory "index bloat: MEMORY.md has $line_count lines ($entry_count entries), limit 120"
    else
      pass memory "index size within bound: $line_count/120 lines"
    fi
  else
    # Empty dir is a fresh project; only data-without-index is corruption.
    unindexed=$(find "$MEM_DIR" -maxdepth 1 -type f -name '*.md' ! -name 'MEMORY.md' -print -quit 2>/dev/null)
    if [ -n "$unindexed" ]; then
      fail memory "MEMORY.md index missing (unindexed: $(basename "$unindexed"))"
    else
      pass memory "no memory files yet — index not required"
    fi
  fi

  # Staleness needs `find -mtime` over the memory dir — cheap once, but cc-score
  # now also runs from statusline.sh every ~60s, so cache it per project for a day.
  mkdir -p "$CACHE_DIR"
  STALE_CACHE="$CACHE_DIR/stale-cache-${SLUG}"
  STALE_LOCK="$CACHE_DIR/stale-cache-${SLUG}.lock"
  CACHE_TTL=86400
  now=$(date +%s)
  stale=""
  cache_age=$(( now - $(stat -c %Y "$STALE_CACHE" 2>/dev/null || echo 0) ))
  if [ -f "$STALE_CACHE" ] && [ "$cache_age" -lt "$CACHE_TTL" ]; then
    stale=$(cat "$STALE_CACHE" 2>/dev/null || true)
  else
    exec 202>"$STALE_LOCK"
    flock 202
    # Re-check after acquiring the lock: a racing process may have just
    # refreshed the cache while we were waiting, in which case reuse it.
    cache_age=$(( $(date +%s) - $(stat -c %Y "$STALE_CACHE" 2>/dev/null || echo 0) ))
    if [ -f "$STALE_CACHE" ] && [ "$cache_age" -lt "$CACHE_TTL" ]; then
      stale=$(cat "$STALE_CACHE" 2>/dev/null || true)
    else
      stale=$(find "$MEM_DIR" -type f -name "*.md" ! -name "MEMORY.md" -mtime +180 2>/dev/null || true)
      printf '%s\n' "$stale" > "$STALE_CACHE"
    fi
    exec 202>&-
  fi
  stale_valid=""
  while IFS= read -r f; do
    [ -n "$f" ] && [ -f "$f" ] && stale_valid+="$f"$'\n'
  done <<< "$stale"
  if [ -n "$stale_valid" ]; then
    stale_list=$(echo "$stale_valid" | to_basename_csv)
    fail memory "stale files (not modified in 180+ days, review for relevance): $stale_list"
  else
    pass memory "no memory files stale 180+ days"
  fi

  # MEMORY.md.bak is excluded: repair instructions create it and it may linger briefly.
  orphaned_tmp=$(find "$MEM_DIR" -type f \( -name "*.tmp" -o -name "*.bak" \) ! -name "MEMORY.md.bak" -mmin +60 2>/dev/null || true)
  if [ -n "$orphaned_tmp" ]; then
    tmp_list=$(echo "$orphaned_tmp" | to_basename_csv)
    fail memory "orphaned temp files, safe to delete: $tmp_list"
  else
    pass memory "no orphaned temp files"
  fi
elif [ "$MEM_OK" = 1 ]; then
  [ -e "$MEM_DIR" ] && fail memory "memory directory is a symlink, not plain: $MEM_DIR"
fi

# Statusline score = layers passed / layers total: a layer passes when none of
# its assertions failed; a layer with no checks trivially passes.
TOTAL_F=0; LAYER_P=0; NLAYERS=0
for l in $LAYERS; do
  NLAYERS=$((NLAYERS + 1))
  TOTAL_F=$((TOTAL_F + ${LF[$l]:-0}))
  [ "${LF[$l]:-0}" = 0 ] && LAYER_P=$((LAYER_P + 1))
done
PCT=$(( LAYER_P * 100 / NLAYERS ))
printf '%s %d%% %d/%d\n' "$(date +%F)" "$PCT" "$LAYER_P" "$NLAYERS" >> "$SCORE_LOG"

[ "$HOOK" = 1 ] && exit 0

echo
echo "== score"
for l in $LAYERS; do
  printf '%-8s %d/%d\n' "$l" "${LP[$l]:-0}" "$(( ${LP[$l]:-0} + ${LF[$l]:-0} ))"
done
if   [ "$PCT" -ge 95 ]; then BAND="healthy"
elif [ "$PCT" -ge 80 ]; then BAND="needs attention"
else BAND="rotting"; fi
printf 'overall  %d/%d layers (%d%%) — %s\n' "$LAYER_P" "$NLAYERS" "$PCT" "$BAND"
[ "$TOTAL_F" = 0 ]
