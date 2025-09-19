#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=$(basename "$0")
VERSION="1.1.0"

##############
### config ###
##############

declare -A CONFIG=(
  [cache_dir]="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
  [token_file]="${XDG_CACHE_HOME:-$HOME/.cache}/waybar/poetry.token"
  [cache_file]="${XDG_CACHE_HOME:-$HOME/.cache}/waybar/poetry.json"
  [curl_timeout]=8
  [token_expire_hours]=24
  [max_content_length]=50
)

mkdir -p "${CONFIG[cache_dir]}"

show_help() {
  cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Options:
  --click      Handle click (show loading and update)
  --force      Force update poetry
  --status     Show cache/token status
  --clean      Clean cache files
  -h, --help   Show this help
  -v, --version Show version
  (no args)    Update poetry (default)
EOF
}

############
### main ###
############

error() { echo -e "\e[31mERROR:\e[0m $*" >&2; }
warn()  { echo -e "\e[33mWARN:\e[0m  $*" >&2; }
info()  { echo -e "\e[34mINFO:\e[0m  $*"; }

show_status() {
  echo "=== 诗词模块状态 ==="
  echo "缓存目录: ${CONFIG[cache_dir]}"
  echo "Token文件: ${CONFIG[token_file]}"
  echo "缓存文件: ${CONFIG[cache_file]}"
  [[ -f "${CONFIG[token_file]}" ]] && echo "Token 存在" || echo "Token 不存在"
  [[ -f "${CONFIG[cache_file]}" ]] && echo "缓存 存在" || echo "缓存 不存在"
}

truncate_text() {
  local text="$1" max_len="$2"
  [[ ${#text} -gt $max_len ]] && echo "${text:0:$max_len}…" || echo "$text"
}

is_token_expired() {
  [[ ! -f "${CONFIG[token_file]}" ]] && return 0
  local token_mtime file_age_hours
  token_mtime=$(stat -c %Y "${CONFIG[token_file]}" 2>/dev/null || echo 0)
  file_age_hours=$((($(date +%s) - token_mtime) / 3600))
  [[ $file_age_hours -gt ${CONFIG[token_expire_hours]} ]]
}

get_token() {
  if ! is_token_expired; then
    cat "${CONFIG[token_file]}" 2>/dev/null && return 0
  fi

  info "Fetching new token..."
  local response token
  response=$(curl -sSL --connect-timeout "${CONFIG[curl_timeout]}" --max-time "${CONFIG[curl_timeout]}" \
    "https://v2.jinrishici.com/token") || { error "Token request failed"; return 1; }

  token=$(jq -r '.data // empty' <<<"$response")
  if [[ -n "$token" && "$token" != "null" ]]; then
    echo "$token" >"${CONFIG[token_file]}"
    info "Token saved"
    echo "$token"
  else
    error "Token parse failed: $response"
    return 1
  fi
}

get_poetry() {
  local token="$1"
  curl -sSL --connect-timeout "${CONFIG[curl_timeout]}" --max-time "${CONFIG[curl_timeout]}" \
    -H "X-User-Token: $token" \
    -H "User-Agent: Waybar-Poetry/1.0" \
    "https://v2.jinrishici.com/sentence"
}

format_output() {
  local json_data="$1"

  local status content author title dynasty full warning
  status=$(jq -r '.status // "unknown"' <<<"$json_data")
  content=$(jq -r '.data.content // "暂无诗词"' <<<"$json_data")
  author=$(jq -r '.data.origin.author // ""' <<<"$json_data")
  title=$(jq -r '.data.origin.title // ""' <<<"$json_data")
  dynasty=$(jq -r '.data.origin.dynasty // ""' <<<"$json_data")
  warning=$(jq -r '.warning // ""' <<<"$json_data")
  full=$(jq -r '.data.origin.content // [] | if type=="array" then join("\n") else . end' <<<"$json_data")

  local display_text tooltip
  display_text=$(truncate_text "$content" "${CONFIG[max_content_length]}")

  if [[ "$status" == "success" ]]; then
    [[ -n "$title" && -n "$author" ]] && tooltip="📖 ${dynasty:+$dynasty·}$author·$title"
    [[ -n "$full" ]] && tooltip="$tooltip"$'\n\n'"$full"
    [[ "$content" != "$display_text" ]] && tooltip="$tooltip"$'\n\n'"$content"
    [[ -n "$warning" ]] && tooltip="$tooltip"$'\n\n'"⚠️ $warning"
    tooltip="$tooltip"$'\n\n'"🕐 更新于 $(date '+%H:%M:%S')"
  else
    tooltip="❌ 获取诗词失败 | 🕐 $(date '+%H:%M:%S')"
    display_text="❌ 获取失败"
    status="error"
  fi

  jq -n -c --arg text "$display_text" --arg tooltip "$tooltip" --arg class "$status" \
    '{text:$text, tooltip:$tooltip, class:$class}'
}

update_poetry() {
  command -v jq >/dev/null || { echo '{"text":"jq not found","class":"error"}' >"${CONFIG[cache_file]}"; return 1; }
  command -v curl >/dev/null || { echo '{"text":"curl not found","class":"error"}' >"${CONFIG[cache_file]}"; return 1; }

  local token poetry_data
  if ! token=$(get_token); then
    warn "Token 获取失败，使用离线模式"
    create_fallback_poetry >"${CONFIG[cache_file]}"
    return 0
  fi

  poetry_data=$(get_poetry "$token")
  if [[ -z "$poetry_data" ]] || ! jq . <<<"$poetry_data" &>/dev/null; then
    error "数据错误，使用离线模式"
    create_fallback_poetry >"${CONFIG[cache_file]}"
    return 0
  fi

  format_output "$poetry_data" >"${CONFIG[cache_file]}"
}

create_fallback_poetry() {
  local poems=(
    "山重水复疑无路，柳暗花明又一村。|宋·陆游《游山西村》"
    "会当凌绝顶，一览众山小。|唐·杜甫《望岳》"
    "采菊东篱下，悠然见南山。|晋·陶渊明《饮酒》"
  )
  local index=$(( $(date +%s) / 86400 % ${#poems[@]} ))
  local content="${poems[$index]}"
  local tooltip="$content"$'\n\n'"🕐 离线模式 $(date '+%H:%M:%S')"
  jq -n -c --arg text "$content" --arg tooltip "$tooltip" --arg class "offline" \
    '{text:$text, tooltip:$tooltip, class:$class}'
}

handle_click() {
  jq -n -c --arg text "📜 ..." --arg tooltip "正在刷新诗词..." --arg class "loading" \
    '{text:$text, tooltip:$tooltip, class:$class}' >"${CONFIG[cache_file]}"
  { sleep 0.1; update_poetry; } &
}

clean_cache() {
  rm -f "${CONFIG[token_file]}" "${CONFIG[cache_file]}"
  echo "缓存已清理"
}

main() {
  [[ $# -eq 0 ]] && { update_poetry; exit 0; }

  while [[ $# -gt 0 ]]; do
    case $1 in
      --click) handle_click ;;
      --force) update_poetry ;;
      --status) show_status ;;
      --clean) clean_cache ;;
      -h|--help) show_help; exit 0 ;;
      -v|--version) echo "$VERSION"; exit 0 ;;
      *) error "未知参数: $1"; show_help; exit 1 ;;
    esac
    shift
  done
}

main "$@"
