#!/usr/bin/env zsh

CONFIG_PATH="$HOME/.cache/foot.ini"
THEME_NAME="$(ls $HOME/.config/foot/themes/ | shuf -n 1)"

cat $HOME/.config/foot/foot.ini $HOME/.config/foot/themes/$THEME_NAME > $CONFIG_PATH
foot --title "foot-$THEME_NAME" --config $CONFIG_PATH &

