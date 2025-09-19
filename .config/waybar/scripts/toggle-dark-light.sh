#!/usr/bin/env bash

css_file="$HOME/.config/waybar/colors.css"

sed -i -e 's/foreground/__TMP__/g' -e 's/background/foreground/g' -e 's/__TMP__/background/g' $css_file
