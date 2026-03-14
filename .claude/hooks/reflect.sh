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

# Check if last assistant message contains reflection marker
last_message=$(tail -n 100 "$transcript" | tac | grep -m1 '"role":"assistant"' | jq -r '.message.content[] | select(.type=="text") | .text' 2>/dev/null || echo "")
if ! echo "$last_message" | grep -q '<!-- REFLECT -->'; then
  exit 0
fi

# Detect reflection loops via Claude Code's official stop_hook_active flag
if [ "$stop_hook_active" = "true" ]; then
  exit 0
fi

# Deduplicate: skip if already reflected for this transcript state
REFLECTED_FLAG="$HOME/.claude/hooks/.reflected-$(basename "$transcript" .jsonl)"
transcript_mtime=$(stat -c %Y "$transcript" 2>/dev/null || echo 0)
if [ -f "$REFLECTED_FLAG" ] && [ "$(cat "$REFLECTED_FLAG" 2>/dev/null)" = "$transcript_mtime" ]; then
  exit 0
fi

# Acquire exclusive lock to prevent concurrent health check + reflection
LOCK_FILE="$HOME/.claude/hooks/.reflect.lock"
exec 200>"$LOCK_FILE"
if ! flock -w 5 200; then
  echo "[$(date -Iseconds)] Reflection skipped: lock timeout after 5s. Transcript: $transcript" >> "$HOME/.claude/hooks/reflect.log"
  exit 0
fi

# Cleanup: run every 10 invocations to reduce I/O overhead
CLEANUP_COUNTER="$HOME/.claude/hooks/.cleanup-counter"
counter=$(cat "$CLEANUP_COUNTER" 2>/dev/null || echo 0)
counter=$((counter + 1))
echo "$counter" > "$CLEANUP_COUNTER"
if [ $((counter % 10)) -eq 0 ]; then
  find "$HOME/.claude/hooks/" \( -name ".reflected-*" -o -name ".count-*" -o -name ".stale-cache-*" \) -mmin +1440 -delete 2>/dev/null || true
  # Rotate reflect.log if over 100KB
  LOG_FILE="$HOME/.claude/hooks/reflect.log"
  if [ -f "$LOG_FILE" ] && [ "$(stat -c %s "$LOG_FILE" 2>/dev/null || echo 0)" -gt 102400 ]; then
    tail -n 50 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
  fi
fi

# Run health check (now protected by lock)
heal_exit=0
heal_output=$(~/.claude/hooks/memory-heal.sh 2>&1) || heal_exit=$?

if [ $heal_exit -ne 0 ]; then
  echo "[$(date -Iseconds)] Health check failed (exit $heal_exit): $heal_output" >> "$HOME/.claude/hooks/reflect.log"
  # Don't block, just log and skip reflection
  exit 0
fi

# Compute project memory directory
PROJECT_SLUG=$(echo "$PWD" | sed 's|[/.]|-|g; s|^-||')
MEMORY_DIR="$HOME/.claude/projects/-${PROJECT_SLUG}/memory"

# Log health check issues (don't ask haiku to fix them — too risky)
if [ -n "$heal_output" ]; then
  echo "[$(date -Iseconds)] Health check issues (will be fixed by main session next time): $heal_output" >> "$HOME/.claude/hooks/reflect.log"
fi

# Ensure memory directory exists
mkdir -p "$MEMORY_DIR"

# Extract recent conversation context (include tool_use for richer context)
conversation=$(tail -n 500 "$transcript" | grep -E '"role":"(assistant|user)"' | tail -n 50 | jq -r '
  .role as $role |
  .message.content[]? |
  if .type == "text" then "\($role): \(.text)"
  elif .type == "tool_use" then "\($role) [tool: \(.name)]: \(.input | tostring | .[0:200])"
  else empty end
' 2>/dev/null | head -c 8000 || echo "(failed to extract conversation)")

# Mark as reflected before launching (use mtime for dedup)
echo "$transcript_mtime" > "$REFLECTED_FLAG"

# Write prompt to temp file to avoid shell argument size/quoting issues
PROMPT_FILE=$(mktemp /tmp/reflect-prompt.XXXXXX)
cat > "$PROMPT_FILE" <<PROMPT
You are a reflection agent. Review the conversation below and save memorable content.

## Decision tree (follow strictly)

1. Is this a user preference, correction, or feedback about YOUR behavior?
   → Append to ~/.claude/rules/user.md (role/knowledge) or ~/.claude/rules/standards.md (code style) or create ~/.claude/rules/<domain>.md if no existing file fits
   → Each rules file must stay under 30 lines. Read the file first, update existing entries rather than appending duplicates.

2. Is this a project-specific decision, architecture choice, or external resource reference?
   → Write to $MEMORY_DIR/<topic>.md with frontmatter (name, description, type: project|reference)
   → Update $MEMORY_DIR/MEMORY.md index

3. Neither? → Do nothing.

## Rules

- Write all content in English only
- ALWAYS read the target file before writing to check for duplicates
- NEVER modify ~/.claude/CLAUDE.md
- NEVER create new rules files if an existing one covers the domain — update it instead
- If unsure whether something is memorable, skip it

Recent conversation:
$conversation
PROMPT

# Launch claude CLI in background for reflection
nohup claude -p --model haiku --dangerously-skip-permissions < "$PROMPT_FILE" >> "$HOME/.claude/hooks/reflect.log" 2>&1 &
CLAUDE_PID=$!

# Clean up prompt file after claude reads it (give it a moment to start)
(sleep 5 && rm -f "$PROMPT_FILE") &

exit 0
