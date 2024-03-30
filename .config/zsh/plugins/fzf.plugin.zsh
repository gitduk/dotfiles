# Set the trigger character for fzf completion
export FZF_COMPLETION_TRIGGER="**"

# Fzf options for completion
export FZF_COMPLETION_OPTS="--border"

# Disable fzf within tmux
export FZF_TMUX=0

# Define the default command for fzf
export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden --exclude .git'

# Set fzf options
export FZF_DEFAULT_OPTS="
  --preview 'batcat --color=always --style=numbers --line-range=:500 {}'
  --preview-window hidden
  --cycle
  --exact
  --multi
  --height 90%
  --tiebreak=index
  --pointer='•'
  --marker='✔'
  --history=$HOME/.fzf.history
  --history-size=10
  --bind 'G:last'
  --bind 'J:half-page-down'
  --bind 'K:half-page-up'
  --bind 'L:jump'
  --bind 'U:toggle-up'
  --bind 'I:toggle-down'
  --bind 'P:toggle-preview'
  --bind 'S:toggle-sort'
  --bind 'Y:execute(echo -n {} | wl-copy)'
  --bind 'ctrl-space:accept'
  --bind 'ctrl-a:toggle-all'
  --bind 'ctrl-c:abort'
  --bind 'ctrl-l:clear-query+deselect-all'
  --bind 'ctrl-n:preview-down'
  --bind 'ctrl-p:preview-up'
  --bind 'ctrl-z:ignore'
"

# Define the path completion function
_fzf_compgen_path() {
  if hash fd 2>/dev/null; then
    fd --hidden --follow --exclude ".git" . "$1"
  else
    # Fallback to find if fd is not available
    find * -type f | grep "$1"
  fi
}

# Define the directory completion function
_fzf_compgen_dir() {
  if hash fd 2>/dev/null; then
    fd --type d --hidden --follow --exclude ".git" . "$1"
  else
    # Fallback to find if fd is not available
    find * -type d | grep "$1"
  fi
}

# Advanced customization of fzf options via _fzf_comprun function
_fzf_comprun() {
  local command=$1
  shift
  case "$command" in
    cd)
      fzf "$@" --preview 'tree -C {} | head -200'
      ;;
    export|unset)
      fzf "$@" --preview "eval 'echo \$'{}"
      ;;
    ssh)
      fzf "$@" --preview 'dig {}'
      ;;
    *)
      fzf "$@"
      ;;
  esac
}

