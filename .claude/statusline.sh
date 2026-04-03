#!/usr/bin/env bash
# Claude Code status line script
# Each section is a function — reorder the sections array to change layout.

input=$(cat)
echo "$input" > /tmp/statusline_debug.json

# ============================================================
# Data extraction (parsed once, used by section functions)
# ============================================================
eval "$(echo "$input" | jq -r '
  @sh "model=\(.model.display_name // "Unknown")",
  @sh "used_pct=\(.context_window.used_percentage // "")",
  @sh "total_out=\(.context_window.total_output_tokens // 0)",
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
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
MAGENTA='\033[35m'
WHITE='\033[37m'
CYAN='\033[36m'

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

_pending() {
  local label="$1"
  printf '%b' "${DIM}${label}:...${RESET}"
}

_fmt_speed() {
  # Format tps100 (tokens/s * 100) into a human-readable speed string.
  local tps100="$1"
  [ "$tps100" -le 0 ] && return
  local t_int=$(( tps100 / 100 )) t_frac=$(( tps100 % 100 ))
  if [ "$t_int" -ge 1000 ]; then
    printf '%d.%02dkt/s' $(( t_int / 1000 )) $(( (t_int % 1000) / 10 ))
  else
    printf '%d.%02dt/s' "$t_int" "$t_frac"
  fi
}

_quota_bar() {
  # 2D bar: horizontal extent = pct_h, block height = pct_v
  # Usage: _quota_bar pct_h pct_v [width=8] [color]
  local pct_h="$1" pct_v="$2" width="${3:-8}" c_override="${4:-}"
  local active=$(( pct_h > 0 ? (pct_h * width + 99) / 100 : 0 ))
  local empty=$(( width - active ))

  local v=$(( (pct_v * 7 + 99) / 100 ))
  (( v > 7 )) && v=7
  local blocks=('▁' '▂' '▃' '▄' '▅' '▆' '▇' '█')
  local vert_char="${blocks[$v]}"

  local c
  if [ -n "$c_override" ]; then
    c="$c_override"
  else
    local worse=$(( pct_v > pct_h ? pct_v : pct_h ))
    c=$(pct_color "$worse")
  fi

  local bar="" i
  for (( i = 0; i < active; i++ )); do bar="${bar}${c}${vert_char}${RESET}"; done
  for (( i = 0; i < empty;  i++ )); do bar="${bar}\033[2;90m${vert_char}${RESET}"; done

  printf '%b' "$bar"
}

fmt_tokens() {
  local n="${1:-0}"
  if [ "$n" -ge 1000000 ]; then
    printf '%d.%dM' $(( n / 1000000 )) $(( (n % 1000000) / 100000 ))
  elif [ "$n" -ge 1000 ]; then
    printf '%d.%dk' $(( n / 1000 )) $(( (n % 1000) / 100 ))
  else
    printf '%d' "$n"
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
# Top-level setup (computed once per render)
# ============================================================
_quota_cache_dir="$HOME/.cache/claude"
_session_cache_dir="$_quota_cache_dir/${session_id:-default}"
mkdir -p "$_session_cache_dir" 2>/dev/null

# Detect custom base URL (used by section_quota to hide Anthropic-specific rate limits)
_quota_custom_url=0
if [ -n "$ANTHROPIC_BASE_URL" ]; then
  case "$ANTHROPIC_BASE_URL" in
    *api.anthropic.com*) ;;
    *) _quota_custom_url=1 ;;
  esac
fi

# Detect subscription type from credentials (avoids per-render file I/O in section_cost)
_is_subscription=0
_creds="$HOME/.claude/.credentials.json"
if [ -f "$_creds" ]; then
  _sub=$(jq -r '.claudeAiOauth.subscriptionType // ""' "$_creds" 2>/dev/null)
  [ -n "$_sub" ] && [ "$_sub" != "null" ] && _is_subscription=1
fi

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
  printf '%b' "${BOLD}${GREEN}${display}${RESET}"
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
  if [ -z "$used_pct" ]; then
    printf '%b' "${DIM}no ctx${RESET}"
    return
  fi
  local pct_int; pct_int=$(printf "%.0f" "$used_pct")
  local cache_pct=0
  local total=$(( current_in + cache_read + cache_creation ))
  [ "$total" -gt 0 ] && [ "$cache_read" -gt 0 ] && cache_pct=$(( cache_read * 100 / total ))
  local bar_color
  if [ "$pct_int" -ge 80 ]; then bar_color="$RED"
  elif [ "$pct_int" -ge 60 ]; then bar_color="$YELLOW"
  else bar_color="$GREEN"
  fi
  local c; c=$(pct_color "$pct_int")
  printf '%b' "$(_quota_bar "$pct_int" "$cache_pct" 8 "$bar_color") ${c}${pct_int}%${RESET}${DIM}/${RESET}${CYAN}${cache_pct}%${RESET}"
}

