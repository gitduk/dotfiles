#!/usr/bin/env zsh

##############
### waybar ###
##############

killall waybar &>/dev/null

# wait waybar killed
if [[ $? -eq 0 ]]; then
  sleep 0.1
fi

waybar &
