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

# fpath
fpath=(~/.zsh.d/completions $fpath)

# envs
export OS="$(cat /etc/os-release | grep '^ID=' | awk -F '=' '{printf $2}' | tr -d '"')"

# install function
ins() {
  case "$OS" in
    debian|ubuntu)
      sudo nala install -y $@
      ;;
    fedora|centos|rocky|almalinux)
      sudo dnf install -y $@
      ;;
    rhel)
      sudo yum install -y $@
      ;;
    *)
      echo "Unsupported OS: $OS"
      ;;
  esac
  return 1
}

# proxy
export http_proxy="${proxy:-http://127.0.0.1:7890}"
export https_proxy="${proxy:-http://127.0.0.1:7890}"
export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"

# pre-install
[[ -n "$commands[nala]" ]] || sudo apt install -y nala
[[ -n "$commands[git]" ]] || ins git
[[ -n "$commands[curl]" ]] || ins curl

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

# ensure zbin dir
export ZBIN="$HOME/.local/bin"
[[ ! -d "$ZBIN" ]] && mkdir -p $ZBIN

# Add the following snippet as the first plugin in your configuration
zinit light-mode for zdharma-continuum/zinit-annex-bin-gem-node

# must
zinit ice wait'[[ ! -f ~/.must.ok && $OS == "ubuntu" ]]' lucid as"program" id-as'must' \
  atload'
    ok=0
    command -v ssh &>/dev/null || ins ssh || ok=1
    command -v gcc &>/dev/null || ins build-essential || ok=1
    command -v cmake &>/dev/null || ins cmake || ok=1
    command -v pkg-config &>/dev/null || ins pkg-config || ok=1
    command -v sccache &>/dev/null || ins sccache || ok=1
    command -v openssl &>/dev/null || ins openssh || ok=1
    command -v ddcutil &>/dev/null || ins ddcutil || ok=1
    command -v nodejs &>/dev/null || ins nodejs || ok=1
    command -v npm &>/dev/null || ins npm || ok=1
    command -v yarn &>/dev/null || npm install -g yarn || ok=1
    command -v tmux &>/dev/null || ins tmux || ok=1
    command -v unzip &>/dev/null || ins unzip || ok=1
    dpkg -l | grep libssl-dev | grep ii &>/dev/null || ins libssl-dev || ok=1
    [[ $ok -eq 0 ]] && touch ~/.must.ok
  '
zinit light zdharma-continuum/null

