###################
### ZSH OPTIONS ###
###################

# zsh boot time report
# start=$(date +%s.%N)
# zmodload zsh/zprof

# Directory navigation and stack management
setopt AUTOCD            # 允许直接输入目录名就 cd 进去，例如输入 "~/Downloads" 会自动进入目录
setopt AUTO_PUSHD        # 使用 cd 命令时将目录压入目录栈（可以用 `dirs` / `popd` / `pushd` 管理历史）
setopt PUSHD_IGNORE_DUPS # 忽略重复目录，避免栈中有多个相同路径
setopt PUSHD_SILENT      # 使用 pushd/popd 时不打印栈内容
setopt PUSHDMINUS        # 允许 `cd -1` `cd -2` 等来切换到目录栈中前面的目录

# Auto-completion settings
setopt AUTO_MENU        # 连续按 Tab 时循环候选项
setopt AUTO_LIST        # 模糊补全后自动显示候选项列表
setopt AUTO_PARAM_SLASH # 自动在目录后加 `/`，方便继续补全
setopt COMPLETE_IN_WORD # 允许在单词中间补全，而不是只能在末尾
setopt ALWAYS_TO_END    # 补全后光标移到词末尾
setopt LIST_PACKED      # 紧凑排列候选项列表（节省空间）
setopt LIST_TYPES       # 在候选项中加上 `/`, `*`, `@` 等文件类型标志
setopt EXTENDED_GLOB    # 启用更强大的通配符语法

# History management
setopt HIST_IGNORE_ALL_DUPS # 忽略所有重复命令，只保留最后一次
setopt HIST_REDUCE_BLANKS   # 去除命令中的多余空格
setopt HIST_VERIFY          # 先显示历史命令，让你确认后再执行
setopt SHARE_HISTORY        # 在多个终端间共享历史

# Input and editing optimization
setopt MAGIC_EQUAL_SUBST # 允许 foo=bar somecmd $foo 等形式（适合脚本）
setopt PROMPTSUBST       # 允许 prompt 中的变量实时更新（用于复杂 prompt）
setopt NO_BEEP           # 禁用蜂鸣（大部分人会关）
setopt NO_HUP            # 退出 shell 不发送 HUP 信号，避免关闭后台作业

# Path and command lookup
setopt PATH_DIRS # 输入目录中的命令名会自动搜索 PATH 中的目录

# Safety and error handling
setopt NO_CASE_GLOB # 文件名匹配大小写敏感（你设置的是“关闭大小写敏感”）
setopt NONOMATCH    # 如果通配符找不到匹配项，不报错（而是原样输出）

# xhost access control
xhost +local: &>/dev/null

# set bindkey mode to vi
bindkey -v

############
### ENVS ###
############

export OS="$(cat /etc/os-release | grep '^ID=' | awk -F '=' '{printf $2}' | tr -d '"')"

# proxy
PROXY_HOST="${PROXY_HOST:-127.0.0.1}"
PROXY_PORT="${PROXY_PORT:-7890}"
if nc -z -n "$PROXY_HOST" "$PROXY_PORT" &>/dev/null; then
  # http
  export http_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
  export HTTP_PROXY="$http_proxy"

  # https
  export https_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
  export HTTPS_PROXY="$https_proxy"

  # no_proxy
  export no_proxy="localhost,127.0.0.1"
  export NO_PROXY="$no_proxy"
fi

# PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm/bin:$PATH"

# Qt
QT_VERSION="6.9.1"
if [[ -d "$HOME/.local/share/Qt/$QT_VERSION" ]]; then
  export QT_ROOT="$HOME/.local/share/Qt/$QT_VERSION"
  export PATH="$QT_ROOT/gcc_64/bin:$PATH"
  export Qt6_DIR="$QT_ROOT/gcc_64/lib/cmake/Qt6"
  export LD_LIBRARY_PATH="$QT_ROOT/gcc_64/lib:$LD_LIBRARY_PATH"
fi

# fpath
export ZSH_COMPLETIONS="$HOME/.zcompletions"
[[ ! -d "$ZSH_COMPLETIONS" ]] && mkdir -p "$ZSH_COMPLETIONS"
fpath=($ZSH_COMPLETIONS $fpath)

