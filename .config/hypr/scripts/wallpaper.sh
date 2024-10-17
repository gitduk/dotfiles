#!/usr/bin/env zsh

OPTIONS="s:r:l:i:q"
LONGOPTS="set:,random:,loop:,interval:,query,select:,remote:"
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
SCRIPT="$0"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

wallpaper_from() {
  find "$1" -type f -iname "*.jpg" \
    -o -iname "*.jpeg" \
    -o -iname "*.png" \
    -o -iname "*.gif" | sort
}

wallpaper_set() {
  local wallpaper="$1"
  if [[ -f "$wallpaper" ]]; then
    wallust_waybar "$wallpaper"
    hyprctl hyprpaper unload all &>/dev/null
    hyprctl hyprpaper preload "$wallpaper" &>/dev/null
    hyprctl hyprpaper wallpaper "$FOCUSED_MONITOR,$wallpaper" &>/dev/null
  fi
}

wallust_waybar() {
  wallust run "$1" -s 2>/dev/null
  sleep 0.3
  pidof waybar &>/dev/null && killall -SIGUSR2 waybar
  pidof hyprpaper &>/dev/null || nohup hyprpaper > /dev/null 2>&1 &
  disown
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
  find_cmd="find $wallpaper_dir -type f -iname '*.' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif'"
  star_cmd='
    wname="${wallpaper##*/}"
    wpath="${wallpaper%/*}"
    if [[ "$wname" == \** ]]; then
      mv "${wallpaper}" "${wpath}/${wname#\*}"
    else
      mv "${wallpaper}" "${wpath}/*${wname}"
    fi
  '
  selected="$(
    echo $wallpapers | shuf | \
      fzf --preview=$preview \
      --preview-window=$window \
      --bind "ctrl-r:reload(echo '$wallpapers' | shuf)" \
      --bind "D:reload(rm -rf {}; $find_cmd)" \
      --bind "L:reload(wallpaper={} && $star_cmd; $find_cmd)+change-query(*)"
  )"
  wallpaper_set "$selected"
}

bing() {
  # 1366 1920 3840
  local resolution=3840
  local download_dir="$WALLPAPER_DIR/bing"
  [[ ! -d "$download_dir" ]] && mkdir -p "$download_dir"
  resp=$(curl "https://bing.biturl.top/?resolution=$resolution&format=json&index=random&mkt=random")
  url=$(jq .url <<< $resp)
  name=$(jq .copyright <<< $resp)
  name=${name//\"/}
  name=${name%%\(*}
  name=${name%%,*}
  name="$(echo $name)"
  img_path="$download_dir/$name.jpg"
  if [[ ! -e "$img_path" ]]; then
    aria2c ${url//\"/} -d "$download_dir" -o "$name.jpg" &>/dev/null
  fi
  echo $img_path
}

while true; do
  case "$1" in
    -s|--set)
      wallpaper_set "$2"
      shift
      ;;
    -r|--random)
      listactive="$(hyprctl hyprpaper listactive)"
      if [[ ! "$listactive" == "no wallpapers active" ]]; then
        current_wallpaper="$(echo -n "$listactive" | awk -F' = ' "/$FOCUSED_MONITOR/{print \$2}")"
        random="$(wallpaper_from $2 | grep -v "$current_wallpaper" | shuf -n 1)"
      else
        random="$(wallpaper_from $2 | shuf -n 1)"
      fi
      wallpaper_set "$random"
      shift
      ;;
    -l|--loop)
      wallpaper_loop "$2"
      shift
      ;;
    -i|--interval)
      INTERVAL="$2"
      shift
      ;;
    --select)
      wallpaper_select "$2"
      shift
      ;;
    --remote)
      case "$2" in
        bing) wallpaper="$(bing)" ;;
        *) wallpaper="$(bing)" ;;
      esac
      notify-send "$2" "$wallpaper"
      wallpaper_set "$wallpaper"
      shift
      ;;
    -q|--query) ;;
    --) shift; break ;;
    *)
      echo "Invalid option: $1"
      exit 1
      ;;
  esac
  shift
done

