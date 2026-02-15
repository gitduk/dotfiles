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

######################
### fzf-apt-widget ###
######################

# fzf pkgs
function fzf-apt-widget {
  package=$(
    apt-cache search . | fzf \
      --exact \
      --preview="" \
      --query=$LBUFFER \
      --multi \
      --prompt="pkgs> " \
      --header="U:upgradable I:installed R:reload Enter:copy" \
      --bind="U:reload(apt list --upgradable|sed '1d')" \
      --bind="I:reload(apt list --installed|sed '1d')" \
      --bind="R:reload(apt-cache search .)"
  )
  selected=$(echo $package | awk '{printf $1}' | xargs echo -n)
  if [[ -n "$selected" ]]; then
    echo -n $selected | wl-copy
    if command -v nala &>/dev/null; then
      BUFFER="sudo nala install -y $selected"
    else
      BUFFER="sudo apt install -y $selected"
    fi
  fi
  zle reset-prompt
  zle vi-add-eol
}
zbindkey -M viins '^P' fzf-apt-widget

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

