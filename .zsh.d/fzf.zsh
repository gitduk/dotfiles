###########
### fzf ###
###########

# fzf shell integration (key bindings + path completion via ** trigger)
eval "$(fzf --zsh)"
# fzf --zsh overwrites ^R; restore atuin's binding
bindkey -M emacs '^r' atuin-search
bindkey -M viins '^r' atuin-search-viins

# fzf default command
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow \
  --exclude .git \
  --exclude .venv \
  --exclude venv \
  --exclude node_modules \
  2>/dev/null || find . -type f"

# fzf default opts
export FZF_DEFAULT_OPTS="
  --preview 'bat --color=always --style=numbers --line-range=:500 {}'
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
  --bind 'ctrl-p:toggle-preview'
  --cycle --ansi --exact
"
