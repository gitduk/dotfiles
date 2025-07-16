#!/bin/bash

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
cache_file="${cache_dir}/color-scheme.icon"

mkdir -p $cache_dir

current=$(gsettings get org.gnome.desktop.interface color-scheme | tr -d "'")

if [[ "$current" == "prefer-dark" ]]; then
  gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
  echo "󰖔" | tee $cache_file
else
  gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
  echo "󰖨" | tee $cache_file
fi
