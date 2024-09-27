#!/usr/bin/env zsh

OPTIONS="s:r:l:i:q"
LONGOPTS="set:,random:,loop:,interval:,query,select:"
ARGS=`getopt -a --options=$OPTIONS --longoptions=$LONGOPTS --name "${0##*/}" -- "$@"`
if [[ $? -ne 0 || $# -eq 0 ]]; then
  cat <<- EOF
$0: -[`echo $OPTIONS|sed 's/,/|/g'`] --[`echo $LONGOPTS|sed 's/,/|/g'`]
EOF
fi
eval set -- "$ARGS"

# vars
FOCUSED_MONITOR=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')
INTERVAL=1800
DURATION=1
SCRIPT="$0"

wallpaper_from() {
  find "$1" -type f -iname "*.jpg" \
    -o -iname "*.jpeg" \
    -o -iname "*.png" \
    -o -iname "*.gif" | sort
}

wallpaper_set() {
  local wallpaper="$1"
  local FPS=60
  local TYPE="random"
  local BEZIER=".43,1.19,1,.4"
  if [[ -f "$wallpaper" ]]; then
    wallust_waybar "$wallpaper"
    swww img -o $FOCUSED_MONITOR "$wallpaper" \
      --transition-fps $FPS \
      --transition-type $TYPE \
      --transition-duration $DURATION
  fi
}

wallust_waybar() {
  wallust run "$1" -s
  sleep 0.3
  pidof waybar && killall -SIGUSR2 waybar
  sleep 0.2
}

wallpaper_loop() {
  local wallpaper_dir=$1
  while true; do
    wallpaper_from $wallpaper_dir | while read -r img; do
      echo "$((RANDOM % 1000)):$img"
    done | sort -n | cut -d':' -f2- | while read -r img; do
      wallpaper_set "$img"
      sleep $INTERVAL
    done
  done
}

wallpaper_select() {
  local wallpaper_dir=$1
  local preview="kitty icat --align center --clear --transfer-mode file {} 2>/dev/null"
  local window="top:70%:wrap"

  # set selected wallpaper
  wallpapers="$(wallpaper_from $wallpaper_dir)"
  selected="$(
    echo $wallpapers | \
      fzf --preview=$preview \
      --preview-window=$window \
      --bind "ctrl-r:reload(echo '$wallpapers' | shuf)"
  )"
  wallpaper_set "$selected"
}

while true; do
  case "$1" in
    -s|--set)
      wallpaper_set "$2"
      shift 2
      ;;
    -r|--random)
      current_wallpaper="$(swww query | cut -d ' ' -f 8-)"
      random="$(wallpaper_from $2 | grep -v "$current_wallpaper" | shuf -n 1)"
      wallpaper_set "$random"
      shift 2
      ;;
    -l|--loop)
      WALLPAPER_DIR="$2"
      shift 2
      ;;
    -i|--interval)
      INTERVAL="$2"
      shift 2
      ;;
    --select)
      wallpaper_select "$2"
      shift 2
      ;;
    -q|--query)
      shift
      ;;
    --) shift ; break ;;
    *)
      echo "Invalid option: $1"
      exit 1
      ;;
  esac
done

if [[ -n "$WALLPAPER_DIR" ]]; then
  wallpaper_loop "$WALLPAPER_DIR"
fi

