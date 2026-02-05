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
zstyle ':completion:*' complete-options true

####################################
### Matching and Error Tolerance ###
####################################
# Smart case and fuzzy matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'

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

###############################################
### Performance and experience optimization ###
###############################################

# Speed up completion in large directories
zstyle ':completion:*' max-errors 2 not-numeric

# Better sorting
zstyle ':completion:*:*:*:*:*' menu select=2

# Set different completion behaviors for different file types
zstyle ':completion:*:*:v:*:*files' ignored-patterns \
  '*.o' '*.so' '*.a' '*.pyc' '*.pyo' '*.class' '*.jar' '*.war' '*.ear'

# Better network completion
zstyle ':completion:*:*:*:hosts' hosts-ports true