# display
zinit ice wait'[[ -n $DISPLAY && ! -f ~/.desktop.ok ]]' lucid as"program" id-as'display' \
  atload'
    ok=0
    command -v foot &>/dev/null || ins foot || ok=1
    command -v kitty &>/dev/null || ins kitty || ok=1
    [[ $ok -eq 0 ]] && touch ~/.display.ok
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
  atinit"fpath+=~/.zsh.d/functions" \
  atload'
    autoload -Uz ~/.zsh.d/functions/**/*(:t)
    for script (~/.zsh.d/*.zsh(N)) source $script
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
zinit ice wait"0" lucid as"program" id-as'brew' \
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
zinit ice wait"0" lucid as"program" id-as'cargo' \
  atclone"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    cargo install --locked git-delta
    " \
  atload'
    export PATH="$HOME/.cargo/bin:$PATH"
    [[ -n "$commands[sccache]" ]] && export RUSTC_WRAPPER="$commands[sccache]"
  '
zinit light zdharma-continuum/null

# golang
zinit ice wait'0' lucid as"program" id-as'golang' \
  atclone'
    version=$(curl -s https://raw.githubusercontent.com/actions/go-versions/main/versions-manifest.json|jq -r ".[0].version")
    wget -c https://go.dev/dl/go${version}.linux-amd64.tar.gz -P /tmp
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go$version.linux-amd64.tar.gz
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

# fnm - node version manager
zinit ice wait'1' lucid as"program" id-as'fnm' \
  atclone"
    curl -fsSL https://fnm.vercel.app/install | bash
    ~/.local/share/fnm/fnm env --use-on-cd --shell zsh > init.zsh
    ~/.local/share/fnm/fnm completions --shell zsh > _fnm
    ln -fs ~/.local/share/fnm/fnm $ZBIN/fnm
    " \
  src"init.zsh" \
  atpull"%atclone"
zinit light zdharma-continuum/null

# navi
zinit ice wait'1' lucid as"program" id-as'navi' \
  atclone'export PATH="$HOME/.cargo/bin:$PATH"' \
  atclone"cargo install navi --locked && navi widget zsh > init.zsh" \
  atload'
    export NAVI_PATH=$HOME/.config/navi/cheats
    export NAVI_CONFIG=$HOME/.config/navi/config.yaml
    [[ ! -d "$NAVI_PATH" ]] && mkdir -p $NAVI_PATH
    [[ ! -e "$NAVI_CONFIG" ]] && navi info config-example > $NAVI_CONFIG
    bindkey "^N" _navi_widget
    ' \
  src"init.zsh"
zinit light zdharma-continuum/null

# fzf
zinit ice wait"1" lucid as"program" from"gh-r" id-as"fzf" \
  atclone"./fzf --zsh > init.zsh && mv -vf ./fzf $ZBIN/" \
  src"init.zsh" \
  atpull"%atclone"
zinit light junegunn/fzf

# uv - python package manager
zinit ice wait'[[ ! -n "$commands[uv]" ]]' lucid as"program" id-as"uv" \
  atclone"curl -LsSf https://astral.sh/uv/install.sh | sh" \
  atpull"%atclone"
zinit light zdharma-continuum/null

# fd
zinit ice wait'[[ ! -n "$commands[fd]" ]]' lucid as"program" from"gh-r" id-as"fd" \
  atclone"mv -vf fd*/fd $ZBIN/" \
  atpull"%atclone"
zinit light sharkdp/fd

# nvim
zinit ice wait'[[ ! -n "$commands[nvim]" ]]' lucid as"program" from"gh-r" id-as"nvim" \
  bpick"nvim-linux-x86_64.appimage" \
  atclone"sudo mv -vf nvim-linux-x86_64.appimage /usr/bin/nvim" \
  atpull"%atclone"
zinit light neovim/neovim

# hx
zinit ice wait'[[ ! -n "$commands[hx]" ]]' lucid as"program" from"gh-r" id-as"hx" \
  atclone"sudo mv -vf */hx /usr/bin/ && mv -vf */runtime ~/.config/helix/" \
  atpull"%atclone"
zinit light helix-editor/helix

# sing-box
zinit ice wait'[[ ! -n "$commands[sing-box]" ]]' lucid as"program" from"gh-r" id-as"sing-box" \
  bpick"sing-box-*-linux-amd64.tar.gz" \
  atclone"mv -vf */sing-box $ZBIN/sing-box && sudo setcap cap_net_admin=+ep $ZBIN/sing-box" \
  atpull"%atclone"
zinit light SagerNet/sing-box

# zellij
# zinit ice wait'[[ ! -n "$commands[zellij]" ]]' lucid as"program" from"gh-r" id-as"zellij" \
#   bpick"zellij-x86_64-unknown-linux-musl.tar.gz" \
#   atclone"sudo mv -vf zellij /usr/bin/" \
#   atpull"%atclone"
# zinit light zellij-org/zellij

# pueue
zinit ice wait'[[ ! -n "$commands[pueue]" ]]' lucid as"program" from"gh" id-as"pueue" \
  atclone"
    cd pueue && cargo build --release --locked
    cp ../target/release/{pueue,pueued} $ZBIN/
    sudo chmod 744 $ZBIN/pueue*
    $ZBIN/pueue completions zsh > ../_pueue
  " \
  atpull"%atclone"
zinit light Nukesor/pueue

# caddy
# zinit ice wait'[[ ! -n "$commands[caddy]" ]]' lucid as"program" from"gh-r" id-as"caddy" \
#   bpick"caddy_*_linux_amd64.deb" \
#   atclone"sudo cp -rvf ./etc/caddy /etc/" \
#   atclone"sudo cp -rvf ./usr/bin/caddy /usr/bin/" \
#   atpull"%atclone"
# zinit light caddyserver/caddy

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
  atclone"mv -vf yazi*/* ./" \
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

# curlie
zinit ice wait'[[ ! -n "$commands[curlie]" ]]' lucid as"command" from"gh-r" id-as"curlie"
zinit light rs/curlie

# dust
zinit ice wait'[[ ! -n "$commands[dust]" ]]' lucid as"command" from"gh-r" id-as"dust" \
  atclone"sudo mv -vf */dust /usr/bin/" \
  atpull"%atclone"
zinit light bootandy/dust

# eza - eza is a modern replacement for ls
zinit ice wait'[[ ! -n "$commands[eza]" ]]' lucid as"command" from"gh-r" id-as"eza"
zinit light eza-community/eza

# fx - Command-line tool and terminal JSON viewer
zinit ice wait'[[ ! -n "$commands[fx]" ]]' lucid as"command" from"gh-r" id-as"fx" \
  mv"fx* -> fx"
zinit light antonmedv/fx

# gh
zinit ice wait'[[ ! -n "$commands[gh]" ]]' lucid as"command" from"gh-r" id-as"gh" \
  atclone"sudo mv -vf */bin/gh /usr/bin/" \
  atpull"%atclone"
zinit light cli/cli

# glow - Glow is a terminal-based markdown reader designed from the ground up to bring out the beauty—and power—of the CLI
zinit ice wait'[[ ! -n "$commands[glow]" ]]' lucid as"command" from"gh-r" id-as"glow" \
  pick"**/glow"
zinit light charmbracelet/glow

# grex - A command-line tool and library for generating regular expressions from user-provided test cases
zinit ice wait'[[ ! -n "$commands[grex]" ]]' lucid as"command" from"gh-r" id-as"grex" \
  pick"**/grex"
zinit light pemistahl/grex

# procs - procs is a replacement for ps written in Rust
zinit ice wait'[[ ! -n "$commands[procs]" ]]' lucid as"command" from"gh-r" id-as"procs" \
  pick"**/procs"
zinit light dalance/procs

# ripgrep - ripgrep recursively searches directories for a regex pattern while respecting your gitignore
zinit ice wait'[[ ! -n "$commands[rg]" ]]' lucid as"command" from"gh-r" id-as"rg" \
  atclone"sudo mv -vf */rg /usr/bin/" \
  atpull"%atclone"
zinit light burntSushi/ripgrep

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

# fzf
zinit ice wait'[[ -n ${ZLAST_COMMANDS[(r)fzf]} ]]' lucid as"completion"
zinit snippet https://raw.githubusercontent.com/lmburns/dotfiles/master/.config/zsh/completions/_fzf

#############
### Zprof ###
#############
# you need add `zmodload zsh/zprof` to the top of .zshrc file
# zprof | head -n 20; zmodload -u zsh/zprof
# echo "Runtime was: $(echo "$(date +%s.%N) - $start" | bc)"


# fnm
FNM_PATH="/home/wukaige/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="/home/wukaige/.local/share/fnm:$PATH"
  eval "`fnm env`"
fi
