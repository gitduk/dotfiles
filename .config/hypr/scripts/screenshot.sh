#!/usr//bin/env zsh

if [[ $1 == "copy" ]]; then
  flameshot gui --raw | wl-copy
else
  flameshot gui || grim -t png -g "$(slurp)" - | swappy -f -
fi

