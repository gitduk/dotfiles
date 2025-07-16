#!/bin/bash

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
cache_file="${cache_dir}/dark-light"
css_file="$HOME/.config/waybar/colors.css"

mkdir -p $cache_dir
if [[ ! -f $cache_file ]]; then
  touch $cache_file
fi

current="$(cat $cache_file)"

case $current in
0)
  echo 1 | tee $cache_file
  ;;
1)
  echo 0 | tee $cache_file
  ;;
*)
  echo 1 | tee $cache_file
  ;;
esac

sed -i -e 's/foreground/__TMP__/g' -e 's/background/foreground/g' -e 's/__TMP__/background/g' $css_file
