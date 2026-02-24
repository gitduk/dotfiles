#!/usr/bin/env bash
# Claude Code status line script
# Each section is a function — reorder the sections array to change layout.

input=$(cat)

# ============================================================
# Data extraction (parsed once, used by section functions)
# ============================================================
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
api_duration_ms=$(echo "$input" | jq -r '.cost.total_api_duration_ms // 0')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

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

# Color by percentage: green < 60, yellow 60-79, red >= 80
pct_color() {
  local pct="${1:-0}"
  if [ "$pct" -ge 80 ]; then printf '\033[31m'
  elif [ "$pct" -ge 60 ]; then printf '\033[33m'
  else printf '\033[32m'
  fi
}

# Format token counts: 1234 -> 1.2k, 1234567 -> 1.2M
fmt_tokens() {
  local n="${1:-0}"
  if [ "$n" -ge 1000000 ]; then
    printf "%.1fM" "$(echo "scale=1; $n / 1000000" | bc)"
  elif [ "$n" -ge 1000 ]; then
    printf "%.1fk" "$(echo "scale=1; $n / 1000" | bc)"
  else
    echo "$n"
  fi
}

# Format milliseconds to human-readable: 1h 2m, 3m 45s, 12s
fmt_duration() {
  local ms="${1:-0}"
  local secs=$((ms / 1000))
  if [ "$secs" -ge 3600 ]; then
    printf "%dh %dm" $((secs / 3600)) $(((secs % 3600) / 60))
  elif [ "$secs" -ge 60 ]; then
    printf "%dm %ds" $((secs / 60)) $((secs % 60))
  else
    printf "%ds" "$secs"
  fi
}

# ============================================================
# Quota API (cached, non-blocking)
# ============================================================
CACHE_FILE="$HOME/.cache/claude/quota-cache.json"
CACHE_TTL=60

fetch_quota() {
  local token
  token=$(jq -r '.claudeAiOauth.accessToken // empty' "$HOME/.claude/.credentials.json" 2>/dev/null)
  [ -z "$token" ] && return 1
  local resp
  resp=$(curl -s --max-time 5 \
    -H "Authorization: Bearer $token" \
    -H "anthropic-beta: oauth-2025-04-20" \
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)
  [ -z "$resp" ] && return 1
  echo "$resp" | jq -e '.five_hour or .seven_day' >/dev/null 2>&1 || return 1
  jq -n --argjson data "$resp" --arg ts "$(date +%s)" \
    '{data: $data, cached_at: ($ts | tonumber)}' > "$CACHE_FILE" 2>/dev/null
}

get_quota() {
  mkdir -p "$(dirname "$CACHE_FILE")"
  if [ -f "$CACHE_FILE" ]; then
    local cached_at now age
    cached_at=$(jq -r '.cached_at // 0' "$CACHE_FILE" 2>/dev/null)
    now=$(date +%s)
    age=$((now - cached_at))
    if [ "$age" -lt "$CACHE_TTL" ]; then
      jq -r '.data' "$CACHE_FILE" 2>/dev/null
      return
    fi
  fi
  fetch_quota &
  if [ -f "$CACHE_FILE" ]; then
    jq -r '.data' "$CACHE_FILE" 2>/dev/null
  fi
}

quota_json=$(get_quota)
five_h=""
seven_d=""
if [ -n "$quota_json" ] && [ "$quota_json" != "null" ]; then
  five_h=$(echo "$quota_json" | jq -r '.five_hour.utilization // empty' 2>/dev/null)
  seven_d=$(echo "$quota_json" | jq -r '.seven_day.utilization // empty' 2>/dev/null)
fi

# ============================================================
# Transcript parsing (for tools, todos)
# ============================================================
tool_summary=""
todo_summary=""

