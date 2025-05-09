#!/usr/bin/env zsh

cliphist list \
  | fzf --no-sort \
    --bind "D:execute-silent(echo {+} | cliphist delete)+reload(cliphist list)" \
    --bind "C:execute-silent(cliphist wipe)+reload(cliphist list)" \
  | cliphist decode | wl-copy

