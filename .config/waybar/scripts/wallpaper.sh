#!/usr/bin/env zsh

# 启用 zsh 现代特性
emulate -L zsh
setopt extended_glob null_glob

# 脚本信息
readonly SCRIPT_NAME=${0:t}
readonly SCRIPT_DIR=${0:h}
readonly VERSION="1.0.0"

# 配置
typeset -A CONFIG=(
    [wallpaper_dir]="${HOME}/Pictures/wallpapers"
    [interval]="1800"
    [resolution]="3840"
    [user_agent]="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    [bing_api]="https://bing.biturl.top/?resolution=%s&format=json&index=random&mkt=random"
    [waybar_toggle_file]="${XDG_CACHE_HOME:-$HOME/.cache}/waybar/dark-light"
    [waybar_css_file]="$HOME/.config/waybar/colors.css"
)

# 支持的图片格式
readonly -a IMAGE_EXTS=(jpg jpeg png gif)

# 错误处理
error() { print -P "%F{red}ERROR:%f $*" >&2; exit 1 }
warn() { print -P "%F{yellow}WARN:%f $*" >&2 }
info() { print -P "%F{blue}INFO:%f $*" }

# 帮助信息
usage() {
    cat << EOF
${SCRIPT_NAME} ${VERSION} - 优雅的壁纸管理器

用法: ${SCRIPT_NAME} <命令> [选项]

命令:
    set <文件>              设置指定壁纸
    random [目录]           随机选择壁纸 (默认: ${CONFIG[wallpaper_dir]})
    loop [目录]             循环播放壁纸
    select [目录]           交互式选择壁纸
    download [源]           下载远程壁纸 (无参数时随机选择源)
    sources                 列出所有可用的壁纸源
    
选项:
    -i, --interval <秒>     循环间隔 (默认: ${CONFIG[interval]})
    -d, --dir <目录>        壁纸目录 (默认: ${CONFIG[wallpaper_dir]})
    -h, --help             显示帮助
    -v, --version          显示版本

示例:
    ${SCRIPT_NAME} set ~/wallpaper.jpg
    ${SCRIPT_NAME} random ~/wallpapers
    ${SCRIPT_NAME} loop -i 3600
    ${SCRIPT_NAME} download              # 随机选择源
    ${SCRIPT_NAME} download bing         # 指定源
    ${SCRIPT_NAME} sources               # 列出所有源
EOF
}

# 获取焦点显示器
get_focused_monitor() {
    hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}'
}

