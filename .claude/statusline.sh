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
# Quota — async curl, stale-while-revalidate (no TTL)
# Each render fires a background curl; the result file in /tmp is read by the
# *next* render.  Using session_id keeps instances isolated and avoids a cold
# blank on the very first render (the file simply won't exist yet).
# ============================================================
_quota_file="/tmp/claude-quota-${session_id:-$$}.json"
_quota_token=$(jq -r '.claudeAiOauth.accessToken // empty' \
  "$HOME/.claude/.credentials.json" 2>/dev/null)

# Fire curl in the background — never blocks the render path.
if [ -n "$_quota_token" ]; then
  (curl -sf --max-time 3 \
    -H "Authorization: Bearer $_quota_token" \
    -H "anthropic-beta: oauth-2025-04-20" \
    "https://api.anthropic.com/api/oauth/usage" \
    > "$_quota_file.tmp" 2>/dev/null \
    && mv -f "$_quota_file.tmp" "$_quota_file" 2>/dev/null \
    || rm -f "$_quota_file.tmp" 2>/dev/null) &
fi

# Read whatever the previous render wrote.
# _quota_ready: 0 = no token (quota N/A), 1 = token exists but file not yet written (show placeholder), 2 = data available
_quota_five_h="" _quota_seven_d="" _quota_json=""
_quota_ready=0
if [ -n "$_quota_token" ]; then
  if [ -f "$_quota_file" ]; then
    _quota_json=$(cat "$_quota_file" 2>/dev/null)
    if [ -n "$_quota_json" ]; then
      _quota_five_h=$(printf '%s' "$_quota_json" | jq -r '.five_hour.utilization  // empty' 2>/dev/null)
      _quota_seven_d=$(printf '%s' "$_quota_json" | jq -r '.seven_day.utilization // empty' 2>/dev/null)
      _quota_ready=2
    fi
  else
    _quota_ready=1  # curl fired but result not yet written — show placeholder
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

# Config stats: rules, mcp, hooks, skills, agents, mem — all computed inline.
# Helper: count rules/hooks/mcp in one settings file.
_count_mcp()   { jq -r '.mcpServers // {} | length' "$1" 2>/dev/null; }
_count_hooks() { jq -r '[.hooks // {} | to_entries[].value[] | .hooks | length] | add // 0' "$1" 2>/dev/null; }

