#!/usr/bin/env zsh

OPTIONS="i:d:gs:"
LONGOPTS="inc:,dec:,get,set:"
ARGS=`getopt -a --options=$OPTIONS --longoptions=$LONGOPTS --name "${0##*/}" -- "$@"`
if [[ $? -ne 0 || $# -eq 0 ]]; then
  cat <<- EOF
$0: -[`echo $OPTIONS|sed 's/,/|/g'`] --[`echo $LONGOPTS|sed 's/,/|/g'`]
Usage:
  -g, --get        Get current brightness level
  -s, --set VALUE  Set brightness by VALUE
  -i, --inc VALUE  Increase brightness by VALUE
  -d, --dec VALUE  Decrease brightness by VALUE
EOF
fi
eval set -- "$ARGS"

get() {
  ddcutil getvcp 10 -t | cut -d ' ' -f 4
}

set() {
  local new=$1
  if ((new > 100)); then
    new=100
  fi
  if ((new < 0)); then
    new=0
  fi
  ddcutil setvcp 10 $new
  echo "Brightness set up to $new"
}

inc() {
  local current=$(get)
  local new=$(($current + $1))
  if ((new > 100)); then
    new=100
  fi
  ddcutil setvcp 10 $new
  echo "Brightness increased to $new"
}

dec() {
  local current=$(get)
  local new=$(($current - $1))
  if ((new < 0)); then
    new=0
  fi
  ddcutil setvcp 10 $new
  echo "Brightness decreased to $new"
}

while true; do
  case "$1" in
    -g|--get)
      get
      ;;
    -s|--set)
      set "$2"
      shift
      ;;
    -i|--inc)
      inc "$2"
      shift
      ;;
    -d|--dec)
      dec "$2"
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

