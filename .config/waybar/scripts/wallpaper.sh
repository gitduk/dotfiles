#!/usr/bin/env bash

SCRIPT_NAME=$(basename "$0")
VERSION="1.0.0"

##############
### config ###
##############

declare -A CONFIG=(
    [wallpaper_dir]="${HOME}/Pictures/wallpapers"
    [interval]="1800"
    [waybar_css_file]="$HOME/.config/waybar/colors.css"
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
  local file="${1:-${CONFIG[waybar_css_file]}}"
  sed -i -e 's/foreground/__TMP__/g' -e 's/background/foreground/g' -e 's/__TMP__/background/g' "$file"
}

check_top_color() {
  local wallpaper="$1"

  if ! command -v identify >/dev/null; then
    echo 50; return
  fi

  local width
  width=$(identify -format "%w" "$wallpaper" 2>/dev/null) || { echo 50; return; }

  local start_x=$((width / 4))
  local crop_width=$((width / 2))
  local crop_area="${crop_width}x100+${start_x}+0"
  convert "$wallpaper" -crop "$crop_area" +repage -alpha off -colorspace Gray -resize 200x100 -depth 8 txt:- 2>/dev/null |
    awk -F'[()]' '/gray\(/ { total++; val=int($2); if (val > 127) bright++ }
      END { if (total > 0) printf "%d", bright * 100 / total; else print 50 }'
}

find_wallpapers() {
  local dir=${1:-${CONFIG[wallpaper_dir]}}
  [[ -d $dir ]] || error "Directory not found: $dir"
  find "$dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | sort -u
}

set_wallpaper() {
  local wallpaper=$1
  local monitor=$(get_focused_monitor)
  [[ -f $wallpaper ]] || error "File not found: $wallpaper"

  info "Setting wallpaper: ${wallpaper##*/}"
  hyprctl hyprpaper wallpaper "$monitor,$wallpaper" &>/dev/null

  if ! command -v wallust >/dev/null; then
    warn "wallust not found"; return
  fi

  # check_top_color 和 wallust 并行
  local css="${CONFIG[waybar_css_file]}"
  local percent_file=$(mktemp)
  check_top_color "$wallpaper" > "$percent_file" &
  local check_pid=$!
  wallust run "$wallpaper" -s || warn "wallust failed"
  wait "$check_pid"
  local percent=$(<"$percent_file")
  rm -f "$percent_file"
  [[ $percent -gt 45 ]] && toggle_foreground "${css}.tmp"
  mv -f "${css}.tmp" "$css"

  if command -v makoctl >/dev/null; then
    makoctl reload &>/dev/null
    makoctl dismiss -a
  fi
  notify-send "${wallpaper##*/}"
}

random_wallpaper() {
  local dir=${1:-${CONFIG[wallpaper_dir]}}
  mapfile -t wallpapers < <(find_wallpapers "$dir")
  [[ ${#wallpapers[@]} -gt 0 ]] || error "No wallpapers found"
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
    help) usage ;;
    *) error "Unknown command: $1" ;;
  esac
}

# waiting hyprpaper IPC ready
while ! pgrep -x hyprpaper &>/dev/null; do
  sleep 0.1
done

main "$@"
