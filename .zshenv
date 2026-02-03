# editor
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export VISUAL="$EDITOR"

# browser
export BROWSER=google-chrome

# Skip the not really helping Ubuntu global compinit
export skip_global_compinit=1

# cache
export XDG_CACHE_HOME=$HOME/.cache

# lang
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

# Term options
# terminfo directory: ${HOME}/.terminfo
# then /etc/terminfo
# then /lib/terminfo
# then /usr/share/terminfo
export TERMINFO="/lib/terminfo"
# Only set TERM if not already set to a meaningful value (preserve TERM=dumb from tools)
[[ -z "$TERM" || "$TERM" == "unknown" || "$TERM" == "linux" ]] && export TERM="xterm-256color"
export KEYTIMEOUT=20
export CLIPBOARD="$HOME/.clipboard"

# ld library
export LD_LIBRARY_PATH="/usr/lib"
export LD_LIBRARY_PATH="/usr/lib64:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/usr/local/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/usr/local/lib64:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/opt/gcc-15/lib64:$LD_LIBRARY_PATH"

# pkg config
export PKG_CONFIG_PATH="/usr/lib/pkgconfig"
export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_PATH="/usr/local/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_PATH="/usr/share/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_PATH="/usr/local/share/pkgconfig:$PKG_CONFIG_PATH"

# cursor
export XCURSOR_PATH="$HOME/.local/share/icons"
export XCURSOR_SIZE=16
export XCURSOR_THEME=Vimix
export WLR_NO_HARDWARE_CURSORS=1

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

# nvidai
# export LIBVA_DRIVER_NAME=nvidia
# export GBM_BACKEND=nvidia-drm
# export __GLX_VENDOR_LIBRARY_NAME=nvidia

# qt
export QT_QPA_PLATFORM='wayland;xcb'
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

# update HYPRLAND_INSTANCE_SIGNATURE (only in interactive sessions)
if [[ -o interactive && -d "$XDG_RUNTIME_DIR/hypr" ]]; then
  export HYPRLAND_INSTANCE_SIGNATURE="$(/usr/bin/ls -t "$XDG_RUNTIME_DIR/hypr" | head -n1)"
fi

# ensure display (only in interactive sessions, ps can block in sandboxed envs)
export DISPLAY="$(pgrep -a Xwayland | grep -o ':[0-9]*')"

# local path
export PATH="$HOME/.local/bin:$PATH"

# custom
[[ -f ~/.custom.zsh ]] && source ~/.custom.zsh || touch ~/.custom.zsh

