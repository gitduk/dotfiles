####################### Global Options #######################
zstyle ':completion:*' completer _complete _extensions _match _approximate
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zcompcache"
zstyle ':completion:*' file-sort modification
zstyle ':completion:*' file-patterns '*(.) *(/)'
zstyle ':completion:*' menu select=2
zstyle ':completion:*' verbose yes
zstyle ':completion:*' follow-links true
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' complete-options true
zstyle ':completion:*' keep-prefix true
zstyle ':completion:*' group-name ''
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' ignore-parents '..'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

#################### Matching and Errors ####################
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

#################### Array Completion ####################
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

#################### Case Sensitivity ####################
if zstyle -t ':prezto:module:completion:*' case-sensitive; then
  zstyle ':completion:*' matcher-list 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
  setopt CASE_GLOB
else
  unsetopt CASE_GLOB
fi

#################### Command Completion #####################
zstyle ':completion:complete:*:options' sort false
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:*:-command-:*:*' group-order aliases commands functions builtins

########################### Themes ###########################
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:messages' format '%F{purple} [ %d ]%f'
zstyle ':completion:*:descriptions' format '[ %d ]'
zstyle ':completion:*:corrections' format '%F{yellow}![ %d (errors: %e) ]!%f'
zstyle ':completion:*:warnings' format '%F{red}[ no matches found ]%f'

########################### History ###########################

zstyle ':completion:*:history-words' stop yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' list false 
zstyle ':completion:*:history-words' menu yes

#################### Environment Variables ####################
zstyle ':completion::*:(-command-|export):*' fake-parameters ${${${_comps[(I)-value-*]#*,}%%,*}:#-*-}

##################### Command Specifics #####################
# ssh
zstyle ':completion:*:ssh:*' group-order users hosts-host hosts-ipaddr hosts-domain
zstyle ':completion:*:ssh:*' tag-order 'users:-user:user hosts:-host:host hosts:-ipaddr:ip\ address hosts:-domain:domain *'
zstyle ':completion:*:ssh:*' ignored-patterns '*[0-9a-fA-F]:*:*|::1'
zstyle -e ':completion::*:*:*:hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

# scp/rsync  
zstyle ':completion:*:(scp|rsync):*' group-order files all-files users hosts-host hosts-ipaddr hosts-domain
zstyle ':completion:*:(scp|rsync):*' tag-order 'users:-user:user hosts:-host:host hosts:-ipaddr:ip\ address hosts:-domain:domain *'

