#!/usr//bin/env zsh

WALLPAPER_DIR="$HOME/Pictures/wallpaper"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"
MONITOR="$(hyprctl monitors|grep 'ID 0'|awk '{print $2}')"

init_config() {
  local monitor=$MONITOR

  # preload wallpaper
  ls $WALLPAPER_DIR | while read -r file; do
    echo "preload = $WALLPAPER_DIR/$file"
  done | tee $HYPRPAPER_CONF

  # set wallpaper
  echo "wallpaper = $monitor,$(shuf -n 1 -e $WALLPAPER_DIR/*)" | tee -a $HYPRPAPER_CONF

  # ipc options
  echo "ipc = on" | tee -a $HYPRPAPER_CONF
}

random_wallpaper() {
  local monitor=$MONITOR
  local wallpaper="$(shuf -n 1 -e $WALLPAPER_DIR/*)"
  notify-send "${wallpaper##*/}"
  hyprctl hyprpaper wallpaper "$monitor,$wallpaper"
}

switch_wallpaper() {
  local monitor=$MONITOR
  local action=$1
  local wallpaper
  local prev_wallpaper
  local next_wallpaper

  current_wallpaper="$(hyprctl hyprpaper listactive | sed 's|.*/||')"
  echo "Currnet: $current_wallpaper"

  ls -1v $WALLPAPER_DIR | while read -r file; do
    [[ -n "$next_wallpaper" ]] && next_wallpaper="$file" && break
    if [[ "$file" == "$current_wallpaper" ]]; then
      next_wallpaper="$file"
    else
      prev_wallpaper="$file"
    fi
  done

  echo "Next: $next_wallpaper"
  echo "Prev: $prev_wallpaper"

  if [[ $action == "next" ]]; then
    [[ -n "$next_wallpaper" ]] && wallpaper=$next_wallpaper
  elif [[ $action == "prev" ]]; then
    [[ -n "$prev_wallpaper" ]] && wallpaper=$prev_wallpaper
  else
    echo "Invalid action" && exit 1
  fi

  if [[ -n "$wallpaper" ]]; then
    notify-send "$wallpaper"
    hyprctl hyprpaper wallpaper "$monitor,$WALLPAPER_DIR/$wallpaper"
  else
    notify-send "No wallpaper found"
  fi
}

# ###  Main  ##################################################################

SHORT="i,r,s:"
LONG="init,random,switch:"
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
  -i|--init) init_config ;;
  -r|--random) random_wallpaper ;;
  -s|--switch) switch_wallpaper $2; shift ;;
  --) shift ; break ;;
  esac
shift
done

