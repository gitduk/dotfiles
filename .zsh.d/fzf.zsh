#!/usr/bin/env

# fzf default command
if (( $+commands[fd] )); then
  export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow \
    --exclude .git \
    --exclude .venv \
    --exclude venv \
    --exclude node_modules"
fi

# fzf preview command
if (( $+commands[bat] )); then
  preview="--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
else
  preview="--preview 'head -200 {}'"
fi

# fzf default opts
export FZF_DEFAULT_OPTS="
  $preview
  --preview-window=right:50%:wrap
  --height 100%
  --bind 'ctrl-k:up'
  --bind 'ctrl-j:down'
  --bind 'ctrl-e:last'
  --bind 'ctrl-a:first'
  --bind 'ctrl-w:backward-kill-word'
  --bind 'ctrl-f:page-down'
  --bind 'ctrl-b:page-up'
  --bind 'ctrl-u:half-page-up'
  --bind 'ctrl-d:half-page-down'
  --cycle --ansi
"
