#!/bin/bash

# Waybar 诗词模块
# 用于显示今日诗词的 waybar 自定义模块

# 配置文件路径
CACHE_DIR="$XDG_CACHE_HOME/waybar"
TOKEN_FILE="$CACHE_DIR/poetry_token"
CACHE_FILE="$CACHE_DIR/poetry_cache"

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

  if [[ $? -eq 0 ]]; then
    echo "$response" >"$CACHE_FILE"
    echo "$response"
  else
    # 如果网络请求失败，尝试使用缓存
    if [[ -f "$CACHE_FILE" ]]; then
      cat "$CACHE_FILE"
    else
      echo '{"status":"error","data":{"content":"网络连接失败","origin":{"author":"","title":"","dynasty":""}}}'
    fi
  fi
}

# 格式化输出
format_output() {
  local json_data="$1"
  local format="$2"

  # 提取数据
  local content=$(echo "$json_data" | jq -r '.data.content // "暂无诗词"')
  local author=$(echo "$json_data" | jq -r '.data.origin.author // ""')
  local title=$(echo "$json_data" | jq -r '.data.origin.title // ""')
  local dynasty=$(echo "$json_data" | jq -r '.data.origin.dynasty // ""')

  case "$format" in
  "content-only")
    echo "$content"
    ;;
  "json")
    # 为 waybar 准备的 JSON 格式
    local tooltip=""
    if [[ "$author" != "" && "$title" != "" ]]; then
      tooltip="${title} -- ${dynasty}·${author}"
    else
      tooltip="今日诗词"
    fi

    # 限制显示长度
    local display_content="$content"
    if [[ ${#display_content} -gt 30 ]]; then
      display_content="${display_content:0:27}..."
    fi

    # 配置 tooltip
    if [[ "$display_content" != "$content" ]]; then
      tooltip="$tooltip | $content"
    fi

    jq -n -c \
      --arg text "$display_content" \
      --arg tooltip "$tooltip" \
      --arg class "poetry" \
      '{text: $text, tooltip: $tooltip, class: $class}'
    ;;
  *)
    echo "$content"
    ;;
  esac
}

# 主函数
main() {
  local format="${1:-json}"

  # 检查依赖
  if ! command -v jq &>/dev/null; then
    echo "错误：需要安装 jq 工具" >&2
    echo '{"text":"需要安装jq","class":"error"}'
    exit 1
  fi

  if ! command -v curl &>/dev/null; then
    echo "错误：需要安装 curl 工具" >&2
    echo '{"text":"需要安装curl","class":"error"}'
    exit 1
  fi

  # 获取 Token
  local token=$(get_token)
  if [[ $? -ne 0 ]]; then
    echo '{"text":"Token获取失败","class":"error"}'
    exit 1
  fi

  # 获取诗词
  local poetry_data=$(get_poetry "$token")

  # 检查 API 响应状态
  local status=$(echo "$poetry_data" | jq -r '.status // "error"')
  if [[ "$status" != "success" ]]; then
    # Token 可能过期，尝试重新获取
    rm -f "$TOKEN_FILE"
    token=$(get_token)
    if [[ $? -eq 0 ]]; then
      poetry_data=$(get_poetry "$token")
    fi
  fi

  # 格式化并输出
  format_output "$poetry_data" "$format"
}

# 处理命令行参数
case "$1" in
"--refresh" | "-r")
  rm -f "$CACHE_FILE"
  main json
  ;;
"--content" | "-c")
  main content-only
  ;;
"--help" | "-h")
  echo "用法: $0 [选项]"
  echo "选项:"
  echo "  -r, --refresh    刷新缓存并获取新诗词"
  echo "  -c, --content    只显示诗句内容"
  echo "  -h, --help       显示此帮助信息"
  echo "  无参数           输出 waybar JSON 格式"
  ;;
*)
  main json
  ;;
esac
