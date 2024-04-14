#!/usr/bin/env zsh

local snumber
snumber=$(tmux list-sessions | wc -l)

if [[ $snumber -gt 1 ]];then
  printf ":%d" $snumber
else
  echo -n ""
fi

