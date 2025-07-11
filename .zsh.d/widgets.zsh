###############
### Widgets ###
###############
# Guide: https://thevaluable.dev/zsh-line-editor-configuration-mouseless/
# Manual: https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html#Zle-Widgets

# bindkey quickly
function zbindkey {
  eval wid_name=\$$#
  zle -N $wid_name
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
    apt-cache search . | fzf --query=$LBUFFER --multi --prompt="pkgs> " \
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

###########################
### fzf-services-widget ###
###########################

function fzf-services-widget {
  selected_service=$({
    systemctl --user list-units --no-pager --type=service --no-legend --all
    systemctl --system list-units --no-pager --type=service --no-legend --all
  } | while read -r raw; do
    if [[ "$raw" = ●* ]]; then
      stat="✘"
      read _ name load active run comment <<<"$(echo "$raw" | awk '{print $1, $2, $3, $4, $5}')"
    else
      stat="✔"
      read name load active run comment <<<"$(echo "$raw" | awk '{print $1, $2, $3, $4, $5}')"
    fi
    [[ ${#name} -gt 30 ]] && name="${name:0:28}.."
    printf "%s %-30s %-10s %-10s %-10s %s\n" $stat $name $load $active $run $comment
  done | fzf --exact --preview 'systemctl status $(cut -d " " -f2 <<< "{}") 2>/dev/null || systemctl --user status $(cut -d " " -f2 <<< "{}")')
}

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

##########################
### expand-alias-space ###
##########################

baliases=()
function balias() {
  alias $@
  args="$@"
  args=${args%%\=*}
  baliases+=(${args##* })
}

ialiases=()
function ialias() {
  alias $@
  args="$@"
  args=${args%%\=*}
  ialiases+=(${args##* })
}

function expand-alias-space() {
  [[ $LBUFFER =~ "\<(${(j:|:)baliases})\$" ]]; insertBlank=$?
  if [[ ! $LBUFFER =~ "\<(${(j:|:)ialiases})\$" ]]; then
    zle _expand_alias
  fi
  zle self-insert
  if [[ "$insertBlank" = "0" ]]; then
    zle backward-delete-char
  fi
}

#########################
### lazy-space-widget ###
#########################

# lazy loader
function lazy-space-widget() {
  # check if lazy_map is empty
  if [[ ${#lazy_map[@]} -gt 0 ]]; then
    local buffer="$BUFFER"
    local key; for key in ${(k)lazy_map}; do
      if [[ "$buffer" == "$key" && -z "${__lazy_injected[$key]}" ]]; then
        eval "${lazy_map[$key]}"
        __lazy_injected[$key]=1
        # zle -M "✨ Lazy alias loaded for: $key"
        break
      fi
    done
  fi
}

####################
### space-widget ###
####################

function space-widget() {
  lazy-space-widget
  expand-alias-space
}
zbindkey ' ' space-widget
