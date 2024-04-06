#!/usr/bin/env bash

uptime=$(uptime -p | sed -e 's/up //g')

# Options
shutdown="Shutdown"
reboot="Reboot"
lock="Lock"
suspend="Sleep"
logout="Logout"

# Variable passed to rofi
options="$shutdown\n$reboot\n$suspend\n$lock\n$logout"

chosen="$(echo -e "$options" | $HOME/.local/bin/fzf --cycle --header "Up: $uptime")"
case $chosen in
  $shutdown) systemctl poweroff ;;
  $reboot) systemctl reboot ;;
  $lock) i3lock ;;
  $suspend)
    mpc -q pause
		amixer set Master mute
		systemctl suspend
    ;;
  $logout)
    if [[ "$DESKTOP_SESSION" == "Openbox" ]]; then
      openbox --exit
    elif [[ "$DESKTOP_SESSION" == "bspwm*" ]]; then
      bspc quit
    elif [[ "$DESKTOP_SESSION" = i3* ]]; then
      i3-msg exit
    fi
    ;;
esac
