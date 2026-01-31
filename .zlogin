# Only start Hyprland from a real VT login, not from tools/scripts
if [[ -z "$DISPLAY" && "${XDG_VTNR}" -eq 1 && -t 0 && -t 1 ]]; then
  pgrep -x Hyprland &>/dev/null || exec Hyprland
fi
