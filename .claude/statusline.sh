#!/usr/bin/env bash
# Claude Code status line script
# Each section is a function — reorder the sections array to change layout.
# No caching: all data is either read from the JSON input or computed directly.

input=$(cat)

# ============================================================
# Data extraction (parsed once, used by section functions)
# ============================================================
eval "$(echo "$input" | jq -r '
  @sh "model=\(.model.display_name // "Unknown")",
  @sh "used_pct=\(.context_window.used_percentage // "")",
  @sh "ctx_size=\(.context_window.context_window_size // 0)",
  @sh "total_in=\(.context_window.total_input_tokens // 0)",
  @sh "total_out=\(.context_window.total_output_tokens // 0)",
  @sh "current_out=\(.context_window.current_usage.output_tokens // 0)",
  @sh "current_in=\(.context_window.current_usage.input_tokens // 0)",
  @sh "cache_read=\(.context_window.current_usage.cache_read_input_tokens // 0)",
  @sh "cache_creation=\(.context_window.current_usage.cache_creation_input_tokens // 0)",
  @sh "total_cost=\(.cost.total_cost_usd // 0)",
  @sh "duration_ms=\(.cost.total_duration_ms // 0)",
  @sh "api_duration_ms=\(.cost.total_api_duration_ms // 0)",
  @sh "cwd=\(.workspace.current_dir // "")",
  @sh "project_dir=\(.workspace.project_dir // "")",
  @sh "transcript_path=\(.transcript_path // "")",
  @sh "session_id=\(.session_id // "")",
  @sh "rl_5h_pct=\(.rate_limits.five_hour.used_percentage // "")",
  @sh "rl_5h_resets=\(.rate_limits.five_hour.resets_at // "")",
  @sh "rl_7d_pct=\(.rate_limits.seven_day.used_percentage // "")",
  @sh "rl_7d_resets=\(.rate_limits.seven_day.resets_at // "")"
')"

# ============================================================
# ANSI colors
# ============================================================
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
MAGENTA='\033[35m'
WHITE='\033[37m'
BLUE='\033[34m'

pct_color() {
  local pct="${1:-0}"
  if [ "$pct" -ge 80 ]; then printf '\033[31m'
  elif [ "$pct" -ge 60 ]; then printf '\033[33m'
  else printf '\033[32m'
  fi
}

_sec() {
  local label="$1" value="$2" color="${3:-$WHITE}"
  [ -z "$value" ] && return
  printf '%b' "${DIM}${label}:${RESET}${color}${value}${RESET}"
}

fmt_tokens() {
  local n="${1:-0}"
  if [ "$n" -ge 1000000 ]; then
    awk "BEGIN{printf \"%.1fM\", $n/1000000}"
  elif [ "$n" -ge 1000 ]; then
    awk "BEGIN{printf \"%.1fk\", $n/1000}"
  else
    echo "$n"
  fi
}

fmt_duration() {
  local ms="${1:-0}"
  local secs=$((ms / 1000))
  if [ "$secs" -ge 3600 ]; then
    printf "%dh%dm" $((secs / 3600)) $(((secs % 3600) / 60))
  elif [ "$secs" -ge 60 ]; then
    printf "%dm%ds" $((secs / 60)) $((secs % 60))
  else
    printf "%ds" "$secs"
  fi
}

# ============================================================
# Session cache (for speed calculation)
# ============================================================
_quota_cache_dir="$HOME/.cache/claude"
_session_cache_dir="$_quota_cache_dir/${session_id:-default}"
mkdir -p "$_session_cache_dir" 2>/dev/null

# Detect custom base URL (used by section_model for color)
_quota_custom_url=0
if [ -n "$ANTHROPIC_BASE_URL" ]; then
  case "$ANTHROPIC_BASE_URL" in
    *api.anthropic.com*) ;;
    *) _quota_custom_url=1 ;;
  esac
fi

# ============================================================
# Real-time computed values
# ============================================================

# Git
_git_dir="${project_dir:-$cwd}"
_git_branch="" _git_dirty="no"
if [ -n "$_git_dir" ] && [ -d "$_git_dir/.git" ]; then
  _git_branch=$(git --no-optional-locks -C "$_git_dir" branch --show-current 2>/dev/null)
  git --no-optional-locks -C "$_git_dir" diff --quiet 2>/dev/null || _git_dirty="yes"
