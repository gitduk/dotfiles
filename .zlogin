# launch hyprland

if [[ -z "$DISPLAY" ]]; then
  pgrep hyprland || exec hyprland
fi

