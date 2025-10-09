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

# zload
zmodload zsh/zle
autoload -Uz add-zsh-hook
autoload -Uz edit-command-line

############
### ENVS ###
############

export OS="$(cat /etc/os-release | grep '^ID=' | awk -F '=' '{printf $2}' | tr -d '"')"

# Proxy settings
function setup_proxy() {
  local PROXY_HOST="${1:-${PROXY_HOST:-127.0.0.1}}"
  local PROXY_PORT="${2:-${PROXY_PORT:-7890}}"
  if timeout 0.5 bash -c "echo >/dev/tcp/${PROXY_HOST}/${PROXY_PORT}" 2>/dev/null; then
    export http_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
    export HTTP_PROXY="$http_proxy"
    export https_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
    export HTTPS_PROXY="$https_proxy"
    export no_proxy="localhost,127.0.0.1"
    export NO_PROXY="$no_proxy"
  fi
}
function unset_proxy() {
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
  unset no_proxy NO_PROXY
}

# Proxy settings
[[ -n "$DISPLAY" ]] && setup_proxy

# PATH management
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
export ZSH_COMPLETIONS="$HOME/.zsh.d/completions"
[[ ! -d "$ZSH_COMPLETIONS" ]] && mkdir -p "$ZSH_COMPLETIONS"
fpath=($ZSH_COMPLETIONS $fpath)

############
### MUST ###
############

# installer
function ins() {
  case "$OS" in
    debian | ubuntu)
      sudo nala install -y $@ || { echo "Failed to install: $@"; return 1 }
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

if ! command -v nala &>/dev/null; then
  case "$OS" in
    debian | ubuntu)
      sudo apt install -y nala
      ;;
  esac
fi

command -v git &>/dev/null || ins git
command -v git &>/dev/null || ins curl

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

# prompt
zinit ice lucid as"program" from"gh-r" id-as"starship" \
  atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
  atload"export STARSHIP_CONFIG=~/.starship.toml" \
  src"init.zsh" \
  atpull"%atclone"
zinit light starship/starship

# must
zinit ice if'[[ ! -f ~/.must.ok && $OS == "ubuntu" ]]' lucid as"program" id-as"must" \
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
zinit ice if'[[ -n $DISPLAY && ! -f ~/.desktop.ok ]]' lucid as"program" id-as"display" \
  atload'
    ok=0
    command -v foot &>/dev/null || ins foot || ok=1
    command -v kitty &>/dev/null || ins kitty || ok=1
    [[ $ok -eq 0 ]] && touch ~/.display.ok
  '
zinit light zdharma-continuum/null

############
### Brew ###
############

# brew
zinit ice wait"1" lucid as"program" id-as"brew" \
  atclone'
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    /home/linuxbrew/.linuxbrew/bin/brew shellenv > init.zsh
    /home/linuxbrew/.linuxbrew/bin/brew install lnav
    ' \
  atpull"%atclone" \
  atload'
    export HOMEBREW_NO_AUTO_UPDATE=true
    export HOMEBREW_AUTO_UPDATE_SECS=$((60 * 60 * 24))
    ' \
  src"init.zsh"
zinit light zdharma-continuum/null

#################
### Languages ###
#################

# rustup
zinit ice wait"1" lucid as"program" id-as"rustup" \
  atclone"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    $HOME/.cargo/bin/rustup completions zsh > _rustup
    $HOME/.cargo/bin/rustup completions zsh cargo > _cargo
    $HOME/.cargo/bin/cargo install --root $HOME/.local --locked wallust
    command -v wallust &>/dev/null && wallust theme base16-default-dark -s
    " \
  atpull"%atclone" \
  atload'
    export PATH="$HOME/.cargo/bin:$PATH"
    export CARGO_INSTALL_ROOT="$HOME/.local"
    command -v sccache &>/dev/null && export RUSTC_WRAPPER="$(command -v sccache)"
  '
zinit light zdharma-continuum/null

# golang
zinit ice wait"1" lucid as"program" id-as"golang" \
  atclone'
    version=$(curl -s https://raw.githubusercontent.com/actions/go-versions/main/versions-manifest.json|jq -r ".[0].version")
    wget -c https://go.dev/dl/go${version}.linux-amd64.tar.gz -P /tmp
    [[ -d /usr/local/go ]] && sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go$version.linux-amd64.tar.gz
    ' \
  atload'
    export GOPATH="$HOME/go"
    export GOBIN="$GOPATH/bin"
    export PATH="/usr/local/go/bin:$GOBIN:$PATH"
    export GOPROXY="https://goproxy.cn,https://mirrors.aliyun.com/goproxy,https://goproxy.io,direct"
    export GOPRIVATE="*.corp.example.com,rsc.io/private"
    export GOSUMDB="sum.golang.org"
    export GO111MODULE=on
    ' \
  atpull"%atclone"
zinit light zdharma-continuum/null


##############################
### Custom Config & Script ###
##############################

# settings & functions
zinit ice wait"0" lucid as"program" id-as"autoload" \
  atinit"fpath+=~/.zsh.d/functions" \
  atload'
    autoload -Uz ~/.zsh.d/functions/**/*(:t)
    for script (~/.zsh.d/*.zsh(N)) source $script
    [[ -f ~/.alias.zsh ]] && source ~/.alias.zsh
    [[ -f ~/.alias.custom.zsh ]] && source ~/.alias.custom.zsh
    [[ -f ~/.installer.zsh ]] && source ~/.installer.zsh
  '
zinit light zdharma-continuum/null

###############
### Plugins ###
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
  atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay"
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

# Aloxaf/fzf-tab
zinit ice wait"1" lucid id-as"fzf-tab" \
  atload"
    zstyle ':fzf-tab:*' fzf-flags --ansi
  "
zinit light Aloxaf/fzf-tab

# sudo
zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh

# extract
zinit snippet OMZ::plugins/extract/extract.plugin.zsh

###################
### Completions ###
###################

# docker
zinit ice if'[[ -n ${ZLAST_COMMANDS[(r)docker]} ]]' lucid as"completion"
zinit snippet "https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker"

# fzf
zinit ice if'[[ -n ${ZLAST_COMMANDS[(r)fzf]} ]]' lucid as"completion"
zinit snippet "https://raw.githubusercontent.com/lmburns/dotfiles/master/.config/zsh/completions/_fzf"

#############
### Zprof ###
#############
# you need add `zmodload zsh/zprof` to the top of .zshrc file
if [[ -n "$ZPROF" ]]; then
  zprof | head -n 20
  zmodload -u zsh/zprof
  echo "Runtime was: $(echo "$(date +%s.%N) - $start" | bc)"
fi
