#!/usr/bin/env zsh

OPTIONS="s:r:l:i:q"
LONGOPTS="set:,random:,loop:,interval:,query,select:,remote:"
ARGS=$(getopt -a --options=$OPTIONS --longoptions=$LONGOPTS --name "${0##*/}" -- "$@")
if [[ $? -ne 0 || $# -eq 0 ]]; then
  cat <<-EOF
$0: -[$(echo $OPTIONS | sed 's/,/|/g')] --[$(echo $LONGOPTS | sed 's/,/|/g')]
EOF
fi
eval set -- "$ARGS"

# vars
FOCUSED_MONITOR=$(hyprctl monitors | awk '/^Monitor/{name=$2} /focused: yes/{print name}')
INTERVAL=1800
SCRIPT="$0"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
[[ -d "$WALLPAPER_DIR" ]] || mkdir -p "$WALLPAPER_DIR"
wallust_cmd="$HOME/.cargo/bin/wallust"

wallpaper_from() {
  find "$1" -type f -iname "*.jpg" \
    -o -iname "*.jpeg" \
    -o -iname "*.png" \
    -o -iname "*.gif" | sort
}

wallpaper_set() {
  local wallpaper="$1"
  if [[ -f "$wallpaper" ]]; then
    # set wallpaper
    hyprctl hyprpaper unload all &>/dev/null
    hyprctl hyprpaper preload "$wallpaper" &>/dev/null
    hyprctl hyprpaper wallpaper "$FOCUSED_MONITOR,$wallpaper" &>/dev/null

    # general colors
    ${wallust_cmd:-wallust} run "$wallpaper" -s 2>/dev/null

    # reload waybar
    pidof waybar &>/dev/null && killall -SIGUSR2 waybar

    # reload hyprland
    hyprctl reload &>/dev/null
  fi
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
  find_cmd="find $wallpaper_dir -type f -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif'"
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
    wallpaper_from $wallpaper_dir | shuf |
      fzf --preview=$preview \
        --preview-window=$window \
        --bind "J:down,K:up" \
        --bind "ctrl-r:reload($find_cmd | shuf)" \
        --bind "D:reload(rm -rf {}; $find_cmd)" \
        --bind "L:reload(wallpaper={} && $star_cmd; $find_cmd)+change-query(*)"
  )"
  wallpaper_set "$selected"
}

bing() {
  # 1366 1920 3840
  local resolution=3840
  local download_dir="$WALLPAPER_DIR/bing"
  local agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

  [[ ! -d "$download_dir" ]] && mkdir -p "$download_dir"

  # Perform the curl request and store the response
  resp=$(curl -A "$agent" "https://bing.biturl.top/?resolution=$resolution&format=json&index=random&mkt=random")

  # Check if the response is valid JSON
  if ! echo "$resp" | jq empty 2>/dev/null; then
    echo "Error: Invalid JSON response received. Please try again later."
    return 1
  fi

  # Extract URL and copyright
  url=$(jq .url <<<$resp)
  name=$(jq .copyright <<<$resp)

  # Handle cases where URL or copyright might be missing
  if [[ -z "$url" || -z "$name" ]]; then
    echo "Error: Missing data in response."
    return 1
  fi

  # Clean up the name for the file (remove leading/trailing quotes, everything after the first '(' and any trailing commas)
  name=$(echo "$name" | sed -e 's/^"\(.*\)"$/\1/' -e 's/(\(.*\))//g' -e 's/,.*//')

  # Download the image if it doesn't already exist
  img_path="$download_dir/$name.jpg"
  if [[ ! -e "$img_path" ]]; then
    wget "${url//\"/}" -O "$download_dir/$name.jpg"
  fi

  echo $img_path
}

while true; do
  case "$1" in
  -s | --set)
    wallpaper_set "$2"
    shift
    ;;
  -r | --random)
    listactive="$(hyprctl hyprpaper listactive)"
    current_wallpaper="$(echo -n "$listactive" | awk -F' = ' "/$FOCUSED_MONITOR/{print \$2}")"
    if [[ -f "$current_wallpaper" ]]; then
      random="$(wallpaper_from $2 | grep -v "$current_wallpaper" | shuf -n 1)"
    else
      random="$(wallpaper_from $2 | shuf -n 1)"
    fi
    wallpaper_set "$random"
    shift
    ;;
  -l | --loop)
    wallpaper_loop "$2"
    shift
    ;;
  -i | --interval)
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
  -q | --query) ;;
  --)
    shift
    break
    ;;
  *)
    echo "Invalid option: $1"
    exit 1
    ;;
  esac
  shift
done
