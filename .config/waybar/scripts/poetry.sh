#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=$(basename "$0")
VERSION="1.3.0"

##############
### config ###
##############

declare -A CONFIG=(
  [cache_dir]="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
  [token_file]="${XDG_CACHE_HOME:-$HOME/.cache}/waybar/poetry.token"
  [cache_file]="${XDG_CACHE_HOME:-$HOME/.cache}/waybar/poetry.json"
  [last_request_file]="${XDG_CACHE_HOME:-$HOME/.cache}/waybar/poetry.last"
  [history_file]="${XDG_CACHE_HOME:-$HOME/.cache}/waybar/poetry.history"
  [curl_timeout]=10
  [token_expire_hours]=24
  [max_content_length]=50
  [min_request_interval]=60
  [max_history_size]=1000
  # [retry_delay]=3600  # 保留配置项，将来可用于失败重试间隔
)

mkdir -p "${CONFIG[cache_dir]}" 2>/dev/null || {
  echo '{"text":"无法创建缓存目录","class":"error"}' >&2
  exit 1
}

# 检查缓存目录是否可写
if [[ ! -w "${CONFIG[cache_dir]}" ]]; then
  echo '{"text":"缓存目录不可写","class":"error"}' >&2
  exit 1
fi

# 检查必要依赖
check_dependencies() {
  local missing_deps=()

  command -v curl >/dev/null || missing_deps+=("curl")
  command -v jq >/dev/null || missing_deps+=("jq")

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    local deps_str="${missing_deps[*]}"
    echo "{\"text\":\"缺少依赖: $deps_str\",\"class\":\"error\"}" > "${CONFIG[cache_file]}"
    error "缺少必要依赖: $deps_str"
    return 1
  fi
  return 0
}

show_help() {
  cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Options:
  --click      Handle click (show loading and update)
  --force      Force update poetry (ignore rate limit)
  --status     Show cache/token status
  --clean      Clean cache files
  -h, --help   Show this help
  -v, --version Show version
  (no args)    Update poetry (with rate limit)
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
  echo "历史文件: ${CONFIG[history_file]}"
  echo "最小请求间隔: ${CONFIG[min_request_interval]} 秒"
  [[ -f "${CONFIG[token_file]}" ]] && echo "Token: 存在" || echo "Token: 不存在"
  [[ -f "${CONFIG[cache_file]}" ]] && echo "缓存: 存在" || echo "缓存: 不存在"

  # 显示历史文件状态
  if [[ -f "${CONFIG[history_file]}" ]]; then
    local history_count=0
    if command -v jq >/dev/null 2>&1; then
      history_count=$(jq '. | length' "${CONFIG[history_file]}" 2>/dev/null || echo 0)
    else
      history_count=$(grep -c '"content"' "${CONFIG[history_file]}" 2>/dev/null || echo 0)
    fi
    echo "历史记录: 存在 (${history_count} 条)"
  else
    echo "历史记录: 不存在"
  fi

  if [[ -f "${CONFIG[last_request_file]}" ]]; then
    local last_req now elapsed wait
    last_req=$(cat "${CONFIG[last_request_file]}" 2>/dev/null || echo 0)
    now=$(date +%s)
    elapsed=$((now - last_req))
    wait=$(( CONFIG[min_request_interval] - elapsed ))
    [[ $wait -lt 0 ]] && wait=0
    echo "上次请求: ${elapsed} 秒前"
    echo "可再次请求: ${wait} 秒后"
  fi
}

