#!/usr/bin/env zsh

OPTIONS="l:s:"
LONGOPTS="layer:,style:"
ARGS=`getopt -a --options=$OPTIONS --longoptions=$LONGOPTS --name "${0##*/}" -- "$@"`
if [[ $? -ne 0 || $# -eq 0 ]]; then
  cat <<- EOF
$0: -[`echo $OPTIONS|sed 's/,/|/g'`] --[`echo $LONGOPTS|sed 's/,/|/g'`]
EOF
fi
eval set -- "$ARGS"

# vars
WAYBAR_CONFIG="$HOME/.config/waybar/config"
WAYBAR_STYLE="$HOME/.config/waybar/style.css"

find_command() {
  find "$1" -maxdepth 1 -type f -exec basename {} \; | sort
}

ln_command() {
  local source_file="$1"
  local link_file="$2"
  [[ ! -f "$source_file" ]] && exit 0
  echo "$source_file"
  ln -sf "$source_file" "$link_file"
}

layer_set() {
  local layer_dir=$1
  local preview="cat $layer_dir/{}"
  local window="right:60%:wrap"

  # select waybar layer use fzf
  selected="$(find_command $layer_dir | fzf --preview=$preview --preview-window=$window)"
  ln_command "$layer_dir/$selected" "$WAYBAR_CONFIG"

  # reload waybar config
  if pidof waybar &>/dev/null; then
    killall -SIGUSR2 waybar
  else
    nohup waybar &>/dev/null &
    sleep 0.5
  fi
}

style_set() {
  local style_dir=$1
  local preview="cat $style_dir/{}"
  local window="right:60%:wrap"

  # select waybar style use fzf
  selected="$(find_command $style_dir | fzf --preview=$preview --preview-window=$window)"
  ln_command "$style_dir/$selected" "$WAYBAR_STYLE"

  # restart waybar
  pidof waybar &>/dev/null && pkill waybar
  nohup waybar &>/dev/null &
  sleep 0.5
}

while true; do
  case "$1" in
    -l|--layer)
      layer_set "$2"
      shift 2
      ;;
    -s|--style)
      style_set "$2"
      shift 2
      ;;
    --) shift ; break ;;
    *)
      echo "Invalid option: $1"
      exit 1
      ;;
  esac
done