# Helper: check whether a rule file's paths: frontmatter matches the project dir.
_should_load_rule() {
  local f="$1" dir="$2"
  [ "$(head -1 "$f" 2>/dev/null)" = "---" ] || return 0
  local fm; fm=$(sed -n '2,/^---$/p' "$f" 2>/dev/null)
  echo "$fm" | grep -q '^paths:' || return 0
  [ -z "$dir" ] && return 1
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

_cfg_dir="${project_dir:-${cwd:-$HOME}}"
_cfg_md=0 _cfg_rules=0 _cfg_mcp=0 _cfg_hooks=0
_mem_chars=0 _mem_files=0 _mem_oversize=0
_f="" _c="" _n="" _m="" _h="" _rf="" _d=""

# global CLAUDE.md
_f="$HOME/.claude/CLAUDE.md"
if [ -f "$_f" ]; then
  _c=$(wc -c < "$_f" 2>/dev/null); _n=$(wc -l < "$_f" 2>/dev/null)
  _cfg_md=$((_cfg_md+1)); _mem_chars=$((_mem_chars+${_c:-0})); _mem_files=$((_mem_files+1))
  [ "${_n:-0}" -gt 200 ] && _mem_oversize=$((_mem_oversize+1))
fi

# global rules dir
_d="$HOME/.claude/rules"
if [ -d "$_d" ]; then
  while IFS= read -r _rf; do
    _should_load_rule "$_rf" "$_cfg_dir" || continue
    [ -f "$_rf" ] || continue
    _c=$(wc -c < "$_rf" 2>/dev/null); _n=$(wc -l < "$_rf" 2>/dev/null)
    _cfg_rules=$((_cfg_rules+1)); _mem_chars=$((_mem_chars+${_c:-0})); _mem_files=$((_mem_files+1))
    [ "${_n:-0}" -gt 200 ] && _mem_oversize=$((_mem_oversize+1))
  done < <(find "$_d" -type f 2>/dev/null)
fi

# global settings
for _f in "$HOME/.claude/settings.json" "$HOME/.claude/settings.local.json"; do
  [ -f "$_f" ] || continue
  _m=$(_count_mcp   "$_f"); _cfg_mcp=$((_cfg_mcp   + ${_m:-0}))
  _h=$(_count_hooks "$_f"); _cfg_hooks=$((_cfg_hooks + ${_h:-0}))
done

# project-local config
if [ "$_cfg_dir" != "$HOME" ] && [ "$_cfg_dir" != "$HOME/.claude" ]; then
  for _f in "$_cfg_dir/CLAUDE.md" "$_cfg_dir/.claude/CLAUDE.md"; do
    if [ -f "$_f" ]; then
      _c=$(wc -c < "$_f" 2>/dev/null); _n=$(wc -l < "$_f" 2>/dev/null)
      _cfg_md=$((_cfg_md+1)); _mem_chars=$((_mem_chars+${_c:-0})); _mem_files=$((_mem_files+1))
      [ "${_n:-0}" -gt 200 ] && _mem_oversize=$((_mem_oversize+1))
    fi
  done
  _d="$_cfg_dir/.claude/rules"
  if [ -d "$_d" ]; then
    while IFS= read -r _rf; do
      _should_load_rule "$_rf" "$_cfg_dir" || continue
      [ -f "$_rf" ] || continue
      _c=$(wc -c < "$_rf" 2>/dev/null); _n=$(wc -l < "$_rf" 2>/dev/null)
      _cfg_rules=$((_cfg_rules+1)); _mem_chars=$((_mem_chars+${_c:-0})); _mem_files=$((_mem_files+1))
      [ "${_n:-0}" -gt 200 ] && _mem_oversize=$((_mem_oversize+1))
    done < <(find "$_d" -type f 2>/dev/null)
  fi
  for _f in "$_cfg_dir/.claude/settings.json" "$_cfg_dir/.claude/settings.local.json"; do
    [ -f "$_f" ] || continue
    _m=$(_count_mcp   "$_f"); _cfg_mcp=$((_cfg_mcp   + ${_m:-0}))
    _h=$(_count_hooks "$_f"); _cfg_hooks=$((_cfg_hooks + ${_h:-0}))
  done
fi

# plugin hooks
_plugins_file="$HOME/.claude/plugins/installed_plugins.json"
if [ -f "$_plugins_file" ]; then
  while IFS= read -r _ppath; do
    [ -z "$_ppath" ] && continue
    if [ -f "$_ppath/hooks/hooks.json" ]; then
      _h=$(_count_hooks "$_ppath/hooks/hooks.json")
      _cfg_hooks=$((_cfg_hooks + ${_h:-0}))
    fi
  done <<< "$(jq -r '.plugins // {} | to_entries[].value[0].installPath // empty' "$_plugins_file" 2>/dev/null)"
fi

_skills_count=$(find "$HOME/.claude/skills" -mindepth 1 -maxdepth 1 -type d  2>/dev/null | wc -l)
_agents_count=$(find "$HOME/.claude/agents" -mindepth 1 -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l)
_mem_tokens=$((_mem_chars / 4))

plugins_count=$(jq '[.enabledPlugins // {} | to_entries[] | select(.value == true)] | length' \
  "$HOME/.claude/settings.json" 2>/dev/null)

# ============================================================
# Section functions
# ============================================================

section_model()   { printf '%b' "${CYAN}${model}${RESET}"; }

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

section_cost() { printf '%b' "${MAGENTA}$(printf "\$%.2f" "$total_cost")${RESET}"; }

section_tokens_in()  { _sec "in"  "$(fmt_tokens "$total_in")"; }
section_tokens_out() { _sec "out" "$(fmt_tokens "$total_out")"; }

section_speed() {
  [ "$api_duration_ms" -le 0 ] 2>/dev/null && return
  [ "$total_out" -le 0 ] 2>/dev/null && return
  local tps; tps=$(awk "BEGIN{printf \"%.1f\", $total_out*1000/$api_duration_ms}" 2>/dev/null)
  [ -z "$tps" ] && return
  _sec "speed" "${tps}t/s"
}

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
  local pct pct_c reset_part=""
  pct=$(printf "%.0f" "$_quota_five_h")
  pct_c=$(pct_color "$pct")
  local resets_at
  resets_at=$(printf '%s' "$_quota_json" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
  if [ -n "$resets_at" ]; then
    local reset_epoch secs_left
    reset_epoch=$(date -d "$resets_at" +%s 2>/dev/null)
    if [ -n "$reset_epoch" ]; then
      secs_left=$(( reset_epoch - $(date +%s) ))
      local tlabel
      if [ "$secs_left" -le 0 ]; then
        tlabel="now"
      else
        local mins=$(( secs_left / 60 )) hrs=$(( secs_left / 3600 ))
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
  local pct; pct=$(printf "%.0f" "$_quota_seven_d")
  _sec "7d" "${pct}%" "$(pct_color "$pct")"
}

section_tools() { _sec "tools" "$tool_summary"; }
section_todos() { _sec "todo"  "$todo_summary" "$GREEN"; }

_sec_nonzero() { [ "${2:-0}" -gt 0 ] && _sec "$1" "$2"; }
section_cfg_md()      { _sec_nonzero "md"      "$_cfg_md"; }
section_cfg_rules()   { _sec_nonzero "rules"   "$_cfg_rules"; }
section_cfg_mcp()     { _sec_nonzero "mcp"     "$_cfg_mcp"; }
section_cfg_hooks()   { _sec_nonzero "hooks"   "$_cfg_hooks"; }
section_cfg_plugins() { _sec_nonzero "plugins" "$plugins_count"; }
section_cfg_skills()  { _sec_nonzero "skills"  "$_skills_count"; }
section_cfg_agents()  { _sec_nonzero "agents"  "$_agents_count"; }

section_mem_tokens() {
  [ "$_mem_files" -eq 0 ] && return
  local tok_fmt color warn=""
  if [ "$_mem_tokens" -ge 1000 ]; then
    tok_fmt=$(awk "BEGIN{printf \"%.1fk\", $_mem_tokens/1000}")
  else
    tok_fmt="${_mem_tokens}"
  fi
  local ctx="${ctx_size:-200000}"
  [ "$ctx" -le 0 ] 2>/dev/null && ctx=200000
  local pct_x100=$((_mem_tokens * 10000 / ctx))
  if   [ "$pct_x100" -gt 500 ]; then color="$RED"
  elif [ "$pct_x100" -ge 300 ]; then color="$YELLOW"
  else color="$GREEN"
  fi
  [ "$_mem_oversize" -gt 0 ] && warn="!"
  _sec "mem" "${tok_fmt}${warn}" "$color"
}

# ============================================================
# Render — use "---" to start a new line
# ============================================================
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
  section_cfg_skills
  section_cfg_agents
  section_mem_tokens
  ---
  section_cfg_hooks
  section_cfg_mcp
  section_cfg_plugins
  section_duration
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
