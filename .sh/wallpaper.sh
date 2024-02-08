#!/usr/bin/env zsh

function change {
  local transition=("simple" "fade" "left" "right" "top" "bottom" "wipe" "grow" "center" "outer" "random" "wave")
  swww img "$1" --transition-type=$(shuf -n1 -e "${transition[@]}")
}

function bing {
  # 1366 1920 3840
  resolution=3840
  resp=$(curl "https://bing.biturl.top/?resolution=$resolution&format=json&index=random&mkt=random")
  url=$(jq .url <<< $resp)
  name=$(jq .copyright <<< $resp)
  name=${name//\"/}
  name=${name%%\(*}
  name=${name%%,*}
  name="$(echo $name)"
  img_path="$HOME/Pictures/wallpaper/$name.jpg"
  if [[ ! -e "$img_path" ]]; then
    aria2c ${url//\"/} -d "$HOME/Pictures/wallpaper" -o "$name.jpg"
  fi
  change "$img_path" && notify-send "Bing Wallpaper" "$name"
}

function random {
  local commands=(
    "bing"
  )
  $(shuf -n1 -e "${commands[@]}")
}

############################ Args ############################

SHORT="b,p,r"
LONG="bing,random"
ARGS=`getopt -a -o $SHORT -l $LONG -n "${0##*/}" -- "$@"`

if [[ $? -ne 0 || $# -eq 0 ]; then
  cat <<- EOF
$0: -[`echo $SHORT|sed 's/,/|/g'`] --[`echo $LONG|sed 's/,/|/g'`]
EOF
fi

eval set -- "${ARGS}"

while true
do
  case "$1" in
  -b|--bing) bing ;;
  -r|--random) random ;;
  --) shift ; break ;;
  esac
shift
done

