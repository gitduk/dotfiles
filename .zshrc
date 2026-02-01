###################
### ZSH OPTIONS ###
###################
# zsh boot time report
# Uncomment to enable profiling
# ZPROF=1
if [[ -n "$ZPROF" ]]; then
  start=$(date +%s.%N)
  zmodload zsh/zprof
fi

# Skip heavy shell initialization for programmatic use (Claude Code, IDE tools, scripts)
# Must be at the very top before any heavy operations
if [[ -n "$ZSH_EXECUTION_STRING" ]] || \
  [[ ! -t 0 ]] || \
  [[ ! -t 1 ]] || \
  [[ "$TERM" = "dumb" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
  export PATH="/opt/zerobrew/prefix/bin:$PATH"
  return 0 2>/dev/null || exit 0
fi

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
setopt NO_NOMATCH    # 如果通配符找不到匹配项，不报错（而是原样输出）

# xhost access control
xhost +local: &>/dev/null

# set bindkey mode to vi
bindkey -v

# zload
zmodload zsh/zle
autoload -Uz add-zsh-hook
autoload -Uz edit-command-line

#################
### Functions ###
#################

# get os id
export OS=$(. /etc/os-release; echo "${ID}")

# proxy settings
function proxy() {
  local proxy_host="127.0.0.1"
  local proxy_port="7890"
  local slient="false"
  local action="set"
  
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--host) proxy_host="$2"; shift 2 ;;
      -p|--port) proxy_port="$2"; shift 2 ;;
      -s|--slient) slient="true"; shift ;;
      -u|--unset) action="unset"; shift ;;
      *) break ;;
    esac
  done
  
  if [[ "$action" == "unset" ]]; then
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY
    return 0
  fi
  
  export http_proxy="http://${proxy_host}:${proxy_port}"
  export HTTP_PROXY="$http_proxy"
  export https_proxy="http://${proxy_host}:${proxy_port}"
  export HTTPS_PROXY="$https_proxy"
  export no_proxy="localhost,127.0.0.1"
  export NO_PROXY="$no_proxy"
  [[ "$slient" == "false" ]] && echo "✓ Proxy set: ${proxy_host}:${proxy_port}"
}

############
### MUST ###
############

# install tool
function instr() {
  case "$OS" in
    debian | ubuntu)
      sudo apt install -y $@ || { echo "Failed to install: $@"; return 1 }
      ;;
    fedora | centos | rocky | almalinux)
      sudo dnf install -y $@ || { echo "Failed to install: $@"; return 1 }
      ;;
    rhel)
      sudo yum install -y $@ || { echo "Failed to install: $@"; return 1 }
      ;;
    *)
      echo "Unsupported OS: $OS"
      return 1
      ;;
  esac
}

command -v git &>/dev/null || instr git
command -v curl &>/dev/null || instr curl

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
[[ ! -d "$HOME/.local/bin" ]] && mkdir -p $HOME/.local/bin

# Add the following snippet as the first plugin in your configuration
zinit light-mode for zdharma-continuum/zinit-annex-bin-gem-node

# starship
zinit ice lucid as"program" from"gh-r" id-as"starship" \
  atclone"./starship completions zsh > _starship" \
  atpull"%atclone" \
  atload'
    export STARSHIP_CONFIG=~/.starship.toml
    eval "$(starship init zsh)"
  '
zinit light starship/starship

###############
### Plugins ###
###############

# zsh-completions
zinit ice wait"0" blockf lucid id-as"zsh-completions" \
  atpull"zinit creinstall -q ."
zinit light zsh-users/zsh-completions

# compinit
zinit ice wait"0a" lucid nocompile id-as"compinit" \
  atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay"
zinit light zdharma-continuum/null

