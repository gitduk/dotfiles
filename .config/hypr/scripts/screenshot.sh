#!/usr/bin/env zsh

# Short options and long options
SHORT_OPTS="aAwns"
LONG_OPTS="area,active,window,now,swappy"

if ! hash grim &>/dev/null; then
  notify-send "Screenshot" "grim command not found"
fi

if ! hash slurp &>/dev/null; then
  notify-send "Screenshot" "slurp command not found"
fi

# Parse the command-line arguments
ARGS=$(getopt -a --options=$SHORT_OPTS --longoptions=$LONG_OPTS --name "${0##*/}" -- "$@")

# Check if getopt failed or if no arguments were provided
if [[ $? -ne 0 || $# -eq 0 ]]; then
  echo "Usage: $0 [-$SHORT_OPTS] [--$LONG_OPTS]"
  exit 1
fi

# Set the parsed arguments
eval set -- "$ARGS"

# Screenshots scripts
time=$(date "+%d-%b_%H-%M-%S")
save_dir="$HOME/Pictures/Screenshots"
file="screenshot_${time}_${RANDOM}.png"

active_window_class=$(hyprctl -j activewindow | jq -r '(.class)')
active_window_file="Screenshot_${time}_${active_window_class}.png"
active_window_path="${save_dir}/${active_window_file}"

# countdown
countdown() {
  for sec in $(seq $1 -1 1); do
    notify-send "Taking shot in : ${sec}s"
    sleep 1
  done
}

# take shots
shotnow() {
  grim - | tee "$save_dir/$file" | wl-copy && notify-send "$file"
}

_shotdelay() {
  countdown "$1"
  grim - | tee "$save_dir/$file" | wl-copy && notify-send "$file"
}

shotarea() {
  grim -g "$(slurp)" - | tee "$save_dir/$file" | wl-copy && notify-send "$file"
}

shotactive() {
  hyprctl -j activewindow | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | \
    grim -g - - | tee "${active_window_path}" | wl-copy && \
    notify-send "$active_window_file"
}

shotswappy() {
  grim -g "$(slurp)" - | swappy -f -
}

# ensure save dir
[[ ! -d "$save_dir" ]] && mkdir -p $save_dir

while true; do
  case "$1" in
    -n|--now)
      shotnow
      ;;
    -a|--area)
      shotarea
      ;;
    -A|--active)
      shotactive
      ;;
    -s|--swappy)
      shotswappy
      ;;
    --)
      shift
      break
      ;;
    *)
      exit 1
      ;;
  esac
  shift
done

