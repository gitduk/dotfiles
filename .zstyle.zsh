# https://thevaluable.dev/zsh-completion-guide-examples/
# :completion:<function>:<completer>:<command>:<argument>:<tag>
# function - Apply the style to the completion of an external function or widget.
# completer - Apply the style to a specific completer. We need to drop the underscore from the completer’s name here.
# command - Apply the style to a specific command, like cd, rm, or sed for example.
# argument - Apply the style to the nth option or the nth argument. It’s not available for many styles.
# tag - Apply the style to a specific tag.

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
zstyle ':completion:complete:*:options' sort false
zstyle ':history-beginning-search:*' search true

# Increase the number of errors based on the length of the typed word. But make
# sure to cap (at 7) the max-errors to avoid hanging.
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'

# Don't complete unavailable commands.
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

# Array completion element sorting.
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# Case-insensitive (all), partial-word, and then substring completion.
if zstyle -t ':prezto:module:completion:*' case-sensitive; then
  zstyle ':completion:*' matcher-list 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
  setopt CASE_GLOB
else
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
  unsetopt CASE_GLOB
fi

zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:*:-command-:*:*' group-order aliases commands functions builtins

########################### Themes ###########################
# set descriptions format to enable group support
# %d - description
# %F{<color>} %f - Change the foreground color with <color>.
# %K{<color>} %k - Change the background color with <color>.
# %B %b - Bold.
# %U %u - Underline.
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

##################### Command Completion #####################

# ssh
zstyle ':completion:*:ssh:*' group-order users hosts-host hosts-ipaddr hosts-domain
zstyle ':completion:*:ssh:*' tag-order 'users:-user:user hosts:-host:host hosts:-ipaddr:ip\ address hosts:-domain:domain *'
zstyle ':completion:*:ssh:*' ignored-patterns '*[0-9a-fA-F]:*:*|::1'

zstyle -e ':completion::*:*:*:hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

# scp/rsync
zstyle ':completion:*:(scp|rsync):*' group-order files all-files users hosts-host hosts-ipaddr hosts-domain
zstyle ':completion:*:(scp|rsync):*' tag-order 'users:-user:user hosts:-host:host hosts:-ipaddr:ip\ address hosts:-domain:domain *'

# Kill
zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,command -w'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*' insert-ids single

# Man
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true
zstyle ':completion:*:man:*' menu yes select

# cd
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'

# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
