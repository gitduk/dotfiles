#!/usr/bin/env zsh

# read urls from rules.txt
urls=($(cat "rules.txt"))

# download rules
wget -P ./rules/ -N "${urls[@]}"

