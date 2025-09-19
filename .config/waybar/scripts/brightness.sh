#!/usr/bin/env bash

SCRIPT_NAME=$(basename "$0")
VERSION="1.0.0"

##############
### config ###
##############

declare -A CONFIG=(
  [min]=0
  [max]=100
)

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Options:
  -g, --get           Get current brightness level
  -s, --set VALUE     Set brightness to VALUE
  -i, --inc VALUE     Increase brightness by VALUE
  -d, --dec VALUE     Decrease brightness by VALUE
  -h, --help          Show this help
  -v, --version       Show version

Examples:
  $SCRIPT_NAME --get
  $SCRIPT_NAME --set 50
  $SCRIPT_NAME --inc 10
  $SCRIPT_NAME --dec 20
EOF
}

############
### main ###
############

# 获取当前亮度
get_brightness() {
  ddcutil getvcp 10 -t | awk '{print $4}'
}

# 设置亮度
set_brightness() {
  local new=$1
  (( new > CONFIG[max] )) && new=${CONFIG[max]}
  (( new < CONFIG[min] )) && new=${CONFIG[min]}
  ddcutil setvcp 10 "$new"
  echo "Brightness set to $new"
}

# 增加亮度
inc_brightness() {
  local current=$(get_brightness)
  local new=$(( current + $1 ))
  (( new > CONFIG[max] )) && new=${CONFIG[max]}
  ddcutil setvcp 10 "$new"
  echo "Brightness increased to $new"
}

# 降低亮度
dec_brightness() {
  local current=$(get_brightness)
  local new=$(( current - $1 ))
  (( new < CONFIG[min] )) && new=${CONFIG[min]}
  ddcutil setvcp 10 "$new"
  echo "Brightness decreased to $new"
}

main() {
  [[ $# -eq 0 ]] && { usage; exit 1; }

  while [[ $# -gt 0 ]]; do
    case $1 in
      -g|--get)
        get_brightness
        shift
        ;;
      -s|--set)
        [[ -n $2 ]] || { echo "Error: --set requires a value"; exit 1; }
        set_brightness "$2"
        shift 2
        ;;
      -i|--inc)
        [[ -n $2 ]] || { echo "Error: --inc requires a value"; exit 1; }
        inc_brightness "$2"
        shift 2
        ;;
      -d|--dec)
        [[ -n $2 ]] || { echo "Error: --dec requires a value"; exit 1; }
        dec_brightness "$2"
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
