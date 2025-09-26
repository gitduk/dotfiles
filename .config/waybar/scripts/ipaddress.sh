#!/usr/bin/env bash

SCRIPT_NAME=$(basename "$0")
VERSION="1.0.0"

##############
### config ###
##############

# 配置
declare -A CONFIG=(
  [cache_dir]="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
  [token_file]="${XDG_CACHE_HOME:-$HOME/.cache}/waybar/ip.token"
  [cache_file]="${XDG_CACHE_HOME:-$HOME/.cache}/waybar/ipaddress.json"
  [token_api]="https://v2.jinrishici.com/token"
  [ip_api]="https://v2.jinrishici.com/info"
)

# 创建缓存目录
mkdir -p "${CONFIG[cache_dir]}"

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Options:
  --click       Show loading state and update in background
  -h, --help    Show this help
  -v, --version Show version
  (no args)     Update IP info immediately

Waybar config example:
"custom/ipaddress": {
    "exec": "cat ~/.cache/waybar/ipaddress.json || echo '{\"text\": \"127.0.0.1\"}'",
    "format": " {} ",
    "return-type": "json",
    "interval": 1,
    "tooltip": true,
    "on-click": "$SCRIPT_NAME --click"
}
EOF
}

############
### main ###
############

error() { echo -e "\e[31mERROR:\e[0m $*" >&2; }
warn()  { echo -e "\e[33mWARN:\e[0m  $*" >&2; }
info()  { echo -e "\e[34mINFO:\e[0m  $*"; }

show_loading() {
  local current_ip="127.0.0.1"
  if [[ -f "${CONFIG[cache_file]}" ]]; then
    current_ip=$(jq -r '.text // "127.0.0.1"' "${CONFIG[cache_file]}" 2>/dev/null)
  fi

  jq -n -c \
    --arg text "${current_ip}..." \
    --arg tooltip "正在刷新 IP 地址信息..." \
    --arg class "loading" \
    '{text: $text, tooltip: $tooltip, class: $class}' >"${CONFIG[cache_file]}"
}

get_token() {
  if [[ -f "${CONFIG[token_file]}" ]]; then
    cat "${CONFIG[token_file]}"
  else
    info "正在获取 Token..."
    local token
    token=$(curl -s "${CONFIG[token_api]}" | jq -r '.data')
    if [[ -n "$token" && "$token" != "null" ]]; then
      echo "$token" >"${CONFIG[token_file]}"
      echo "$token"
    else
      error "获取 Token 失败"
      return 1
    fi
  fi
}

get_ipaddress() {
  local token="$1"
  curl -s -H "X-User-Token: $token" "${CONFIG[ip_api]}"
}

format_output() {
  local json_data="$1"

  local class ip region weather temperature time tooltip
  class=$(jq -r '.status' <<< "$json_data")
  ip=$(jq -r '.data.ip // "127.0.0.1"' <<< "$json_data")
  region=$(jq -r '.data.region // ""' <<< "$json_data")
  weather=$(jq -r '.data.weatherData.weather // ""' <<< "$json_data")
  temperature=$(jq -r '.data.weatherData.temperature // ""' <<< "$json_data")
  time=$(jq -r '.data.beijingTime // ""' <<< "$json_data")

  if [[ -z "$time" ]]; then
    time=$(date "+%H:%M:%S")
  else
    time="${time#*T}"
    time="${time%.*}"
    region="${region/|/-}"
  fi

  if [[ "$class" == "error" ]]; then
    tooltip="请求失败 | $time"
  else
    tooltip="$region | $weather ${temperature}°C | $time"
  fi

  jq -n -c \
    --arg text "$ip" \
    --arg tooltip "$tooltip" \
    --arg class "$class" \
    '{text: $text, tooltip: $tooltip, class: $class}'
}

update_ip() {
  # 检查依赖
  command -v jq    >/dev/null || { echo '{"text":"jq not found","class":"error"}' > "${CONFIG[cache_file]}"; return 1; }
  command -v curl  >/dev/null || { echo '{"text":"curl not found","class":"error"}' > "${CONFIG[cache_file]}"; return 1; }

  local token
  token=$(get_token) || { echo '{"text":"get token failed","class":"error"}' > "${CONFIG[cache_file]}"; return 1; }

  local ip_data
  ip_data=$(get_ipaddress "$token")
  [[ -z "$ip_data" ]] && ip_data='{"status":"error"}'

  format_output "$ip_data" >"${CONFIG[cache_file]}"
}

handle_click() {
  show_loading
  {
    sleep 0.1
    update_ip
  } &
}

main() {
  [[ $# -eq 0 ]] && { update_ip; exit 0; }

  while [[ $# -gt 0 ]]; do
    case $1 in
      --click)   handle_click; shift ;;
      -h|--help) usage; exit 0 ;;
      -v|--version) echo "$VERSION"; exit 0 ;;
      *) error "未知参数: $1"; usage; exit 1 ;;
    esac
  done
}

main "$@"
