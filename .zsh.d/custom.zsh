############
### pnpm ###
############

export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

###########
### fzf ###
###########

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
  --bind 'ctrl-p:toggle-preview'
  --cycle --ansi
"

##########
### Qt ###
##########

QT_VERSION="6.9.1"
if [[ -d "$HOME/.local/share/Qt/$QT_VERSION" ]]; then
  export QT_ROOT="$HOME/.local/share/Qt/$QT_VERSION"
  export PATH="$QT_ROOT/gcc_64/bin:$PATH"
  export Qt6_DIR="$QT_ROOT/gcc_64/lib/cmake/Qt6"
  export LD_LIBRARY_PATH="$QT_ROOT/gcc_64/lib:$LD_LIBRARY_PATH"
fi

