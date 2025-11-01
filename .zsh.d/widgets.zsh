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
  # Helper function to format services and timers - includes both loaded and unit files
  function _format_services() {
    local scope="$1"

    {
      # Get all loaded services and timers
      systemctl $scope list-units --no-pager --type=service,timer --no-legend --all

      # Get unloaded service files
      systemctl $scope list-unit-files --no-pager --type=service --no-legend | while read -r name state preset; do
        [[ -z "$name" ]] && continue
        if ! systemctl $scope list-units --no-pager --type=service,timer --no-legend --all 2>/dev/null | grep -q "^[●○*]\? *$name"; then
          printf "○ %s not-loaded inactive dead %s\n" "$name" "$state"
        fi
      done

      # Get unloaded timer files
      systemctl $scope list-unit-files --no-pager --type=timer --no-legend | while read -r name state preset; do
        [[ -z "$name" ]] && continue
        if ! systemctl $scope list-units --no-pager --type=service,timer --no-legend --all 2>/dev/null | grep -q "^[●○*]\? *$name"; then
          printf "○ %s not-loaded inactive dead %s\n" "$name" "$state"
        fi
      done
    } | while read -r raw; do
      [[ -z "$raw" ]] && continue

      # Determine unit type and status icon
      if [[ "$raw" = ●* ]]; then
        stat="✘"
        read _ name load active run comment <<<"$(echo "$raw" | awk '{print $1, $2, $3, $4, $5}')"
      elif [[ "$raw" = ○* ]]; then
        stat="○"
        read _ name load active run comment <<<"$(echo "$raw" | awk '{print $1, $2, $3, $4, $5}')"
      else
        stat="✔"
        read name load active run comment <<<"$(echo "$raw" | awk '{print $1, $2, $3, $4, $5}')"
      fi

      [[ ${#name} -gt 28 ]] && name="${name:0:26}.."
      printf "%s %-28s %-10s %-10s %-10s %s\n" $stat $name $load $active $run $comment
    done
  }

  # Create temporary scripts for S/U key bindings
  local tmpdir=$(mktemp -d)
  local user_script="$tmpdir/user_services.sh"
  local system_script="$tmpdir/system_services.sh"

  # Create user services reload script
  cat > "$user_script" << 'EOF'
#!/bin/bash
{
  systemctl --user list-units --no-pager --type=service,timer --no-legend --all
  systemctl --user list-unit-files --no-pager --type=service --no-legend | while read -r name state preset; do
    [[ -z "$name" ]] && continue
    if ! systemctl --user list-units --no-pager --type=service,timer --no-legend --all 2>/dev/null | grep -q "^[●○*]\? *$name"; then
      printf "○ %s not-loaded inactive dead %s\n" "$name" "$state"
    fi
  done
  systemctl --user list-unit-files --no-pager --type=timer --no-legend | while read -r name state preset; do
    [[ -z "$name" ]] && continue
    if ! systemctl --user list-units --no-pager --type=service,timer --no-legend --all 2>/dev/null | grep -q "^[●○*]\? *$name"; then
      printf "○ %s not-loaded inactive dead %s\n" "$name" "$state"
    fi
  done
} | while read -r raw; do
  [[ -z "$raw" ]] && continue
  if [[ "$raw" = ●* ]]; then
    stat="✘"
    read _ name load active run comment <<<"$(echo "$raw" | awk '{print $1, $2, $3, $4, $5}')"
  elif [[ "$raw" = ○* ]]; then
    stat="○"
    read _ name load active run comment <<<"$(echo "$raw" | awk '{print $1, $2, $3, $4, $5}')"
  else
    stat="✔"
    read name load active run comment <<<"$(echo "$raw" | awk '{print $1, $2, $3, $4, $5}')"
  fi
  [[ ${#name} -gt 28 ]] && name="${name:0:26}.."
  printf "%s %-28s %-10s %-10s %-10s %s\n" $stat $name $load $active $run $comment
done
EOF

  # Create system services reload script
  cat > "$system_script" << 'EOF'
#!/bin/bash
{
  systemctl --system list-units --no-pager --type=service,timer --no-legend --all
  systemctl --system list-unit-files --no-pager --type=service --no-legend | while read -r name state preset; do
    [[ -z "$name" ]] && continue
    if ! systemctl --system list-units --no-pager --type=service,timer --no-legend --all 2>/dev/null | grep -q "^[●○*]\? *$name"; then
      printf "○ %s not-loaded inactive dead %s\n" "$name" "$state"
    fi
  done
  systemctl --system list-unit-files --no-pager --type=timer --no-legend | while read -r name state preset; do
    [[ -z "$name" ]] && continue
    if ! systemctl --system list-units --no-pager --type=service,timer --no-legend --all 2>/dev/null | grep -q "^[●○*]\? *$name"; then
      printf "○ %s not-loaded inactive dead %s\n" "$name" "$state"
    fi
  done
} | while read -r raw; do
  [[ -z "$raw" ]] && continue
  if [[ "$raw" = ●* ]]; then
    stat="✘"
    read _ name load active run comment <<<"$(echo "$raw" | awk '{print $1, $2, $3, $4, $5}')"
  elif [[ "$raw" = ○* ]]; then
    stat="○"
    read _ name load active run comment <<<"$(echo "$raw" | awk '{print $1, $2, $3, $4, $5}')"
  else
    stat="✔"
    read name load active run comment <<<"$(echo "$raw" | awk '{print $1, $2, $3, $4, $5}')"
  fi
  [[ ${#name} -gt 28 ]] && name="${name:0:26}.."
  printf "%s %-28s %-10s %-10s %-10s %s\n" $stat $name $load $active $run $comment
done
EOF

  chmod +x "$user_script" "$system_script"

  selected_service=$(_format_services "--user" | fzf \
    --exact \
    --header="📊 User Services & Timers | S:System U:User Ctrl-R:Refresh" \
    --preview 'unit_name=$(echo {} | awk "{print \$2}"); systemctl --user status "$unit_name" 2>/dev/null || echo "Unit not available"' \
    --preview-window=up:60%:wrap \
    --bind="S:reload($system_script)+change-header(📊 System Services & Timers | S:System U:User Ctrl-R:Refresh)+change-preview(unit_name=\$(echo {} | awk \"{print \\\$2}\"); systemctl --system status \"\$unit_name\" 2>/dev/null || echo \"Unit not available\")" \
    --bind="U:reload($user_script)+change-header(📊 User Services & Timers | S:System U:User Ctrl-R:Refresh)+change-preview(unit_name=\$(echo {} | awk \"{print \\\$2}\"); systemctl --user status \"\$unit_name\" 2>/dev/null || echo \"Unit not available\")" \
    --bind="ctrl-r:refresh-preview"
  )

  # Clean up temporary files
  rm -rf "$tmpdir"
}
zbindkey -M viins '^O' fzf-services-widget

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

###########################
### alias-expand-widget ###
###########################

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

function alias-expand-widget() {
  [[ $LBUFFER =~ "\<(${(j:|:)baliases})\$" ]]; insertBlank=$?
  if [[ ! $LBUFFER =~ "\<(${(j:|:)ialiases})\$" ]]; then
    zle _expand_alias
  fi
  zle self-insert
  if [[ "$insertBlank" = "0" ]]; then
    zle backward-delete-char
  fi
}

####################
### space-widget ###
####################

function space-widget() {
  alias-expand-widget
}
zbindkey ' ' space-widget
