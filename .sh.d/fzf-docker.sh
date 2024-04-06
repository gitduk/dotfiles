#!/usr/bin/env zsh

source $HOME/.fzf-custom.zsh &>/dev/null

RELOAD="reload(docker container ls -a)"
START="execute(echo {} | choose 0 | xargs docker container start)+$RELOAD"
STOP="execute(echo {} | choose 0 | xargs docker container stop)+$RELOAD"
DELETE="execute(echo {} | choose 0 | xargs docker continer rm)+$RELOAD"
RESTART="execute(echo {} | choose 0 | xargs docker container restart)+$RELOAD"
INSPECT="execute(echo {} | choose 0 | xargs docker container inspect | batcat)"

docker container ls -a | fzf --layout=reverse \
  --bind "enter:$START" \
  --bind "ctrl-r:$RELOAD" \
  --bind "S:$STOP" \
  --bind "R:$RESTART" \
  --bind "D:$DELETE" \
  --bind "I:$INSPECT"

