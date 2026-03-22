#!/usr/bin/env bash
# Session Reflect Hook — runs on Stop, uses haiku to reflect on conversation
# and extract worth-remembering insights to project memory or global rules.

set -euo pipefail

# Configuration
FREQUENCY=5           # Trigger every N conversation pairs
WINDOW_SIZE=15        # Analyze last N pairs
LOG_FILE="$HOME/.cache/claude/session-reflect.log"
LOCK_FILE="$HOME/.claude/hooks/.session-reflect.lock"

# Helper function for logging
log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
  echo "$msg" >> "$LOG_FILE"
  printf '%*s\n' "${#msg}" '' | tr ' ' '=' >> "$LOG_FILE"
}

INPUT=$(cat)
mkdir -p "$HOME/.cache/claude"

# Prevent infinite loop: haiku's own session would trigger this hook too
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
[ "$STOP_HOOK_ACTIVE" = "true" ] && exit 0

TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

[ -z "$TRANSCRIPT_PATH" ] && exit 0
[ ! -f "$TRANSCRIPT_PATH" ] && exit 0

# Acquire exclusive lock to prevent concurrent execution
exec 200>"$LOCK_FILE"
if ! flock -w 5 200; then
  log "SKIP lock_timeout transcript=$TRANSCRIPT_PATH"
  exit 0
fi

# Compute paths
PROJECT_SLUG=$(echo "$CWD" | sed 's|[/.]|-|g; s|^-||')
MEMORY_DIR="$HOME/.claude/projects/-${PROJECT_SLUG}/memory"
RULES_DIR="$HOME/.claude/rules"
mkdir -p "$MEMORY_DIR"

# Extract conversation as paired {user, assistant} JSON lines
CONVERSATION=$(jq -cn '
  [inputs | select((.type == "user" or .type == "assistant") and (.isMeta != true)) | {
    role: (.message.role // .type),
    text: (.message.content |
      if type == "array" then map(select(.type == "text") | .text) | join(" ")
      elif type == "string" then .
      else "" end |
      gsub("<command-message>[^<]*</command-message>\\n?"; "") |
      gsub("<command-name>[^<]*</command-name>\\n?"; "") |
      gsub("<command-args>(?<a>[^<]*)</command-args>"; "/\\(.a)") |
      gsub("^\\s+|\\s+$"; ""))
  }] | map(select(.text | gsub("^\\s+|\\s+$"; "") | . != "")) as $msgs |
  reduce range($msgs | length) as $i (
    {out: [], cur: null};
    $msgs[$i] as $m |
    if $m.role == "user" then
      if .cur != null then
        .out += [.cur] | .cur = {user: $m.text, assistant: []}
      else
        .cur = {user: $m.text, assistant: []}
      end
    else
      if .cur != null then
        .cur.assistant += [$m.text]
      else
        .out += [{user: "", assistant: [$m.text]}] | .cur = null
      end
    end
  ) |
  if .cur != null then .out + [.cur] else .out end |
  .[] | select(.user != "" and (.assistant | length) > 0) |
  if (.assistant | length) == 1 then {user, assistant: .assistant[0]} else . end
' "$TRANSCRIPT_PATH" 2>&1 | { grep -v '\[Request interrupted by user\]' || true; })

# Frequency control: trigger every N conversation pairs
PAIR_COUNT=$(echo "$CONVERSATION" | wc -l)
[ "$PAIR_COUNT" -eq 0 ] && exit 0
[ $((PAIR_COUNT % FREQUENCY)) -ne 0 ] && exit 0

# Limit to last N pairs for prompt
CONVERSATION=$(echo "$CONVERSATION" | tail -$WINDOW_SIZE)
ACTUAL_WINDOW=$(echo "$CONVERSATION" | wc -l)
# Write prompt to temp file to avoid shell argument size limits
PROMPT_FILE=$(mktemp /tmp/session-reflect-prompt.XXXXXX) || {
  log "ERROR mktemp_failed"
  exit 1
}

cat > "$PROMPT_FILE" <<PROMPT
You are a reflection agent. Your job is to extract ONLY truly valuable, reusable insights.

## What to extract (very selective)

1. **User preferences/corrections** — ONLY if it changes how you should work in future sessions:
   - "always use X instead of Y"
   - "never do Z"
   - "I prefer approach A over B"
   → Update ~/.claude/rules/user.md or ~/.claude/rules/<domain>.md

2. **Project-specific knowledge** — ONLY if it's non-obvious and will be useful later:
   - Architecture decisions with rationale
   - Known bugs/workarounds
   - External resource locations
   → Write to $MEMORY_DIR/<topic>.md with frontmatter

## What to SKIP (most things)

- Implementation details of what was just built
- Bug fixes that are now resolved
- Routine coding tasks
- Temporary debugging
- Anything already obvious from reading the code
- Session summaries or progress reports

## Critical rules

- If nothing is worth remembering, output NOTHING and exit silently
- Read target files first to avoid duplicates
- Keep entries under 3 sentences
- Write in English only
- NEVER modify ~/.claude/CLAUDE.md

## Context

Session directory: $CWD
Project memory: $MEMORY_DIR
Global rules: $RULES_DIR

## Conversation
$CONVERSATION
PROMPT

# Check if claude command exists
if ! command -v claude &> /dev/null; then
  log "ERROR claude_not_found"
  rm -f "$PROMPT_FILE"
  exit 1
fi

# Run in background so it doesn't block session teardown
nohup claude -p --model haiku --allowedTools "Read,Write,Edit" < "$PROMPT_FILE" >> "$LOG_FILE" 2>&1 &
CLAUDE_PID=$!

# Clean up prompt file after claude process exits
(tail --pid=$CLAUDE_PID -f /dev/null 2>/dev/null && rm -f "$PROMPT_FILE") &

if [ "$ACTUAL_WINDOW" -lt "$WINDOW_SIZE" ]; then
  log "RUN pairs=$PAIR_COUNT window=$ACTUAL_WINDOW (requested=$WINDOW_SIZE) pid=$CLAUDE_PID"
else
  log "RUN pairs=$PAIR_COUNT window=$WINDOW_SIZE pid=$CLAUDE_PID"
fi
exit 0
