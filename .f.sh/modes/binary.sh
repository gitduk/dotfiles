#!/usr/bin/env zsh

url=$(echo $urls | grep -E "$pattern" | fzf -1)
info "$(blue url): $url"

# download release file
aria2c --all-proxy="$http_proxy" "$url" -d "$prefix" -o "$cmd" --allow-overwrite=true
sudo chmod 744 "${prefix%/}/$cmd"

