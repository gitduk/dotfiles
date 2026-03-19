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
  @sh "total_cost=\(.cost.total_cost_usd // 0)",
  @sh "duration_ms=\(.cost.total_duration_ms // 0)",
  @sh "api_duration_ms=\(.cost.total_api_duration_ms // 0)",
  @sh "cwd=\(.workspace.current_dir // "")",
  @sh "project_dir=\(.workspace.project_dir // "")",
  @sh "transcript_path=\(.transcript_path // "")",
  @sh "session_id=\(.session_id // "")"
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
# Quota — per-session cache under ~/.cache/claude/<session_id>/
# Each session maintains its own quota cache; TTL prevents over-fetching.
# TTL: 300 seconds (5 minutes) to avoid rate limiting.
# Backoff: on fetch failure, record next-allowed time in quota.backoff
#   - If Retry-After header present, use it; else default 300s backoff.
# ============================================================
_quota_cache_dir="$HOME/.cache/claude"
_session_cache_dir="$_quota_cache_dir/${session_id:-default}"
_quota_file="$_session_cache_dir/quota.json"
_quota_lock="$_session_cache_dir/quota.lock"
_quota_backoff_file="$_session_cache_dir/quota.backoff"
_quota_ttl=300  # Cache TTL in seconds (5 minutes)
_quota_token=$(jq -r '.claudeAiOauth.accessToken // empty' \
  "$HOME/.claude/.credentials.json" 2>/dev/null)

# Ensure per-session cache directory exists
mkdir -p "$_session_cache_dir" 2>/dev/null

# Fire curl in the background only if cache is stale or missing,
# and we are not in a backoff window from a previous failure.
# Use flock with non-blocking mode: if another session is already fetching, skip.
if [ -n "$_quota_token" ]; then
  _should_fetch=0
  _now=$(date +%s)

  # Check backoff: if backoff file exists and its timestamp is in the future, skip fetch
  _backoff_until=0
  if [ -f "$_quota_backoff_file" ]; then
    _backoff_until=$(cat "$_quota_backoff_file" 2>/dev/null || echo 0)
  fi

  if [ "$_now" -lt "${_backoff_until:-0}" ] 2>/dev/null; then
    _should_fetch=0  # Still in backoff window
  elif [ ! -f "$_quota_file" ]; then
    _should_fetch=1
  else
    _file_age=$(( _now - $(stat -c %Y "$_quota_file" 2>/dev/null || echo 0) ))
    [ "$_file_age" -gt "$_quota_ttl" ] && _should_fetch=1
  fi

  if [ "$_should_fetch" = "1" ]; then
    (
      flock -n 200 || exit 0
      # Re-check backoff inside the lock (another session may have just set it)
      _inner_now=$(date +%s)
      _inner_backoff=0
      [ -f "$_quota_backoff_file" ] && _inner_backoff=$(cat "$_quota_backoff_file" 2>/dev/null || echo 0)
      [ "$_inner_now" -lt "${_inner_backoff:-0}" ] 2>/dev/null && exit 0

      # Re-check TTL inside the lock (avoid double fetch)
      if [ -f "$_quota_file" ]; then
        _inner_age=$(( _inner_now - $(stat -c %Y "$_quota_file" 2>/dev/null || echo 0) ))
        [ "$_inner_age" -le "$_quota_ttl" ] && exit 0
      fi

      # Fetch with response headers to detect Retry-After
      _resp_headers=$(mktemp)
      _resp_body=$(mktemp)
      _http_code=$(curl -s --max-time 8 \
        -D "$_resp_headers" \
        -o "$_resp_body" \
        -w "%{http_code}" \
        -H "Authorization: Bearer $_quota_token" \
        -H "anthropic-beta: oauth-2025-04-20" \
        "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

      if [ "$_http_code" = "200" ]; then
        # Success: update cache, clear any backoff
        mv -f "$_resp_body" "$_quota_file" 2>/dev/null
        rm -f "$_quota_backoff_file" 2>/dev/null
      else
        # Failure: set backoff window
        _retry_after=$(grep -i '^retry-after:' "$_resp_headers" 2>/dev/null \
          | head -1 | awk '{print $2}' | tr -d '[:space:][:cntrl:]')
        if [ -n "$_retry_after" ] && [ "$_retry_after" -eq "$_retry_after" ] 2>/dev/null; then
          _backoff_secs="$_retry_after"
        else
          _backoff_secs=300  # Default 5-minute backoff on any error
        fi
        echo $(( $(date +%s) + _backoff_secs )) > "$_quota_backoff_file" 2>/dev/null
        rm -f "$_resp_body" 2>/dev/null
      fi
      rm -f "$_resp_headers" 2>/dev/null
    ) 200>"$_quota_lock" &
  fi
fi

# Read the shared cache file.
# _quota_ready: 0 = no token (quota N/A), 1 = token exists but no valid data yet (show placeholder), 2 = data available
# Detect custom base URL: if ANTHROPIC_BASE_URL is set and points away from
# the official api.anthropic.com endpoint, quota data is irrelevant (different
# provider / proxy won't serve the usage API).
_quota_custom_url=0
if [ -n "$ANTHROPIC_BASE_URL" ]; then
  case "$ANTHROPIC_BASE_URL" in
    *api.anthropic.com*) ;;  # official endpoint — quota still applies
    *) _quota_custom_url=1 ;;
  esac
