#!/usr/bin/env zsh

##############
### waybar ###
##############

killall waybar &>/dev/null
sleep 0.2 && waybar &
