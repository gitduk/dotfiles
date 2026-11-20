###################
### Zsh Options ###
###################
# zsh boot time report
# ZPROF=1
if [[ -n "$ZPROF" ]]; then
  start=$(date +%s.%N)
  zmodload zsh/zprof
fi

# Skip heavy shell initialization for programmatic use
if [[ -n "$ZSH_EXECUTION_STRING" ]] || \
  [[ ! -t 0 ]] || \
  [[ ! -t 1 ]] || \
  [[ "$TERM" = "dumb" ]]; then
  return 0 2>/dev/null || exit 0
fi

setopt AUTOCD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT PUSHDMINUS
setopt MENU_COMPLETE AUTO_LIST AUTO_PARAM_SLASH COMPLETE_IN_WORD ALWAYS_TO_END LIST_PACKED LIST_TYPES EXTENDED_GLOB
setopt HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY SHARE_HISTORY
setopt MAGIC_EQUAL_SUBST PROMPTSUBST NO_BEEP NO_HUP PATH_DIRS NO_CASE_GLOB NO_NOMATCH

xhost +local: &>/dev/null
bindkey -v
zmodload zsh/zle
autoload -Uz add-zsh-hook edit-command-line

###########
### rig ###
###########

# bootstrap
_rig_zsh=$HOME/.local/share/rig/rig.zsh
[[ -f $_rig_zsh ]] || {
  mkdir -p ${_rig_zsh:h}
  curl -fsSL -o $_rig_zsh \
    https://raw.githubusercontent.com/gitduk/rig/master/rig.zsh
}
source $_rig_zsh

###################
### completions ###
###################

fpath+=~/.zsh.d/completions
autoload -Uz compinit
ZCD="${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"
if [[ -n ${ZCD}(#qN.mh+24) ]]; then
  compinit -d $ZCD
else
  compinit -C -d $ZCD
fi

#####################
### Local Scripts ###
#####################

fpath+=~/.zsh.d/functions
autoload -Uz ~/.zsh.d/functions/**/*(:t)
for script (~/.zsh.d/*.zsh(N)) source $script

#############
### Zprof ###
#############

if [[ -n "$ZPROF" ]]; then
  zprof | head -n 20
  zmodload -u zsh/zprof
  echo "Runtime was: $(echo "$(date +%s.%N) - $start" | bc)"
fi

