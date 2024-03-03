#!/usr/bin/env zsh

# ###  Args  ##################################################################

short="m:,r:"
long="mode:,rename:"
ARGS=`getopt -a -o $short -l $long -n "${0##*/}" -- "$@"`

if [[ $? -ne 0 ]]; then
  cat <<- EOF
Usage: $0 [OPTIONS] [REPO] [DIR/REPATTERN]

Options:
    -m, --mode      The mode of the script.
    -r, --rename    Rename cmd.
EOF
  return 1
fi

eval set -- "${ARGS}"

while true
do
  case "$1" in
  -m|--mode) MODE="$2"; shift ;;
  -r|--rename) CMD="$2"; shift ;;
  --) shift ; break ;;
  esac
shift
done

# ###  Main  ##################################################################

# ensure $1 is github repo
[[ ! "$1" =~ ^[^/]+/[^/]+$ ]] && error "invalid REPO: $1" && exit 1

# default
local mode=${MODE:-clone}
export repo=$1
export cmd=${CMD}
export root_dir=$HOME/.f.sh
export db=$root_dir/data.db
export prefix=$HOME/.local/bin

# ensure root dir
[[ ! -e "$root_dir" ]] && mkdir -p "$root_dir"

# ensure database
if [[ ! -e "$db" ]]; then
  hash sqlite3 2>/dev/null || {error "sqlite3 is not found" && exit 1}
  info "create database $db"
  sqlite3 $db "CREATE TABLE f_sh(cmd TEXT PRIMARY KEY, repo TEXT, tag TEXT)"
fi

# run mode
mode_path="$root_dir/modes/$mode.sh"
if [[ -e "$mode_path" && -x "$mode_path" ]]; then
  bar "$mode, $repo${cmd:+ -> $cmd}"
  $mode_path ${@:2}
else
  [[ -e "$mode_path" ]] && error "mode $mode is not executable" && exit 1
  error "mode $mode is not found" && exit 1
fi

