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
# Quota — shared cache with file locking to avoid rate limiting
# All Claude Code sessions share ~/.cache/claude/quota.json.
# Only one session fetches at a time (via flock), others read the cache.
# TTL: 60 seconds (aligned with claude-hud).
# ============================================================
_quota_cache_dir="$HOME/.cache/claude"
_quota_file="$_quota_cache_dir/quota.json"
_quota_lock="$_quota_cache_dir/quota.lock"
_quota_backoff="$_quota_cache_dir/quota.backoff"
_quota_ttl=300  # Cache TTL in seconds
_quota_token=$(jq -r '.claudeAiOauth.accessToken // empty' \
  "$HOME/.claude/.credentials.json" 2>/dev/null)

# Ensure cache directory exists
[ ! -d "$_quota_cache_dir" ] && mkdir -p "$_quota_cache_dir" 2>/dev/null

# Fire curl in the background only if cache is stale or missing.
# Use flock to ensure only one session fetches at a time.
if [ -n "$_quota_token" ]; then
  _should_fetch=0
  if [ ! -f "$_quota_file" ]; then
    _should_fetch=1
  else
    _file_age=$(($(date +%s) - $(stat -c %Y "$_quota_file" 2>/dev/null || echo 0)))
    # Only refetch if older than 60 seconds
    if [ "$_file_age" -gt "$_quota_ttl" ]; then
      _should_fetch=1
    fi
  fi
  if [ "$_should_fetch" = "1" ]; then
    # Check backoff: if quota.backoff exists and is < 10 minutes old, skip fetch
    _in_backoff=0
    if [ -f "$_quota_backoff" ]; then
      _backoff_ts=$(cat "$_quota_backoff" 2>/dev/null)
      if [ -n "$_backoff_ts" ] && [ "$(( $(date +%s) - _backoff_ts ))" -lt 600 ]; then
        _in_backoff=1
      else
        rm -f "$_quota_backoff" 2>/dev/null
      fi
    fi
    if [ "$_in_backoff" = "0" ]; then
      # Use flock with non-blocking mode: if another session is fetching, skip
      (
        flock -n 200 || exit 0
        _resp=$(curl -sf --max-time 5 \
          -H "Authorization: Bearer $_quota_token" \
          -H "anthropic-beta: oauth-2025-04-20" \
          "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
        _curl_exit=$?
        if [ "$_curl_exit" -eq 0 ] && [ -n "$_resp" ]; then
          # Check for rate_limit_error in response body
          if printf '%s' "$_resp" | grep -q '"rate_limit_error"'; then
            date +%s > "$_quota_backoff" 2>/dev/null
          else
            printf '%s' "$_resp" > "$_quota_file.tmp" 2>/dev/null \
              && mv -f "$_quota_file.tmp" "$_quota_file" 2>/dev/null \
              || rm -f "$_quota_file.tmp" 2>/dev/null
          fi
        elif [ "$_curl_exit" -eq 22 ]; then
          # HTTP 4xx/5xx from -f flag; treat as rate limit backoff
          date +%s > "$_quota_backoff" 2>/dev/null
        else
          rm -f "$_quota_file.tmp" 2>/dev/null
        fi
      ) 200>"$_quota_lock" &
    fi
  fi
fi

# Read the shared cache file.
# _quota_ready: 0 = no token (quota N/A), 1 = token exists but no valid data yet (show placeholder), 2 = data available
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
      # Stale: cache much older than TTL means the last fetch truly failed (e.g. rate limited).
      # Use 2x TTL to avoid false positives from async background fetches that haven't
      # completed yet (fetch is non-blocking, so file age can briefly exceed TTL).
      _quota_stale=0
      _cache_age=$(($(date +%s) - $(stat -c %Y "$_quota_file" 2>/dev/null || echo 0)))
      [ "$_cache_age" -gt "$(( _quota_ttl * 2 ))" ] && _quota_stale=1
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
  printf '%b' "${CYAN}${display}${RESET}"
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
  # Only show cost once something has been spent
  [ "${total_cost:-0}" = "0" ] && return
  printf '%b' "${MAGENTA}$(printf "\$%.2f" "$total_cost")${RESET}"
}

section_tokens_in()  { _sec "in"  "$(fmt_tokens "$total_in")"; }
section_tokens_out() { _sec "out" "$(fmt_tokens "$total_out")"; }

section_duration() {
  [ "${duration_ms:-0}" -le 0 ] 2>/dev/null && return
  _sec "time" "$(fmt_duration "$duration_ms")"
}

section_quota_5h() {
  [ "$_quota_ready" = "0" ] && return
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
)

# Build output
output=""
for item in "${sections[@]}"; do
  part=$($item)
  [ -n "$part" ] && output="${output:+${output}${SEP}}${part}"
done

printf '%b\n' "$output"
exit 0