#############
### TOOLS ###
#############

# pre-install
[[ -n "$commands[nala]" ]] || sudo apt install -y nala
[[ -n "$commands[git]" ]] || ins git
[[ -n "$commands[curl]" ]] || ins curl

# install function
function ins() {
  case "$OS" in
  debian | ubuntu)
    sudo nala install -y $@
    ;;
  fedora | centos | rocky | almalinux)
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

#############
### ZINIT ###
#############
# Order of execution of related Ice-mods:
# atinit -> atpull! -> make'!!' -> mv -> cp -> make! ->
# atclone/atpull -> make -> (plugin script loading) ->
# src -> multisrc -> atload.
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[[ ! -d "$ZINIT_HOME" ]] && mkdir -p "$(dirname $ZINIT_HOME)"
[[ ! -d "$ZINIT_HOME/.git" ]] && git clone "https://github.com/zdharma-continuum/zinit.git" "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# ensure dir
export BPFX="$HOME/.local/bin"
[[ ! -d "$BPFX" ]] && mkdir -p $BPFX

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
    command -v tmux &>/dev/null || ins tmux || ok=1
    command -v unzip &>/dev/null || ins unzip || ok=1
    command -v jq &>/dev/null || ins jq || ok=1
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

# zsh-users/zsh-autosuggestions
zinit ice wait"0" lucid id-as"zsh-autosuggestions" \
  atload"!_zsh_autosuggest_start" \
  atload"
    export ZSH_AUTOSUGGEST_MANUAL_REBIND='1'
    export ZSH_AUTOSUGGEST_STRATEGY=(completion match_prev_cmd)
    export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
    bindkey -M viins '^q' autosuggest-clear
    bindkey -M viins '^@' autosuggest-execute
    bindkey -M vicmd '^@' autosuggest-execute
  "
zinit light zsh-users/zsh-autosuggestions

# zdharma-continuum/fast-syntax-highlighting
zinit ice wait"0" lucid id-as"fast-syntax-highlighting" \
  atinit"zicompinit; zicdreplay"
zinit light zdharma-continuum/fast-syntax-highlighting

# zsh-users/zsh-history-substring-search
zinit ice wait"1" lucid id-as"zsh-history-substring-search" \
  atload"
    export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=''
    bindkey '^[[A' history-substring-search-up
    bindkey '^[OA' history-substring-search-up
    bindkey '^k' history-substring-search-up
    bindkey '^j' history-substring-search-down
  "
zinit light zsh-users/zsh-history-substring-search

# sudo
zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh

# extract
zinit snippet OMZ::plugins/extract/extract.plugin.zsh

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
    export HOMEBREW_AUTO_UPDATE_SECS=$((60 * 60 * 24))
    " \
  src"init.zsh" \
  atpull"%atclone"
zinit light zdharma-continuum/null=s

# rustup
zinit ice wait"0" lucid as"program" id-as'rustup' \
  atclone"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    $HOME/.cargo/bin/rustup completions zsh > _rustup
    $HOME/.cargo/bin/rustup completions zsh cargo > _cargo
    $HOME/.cargo/bin/cargo install --root $HOME/.local --locked wallust
    command -v wallust &>/dev/null && wallust theme base16-default-dark -s
    " \
  atload'
    export PATH="$HOME/.cargo/bin:$PATH"
    export CARGO_INSTALL_ROOT="$HOME/.local"
    command -v sccache &>/dev/null && export RUSTC_WRAPPER="$(command -v sccache)"
  ' \
  atpull"%atclone"
zinit light zdharma-continuum/null

