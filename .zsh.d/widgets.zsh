# ###  Widgets  ###############################################################
# Guide: https://thevaluable.dev/zsh-line-editor-configuration-mouseless/
# Manual: https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html#Zle-Widgets

function cursor_mode() {
  # See https://ttssh2.osdn.jp/manual/4/en/usage/tips/vim.html for cursor shapes
  cursor_block='\e[2 q'
  cursor_beam='\e[6 q'

  function zle-keymap-select {
    if [[ ${KEYMAP} == vicmd ]] ||
      [[ $1 = 'block' ]]; then
      echo -ne $cursor_block
    elif [[ ${KEYMAP} == main ]] ||
      [[ ${KEYMAP} == viins ]] ||
      [[ ${KEYMAP} = '' ]] ||
      [[ $1 = 'beam' ]]; then
      echo -ne $cursor_beam
    fi
  }

  zle-line-init() {
    echo -ne $cursor_beam
  }

  zle -N zle-keymap-select
  zle -N zle-line-init
}

# copy to system clipboard
function vi-yank-copy {
   zle vi-yank
   echo "$CUTBUFFER" | tr -d '\n' | wl-copy
}

function fzf-alias-widget {
  cmd=$(grep -Ev '^#|^$' < $HOME/.alias.zsh | cut -b 7- | awk -F '=' '{printf "%-6s=%s\n",$1,$2}' | sed -e 's/=\"/¦ /' -e 's/"$//' | fzf --prompt="alias> " --query=$LBUFFER)
  if [ -n "$cmd" ]; then
    BUFFER="$(awk -F '¦ ' '{print $2" "}' <<< "$cmd")"
  fi
  zle reset-prompt
  zle end-of-line
}

function fzf-apt-widget {
  package=$(apt-cache search . | fzf --query=$LBUFFER --multi --prompt="pkgs> " \
    --header="U:upgradable I:installed R:reload Enter:copy" \
    --bind="U:reload(apt list --upgradable|sed '1d')" \
    --bind="I:reload(apt list --installed|sed '1d')" \
    --bind="R:reload(apt-cache search .)"
  )
  echo $package | awk '{printf $1}' | xargs echo -n | wl-copy
  zle reset-prompt
  zle vi-add-eol
}

function fzf-commands-widget {
  cmd_path="$(zsh -c "$HOME/.sh/fzf-commands.sh $LBUFFER")"
  if [ -n "$cmd_path" ]; then
    BUFFER="$(awk -F '/' '{printf "%s ", $NF}' <<< $cmd_path)"
  fi
  zle reset-prompt
  zle end-of-line
}

function fzf-bindkeys-widget {
  fzf --prompt="bindkeys> " --query=$LBUFFER <<< "$(bindkey | tr -d '"' | awk '{printf "%-12s| %s\n",$1,$2}')"
  zle reset-prompt
  zle end-of-line
}

function space-widget {
  BUFFER="$BUFFER "
  zle reset-prompt
  zle end-of-line
}

function _navi_call {
  local result="$(navi "$@" </dev/tty)"
  printf "%s" "$result"
}

function _navi_widget {
  local -r input="${LBUFFER}"
  local -r last_command="$(echo "${input}" | navi fn widget::last_command)"
  local replacement="$last_command"

  if [ -z "$last_command" ]; then
    replacement="$(_navi_call --print)"
  elif [ "$LASTWIDGET" = "_navi_widget" ] && [ "$input" = "$previous_output" ]; then
    replacement="$(_navi_call --print --query "$last_command")"
  else
    replacement="$(_navi_call --print --best-match --query "$last_command")"
  fi

  if [ -n "$replacement" ]; then
    local -r find="${last_command}_NAVIEND"
    previous_output="${input}_NAVIEND"
    previous_output="${previous_output//$find/$replacement}"
  else
    previous_output="$input"
  fi

  zle kill-whole-line
  LBUFFER="${previous_output:+$previous_output }"
  region_highlight=("P0 100 bold")
  zle redisplay
  # zle accept-line
}

function fzf-pip-list-widget {
  package=$(curl -s https://pypi.org/simple/ | tail -n +7 | sed 's/<[^>]*>//g' | sed 1d | fzf --query=$LBUFFER --prompt="pip pkgs> " --multi  \
    --bind="I:reload(pip list | sed 1,2d)" \
    --bind="L:reload(curl -s https://pypi.org/simple/ | tail -n +7 | sed 's/<[^>]*>//g')" \
    --bind="R:execute(echo 'uninstall')+accept")

  result=$(awk -F '{printf "%s ",$1}') <<< $package

  if [ -n "${result// /}" ];then
    [[ ! "$result" =~ "uninstall" ]] && result="install $result"
    BUFFER="pip $result"
  fi

  zle reset-prompt
  zle end-of-line
  zle accept-line
}

function fzf-kill-widget {
  result=`ps -u $LOGNAME -o pid,user,command -w | fzf`
  pid=`echo $result | awk '{printf $1}'`
  msg=`echo $result | awk '{printf $3}':`
  [[ -n "$pid" ]] && BUFFER="kill $pid # $msg"
  zle reset-prompt
  zle accept-line
}

# ###  Keybinding  ############################################################

# bindkey quickly
function zbindkey {
  eval wid_name=\$$#
  zle -N $wid_name
  bindkey $*
}

# autoload
autoload -U edit-command-line

# zbindkey cmd
zbindkey -M vicmd 'Y' vi-yank-copy
zbindkey -M vicmd 'L' fzf-apt-list-widget
zbindkey -M vicmd 'P' fzf-pip-list-widget
zbindkey -M vicmd 'K' fzf-kill-widget
zbindkey -M vicmd 'e' edit-command-line
zbindkey -M vicmd '^w' backward-delete-word

# zbindkey ins
zbindkey -M viins " " expand-alias-space
zbindkey -M viins '^T' fzf-apt-widget
zbindkey -M viins '^N' _navi_widget
zbindkey -M viins '^_' fzf-commands-widget
zbindkey -M viins '^B' fzf-bindkeys-widget
