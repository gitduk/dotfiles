# browser
export BROWSER=google-chrome

# XDG session
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland

# Cursor
export XCURSOR_PATH=/home/wukaige/.local/share/icons
export XCURSOR_SIZE=16
export XCURSOR_THEME=Vimix
export WLR_NO_HARDWARE_CURSORS=1

# Qt
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_QPA_PLATFORM="wayland;xcb"
export QT_QPA_PLATFORMTHEME=qt6ct
export QT_SCALE_FACTOR=1
export QT_SCREEN_SCALE_FACTORS="1;1"
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

# GTK/GDK
export GDK_SCALE=1
export GDK_DPI_SCALE=1
export GDK_BACKEND=wayland
export GTK_USE_PORTAL=1

# Wayland backend
export CLUTTER_BACKEND=wayland
export SDL_VIDEODRIVER=wayland

# Firefox
export MOZ_ENABLE_WAYLAND=1
export MOZ_WAYLAND_USE_VAAPI=1
export MOZ_DBUS_REMOTE=1
export MOZ_USE_XINPUT2=1
export MOZ_WEBRENDER=1

# Electron
export ELECTRON_OZONE_PLATFORM_HINT=auto

# Fcitx5
export XMODIFIERS=@im=fcitx5
export QT_IM_MODULE=fcitx5
export SDL_IM_MODULE=fcitx5
export GLFW_IM_MODULE=ibus