fi

_quota_five_h="" _quota_seven_d="" _quota_json=""
_quota_ready=0
if [ -n "$_quota_token" ]; then
  _quota_ready=1  # token exists, default to placeholder
  if [ -f "$_quota_file" ]; then
    _quota_json=$(cat "$_quota_file" 2>/dev/null)
    if [ -n "$_quota_json" ]; then
      # Parse both fields in a single jq call
      eval "$(printf '%s' "$_quota_json" | jq -r '
        @sh "_quota_five_h=\(.five_hour.utilization  // "")",
        @sh "_quota_seven_d=\(.seven_day.utilization // "")"
      ' 2>/dev/null)"
      # Only mark ready if we actually got valid data
      if [ -n "$_quota_five_h" ] || [ -n "$_quota_seven_d" ]; then
        _quota_ready=2
      fi
      # Stale: cache older than TTL means the last fetch failed (e.g. rate limited)
      _quota_stale=0
      _cache_age=$(($(date +%s) - $(stat -c %Y "$_quota_file" 2>/dev/null || echo 0)))
      [ "$_cache_age" -gt "$_quota_ttl" ] && _quota_stale=1
    fi
  fi
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
  if [ -n "$used_pct" ]; then
    local pct_int; pct_int=$(printf "%.0f" "$used_pct")
    _sec "ctx" "${pct_int}%" "$(pct_color "$pct_int")"
  else
    printf '%b' "${DIM}no ctx${RESET}"
  fi
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
  # Speed = delta(total_input_tokens + total_output_tokens) / delta(total_api_duration_ms)
  # Both are cumulative session totals; consistent baseline.
  local total_tokens=$(( total_in + total_out ))
  if [ "${total_tokens:-0}" -le 0 ] 2>/dev/null || [ "${api_duration_ms:-0}" -le 0 ] 2>/dev/null; then
    printf '%b' "${DIM}speed:...${RESET}"
    return
  fi
  local speed_display="" last_speed=""

  if [ -f "$_speed_cache" ]; then
    local prev_total_tokens prev_api_ms prev_speed
    # Use empty string (not 0) as default so we can detect a missing/stale cache entry
    prev_total_tokens=$(jq -r '.totalTokens // ""' "$_speed_cache" 2>/dev/null)
    prev_api_ms=$(      jq -r '.apiDurationMs // 0' "$_speed_cache" 2>/dev/null)
    prev_speed=$(       jq -r '.lastSpeed // ""'   "$_speed_cache" 2>/dev/null)

    # Skip calculation if prev_total_tokens is absent (old cache format)
    if [ -n "$prev_total_tokens" ]; then
      local delta_tokens=$(( total_tokens - prev_total_tokens ))
      local delta_ms=$(( api_duration_ms - prev_api_ms ))

      if [ "$delta_ms" -gt 0 ] && [ "$delta_tokens" -gt 0 ]; then
        # tps in micro-tokens/s for precision at low speeds; convert to tok/s for display
        local tps_micro=$(( delta_tokens * 1000000 / delta_ms ))
        if [ "$tps_micro" -gt 0 ]; then
          local t_int=$(( tps_micro / 1000000 ))
          local t_frac=$(( (tps_micro % 1000000 + 5000) / 10000 ))
          [ "$t_frac" -ge 100 ] && t_int=$(( t_int + 1 )) && t_frac=0
          if [ "$t_int" -ge 1000 ]; then
            local kt_int=$(( t_int / 1000 ))
            local kt_frac=$(( (t_int % 1000 + 5) / 10 ))
            speed_display="$(printf '%d.%02dkt/s' "$kt_int" "$kt_frac")"
          else
            speed_display="$(printf '%d.%02dt/s' "$t_int" "$t_frac")"
          fi
        fi
      fi
    fi  # end prev_total_out check
    last_speed="$prev_speed"
  fi

  printf '{"totalTokens":%d,"apiDurationMs":%d,"lastSpeed":"%s"}' \
    "$total_tokens" "$api_duration_ms" "${speed_display:-$last_speed}" > "$_speed_cache"

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
  # Show 5h regardless of base URL; only skip if there is no token at all.
  [ -z "$_quota_token" ] && return
  if [ "$_quota_ready" = "1" ]; then
    printf '%b' "${DIM}5h:...${RESET}"
    return
  fi
  [ -z "$_quota_five_h" ] && return
  local pct pct_c reset_part=""
  pct=$(printf "%.0f" "$_quota_five_h")
  pct_c=$([ "$_quota_stale" = "1" ] && printf '%b' "$DIM" || pct_color "$pct")
  local resets_at
  resets_at=$(printf '%s' "$_quota_json" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
  if [ -n "$resets_at" ]; then
    local reset_epoch secs_left tlabel mins hrs
    reset_epoch=$(date -d "$resets_at" +%s 2>/dev/null)
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
  [ "$_quota_ready" = "0" ] && return
  if [ "$_quota_ready" = "1" ]; then
    printf '%b' "${DIM}7d:...${RESET}"
    return
  fi
  [ -z "$_quota_seven_d" ] && return
  local pct; pct=$(printf "%.0f" "$_quota_seven_d")
  local pct_c; pct_c=$([ "$_quota_stale" = "1" ] && printf '%b' "$DIM" || pct_color "$pct")
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

