#!/usr/bin/env zsh

pidof copyq || copyq --start-server &

copyq show

