#!/usr/bin/env zsh

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
  echo $img_path
}

############################ Args ############################

SHORT="b"
LONG="bing"
ARGS=`getopt -a -o $SHORT -l $LONG -n "${0##*/}" -- "$@"`

if [[ $? -ne 0 || $# -eq 0 ]]; then
  cat <<- EOF
$0: -[`echo $SHORT|sed 's/,/|/g'`] --[`echo $LONG|sed 's/,/|/g'`]
EOF
fi

eval set -- "${ARGS}"

while true
do
  case "$1" in
  -b|--bing) bing ;;
  --) shift ; break ;;
  esac
shift
done

