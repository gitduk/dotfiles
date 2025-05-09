#!/bin/bash

# check hyproled command
hash hyproled 2>/dev/null || {
  echo "Error: hyproled command not found. Please install hyproled."
  exit 1
}

# getopt
OPTIONS="foa:"
LONGOPTS="focus,off,area:"
ARGS=$(getopt -a --options=$OPTIONS --longoptions=$LONGOPTS --name "${0##*/}" -- "$@")
if [[ $? -ne 0 || $# -eq 0 ]]; then
  cat <<-EOF
$0: -[$(echo $OPTIONS | sed 's/,/|/g')] --[$(echo $LONGOPTS | sed 's/,/|/g')]
Usage:
  $0 [options]

Options:
  -f, --focus        Activate hyproled to mask pixels of the focused window area
  -o, --off          Turn off hyproled and restore the screen
  -a, --area AREA    Apply hyproled to a specific area of the screen (e.g., "x:y:w:h")

EOF
fi
eval set -- "$ARGS"

focus() {
  # Focus current active window by masking everything around
  window="$(hyprctl activewindow -j)"
  x="$(echo $window | jq -r '.at[0]')"
  y="$(echo $window | jq -r '.at[1]')"
  w="$(echo $window | jq -r '.size[0]')"
  h="$(echo $window | jq -r '.size[1]')"
  area="$x:$y:$w:$h"
  hyproled -i -a "$area"
}

while true; do
  case "$1" in
  -f | --focus)
    focus
    ;;
  -o | --off)
    hyproled -s -a 0:0:0:0
    ;;
  -a | --area)
    hyproled -s -a $2
    shift
    ;;
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