fi

# Transcript: tool-use and todo summaries read directly from the transcript file
tool_summary="" todo_summary=""
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  tool_summary=$(jq -r '
    [.. | objects | select(.type == "tool_use")] as $uses |
    [.. | objects | select(.type == "tool_result")] as $results |
    ($results | map(.tool_use_id) | unique) as $done_ids |
    ($uses | map(select(.id as $id | ($done_ids | index($id)) == null)) | length) as $running |
    ($results | length) as $completed |
    if ($running > 0) then "\($running) running"
    elif ($completed > 0) then "\($completed) done"
    else empty end
  ' "$transcript_path" 2>/dev/null)
  todo_summary=$(jq -r '
    [.. | objects | select(.type == "tool_use" and .name == "TaskCreate")] as $creates |
    [.. | objects | select(.type == "tool_use" and .name == "TaskUpdate" and .input.status == "completed")] as $completes |
    if ($creates | length) > 0 then "\($completes | length)/\($creates | length)"
    else empty end
  ' "$transcript_path" 2>/dev/null)
fi

# ============================================================
# Section functions
# ============================================================

section_model() {
  local display
  case "$model" in
    *"Opus 4.6"*) display="${model// (1M context)/}"; display="${display/Opus 4.6/Opus 4.6 [1m]}" ;;
    *)            display="$model" ;;
  esac
  local model_color="$CYAN"
  if [ "$_quota_custom_url" = "1" ]; then
    model_color="$GREEN"
  fi
  printf '%b' "${BOLD}${model_color}${display}${RESET}"
}

section_project() {
  local dir="${project_dir:-$cwd}"
  [ -z "$dir" ] && return
  printf '%b' "${WHITE}${dir##*/}${RESET}"
}

section_git() {
  [ -z "$_git_branch" ] && return
  local dirty=""
  [ "$_git_dirty" = "yes" ] && dirty="${YELLOW}*${RESET}"
  printf '%b' "${CYAN}${_git_branch}${RESET}${dirty}"
}

section_context() {
  local ctx_part cache_part
  if [ -n "$used_pct" ]; then
    local pct_int; pct_int=$(printf "%.0f" "$used_pct")
    ctx_part="${DIM}ctx:${RESET}$(pct_color "$pct_int")${pct_int}%${RESET}"
  else
    ctx_part="${DIM}no ctx${RESET}"
  fi
  local total=$(( current_in + cache_read + cache_creation ))
  if [ "$total" -gt 0 ] && [ "$cache_read" -gt 0 ]; then
    local cpct=$(( cache_read * 100 / total ))
    cache_part="${DIM}·${RESET}$(pct_color $(( 100 - cpct )))${cpct}%${RESET}"
  fi
  printf '%b' "${ctx_part}${cache_part}"
}

section_cost() {
  if [ "${total_cost:-0}" = "0" ]; then
    printf '%b' "${DIM}cost:...${RESET}"
    return
  fi
  printf '%b' "${MAGENTA}$(printf "\$%.2f" "$total_cost")${RESET}"
}

section_tokens_in()  { _sec "in"  "$(fmt_tokens "$total_in")"; }
section_tokens_out() { _sec "out" "$(fmt_tokens "$total_out")"; }

# Per-session speed cache: stored in the session's own cache directory.
_speed_cache="$_session_cache_dir/speed.json"

