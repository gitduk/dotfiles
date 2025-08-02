#!/bin/bash

current=$(gsettings get org.gnome.desktop.interface color-scheme | tr -d "'")

case "$current" in
  prefer-dark)
    if [[ $1 == "--toggle" ]]; then
      gsettings set org.gnome.desktop.interface color-scheme "prefer-light"
      echo "󰖨"
    else
      echo "󰖔"
    fi
    ;;
  prefer-light)
    if [[ $1 == "--toggle" ]]; then
      gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
      echo "󰖔"
    else
      echo "󰖨"
    fi
    ;;
  *)
    echo "Unknow status: $current"
  ;;
esac

