#!/usr//bin/env zsh

# settings
WALLPAPER_DIR="$HOME/Pictures/wallpaper"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"
MONITOR="$(hyprctl monitors|grep 'ID 0'|awk '{print $2}')"
HYPRLAND_INSTANCE_SIGNATURE="$(ls /tmp/hypr/*.lock|tail -n 1|awk -F '/' '{print $4}'|sed 's|.lock||')"

pgrep hyprpaper &>/dev/null || {hyprctl dispatch exec hyprpaper && sleep 1}

load_wallpaper() {
  local wallpaper="${1##*/}"

  if [[ -n "$wallpaper" ]]; then
    load_status="$(hyprctl hyprpaper preload "$WALLPAPER_DIR/$wallpaper")"
    if [[ $load_status == "ok" ]]; then
      notify-send "${wallpaper%.*}"
      hyprctl hyprpaper wallpaper "$MONITOR,$WALLPAPER_DIR/$wallpaper"
    else
      notify-send "Load $wallpaper faield: $load_status"
    fi
    hyprctl hyprpaper unload unused
  else
    notify-send "No wallpaper found"
  fi
}

switch_wallpaper() {
  local action=$1
  local wallpaper
  local prev_wallpaper
  local next_wallpaper
  local current_wallpaper

  current_wallpaper="$(hyprctl hyprpaper listactive | grep -v 'no wallpapers' | sed 's|.*/||' | head -n 1)"

  ls -1v $WALLPAPER_DIR | while read -r file; do
    [[ -n "$next_wallpaper" ]] && next_wallpaper="$file" && break
    if [[ "$file" == "$current_wallpaper" ]]; then
      next_wallpaper="$file"
    else
      prev_wallpaper="$file"
    fi
  done

  if [[ $action == "next" ]]; then
    if [[ "$next_wallpaper" == "$current_wallpaper" ]]; then
      wallpaper="$(ls -1v $WALLPAPER_DIR | head -n 1)"
    else
      wallpaper=$next_wallpaper
    fi
  elif [[ $action == "prev" ]]; then
    if [[ -z "$prev_wallpaper" ]]; then
      wallpaper="$(ls -1v $WALLPAPER_DIR | tail -n 1)"
    else
      wallpaper=$prev_wallpaper
    fi
  else
    notify-send "Invalid action: $action" && exit 1
  fi

  load_wallpaper "$wallpaper"
}

cycle_wallpaper() {
  while true; do
    find "$WALLPAPER_DIR" -type f | while read -r img; do
        echo "$((RANDOM % 1000)):$img"
    done | sort -n | cut -d':' -f2- | while read -r img; do
      sleep ${INTERVAL:-1800} && load_wallpaper "$WALLPAPER_DIR/$img"
    done
  done
}

# ###  Main  ##################################################################

SHORT="r,s:,c,i:"
LONG="random,switch:,set:,cycle,interval:"
ARGS=`getopt -a -o $SHORT -l $LONG -n "${0##*/}" -- "$@"`

if [[ $? -ne 0 || $# -eq 0 ]]; then
  cat <<- EOF

$0 -[`echo $SHORT|sed 's/,/|/g'`] --[`echo $LONG|sed 's/,/|/g'`]
EOF
fi

eval set -- "${ARGS}"

while true; do
  case "$1" in
    -c|--cycle) cycle_wallpaper ;;
    -r|--random) load_wallpaper "$(shuf -n 1 -e $WALLPAPER_DIR/*)" ;;

    -i|--interval) INTERVAL=$2; shift ;;
    -s|--switch) switch_wallpaper $2; shift ;;
    --set) load_wallpaper "$2"; shift ;;

    --) shift ; break ;;
  esac
  shift
done