# 查找壁纸文件
find_wallpapers() {
  local dir=${1:-${CONFIG[wallpaper_dir]}}
  [[ -d $dir ]] || error "目录不存在: $dir"
  
  local -a patterns
  for ext in $IMAGE_EXTS; do
    # 大小写不敏感 ((#i))
    patterns+=($dir/**/*.$ext(#i))
  done
  
  print -l ${^patterns} | sort -u
}

# 设置壁纸
set_wallpaper() {
  local wallpaper=$1
  local monitor=$(get_focused_monitor)
  
  [[ -f $wallpaper ]] || error "文件不存在: $wallpaper"
  
  info "设置壁纸: ${wallpaper:t}"
  
  # 设置壁纸
  {
    hyprctl hyprpaper unload all
    hyprctl hyprpaper preload "$wallpaper"
    hyprctl hyprpaper wallpaper "$monitor,$wallpaper"
  } &>/dev/null
  
  # 更新颜色主题
  (( ${+commands[wallust]} )) && wallust run "$wallpaper" -s 2>/dev/null \
    || warn "wallust 命令未找到"

  # 颜色反转
  toggle=$(cat ${CONFIG[waybar_toggle_file]})
  (( $toggle )) && sed -i -e 's/foreground/__TMP__/g' -e 's/background/foreground/g' -e 's/__TMP__/background/g' ${CONFIG[waybar_css_file]}

  # 重新加载相关服务
  (( ${+commands[hyprctl]} )) && hyprctl reload &>/dev/null
}

# 随机选择壁纸
random_wallpaper() {
  local dir=${1:-${CONFIG[wallpaper_dir]}}
  # (f) 标志：按行分割
  local -a wallpapers=(${(f)"$(find_wallpapers $dir)"})
  
  (( ${#wallpapers} )) || error "没有找到壁纸文件"
  
  # 排除当前壁纸
  local current=$(hyprctl hyprpaper listactive | awk -F' = ' "/$(get_focused_monitor)/{print \$2}")
  if [[ -f $current ]]; then
    # 排除特定元素 (# 表示匹配并删除)
    wallpapers=(${wallpapers:#$current})
  fi
  
  local selected=${wallpapers[$RANDOM % ${#wallpapers} + 1]}
  set_wallpaper "$selected"
}

# 循环播放壁纸
loop_wallpapers() {
  local dir=${1:-${CONFIG[wallpaper_dir]}}
  local interval=${CONFIG[interval]}
  
  info "开始循环播放，间隔: ${interval}秒"
  
  while true; do
    local -a wallpapers=(${(f)"$(find_wallpapers $dir)"})
    
    for wallpaper in ${wallpapers[(r)$RANDOM]}; do
      set_wallpaper "$wallpaper"
      sleep $interval
    done
  done
}

# 交互式选择壁纸
select_wallpaper() {
  local dir=${1:-${CONFIG[wallpaper_dir]}}
  
  (( ${+commands[fzf]} )) || error "需要安装 fzf"
  
  local preview_cmd="kitty icat --align center --clear --transfer-mode file {} 2>/dev/null"
  local iname_str="${(j:' -o -iname '*.:)^IMAGE_EXTS/#/'*.}'"
  local find_cmd="find $dir -type f -iname $iname_str"
  local star_cmd='
    wname="${wallpaper##*/}"
    wpath="${wallpaper%/*}"
    if [[ "$wname" == \** ]]; then
      mv "${wallpaper}" "${wpath}/${wname#\*}"
    else
      mv "${wallpaper}" "${wpath}/*${wname}"
    fi
  '
  local selected
  
  selected=$(find_wallpapers $dir | shuf | fzf \
    --preview="$preview_cmd" \
    --preview-window="top:70%:wrap" \
    --bind="J:down,K:up" \
    --bind="ctrl-r:reload($find_cmd | shuf)" \
    --bind="D:reload(rm -rf {}; $find_cmd)" \
    --bind "L:reload(wallpaper={} && $star_cmd; $find_cmd)+change-query(*)"
    --header="D=Delete, Ctrl-r=Refresh"
  )
  
  [[ -n $selected ]] && set_wallpaper "$selected"
}

# 壁纸源配置
typeset -A WALLPAPER_SOURCES=(
  [bing]="download_bing"
  [unsplash]="download_unsplash"
  [pixabay]="download_pixabay"
  [pexels]="download_pexels"
  [wallhaven]="download_wallhaven"
)

# 下载 Bing 壁纸
download_bing() {
  local download_dir="${CONFIG[wallpaper_dir]}/bing"
  local api_url=$(printf ${CONFIG[bing_api]} ${CONFIG[resolution]})
  
  [[ -d $download_dir ]] || mkdir -p "$download_dir"
  
  info "正在下载 Bing 壁纸..."
  
  local resp=$(curl -sA "${CONFIG[user_agent]}" "$api_url")
  
  # 验证 JSON 响应
  if ! jq empty <<< "$resp" 2>/dev/null; then
    error "API 响应无效，请稍后重试"
  fi
  
  local url=$(jq -r .url <<< "$resp")
  local name=$(jq -r .copyright <<< "$resp")
  
  [[ $url == null || $name == null ]] && error "响应数据不完整"
  
  # 清理文件名
  # 替换所有匹配 (// 表示全局替换)
  name=${name//[^[:alnum:][:space:]._-]/_}
  name=${name%% \(*}
  
  local img_path="$download_dir/${name}.jpg"
  
  if [[ ! -f $img_path ]]; then
    wget -q "$url" -O "$img_path" || error "下载失败"
  fi
  
  info "下载完成: ${img_path:t}"
  notify-send "Bing 壁纸" "已下载: ${img_path:t}" 2>/dev/null
  
  set_wallpaper "$img_path"
}

# 下载 Unsplash 壁纸
download_unsplash() {
  local download_dir="${CONFIG[wallpaper_dir]}/unsplash"
  local api_url="https://source.unsplash.com/${CONFIG[resolution]}x$((CONFIG[resolution] * 9 / 16))/?nature,landscape"
  
  [[ -d $download_dir ]] || mkdir -p "$download_dir"
  
  info "正在下载 Unsplash 壁纸..."
  
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local img_path="$download_dir/unsplash_${timestamp}.jpg"
  
  if wget -q "$api_url" -O "$img_path"; then
    info "下载完成: ${img_path:t}"
    notify-send "Unsplash 壁纸" "已下载: ${img_path:t}" 2>/dev/null
    set_wallpaper "$img_path"
  else
    error "下载失败"
  fi
}

# 下载 Pixabay 壁纸
download_pixabay() {
  local download_dir="${CONFIG[wallpaper_dir]}/pixabay"
  
  [[ -d $download_dir ]] || mkdir -p "$download_dir"
  
  info "正在下载 Pixabay 壁纸..."
  
  # 需要 API key，这里只是示例
  warn "Pixabay 需要 API key，请在 CONFIG 中配置"
  
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local img_path="$download_dir/pixabay_${timestamp}.jpg"
  
  # 示例实现
  echo "https://pixabay.com/api/?key=YOUR_API_KEY&q=nature&image_type=photo&orientation=horizontal&min_width=${CONFIG[resolution]}"
}

# 下载 Pexels 壁纸
download_pexels() {
  local download_dir="${CONFIG[wallpaper_dir]}/pexels"
  
  [[ -d $download_dir ]] || mkdir -p "$download_dir"
  
  info "正在下载 Pexels 壁纸..."
  
  warn "Pexels 需要 API key，请在 CONFIG 中配置"
  
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local img_path="$download_dir/pexels_${timestamp}.jpg"
  
  # 示例实现
  echo "https://api.pexels.com/v1/search?query=nature&per_page=1&page=$((RANDOM % 100 + 1))"
}

# 下载 Wallhaven 壁纸
download_wallhaven() {
  local download_dir="${CONFIG[wallpaper_dir]}/wallhaven"
  local api_url="https://wallhaven.cc/api/v1/search?categories=100&purity=100&resolutions=${CONFIG[resolution]}x$((CONFIG[resolution] * 9 / 16))&sorting=random"
  
  [[ -d $download_dir ]] || mkdir -p "$download_dir"
  
  info "正在下载 Wallhaven 壁纸..."
  
  local resp=$(curl -sA "${CONFIG[user_agent]}" "$api_url")
  
  if ! jq empty <<< "$resp" 2>/dev/null; then
    error "API 响应无效，请稍后重试"
  fi
  
  local url=$(jq -r '.data[0].path' <<< "$resp")
  local id=$(jq -r '.data[0].id' <<< "$resp")
  
  [[ $url == null || $id == null ]] && error "响应数据不完整"
  
  local img_path="$download_dir/wallhaven_${id}.jpg"
  
  if [[ ! -f $img_path ]]; then
    wget -q "$url" -O "$img_path" || error "下载失败"
  fi
  
  info "下载完成: ${img_path:t}"
  notify-send "Wallhaven 壁纸" "已下载: ${img_path:t}" 2>/dev/null
  
  set_wallpaper "$img_path"
}

# 随机选择壁纸源
random_source() {
  local -a sources=(${(k)WALLPAPER_SOURCES})
  local selected=${sources[$RANDOM % ${#sources} + 1]}
  
  info "随机选择源: $selected"
  ${WALLPAPER_SOURCES[$selected]}
}

# 列出所有可用源
list_sources() {
  print -P "%F{cyan}可用的壁纸源:%f"
  for source in ${(k)WALLPAPER_SOURCES}; do
    print "  • $source"
  done
}

# 主函数
main() {
  # 创建壁纸目录
  [[ -d ${CONFIG[wallpaper_dir]} ]] || mkdir -p "${CONFIG[wallpaper_dir]}"
  
  # 解析全局选项
  local -A opts
  zparseopts -D -A opts \
    i:=interval -interval:=interval \
    d:=dir -dir:=dir \
    h=help -help=help \
    v=version -version=version
  
  # 处理全局选项
  [[ -n ${opts[-h]} || -n ${opts[--help]} ]] && { usage; exit 0 }
  [[ -n ${opts[-v]} || -n ${opts[--version]} ]] && { echo $VERSION; exit 0 }
  
  # 更新配置
  [[ -n ${opts[-i]} ]] && CONFIG[interval]=${opts[-i]}
  [[ -n ${opts[--interval]} ]] && CONFIG[interval]=${opts[--interval]}
  [[ -n ${opts[-d]} ]] && CONFIG[wallpaper_dir]=${opts[-d]}
  [[ -n ${opts[--dir]} ]] && CONFIG[wallpaper_dir]=${opts[--dir]}
  
  # 处理命令
  case ${1:-help} in
    set)
      [[ -n $2 ]] || error "请指定壁纸文件"
      set_wallpaper "$2"
      ;;
    random|rand)
      random_wallpaper "$2"
      ;;
    loop)
      loop_wallpapers "$2"
      ;;
    select|choose)
      select_wallpaper "$2"
      ;;
    download|dl)
      if [[ -n $2 ]]; then
        # 指定源
        if [[ -n ${WALLPAPER_SOURCES[$2]} ]]; then
            ${WALLPAPER_SOURCES[$2]}
        else
            error "不支持的源: $2\n可用源: ${(k)WALLPAPER_SOURCES}"
        fi
      else
        # 随机选择源
        random_source
      fi
      ;;
    sources|list)
      list_sources
      ;;
    help|--help|-h)
      usage
      ;;
    *)
      error "未知命令: $1\n$(usage)"
      ;;
  esac
}

# 运行主函数
main "$@"
