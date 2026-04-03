###############
### Widgets ###
###############
# Guide: https://thevaluable.dev/zsh-line-editor-configuration-mouseless/
# Manual: https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html#Zle-Widgets

# bindkey quickly
function zbindkey {
  zle -N ${(P)#}
  bindkey $*
}
zbindkey -M vicmd 'e' edit-command-line

####################
### vi-yank-copy ###
####################

# copy to system clipboard
function vi-yank-copy {
  zle vi-yank
  echo -n "$CUTBUFFER" | wl-copy
}
zbindkey -M vicmd 'Y' vi-yank-copy

###########################
### fzf-bindkeys-widget ###
###########################

# list Keybindings
function fzf-bindkeys-widget {
  fzf --prompt="bindkeys> " --query=$LBUFFER <<<"$(bindkey | tr -d '"' | awk '{printf "%-12s| %s\n",$1,$2}')"
  zle reset-prompt
  zle end-of-line
}
zbindkey -M viins '^B' fzf-bindkeys-widget

##########################
### fzf-crontab-widget ###
##########################

function fzf-crontab-widget {
  crontab -l | grep -Ev "^#|^$|^[a-zA-Z]" | sort | fzf | while read -r raw; do
    raw=${raw//\*/\\*}
    task="$(echo $raw | sed -n 's/\\\*/*/g;p')"
    read _ _ _ _ _ command <<<$task
    [[ -z "$command" ]] && continue
    zsh <<<$command
  done
}

##############################
### backward-delete-widget ###
##############################

function backward-delete-widget() {
  local WORDCHARS=${WORDCHARS//[\/:=.]/}
  zle backward-delete-word
}
zbindkey -M viins '^W' backward-delete-widget

####################
### space-widget ###
####################

function space-widget() {
  zle _expand_alias
  zle self-insert
}
zbindkey ' ' space-widget

