# ###  Funtions  ##############################################################

# pretty.sh
[[ -e "$HOME/.sh.d/pretty.sh" ]] && source $HOME/.sh.d/pretty.sh

# blank aliases
typeset -a baliases
baliases=()
balias() {
  alias $@
  args="$@"
  args=${args%%\=*}
  baliases+=(${args##* })
}

# ignored aliases
typeset -a ialiases
ialiases=()

ialias() {
  alias $@
  args="$@"
  args=${args%%\=*}
  ialiases+=(${args##* })
}

# functionality
expand-alias-space() {
  [[ $LBUFFER =~ "\<(${(j:|:)baliases})\$" ]]; insertBlank=$?
  if [[ ! $LBUFFER =~ "\<(${(j:|:)ialiases})\$" ]]; then
    zle _expand_alias
  fi
  zle self-insert
  if [[ "$insertBlank" = "0" ]]; then
    zle backward-delete-char
  fi
}

backward-delete-worda() {
  local WORDCHARS='*?_[]~=&;!#$%^(){}<>'
  zle backward-kill-word
}

addPath() {
  local paths="${(@s/:/)1}"
  for p in ${(s/:/)paths}; do
    [[ ":$PATH:" != *":$p:"* ]] && export PATH="$p:$PATH"
  done
}

# ###  Path  ##################################################################

# sh
addPath "/usr/sbin"
addPath "$HOME/.local/bin"
addPath "$HOME/.sh.d"

# snap
addPath "/snap/bin"

# go
export GOROOT="/usr/local/go"
export GOPATH="$HOME/go"
export GOENV="$HOME/go/env"
addPath "$GOROOT/bin"
addPath "$GOPATH/bin"

# sqlserver
addPath "/opt/mssql-tools/bin"

# dotnet
addPath "$HOME/.dotnet:$HOME/.dotnet/tools"

# cuda
addPath "/usr/local/cuda/bin"

# pnpm
export PNPM_HOME="/home/wukaige/.local/share/pnpm"
addPath "$PNPM_HOME"

# TiDB
addPath "$HOME/.tiup/bin"

# doom emacs
addPath "$HOME/.config/emacs/bin"

# conda
addPath "$HOME/anaconda3/bin"

# f.sh
addPath "$HOME/.f.sh"

# ###  Envs  ##################################################################

# editor
if hash nvim &>/dev/null; then
  export EDITOR="nvim"
elif hash hx &>/dev/null; then
  export EDITOR="hx"
elif hash vim &>/dev/null; then
  export EDITOR="vim"
else
  sudo apt install vim
  export EDITOR="vim"
fi

export SUDO_EDITOR="$EDITOR"
export VISUAL="$EDITOR"

# browser
export BROWSER=chromium

# cursor
export XCURSOR_PATH="$HOME/.local/share/icons"
export XCURSOR_THEME=Vimix

# Skip the not really helping Ubuntu global compinit
export skip_global_compinit=1

# zsh
export ZSH_DIR=$HOME/.zsh.d

# tmux
export TMUX_DIR=$HOME/.tmux.d

# plugin root dir
export PLUGIN_DIR=$HOME/.plugin.d

# cache
export XDG_CACHE_HOME=$HOME/.cache

