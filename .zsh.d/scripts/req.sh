#!/usr/bin/env zsh

tmp_file="/tmp/requirements.txt"
max_length=0

[[ -e "$tmp_file" ]] && rm -rf $tmp_file

pip3 list 2>/dev/null | sed '1,2d' | awk '{printf "%s == %s\n", $1, $2}' | while read -r raw
do
  echo $raw >> $tmp_file
  package="$(echo $raw|choose 0)"
  length=${#package}
  [[ $length -gt $max_length ]] && max_length=$length
done

while read -r raw
do
  read package version <<< "$(echo $raw|choose 0 2)"
  [[ "$package" = "pip" ]] && continue
  printf "%-${max_length}s == %s\n" "$package" "$version"
done < $tmp_file

