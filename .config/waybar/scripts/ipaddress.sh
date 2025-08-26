#!/bin/bash

# 配置文件路径
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
TOKEN_FILE="$CACHE_DIR/ip.token"
CACHE_FILE="$CACHE_DIR/ipaddress.json"

# 创建配置目录
mkdir -p "$CACHE_DIR"

# 显示加载状态
show_loading() {
  local current_ip=""
  if [[ -f "$CACHE_FILE" ]]; then
    current_ip=$(cat "$CACHE_FILE" | jq -r '.text // "127.0.0.1"' 2>/dev/null)
  fi
  [[ -z "$current_ip" ]] && current_ip="127.0.0.1"

  jq -n -c \
    --arg text "${current_ip}..." \
    --arg tooltip "正在刷新 IP 地址信息..." \
    --arg class "loading" \
    '{text: $text, tooltip: $tooltip, class: $class}' >"$CACHE_FILE"
}

# 获取或读取 Token
get_token() {
  if [[ -f "$TOKEN_FILE" ]]; then
    cat "$TOKEN_FILE"
  else
    echo "正在获取 Token..." >&2
    token=$(curl -s "https://v2.jinrishici.com/token" | jq -r '.data')
    if [[ "$token" != "null" && "$token" != "" ]]; then
      echo "$token" >"$TOKEN_FILE"
      echo "$token"
    else
      echo "获取 Token 失败" >&2
      return 1
    fi
  fi
}

# 获取 IP 地址
get_ipaddress() {
  local token="$1"
  local response=$(curl -s -H "X-User-Token: $token" "https://v2.jinrishici.com/info")

  if [[ -z "$response" ]]; then
    echo '{"status":"error","data":{"ip":"127.0.0.1","region":"","weatherData":{"weather":"","temperature":""}}}'
  else
    echo "$response"
  fi
}

format_weather() {
  local weather="$1"
  case "$weather" in
  "晴") echo "" ;;
  "阴") echo "" ;;
  "云") echo "" ;;
  "雨") echo "" ;;
  "小雨") echo "" ;;
  "大雨") echo "" ;;
  "雪") echo "" ;;
  *) echo "" ;;
  esac
}

# 格式化输出
format_output() {
  local json_data="$1"

  # 提取数据
  local class=$(echo "$json_data" | jq -r '.status')
  local ip=$(echo "$json_data" | jq -r '.data.ip // "127.0.0.1"')
  local region=$(echo "$json_data" | jq -r '.data.region // ""')
  local weather=$(echo "$json_data" | jq -r '.data.weatherData.weather // ""')
  local temperature=$(echo "$json_data" | jq -r '.data.weatherData.temperature // ""')
  local time=$(echo "$json_data" | jq -r '.data.beijingTime // ""')

  if [[ "$time" == "" ]]; then
    time=$(date "+%H:%M:%S")
  else
    time="${time#*T}"
    time="${time%.*}"
    region="${region/|/-}"
  fi

  if [[ "$class" = "error" ]]; then
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

# 点击处理函数
handle_click() {
  # 显示加载状态
  show_loading

  # 在后台更新 IP 信息
  {
    sleep 0.1 # 让加载状态先显示
    update_ip
  } &
}

# 更新 IP 信息
update_ip() {
  # 检查依赖
  if ! command -v jq &>/dev/null; then
    echo '{"text":"jq not found", "class":"error"}' >"$CACHE_FILE"
    return 1
  fi

  if ! command -v curl &>/dev/null; then
    echo '{"text":"curl not found", "class":"error"}' >"$CACHE_FILE"
    return 1
  fi

  # 获取 Token
  local token="$(get_token)"
  if [[ $? -ne 0 ]]; then
    echo '{"text":"get token failed", "class":"error"}' >"$CACHE_FILE"
    return 1
  fi

  # 获取 IP
  local ip_data=$(get_ipaddress "$token")

  # 格式化并保存
  format_output "$ip_data" >"$CACHE_FILE"
}

# 显示帮助信息
show_help() {
  cat <<EOF
用法: $0 [选项]

选项:
  无参数     - 更新 IP 信息（初始化时使用）
  --click    - 处理点击事件（显示加载状态并后台更新）
  --help     - 显示此帮助信息

waybar 配置示例:
"custom/ipaddress": {
    "exec": "cat ~/.cache/waybar/ipaddress.json || echo '{\"text\": \"127.0.0.1\"}'",
    "format": " {} ",
    "return-type": "json",
    "interval": 1,
    "tooltip": true,
    "on-click": "$0 --click"
}
EOF
}

# 主函数
main() {
  case "$1" in
  "--click")
    handle_click
    ;;
  "--help" | "-h")
    show_help
    ;;
  "")
    # 默认行为：更新 IP 信息
    update_ip
    ;;
  *)
    echo "未知参数: $1"
    echo "使用 --help 查看帮助信息"
    exit 1
    ;;
  esac
}

main "$@"
