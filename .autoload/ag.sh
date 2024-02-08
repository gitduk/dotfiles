#!/usr/bin/env zsh

read -r file line <<<"$(ag --nobreak --noheading $@ | fzf -0 -1 | awk -F: '{print $1, $2}')"

if [[ -n $file ]]; then
	nvim $file +$line
fi
