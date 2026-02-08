# Only start Hyprland from a real VT login, not from tools/scripts
if [[ -z "$DISPLAY" && "${XDG_VTNR}" -eq 1 && -t 0 && -t 1 ]]; then
  if ! pgrep -x Hyprland &>/dev/null; then
    rm -rf "$XDG_RUNTIME_DIR/hypr"/* 2>/dev/null
    exec start-hyprland
  fi
fi
