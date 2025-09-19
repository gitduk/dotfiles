#!/usr/bin/env bash

SCRIPT_NAME=$(basename "$0")
VERSION="1.0.0"

##############
### config ###
##############

declare -A CONFIG=(
  [waybar_config]="$HOME/.config/waybar/config"
  [waybar_style]="$HOME/.config/waybar/style.css"
)

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Options:
  -l, --layer DIR    Select config layer from DIR and link to ${CONFIG[waybar_config]}
  -s, --style DIR    Select style file from DIR and link to ${CONFIG[waybar_style]}
  -h, --help         Show this help
  -v, --version      Show version

Examples:
  $SCRIPT_NAME --layer ~/.config/waybar/layers
  $SCRIPT_NAME --style ~/.config/waybar/styles
EOF
}

############
### main ###
############

find_command() {
  local dir=$1
  find "$dir" -maxdepth 1 -type f -exec basename {} \; | sort
}

style_set() {
  local style_dir=$1
  local link=$2
  local preview="cat $style_dir/{}"
  local window="right:60%:wrap"

  find_command "$style_dir" | fzf \
    --preview="$preview" \
    --preview-window="$window" \
    --bind "Y:execute(ln -sf $style_dir/{} $link && pidof waybar &>/dev/null && pkill waybar && nohup waybar &>/dev/null &)" \
    --bind "enter:execute(ln -sf $style_dir/{} $link && pidof waybar &>/dev/null && pkill waybar && nohup waybar &>/dev/null &)+abort"
}

main() {
  [[ $# -eq 0 ]] && { usage; exit 1; }

  while [[ $# -gt 0 ]]; do
    case $1 in
      -l|--layer)
        [[ -n $2 ]] || { echo "Error: --layer requires a directory"; exit 1; }
        style_set "$2" "${CONFIG[waybar_config]}"
        shift 2
        ;;
      -s|--style)
        [[ -n $2 ]] || { echo "Error: --style requires a directory"; exit 1; }
        style_set "$2" "${CONFIG[waybar_style]}"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -v|--version)
        echo "$VERSION"
        exit 0
        ;;
      *)
        echo "Invalid option: $1"
        usage
        exit 1
        ;;
    esac
  done
}

main "$@"