# golang
zinit ice wait'0' lucid as"program" id-as'golang' \
  atclone'
    version=$(curl -s https://raw.githubusercontent.com/actions/go-versions/main/versions-manifest.json|jq -r ".[0].version")
    wget -c https://go.dev/dl/go${version}.linux-amd64.tar.gz -P /tmp
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go$version.linux-amd64.tar.gz
    ' \
  atload'
    export GOPATH="$HOME/go/bin"
    export PATH="/usr/local/go/bin:$GOPATH:$PATH"
    export GOPROXY="https://goproxy.cn,https://mirrors.aliyun.com/goproxy,https://goproxy.io,direct"
    export GOPRIVATE="*.corp.example.com,rsc.io/private"
    export GOSUMDB="sum.golang.org"
    export GO111MODULE=on
    ' \
  atpull"%atclone"
zinit light zdharma-continuum/null

# fzf
zinit ice wait"0" lucid as"program" from"gh-r" id-as"fzf" \
  atclone"./fzf --zsh > init.zsh" \
  atclone"mv ./fzf $BPFX/" \
  src"init.zsh" \
  atpull"%atclone"
zinit light junegunn/fzf

# navi
zinit ice wait'0' lucid as"program" from"gh-r" id-as'navi' \
  atload'
    export NAVI_PATH="$HOME/.config/navi/cheats"
    export NAVI_CONFIG="$HOME/.config/navi/config.yaml"
    [[ ! -d "$NAVI_PATH" ]] && mkdir -p $NAVI_PATH
    [[ ! -e "$NAVI_CONFIG" ]] && navi info config-example > $NAVI_CONFIG
    eval "$(navi widget zsh)"
    bindkey "^N" _navi_widget
    ' \
  atpull"%atclone"
zinit light denisidoro/navi

# fnm - node version manager
zinit ice wait'1' lucid as"program" id-as'fnm' \
  atclone"
    curl -fsSL https://fnm.vercel.app/install | bash
    ~/.local/share/fnm/fnm env --use-on-cd --shell zsh > init.zsh
    ~/.local/share/fnm/fnm completions --shell zsh > _fnm
    ln -fs ~/.local/share/fnm/fnm $BPFX/fnm
    " \
  src"init.zsh" \
  atpull"%atclone"
zinit light zdharma-continuum/null

# bun - Bun is an all-in-one toolkit for JavaScript and TypeScript apps.
zinit ice wait'[[ ! -n "$commands[bun]" ]]' lucid as"program" from"gh-r" id-as'bun' \
  bpick"bun-linux-x64.zip" \
  atclone"mkdir -p ~/.bun/bin && mv */bun ~/.bun/bin/" \
  atclone"SHELL=zsh ~/.bun/bin/bun completions" \
  atclone"mv ~/.bun/_bun _bun" \
  atclone"rm -rf */" \
  atpull"%atclone" \
  atload'
    export PATH="$HOME/.bun/bin:$PATH"
    export PATH="$HOME/.cache/.bun/bin:$PATH"
  '
zinit light oven-sh/bun

# alacritty
zinit ice wait'[[ -n $DISPLAY && ! -n "$commands[alacritty]" ]]' lucid as"program" id-as'alacritty' \
  atclone'export PATH="$HOME/.cargo/bin:$PATH"' \
  atclone"cargo build --release --no-default-features --features=wayland" \
  atclone"sudo cp target/release/alacritty /usr/bin" \
  atclone"sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg" \
  atclone"sudo desktop-file-install extra/linux/Alacritty.desktop" \
  atclone"sudo update-desktop-database" \
  atpull"%atclone"
zinit light alacritty/alacritty

# fd
zinit ice wait'[[ ! -n "$commands[fd]" ]]' lucid as"program" from"gh-r" id-as"fd" \
  atclone"mv */fd $BPFX/" \
  atclone"mv */autocomplete/_fd ." \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light sharkdp/fd

# nvim
zinit ice wait'[[ ! -n "$commands[nvim]" ]]' lucid as"program" from"gh-r" id-as"nvim" \
  bpick"nvim-linux-x86_64.appimage" \
  atclone"sudo mv nvim-linux-x86_64.appimage /usr/bin/nvim" \
  atpull"%atclone"
zinit light neovim/neovim

# hx
zinit ice wait'[[ ! -n "$commands[hx]" ]]' lucid as"program" from"gh-r" id-as"hx" \
  atclone"sudo mv */hx /usr/bin/" \
  atclone"mv */runtime ~/.config/helix/" \
  atclone"mv */contrib/completion/hx.zsh _hx" \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light helix-editor/helix

# sing-box
zinit ice wait'[[ ! -n "$commands[sing-box]" ]]' lucid as"program" from"gh-r" id-as"sing-box" \
  bpick"sing-box-*-linux-amd64.tar.gz" \
  atclone"mv */sing-box $BPFX/sing-box" \
  atclone"sudo setcap cap_net_admin=+ep $BPFX/sing-box" \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light SagerNet/sing-box

# zellij
# zinit ice wait'[[ ! -n "$commands[zellij]" ]]' lucid as"program" from"gh-r" id-as"zellij" \
#   bpick"zellij-x86_64-unknown-linux-musl.tar.gz" \
#   atclone"sudo mv zellij /usr/bin/" \
#   atpull"%atclone"
# zinit light zellij-org/zellij

# caddy
# zinit ice wait'[[ ! -n "$commands[caddy]" ]]' lucid as"program" from"gh-r" id-as"caddy" \
#   bpick"caddy_*_linux_amd64.deb" \
#   atclone"sudo cp -rvf ./etc/caddy /etc/" \
#   atclone"sudo cp -rvf ./usr/bin/caddy /usr/bin/" \
#   atclone"rm -rf */" \
#   atpull"%atclone"
# zinit light caddyserver/caddy

###############
### COMMAND ###
###############

# atuin
zinit ice wait'0' lucid as"command" from"gh-r" id-as"atuin" \
  bpick"atuin-*.tar.gz" \
  atclone"mv */atuin atuin" \
  atclone"./atuin init zsh > init.zsh" \
  atclone"./atuin gen-completions --shell zsh > _atuin" \
  atclone"rm -rf */" \
  src"init.zsh" \
  atpull"%atclone"
zinit light atuinsh/atuin

# zoxide
zinit ice wait"1" lucid as"command" from"gh-r" id-as"zoxide" \
  atclone"./zoxide init zsh --cmd j > init.zsh" \
  src"init.zsh" \
  atpull"%atclone"
zinit light ajeetdsouza/zoxide

# direnv
zinit ice wait"2" lucid as"command" from"gh-r" id-as"direnv" \
  atclone"mv direnv* direnv" \
  atclone"./direnv hook zsh > init.zsh" \
  src"init.zsh" \
  atpull"%atclone"
zinit light direnv/direnv

# just
zinit ice wait'[[ ! -n "$commands[just]" ]]' lucid as"command" from"gh-r" id-as"just" \
  atclone'./just --completions zsh > _just' \
  atpull"%atclone"
zinit light casey/just

# delta - A syntax-highlighting pager for git, diff, and grep output
zinit ice wait'[[ ! -n "$commands[delta]" ]]' lucid as"command" from"gh-r" id-as"delta" \
  atclone"mv */delta ." \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light dandavison/delta

# curlie
zinit ice wait'[[ ! -n "$commands[curlie]" ]]' lucid as"command" from"gh-r" id-as"curlie"
zinit light rs/curlie

# hurl
zinit ice wait'[[ ! -n "$commands[hurl]" ]]' lucid as"command" from"gh-r" id-as"hurl" \
  atclone"mv */bin/* ." \
  atclone"mv */completions/_hurl ." \
  atclone"mv */completions/_hurlfmt ." \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light Orange-OpenSource/hurl

# dust
zinit ice wait'[[ ! -n "$commands[dust]" ]]' lucid as"command" from"gh-r" id-as"dust" \
  atclone"sudo mv */dust /usr/bin/" \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light bootandy/dust

# eza - eza is a modern replacement for ls
zinit ice wait'[[ ! -n "$commands[eza]" ]]' lucid as"command" from"gh-r" id-as"eza"
zinit light eza-community/eza

# fx - Command-line tool and terminal JSON viewer
zinit ice wait'[[ ! -n "$commands[fx]" ]]' lucid as"command" from"gh-r" id-as"fx" \
  atclone"mv fx* fx"
zinit light antonmedv/fx

# gh
zinit ice wait'[[ ! -n "$commands[gh]" ]]' lucid as"command" from"gh-r" id-as"gh" \
  atclone"sudo mv */bin/gh /usr/bin/" \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light cli/cli

# glow - Glow is a terminal-based markdown reader designed from the ground up to bring out the beauty—and power—of the CLI
zinit ice wait'[[ ! -n "$commands[glow]" ]]' lucid as"command" from"gh-r" id-as"glow" \
  atclone"mv */glow ." \
  atclone"mv */completions/glow.zsh _glow" \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light charmbracelet/glow

# grex - A command-line tool and library for generating regular expressions from user-provided test cases
zinit ice wait'[[ ! -n "$commands[grex]" ]]' lucid as"command" from"gh-r" id-as"grex"
zinit light pemistahl/grex

# procs - procs is a replacement for ps written in Rust
zinit ice wait'[[ ! -n "$commands[procs]" ]]' lucid as"command" from"gh-r" id-as"procs"
zinit light dalance/procs

# ripgrep - ripgrep recursively searches directories for a regex pattern while respecting your gitignore
zinit ice wait'[[ ! -n "$commands[rg]" ]]' lucid as"command" from"gh-r" id-as"rg" \
  atclone"sudo mv */rg /usr/bin/" \
  atclone"mv */complete/_rg ." \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light burntSushi/ripgrep

# frp - A fast reverse proxy to help you expose a local server behind a NAT or firewall to the internet
zinit ice wait'[[ ! -n "$commands[frpc]" ]]' lucid as"command" from"gh-r" id-as"frp" \
  atclone"mv */frpc $BPFX/" \
  atclone"mv */frps $BPFX/" \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light fatedier/frp

# yazi - file browser
zinit ice wait'[[ ! -n "$commands[yazi]" ]]' lucid as"command" from"gh-r" id-as"yazi" \
  bpick"yazi-x86_64-unknown-linux-musl.zip" \
  atclone"mv yazi*/* ." \
  atclone"mv comp*/_ya ." \
  atclone"mv comp*/_yazi ." \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light sxyazi/yazi

# uv - python package manager
zinit ice wait'[[ ! -n "$commands[uv]" ]]' lucid as"command" from"gh-r" id-as"uv" \
  atclone"mv */* . && ./uv generate-shell-completion zsh > _uv" \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light astral-sh/uv

# fscan
zinit ice wait'[[ ! -n "$commands[fscan]" ]]' lucid as"command" from"gh-r" id-as"fscan" \
  bpick"fscan"
zinit light shadow1ng/fscan

# sttr
zinit ice wait'[[ ! -n "$commands[sttr]" ]]' lucid as"command" from"gh-r" id-as"sttr" \
  atclone"./sttr completion zsh > _sttr" \
  atpull"%atclone"
zinit light abhimanyu003/sttr

# dysk - A linux utility to get information on filesystems, like df but better
zinit ice wait'[[ ! -n "$commands[dysk]" ]]' lucid as"command" from"gh-r" id-as"dysk" \
  atclone"mv */completion/_dysk ." \
  atclone"mv */x86_64-unknown-linux-musl/dysk ." \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light Canop/dysk

# rainfrog - a database management tui
zinit ice wait'[[ -n $DISPLAY && ! -n "$commands[rainfrog]" ]]' lucid as"command" from"gh-r" id-as"rainfrog" \
  atclone"mv rainfrog rain" \
  atpull"%atclone"
zinit light achristmascarl/rainfrog

##################
### COMPLETION ###
##################

# zsh-completions
zinit ice wait"3" blockf lucid id-as"zsh-completions" \
  atpull"zinit creinstall -q ."
zinit light zsh-users/zsh-completions

# docker
zinit ice wait'[[ -n ${ZLAST_COMMANDS[(r)docker]} ]]' lucid as"completion"
zinit snippet "https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker"

# fzf
zinit ice wait'[[ -n ${ZLAST_COMMANDS[(r)fzf]} ]]' lucid as"completion"
zinit snippet "https://raw.githubusercontent.com/lmburns/dotfiles/master/.config/zsh/completions/_fzf"

#############
### Zprof ###
#############
# you need add `zmodload zsh/zprof` to the top of .zshrc file
# zprof | head -n 20; zmodload -u zsh/zprof
# echo "Runtime was: $(echo "$(date +%s.%N) - $start" | bc)"
