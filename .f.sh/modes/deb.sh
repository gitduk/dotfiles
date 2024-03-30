#!/usr/bin/env zsh

url=$(echo $urls | grep -E "$pattern" | fzf -1)
info "$(blue url): $url"

file="${url##*/}"
dir="${repo//\//_}"
mkdir -p /tmp/$dir

# download release file
aria2c --all-proxy="$http_proxy" "$url" -d "/tmp/$dir" -o "$file" --allow-overwrite=true
builtin cd -q /tmp/$dir

sudo dpkg -i "$file"

