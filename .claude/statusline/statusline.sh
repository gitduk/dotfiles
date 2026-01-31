#!/usr/bin/env bash
# =============================================================================
# Claude Code Statusline — Modular Widget Architecture
# Each widget is a function returning a string (empty = skip).
# Customize by editing WIDGETS and SEPARATOR below.
# =============================================================================

# ─── Configuration ───────────────────────────────────────────────────────────
WIDGETS=(model session_cost block_timer context_percentage git_branch)
SEPARATOR=" | "

# ─── Global Variables (populated by parse_input / parse_transcript) ──────────
J_MODEL="" J_MODEL_ID="" J_VERSION="" J_OUTPUT_STYLE="" J_SESSION_ID=""
J_COST="" J_CWD="" J_TRANSCRIPT_PATH=""
T_INPUT=0 T_OUTPUT=0 T_CACHED=0 T_TOTAL=0 T_CONTEXT_LEN=0
T_FIRST_TS="" T_LAST_TS=""
TRANSCRIPT_PARSED=0

# ─── Read stdin ──────────────────────────────────────────────────────────────
INPUT=$(cat)

# =============================================================================
# parse_input — extract all fields from the status JSON in one jq call
# =============================================================================
parse_input() {
  eval "$(printf '%s' "$INPUT" | jq -r '
    @sh "J_MODEL=\(.model.display_name // "")",
    @sh "J_MODEL_ID=\(.model.id // "")",
    @sh "J_VERSION=\(.version // "")",
    @sh "J_OUTPUT_STYLE=\(.output_style.name // "")",
    @sh "J_SESSION_ID=\(.session_id // "")",
    @sh "J_COST=\(.cost.total_cost_usd // "")",
    @sh "J_CWD=\(.cwd // "")",
    @sh "J_TRANSCRIPT_PATH=\(.transcript_path // "")"
  ')"
}

# =============================================================================
# parse_transcript — parse the session JSONL file for token metrics & timestamps
# Uses a cache file keyed on file size to avoid re-parsing unchanged files.
# =============================================================================
TRANSCRIPT_CACHE="$HOME/.cache/claude_statusline_transcript_cache"

