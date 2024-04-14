#!/usr/bin/env zsh

if hash fzf &>/dev/null; then
  url=$(echo $urls | grep -E "$pattern" | fzf -1)
else
  url=$(echo $urls | grep -E "$pattern" | head -n 1)
fi
info "$(blue url): $url"

# download release file
aria2c --all-proxy="$http_proxy" "$url" -d "$prefix" -o "$cmd" --allow-overwrite=true
sudo chmod 744 "${prefix%/}/$cmd"

