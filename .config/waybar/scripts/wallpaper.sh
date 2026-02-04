#!/usr/bin/env bash

SCRIPT_NAME=$(basename "$0")
VERSION="1.0.0"

##############
### config ###
##############

declare -A CONFIG=(
    [wallpaper_dir]="${HOME}/Pictures/wallpapers"
    [interval]="1800"
    [resolution]="3840"
    [user_agent]="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    [bing_api]="https://bing.biturl.top/?resolution=%s&format=json&index=random&mkt=random"
    [waybar_css_file]="$HOME/.config/waybar/colors.css"
)

declare -A WALLPAPER_SOURCES=(
  [bing]="download_bing"
  [unsplash]="download_unsplash"
  [pixabay]="download_pixabay"
  [pexels]="download_pexels"
  [wallhaven]="download_wallhaven"
)

[[ -d ${CONFIG[wallpaper_dir]} ]] || mkdir -p "${CONFIG[wallpaper_dir]}"

usage() {
  cat << EOF
Usage: ${SCRIPT_NAME} <command> [options]

commands:
    set <wallpaper path>    set wallpaper
    random [wallpaper dir]  set a random wallpaper (default: ${CONFIG[wallpaper_dir]})
    loop [wallpaper dir]    loop wallpapers
    select [wallpaper dir]  select wallpaper interactively
    download [source]       download wallpaper from a source
    sources                 list available sources
    
options:
    -i, --interval <sec>    loop interval (default: ${CONFIG[interval]})
    -d, --dir <dir>         wallpaper directory (default: ${CONFIG[wallpaper_dir]})
    -h, --help              show help
    -v, --version           show version
EOF
}

############
### main ###
############

error() { echo -e "\e[31mERROR:\e[0m $*" >&2; exit 1; }
warn()  { echo -e "\e[33mWARN:\e[0m $*" >&2; }
info()  { echo -e "\e[34mINFO:\e[0m $*"; }

get_focused_monitor() {
  hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}'
}

toggle_foreground() {
  sed -i -e 's/foreground/__TMP__/g' -e 's/background/foreground/g' -e 's/__TMP__/background/g' "${CONFIG[waybar_css_file]}"
}

check_top_color() {
  local wallpaper="$1"
  if ! command -v identify >/dev/null; then
    warn "imagemagick not installed"
    echo 0
    return
  fi
  local width=$(identify -format "%w" "$wallpaper")
  local start_x=$((width / 4))
  local crop_width=$((width / 2))
  local crop_area="${crop_width}x100+${start_x}+0"

  local pixels=$(convert "$wallpaper" -crop "$crop_area" +repage -colorspace Gray -resize 200x100 -depth 8 txt:- |
    grep -o "gray([0-9]*)" | grep -o "[0-9]*")

  local total=$(echo "$pixels" | wc -l)
  local bright=$(echo "$pixels" | awk '$1 > 127' | wc -l)

  echo $((bright * 100 / total))
}

find_wallpapers() {
  local dir=${1:-${CONFIG[wallpaper_dir]}}
  [[ -d $dir ]] || error "Directory not found: $dir"
  find "$dir" -type f -regex '.*\.\(jpg\|jpeg\|png\)$' | sort -u
}

set_wallpaper() {
  local wallpaper=$1
  local monitor=$(get_focused_monitor)
  [[ -f $wallpaper ]] || error "File not found: $wallpaper"

  info "Setting wallpaper: ${wallpaper##*/}"

  local loaded=$(hyprctl hyprpaper listloaded | wc -l)
  {
    [[ $loaded -gt 100 ]] && hyprctl hyprpaper unload all
    hyprctl hyprpaper preload "$wallpaper"
    hyprctl hyprpaper wallpaper "$monitor,$wallpaper"
  } &>/dev/null

  if command -v wallust >/dev/null; then
    wallust run "$wallpaper" -s || warn "wallust failed"
  else
    warn "wallust not found"
  fi

  local percent=$(check_top_color "$wallpaper")
  [[ $percent -gt 50 ]] && toggle_foreground

  command -v makoctl >/dev/null && makoctl reload &>/dev/null
  command -v hyprctl >/dev/null && hyprctl reload &>/dev/null
  notify-send "$wallpaper"
}

random_wallpaper() {
  local dir=${1:-${CONFIG[wallpaper_dir]}}
  mapfile -t wallpapers < <(find_wallpapers "$dir")
  [[ ${#wallpapers[@]} -gt 0 ]] || error "No wallpapers found"

  local current=$(hyprctl hyprpaper listactive | awk -F' = ' "/$(get_focused_monitor)/{print \$2}")

  # 只在有多张壁纸时排除当前壁纸
  if [[ -f $current && ${#wallpapers[@]} -gt 1 ]]; then
    local tmp=()
    for w in "${wallpapers[@]}"; do
      [[ $w != "$current" ]] && tmp+=("$w")
    done
    wallpapers=("${tmp[@]}")
  fi

  local idx=$((RANDOM % ${#wallpapers[@]}))
  local candidate="${wallpapers[$idx]}"
  [[ -n $candidate && -f $candidate ]] || error "Invalid random wallpaper"
  set_wallpaper "$candidate"
}

loop_wallpapers() {
  local dir=${1:-${CONFIG[wallpaper_dir]}}
  local interval=${CONFIG[interval]}
  info "Start looping wallpapers every ${interval}s"

  while true; do
    mapfile -t wallpapers < <(find_wallpapers "$dir")
    for wallpaper in "${wallpapers[@]}"; do
      set_wallpaper "$wallpaper"
      sleep "$interval"
    done
  done
}

select_wallpaper() {
  local dir=${1:-${CONFIG[wallpaper_dir]}}
  command -v fzf >/dev/null || error "fzf required"
  local selected=$(find_wallpapers "$dir" | shuf | fzf --preview="kitty icat {}")
  [[ -n $selected ]] && set_wallpaper "$selected"
}

# TODO: 下载函数们保留不变 (bing, unsplash, wallhaven …)，只改用 bash 风格

random_source() {
  local sources=("${!WALLPAPER_SOURCES[@]}")
  local idx=$((RANDOM % ${#sources[@]}))
  local selected=${sources[$idx]}
  info "Random source: $selected"
  ${WALLPAPER_SOURCES[$selected]}
}

list_sources() {
  echo -e "\e[36mAvailable sources:\e[0m"
  for s in "${!WALLPAPER_SOURCES[@]}"; do
    echo "  • $s"
  done
}

main() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -i|--interval) CONFIG[interval]=$2; shift 2 ;;
      -d|--dir) CONFIG[wallpaper_dir]=$2; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      -v|--version) echo "$VERSION"; exit 0 ;;
      *) break ;;
    esac
  done
  
  case ${1:-help} in
    set) [[ -n $2 ]] || error "Please specify file"; set_wallpaper "$2" ;;
    random|rand) random_wallpaper "$2" ;;
    loop) loop_wallpapers "$2" ;;
    select|choose) select_wallpaper "$2" ;;
    download|dl)
      if [[ -n $2 ]]; then
        if [[ -n ${WALLPAPER_SOURCES[$1]} ]]; then
          ${WALLPAPER_SOURCES[$1]}
        else
          error "Unsupported source: $1"
        fi
      else
        random_source
      fi
      ;;
    sources|list) list_sources ;;
    help) usage ;;
    *) error "Unknown command: $1" ;;
  esac
}

# waiting hyprpaper IPC ready
while ! pgrep -x hyprpaper &>/dev/null; do
  sleep 0.1
done
sleep 0.1

main "$@"
