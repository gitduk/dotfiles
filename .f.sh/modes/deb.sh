#!/usr/bin/env zsh

local pattern=$1

# fetch latest version
latest=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | sed 's/\\n//g' | sed 's/\\r//g')
[[ -z "$latest" ]] && error "$(red $repo): cannot fetch latest release" && exit 1

# get latest tag name
tag="$(echo $latest | jq -r '.name')"
[[ -z "$tag" ]] && error "$(red $repo): cannot fetch latest version" && exit 1

# query tag field from sqlite table f_sh
current_tag=$(sqlite3 $db "select tag from f_sh where repo='$repo'" 2>/dev/null || error "$(red $repo): cannot query tag from $db")

# no need to update
[[ -n "$current_tag" ]] && [[ "$tag" == "$current_tag" ]] && ok "$(green $repo): no need to update" && exit

urls="$(echo $latest | jq -r '.assets[].browser_download_url' | grep -E "$pattern")"

# urls is null
if [[ -z "$urls" ]]; then
	error "$(red $repo): cannot match url with $pattern"
	debug "latest: \n$latest"
	exit 1
fi

# match many url
if [[ $(echo $url | wc -l) -eq 1 ]]; then
	url="$urls"
else
	url="$(echo $urls | fzf --prompt 'select url: ')"
fi

file="${url##*/}"
dir="${repo//\//_}"
mkdir -p /tmp/$dir
cmd="${cmd:-${repo##*/}}"

# download release file
aria2c -c --all-proxy="$http_proxy" "$url" -d "/tmp/$dir" -o "$file"
builtin cd -q /tmp/$dir

sudo dpkg -i "$file"

# update sqlite table f_sh
if [[ $? -eq 0 ]]; then
  sqlite3 $db "insert or replace into f_sh (cmd, repo, tag) values ('$cmd', '$repo', '$tag')"
  ok "$(green $repo): ${cmd} updated to $tag"
fi

