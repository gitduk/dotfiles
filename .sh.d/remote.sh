#!/usr/bin/env zsh

while true; do
  ssh sv "cat $HOME/.remote.sh" | zsh
  sleep 60
done

