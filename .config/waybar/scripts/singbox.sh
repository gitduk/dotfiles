#!/usr/bin/env bash

CONFIG_ROOT="$HOME/.config/sing-box"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
IP_CACHE="$CACHE_DIR/singbox.ip.cache"
IP_LOCK="$CACHE_DIR/singbox.ip.lock"
IP_API="https://ipinfo.io/json"

mkdir -p "$CACHE_DIR"

# 后台刷新 IP 缓存（非阻塞）
_refresh_ip_cache() {
  # 防止并发刷新
  if [[ -f "$IP_LOCK" ]] && kill -0 "$(cat "$IP_LOCK" 2>/dev/null)" 2>/dev/null; then
    return
  fi

  (
    echo $$ > "$IP_LOCK"
    trap 'rm -f "$IP_LOCK"' EXIT

    local ip_data
    ip_data=$(curl -s --max-time 3 "$IP_API" 2>/dev/null)
    [[ -z "$ip_data" ]] && return

    local ip city region country org
    ip=$(echo "$ip_data" | jq -r '.ip // "N/A"')
    city=$(echo "$ip_data" | jq -r '.city // ""')
    region=$(echo "$ip_data" | jq -r '.region // ""')
    country=$(echo "$ip_data" | jq -r '.country // ""')
    org=$(echo "$ip_data" | jq -r '.org // ""')

    local location=""
    [[ -n "$city" ]] && location="$city"
    [[ -n "$region" ]] && location="${location:+$location, }$region"
    [[ -n "$country" ]] && location="${location:+$location, }$country"
    [[ -z "$location" ]] && location="Unknown"

    local info="$ip\\n$location"
    [[ -n "$org" ]] && info="$info | $org"
    echo "$info" > "$IP_CACHE"
  ) &
  disown
}

# 获取 IP 信息（立即返回，不阻塞）
get_ip_info() {
  if [[ -f "$IP_CACHE" ]]; then
    cat "$IP_CACHE"
    # 超过 5 分钟则后台刷新
    local age=$(( $(date +%s) - $(stat -c %Y "$IP_CACHE" 2>/dev/null || echo 0) ))
    [[ $age -ge 300 ]] && _refresh_ip_cache
  else
    echo "loading..."
    _refresh_ip_cache
  fi
}

# 获取所有 json 配置文件（不含 .json 后缀）
ls_config() {
  find "$CONFIG_ROOT" -maxdepth 1 -type f -name "*.json" -exec basename {} \; | sort | sed 's/\.json$//'
}

# 切换配置
set_config() {
  local name="$1"
  ln -sf "$CONFIG_ROOT/$name.json" "$CONFIG_ROOT/config.json"
  systemctl --user restart sing-box.service
}

# 获取当前配置文件名（不含 .json）
current_config() {
  basename "$(readlink "$CONFIG_ROOT/config.json")" .json 2>/dev/null
}

# 切换到下一个/上一个
switch_config() {
  local direction="$1"
  local configs=($(ls_config))
  local current="$(current_config)"
  local index=-1

  for i in "${!configs[@]}"; do
    [[ "${configs[$i]}" == "$current" ]] && index=$i && break
  done

  [[ $index -eq -1 ]] && index=0

  local total=${#configs[@]}
  if [[ "$direction" == "next" ]]; then
    index=$(( (index + 1) % total ))
  elif [[ "$direction" == "prev" ]]; then
    index=$(( (index - 1 + total) % total ))
  fi

  set_config "${configs[$index]}"
}

# 输出严格 JSON 给 Waybar
output_json() {
  local current="$(current_config)"
  local ip_info=$(get_ip_info)
  local configs=$(ls_config | sed 's/"/\\"/g' | paste -sd ' ' -)
  local tooltip="${configs}\\n---\\n${ip_info}"
  if pidof -q sing-box; then
    current="󰮤 ${current}"
  else
    current="! ${current}"
  fi
  echo "{\"text\":\"$current\",\"tooltip\":\"$tooltip\"}"
}

main() {
  case "$1" in
    --next) switch_config next ;;
    --prev) switch_config prev ;;
    *) output_json ;;
  esac
}

main "$@"
