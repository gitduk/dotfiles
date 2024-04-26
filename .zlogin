# launch hyprland

if [[ -z "$DISPLAY" ]]; then
  pgrep hyprland &>/dev/null || exec hyprland
fi

