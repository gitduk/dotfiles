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
setopt AUTO_MENU AUTO_LIST AUTO_PARAM_SLASH COMPLETE_IN_WORD ALWAYS_TO_END LIST_PACKED LIST_TYPES EXTENDED_GLOB
setopt HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY SHARE_HISTORY
setopt MAGIC_EQUAL_SUBST PROMPTSUBST NO_BEEP NO_HUP PATH_DIRS NO_CASE_GLOB NO_NOMATCH

xhost +local: &>/dev/null
bindkey -v
zmodload zsh/zle
autoload -Uz add-zsh-hook edit-command-line

###################
### Zinit Setup ###
###################

# zinit
command -v git &>/dev/null || sudo apt install git
command -v curl &>/dev/null || sudo apt install curl
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[[ ! -d "$ZINIT_HOME" ]] && mkdir -p "$(dirname $ZINIT_HOME)"
[[ ! -d "$ZINIT_HOME/.git" ]] && git clone "https://github.com/zdharma-continuum/zinit.git" "$ZINIT_HOME"
export ZPFX="$HOME/.local"
source "${ZINIT_HOME}/zinit.zsh"
zinit light-mode for zdharma-continuum/zinit-annex-bin-gem-node

# prompt
zinit ice lucid as"program" from"gh-r" id-as"starship" \
  atclone"./starship completions zsh > _starship" \
  atpull"%atclone" \
  atload'
    export STARSHIP_CONFIG=~/.starship.toml
    eval "$(starship init zsh)"
  '
zinit light starship/starship

##################################
### Main Plugins (Lazy Loaded) ###
##################################

zinit ice wait"0" blockf lucid id-as"zsh-completions" \
  atpull"zinit creinstall -q ."
zinit light zsh-users/zsh-completions

zinit ice wait"0" lucid id-as"zsh-autosuggestions" \
  atload'!
    ZSH_AUTOSUGGEST_MANUAL_REBIND=1
    ZSH_AUTOSUGGEST_STRATEGY=(completion match_prev_cmd)
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
    bindkey -M viins "^ " autosuggest-execute
    bindkey -M vicmd "^ " autosuggest-execute
    _zsh_autosuggest_start
  '
zinit light zsh-users/zsh-autosuggestions

zinit ice wait"0a" lucid nocompile id-as"compinit" \
  atinit'
    _zcd="${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump"
    if [[ ! -s "$_zcd" || -n ${_zcd}(N.mh+24) ]]; then
      ZINIT[COMPINIT_OPTS]="-i -d $_zcd"
    else
      ZINIT[COMPINIT_OPTS]="-C -d $_zcd"
    fi
    zicompinit; zicdreplay
  '
zinit light zdharma-continuum/null

zinit ice wait"0b" lucid as"program" id-as"autoload" \
  atinit"fpath+=~/.zsh.d/functions" \
  atload'
    autoload -Uz ~/.zsh.d/functions/**/*(:t)
    for script (~/.zsh.d/*.zsh(N)) source $script
  '
zinit light zdharma-continuum/null

zinit ice wait"0b" lucid id-as"fast-syntax-highlighting"
zinit light zdharma-continuum/fast-syntax-highlighting

zinit ice wait"0c" lucid id-as"fzf-tab" \
  atload"zstyle ':fzf-tab:*' fzf-flags --ansi"
zinit light Aloxaf/fzf-tab

zinit ice wait"1" lucid id-as"zsh-history-substring-search" \
  atload"
    export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=''
    bindkey '^k' history-substring-search-up
    bindkey '^j' history-substring-search-down
  "
zinit light zsh-users/zsh-history-substring-search

zinit ice wait"1" lucid; zinit snippet OMZP::sudo
zinit ice wait"1" lucid; zinit snippet OMZP::extract

####################
### Binary Tools ###
####################

# rustup
zinit ice wait"1" lucid as"program" run-atpull id-as"rustup" \
  atclone'
    curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh
    $HOME/.cargo/bin/rustup completions zsh > _rustup
    $HOME/.cargo/bin/rustup completions zsh cargo > _cargo
    sudo ln -sf ~/.cargo/bin/cargo /usr/bin/cargo
  ' \
  atpull"%atclone" \
  atload'
    export CARGO_INSTALL_ROOT=$HOME/.local
    export PATH=$HOME/.cargo/bin:$PATH
    command -v sccache &>/dev/null && export RUSTC_WRAPPER="$(command -v sccache)"
  '
zinit light zdharma-continuum/null

# golang
zinit ice wait"1" lucid as"program" run-atpull id-as"golang" \
  atclone'
    version=$(curl -s https://raw.githubusercontent.com/actions/go-versions/main/versions-manifest.json|jq -r ".[0].version")
    wget -c https://go.dev/dl/go${version}.linux-amd64.tar.gz -P /tmp
    [[ -d /usr/local/go ]] && sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go$version.linux-amd64.tar.gz
  ' \
  atpull"%atclone" \
  atload'
    export GOPROXY="https://goproxy.cn,https://mirrors.aliyun.com/goproxy,https://goproxy.io,direct"
    export GOPRIVATE="*.corp.example.com,rsc.io/private"
    export GOSUMDB="sum.golang.org"
    export GO111MODULE=on
  '
zinit light zdharma-continuum/null

# tmux
zinit ice if'[[ ! -x $commands[tmux] ]]' lucid as"program" from"gh-r" id-as"tmux" sbin"tmux"
zinit light tmux/tmux-builds

# zoxide
zinit ice wait"0" lucid as"program" from"gh-r" id-as"zoxide" \
  sbin"zoxide" \
  atload'eval "$(zoxide init zsh --cmd j)"'
zinit light ajeetdsouza/zoxide

# atuin
zinit ice wait"0" lucid as"program" from"gh-r" id-as"atuin" \
  bpick"atuin-x86_64-unknown-linux-musl.tar.gz" \
  extract"!" sbin"atuin" \
  atclone'
    ./atuin gen-completions --shell zsh > _atuin
    ./atuin init zsh > init.zsh
  ' \
  atpull"%atclone" \
  src"init.zsh" \
  atload"export ATUIN_TMUX_POPUP=false"
zinit light atuinsh/atuin

# navi
zinit ice wait"0" lucid as"program" from"gh-r" id-as"navi" \
  atclone'
    mkdir -p "$HOME/.config/navi/cheats"
    navi info config-example > "$HOME/.config/navi/config.yaml"
  ' \
  atpull"%atclone" \
  atload'
    export NAVI_PATH="$HOME/.config/navi/cheats"
    export NAVI_CONFIG="$HOME/.config/navi/config.yaml"
    eval "$(navi widget zsh)"
    bindkey "^N" _navi_widget
  '
zinit light denisidoro/navi

# direnv
zinit ice wait"1" lucid as"program" from"gh-r" id-as"direnv" \
  sbin"direnv* -> direnv" \
  atload'eval "$(direnv hook zsh)"'
zinit light direnv/direnv

# fzf
zinit ice if'[[ ! -x $commands[fzf] ]]' lucid as"program" from"gh-r" id-as"fzf" sbin"fzf"
zinit light junegunn/fzf

#############
### Zprof ###
#############

if [[ -n "$ZPROF" ]]; then
  zprof | head -n 20
  zmodload -u zsh/zprof
  echo "Runtime was: $(echo "$(date +%s.%N) - $start" | bc)"
fi