# settings & functions
zinit ice wait"0b" lucid as"program" id-as"autoload" \
  atinit"fpath+=~/.zsh.d/functions" \
  atload'
    autoload -Uz ~/.zsh.d/functions/**/*(:t)
    for script (~/.zsh.d/*.zsh(N)) source $script
  '
zinit light zdharma-continuum/null

# zsh-users/zsh-autosuggestions
zinit ice wait"0b" lucid id-as"zsh-autosuggestions" \
  atload"!_zsh_autosuggest_start" \
  atload"
    export ZSH_AUTOSUGGEST_MANUAL_REBIND='1'
    export ZSH_AUTOSUGGEST_STRATEGY=(completion match_prev_cmd)
    export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
    bindkey -M viins '^q' autosuggest-clear
    bindkey -M viins '^ ' autosuggest-execute
    bindkey -M vicmd '^ ' autosuggest-execute
  "
zinit light zsh-users/zsh-autosuggestions

# zdharma-continuum/fast-syntax-highlighting
zinit ice wait"0b" lucid id-as"fast-syntax-highlighting"
zinit light zdharma-continuum/fast-syntax-highlighting

# Aloxaf/fzf-tab
zinit ice wait"0c" lucid id-as"fzf-tab" \
  atload"zstyle ':fzf-tab:*' fzf-flags --ansi"
zinit light Aloxaf/fzf-tab

# zsh-users/zsh-history-substring-search
zinit ice wait"1" lucid id-as"zsh-history-substring-search" \
  atload"
    export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=''
    bindkey '^k' history-substring-search-up
    bindkey '^j' history-substring-search-down
  "
zinit light zsh-users/zsh-history-substring-search

# sudo
zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh

# extract
zinit snippet OMZ::plugins/extract/extract.plugin.zsh

#############
### Tools ###
#############

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
    command -v sccache &>/dev/null && export RUSTC_WRAPPER=$(command -v sccache)
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

# bun - Bun is an all-in-one toolkit for JavaScript and TypeScript apps
zinit ice wait"1" lucid as"program" from"gh-r" id-as"bun" \
  bpick"bun-linux-x64.zip" extract"!" \
  atclone'
    wget https://raw.githubusercontent.com/oven-sh/bun/refs/heads/main/completions/bun.zsh -O _bun
  ' \
  atpull"%atclone" \
  atload'
    export BUN_INSTALL=$HOME/.local
  '
zinit light oven-sh/bun

# vfox - cross-platform and extendable version manager
zinit ice wait"1" lucid as"program" from"gh-r" id-as"vfox" \
  bpick"vfox_*_linux_x86_64.tar.gz" extract"!" \
  atclone'mv */zsh_autocomplete _vfox' \
  atpull"%atclone" \
  atload'eval "$(vfox activate zsh)"'
zinit light version-fox/vfox

# direnv
zinit ice wait"1" lucid as"program" from"gh-r" id-as"direnv" \
  atclone'mv direnv* direnv' \
  atpull"%atclone" \
  atload'eval "$(direnv hook zsh)"'
zinit light direnv/direnv

# zoxide - quick jump dir
zinit ice wait"0" lucid as"null" from"gh-r" id-as"zoxide" \
  atclone'ln -sf $PWD/zoxide ~/.local/bin/zoxide' \
  atpull"%atclone" \
  atload'eval "$(zoxide init zsh --cmd j)"'
zinit light ajeetdsouza/zoxide

# fzf - essential tool, load early
zinit ice wait"1" lucid as"null" from"gh-r" id-as"fzf" \
  atclone'
    ln -sf $PWD/fzf ~/.local/bin/fzf
    fzf --zsh > init.zsh
  ' \
  atpull"%atclone" \
  src"init.zsh"
zinit light junegunn/fzf

# atuin - command history, load after compinit for completion support
zinit ice wait"0" lucid as"null" from"gh-r" id-as"atuin" \
  bpick"atuin-*.tar.gz" extract"!" \
  atclone'
    ln -sf $PWD/atuin ~/.local/bin/atuin
    atuin init zsh > init.zsh
    atuin gen-completions --shell zsh > _atuin
  ' \
  atpull"%atclone" \
  src"init.zsh"
zinit light atuinsh/atuin

# navi - cheatsheet tool, load after widgets
zinit ice wait"0" lucid as"program" from"gh-r" id-as"navi" \
  atload'
    export NAVI_PATH="$HOME/.config/navi/cheats"
    export NAVI_CONFIG="$HOME/.config/navi/config.yaml"
    [[ ! -d "$NAVI_PATH" ]] && mkdir -p $NAVI_PATH
    [[ ! -e "$NAVI_CONFIG" ]] && navi info config-example > $NAVI_CONFIG
    eval "$(navi widget zsh)"
    bindkey "^N" _navi_widget
  '
zinit light denisidoro/navi

# display
zinit ice if'[[ -n $DISPLAY ]]' lucid as"null" id-as"display" \
  atclone'
    command -v foot &>/dev/null || instr foot
    command -v kitty &>/dev/null || instr kitty
  ' \
  atpull"%atclone"
zinit light zdharma-continuum/null

# bat
zinit ice if'[[ ! -x $commands[bat] ]]' lucid as"null" from"gh-r" id-as"bat" \
  completions extract"!" \
  atclone'
    ln -sf $PWD/bat ~/.local/bin/cat
    bat --completion zsh > _bat
  ' \
  atpull"%atclone"
zinit light sharkdp/bat

# eza - eza is a modern replacement for ls
zinit ice if'[[ ! -x $commands[eza] ]]' lucid as"null" from"gh-r" id-as"eza" \
  atclone'ln -sf $PWD/eza ~/.local/bin/ls' \
  atpull"%atclone"
zinit light eza-community/eza

# delta - A syntax-highlighting pager for git, diff, and grep output
zinit ice if'[[ ! -x $commands[delta] ]]' lucid as"null" from"gh-r" id-as"delta" \
  extract"!" \
  atclone'ln -sf $PWD/delta ~/.local/bin/delta' \
  atpull"%atclone"
zinit light dandavison/delta

# fd
zinit ice if'[[ ! -x $commands[fd] ]]' lucid as"null" from"gh-r" id-as"fd" \
  completions extract"!" \
  atclone'sudo ln -sf $PWD/fd /usr/bin/fd' \
  atpull"%atclone"
zinit light sharkdp/fd

# dust
zinit ice if'[[ ! -x $commands[dust] ]]' lucid as"null" from"gh-r" id-as"dust" \
  completions extract"!" \
  atclone'
    sudo ln -sf $PWD/dust /usr/bin/dust
    wget https://raw.githubusercontent.com/bootandy/dust/refs/heads/master/completions/_dust
  ' \
  atpull"%atclone"
zinit light bootandy/dust

# dysk - A linux utility to get information on filesystems, like df but better
zinit ice if'[[ ! -x $commands[dysk] ]]' lucid as"null" from"gh-r" id-as"dysk" \
  completions \
  atclone'
    mv */completion/_dysk .
    mv */x86_64-unknown-linux-musl/dysk .
    ln -sf $PWD/dysk ~/.local/bin/dysk
    rm -rf */
  ' \
  atpull"%atclone"
zinit light Canop/dysk

# just
zinit ice if'[[ ! -x $commands[just] ]]' lucid as"null" from"gh-r" id-as"just" \
  completions \
  atclone'
    ln -sf $PWD/just ~/.local/bin/just
    just --completions zsh > _just
  ' \
  atpull"%atclone"
zinit light casey/just

# nvim
zinit ice if'[[ ! -x $commands[nvim] ]]' lucid as"null" from"gh-r" id-as"nvim" \
  bpick"nvim-linux-x86_64.appimage" \
  atclone'sudo ln -sf $PWD/nvim-linux-x86_64.appimage /usr/bin/nvim' \
  atpull"%atclone"
zinit light neovim/neovim

# easytier
zinit ice if'[[ ! -x $commands[easytier-cli] ]]' lucid as"null" from"gh-r" id-as"easytier" \
  extract"!" \
  atclone'
    sudo ln -sf $PWD/easytier-cli /usr/bin/easytier-cli
    sudo ln -sf $PWD/easytier-core /usr/bin/easytier-core
  ' \
  atpull"%atclone"
zinit light EasyTier/EasyTier

# lnav
zinit ice if'[[ ! -x $commands[lnav] ]]' lucid as"null" from"gh-r" id-as"lnav" \
  extract"!" \
  atclone'ln -sf $PWD/lnav ~/.local/bin/lnav' \
  atpull"%atclone"
zinit light tstack/lnav

# snitch - a prettier way to inspect network connections
zinit ice if'[[ ! -x $commands[snitch] ]]' lucid as"null" from"gh-r" id-as"snitch" \
  completions \
  atclone'
    ln -sf $PWD/snitch ~/.local/bin/snitch
    snitch completion zsh > _snitch
  ' \
  atpull"%atclone"
zinit light karol-broda/snitch

# serie - A rich git commit graph in your terminal, like magic 📚
zinit ice if'[[ ! -x $commands[se] ]]' lucid as"null" from"gh-r" id-as"se" \
  atclone'ln -sf $PWD/serie ~/.local/bin/se' \
  atpull"%atclone"
zinit light lusingander/serie

# fastfetch
zinit ice if'[[ ! -x $commands[fastfetch] ]]' lucid as"null" from"gh-r" id-as"fastfetch" \
  bpick"fastfetch-linux-amd64.tar.gz" extract"!" \
  atclone'ln -sf $PWD/usr/bin/fastfetch ~/.local/bin/fastfetch' \
  atpull"%atclone"
zinit light fastfetch-cli/fastfetch

# uv - python package manager
zinit ice if'[[ ! -x $commands[uv] ]]' lucid as"null" from"gh-r" id-as"uv" \
  extract"!" \
  atclone'
    ./uv generate-shell-completion zsh > _uv
    ls -sf $PWD/uv ~/.local/bin/uv
  ' \
  atpull"%atclone"
zinit light astral-sh/uv

# zb - Homebrew alternative
zinit ice if'[[ ! -x $commands[zb] ]]' lucid as"null" run-atpull id-as"zb" \
  atclone"curl -sSL https://raw.githubusercontent.com/lucasgelfond/zerobrew/main/install.sh | bash" \
  atpull"%atclone"
zinit light zdharma-continuum/null
export PATH="/opt/zerobrew/prefix/bin:$PATH"

# wallust
zinit ice if'[[ -n $DISPLAY && ! -x $commands[wallust] ]]' lucid as"null" from"codeberg.org" id-as"wallust" \
  atclone"cargo +nightly install --path ." \
  atpull"%atclone"
zinit light explosion-mental/wallust

# feedr
zinit ice if'[[ ! -x $commands[feedr] ]]' lucid as"null" from"gh-r" id-as"feedr" \
  atclone'
    mv feedr* feedr
    ln -sf $PWD/feedr ~/.local/bin/feedr
  ' \
  atpull"%atclone"
zinit light bahdotsh/feedr

# pueue
zinit ice if'[[ ! -x $commands[pueue] ]]' lucid as"null" from"gh-r" id-as"pueue" \
  bpick"pueue-x86_64-unknown-linux-musl" \
  bpick"pueued-x86_64-unknown-linux-musl" \
  completions \
  atclone'
    chmod +x pueue*
    ln -sf $PWD/pueue-x86_64-unknown-linux-musl ~/.local/bin/pueue
    ln -sf $PWD/pueued-x86_64-unknown-linux-musl ~/.local/bin/pueued
    pueue completions zsh > _pueue
  ' \
  atpull"%atclone"
zinit light Nukesor/pueue

# witr
zinit ice if'[[ ! -x $commands[witr] ]]' lucid as"null" from"gh-r" id-as"witr" \
  bpick"witr-linux-amd64" \
  atclone'ln -sf $PWD/witr-linux-amd64 ~/.local/bin/witr' \
  atpull"%atclone"
zinit light pranshuparmar/witr

# claude-code
zinit ice if'[[ ! -x $commands[claude] ]]' lucid as"null" run-atpull id-as"claude" \
  atclone"curl -fsSL https://claude.ai/install.sh | bash" \
  atpull"%atclone"
zinit light zdharma-continuum/null

# sttr
zinit ice if'[[ ! -x $commands[sttr] ]]' lucid as"null" from"gh-r" id-as"sttr" \
  atclone'
    ln -sf $PWD/sttr ~/.local/bin/sttr
    sttr completion zsh > _sttr
  ' \
  atpull"%atclone"
zinit light abhimanyu003/sttr

# xh
zinit ice if'[[ ! -x $commands[xh] ]]' lucid as"null" from"gh-r" id-as"xh" \
  completions extract"!" \
  atclone'
    mv completions/_xh ./
    ln -sf $PWD/xh ~/.local/bin/xh
    rm -rf */
  ' \
  atpull"%atclone"
zinit light ducaale/xh

# hl - A fast and powerful log viewer and processor that converts JSON logs or logfmt logs into a clear human-readable format
zinit ice if'[[ ! -x $commands[hl] ]]' lucid as"null" from"gh-r" id-as"hl" \
  bpick"hl-linux-x86_64-musl.tar.gz" \
  atclone'ln -sf $PWD/hl ~/.local/bin/hl' \
  atpull"%atclone"
zinit light pamburus/hl

# fx - Command-line tool and terminal JSON viewer
zinit ice if'[[ ! -x $commands[fx] ]]' lucid as"null" from"gh-r" id-as"fx" \
  completions \
  atclone'
    ln -sf $PWD/fx* ~/.local/bin/fx
    fx --comp zsh > _fx
  ' \
  atpull"%atclone"
zinit light antonmedv/fx

# tw - view and query tabular data files, such as CSV, TSV, and parquet
zinit ice if'[[ ! -x $commands[tw] ]]' lucid as"null" from"gh-r" id-as"tw" \
  bpick"tw-x86_64-unknown-linux-gnu" \
  atclone'ln -sf $PWD/tw* ~/.local/bin/tw' \
  atpull"%atclone"
zinit light shshemi/tabiew

# ripgrep - ripgrep recursively searches directories for a regex pattern
zinit ice if'[[ ! -x $commands[rg] ]]' lucid as"null" from"gh-r" id-as"rg" \
  completions extract"!" \
  atclone'
    sudo ln -sf $PWD/rg /usr/bin/rg
    mv complete/_rg .
    rm -rf */
  ' \
  atpull"%atclone"
zinit light burntSushi/ripgrep

# yazi - file browser
zinit ice if'[[ ! -x $commands[yazi] ]]' lucid as"null" from"gh-r" id-as"yazi" \
  bpick"yazi-x86_64-unknown-linux-musl.zip" completions extract"!" \
  atclone'
    mv comp*/_ya .
    mv comp*/_yazi .
    ln -sf $PWD/ya ~/.local/bin/ya
    ln -sf $PWD/yazi ~/.local/bin/yazi
    rm -rf */
  ' \
  atpull"%atclone"
zinit light sxyazi/yazi

# fscan
zinit ice if'[[ ! -x $commands[fscan] ]]' lucid as"null" from"gh-r" id-as"fscan" \
  atclone'ln -sf $PWD/fscan ~/.local/bin/fscan' \
  atpull"%atclone"
zinit light shadow1ng/fscan

# rainfrog - a database management tui
zinit ice if'[[ ! -x $commands[rain] ]]' lucid as"null" from"gh-r" id-as"rain" \
  atclone'ln -sf $PWD/rainfrog ~/.local/bin/rain' \
  atpull"%atclone"
zinit light achristmascarl/rainfrog

# sing-box
zinit ice if'[[ ! -x $commands[sing-box] ]]' lucid as"null" from"gh-r" id-as"sing-box" \
  bpick"sing-box-*-linux-amd64.tar.gz" extract"!" \
  atclone'
    ln -sf $PWD/sing-box ~/.local/bin/sing-box
    sudo setcap cap_net_admin=+ep $PWD/sing-box
  ' \
  atpull"%atclone"
zinit light SagerNet/sing-box

# yaak - The most intuitive desktop API client
zinit ice if'[[ -n $DISPLAY && ! -x $commands[yaak] ]]' lucid as"null" from"gh-r" id-as"yaak" \
  bpick"yaak_*_amd64.AppImage" \
  atclone'ln -sf $PWD/yaak* ~/.local/bin/yaak' \
  atpull"%atclone"
zinit light mountain-loop/yaak

# gh
zinit ice if'[[ ! -x $commands[gh] ]]' lucid as"null" from"gh-r" id-as"gh" \
  completions extract"!" \
  atclone'
    sudo ln -sf $PWD/bin/gh /usr/bin/gh
    gh completion -s zsh > _gh
  ' \
  atpull"%atclone"
zinit light cli/cli

# alacritty
zinit ice if'[[ -n $DISPLAY && ! -x $commands[alacritty] ]]' lucid as"null" id-as"alacritty" \
  atclone'
    export PATH="$HOME/.cargo/bin:$PATH"
    cargo build --release --no-default-features --features=wayland
    sudo ln -sf $PWD/target/release/alacritty /usr/bin/alacritty
    sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
    sudo desktop-file-install extra/linux/Alacritty.desktop
    sudo update-desktop-database
  ' \
  atpull"%atclone"
zinit light alacritty/alacritty

###################
### Completions ###
###################

# docker
zinit ice if'[[ -n ${ZLAST_COMMANDS[(r)docker]} ]]' lucid as"completion"
zinit snippet "https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker"

#############
### Zprof ###
#############
# you need add `zmodload zsh/zprof` to the top of .zshrc file
if [[ -n "$ZPROF" ]]; then
  zprof | head -n 20
  zmodload -u zsh/zprof
  echo "Runtime was: $(echo "$(date +%s.%N) - $start" | bc)"
fi

