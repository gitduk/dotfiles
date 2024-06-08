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
export QT_IM_MODULE=fcitx5

# fcitx input-related
export GLFW_IM_MODULE=fcitx5
export GTK_IM_MODULE=fcitx5
export SDL_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx5
export IMSETTINGS_MODULE=fcitx5
export INPUT_METHOD=fcitx5

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

