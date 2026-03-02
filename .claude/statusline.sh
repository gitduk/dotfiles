#!/usr/bin/env bash
# Claude Code status line script
# Each section is a function — reorder the sections array to change layout.

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
  @sh "total_cost=\(.cost.total_cost_usd // 0)",
  @sh "duration_ms=\(.cost.total_duration_ms // 0)",
  @sh "api_duration_ms=\(.cost.total_api_duration_ms // 0)",
  @sh "cwd=\(.workspace.current_dir // "")",
  @sh "project_dir=\(.workspace.project_dir // "")",
  @sh "transcript_path=\(.transcript_path // "")"
')"

# Plugin count from settings.json
plugins_count=$(jq '[.enabledPlugins // {} | to_entries[] | select(.value == true)] | length' ~/.claude/settings.json 2>/dev/null)

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

# Generic section: _sec "label" "value" [color]  →  label:value (dim label, colored value)
_sec() {
  local label="$1" value="$2" color="${3:-$WHITE}"
  [ -z "$value" ] && return
  printf '%b' "${DIM}${label}:${RESET}${color}${value}${RESET}"
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
CACHE_TTL=15

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
    local pct_int; pct_int=$(printf "%.0f" "$used_pct")
    _sec "ctx" "${pct_int}%" "$(pct_color "$pct_int")"
  else
    printf '%b' "${DIM}no ctx${RESET}"
  fi
}

# Session cost
section_cost() { printf '%b' "${MAGENTA}$(printf "\$%.2f" "$total_cost")${RESET}"; }

# Input / output token counts
section_tokens_in()  { _sec "in" "$(fmt_tokens "$total_in")"; }
section_tokens_out() { _sec "out" "$(fmt_tokens "$total_out")"; }

# Output speed (tokens/sec based on API duration)
section_speed() {
  [ "$api_duration_ms" -le 0 ] 2>/dev/null && return
  [ "$total_out" -le 0 ] 2>/dev/null && return
  local tps; tps=$(echo "scale=1; $total_out * 1000 / $api_duration_ms" | bc 2>/dev/null)
  [ -z "$tps" ] && return
  _sec "speed" "${tps}t/s"
}

# Session duration
section_duration() {
  [ "$duration_ms" -le 0 ] 2>/dev/null && return
  _sec "time" "$(fmt_duration "$duration_ms")"
}

