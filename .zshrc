# ###  Zsh Config  ############################################################

# zsh boot time report
# start=$(date +%s.%N)
# zmodload zsh/zprof

# zsh opts
setopt AUTOCD                 # 免输入cd进入目录
setopt AUTO_PUSHD             # Push the current directory visited on the stack.
setopt PUSHD_IGNORE_DUPS      # Do not store duplicates in the stack.
setopt PUSHD_SILENT           # Do not print the directory stack after pushd or popd.
setopt PUSHDMINUS

setopt AUTO_MENU              # Show completion menu on a successive tab press.
setopt AUTO_LIST              # Automatically list choices on ambiguous completion.
setopt AUTO_PARAM_SLASH       # If completed parameter is a directory, add a trailing slash.

setopt COMPLETE_IN_WORD       # Complete from both ends of a word.
setopt ALWAYS_TO_END          # Move cursor to the end of a completed word.
setopt PATH_DIRS              # Perform path search even on command names with slashes.
setopt EXTENDED_GLOB          # Needed for file modification glob modifiers with compinit.
setopt MENU_COMPLETE          # Autoselect the first completion entry.
setopt FLOW_CONTROL           # Ensable start/stop characters in shell editor.
setopt HIST_IGNORE_ALL_DUPS   # 移除重复的命令历史
setopt NONOMATCH              # 设置可以使用通配符
setopt PROMPTSUBST

# custom path
export ZPFX="$HOME/.local"
export ZLOAD="$HOME/.autoload"
export ZCOMP="$HOME/.completions"
export ZPLUG="$HOME/.plugins"

# set fpath
fpath+=("$ZLOAD" "$ZCOMP" "$ZPLUG")

# enable hidden files completion
_comp_options+=(globdots)

# xhost access control
xhost +local: &>/dev/null

# completion
ZCOMPDUMP_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump-${ZSH_VERSION}"
if [[ ! -e "$ZCOMPDUMP_FILE" ]]; then
  autoload -Uz compinit -C -d "$ZCOMPDUMP_FILE"
else
  autoload -Uz compinit -d "$ZCOMPDUMP_FILE"
fi
compinit -u
zmodload zsh/complist

# set bindkey mode to vi
bindkey -v

# zstyle
source $HOME/.zstyle.zsh

# ###  Autoload  ##############################################################

ls "$HOME/.autoload" | while read -n file; do
  autoload -Uz $file
done

# ###  Snippet  ###############################################################

# widgets
source $HOME/.widgets.zsh

# alias
source $HOME/.alias.zsh

# ###  Plugin  ################################################################

# load plugin
source $HOME/.plugin.zsh

# dotenv
export ZSH_DOTENV_FILE='.env'
export ZSH_CLEAR_FILE='.clear'
export ZSH_DOTENV_PROMPT=false
export PROJECT_TAG=("venv" ".git" ".idea" ".env" ".vscode" ".clear")
export ZSH_DOTENV_ALLOWED_LIST='${ZSH_CACHE_DIR:-$ZSH/cache}/dotenv-allowed.list'
export ZSH_DOTENV_DISALLOWED_LIST='${ZSH_CACHE_DIR:-$ZSH/cache}/dotenv-disallowed.list'

# zsh-autosuggestions
export ZSH_AUTOSUGGEST_MANUAL_REBIND='1'
export ZSH_AUTOSUGGEST_STRATEGY=(completion match_prev_cmd)
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# zsh-history-substring-search
export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=''

# ###  Brew  ##################################################################

# set remote
# export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
# export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
# export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"

export HOMEBREW_NO_AUTO_UPDATE=true             # 关闭自动更新
export HOMEBREW_AUTO_UPDATE_SECS=$((60*60*24))  # 自动更新间隔时间

# brew installer
if ! hash brew &> /dev/null; then
  sudo apt install -y libbz2-dev libcurl4-openssl-dev libexpat-dev libncurses-dev zlib1g-dev
  git clone --depth=1 "https://github.com/Homebrew/brew" $HOME/.linuxbrew
fi

# ###  Npm  ###################################################################

# installer
hash npm &> /dev/null || sudo apt install -y npm

# ###  Golang  ################################################################

# Set the Go proxy
export GOPROXY=https://goproxy.cn,https://mirrors.aliyun.com/goproxy,https://goproxy.io,direct

# Enable Go modules
export GO111MODULE=on

# Disable the Go checksum database
export GOSUMDB=off

# 1.13 开始支持，配置私有 module，不去校验 checksum
export GOPRIVATE=*.corp.example.com,rsc.io/private

# go installer
if ! hash go &> /dev/null; then
  go_version="1.21.3"
  wget -c "https://go.dev/dl/go1.21.3.linux-amd64.tar.gz" -P /tmp
  sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go$go_version.linux-amd64.tar.gz
fi

# ###  Rust  ##################################################################

# set build wrapper
export RUSTC_WRAPPER="$HOMEBREW_PREFIX/bin/sccache"

# rustup installer
hash rustup &> /dev/null || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# ###  Application  ###########################################################

source $HOME/.app.zsh

# ###  Keybind  ###############################################################

source $HOME/.keybind.zsh

# ###  Starship  ##############################################################

# starship: shell prompts
export STARSHIP_CONFIG=~/.starship.toml
eval "$(starship init zsh)"

# ###  Zprof  #################################################################
# you need add `zmodload zsh/zprof` to the top of .zshrc file
# echo "Runtime was: $(echo "$(date +%s.%N) - $start" | bc)"
# zprof | head -n 20; zmodload -u zsh/zprof

