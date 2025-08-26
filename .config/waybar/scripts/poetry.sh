#!/usr/bin/env bash

# Waybar 诗词模块 - 优化版
# 用于显示今日诗词的 waybar 自定义模块

set -euo pipefail # 严格错误处理

# 配置文件路径
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
TOKEN_FILE="$CACHE_DIR/poetry.token"
CACHE_FILE="$CACHE_DIR/poetry.json"

# 配置参数
readonly CURL_TIMEOUT=8
readonly TOKEN_EXPIRE_HOURS=24
readonly MAX_CONTENT_LENGTH=50 # 诗词内容最大显示长度

# 创建配置目录
mkdir -p "$CACHE_DIR"

# 日志函数
log() {
  echo "[$(date '+%H:%M:%S')] $*" >&2
}

# 显示加载状态
show_loading() {
  local current_data current_content="📜 诗词"

  if [[ -f "$CACHE_FILE" ]]; then
    current_data=$(cat "$CACHE_FILE" 2>/dev/null || echo '{}')
    current_content=$(echo "$current_data" | jq -r '.text // "📜 诗词"' 2>/dev/null || echo "📜 诗词")

    # 如果当前内容太长，截取前20个字符
    if [[ ${#current_content} -gt 20 ]]; then
      current_content="${current_content:0:20}…"
    fi
  fi

  jq -n -c \
    --arg text "${current_content}..." \
    --arg tooltip "🔄 正在获取今日诗词..." \
    --arg class "loading" \
    '{text: $text, tooltip: $tooltip, class: $class}' >"$CACHE_FILE" 2>/dev/null || {
    echo '{"text":"📜 加载中...","tooltip":"正在获取诗词...","class":"loading"}' >"$CACHE_FILE"
  }
}

# 检查Token是否过期
is_token_expired() {
  if [[ ! -f "$TOKEN_FILE" ]]; then
    return 0 # 文件不存在，需要获取
  fi

  local token_mtime file_age_hours
  token_mtime=$(stat -c %Y "$TOKEN_FILE" 2>/dev/null || echo 0)
  file_age_hours=$((($(date +%s) - token_mtime) / 3600))

  [[ $file_age_hours -gt $TOKEN_EXPIRE_HOURS ]]
}

# 获取或刷新 Token
get_token() {
  if ! is_token_expired; then
    cat "$TOKEN_FILE" 2>/dev/null && return 0
  fi

  log "获取新的Token..."
  local token response

  response=$(curl -sSL --connect-timeout "$CURL_TIMEOUT" --max-time "$CURL_TIMEOUT" \
    "https://v2.jinrishici.com/token" 2>/dev/null) || {
    log "Token获取请求失败"
    return 1
  }

  token=$(echo "$response" | jq -r '.data // empty' 2>/dev/null)

  if [[ -n "$token" && "$token" != "null" ]]; then
    echo "$token" >"$TOKEN_FILE"
    log "Token获取成功"
    echo "$token"
    return 0
  else
    log "Token解析失败: $response"
    return 1
  fi
}

# 获取诗词
get_poetry() {
  local token="$1"
  local response

  response=$(curl -sSL --connect-timeout "$CURL_TIMEOUT" --max-time "$CURL_TIMEOUT" \
    -H "X-User-Token: $token" \
    -H "User-Agent: Waybar-Poetry/1.0" \
    "https://v2.jinrishici.com/sentence" 2>/dev/null) || {
    log "诗词请求失败"
    return 1
  }

  if [[ -n "$response" ]]; then
    echo "$response"
    return 0
  else
    log "响应为空"
    return 1
  fi
}

# 截断文本
truncate_text() {
  local text="$1"
  local max_len="$2"

  if [[ ${#text} -gt $max_len ]]; then
    echo "${text:0:$max_len}…"
  else
    echo "$text"
  fi
}

# 处理诗词内容的换行
format_poetry_content() {
  local content="$1"
  # 将诗词中的句号、问号、感叹号后面添加换行，但保持原有的意境
  echo "$content" | sed 's/[。！？]/&\n/g' | grep -v '^$'
}

# 检查更新间隔（简化版，只检查是否正在加载）
is_loading() {
  [[ -f "$CACHE_FILE" ]] || return 1

  local current_class
  current_class=$(cat "$CACHE_FILE" 2>/dev/null | jq -r '.class // ""' 2>/dev/null || echo "")

  [[ "$current_class" == "loading" ]]
}

# 格式化输出
format_output() {
  local json_data="$1"

  # 提取数据
  local status content author title dynasty full warning

  status=$(echo "$json_data" | jq -r '.status // "unknown"' 2>/dev/null || echo "error")
  content=$(echo "$json_data" | jq -r '.data.content // "暂无诗词"' 2>/dev/null || echo "暂无诗词")
  author=$(echo "$json_data" | jq -r '.data.origin.author // ""' 2>/dev/null || echo "")
  title=$(echo "$json_data" | jq -r '.data.origin.title // ""' 2>/dev/null || echo "")
  dynasty=$(echo "$json_data" | jq -r '.data.origin.dynasty // ""' 2>/dev/null || echo "")
  warning=$(echo "$json_data" | jq -r '.warning // ""' 2>/dev/null || echo "")

  # 获取完整诗词内容
  full=$(echo "$json_data" | jq -r '.data.origin.content // [] | 
        if type == "array" then join("\n") 
        else . end' 2>/dev/null || echo "")

  # 处理显示文本（截断过长内容）
  local display_text
  display_text=$(truncate_text "$content" "$MAX_CONTENT_LENGTH")

  # 构建tooltip
  local tooltip=""

  if [[ "$status" == "success" ]]; then
    # 诗词信息
    if [[ -n "$title" && -n "$author" ]]; then
      local source_info="${title}"
      [[ -n "$dynasty" ]] && source_info="${dynasty}·${author}·${source_info}" || source_info="${author}·${source_info}"
      tooltip="📖 ${source_info}"
    fi

    # 完整诗词内容
    if [[ -n "$full" ]]; then
      if [[ -n "$tooltip" ]]; then
        tooltip="${tooltip}"$'\n\n'"${full}"
      else
        tooltip="$full"
      fi
    elif [[ "$content" != "$display_text" ]]; then
      # 如果没有完整内容但显示内容被截断了，显示完整的句子
      if [[ -n "$tooltip" ]]; then
        tooltip="${tooltip}"$'\n\n'"${content}"
      else
        tooltip="$content"
      fi
    fi

    # 添加warning信息
    if [[ -n "$warning" ]]; then
      tooltip="${tooltip}"$'\n\n'"⚠️  ${warning}"
    fi

    # 添加时间信息
    tooltip="${tooltip}"$'\n\n'"🕐 更新于 $(date '+%H:%M:%S')"

  else
    tooltip="❌ 获取诗词失败 | 🕐 $(date '+%H:%M:%S')"
    display_text="❌ 获取失败"
    status="error"
  fi

  # 输出JSON
  jq -n -c \
    --arg text "$display_text" \
    --arg tooltip "$tooltip" \
    --arg class "$status" \
    '{text: $text, tooltip: $tooltip, class: $class}' 2>/dev/null || {
    echo "{\"text\":\"$display_text\",\"tooltip\":\"$tooltip\",\"class\":\"$status\"}"
  }
}

# 创建错误输出
create_error_output() {
  local message="$1"
  local current_time=$(date "+%H:%M:%S")

  jq -n -c \
    --arg text "❌ 错误" \
    --arg tooltip "❌ $message | 🕐 $current_time" \
    --arg class "error" \
    '{text: $text, tooltip: $tooltip, class: $class}' 2>/dev/null || {
    echo "{\"text\":\"❌ 错误\",\"tooltip\":\"❌ $message\",\"class\":\"error\"}"
  }
}

# 创建默认诗词（网络不可用时的备用内容）
create_fallback_poetry() {
  local fallback_poems=(
    "山重水复疑无路，柳暗花明又一村。|游山西村|宋·陆游"
    "海内存知己，天涯若比邻。|送杜少府之任蜀州|唐·王勃"
    "会当凌绝顶，一览众山小。|望岳|唐·杜甫"
    "采菊东篱下，悠然见南山。|饮酒·其五|晋·陶渊明"
    "落红不是无情物，化作春泥更护花。|己亥杂诗|清·龚自珍"
  )

  # 基于当前时间选择一首诗
  local index=$(($(date +%s) / 86400 % ${#fallback_poems[@]}))
  local selected="${fallback_poems[$index]}"

  IFS='|' read -r content title author <<<"$selected"

  local tooltip="📖 ${title} - ${author}"$'\n\n'"${content}"$'\n\n'"🕐 离线模式 $(date '+%H:%M:%S')"

  jq -n -c \
    --arg text "$content" \
    --arg tooltip "$tooltip" \
    --arg class "offline" \
    '{text: $text, tooltip: $tooltip, class: $class}' 2>/dev/null || {
    echo "{\"text\":\"$content\",\"tooltip\":\"$tooltip\",\"class\":\"offline\"}"
  }
}

# 检查依赖
check_dependencies() {
  local missing_deps=()

  command -v jq >/dev/null 2>&1 || missing_deps+=("jq")
  command -v curl >/dev/null 2>&1 || missing_deps+=("curl")

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    local dep_list=$(
      IFS=', '
      echo "${missing_deps[*]}"
    )
    create_error_output "缺少依赖: $dep_list"
    return 1
  fi

  return 0
}

# 点击处理函数
handle_click() {
  # 如果正在加载中，则跳过此次点击
  if is_loading; then
    log "正在加载中，跳过此次点击"
    return 0
  fi

  show_loading

  # 在后台更新，避免阻塞
  (
    sleep 0.1 # 让加载状态先显示
    update_poetry
  ) &
}

# 更新诗词的核心函数
update_poetry() {
  local token poetry_data

  # 检查依赖
  if ! check_dependencies; then
    check_dependencies >"$CACHE_FILE"
    return 1
  fi

  # 获取Token
  if ! token=$(get_token); then
    log "Token获取失败，使用离线模式"
    create_fallback_poetry >"$CACHE_FILE"
    return 0 # 不算错误，只是使用备用内容
  fi

  # 获取诗词
  if ! poetry_data=$(get_poetry "$token"); then
    # Token可能过期，删除并重试一次
    rm -f "$TOKEN_FILE"
    if token=$(get_token) && poetry_data=$(get_poetry "$token"); then
      log "重新获取Token后成功"
    else
      log "网络请求失败，使用离线模式"
      create_fallback_poetry >"$CACHE_FILE"
      return 0
    fi
  fi

  # 验证返回的数据格式
  if ! echo "$poetry_data" | jq . >/dev/null 2>&1; then
    log "数据格式错误，使用离线模式"
    create_fallback_poetry >"$CACHE_FILE"
    return 0
  fi

  # 格式化并保存
  format_output "$poetry_data" >"$CACHE_FILE"
}

# 显示帮助信息
show_help() {
  cat <<'EOF'
诗词显示模块

用法: 
  poetry.sh [选项]

选项:
  无参数     - 更新诗词（用于初始化和定期更新）
  --click    - 处理点击事件（显示加载状态并异步更新）
  --force    - 强制更新诗词
  --status   - 显示缓存状态信息
  --clean    - 清理缓存文件
  --help     - 显示帮助信息
EOF
}

# 显示状态信息
show_status() {
  echo "=== 诗词模块状态 ==="
  echo "缓存目录: $CACHE_DIR"
  echo "配置文件: $TOKEN_FILE"
  echo "缓存文件: $CACHE_FILE"
  echo

  if [[ -f "$TOKEN_FILE" ]]; then
    local token_age=$((($(date +%s) - $(stat -c %Y "$TOKEN_FILE" 2>/dev/null || echo 0)) / 3600))
    echo "Token状态: 存在 (${token_age}小时前)"
  else
    echo "Token状态: 不存在"
  fi

  if [[ -f "$CACHE_FILE" ]]; then
    local cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)))
    local current_class=$(cat "$CACHE_FILE" 2>/dev/null | jq -r '.class // ""' 2>/dev/null || echo "")
    echo "缓存状态: 存在 (${cache_age}秒前)"
    echo "当前状态: $current_class"
    echo "缓存内容:"
    cat "$CACHE_FILE" 2>/dev/null | jq . 2>/dev/null || echo "  格式错误或为空"
  else
    echo "缓存状态: 不存在"
  fi
}

# 清理缓存
clean_cache() {
  log "清理缓存文件..."
  rm -f "$TOKEN_FILE" "$CACHE_FILE"
  echo "缓存已清理"
}

# 主函数
main() {
  case "${1:-}" in
  "--click")
    handle_click
    ;;
  "--force")
    update_poetry
    ;;
  "--status")
    show_status
    ;;
  "--clean")
    clean_cache
    ;;
  "--help" | "-h")
    show_help
    ;;
  "")
    # 默认行为：直接更新诗词
    update_poetry
    ;;
  *)
    echo "❌ 未知参数: $1" >&2
    echo "使用 --help 查看帮助信息" >&2
    exit 1
    ;;
  esac
}

# 运行主函数
main "$@"
