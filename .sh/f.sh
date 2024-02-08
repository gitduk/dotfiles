#!/usr/bin/env zsh

source $HOME/.sh/pretty.sh

# ###  Args  ##################################################################

short="a,c,b,p:,n:,i"
long="archive,clone,binary,prefix:,name:,install"
ARGS=`getopt -a -o $short -l $long -n "${0##*/}" -- "$@"`

if [[ $? -ne 0 ]]; then
  cat <<- EOF
Usage: $0 [OPTIONS] [REPO] [DIR/REPATTERN]

Options:
    -a, --archive   Archive mode.
    -c, --clone     Clone repo to dir.
    -b, --binary    Download the binary file.
    -p, --prefix    The binary file prefix.
    -i, --install   Install mode.
    -n, --name      Rename binary file.
EOF
  return 1
fi

eval set -- "${ARGS}"

while true
do
  case "$1" in
  -a|--archive) ARCHIVE_MODE=1 ;;
  -b|--binary) BIN_MODE=1 ;;
  -c|--clone) CLONE_MODE=1 ;;
  -i|--install) INSTALL_MODE=1 ;;
  -p|--prefix) PREFIX="$2"; shift ;;
  -n|--name) BIN_NAME="$2"; shift ;;
  --) shift ; break ;;
  esac
shift
done

# ###  Main  ##################################################################


function extract {
  local full_path="$1"
  local file="${full_path##*/}"
  case "${file:l}" in
    *.tar.gz|*.tgz)
      (( $+commands[pigz] )) && { tar -I pigz -xvf "$full_path" } || tar zxvf "$full_path" ;;
    *.tar.bz2|*.tbz|*.tbz2)
      (( $+commands[pbzip2] )) && { tar -I pbzip2 -xvf "$full_path" } || tar xvjf "$full_path" ;;
    *.tar.xz|*.txz)
      (( $+commands[pixz] )) && { tar -I pixz -xvf "$full_path" } || {
      tar --xz --help &> /dev/null \
      && tar --xz -xvf "$full_path" \
      || xzcat "$full_path" | tar xvf - } ;;
    *.tar.zma|*.tlz)
      tar --lzma --help &> /dev/null \
      && tar --lzma -xvf "$full_path" \
      || lzcat "$full_path" | tar xvf - ;;
    *.tar.zst|*.tzst)
      tar --zstd --help &> /dev/null \
      && tar --zstd -xvf "$full_path" \
      || zstdcat "$full_path" | tar xvf - ;;
    *.tar) tar xvf "$full_path" ;;
    *.tar.lz) (( $+commands[lzip] )) && tar xvf "$full_path" ;;
    *.tar.lz4) lz4 -c -d "$full_path" | tar xvf - ;;
    *.tar.lrz) (( $+commands[lrzuntar] )) && lrzuntar "$full_path" ;;
    *.gz) (( $+commands[pigz] )) && pigz -cdk "$full_path" > "${file:t:r}" || gunzip -ck "$full_path" > "${file:t:r}" ;;
    *.bz2) bunzip2 "$full_path" ;;
    *.xz) unxz "$full_path" ;;
    *.lrz) (( $+commands[lrunzip] )) && lrunzip "$full_path" ;;
    *.lz4) lz4 -d "$full_path" ;;
    *.lzma) unlzma "$full_path" ;;
    *.z) uncompress "$full_path" ;;
    *.zip|*.war|*.jar|*.ear|*.sublime-package|*.ipa|*.ipsw|*.xpi|*.apk|*.aar|*.whl) unzip "$full_path" ;;
    *.rar) unrar x -ad "$full_path" ;;
    *.7z) 7za x "$full_path" ;;
    *) echo "$0: '$file' cannot be extracted" >&2 ;;
  esac
}

# require redis-cli command
hash redis-cli 2>/dev/null || sudo apt install -y redis-tools

# default vars
local REPO="$1"
local PREFIX=${PREFIX:-$HOME/.local/bin}

# modes
local ARCHIVE_MODE=${ARCHIVE_MODE:-0}
local BIN_MODE=${BIN_MODE:-0}
local BIN_NAME=${BIN_NAME:-${REPO##*/}}
local CLONE_MODE=${CLONE_MODE:-0}
local INSTALL_MODE=${INSTALL_MODE:-0}


# set CLONE_MODE to default
[[ $(( $ARCHIVE_MODE + $BIN_MODE + $CLONE_MODE + $INSTALL_MODE )) -eq 0 ]] && CLONE_MODE=1

[[ ! -e "$PREFIX" ]] && mkdir -p "$PREFIX"

# clone mode
if [[ $CLONE_MODE -eq 1 ]]; then
  if [[ -n "$2" ]]; then
    git clone --depth=1 "https://github.com/$REPO.git" "$2" && exit
  else
    git clone --depth=1 "https://github.com/$REPO.git" && exit
  fi
fi

# binary / install / archive mode
local REPATTERN="$2"
# fetch latest version
releases="$(curl -s "https://api.github.com/repos/$REPO/releases" | jq -r '.[].assets[].browser_download_url')"
url="$(echo $releases | grep -E "$REPATTERN" | head -n 1)"

# error case
if [[ -z "$url" ]];then
  warn "can not parse url from $releases with pattern $REPATTERN"
  exit 1
fi

# no need to update
[[ "$url" = "$(redis-cli GET "$BIN_NAME")" ]] && ok "$(green $BIN_NAME): no need to update" && exit

info "$REPO: $url"
[[ -e "${PREFIX%/}/$BIN_NAME" ]] && rm -rf "${PREFIX%/}/$BIN_NAME"

# binary mode
if [[ $BIN_MODE -eq 1 ]]; then
  aria2c -c --all-proxy="$http_proxy" "$url" -d "$PREFIX" -o "$BIN_NAME"
  sudo chmod 744 "${PREFIX%/}/$BIN_NAME"
fi

# install mode
if [[ $INSTALL_MODE -eq 1 ]]; then
  aria2c -c --all-proxy="$http_proxy" "$url" -d "/tmp/" -o "${url##*/}"
  sudo dpkg -i "/tmp/${url##*/}"
fi

# archive mode
if [[ $ARCHIVE_MODE -eq 1 ]]; then
  mkdir -p /tmp/$BIN_NAME
  aria2c -c --all-proxy="$http_proxy" "$url" -d "/tmp/$BIN_NAME/" -o "${url##*/}"
  builtin cd -q /tmp/$BIN_NAME
  extract "${url##*/}" &>/dev/null
  [[ ! $? -eq 0 ]] && error "Can not extract /tmp/$BIN_NAME/${url##*/}" && exit 1
  find "/tmp/$BIN_NAME" -type f -executable | while read -r file; do
    cp -v $file $PREFIX/
  done
fi

[[ $? -eq 0 ]] && redis-cli SET "$BIN_NAME" "$url"

