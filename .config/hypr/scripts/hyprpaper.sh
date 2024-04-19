#!/usr//bin/env zsh

WALLPAPER_DIR="$HOME/Pictures/wallpaper"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"
MONITOR="$(hyprctl monitors|grep 'ID 0'|awk '{print $2}')"

load_wallpaper() {
  local wallpaper="${1##*/}"
  if [[ -n "$wallpaper" ]]; then
    load_status="$(hyprctl hyprpaper preload "$WALLPAPER_DIR/$wallpaper")"
    if [[ $load_status == "ok" ]]; then
      notify-send "${wallpaper%.*}"
      hyprctl hyprpaper wallpaper "$MONITOR,$WALLPAPER_DIR/$wallpaper"
    else
      notify-send "Load $wallpaper faield: $load_status" && exit 1
    fi
    hyprctl hyprpaper unload unused
  else
    notify-send "No wallpaper found" && exit 1
  fi
}

switch_wallpaper() {
  local action=$1
  local wallpaper
  local prev_wallpaper
  local next_wallpaper

  current_wallpaper="$(hyprctl hyprpaper listactive | sed 's|.*/||')"

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

# ###  Main  ##################################################################

SHORT="r,s:"
LONG="random,switch:,set:"
ARGS=`getopt -a -o $SHORT -l $LONG -n "${0##*/}" -- "$@"`

if [[ $? -ne 0 || $# -eq 0 ]]; then
  cat <<- EOF

$0 -[`echo $SHORT|sed 's/,/|/g'`] --[`echo $LONG|sed 's/,/|/g'`]
EOF
fi

eval set -- "${ARGS}"

while true
do
  case "$1" in
  -r|--random) load_wallpaper "$(shuf -n 1 -e $WALLPAPER_DIR/*)" ;;
  -s|--switch) switch_wallpaper $2; shift ;;

  --set) load_wallpaper "$2"; shift ;;
  --) shift ; break ;;
  esac
shift
done

