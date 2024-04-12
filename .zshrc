# ###  Zsh Config  ############################################################

# zsh boot time report
# start=$(date +%s.%N)
# zmodload zsh/zprof

# completion
# 加载 compinit 函数,但不执行
autoload -Uz compinit

# 设置补全转储文件路径
zstyle ':completion::complete:*' use-cache 1

ZCOMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump-$ZSH_VERSION"
zstyle ':completion::complete:*' cache-path "$ZCOMPDUMP"

# 检查补全转储文件是否存在, 如果不存在,则生成新的转储文件, 否则,从现有转储文件加载补全定义
if [[ -f "$ZCOMPDUMP" ]]; then
  compinit -i -d "$ZCOMPDUMP"
else
  compinit -C -d "$ZCOMPDUMP"
fi

# 加载所有新的未加载的补全定义
compinit -u

# 加载控制补全列表显示的模块
zmodload zsh/complist

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
export ZLOAD="$ZSH_DIR/autoload"
export ZCOMP="$ZSH_DIR/completions"
export ZPLUG="$PLUGIN_DIR/zsh"

# set fpath
fpath+=($ZLOAD $ZCOMP $ZPLUG)

# enable hidden files completion
_comp_options+=(globdots)

# xhost access control
xhost +local: &>/dev/null

# set bindkey mode to vi
bindkey -v

# set proxy
export http_proxy="http://127.0.0.1:7890"
export https_proxy="http://127.0.0.1:7890"
export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"

# ###  Autoload  ##############################################################

# autoload
if [[ -d "$ZLOAD" ]]; then
  files=("$ZLOAD"/*(N))
  for file in "${files[@]}"; do
    autoload -Uz $file
  done
fi

# source
if [[ -d "$ZSH_DIR" ]]; then
  files=("$ZSH_DIR"/*.zsh(N))
  for file in "${files[@]}"; do
    source "$file"
  done
fi

# ###  Brew  ##################################################################

# set remote
# export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
# export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
# export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"

export HOMEBREW_NO_AUTO_UPDATE=true             # 关闭自动更新
export HOMEBREW_AUTO_UPDATE_SECS=$((60*60*24))  # 自动更新间隔时间

# brew installer
hash brew &> /dev/null || curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash

# ###  Npm  ###################################################################

# installer
hash npm &> /dev/null || curl -qL https://www.npmjs.com/install.sh | sh

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

# ###  Starship  ##############################################################

# starship: shell prompts
export STARSHIP_CONFIG=~/.starship.toml
hash starship 2>/dev/null && eval "$(starship init zsh)"

# ###  Zprof  #################################################################
# you need add `zmodload zsh/zprof` to the top of .zshrc file
# zprof | head -n 20; zmodload -u zsh/zprof
# echo "Runtime was: $(echo "$(date +%s.%N) - $start" | bc)"

