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

# update HYPRLAND_INSTANCE_SIGNATURE
if [[ -d "$XDG_RUNTIME_DIR/hypr" ]]; then
  export HYPRLAND_INSTANCE_SIGNATURE="$(ls $XDG_RUNTIME_DIR/hypr | tail -n 1)"
fi
