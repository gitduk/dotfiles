#!/usr/bin/env bash

SCRIPT_NAME=$(basename "$0")
VERSION="1.0.0"

##############
### config ###
##############

# 配置
declare -A CONFIG=(
  [cache_dir]="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
  [cache_file]="${XDG_CACHE_HOME:-$HOME/.cache}/waybar/ipaddress.json"
  [ip_api]="https://ipinfo.io/json"
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

get_ipaddress() {
  curl -s "${CONFIG[ip_api]}"
}

format_output() {
  local json_data="$1"

  local ip city region country org timezone time tooltip class
  ip=$(jq -r '.ip // "127.0.0.1"' <<< "$json_data")
  city=$(jq -r '.city // ""' <<< "$json_data")
  region=$(jq -r '.region // ""' <<< "$json_data")
  country=$(jq -r '.country // ""' <<< "$json_data")
  org=$(jq -r '.org // ""' <<< "$json_data")
  timezone=$(jq -r '.timezone // ""' <<< "$json_data")
  time=$(date "+%H:%M:%S")

  # 检查是否获取到有效IP
  if [[ "$ip" == "127.0.0.1" || -z "$ip" ]]; then
    class="error"
    tooltip="请求失败 | $time"
  else
    class="success"
    # 构建位置信息
    local location=""
    [[ -n "$city" ]] && location="$city"
    [[ -n "$region" ]] && location="${location:+$location, }$region"
    [[ -n "$country" ]] && location="${location:+$location, }$country"
    [[ -z "$location" ]] && location="Unknown"

    tooltip="$location | $org | $time"
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

  local ip_data
  ip_data=$(get_ipaddress)
  [[ -z "$ip_data" ]] && ip_data='{"ip":"127.0.0.1"}'

  local output
  output=$(format_output "$ip_data")
  echo "$output" | tee "${CONFIG[cache_file]}"
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
