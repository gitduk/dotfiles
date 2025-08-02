#!/usr/bin/env zsh

# Waybar 诗词模块
# 用于显示今日诗词的 waybar 自定义模块

# 配置文件路径
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
TOKEN_FILE="$CACHE_DIR/poetry.token"
CACHE_FILE="$CACHE_DIR/poetry.json"

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

# 获取诗词
get_poetry() {
  local token="$1"
  local response=$(curl -s -H "X-User-Token: $token" "https://v2.jinrishici.com/sentence")

  if [[ $response == "" ]]; then
    echo '{"status":"error","data":{"content":"醉后不知天在水，满船清梦压星河。","origin":{"author":"","title":"","dynasty":""}}}'
  else
    echo "$response"
  fi
}

# 格式化输出
format_output() {
  local json_data="$1"

  # 提取数据
  local content=$(echo "$json_data" | jq -r '.data.content // "暂无诗词"')
  local author=$(echo "$json_data" | jq -r '.data.origin.author // ""')
  local title=$(echo "$json_data" | jq -r '.data.origin.title // ""')
  local dynasty=$(echo "$json_data" | jq -r '.data.origin.dynasty // ""')
  local full=$(echo "$json_data" | jq -r '.data.origin.content // [] | join("\n")')
  local warning=$(echo "$json_data" | jq -r '.warning // ""')

  # 为 waybar 准备的 JSON 格式
  local tooltip=""
  if [[ "$author" != "" && "$title" != "" ]]; then
    tooltip="${title} -- ${dynasty}·${author}"$'\n'"${full}"
  fi

  # 添加 warning 信息
  if [[ "$warning" != "" ]]; then
    tooltip="${tooltip}"$'\n\n'"!!! WARNING !!!"
  fi

  jq -n -c \
    --arg text "$content" \
    --arg tooltip "$tooltip" \
    --arg class "poetry" \
    '{text: $text, tooltip: $tooltip, class: $class}'
}

# 主函数
main() {
  # 检查依赖
  if ! command -v jq &>/dev/null; then
    echo "错误：需要安装 jq 工具" >&2
    echo '{"text":"需要安装 jq", "class":"error"}'
    exit 1
  fi

  if ! command -v curl &>/dev/null; then
    echo "错误：需要安装 curl 工具" >&2
    echo '{"text":"需要安装 curl", "class":"error"}'
    exit 1
  fi

  # 获取 Token
  local token="$(get_token)"
  if [[ $? -ne 0 ]]; then
    echo '{"text":"Token 获取失败", "class":"error"}'
    exit 1
  fi

  # 获取诗词
  local poetry_data=$(get_poetry "$token")

  # 格式化并输出
  format_output "$poetry_data" | tee "$CACHE_FILE"
}

main

