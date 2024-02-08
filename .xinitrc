#!/bin/sh

# /etc/X11/xinit/xinitrc
#
# global xinitrc file, used by all X sessions started by xinit (startx)
# invoke global X session script

#   —————————————————— Desktop Envs ——————————————————— ₍˄·͈༝·͈˄*₎◞ ̑̑

# export XDG_SESSION_TYPE="wayland"
# export XDG_CONFIG_HOME="$HOME/.config"
# export XDG_DATA_HOME="$HOME/.local/share"
# export XDG_CACHE_HOME="$HOME/.cache"
# export XDG_RUNTIME_DIR=/run/user/$UID
# export XDG_CURRENT_DESKTOP=Unity
# export GDK_BACKEND="wayland"

# locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8",
export LC_CTYPE="zh_CN.UTF-8",

# input
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS="@im=fcitx"

#   —————————————————————— Exec ——————————————————————— ₍˄·͈༝·͈˄*₎◞ ̑̑
# . /etc/X11/Xsession
exec i3

