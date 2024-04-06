#!/usr/bin/env zsh

greenclip print | grep -Ev "^w.*@$" | fzf -e --prompt="clipboard> " | xargs echo -n | xsel -b

