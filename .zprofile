# browser
export BROWSER=google-chrome

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

# fcitx5 input-related
# Note: GTK_IM_MODULE should NOT be set in Wayland - use wayland input method frontend
export XMODIFIERS=@im=fcitx5
export QT_IM_MODULE=fcitx5
export SDL_IM_MODULE=fcitx5

# xdg
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=hyprland
export XDG_CURRENT_DESKTOP=hyprland

