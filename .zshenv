############
### ENVS ###
############

# editor
export EDITOR="hx"
export SUDO_EDITOR="$EDITOR"
export VISUAL="$EDITOR"

# browser
export BROWSER=google-chrome

# cursor
export XCURSOR_PATH="$HOME/.local/share/icons"
export XCURSOR_THEME=Vimix

# Skip the not really helping Ubuntu global compinit
export skip_global_compinit=1

# cache
export XDG_CACHE_HOME=$HOME/.cache

# wayland compatibility
export MOZ_ENABLE_WAYLAND=1
export MOZ_WAYLAND_USE_VAAPI=1
export MOZ_DBUS_REMOTE=1
export MOZ_USE_XINPUT2=1
export MOZ_WEBRENDER=1
export GTK_USE_PORTAL=1
export GDK_BACKEND=wayland
export SDL_VIDEODRIVER=wayland
export CLUTTER_BACKEND=wayland

# cursor
export XCURSOR_THEME=Vimix
export XCURSOR_SIZE=16
export WLR_NO_HARDWARE_CURSORS=1

# nvidai
# export LIBVA_DRIVER_NAME=nvidia
# export GBM_BACKEND=nvidia-drm
# export __GLX_VENDOR_LIBRARY_NAME=nvidia

# qt
export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=qt5ct

# fcitx input-related
export XMODIFIERS=@im=fcitx
export QT_IM_MODULE=fcitx
export QT_IM_MODULES="wayland;fcitx;ibus"
export SDL_IM_MODULE=fcitx
export CLUTTER_IM_MODULE=fcitx

# xdg
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=hyprland
export XDG_CURRENT_DESKTOP=hyprland

# lang
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

# for cmake
# export CXX=/usr/bin/g++-11
# export CC=/usr/bin/gcc-11
# export LD=/usr/bin/g++-11

# Term options
# terminfo directory: ${HOME}/.terminfo
# then /etc/terminfo
# then /lib/terminfo
# then /usr/share/terminfo
export TERMINFO="/lib/terminfo"
export TERM="xterm-256color"
export KEYTIMEOUT=20
export CLIPBOARD="$HOME/.clipboard"

# pkg config
export PKG_CONFIG_PATH="/usr/lib/pkgconfig:\
/usr/lib/x86_64-linux-gnu/pkgconfig:\
/usr/share/pkgconfig:\
/usr/local/lib/x86_64-linux-gnu/pkgconfig"

# ld library
export LD_LIBRARY_PATH="/usr/local/lib:\
/usr/lib/x86_64-linux-gnu:\
/usr/local/cuda/lib64:\
/usr/local/cuda/targets/x86_64-linux/lib:\
/usr/local/cuda/targets/x86_64-linux/lib/stubs"

################
### FUNCTION ###
################

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

##############
### CUSTOM ###
##############

# local
addPath "$HOME/.local/bin"

# npm
addPath "$HOME/.npm/bin"

# update HYPRLAND_INSTANCE_SIGNATURE for zellij
if [[ -d "/run/user/$UID/hypr" ]]; then
  export HYPRLAND_INSTANCE_SIGNATURE="$(ls /run/user/$UID/hypr | tail -n 1)"
fi

