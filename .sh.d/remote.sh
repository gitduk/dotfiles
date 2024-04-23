#!/usr/bin/env zsh

while true; do
  sleep 60
  ssh sv "cat $HOME/.remote.sh" | zsh
done

