#!/usr/bin/env zsh

# use slop and xdotool to visually resize the focused window

IFS='x+' read -r w h x y <<< "$(slop -b 5 -l -c 0.3,0.4,0.6,0.4)"

i3-msg floating enable 

# resize
winid="$(xdotool getactivewindow)"
xdotool windowsize $winid $w $h

# move
xwininfo -id $winid | grep 'Corners' | IFS='+ ' read -Ar S
X=$(( $x - ${S[2]} ))
Y=$(( $y - ${S[3]} ))

if [[ $X -lt 0 ]]; then
  i3-msg move left "$(( $X * -1 ))"
else
  i3-msg move right $X
fi

if [[ $Y -lt 0 ]]; then
  i3-msg move up "$(( $Y * -1 ))"
else
  i3-msg move down $Y
fi