section_cost() {
  # Subscription users: cost is shadow-tracked equivalent, not actual billing — always hide
  if [ "$_quota_custom_url" = "0" ] && { [ -n "$rl_5h_pct" ] || [ -n "$rl_7d_pct" ] || [ "$_is_subscription" = "1" ]; }; then
    return
  fi
  if [ "${total_cost:-0}" = "0" ]; then
    _pending "cost"
    return
  fi
  printf '%b' "${MAGENTA}$(printf "\$%.2f" "$total_cost")${RESET}"
}

section_tokens_in()  { _sec "in"  "$(fmt_tokens "$total_in")"; }
section_tokens_out() { _sec "out" "$(fmt_tokens "$total_out")"; }

# Per-session speed cache
_speed_cache="$_session_cache_dir/speed.json"

section_speed() {
  # Speed = delta(output_tokens) / delta(api_duration_ms); output-only to avoid prefill skew.
  if [ "${total_out:-0}" -le 0 ] 2>/dev/null || [ "${api_duration_ms:-0}" -le 0 ] 2>/dev/null; then
    _pending "speed"
    return
  fi
  local speed_display="" last_speed=""

  if [ ! -f "$_speed_cache" ]; then
    # First message: fall back to cumulative average as initial estimate
    speed_display="$(_fmt_speed $(( total_out * 100000 / api_duration_ms )))"
  else
    eval "$(jq -r '@sh "prev_total_out=\(.totalOut // "")
prev_api_ms=\(.apiDurationMs // 0)
last_speed=\(.lastSpeed // "")"' "$_speed_cache" 2>/dev/null)"

    if [ -n "$prev_total_out" ]; then
      local delta_out=$(( total_out - prev_total_out ))
      local delta_ms=$(( api_duration_ms - prev_api_ms ))
      if [ "$delta_ms" -gt 0 ] && [ "$delta_out" -gt 0 ]; then
        speed_display="$(_fmt_speed $(( delta_out * 100000 / delta_ms )))"
      fi
    fi
  fi

  printf '{"totalOut":%d,"apiDurationMs":%d,"lastSpeed":"%s"}' \
    "$total_out" "$api_duration_ms" "${speed_display:-$last_speed}" > "$_speed_cache"

  if [ -n "$speed_display" ]; then
    _sec "speed" "$speed_display"
  elif [ -n "$last_speed" ]; then
    _sec "speed" "$last_speed" "$DIM"
  else
    _pending "speed"
  fi
}

section_duration() {
  [ "${duration_ms:-0}" -le 0 ] 2>/dev/null && return
  _sec "time" "$(fmt_duration "$duration_ms")"
}

section_quota() {
  [ "$_quota_custom_url" = "1" ] && return
  local pct5="" pct7=""
  [ -n "$rl_5h_pct" ] && pct5=$(printf "%.0f" "$rl_5h_pct")
  [ -n "$rl_7d_pct" ] && pct7=$(printf "%.0f" "$rl_7d_pct")
  [ -z "$pct5" ] && [ -z "$pct7" ] && { _pending "rl"; return; }
  local bar_color
  if [ "${pct5:-0}" -ge 80 ]; then bar_color="$RED"
  elif [ "${pct5:-0}" -ge 60 ]; then bar_color="$YELLOW"
  else bar_color="$GREEN"
  fi
  local c; c=$(pct_color "$pct5")
  local reset_part=""
  if [ -n "$rl_5h_resets" ]; then
    local secs_left=$(( rl_5h_resets - EPOCHSECONDS ))
    if [ "$secs_left" -le 0 ]; then
      reset_part=" ${DIM}now${RESET}"
    else
      local mins=$(( secs_left / 60 )) hrs=$(( secs_left / 3600 ))
      local tlabel
      if [ "$hrs" -gt 0 ]; then tlabel="${hrs}h$(( mins % 60 ))m"; else tlabel="${mins}m"; fi
      reset_part=" ${DIM}${tlabel}${RESET}"
    fi
  fi
  local pct7_remain="" pct7_display=""
  if [ -n "$pct7" ]; then
    pct7_remain=$(( 100 - pct7 ))
    pct7_display="${DIM}/${RESET}${DIM}${pct7}%${RESET}"
  fi
  printf '%b' "$(_quota_bar "${pct5:-0}" "${pct7_remain:-0}" 8 "$bar_color") ${c}${pct5}%${RESET}${pct7_display}${reset_part}"
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
  section_quota
  section_cost
  section_speed
)

output=""
for item in "${sections[@]}"; do
  part=$($item)
  [ -n "$part" ] && output="${output:+${output}${SEP}}${part}"
done

printf '%b\n' "$output"

# Clean up session cache dirs older than 24h — probabilistic to avoid fork on every render
(( RANDOM % 60 == 0 )) && find "$_quota_cache_dir" -maxdepth 1 -mindepth 1 -type d -mmin +1440 -exec rm -rf {} + 2>/dev/null || true

exit 0
