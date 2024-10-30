###################
### ZSH OPTIONS ###
###################

# zsh boot time report
# start=$(date +%s.%N)
# zmodload zsh/zprof

# Directory navigation and stack management
setopt AUTOCD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT PUSHDMINUS

# Auto-completion settings
setopt AUTO_MENU AUTO_LIST AUTO_PARAM_SLASH COMPLETE_IN_WORD ALWAYS_TO_END MENU_COMPLETE
setopt LIST_PACKED LIST_TYPES EXTENDED_GLOB

# History management
setopt HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY SHARE_HISTORY

# Input and editing optimization
setopt FLOW_CONTROL MAGIC_EQUAL_SUBST CORRECT PROMPTSUBST NO_BEEP NO_HUP

# Path and command lookup
setopt PATH_DIRS

# Safety and error handling
setopt NO_CASE_GLOB NONOMATCH

# Other optimizations
unsetopt BEEP

# xhost access control
xhost +local: &>/dev/null

# set bindkey mode to vi
bindkey -v

# proxy
export http_proxy="${proxy:-http://127.0.0.1:7890}"
export https_proxy="${proxy:-http://127.0.0.1:7890}"
export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"

#############
### ZINIT ###
#############
# Order of execution of related Ice-mods:
# atinit -> atpull! -> make'!!' -> mv -> cp -> make! ->
# atclone/atpull -> make -> (plugin script loading) -> 
# src -> multisrc -> atload.

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# must
zinit ice wait"[[ ! -f ~/.must.ok ]]" lucid as"program" id-as'must' \
  atload'
    ok=0
    command -v nala &>/dev/null || sudo apt install nala || ok=1
    command -v ssh &>/dev/null || sudo nala install ssh || ok=1
    command -v curl &>/dev/null || sudo nala install curl || ok=1
    command -v foot &>/dev/null || sudo nala install foot || ok=1
    command -v kitty &>/dev/null || sudo nala install kitty || ok=1
    command -v gcc &>/dev/null || sudo nala install build-essential || ok=1
    command -v cmake &>/dev/null || sudo nala install cmake || ok=1
    command -v sccache &>/dev/null || sudo nala install sccache || ok=1
    command -v openssl &>/dev/null || sudo nala install openssh || ok=1
    command -v npm &>/dev/null || sudo nala install npm || ok=1
    command -v yarn &>/dev/null || npm install -g yarn || ok=1
    dpkg -l | grep libssl-dev | grep ii &>/dev/null || sudo nala install libssl-dev || ok=1
    [[ $ok -eq 0 ]] && touch ~/.must.ok
  '
zinit light zdharma-continuum/null

# prompt
zinit ice lucid as"program" from"gh-r" id-as"starship" \
  atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
  atload"export STARSHIP_CONFIG=~/.starship.toml" \
  src"init.zsh" \
  atpull"%atclone"
zinit light starship/starship

