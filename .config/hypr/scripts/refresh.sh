#!/usr/bin/env zsh

############
### tofi ###
############

pkill tofi &>/dev/null

###########
### ags ###
###########

killall ags &>/dev/null
ags &

##############
### waybar ###
##############

killall waybar &>/dev/null
waybar &

