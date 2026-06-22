#!/usr/bin/env bash
# Claude Code status line script
# Each section is a function — reorder the sections array to change layout.

input=$(cat)
[ -n "$STATUSLINE_DEBUG" ] && echo "$input" > /tmp/statusline_debug.json

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
  local label="$1" value="$2" color="${3:-$WHITE}" sep="${4:- }"
  [ -z "$value" ] && return
  printf '%b' "${DIM}${label}${sep}${RESET}${color}${value}${RESET}"
}

_pending() {
  local label="$1"
  printf '%b' "${DIM}${label} -${RESET}"
}

_fmt_speed() {
  # Format tps100 (tokens/s * 100) into a human-readable speed string.
  local tps100="$1"
  [ "$tps100" -le 0 ] && return
  local t_int=$(( tps100 / 100 ))
  if [ "$t_int" -ge 1000 ]; then
    printf '%dkt/s' $(( t_int / 1000 ))
  else
    printf '%dt/s' "$t_int"
  fi
}

_quota_bar() {
  # Horizontal progress bar.
  # Usage: _quota_bar pct [width=8] [color]
  local pct_h="$1" width="${2:-8}" c_override="${3:-}"
  local active=$(( pct_h > 0 ? (pct_h * width + 99) / 100 : 0 ))

  local c
  if [ -n "$c_override" ]; then
    c="$c_override"
  else
    c=$(pct_color "$pct_h")
  fi

  local bar="" i
  for (( i = 0; i < width; i++ )); do
    if [ "$i" -lt "$active" ]; then
      bar="${bar}${c}▰${RESET}"
    else
      bar="${bar}\033[38;2;130;130;130m▱${RESET}"
    fi
  done

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

fmt_reset() {
  # Human-readable countdown from a reset-time delta (seconds). Days only show
  # when present, so this serves both the 7d and 5h quota windows.
  local secs_left="$1"
  [ "$secs_left" -le 0 ] && { printf 'now'; return; }
  local mins=$(( secs_left / 60 )) hrs=$(( secs_left / 3600 )) days=$(( secs_left / 86400 ))
  if [ "$days" -gt 0 ]; then printf '%dd%dh' "$days" $(( hrs % 24 ))
  elif [ "$hrs" -gt 0 ]; then printf '%dh%dm' "$hrs" $(( mins % 60 ))
  else printf '%dm' "$mins"
  fi
}

# ============================================================
# Top-level setup (computed once per render)
# ============================================================
_quota_cache_dir="$HOME/.cache/claude"
_session_cache_dir="$_quota_cache_dir/${session_id:-default}"
_global_cache="$_quota_cache_dir/global.json"
mkdir -p "$_session_cache_dir" 2>/dev/null

# Load global persistent cache (populated by previous renders)
_gc_rl_5h_pct="" _gc_rl_7d_pct="" _gc_rl_5h_resets="" _gc_rl_7d_resets=""
_gc_cost="" _gc_speed=""
if [ -f "$_global_cache" ]; then
  eval "$(jq -r '@sh "
_gc_rl_5h_pct=\(.rl_5h_pct // "")
_gc_rl_7d_pct=\(.rl_7d_pct // "")
_gc_rl_5h_resets=\(.rl_5h_resets // "")
_gc_rl_7d_resets=\(.rl_7d_resets // "")
_gc_cost=\(.cost // "")
_gc_speed=\(.speed // "")
"' "$_global_cache" 2>/dev/null)" 2>/dev/null || true

  # Discard stale quota cache: if the 5h reset time has already passed,
  # the cached percentages are from a completed window and meaningless.
  # (The 7d window is long-lived enough that mid-window stale is still useful.)
  if [ -n "$_gc_rl_5h_resets" ] && [ "$_gc_rl_5h_resets" -lt "$EPOCHSECONDS" ] 2>/dev/null; then
    _gc_rl_5h_pct="" _gc_rl_5h_resets=""
    _gc_rl_7d_pct="" _gc_rl_7d_resets=""
  fi
fi

# Write fresh data into global cache whenever we have real values
_gc_needs_write=0
_gc_new_rl_5h_pct="${rl_5h_pct:-$_gc_rl_5h_pct}"
_gc_new_rl_7d_pct="${rl_7d_pct:-$_gc_rl_7d_pct}"
_gc_new_rl_5h_resets="${rl_5h_resets:-$_gc_rl_5h_resets}"
_gc_new_rl_7d_resets="${rl_7d_resets:-$_gc_rl_7d_resets}"
{ [ -n "$rl_5h_pct" ] || [ -n "$rl_7d_pct" ]; } && _gc_needs_write=1 || true

# Detect whether we're actually using the subscription channel this session.
# When ANTHROPIC_BASE_URL is set (third-party API), only trust live rate_limits
# from the current session — cached data from previous subscription sessions
# must not bleed through. Without ANTHROPIC_BASE_URL, allow cached data so
# subscription users see stale quota immediately on session start.
_use_subscription=0
if [ -n "$ANTHROPIC_BASE_URL" ]; then
  { [ -n "$rl_5h_pct" ] || [ -n "$rl_7d_pct" ]; } && _use_subscription=1 || true
else
  { [ -n "$rl_5h_pct" ] || [ -n "$rl_7d_pct" ] || \
    [ -n "$_gc_rl_5h_pct" ] || [ -n "$_gc_rl_7d_pct" ]; } && _use_subscription=1 || true
fi

# Resolved project directory (project_dir, falling back to cwd) — used by Git
# and the project/settings/mcp sections.
_proj="${project_dir:-$cwd}"

# Git
_git_branch="" _git_dirty="no" _git_ins=0 _git_del=0
if [ -n "$_proj" ] && git --no-optional-locks -C "$_proj" rev-parse --git-dir >/dev/null 2>&1; then
  _git_branch=$(git --no-optional-locks -C "$_proj" branch --show-current 2>/dev/null)
  _shortstat=$(git --no-optional-locks -C "$_proj" diff --shortstat HEAD 2>/dev/null)
  if [ -n "$_shortstat" ]; then
    _git_dirty="yes"
    _git_ins=$(echo "$_shortstat" | grep -o '[0-9]* insertion' | grep -o '[0-9]*' || echo 0)
    _git_del=$(echo "$_shortstat" | grep -o '[0-9]* deletion' | grep -o '[0-9]*' || echo 0)
    _git_ins="${_git_ins:-0}"; _git_del="${_git_del:-0}"
  fi
fi

# ============================================================
# Section functions
# ============================================================

section_model() {
  local display
  case "$model" in
    *" (1M context)"*) display="${model/ (1M context)/ [1m]}" ;;
    *)                 display="$model" ;;
  esac
  printf '%b' "${BOLD}${GREEN}${display}${RESET}"
}

section_mem() {
  local dir="$_proj"
  [ -z "$dir" ] && return
  # Claude Code encodes project paths by replacing non-alphanumeric chars
  # with "-" (e.g. /home/wukaige/.claude -> -home-wukaige--claude)
  local encoded="${dir//[^a-zA-Z0-9]/-}"
  local mem_file="$HOME/.claude/projects/$encoded/memory/MEMORY.md"
  [ -f "$mem_file" ] || return
  local count
  count=$(grep -cE '^(- |# [a-z])' "$mem_file" 2>/dev/null || true)
  [ "${count:-0}" -gt 0 ] && _sec "mem" "$count" "$CYAN"
}

section_project() {
  local dir="$_proj"
  [ -z "$dir" ] && return
  local name="${dir##*/}"
  # Inline git branch when available
  local git_part=""
  if [ -n "$_git_branch" ]; then
    local dirty=""
    if [ "$_git_dirty" = "yes" ]; then
      local stat_ins="${_git_ins:-0}" stat_del="${_git_del:-0}"
      local stat_str=""
      [ "$stat_ins" -gt 0 ] && stat_str="${stat_str}${GREEN}+${stat_ins}${RESET}"
      [ "$stat_ins" -gt 0 ] && [ "$stat_del" -gt 0 ] && stat_str="${stat_str}${DIM}/${RESET}"
      [ "$stat_del" -gt 0 ] && stat_str="${stat_str}${RED}-${stat_del}${RESET}"
      [ -n "$stat_str" ] && dirty=" ${stat_str}"
    fi
    git_part=" ${CYAN}${_git_branch}${RESET}${dirty}"
  fi
  printf '%b' "\033[34m󰏗 ${name}${RESET}${git_part}"
}

section_context() {
  if [ -z "$used_pct" ]; then
    # No context data yet (initialization) — show empty bar
    printf '%b' "${DIM}ctx${RESET} $(_quota_bar 0 10) ${DIM}-${RESET}"
    return
  fi
  local pct_int; pct_int=$(printf "%.0f" "$used_pct")
  local cache_pct=0
  local total=$(( current_in + cache_read + cache_creation ))
  [ "$total" -gt 0 ] && [ "$cache_read" -gt 0 ] && cache_pct=$(( cache_read * 100 / total ))
  local c; c=$(pct_color "$pct_int")
  printf '%b' "${DIM}ctx${RESET} $(_quota_bar "$pct_int" 10 "$c") ${c}${pct_int}%${RESET}${DIM}/${RESET}${CYAN}${cache_pct}%${RESET}"
}

section_cost() {
  if [ "${total_cost:-0}" = "0" ]; then
    # Show last known cost from global cache as a stale hint
    if [ -n "$_gc_cost" ] && [ "$_gc_cost" != "0" ]; then
      printf '%b' "${DIM}${MAGENTA}$(printf "\$%s" "$_gc_cost")${RESET}"
    else
      _pending "cost"
    fi
    return
  fi
  # Persist to global cache
  _gc_new_cost="$(printf "%.2f" "$total_cost")"
  _gc_needs_write=1
  printf '%b' "${MAGENTA}$(printf "\$%.2f" "$total_cost")${RESET}"
}

# Per-session speed cache
_speed_cache="$_session_cache_dir/speed.json"

section_speed() {
  # Speed = delta(output_tokens) / delta(api_duration_ms); output-only to avoid prefill skew.
  if [ "${total_out:-0}" -le 0 ] 2>/dev/null || [ "${api_duration_ms:-0}" -le 0 ] 2>/dev/null; then
    # No live data yet — show last known speed from global cache (dimmed)
    if [ -n "$_gc_speed" ]; then
      printf '%b' "${DIM}spd ${_gc_speed}${RESET}"
    else
      printf '%b' "${DIM}spd -${RESET}"
    fi
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

  # Persist best known speed to global cache
  local _best_speed="${speed_display:-$last_speed}"
  if [ -n "$_best_speed" ]; then
    _gc_new_speed="$_best_speed"
    _gc_needs_write=1
  fi

  if [ -n "$speed_display" ]; then
    printf '%b' "${DIM}spd ${speed_display}${RESET}"
  elif [ -n "$last_speed" ]; then
    printf '%b' "${DIM}spd ${last_speed}${RESET}"
  else
    printf '%b' "${DIM}spd -${RESET}"
  fi
}

section_duration() {
  [ "${duration_ms:-0}" -le 0 ] 2>/dev/null && return
  _sec "time" "$(fmt_duration "$duration_ms")"
}

section_quota() {
  local pct5="" pct7="" _stale=0
  if [ "$_use_subscription" = "1" ]; then
    [ -n "$rl_5h_pct" ] && pct5=$(printf "%.0f" "$rl_5h_pct")
    [ -n "$rl_7d_pct" ] && pct7=$(printf "%.0f" "$rl_7d_pct")
  fi
  # Fall back to global cache when no live data yet (subscription users only)
  if [ -z "$pct5" ] && [ -z "$pct7" ]; then
    if [ "$_use_subscription" = "1" ] && { [ -n "$_gc_rl_5h_pct" ] || [ -n "$_gc_rl_7d_pct" ]; }; then
      [ -n "$_gc_rl_5h_pct" ] && pct5=$(printf "%.0f" "$_gc_rl_5h_pct")
      [ -n "$_gc_rl_7d_pct" ] && pct7=$(printf "%.0f" "$_gc_rl_7d_pct")
      rl_5h_resets="${_gc_rl_5h_resets:-}"
      rl_7d_resets="${_gc_rl_7d_resets:-}"
      _stale=1
    else
      # Non-subscription (or no cached quota data): show cost instead of quota bar
      local _cost_val=""
      if [ "${total_cost:-0}" != "0" ] 2>/dev/null; then
        _cost_val="$(printf "%.2f" "$total_cost")\$"
      elif [ -n "$_gc_cost" ] && [ "$_gc_cost" != "0" ]; then
        _cost_val="${_gc_cost}\$"
      fi
      if [ -n "$_cost_val" ]; then
        printf '%b' "${DIM}qta${RESET} $(_quota_bar 0 10) ${GREEN}${_cost_val}${RESET}"
      else
        printf '%b' "${DIM}qta${RESET} $(_quota_bar 0 10) ${DIM}-${RESET}"
      fi
      return
    fi
  fi

  local c; c=$(pct_color "${pct5:-0}")
  [ "$_stale" = "1" ] && c="$DIM"
  local reset_part=""
  # When 7d quota is exhausted, show 7d reset time instead of 5h
  if [ "${pct7:-0}" -ge 100 ] && [ -n "$rl_7d_resets" ]; then
    reset_part=" ${DIM}$(fmt_reset $(( rl_7d_resets - EPOCHSECONDS )))${RESET}"
  elif [ -n "$rl_5h_resets" ]; then
    reset_part=" ${DIM}$(fmt_reset $(( rl_5h_resets - EPOCHSECONDS )))${RESET}"
  fi
  local pct7_display=""
  if [ -n "$pct7" ]; then
    local c7; c7=$(pct_color "$pct7")
    [ "$_stale" = "1" ] && c7="$DIM"
    pct7_display="${DIM}/${RESET}${c7}${pct7}%${RESET}"
  fi
  # Mark global cache for update when we have live (non-stale) data
  if [ "$_stale" = "0" ]; then
    _gc_new_rl_5h_pct="${rl_5h_pct:-}"
    _gc_new_rl_7d_pct="${rl_7d_pct:-}"
    _gc_new_rl_5h_resets="${rl_5h_resets:-}"
    _gc_new_rl_7d_resets="${rl_7d_resets:-}"
    _gc_needs_write=1
  fi
  printf '%b' "${DIM}qta${RESET} $(_quota_bar "${pct5:-0}" 10 "$c") ${c}${pct5}%${RESET}${pct7_display}${reset_part}"
}

section_rules() {
  local n; n=$(find "$HOME/.claude/rules" -maxdepth 1 -name '*.md' -type f 2>/dev/null | wc -l)
  [ "$n" -gt 0 ] && _sec "rules" "$n" "$CYAN"
}

section_skills() {
  local n; n=$(find "$HOME/.claude/skills" -maxdepth 1 -mindepth 1 \( -type d -o -type l \) 2>/dev/null | wc -l)
  [ "$n" -gt 0 ] && _sec "skills" "$n" "$CYAN"
}

# Merge a JSON field from global + project settings.json (project overrides global).
# Approximation: real Claude Code config resolution has more layers than this.
_merged_settings_field() {
  local field="$1" proj="$_proj"
  local g p
  g=$(jq -c --arg f "$field" '.[$f] // {}' "$HOME/.claude/settings.json" 2>/dev/null)
  [ -z "$g" ] && g='{}'
  p='{}'
  [ -f "$proj/.claude/settings.json" ] && p=$(jq -c --arg f "$field" '.[$f] // {}' "$proj/.claude/settings.json" 2>/dev/null)
  [ -z "$p" ] && p='{}'
  jq -n --argjson g "$g" --argjson p "$p" '$g * $p'
}

_active_plugin_names() {
  local merged; merged=$(_merged_settings_field "enabledPlugins")
  jq -r '[to_entries[] | select(.value == true) | .key] | .[]' <<< "$merged" 2>/dev/null
}

section_mcp() {
  local names=""

  # Native servers: settings.json (global+project) and the legacy ~/.claude.json mcpServers
  local merged; merged=$(_merged_settings_field "mcpServers")
  names="$names $(jq -r 'keys[]' <<< "$merged" 2>/dev/null)"
  if [ -f "$HOME/.claude.json" ]; then
    names="$names $(jq -r --arg p "$_proj" '
      ((.mcpServers // {}) + (.projects[$p].mcpServers // {})) | keys[]
    ' "$HOME/.claude.json" 2>/dev/null)"
  fi

  # Servers contributed by plugins enabled via enabledPlugins=true (their own .mcp.json)
  local plugins_cfg="$HOME/.claude/plugins/installed_plugins.json"
  if [ -f "$plugins_cfg" ]; then
    local plugin_name install_path
    while IFS= read -r plugin_name; do
      [ -z "$plugin_name" ] && continue
      install_path=$(jq -r --arg n "$plugin_name" '.plugins[$n][0].installPath // ""' "$plugins_cfg" 2>/dev/null)
      [ -n "$install_path" ] && [ -f "$install_path/.mcp.json" ] || continue
      names="$names $(jq -r 'if has("mcpServers") then .mcpServers else . end | keys[]' "$install_path/.mcp.json" 2>/dev/null)"
    done < <(_active_plugin_names)
  fi

  local n; n=$(printf '%s\n' $names | sort -u | grep -c .)
  [ "${n:-0}" -gt 0 ] && _sec "mcp" "$n" "$CYAN"
}

section_plugins() {
  local n; n=$(_active_plugin_names | grep -c .)
  [ "${n:-0}" -gt 0 ] && _sec "plugins" "$n" "$CYAN"
}

# ============================================================
# Render — two lines, all left-aligned
# ============================================================
SEP="  "

line1_sections=(
  section_model
  section_context
  section_quota
  section_speed
)

line2_sections=(
  section_project
  section_rules
  section_skills
  section_mcp
  section_plugins
  section_mem
)

_render_line() {
  local -n _items="$1"
  local out="" item part
  for item in "${_items[@]}"; do
    part=$($item)
    [ -n "$part" ] && out="${out:+${out}${SEP}}${part}"
  done
  printf '%s' "$out"
}

line1=$(_render_line line1_sections)
line2=$(_render_line line2_sections)

printf '%b\n%b\n' "$line1" "$line2"

# Persist global cache if any new data was collected this render
if [ "$_gc_needs_write" = "1" ]; then
  jq -n \
    --arg rl_5h_pct    "${_gc_new_rl_5h_pct:-$_gc_rl_5h_pct}" \
    --arg rl_7d_pct    "${_gc_new_rl_7d_pct:-$_gc_rl_7d_pct}" \
    --arg rl_5h_resets "${_gc_new_rl_5h_resets:-$_gc_rl_5h_resets}" \
    --arg rl_7d_resets "${_gc_new_rl_7d_resets:-$_gc_rl_7d_resets}" \
    --arg cost         "${_gc_new_cost:-$_gc_cost}" \
    --arg speed        "${_gc_new_speed:-$_gc_speed}" \
    '{
      rl_5h_pct:    (if $rl_5h_pct    != "" then ($rl_5h_pct    | tonumber) else null end),
      rl_7d_pct:    (if $rl_7d_pct    != "" then ($rl_7d_pct    | tonumber) else null end),
      rl_5h_resets: (if $rl_5h_resets != "" then ($rl_5h_resets | tonumber) else null end),
      rl_7d_resets: (if $rl_7d_resets != "" then ($rl_7d_resets | tonumber) else null end),
      cost:  (if $cost  != "" then $cost  else null end),
      speed: (if $speed != "" then $speed else null end)
    }' > "$_global_cache" 2>/dev/null || true
fi

# Clean up session cache dirs older than 24h — probabilistic to avoid fork on every render
(( RANDOM % 60 == 0 )) && find "$_quota_cache_dir" -maxdepth 1 -mindepth 1 -type d -mmin +1440 -exec rm -rf {} + 2>/dev/null || true

exit 0
