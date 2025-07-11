#!/bin/bash

# ipaddress 模块

# 配置文件路径
CACHE_DIR="$XDG_CACHE_HOME/waybar"
TOKEN_FILE="$CACHE_DIR/ip.token"

# 创建配置目录
mkdir -p "$CACHE_DIR"

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
  "晴") echo "" ;;
  "阴") echo "" ;;
  "云") echo "" ;;
  "雨") echo "" ;;
  "小雨") echo "" ;;
  "大雨") echo "" ;;
  "雪") echo "" ;;
  *) echo "" ;;
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
    tooltip=""
  else
    tooltip="$region | $weather ${temperature}°C | $time"
  fi

  jq -n -c \
    --arg text "$ip" \
    --arg tooltip "$tooltip" \
    --arg class "$class" \
    '{text: $text, tooltip: $tooltip, class: $class}'
}

# 主函数
main() {

  # 检查依赖
  if ! command -v jq &>/dev/null; then
    echo '{"text":"jq not found", "class":"error"}'
    exit 1
  fi

  if ! command -v curl &>/dev/null; then
    echo '{"text":"curl not found", "class":"error"}'
    exit 1
  fi

  # 获取 Token
  local token="$(get_token)"
  if [[ $? -ne 0 ]]; then
    echo '{"text":"get token failed", "class":"error"}'
    exit 1
  fi

  # 获取 IP
  local ip_data=$(get_ipaddress "$token")

  # 格式化并输出
  format_output "$ip_data" | tee $CACHE_DIR/ipaddress.json
}

main