truncate_text() {
  local text="$1" max_len="$2"
  if [[ ${#text} -gt $max_len ]]; then
    echo "${text:0:$max_len}…"
  else
    echo "$text"
  fi
}

# 检查是否可以发起新请求（防止频繁请求）
can_make_request() {
  local force_update="${1:-false}"

  # 强制更新时跳过检查
  [[ "$force_update" == "true" ]] && return 0

  [[ ! -f "${CONFIG[last_request_file]}" ]] && return 0

  local last_request_time current_time elapsed
  last_request_time=$(cat "${CONFIG[last_request_file]}" 2>/dev/null || echo 0)
  current_time=$(date +%s)
  elapsed=$((current_time - last_request_time))

  if [[ $elapsed -lt ${CONFIG[min_request_interval]} ]]; then
    local wait_time=$((CONFIG[min_request_interval] - elapsed))
    return 1
  fi

  return 0
}

# 记录请求时间
record_request_time() {
  date +%s > "${CONFIG[last_request_file]}"
}

is_token_expired() {
  [[ ! -f "${CONFIG[token_file]}" ]] && return 0
  local token_mtime file_age_hours

  # 跨平台获取文件修改时间
  if stat -c %Y "${CONFIG[token_file]}" &>/dev/null; then
    # GNU stat (Linux)
    token_mtime=$(stat -c %Y "${CONFIG[token_file]}")
  elif stat -f %m "${CONFIG[token_file]}" &>/dev/null; then
    # BSD stat (macOS)
    token_mtime=$(stat -f %m "${CONFIG[token_file]}")
  else
    # 回退方案：使用 date 和 ls
    token_mtime=$(date -r "${CONFIG[token_file]}" +%s 2>/dev/null || echo 0)
  fi

  file_age_hours=$(( ( $(date +%s) - token_mtime ) / 3600 ))
  [[ $file_age_hours -gt ${CONFIG[token_expire_hours]} ]]
}

get_token() {
  # 如果 token 存在且未过期，直接输出它
  if ! is_token_expired; then
    cat "${CONFIG[token_file]}" 2>/dev/null && return 0
  fi

  info "Fetching new token..."

  # 更真实的 User-Agent 列表，随机挑选一个
  local user_agents=(
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (X11; Linux x86_64; rv:121.0) Gecko/20100101 Firefox/121.0"
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36 Edg/119.0.0.0"
  )
  local random_ua="${user_agents[$RANDOM % ${#user_agents[@]}]}"

  local response token
  response=$(curl -sSL \
    --connect-timeout "${CONFIG[curl_timeout]}" \
    --max-time "${CONFIG[curl_timeout]}" \
    -H "User-Agent: $random_ua" \
    -H "Accept: application/json" \
    -H "Accept-Language: zh-CN,zh;q=0.9,en;q=0.8" \
    -H "Referer: https://www.jinrishici.com/" \
    "https://v2.jinrishici.com/token") || {
      error "Token request failed"
      return 1
    }

  # 解析 token（兼容不同返回形式）
  if command -v jq >/dev/null 2>&1; then
    token=$(jq -r '.data // .data.token // .token // empty' <<<"$response")
  else
    # jq 不存在时尝试从简单的 JSON 中提取（保守方案，可能不可靠）
    token=$(printf '%s' "$response" | sed -n 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' || true)
  fi

  if [[ -n "$token" && "$token" != "null" ]]; then
    echo "$token" >"${CONFIG[token_file]}"
    info "Token saved"
    echo "$token"
    return 0
  else
    error "Token parse failed: $response"
    return 1
  fi
}

get_poetry() {
  local token="$1"

  # 随机 User-Agent
  local user_agents=(
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (X11; Linux x86_64; rv:121.0) Gecko/20100101 Firefox/121.0"
  )
  local random_ua="${user_agents[$RANDOM % ${#user_agents[@]}]}"

  curl -sSL \
    --connect-timeout "${CONFIG[curl_timeout]}" \
    --max-time "${CONFIG[curl_timeout]}" \
    -H "X-User-Token: $token" \
    -H "User-Agent: $random_ua" \
    -H "Accept: application/json" \
    -H "Accept-Language: zh-CN,zh;q=0.9" \
    -H "Referer: https://www.jinrishici.com/" \
    "https://v2.jinrishici.com/sentence"
}

# 保存诗词到历史记录
save_to_history() {
  local json_data="$1"

  # 如果没有jq，跳过历史保存
  command -v jq >/dev/null || return 0

  # 解析诗词信息
  local status content author title dynasty
  status=$(jq -r '.status // "unknown"' <<<"$json_data")

  # 只保存成功获取的诗词
  [[ "$status" != "success" ]] && return 0

  content=$(jq -r '.data.content // ""' <<<"$json_data")
  author=$(jq -r '.data.origin.author // ""' <<<"$json_data")
  title=$(jq -r '.data.origin.title // ""' <<<"$json_data")
  dynasty=$(jq -r '.data.origin.dynasty // ""' <<<"$json_data")

  # 内容为空时跳过
  [[ -z "$content" || "$content" == "null" ]] && return 0

  # 创建历史记录条目
  local history_entry
  history_entry=$(jq -n -c \
    --arg content "$content" \
    --arg author "$author" \
    --arg title "$title" \
    --arg dynasty "$dynasty" \
    --arg timestamp "$(date +%s)" \
    '{content:$content, author:$author, title:$title, dynasty:$dynasty, timestamp:($timestamp|tonumber)}')

  # 初始化历史文件（如果不存在）
  if [[ ! -f "${CONFIG[history_file]}" ]]; then
    echo '[]' > "${CONFIG[history_file]}"
  fi

  # 读取现有历史
  local current_history
  current_history=$(cat "${CONFIG[history_file]}" 2>/dev/null) || current_history='[]'

  # 检查是否已存在相同内容（避免重复）
  local exists
  exists=$(jq --arg content "$content" 'any(.content == $content)' <<<"$current_history" 2>/dev/null || echo "false")

  # 使用 PID 创建唯一临时文件，避免竞态条件
  local tmpfile="${CONFIG[history_file]}.tmp.$$"

  if [[ "$exists" == "true" ]]; then
    # 如果已存在，更新时间戳
    jq --arg content "$content" --arg timestamp "$(date +%s)" \
      'map(if .content == $content then .timestamp = ($timestamp|tonumber) else . end)' \
      <<<"$current_history" > "$tmpfile" && \
      mv "$tmpfile" "${CONFIG[history_file]}"
  else
    # 添加新记录并限制数量
    jq --argjson entry "$history_entry" --argjson max_size "${CONFIG[max_history_size]}" \
      '. + [$entry] | sort_by(.timestamp) | reverse | .[:$max_size]' \
      <<<"$current_history" > "$tmpfile" && \
      mv "$tmpfile" "${CONFIG[history_file]}"
  fi

  # 清理可能残留的临时文件
  rm -f "$tmpfile" 2>/dev/null || true
}

format_output() {
  local json_data="$1"

  local status content author title dynasty full warning
  if command -v jq >/dev/null 2>&1; then
    status=$(jq -r '.status // "unknown"' <<<"$json_data")
    content=$(jq -r '.data.content // "暂无诗词"' <<<"$json_data")
    author=$(jq -r '.data.origin.author // ""' <<<"$json_data")
    title=$(jq -r '.data.origin.title // ""' <<<"$json_data")
    dynasty=$(jq -r '.data.origin.dynasty // ""' <<<"$json_data")
    ipaddress=$(jq -r '.ipAddress // "127.0.0.1"' <<<"$json_data")
    warning=$(jq -r '.warning // ""' <<<"$json_data")
    full=$(jq -r '.data.origin.content // [] | if type=="array" then join("\n") else . end' <<<"$json_data")
  else
    # 没有 jq 的保守解析（只做最基本显示）
    status="unknown"
    content="$json_data"
    author=""
    title=""
    dynasty=""
    warning=""
    full=""
  fi

  local display_text tooltip
  display_text=$(truncate_text "$content" "${CONFIG[max_content_length]}")

  if [[ "$status" == "success" ]]; then
    tooltip=""
    [[ -n "$title" && -n "$author" ]] && tooltip="󱉟 ${dynasty:+$dynasty·}$author·$title"
    [[ -n "$full" ]] && tooltip="$tooltip"$'\n\n'"$full"
    [[ "$content" != "$display_text" ]] && tooltip="$tooltip"$'\n\n'"$content"
    [[ -n "$warning" ]] && tooltip="$tooltip"$'\n\n'" $warning"
    [[ -n "$ipaddress" ]] && ipaddress="- $ipaddress"
    tooltip="$tooltip"$'\n\n'" 更新于 $(date '+%H:%M:%S') $ipaddress"
  else
    tooltip="❌ 获取诗词失败 |  $(date '+%H:%M:%S')"
    display_text="❌ 获取失败"
    status="error"
  fi

  # 保存成功的诗词到历史记录
  [[ "$status" == "success" ]] && save_to_history "$json_data"

  # 输出为 compact JSON for waybar
  if command -v jq >/dev/null 2>&1; then
    jq -n -c --arg text "$display_text" --arg tooltip "$tooltip" --arg class "$status" \
      '{text:$text, tooltip:$tooltip, class:$class}'
  else
    # 没有 jq 时手动构造（注意基本转义）
    printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
      "$(echo "$display_text" | sed 's/["\\]/\\&/g')" \
      "$(echo "$tooltip" | sed 's/["\\]/\\&/g')" \
      "$status"
  fi
}

create_fallback_poetry() {
  local content author title dynasty tooltip display_text class
  local wait_time_info=""
  if [[ -f "${CONFIG[last_request_file]}" ]]; then
    local last_req now elapsed wait
    last_req=$(cat "${CONFIG[last_request_file]}" 2>/dev/null || echo 0)
    now=$(date +%s)
    elapsed=$((now - last_req))
    wait=$(( CONFIG[min_request_interval] - elapsed ))
    [[ $wait -lt 0 ]] && wait=0
    wait_time_info=" 请 ${wait} 秒后重试"
  fi

  # 首先尝试从历史记录中随机选择
  if [[ -f "${CONFIG[history_file]}" ]] && command -v jq >/dev/null 2>&1; then
    local history_count
    history_count=$(jq '. | length' "${CONFIG[history_file]}" 2>/dev/null || echo 0)

    if [[ $history_count -gt 0 ]]; then
      # 从历史记录中随机选择
      local random_idx=$(( RANDOM % history_count ))
      local history_entry
      history_entry=$(jq ".[$random_idx]" "${CONFIG[history_file]}" 2>/dev/null)

      if [[ -n "$history_entry" && "$history_entry" != "null" ]]; then
        content=$(jq -r '.content // ""' <<<"$history_entry")
        author=$(jq -r '.author // ""' <<<"$history_entry")
        title=$(jq -r '.title // ""' <<<"$history_entry")
        dynasty=$(jq -r '.dynasty // ""' <<<"$history_entry")

        if [[ -n "$content" ]]; then
          display_text=$(truncate_text "$content" "${CONFIG[max_content_length]}")
          tooltip=""
          [[ -n "$title" && -n "$author" ]] && tooltip="󱉟 ${dynasty:+$dynasty·}$author·$title"
          tooltip="$tooltip"$'\n\n'" 离线模式 $(date '+%H:%M:%S')"$'\n'"$wait_time_info"
          class="history"

          jq -n -c --arg text "$display_text" --arg tooltip "$tooltip" --arg class "$class" \
            '{text:$text, tooltip:$tooltip, class:$class}'
          return 0
        fi
      fi
    fi
  fi

  # 回退到固定诗词列表（如果历史记录不可用）
  local poems=(
    "山重水复疑无路，柳暗花明又一村。|宋·陆游《游山西村》"
    "会当凌绝顶，一览众山小。|唐·杜甫《望岳》"
    "采菊东篱下，悠然见南山。|晋·陶渊明《饮酒》"
    "海内存知己，天涯若比邻。|唐·王勃《送杜少府之任蜀州》"
    "欲穷千里目，更上一层楼。|唐·王之涣《登鹳雀楼》"
    "春风得意马蹄疾，一日看尽长安花。|唐·孟郊《登科后》"
    "问君能有几多愁，恰似一江春水向东流。|南唐·李煜《虞美人》"
    "人生自古谁无死，留取丹心照汗青。|宋·文天祥《过零丁洋》"
    "天生我材必有用，千金散尽还复来。|唐·李白《将进酒》"
    "长风破浪会有时，直挂云帆济沧海。|唐·李白《行路难》"
    "落霞与孤鹜齐飞，秋水共长天一色。|唐·王勃《滕王阁序》"
    "先天下之忧而忧，后天下之乐而乐。|宋·范仲淹《岳阳楼记》"
    "千里莺啼绿映红，水村山郭酒旗风。|唐·杜牧《江南春》"
    "春江潮水连海平，海上明月共潮生。|唐·张若虚《春江花月夜》"
    "但愿人长久，千里共婵娟。|宋·苏轼《水调歌头》"
  )
  local idx=$(( ( $(date +%s) + RANDOM ) % ${#poems[@]} ))
  content="${poems[$idx]%%|*}"
  local info="${poems[$idx]##*|}"
  tooltip="󱉟 $info"$'\n\n'" 离线模式 $(date '+%H:%M:%S')"$'\n'"$wait_time_info"

  class="offline"
  if command -v jq >/dev/null 2>&1; then
    jq -n -c --arg text "$content" --arg tooltip "$tooltip" --arg class "$class" \
      '{text:$text, tooltip:$tooltip, class:$class}'
  else
    printf '{"text":"%s","tooltip":"%s","class":"offline"}\n' \
      "$(echo "$content" | sed 's/["\\]/\\&/g')" \
      "$(echo "$tooltip" | sed 's/["\\]/\\&/g')"
  fi
}

update_poetry() {
  local force_update="${1:-false}"

  # 检查请求频率限制
  if ! can_make_request "$force_update"; then
    # 如果缓存存在，继续使用旧缓存
    if [[ -f "${CONFIG[cache_file]}" ]]; then
      info "使用现有缓存"
      return 0
    else
      # 没有缓存时使用离线模式
      create_fallback_poetry >"${CONFIG[cache_file]}"
      return 0
    fi
  fi

  # 记录本次请求时间（尽早记录以避免并发重复请求）
  record_request_time

  local token poetry_data
  if ! token=$(get_token); then
    warn "Token 获取失败，使用离线模式"
    create_fallback_poetry >"${CONFIG[cache_file]}"
    return 0
  fi

  # 添加短随机延迟，模拟人类行为
  sleep 0.$((RANDOM % 5))

  poetry_data=$(get_poetry "$token") || poetry_data=""
  if [[ -z "$poetry_data" ]]; then
    error "数据为空，使用离线模式"
    create_fallback_poetry >"${CONFIG[cache_file]}"
    return 0
  fi

  # 如果有 jq 做验证和格式化，否则直接写回
  if command -v jq >/dev/null 2>&1; then
    if ! jq . <<<"$poetry_data" &>/dev/null; then
      error "返回数据不是有效 JSON，使用离线模式"
      create_fallback_poetry >"${CONFIG[cache_file]}"
      return 0
    fi
  fi

  format_output "$poetry_data" >"${CONFIG[cache_file]}"
}

show_loading_state() {
  # 获取当前诗词
  local current_text
  if [[ -f "${CONFIG[cache_file]}" ]]; then
    current_text=$(jq -r .text "${CONFIG[cache_file]}" 2>/dev/null || echo "")
  else
    current_text=""
  fi

  # 先写入 loading 状态到缓存，Waybar 等会立即显示
  if command -v jq >/dev/null 2>&1; then
    jq -n -c --arg text "$current_text ..." --arg tooltip "正在刷新诗词..." --arg class "loading" \
      '{text:$text, tooltip:$tooltip, class:$class}' >"${CONFIG[cache_file]}"
  else
    printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$current_text ..." "正在刷新诗词..." "loading" >"${CONFIG[cache_file]}"
  fi
}

handle_click() {
  # 点击时强制尝试刷新（但仍保留 can_make_request 的提示行为）
  if ! can_make_request "false"; then
    # 过于频繁时显示随机诗词（临时）
    create_fallback_poetry >"${CONFIG[cache_file]}"
    return 0
  fi

  show_loading_state

  # 后台更新（非阻塞），使用 disown 确保进程不受父进程影响
  # 在子 shell 中禁用 set -e 避免意外退出
  (
    set +e
    sleep 0.1
    update_poetry "false"
  ) &
  disown
}

handle_force() {
  show_loading_state

  # 后台更新（非阻塞），使用 disown 确保进程不受父进程影响
  # 在子 shell 中禁用 set -e 避免意外退出
  (
    set +e
    sleep 0.1
    update_poetry "true"
  ) &
  disown
}

clean_cache() {
  rm -f "${CONFIG[token_file]}" "${CONFIG[cache_file]}" "${CONFIG[last_request_file]}" "${CONFIG[history_file]}" || true
  echo "缓存已清理"
}

main() {
  # 检查依赖（仅在需要时检查）
  if [[ $# -eq 0 ]] || [[ "$1" == "--click" ]] || [[ "$1" == "--force" ]]; then
    check_dependencies || exit 1
  fi

  [[ $# -eq 0 ]] && { update_poetry "false"; exit 0; }

  while [[ $# -gt 0 ]]; do
    case $1 in
      --click) handle_click ;;
      --force) handle_force ;;
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