section_speed() {
  # Speed = delta(total_output_tokens) / delta(total_api_duration_ms)
  # Output-only: input tokens are batched, not streamed — they skew the number.
  if [ "${total_out:-0}" -le 0 ] 2>/dev/null || [ "${api_duration_ms:-0}" -le 0 ] 2>/dev/null; then
    printf '%b' "${DIM}speed:...${RESET}"
    return
  fi
  local speed_display="" last_speed=""

  if [ -f "$_speed_cache" ]; then
    local prev_total_out prev_api_ms prev_speed
    prev_total_out=$(jq -r '.totalOut // ""' "$_speed_cache" 2>/dev/null)
    prev_api_ms=$(   jq -r '.apiDurationMs // 0' "$_speed_cache" 2>/dev/null)
    prev_speed=$(    jq -r '.lastSpeed // ""' "$_speed_cache" 2>/dev/null)

    if [ -n "$prev_total_out" ]; then
      local delta_out=$(( total_out - prev_total_out ))
      local delta_ms=$(( api_duration_ms - prev_api_ms ))

      if [ "$delta_ms" -gt 0 ] && [ "$delta_out" -gt 0 ]; then
        # tps100 = tokens/s scaled by 100 (for 2 decimal places)
        # delta_out * 100000 / delta_ms = delta_out * 100 * (1000/delta_ms) = t/s * 100
        local tps100=$(( delta_out * 100000 / delta_ms ))
        if [ "$tps100" -gt 0 ]; then
          local t_int=$(( tps100 / 100 ))
          local t_frac=$(( tps100 % 100 ))
          if [ "$t_int" -ge 1000 ]; then
            speed_display="$(printf '%d.%02dkt/s' $(( t_int / 1000 )) $(( (t_int % 1000) / 10 )))"
          else
            speed_display="$(printf '%d.%02dt/s' "$t_int" "$t_frac")"
          fi
        fi
      fi
    fi
    last_speed="$prev_speed"
  fi

  printf '{"totalOut":%d,"apiDurationMs":%d,"lastSpeed":"%s"}' \
    "$total_out" "$api_duration_ms" "${speed_display:-$last_speed}" > "$_speed_cache"

  if [ -n "$speed_display" ]; then
    _sec "speed" "$speed_display"
  elif [ -n "$last_speed" ]; then
    printf '%b' "${DIM}speed:${RESET}${DIM}${last_speed}${RESET}"
  else
    printf '%b' "${DIM}speed:...${RESET}"
  fi
}

section_duration() {
  [ "${duration_ms:-0}" -le 0 ] 2>/dev/null && return
  _sec "time" "$(fmt_duration "$duration_ms")"
}


section_quota_5h() {
  [ -z "$rl_5h_pct" ] && return
  local pct pct_c reset_part=""
  pct=$(printf "%.0f" "$rl_5h_pct")
  pct_c=$(pct_color "$pct")
  if [ -n "$rl_5h_resets" ]; then
    local reset_epoch secs_left tlabel mins hrs
    reset_epoch="$rl_5h_resets"
    if [ -n "$reset_epoch" ]; then
      secs_left=$(( reset_epoch - $(date +%s) ))
      if [ "$secs_left" -le 0 ]; then
        tlabel="now"
      else
        mins=$(( secs_left / 60 )); hrs=$(( secs_left / 3600 ))
        if [ "$hrs" -gt 0 ]; then tlabel="${hrs}h$(( mins % 60 ))m"; else tlabel="${mins}m"; fi
      fi
      reset_part="${DIM}·${RESET}${pct_c}${tlabel}${RESET}"
    fi
  fi
  printf '%b' "${DIM}5h:${RESET}${pct_c}${pct}%${RESET}${reset_part}"
}

section_quota_7d() {
  [ -z "$rl_7d_pct" ] && return
  local pct; pct=$(printf "%.0f" "$rl_7d_pct")
  local pct_c; pct_c=$(pct_color "$pct")
  _sec "7d" "${pct}%" "$pct_c"
}

section_tools() { _sec "tools" "$tool_summary"; }
section_todos() { _sec "todo"  "$todo_summary" "$GREEN"; }

# ============================================================
# Render — single line, all left-aligned
# ============================================================
SEP="  "

sections=(
  section_model
  section_context
  section_quota_5h
  section_quota_7d
  section_cost
  section_speed
)

# Build output
output=""
for item in "${sections[@]}"; do
  part=$($item)
  [ -n "$part" ] && output="${output:+${output}${SEP}}${part}"
done

printf '%b\n' "$output"

# Clean up session cache directories older than 24 hours.
find "$_quota_cache_dir" -maxdepth 1 -mindepth 1 -type d -mmin +1440 -exec rm -rf {} + 2>/dev/null || true

exit 0

