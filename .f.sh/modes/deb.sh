#!/usr/bin/env zsh

if hash fzf &>/dev/null; then
  url=$(echo $urls | grep -E "$pattern" | fzf -1)
else
  url=$(echo $urls | grep -E "$pattern" | head -n 1)
fi

info "$(blue url): $url"

file="${url##*/}"
dir="${repo//\//_}"
mkdir -p /tmp/$dir

# download release file
aria2c --all-proxy="$http_proxy" "$url" -d "/tmp/$dir" -o "$file" --allow-overwrite=true
builtin cd -q /tmp/$dir

sudo dpkg -i "$file"

