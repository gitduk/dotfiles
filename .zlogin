# launch hyprland

if [[ "$TTY" == "/dev/tty1" && -z "$DISPLAY" ]]; then
  pgrep hyprland &>/dev/null || exec hyprland
fi