parse_transcript() {
  [[ $TRANSCRIPT_PARSED -eq 1 ]] && return
  TRANSCRIPT_PARSED=1

  [[ -z "$J_TRANSCRIPT_PATH" || ! -f "$J_TRANSCRIPT_PATH" ]] && return

  local file_size
  file_size=$(stat --format='%s' "$J_TRANSCRIPT_PATH" 2>/dev/null \
           || stat -f '%z' "$J_TRANSCRIPT_PATH" 2>/dev/null)

  # Check cache
  if [[ -f "$TRANSCRIPT_CACHE" ]]; then
    local cached_path cached_size
    while IFS='=' read -r key val; do
      case "$key" in
        path) cached_path="$val" ;;
        size) cached_size="$val" ;;
        input) T_INPUT="$val" ;;
        output) T_OUTPUT="$val" ;;
        cached) T_CACHED="$val" ;;
        total) T_TOTAL="$val" ;;
        context_len) T_CONTEXT_LEN="$val" ;;
        first_ts) T_FIRST_TS="$val" ;;
        last_ts) T_LAST_TS="$val" ;;
      esac
    done < "$TRANSCRIPT_CACHE"
    if [[ "$cached_path" == "$J_TRANSCRIPT_PATH" && "$cached_size" == "$file_size" ]]; then
      return
    fi
  fi

  # Parse JSONL with a single jq -s call
  local jq_output
  jq_output=$(jq -r -s '
    [.[] | select(.message.usage != null)] as $entries |
    ($entries | map(.message.usage.input_tokens // 0) | add // 0) as $inp |
    ($entries | map(.message.usage.output_tokens // 0) | add // 0) as $out |
    ($entries | map((.message.usage.cache_read_input_tokens // 0)
                  + (.message.usage.cache_creation_input_tokens // 0)) | add // 0) as $cch |
    # Most recent main-chain entry for context length
    ([.[] | select(.message.usage != null and .isSidechain != true
                   and .isApiErrorMessage != true and .timestamp != null)]
      | sort_by(.timestamp) | last) as $recent |
    (if $recent then
       ($recent.message.usage.input_tokens // 0)
       + ($recent.message.usage.cache_read_input_tokens // 0)
       + ($recent.message.usage.cache_creation_input_tokens // 0)
     else 0 end) as $ctx |
    # First and last timestamps
    ([.[] | select(.timestamp != null) | .timestamp] | sort | first // "") as $fts |
    ([.[] | select(.timestamp != null) | .timestamp] | sort | last  // "") as $lts |
    @sh "T_INPUT=\($inp)",
    @sh "T_OUTPUT=\($out)",
    @sh "T_CACHED=\($cch)",
    @sh "T_TOTAL=\($inp + $out + $cch)",
    @sh "T_CONTEXT_LEN=\($ctx)",
    @sh "T_FIRST_TS=\($fts)",
    @sh "T_LAST_TS=\($lts)"
  ' "$J_TRANSCRIPT_PATH" 2>/dev/null) || return
  eval "$jq_output"

  # Write cache
  mkdir -p "$(dirname "$TRANSCRIPT_CACHE")"
  printf 'path=%s\nsize=%s\ninput=%s\noutput=%s\ncached=%s\ntotal=%s\ncontext_len=%s\nfirst_ts=%s\nlast_ts=%s\n' \
    "$J_TRANSCRIPT_PATH" "$file_size" \
    "$T_INPUT" "$T_OUTPUT" "$T_CACHED" "$T_TOTAL" "$T_CONTEXT_LEN" \
    "$T_FIRST_TS" "$T_LAST_TS" > "$TRANSCRIPT_CACHE"
}

# =============================================================================
# Utility: format_tokens — human-readable token count
#   1500000 → "1.5M"   15000 → "15.0k"   500 → "500"
# =============================================================================
format_tokens() {
  local n=$1
  if [[ $n -ge 1000000 ]]; then
    awk -v n="$n" 'BEGIN { printf "%.1fM", n / 1000000 }'
  elif [[ $n -ge 1000 ]]; then
    awk -v n="$n" 'BEGIN { printf "%.1fk", n / 1000 }'
  else
    printf '%s' "$n"
  fi
}

# =============================================================================
# Utility: get_max_tokens — returns maxTokens and usableTokens for the model
# =============================================================================
get_max_tokens() {
  local model_id="$J_MODEL_ID"
  if [[ "$model_id" == *claude-sonnet-4-5* && "${model_id,,}" == *'[1m]'* ]]; then
    MAX_TOKENS=1000000
    USABLE_TOKENS=800000
  else
    MAX_TOKENS=200000
    USABLE_TOKENS=160000
  fi
}

# =============================================================================
# Widget Functions
# =============================================================================

widget_model() {
  [[ -n "$J_MODEL" ]] && printf '%s' "$J_MODEL"
}

widget_version() {
  [[ -n "$J_VERSION" ]] && printf '%s' "$J_VERSION"
}

widget_output_style() {
  [[ -n "$J_OUTPUT_STYLE" ]] && printf 'Style: %s' "$J_OUTPUT_STYLE"
}

widget_session_id() {
  [[ -n "$J_SESSION_ID" ]] && printf '%s' "${J_SESSION_ID:0:8}…"
}

widget_session_cost() {
  [[ -z "$J_COST" || "$J_COST" == "null" || "$J_COST" == "0" ]] && return
  local fmt
  fmt=$(printf '%.2f' "$J_COST")
  printf '$%s' "$fmt"
}

widget_session_clock() {
  parse_transcript
  [[ -z "$T_FIRST_TS" || -z "$T_LAST_TS" ]] && return

  local first_epoch last_epoch dur_s
  first_epoch=$(date -d "$T_FIRST_TS" +%s 2>/dev/null || date -j -f '%Y-%m-%dT%H:%M:%S' "${T_FIRST_TS%%.*}" +%s 2>/dev/null)
  last_epoch=$(date -d "$T_LAST_TS" +%s 2>/dev/null || date -j -f '%Y-%m-%dT%H:%M:%S' "${T_LAST_TS%%.*}" +%s 2>/dev/null)
  [[ -z "$first_epoch" || -z "$last_epoch" ]] && return

  dur_s=$((last_epoch - first_epoch))
  [[ $dur_s -le 0 ]] && return
  [[ $dur_s -lt 60 ]] && { printf '<1m'; return; }

  local total_m=$((dur_s / 60))
  local h=$((total_m / 60))
  local m=$((total_m % 60))

  if [[ $h -eq 0 ]]; then
    printf '%dm' "$m"
  elif [[ $m -eq 0 ]]; then
    printf '%dhr' "$h"
  else
    printf '%dhr %dm' "$h" "$m"
  fi
}

widget_block_timer() {
  local STATE_FILE="$HOME/.cache/claude_statusline_block_state"
  local NOW FIVE_HOURS block_start last_activity
  NOW=$(date +%s)
  FIVE_HOURS=$((5 * 3600))
  block_start=0
  last_activity=0

  if [[ -f "$STATE_FILE" ]]; then
    while IFS='=' read -r key val; do
      case "$key" in
        block_start) block_start="$val" ;;
        last_activity) last_activity="$val" ;;
      esac
    done < "$STATE_FILE"
  fi

  if [[ $last_activity -eq 0 ]] || [[ $((NOW - last_activity)) -ge $FIVE_HOURS ]]; then
    block_start=$((NOW - NOW % 3600))
  fi

  printf 'block_start=%s\nlast_activity=%s\n' "$block_start" "$NOW" > "$STATE_FILE"

  local elapsed=$((NOW - block_start))
  [[ $elapsed -lt 0 ]] && elapsed=0
  [[ $elapsed -ge $FIVE_HOURS ]] && elapsed=$FIVE_HOURS

  local pct=$((elapsed * 100 / FIVE_HOURS))
  local h=$((elapsed / 3600))
  local m=$(((elapsed % 3600) / 60))

  if [[ $h -gt 0 ]]; then
    printf 'Block: %dh%dm (%d%%)' "$h" "$m" "$pct"
  else
    printf 'Block: %dm (%d%%)' "$m" "$pct"
  fi
}

widget_git_branch() {
  local branch
  branch=$(git -C "${J_CWD:-.}" branch --show-current 2>/dev/null)
  [[ -n "$branch" ]] && printf '⎇ %s' "$branch"
}

widget_git_changes() {
  local cwd="${J_CWD:-.}"
  local staged unstaged added deleted
  staged=$(git -C "$cwd" diff --cached --shortstat 2>/dev/null)
  unstaged=$(git -C "$cwd" diff --shortstat 2>/dev/null)

  added=0; deleted=0
  if [[ -n "$staged" ]]; then
    local sa sd
    sa=$(printf '%s' "$staged" | sed -n 's/.* \([0-9]*\) insertion.*/\1/p')
    sd=$(printf '%s' "$staged" | sed -n 's/.* \([0-9]*\) deletion.*/\1/p')
    added=$((added + ${sa:-0}))
    deleted=$((deleted + ${sd:-0}))
  fi
  if [[ -n "$unstaged" ]]; then
    local ua ud
    ua=$(printf '%s' "$unstaged" | sed -n 's/.* \([0-9]*\) insertion.*/\1/p')
    ud=$(printf '%s' "$unstaged" | sed -n 's/.* \([0-9]*\) deletion.*/\1/p')
    added=$((added + ${ua:-0}))
    deleted=$((deleted + ${ud:-0}))
  fi

  [[ $added -eq 0 && $deleted -eq 0 ]] && return
  printf '(+%d,-%d)' "$added" "$deleted"
}

widget_git_worktree() {
  local cwd="${J_CWD:-.}"
  local git_dir main_wt
  git_dir=$(git -C "$cwd" rev-parse --git-dir 2>/dev/null) || return
  # Detect linked worktree: .git/worktrees/<name>
  if [[ "$git_dir" == *"/worktrees/"* ]]; then
    main_wt=$(basename "$(dirname "$(dirname "$git_dir")")")
    printf '𖠰 %s' "$main_wt"
  fi
}

widget_cwd() {
  [[ -z "$J_CWD" ]] && return
  local p="$J_CWD"
  # Replace $HOME with ~
  p="${p/#$HOME/\~}"

  # Fish-style abbreviation: shorten intermediate directories
  local IFS='/'
  read -ra parts <<< "$p"
  local len=${#parts[@]}
  [[ $len -le 1 ]] && { printf '%s' "$p"; return; }

  local result=""
  # Preserve leading slash for absolute paths
  [[ "$p" == /* ]] && result="/"
  local i
  for ((i = 0; i < len - 1; i++)); do
    local seg="${parts[$i]}"
    if [[ -z "$seg" ]]; then
      continue
    elif [[ "$seg" == "~" ]]; then
      result+="~"
    elif [[ "$seg" == .* ]]; then
      # Hidden dir: keep dot + first char
      result+="${seg:0:2}"
    else
      result+="${seg:0:1}"
    fi
    result+="/"
  done
  result+="${parts[$((len - 1))]}"
  printf '%s' "$result"
}

widget_tokens_input() {
  parse_transcript
  [[ $T_INPUT -eq 0 ]] && return
  printf 'In: %s' "$(format_tokens "$T_INPUT")"
}

widget_tokens_output() {
  parse_transcript
  [[ $T_OUTPUT -eq 0 ]] && return
  printf 'Out: %s' "$(format_tokens "$T_OUTPUT")"
}

widget_tokens_cached() {
  parse_transcript
  [[ $T_CACHED -eq 0 ]] && return
  printf 'Cached: %s' "$(format_tokens "$T_CACHED")"
}

widget_tokens_total() {
  parse_transcript
  [[ $T_TOTAL -eq 0 ]] && return
  printf 'Total: %s' "$(format_tokens "$T_TOTAL")"
}

widget_context_length() {
  parse_transcript
  [[ $T_CONTEXT_LEN -eq 0 ]] && return
  printf 'Ctx: %s' "$(format_tokens "$T_CONTEXT_LEN")"
}

widget_context_percentage() {
  parse_transcript
  get_max_tokens
  [[ $T_CONTEXT_LEN -eq 0 || $MAX_TOKENS -eq 0 ]] && return
  local pct
  pct=$(awk -v ctx="$T_CONTEXT_LEN" -v max="$MAX_TOKENS" 'BEGIN { printf "%.1f", ctx * 100.0 / max }')
  printf 'Ctx: %s%%' "$pct"
}

widget_context_percentage_usable() {
  parse_transcript
  get_max_tokens
  [[ $T_CONTEXT_LEN -eq 0 || $USABLE_TOKENS -eq 0 ]] && return
  local pct
  pct=$(awk -v ctx="$T_CONTEXT_LEN" -v max="$USABLE_TOKENS" 'BEGIN { printf "%.1f", ctx * 100.0 / max }')
  printf 'Ctx(u): %s%%' "$pct"
}

widget_terminal_width() {
  local cols
  cols=$(tput cols 2>/dev/null)
  [[ -n "$cols" ]] && printf 'Term: %s' "$cols"
}

# =============================================================================
# Main — parse input, run widgets, assemble output
# =============================================================================
parse_input

output=""
for w in "${WIDGETS[@]}"; do
  local_result=$("widget_$w")
  [[ -z "$local_result" ]] && continue
  if [[ -n "$output" ]]; then
    output+="${SEPARATOR}${local_result}"
  else
    output="$local_result"
  fi
done

printf "%s" "$output"
