#!/usr/bin/env zsh

# Kill already running processes
_ps=(waybar swaync ags tofi)
for _prs in "${_ps[@]}"; do
  if pidof "${_prs}" >/dev/null; then
    pkill "${_prs}"
  fi
done

# quit ags
ags -q

# Relaunch waybar
waybar &

# relaunch swaync
swaync > /dev/null 2>&1 &

# relaunch ags
ags &

exit 0

