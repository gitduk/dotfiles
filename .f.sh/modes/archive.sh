#!/usr/bin/env zsh

function extract {
  local full_path="$1"
  local name=${full_path##*/}
  local file
  case "${name:l}" in
    *.tar.gz|*.tgz) file=$(tar zxvf "$full_path") ;;
    *) echo "$0: '$full_path' cannot be extracted" >&2 ;;
  esac
  [[ $(echo $file | wc -l) -eq 1 ]] && echo $file
}

local pattern=$1
local success=1

# fetch latest version
latest=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | sed 's/\\n//g' | sed 's/\\r//g')
[[ -z "$latest" ]] && error "$(red $repo): cannot fetch latest release" && exit 1

# get latest tag name
tag="$(echo $latest | jq -r '.name')"
if [[ -z "$tag" ]];then
  error "$(red $repo): cannot fetch latest version"
  debug "latest: $latest"
  exit 1
fi

# query tag field from sqlite table f_sh
current_tag=$(sqlite3 $db "select tag from f_sh where repo='$repo'" 2>/dev/null || error "$(red $repo): cannot query tag from $db")

# no need to update
[[ -n "$current_tag" ]] && [[ "$tag" == "$current_tag" ]] && ok "$(green $repo): no need to update" && exit

urls="$(echo $latest | jq -r '.assets[].browser_download_url' | grep -E "$pattern")"

# urls is null
if [[ -z "$urls" ]];then
  error "$(red $repo): cannot match url with $pattern"
  debug "latest: \n$latest"
  exit 1
fi

# match many url
if [[ $(echo $url | wc -l) -eq 1 ]];then
  url="$urls"
else
  url="$(echo $urls | fzf --prompt 'select url: ')"
fi

file="${url##*/}"
dir="${repo//\//_}"
mkdir -p /tmp/$dir

# download release file
aria2c -c --all-proxy="$http_proxy" "$url" -d "/tmp/$dir" -o "$file"
builtin cd -q /tmp/$dir

# one file
file=$(extract "$file")
if [[ -n "$file" ]];then
  [[ ! -x "$file" ]] && sudo chmod -R 755 $file
  cp -v $file $prefix/$cmd
  success=0
else
  # multiple files
  count=0
  find "/tmp/$dir" -type f -executable | while read -r file; do
    cp -v $file $prefix/
    count=$((count+1))
  done

  # can not found any executable file
  if [[ $count -eq 0 ]]; then
    warn "cannot find any executable file in /tmp/$dir"
  else
    success=0
  fi
fi

cmd="${cmd:-${repo##*/}}"

# update sqlite table f_sh
if [[ $success -eq 0 ]];then
  sqlite3 $db "insert or replace into f_sh (cmd, repo, tag) values ('$cmd', '$repo', '$tag')"
  ok "$(green $repo): ${cmd} updated to $tag"
else
  error "$(red $repo): cannot install $url"
fi