# settings & functions
zinit ice wait"1" lucid as"program" id-as"autoload" \
  atinit"fpath+=~/.zsh/functions" \
  atload'
    autoload -Uz ~/.zsh/functions/**/*(:t)
    for script (~/.zsh/*.zsh(N)) source $script
  '
zinit light zdharma-continuum/null

###############
### PLUGINS ###
###############

# zdharma-continuum/fast-syntax-highlighting
zinit ice wait"1" lucid atinit"zicompinit; zicdreplay" id-as"fast-syntax-highlighting"
zinit light zdharma-continuum/fast-syntax-highlighting

# Aloxaf/fzf-tab
zinit ice wait"2" lucid id-as"fzf-tab"
zinit light Aloxaf/fzf-tab

# zsh-users/zsh-history-substring-search
zinit ice wait"3" lucid id-as"zsh-history-substring-search" \
  atload"
    export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=''
    bindkey '^[[A' history-substring-search-up
    bindkey '^[OA' history-substring-search-up
    bindkey '^k' history-substring-search-up
    bindkey '^j' history-substring-search-down
  "
zinit light zsh-users/zsh-history-substring-search

# zsh-users/zsh-autosuggestions
zinit ice wait"3" lucid id-as"zsh-autosuggestions" \
  atload"
    _zsh_autosuggest_start
    export ZSH_AUTOSUGGEST_MANUAL_REBIND='1'
    export ZSH_AUTOSUGGEST_STRATEGY=(completion match_prev_cmd)
    export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
    bindkey -M viins '^q' autosuggest-clear
    bindkey -M viins '^@' autosuggest-execute
    bindkey -M vicmd '^@' autosuggest-execute
  "
zinit light zsh-users/zsh-autosuggestions

###############
### PROGRAM ###
###############

# brew
zinit ice wait"1" lucid as"program" id-as'brew' \
  atclone'
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    /home/linuxbrew/.linuxbrew/bin/brew shellenv > init.zsh
    brew install lnav
    ' \
  atload"
    export HOMEBREW_NO_AUTO_UPDATE=true
    export HOMEBREW_AUTO_UPDATE_SECS=$((60*60*24))
    " \
  src"init.zsh"
zinit light zdharma-continuum/null

# cargo
zinit ice wait"1" lucid as"program" id-as'cargo' \
  atclone"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    cargo install --locked sccache
    cargo install --locked zellij
    " \
  atload'
    export PATH="$HOME/.cargo/bin:$PATH"
    [[ -n "$commands[sccache]" ]] && export RUSTC_WRAPPER="$commands[sccache]"
  '
zinit light zdharma-continuum/null

# golang
zinit ice wait'1' lucid as"program" id-as'golang' \
  atclone'
    version=$(curl -s https://raw.githubusercontent.com/actions/go-versions/main/versions-manifest.json|jq -r ".[0].version")
    echo \$version
    wget -c https://go.dev/dl/go${version}.linux-amd64.tar.gz -P /tmp
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go\$version.linux-amd64.tar.gz
    ' \
  atload'
    export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
    export GOPROXY=https://goproxy.cn,https://mirrors.aliyun.com/goproxy,https://goproxy.io,direct
    export GO111MODULE=on
    export GOSUMDB=off
    export GOPRIVATE=*.corp.example.com,rsc.io/private
    ' \
  atpull"%atclone"
zinit light zdharma-continuum/null

# fzf
zinit ice wait"1" lucid as"program" from"gh-r" id-as"fzf" \
  atclone"./fzf --zsh > init.zsh && mv ./fzf ~/.local/bin/" \
  src"init.zsh" \
  atpull"%atclone"
zinit light junegunn/fzf

# navi
zinit ice wait'1' lucid as"program" id-as'navi' \
  atclone"cargo install navi --locked && navi widget zsh > init.zsh" \
  atload'
    export NAVI_PATH=$HOME/.config/navi/cheats
    export NAVI_CONFIG=$HOME/.config/navi/config.yaml
    [[ ! -e "$NAVI_CONFIG" ]] && navi info config-example > $NAVI_CONFIG
    bindkey "^N" _navi_widget
    ' \
  src"init.zsh"
zinit light zdharma-continuum/null

# fd
zinit ice wait'[[ ! -n "$commands[fd]" ]]' lucid as"program" from"gh-r" id-as"fd" \
  atclone"mv fd*/fd ~/.local/bin/" \
  atpull"%atclone"
zinit light sharkdp/fd

# node version manager
zinit ice wait'[[ ! -n "$commands[fnm]" ]]' lucid as"program" id-as'nodejs' \
  atclone"
    sudo apt install nodejs
    curl -fsSL https://fnm.vercel.app/install | bash
    ~/.local/share/fnm/fnm env --use-on-cd --shell zsh > init.zsh
    ~/.local/share/fnm/fnm completions --shell zsh > _fnm
    ln -fs ~/.local/share/fnm/fnm ~/.local/bin/fnm
    " \
  src"init.zsh" \
  atpull"%atclone"
zinit light zdharma-continuum/null

# zen
zinit ice wait'[[ ! -n "$commands[zen]" ]]' lucid as"program" from"gh-r" id-as'zen' \
  bpick"zen-specific.AppImage" \
  atclone"mv zen-specific.appimage ~/.local/bin/zen" \
  atpull"%atclone"
zinit light zen-browser/desktop

###############
### COMMAND ###
###############

# zoxide
zinit ice wait"1" lucid as"command" from"gh-r" id-as"zoxide" \
  atclone"./zoxide init zsh --cmd j > init.zsh" \
  src"init.zsh" \
  atpull"%atclone"
zinit light ajeetdsouza/zoxide

# atuin
zinit ice wait'1' lucid as"command" from"gh-r" id-as"atuin" \
  bpick"atuin-*.tar.gz" mv"atuin*/atuin -> atuin" \
  atclone"./atuin init zsh > init.zsh; ./atuin gen-completions --shell zsh > _atuin" \
  atpull"%atclone" src"init.zsh"
zinit light atuinsh/atuin

# yazi
zinit ice wait'3' lucid as"command" from"gh-r" id-as"yazi" \
  bpick"yazi-x86_64-unknown-linux-musl.zip" \
  atclone"mv yazi*/* ./" \
  atpull"%atclone"
zinit light sxyazi/yazi

# direnv
zinit ice wait"3" lucid as"command" from"gh-r" id-as"direnv" \
  mv"direnv* -> direnv" pick"direnv" \
  atclone"./direnv hook zsh > init.zsh" \
  src"init.zsh" \
  atpull"%atclone"
zinit light direnv/direnv

# just
zinit ice wait"3" lucid as"command" from"gh-r" id-as"just" \
  atclone'./just --completions zsh > _just' \
  atpull"%atclone"
zinit light casey/just

# gitui
zinit ice wait"3" lucid as"command" from"gh-r" id-as"gitui"
zinit light extrawurst/gitui

# curlie
zinit ice wait'[[ ! -n "$commands[curlie]" ]]' lucid as"command" from"gh-r" id-as"curlie"
zinit light rs/curlie

##################
### COMPLETION ###
##################

# completions
zinit ice wait"3" blockf lucid id-as"zsh-completions" \
  atpull"zinit creinstall -q ."
zinit light zsh-users/zsh-completions

# docker
zinit ice wait'[[ -n ${ZLAST_COMMANDS[(r)docker]} ]]' lucid as"completion"
zinit snippet https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker

# git
zinit ice wait'[[ -n ${ZLAST_COMMANDS[(r)git]} ]]' lucid as"completion"
zinit snippet OMZ::plugins/git/git.plugin.zsh

#############
### Zprof ###
#############
# you need add `zmodload zsh/zprof` to the top of .zshrc file
# zprof | head -n 20; zmodload -u zsh/zprof
# echo "Runtime was: $(echo "$(date +%s.%N) - $start" | bc)"

