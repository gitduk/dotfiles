# ###  Unbindkey  #############################################################

bindkey -rpM viins "^J"

# ###  Zsh keybind  ###########################################################
# look: https://thevaluable.dev/zsh-line-editor-configuration-mouseless/#:~:text=backward%20for%20example.-,Zsh%20Keymaps,-To%20understand%20how
# `xev` to show key name
# `showkey -a` to show keys
# `bindkey ^I` to show Ctrl-I bind function

# "^[^M" alt+enter
# "^[\t" alt+tab

# vim ins
bindkey -M viins "^h" backward-delete-char
bindkey -M viins "^w" backward-kill-word
bindkey -M viins "^f" vi-forward-char
bindkey -M viins "jk" vi-cmd-mode

# execute command
# bindkey -s '^semicolon' 'xclip -selection clipboard <<< "$(greenclip print|fzf --prompt="clipboard> ")"^M'

# ###  Plugin keybind  ########################################################

# zsh-autosuggestions
bindkey -M viins "^q" autosuggest-clear
bindkey -M viins "^@" autosuggest-execute
bindkey -M vicmd "^@" autosuggest-execute

# zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[OA' history-substring-search-up
bindkey '^k' history-substring-search-up
bindkey '^j' history-substring-search-down

