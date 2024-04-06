# ###  Pkgconfig  #############################################################

export PKG_CONFIG_PATH="/usr/lib/pkgconfig:\
/usr/lib/x86_64-linux-gnu/pkgconfig:\
/usr/share/pkgconfig:\
/usr/local/lib/x86_64-linux-gnu/pkgconfig"

# ###  Lib Path  ##############################################################

export LD_LIBRARY_PATH="/usr/local/lib:\
/usr/lib/x86_64-linux-gnu:\
/usr/local/cuda/lib64:\
/usr/local/cuda/targets/x86_64-linux/lib:\
/usr/local/cuda/targets/x86_64-linux/lib/stubs"

# ###  System Options  ########################################################

# Term options
# terminfo directory: ${HOME}/.terminfo
# then /etc/terminfo
# then /lib/terminfo
# then /usr/share/terminfo
export TERMINFO="/lib/terminfo"
export TERM="xterm-256color"
export KEYTIMEOUT=20
export CLIPBOARD="$HOME/.clipboard"

# for cmake
# export CXX=/usr/bin/g++-11
# export CC=/usr/bin/gcc-11
# export LD=/usr/bin/g++-11

# input method set up
export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx5

# editor
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export VISUAL="$EDITOR"

# browser
export BROWSER=google-chrome

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

# ###  Hyprland  ##############################################################

export MOZ_ENABLE_WAYLAND=1
export MOZ_WAYLAND_USE_VAAPI=1
export MOZ_DBUS_REMOTE=1
export MOZ_WEBRENDER=1
export GTK_USE_PORTAL=1
export GDK_BACKEND=wayland
export XDG_SESSION_TYPE=wayland
export SDL_VIDEODRIVER=wayland
export QT_QPA_PLATFORM=wayland
export CLUTTER_BACKEND=wayland
export XDG_SESSION_DESKTOP=wayland
export XDG_CURRENT_DESKTOP=wayland

# ###  Path  ##################################################################

function addPath {
  local paths="${(@s/:/)1}"
  for p in ${(s/:/)paths}; do
    [[ ":$PATH:" != *":$p:"* ]] && export PATH="$p:$PATH"
  done
}

# sh
addPath "/usr/sbin"
addPath "$HOME/.local/bin"
addPath "$HOME/.sh.d"

# brew
export HOMEBREW_PREFIX="$HOME/.linuxbrew";
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar";
export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX/Homebrew";
addPath "$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin";
addPath "$HOMEBREW_PREFIX/opt/llvm/bin";

export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH:+:$MANPATH}";
export INFOPATH="$HOMEBREW_PREFIX/share/info:$INFOPATH";

# npm
addPath "$HOME/.npm/bin"

# snap
addPath "/snap/bin"

# go
export GOROOT="/usr/local/go"
export GOPATH="$HOME/go"
export GOENV="$HOME/go/env"
addPath "$GOROOT/bin"
addPath "$GOPATH/bin"

# cargo
export CARGO_HOME="$HOME/.cargo"
addPath "$CARGO_HOME/bin"

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

# ###  Function  ##############################################################

# pretty.sh
[[ -e "$HOME/.sh/pretty.sh" ]] && source $HOME/.sh/pretty.sh

# blank aliases
typeset -a baliases
baliases=()
function balias {
  alias $@
  args="$@"
  args=${args%%\=*}
  baliases+=(${args##* })
}

# ignored aliases
typeset -a ialiases
ialiases=()

function ialias {
  alias $@
  args="$@"
  args=${args%%\=*}
  ialiases+=(${args##* })
}

# functionality
function expand-alias-space {
  [[ $LBUFFER =~ "\<(${(j:|:)baliases})\$" ]]; insertBlank=$?
  if [[ ! $LBUFFER =~ "\<(${(j:|:)ialiases})\$" ]]; then
    zle _expand_alias
  fi
  zle self-insert
  if [[ "$insertBlank" = "0" ]]; then
    zle backward-delete-char
  fi
}

function backward-delete-word {
  local WORDCHARS='*?_[]~=&;!#$%^(){}<>'
  zle backward-kill-word
}

