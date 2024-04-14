#!/usr/bin/env zsh

# ###  Args  ##################################################################

short="m:,n:"
long="mode:,name:"
ARGS=`getopt -a -o $short -l $long -n "${0##*/}" -- "$@"`

if [[ $? -ne 0 ]]; then
  cat <<- EOF
Usage: $0 [OPTIONS] [REPO] [DIR/REPATTERN]

Options:
    -m, --mode      The mode of the script.
    -n, --name      Set the name of the command.
EOF
  return 1
fi

eval set -- "${ARGS}"

while true
do
  case "$1" in
  -m|--mode) MODE="$2"; shift ;;
  -n|--name) CMD="$2"; shift ;;
  --) shift ; break ;;
  esac
shift
done

# ###  Main  ##################################################################

# ensure $1 is github repo
[[ $# -lt 1 ]] && error "missing github repo" && exit 1
[[ ! "$1" =~ ^[^/]+/[^/]+$ ]] && error "invalid github repo: $1" && exit 1

# default
local mode=${MODE:-archive}
export repo=$1
export pattern=$2
export cmd=${CMD:-${repo##*/}}
export root_dir=$HOME/.f.sh
export db=$root_dir/data.db
export prefix=$HOME/.local/bin

# 清除标题行并重新输出
# printf "\033[2J\033[H"

# ensure re pattern
[[ -z "$pattern" ]] && error "missing grep pattern" && exit 1

# ensure dir
[[ ! -e "$root_dir" ]] && mkdir -p "$root_dir"
[[ ! -e "$prefix" ]] && mkdir -p "$prefix"

# ensure database
if [[ ! -e "$db" ]]; then
  hash sqlite3 2>/dev/null || {error "sqlite3 is not found" && exit 1}
  info "create database $db"
  sqlite3 $db "CREATE TABLE f_sh(cmd TEXT PRIMARY KEY, repo TEXT, tag TEXT)"
fi

mode_path="$root_dir/modes/$mode.sh"
if [[ -e "$mode_path" && -x "$mode_path" ]]; then
  bar "$repo"
  info "$(blue mod): $mode"
  info "$(blue cmd): $cmd"

  # get current tag
  current_tag="$(sqlite3 $db "SELECT tag FROM f_sh WHERE cmd = '$cmd'" 2>/dev/null)"
  info "$(blue tag): ${current_tag}"

  # get latest tag
  latest=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | sed 's/\\n//g' | sed 's/\\r//g')
  [[ -z "$latest" ]] && error "failed to download release file" && exit 1

  # no need to update
  export tag="$(jq -r '.tag_name' <<<"$latest")"
  [[ $current_tag == $tag ]] && info "no need to update" && exit 0

  # get urls
  export urls=$(
    jq -r '.assets[].browser_download_url' <<<"$latest" 2>/dev/null \
      | grep -Ev ".(sha256|sha256sum)$" \
      | grep -Ev ".minisig$" \
      | grep -Ev ".zsync$"
  )
  [[  -z "$urls" ]] && error "no download url found" && exit 1

  # run script
  info "$(blue new): $tag"
  info "$(blue pattern): $pattern"
  $mode_path ${@:2}

  # update database
  if [[ $? -eq 0 ]]; then
    sqlite3 $db "INSERT OR REPLACE INTO f_sh (cmd, repo, tag) VALUES ('$cmd', '$repo', '$tag')"
    [[ $? -eq 0 ]] && ok "$(green $cmd) updated to $(green $tag)"
  fi

else
  [[ -e "$mode_path" ]] && error "mode $mode is not executable" && exit 1
  error "mode $mode is not found" && exit 1
fi

