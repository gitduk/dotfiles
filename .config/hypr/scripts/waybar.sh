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

style_set() {
  local style_dir=$1
  local preview="cat $style_dir/{}"
  local window="right:60%:wrap"
  local link="$2"

  # select waybar style use fzf
  find_command $style_dir | fzf \
    --preview=$preview \
    --preview-window=$window \
    --bind "Y:execute(ln -sf $style_dir/{} $link && pidof waybar &>/dev/null && pkill waybar && nohup waybar &>/dev/null &)" \
    --bind "enter:execute(ln -sf $style_dir/{} $link && pidof waybar &>/dev/null && pkill waybar && nohup waybar &>/dev/null &)+abort"
}

while true; do
  case "$1" in
    -l|--layer)
      style_set "$2" "$WAYBAR_CONFIG"
      shift 2
      ;;
    -s|--style)
      style_set "$2" "$WAYBAR_STYLE"
      shift 2
      ;;
    --) shift ; break ;;
    *)
      echo "Invalid option: $1"
      exit 1
      ;;
  esac
done