if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  # Parse tools: count running and recently completed
  tool_summary=$(jq -r '
    [.. | objects | select(.type == "tool_use")] as $uses |
    [.. | objects | select(.type == "tool_result")] as $results |
    ($results | map(.tool_use_id) | unique) as $done_ids |
    ($uses | map(select(.id as $id | ($done_ids | index($id)) == null)) | length) as $running |
    ($results | length) as $completed |
    if ($running > 0) then "\($running) running"
    elif ($completed > 0) then "\($completed) done"
    else empty
    end
  ' "$transcript_path" 2>/dev/null)

  # Parse todos: completion progress
  todo_summary=$(jq -r '
    [.. | objects | select(.type == "tool_use" and .name == "TaskCreate")] as $creates |
    [.. | objects | select(.type == "tool_use" and .name == "TaskUpdate" and .input.status == "completed")] as $completes |
    if ($creates | length) > 0 then
      "\($completes | length)/\($creates | length)"
    else empty
    end
  ' "$transcript_path" 2>/dev/null)
fi

# ============================================================
# Section functions — each prints one segment (or empty)
# ============================================================

# Model name (cyan)
section_model() {
  printf '%b' "${CYAN}${model}${RESET}"
}

# Project directory name
section_project() {
  local dir="${project_dir:-$cwd}"
  [ -z "$dir" ] && return
  printf '%b' "${WHITE}${dir##*/}${RESET}"
}

# Git: branch + dirty indicator
section_git() {
  local dir="${project_dir:-$cwd}"
  [ -z "$dir" ] && return
  [ -d "$dir/.git" ] || return
  local branch dirty=""
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
  [ -z "$branch" ] && return
  git -C "$dir" diff --quiet 2>/dev/null || dirty="${YELLOW}*${RESET}"
  local ahead behind ab_info=""
  ahead=$(git -C "$dir" rev-list --count @{upstream}..HEAD 2>/dev/null)
  behind=$(git -C "$dir" rev-list --count HEAD..@{upstream} 2>/dev/null)
  [ "${ahead:-0}" -gt 0 ] && ab_info="${GREEN}↑${ahead}${RESET}"
  [ "${behind:-0}" -gt 0 ] && ab_info="${ab_info}${RED}↓${behind}${RESET}"
  printf '%b' "${CYAN}${branch}${RESET}${dirty}${ab_info}"
}

# Context: percentage, colored by usage
section_context() {
  if [ -n "$used_pct" ]; then
    local pct_int ccolor
    pct_int=$(printf "%.0f" "$used_pct")
    ccolor=$(pct_color "$pct_int")
    printf '%b' "${DIM}ctx:${RESET}${ccolor}${pct_int}%${RESET}"
  else
    printf '%b' "${DIM}no ctx${RESET}"
  fi
}

# Session cost
section_cost() {
  local cost_fmt
  cost_fmt=$(printf "\$%.4f" "$total_cost")
  printf '%b' "${MAGENTA}${cost_fmt}${RESET}"
}

# Input token count
section_tokens_in() {
  local in_fmt
  in_fmt=$(fmt_tokens "$total_in")
  printf '%b' "${DIM}in:${RESET}${WHITE}${in_fmt}${RESET}"
}

# Output token count
section_tokens_out() {
  local out_fmt
  out_fmt=$(fmt_tokens "$total_out")
  printf '%b' "${DIM}out:${RESET}${WHITE}${out_fmt}${RESET}"
}

# Output speed (tokens/sec based on API duration)
section_speed() {
  [ "$api_duration_ms" -le 0 ] 2>/dev/null && return
  [ "$total_out" -le 0 ] 2>/dev/null && return
  local tps
  tps=$(echo "scale=1; $total_out * 1000 / $api_duration_ms" | bc 2>/dev/null)
  [ -z "$tps" ] && return
  printf '%b' "${DIM}speed:${RESET}${WHITE}${tps}t/s${RESET}"
}

# Session duration
section_duration() {
  [ "$duration_ms" -le 0 ] 2>/dev/null && return
  local dur
  dur=$(fmt_duration "$duration_ms")
  printf '%b' "${DIM}time:${RESET}${WHITE}${dur}${RESET}"
}

# 5-hour quota usage
section_quota_5h() {
  if [ -n "$five_h" ]; then
    local five_int five_color
    five_int=$(printf "%.0f" "$five_h")
    five_color=$(pct_color "$five_int")
    printf '%b' "${DIM}5h:${RESET}${five_color}${five_int}%${RESET}"
  fi
}

# Time remaining until 5-hour quota reset
section_reset_5h() {
  [ -z "$quota_json" ] || [ "$quota_json" = "null" ] && return
  local resets_at
  resets_at=$(echo "$quota_json" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
  [ -z "$resets_at" ] && return
  local reset_epoch now_epoch secs_left
  reset_epoch=$(date -d "$resets_at" +%s 2>/dev/null) || return
  now_epoch=$(date +%s)
  secs_left=$((reset_epoch - now_epoch))
  [ "$secs_left" -le 0 ] && printf '%b' "${DIM}5h reset:${RESET}${GREEN}now${RESET}" && return
  local mins=$((secs_left / 60))
  local hrs=$((mins / 60))
  local rem_mins=$((mins % 60))
  local label
  if [ "$hrs" -gt 0 ]; then
    label="${hrs}h ${rem_mins}m"
  else
    label="${mins}m"
  fi
  local color
  if [ "$secs_left" -le 600 ]; then color="$RED"
  elif [ "$secs_left" -le 1800 ]; then color="$YELLOW"
  else color="$GREEN"
  fi
  printf '%b' "${DIM}reset in:${RESET}${color}${label}${RESET}"
}

# 7-day quota usage
section_quota_7d() {
  if [ -n "$seven_d" ]; then
    local seven_int seven_color
    seven_int=$(printf "%.0f" "$seven_d")
    seven_color=$(pct_color "$seven_int")
    printf '%b' "${DIM}7d:${RESET}${seven_color}${seven_int}%${RESET}"
  fi
}

# Tool activity summary
section_tools() {
  [ -z "$tool_summary" ] && return
  printf '%b' "${DIM}tools:${RESET}${WHITE}${tool_summary}${RESET}"
}

# Todo progress
section_todos() {
  [ -z "$todo_summary" ] && return
  printf '%b' "${DIM}todo:${RESET}${GREEN}${todo_summary}${RESET}"
}

# Config counts: CLAUDE.md, rules, mcps, hooks (cached per session)
CONFIG_CACHE="$HOME/.cache/claude/config-cache.json"
CONFIG_CACHE_TTL=60  # 1 minutes

compute_config() {
  local dir="${1:-.}"
  local md_count=0 rules_count=0 mcp_count=0 hook_count=0

  # CLAUDE.md files: user-level
  [ -f "$HOME/.claude/CLAUDE.md" ] && md_count=$((md_count + 1))
  if [ "$dir" != "$HOME" ]; then
    [ -f "$dir/CLAUDE.md" ] && md_count=$((md_count + 1))
    [ -f "$dir/.claude/CLAUDE.md" ] && md_count=$((md_count + 1))
  fi

  # Rules files
  [ -d "$HOME/.claude/rules" ] && rules_count=$(find "$HOME/.claude/rules" -type f 2>/dev/null | wc -l | tr -d ' ')
  if [ "$dir" != "$HOME" ] && [ -d "$dir/.claude/rules" ]; then
    rules_count=$((rules_count + $(find "$dir/.claude/rules" -type f 2>/dev/null | wc -l | tr -d ' ')))
  fi

  # MCP servers
  mcp_count=$(jq -r '.mcpServers // {} | length' "$HOME/.claude/settings.json" 2>/dev/null)
  if [ "$dir" != "$HOME" ] && [ -f "$dir/.claude/settings.json" ]; then
    mcp_count=$((mcp_count + $(jq -r '.mcpServers // {} | length' "$dir/.claude/settings.json" 2>/dev/null)))
  fi

  # Hooks
  count_hooks_in_file() {
    jq -r '[.hooks // {} | to_entries[].value[] | .hooks | length] | add // 0' "$1" 2>/dev/null
  }
  hook_count=$(count_hooks_in_file "$HOME/.claude/settings.json")
  if [ "$dir" != "$HOME" ]; then
    [ -f "$dir/.claude/settings.json" ] && hook_count=$((hook_count + $(count_hooks_in_file "$dir/.claude/settings.json")))
    [ -f "$dir/.claude/settings.local.json" ] && hook_count=$((hook_count + $(count_hooks_in_file "$dir/.claude/settings.local.json")))
  fi
  local plugins_file="$HOME/.claude/plugins/installed_plugins.json"
  if [ -f "$plugins_file" ]; then
    while IFS= read -r ppath; do
      [ -z "$ppath" ] && continue
      [ -f "$ppath/hooks/hooks.json" ] && hook_count=$((hook_count + $(count_hooks_in_file "$ppath/hooks/hooks.json")))
    done <<< "$(jq -r '.plugins // {} | to_entries[].value[0].installPath // empty' "$plugins_file" 2>/dev/null)"
  fi

  jq -n --arg dir "$dir" --argjson md "$md_count" --argjson rules "$rules_count" \
    --argjson mcp "${mcp_count:-0}" --argjson hooks "${hook_count:-0}" --arg ts "$(date +%s)" \
    '{dir: $dir, md: $md, rules: $rules, mcp: $mcp, hooks: $hooks, cached_at: ($ts | tonumber)}' \
    > "$CONFIG_CACHE" 2>/dev/null
}

# Load config counts once at top level
_cfg_md=0 _cfg_rules=0 _cfg_mcp=0 _cfg_hooks=0
_cfg_dir="${project_dir:-$cwd}"
if [ -n "$_cfg_dir" ]; then
  _need_compute=1
  if [ -f "$CONFIG_CACHE" ]; then
    _cached_dir=$(jq -r '.dir // ""' "$CONFIG_CACHE" 2>/dev/null)
    _cached_at=$(jq -r '.cached_at // 0' "$CONFIG_CACHE" 2>/dev/null)
    _now=$(date +%s)
    _age=$((_now - _cached_at))
    if [ "$_cached_dir" = "$_cfg_dir" ] && [ "$_age" -lt "$CONFIG_CACHE_TTL" ]; then
      _need_compute=0
    fi
  fi
  [ "$_need_compute" -eq 1 ] && compute_config "$_cfg_dir"
  if [ -f "$CONFIG_CACHE" ]; then
    _cfg_md=$(jq -r '.md' "$CONFIG_CACHE")
    _cfg_rules=$(jq -r '.rules' "$CONFIG_CACHE")
    _cfg_mcp=$(jq -r '.mcp' "$CONFIG_CACHE")
    _cfg_hooks=$(jq -r '.hooks' "$CONFIG_CACHE")
  fi
fi

section_cfg_md() {
  [ "${_cfg_md:-0}" -gt 0 ] && printf '%b' "${DIM}md:${RESET}${WHITE}${_cfg_md}${RESET}"
}

section_cfg_rules() {
  [ "${_cfg_rules:-0}" -gt 0 ] && printf '%b' "${DIM}rules:${RESET}${WHITE}${_cfg_rules}${RESET}"
}

section_cfg_mcp() {
  [ "${_cfg_mcp:-0}" -gt 0 ] && printf '%b' "${DIM}mcp:${RESET}${WHITE}${_cfg_mcp}${RESET}"
}

section_cfg_hooks() {
  [ "${_cfg_hooks:-0}" -gt 0 ] && printf '%b' "${DIM}hooks:${RESET}${WHITE}${_cfg_hooks}${RESET}"
}

# ============================================================
# Render — use "---" to start a new line
# ============================================================

# separator between sections — change to "  ", " │ ", " · ", etc.
SEP="  "

sections=(
  section_model
  section_context
  section_quota_5h
  section_reset_5h
  section_quota_7d
  section_cost
  ---
  section_git
  section_cfg_md
  section_cfg_rules
  section_cfg_mcp
  section_cfg_hooks
  section_duration
  ---
  section_todos
)

line=""
for item in "${sections[@]}"; do
  if [ "$item" = "---" ]; then
    [ -n "$line" ] && printf '%b\n' "$line"
    line=""
  else
    part=$($item)
    [ -n "$part" ] && line="${line:+${line}${SEP}}${part}"
  fi
done
[ -n "$line" ] && printf '%b\n' "$line"
exit 0
