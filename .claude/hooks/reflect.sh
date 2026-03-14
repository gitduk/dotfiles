#!/usr/bin/env bash
set -euo pipefail

input=$(cat)

read -r transcript stop_hook_active < <(echo "$input" | jq -r '[.transcript_path, (.stop_hook_active // false | tostring)] | @tsv')

if [ "$transcript" = "null" ] || [ ! -f "$transcript" ]; then
  exit 0
fi

# Count assistant messages with mtime-based cache to avoid re-scanning long transcripts
get_assistant_count() {
  local transcript="$1"
  local cache_file="$HOME/.claude/hooks/.count-$(basename "$transcript" .jsonl)"
  local transcript_mtime
  transcript_mtime=$(stat -c %Y "$transcript" 2>/dev/null || echo 0)

  if [ -f "$cache_file" ]; then
    local cached_mtime
    cached_mtime=$(head -1 "$cache_file" 2>/dev/null || echo 0)
    if [ "$transcript_mtime" = "$cached_mtime" ]; then
      tail -1 "$cache_file"
      return
    fi
  fi

  local count
  count=$(grep -c '"role":"assistant"' "$transcript" 2>/dev/null) || true
  count=${count:-0}
  printf '%s\n%s\n' "$transcript_mtime" "$count" > "$cache_file"
  echo "$count"
}

assistant_count=$(get_assistant_count "$transcript")
if [ "$assistant_count" -le 2 ]; then
  exit 0
fi

# Detect reflection loops via Claude Code's official stop_hook_active flag
if [ "$stop_hook_active" = "true" ]; then
  exit 0
fi

# Session-scoped dedup: only reflect once per transcript session
# (stop_hook_active may reset after Claude responds to the block)
SESSION_FLAG="$HOME/.claude/hooks/.reflected-$(basename "$transcript" .jsonl)"
if [ -f "$SESSION_FLAG" ]; then
  exit 0
fi

# Acquire exclusive lock to prevent concurrent health check + reflection
LOCK_FILE="$HOME/.claude/hooks/.reflect.lock"
exec 200>"$LOCK_FILE"
if ! flock -w 5 200; then
  echo "[$(date -Iseconds)] Reflection skipped: lock timeout after 5s. Transcript: $transcript" >> "$HOME/.claude/hooks/reflect.log"
  echo "ERROR: Another reflection in progress, skipping. Logged to ~/.claude/hooks/reflect.log" >&2
  exit 0
fi

# Mark this session as reflected (before doing work, to prevent races)
touch "$SESSION_FLAG"
# Cleanup: run every 10 invocations to reduce I/O overhead
CLEANUP_COUNTER="$HOME/.claude/hooks/.cleanup-counter"
counter=$(cat "$CLEANUP_COUNTER" 2>/dev/null || echo 0)
counter=$((counter + 1))
echo "$counter" > "$CLEANUP_COUNTER"
if [ $((counter % 10)) -eq 0 ]; then
  find "$HOME/.claude/hooks/" \( -name ".reflected-*" -o -name ".count-*" -o -name ".stale-cache-*" \) -mmin +1440 -delete 2>/dev/null || true
fi

# Run health check (now protected by lock)
heal_exit=0
heal_output=$(~/.claude/hooks/memory-heal.sh 2>&1) || heal_exit=$?

if [ $heal_exit -ne 0 ]; then
  echo "CRITICAL: Health check crashed (exit $heal_exit). Output:" >&2
  echo "$heal_output" >&2
  echo "[$(date -Iseconds)] Health check failed: $heal_output" >> "$HOME/.claude/hooks/reflect.log"
  jq -n --arg reason "⚠️ CRITICAL: Memory health check crashed. Check ~/.claude/hooks/reflect.log for details. Do not proceed with reflection until this is resolved." '{decision: "block", reason: $reason}'
  exit 0
fi

if [ -n "$heal_output" ]; then
  prompt="⚠️ Memory system health check found issues. Fix them first, then reflect:

$heal_output

Repair rules (BACKUP FIRST - MEMORY.md.bak created automatically):
- ORPHAN_FILES → Read file frontmatter, verify type/description exist, add to MEMORY.md (format: \"- [file.md](file.md) — description\")
- PHANTOM_ENTRIES → Remove lines referencing missing files from MEMORY.md
- MISPLACED_MEMORY → Move user/feedback type files to ~/.claude/rules/<domain>.md (e.g., git.md, python.md). Remove from project MEMORY.md. Update content to match rules format
- ORPHANED_TMP → Delete .tmp and .bak files older than 1 hour (safe to remove)
- INDEX_BLOAT → Merge entries ONLY if they reference same topic (e.g., \"git workflow\" + \"git commits\" → \"git workflow\"). Keep distinct topics separate
- FILE_BLOAT → Split large files by subtopic, ensure each ≤30 lines. Update MEMORY.md links
- STALE_FILES → Keep if: architectural decision, active project context, or user preference. Delete only if: temporary task notes, resolved bugs, outdated external references
- RULES_OVERSIZE → Remove redundant rules (check if Claude does by default), merge duplicate guidance, split by domain if needed
- SECURITY_ERROR → Report immediately, do not attempt repair

MANDATORY: Use atomic operations for ALL file modifications:
1. Backup: cp MEMORY.md MEMORY.md.bak (if modifying index)
2. Create temp: Write changes to .tmp file
3. Validate: Check frontmatter, no duplicate entries, valid markdown links
4. Atomic replace: mv .tmp target (overwrites atomically)
5. Verify: Read back and confirm changes applied correctly

After repairs, proceed with reflection:
Review conversation for memorable content?
- Preferences/corrections/role → ~/.claude/rules/ or CLAUDE.md Preferences (cross-project)
- Project decisions/external resources → current project memory directory
Confirm no duplicates. If content exists, save and state which file. If nothing to save, produce no output at all — no acknowledgment, no summary, complete silence."
else
  prompt="Review conversation for memorable content?
- Preferences/corrections/role → ~/.claude/rules/ or CLAUDE.md Preferences (cross-project)
- Project decisions/external resources → current project memory directory
Confirm no duplicates. If content exists, save and state which file. If nothing to save, produce no output at all — no acknowledgment, no summary, complete silence."
fi

jq -n --arg reason "$prompt" '{decision: "block", reason: $reason}'
