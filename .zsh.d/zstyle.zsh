###############
### OPTIONS ###
###############
# Core completion system configuration
zstyle ':completion:*' completer _complete _approximate _ignored
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zcompcache"

# File and directory completion
zstyle ':completion:*' file-sort modification
zstyle ':completion:*' file-patterns '*(@) *(.) *(/)'
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' follow-links true
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' ignore-parents parent pwd
zstyle ':completion:*' accept-exact-dirs true
zstyle ':completion:*' accept-exact false

# Interactive and display settings
zstyle ':completion:*' menu select=1
zstyle ':completion:*' verbose yes
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} 'ln=target' 'or=31' 'mi=31'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' keep-prefix true
zstyle ':completion:*' complete-options true

####################################
### Matching and Error Tolerance ###
####################################
# Smart case and fuzzy matching
zstyle ':completion:*' matcher-list '' \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'

# Error tolerance (allow up to 1/3 input errors)
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3))numeric)'

# Ignore certain completions
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

##############################
### Appearance and Theming ###
##############################
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:messages' format '%F{purple} [ %d ]%f'
zstyle ':completion:*:descriptions' format '[ %d ]'
zstyle ':completion:*:corrections' format '%F{yellow}![ %d (errors: %e) ]!%f'
zstyle ':completion:*:warnings' format '%F{red}[ no matches found ]%f'

###############
### History ###
###############
zstyle ':completion:*:history-words' stop yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' list false 
zstyle ':completion:*:history-words' menu yes

########################################
### Environment Variable Completions ###
########################################
zstyle ':completion::*:(-command-|export):*' fake-parameters ${${${_comps[(I)-value-*]#*,}%%,*}:#-*-}

#####################################
### Command Ordering and Priority ###
#####################################
zstyle ':completion:*:*:-command-:*:*' group-order aliases commands functions builtins

# Command option sorting
zstyle ':completion:complete:*:options' sort false
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*:match:*' original only

####################################
### Command-Specific Completions ###
####################################
# Process completion
zstyle ':completion:*:processes' command 'ps -au$(whoami) -o user,pid,cmd'
zstyle ':completion:*:processes-names' command 'ps -u $(whoami) -eo comm='
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:killall:*' menu yes select
zstyle ':completion:*:killall:*' force-list always

# SSH completions
zstyle ':completion:*:ssh:*' group-order hosts-host hosts-ipaddr hosts-domain users
zstyle ':completion:*:ssh:*' tag-order 'hosts:-host:host hosts:-ipaddr:ipaddr hosts:-domain:domain users:-user:user'
zstyle ':completion:*:ssh:*' ignored-patterns '*:[0-9a-fA-F]*:*' '::1' 'ip6*'

# SCP/RSYNC completions
zstyle ':completion:*:(scp|rsync):*' group-order files all-files hosts-host hosts-ipaddr hosts-domain users
zstyle ':completion:*:(scp|rsync):*' tag-order 'hosts:-host:host hosts:-ipaddr:ipaddr hosts:-domain:domain users:-user:user *'
zstyle ':completion:*:(scp|rsync):*' ignored-patterns '*:[0-9a-fA-F]*:*' '::1' 'ip6*'

# Docker
zstyle ':completion:*:*:docker*:*' option-stacking yes

# Directory navigation
zstyle ':completion:*:cd:*' tag-order local-directories path-directories

# Improved soft link and file type completion
zstyle ':completion:*:*:ls:*' file-patterns \
  '*(@):symbolic-links:symlink' \
  '*(#q/):directories:directory' \
  '*(#q.):files:file'

########################
### zsh-autocomplete ###
########################

# Pass arguments to compinit
zstyle '*:compinit' arguments -D -i -u -C -w

# all Tab widgets
zstyle ':autocomplete:*complete*:*' insert-unambiguous yes

# all history widgets
zstyle ':autocomplete:*history*:*' insert-unambiguous yes

# ^S
zstyle ':autocomplete:menu-search:*' insert-unambiguous yes

# Customize common substring message
zstyle ':autocomplete:*:unambiguous' format \
  $'%{\e[0;2m%}%Bcommon substring:%b %0F%11K%d%f%k'

# Wait for a minimum amount of input
zstyle ':autocomplete:*' min-input 2

# Don't show completions if the current word matches a pattern
# zstyle ':autocomplete:*' ignored-input ''

# $LINES is the number of lines that fit on screen.
zstyle -e ':autocomplete:*:*' list-lines 'reply=( $(( LINES / 3 )) )'

# Override for recent path search only
zstyle ':autocomplete:recent-paths:*' list-lines 10

# Override for history search only
zstyle ':autocomplete:history-incremental-search-backward:*' list-lines 8

# Override for history menu only
zstyle ':autocomplete:history-search-backward:*' list-lines 2000

###############################################
### Performance and experience optimization ###
###############################################

# Speed up completion in large directories
zstyle ':completion:*' max-errors 2 not-numeric

# Avoid blocking in large directories
zstyle ':completion:*' insert-tab pending

# Better sorting
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"

# Improved completion sorting
zstyle ':completion:*:*:*:*:*' menu select=2

# Set different completion behaviors for different file types
zstyle ':completion:*:*:v:*:*files' ignored-patterns \
  '*.o' '*.so' '*.a' '*.pyc' '*.pyo' '*.class' '*.jar' '*.war' '*.ear'

# Better network completion
zstyle ':completion:*:*:*:hosts' hosts-ports true