# Quota usage: 5h / 7d (colored by percentage)
_section_quota() {
  local label="$1" value="$2"
  [ -z "$value" ] && return
  local pct; pct=$(printf "%.0f" "$value")
  _sec "$label" "${pct}%" "$(pct_color "$pct")"
}
section_quota_5h() {
  [ -z "$five_h" ] && return
  local pct; pct=$(printf "%.0f" "$five_h")
  local pct_c; pct_c="$(pct_color "$pct")"
  # Try to append reset countdown
  local reset_part=""
  if [ -n "$quota_json" ] && [ "$quota_json" != "null" ]; then
    local resets_at
    resets_at=$(echo "$quota_json" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
    if [ -n "$resets_at" ]; then
      local reset_epoch now_epoch secs_left
      reset_epoch=$(date -d "$resets_at" +%s 2>/dev/null)
      if [ -n "$reset_epoch" ]; then
        now_epoch=$(date +%s)
        secs_left=$((reset_epoch - now_epoch))
        local tlabel tcolor
        if [ "$secs_left" -le 0 ]; then
          tlabel="now"; tcolor="$GREEN"
        else
          local mins=$((secs_left / 60)) hrs=$((secs_left / 3600))
          if [ "$hrs" -gt 0 ]; then tlabel="${hrs}h$((mins % 60))m"; else tlabel="${mins}m"; fi
          if [ "$secs_left" -le 600 ]; then tcolor="$RED"
          elif [ "$secs_left" -le 1800 ]; then tcolor="$YELLOW"
          else tcolor="$GREEN"; fi
        fi
        reset_part="${DIM} - ${RESET}${tcolor}${tlabel}${RESET}"
      fi
    fi
  fi
  printf '%b' "${DIM}5h:${RESET}${pct_c}${pct}%${RESET}${reset_part}"
}
section_quota_7d() { _section_quota "7d" "$seven_d"; }

# Tool activity / todo progress
section_tools() { _sec "tools" "$tool_summary"; }
section_todos() { _sec "todo" "$todo_summary" "$GREEN"; }

# ============================================================
# Config & memory stats — collected in a single pass
# ============================================================

# Check if a rules file with `paths:` frontmatter matches the current project.
# No paths → always loaded (return 0). Has paths → check if any glob matches.
_should_load_rule() {
  local f="$1" dir="$2"
  [ "$(head -1 "$f" 2>/dev/null)" = "---" ] || return 0
  local fm
  fm=$(sed -n '2,/^---$/p' "$f" 2>/dev/null)
  echo "$fm" | grep -q '^paths:' || return 0
  [ -z "$dir" ] && return 1
  # Skip path matching when project dir is $HOME (no real project)
  [ "$dir" = "$HOME" ] && return 1
  local pattern
  while IFS= read -r pattern; do
    pattern="${pattern#"${pattern%%[![:space:]]*}"}"
    pattern="${pattern#- }"
    pattern="${pattern#\"}" ; pattern="${pattern%\"}"
    [ -z "$pattern" ] && continue
    if find "$dir" -not -path "*/.claude/*" -path "$dir/$pattern" -print -quit 2>/dev/null | grep -q .; then
      return 0
    fi
  done < <(echo "$fm" | grep '^ *- ')
  return 1
}

# Count MCP servers in a settings file
_count_mcp() { jq -r '.mcpServers // {} | length' "$1" 2>/dev/null; }

# Count hooks in a settings file
_count_hooks() { jq -r '[.hooks // {} | to_entries[].value[] | .hooks | length] | add // 0' "$1" 2>/dev/null; }

# Accumulate stats from a settings file (MCP + hooks)
_collect_settings() {
  local f="$1"
  [ -f "$f" ] || return
  _cfg_mcp=$((_cfg_mcp + $(_count_mcp "$f")))
  _cfg_hooks=$((_cfg_hooks + $(_count_hooks "$f")))
}

# Accumulate stats from an instruction file (md/rules count + mem chars/lines)
_collect_instruction() {
  local f="$1" type="$2"  # type: "md" or "rule"
  [ -f "$f" ] || return
  local c n
  c=$(wc -c < "$f" 2>/dev/null) || return
  n=$(wc -l < "$f" 2>/dev/null) || return
  [ "$type" = "md" ] && _cfg_md=$((_cfg_md + 1))
  [ "$type" = "rule" ] && _cfg_rules=$((_cfg_rules + 1))
  _mem_chars=$((_mem_chars + c))
  _mem_files=$((_mem_files + 1))
  [ "$n" -gt 200 ] && _mem_oversize=$((_mem_oversize + 1))
}

# Collect loaded rules from a directory
_collect_rules_dir() {
  local dir="$1" project="$2"
  [ -d "$dir" ] || return
  while IFS= read -r rf; do
    _should_load_rule "$rf" "$project" && _collect_instruction "$rf" "rule"
  done < <(find "$dir" -type f 2>/dev/null)
}

# --- Run collection ---
_cfg_md=0 _cfg_rules=0 _cfg_mcp=0 _cfg_hooks=0
_mem_chars=0 _mem_files=0 _mem_oversize=0
_cfg_dir="${project_dir:-$cwd}"

if [ -n "$_cfg_dir" ]; then
  # Global level
  _collect_instruction "$HOME/.claude/CLAUDE.md" "md"
  _collect_rules_dir "$HOME/.claude/rules" "$_cfg_dir"
  _collect_settings "$HOME/.claude/settings.json"
  _collect_settings "$HOME/.claude/settings.local.json"

  # Project level (skip if project IS ~/.claude to avoid double-counting)
  if [ "$_cfg_dir" != "$HOME" ] && [ "$_cfg_dir" != "$HOME/.claude" ]; then
    _collect_instruction "$_cfg_dir/CLAUDE.md" "md"
    _collect_instruction "$_cfg_dir/.claude/CLAUDE.md" "md"
    _collect_rules_dir "$_cfg_dir/.claude/rules" "$_cfg_dir"
    _collect_settings "$_cfg_dir/.claude/settings.json"
    _collect_settings "$_cfg_dir/.claude/settings.local.json"
  fi

  # Plugin hooks
  _plugins_file="$HOME/.claude/plugins/installed_plugins.json"
  if [ -f "$_plugins_file" ]; then
    while IFS= read -r ppath; do
      [ -z "$ppath" ] && continue
      [ -f "$ppath/hooks/hooks.json" ] && _cfg_hooks=$((_cfg_hooks + $(_count_hooks "$ppath/hooks/hooks.json")))
    done <<< "$(jq -r '.plugins // {} | to_entries[].value[0].installPath // empty' "$_plugins_file" 2>/dev/null)"
  fi
fi

_mem_tokens=$((_mem_chars / 4))

# --- Section renderers ---
_sec_nonzero() { [ "${2:-0}" -gt 0 ] && _sec "$1" "$2"; }
section_cfg_md()      { _sec_nonzero "md" "$_cfg_md"; }
section_cfg_rules()   { _sec_nonzero "rules" "$_cfg_rules"; }
section_cfg_mcp()     { _sec_nonzero "mcp" "$_cfg_mcp"; }
section_cfg_hooks()   { _sec_nonzero "hooks" "$_cfg_hooks"; }
section_cfg_plugins() { _sec_nonzero "plugins" "$plugins_count"; }

# Memory budget: tokens consumed by loaded CLAUDE.md + rules files.
# Color by % of context window:  green < 3%,  yellow 3-5%,  red > 5%
# "!" if any single file exceeds 200-line guideline (official per-file recommendation)
section_mem_tokens() {
  [ "$_mem_files" -eq 0 ] && return
  local tok_fmt color warn=""

  if [ "$_mem_tokens" -ge 1000 ]; then
    tok_fmt=$(printf "%.1fk" "$(echo "scale=1; $_mem_tokens / 1000" | bc)")
  else
    tok_fmt="${_mem_tokens}"
  fi

  local ctx="${ctx_size:-200000}"
  [ "$ctx" -le 0 ] 2>/dev/null && ctx=200000
  local pct_x100=$((_mem_tokens * 10000 / ctx))
  if [ "$pct_x100" -gt 500 ]; then
    color="$RED"
  elif [ "$pct_x100" -ge 300 ]; then
    color="$YELLOW"
  else
    color="$GREEN"
  fi

  [ "$_mem_oversize" -gt 0 ] && warn="!"
  _sec "mem" "${tok_fmt}${warn}" "$color"
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
  section_quota_7d
  section_cost
  ---
  section_git
  section_cfg_md
  section_cfg_rules
  section_cfg_mcp
  section_cfg_hooks
  section_cfg_plugins
  section_mem_tokens
  ---
  # section_duration
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
