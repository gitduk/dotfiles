# ###  Zsh Config  ############################################################

# zsh boot time report
# start=$(date +%s.%N)
# zmodload zsh/zprof

# completion
# load compinit, but not execute
autoload -Uz compinit

# set completion cache
zstyle ':completion::complete:*' use-cache 1

# set cache dir
ZCOMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump-$ZSH_VERSION"
zstyle ':completion::complete:*' cache-path "$ZCOMPDUMP"

# load or generation zsh complete cache file
if [[ -f "$ZCOMPDUMP" ]]; then
  compinit -i -d "$ZCOMPDUMP"
else
  compinit -C -d "$ZCOMPDUMP"
fi
compinit -u

# load complist
zmodload zsh/complist

# zsh opts
setopt AUTOCD                 # enter dir without cd command
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
setopt HIST_IGNORE_ALL_DUPS   # remove dups command
setopt NONOMATCH              # re mode
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

# init nala package
if ! hash nala &>/dev/null; then
  sudo apt update && sudo apt install -y nala
  apps=(
    "jq"
    "gh"
    "curl"
    "lua5.3"
    "aria2"
    "cmake"
    "meson"
    "scdoc"
    "foot"
    "tmux"
    "silversearcher-ag"
    "sqlite3"
    "redshift"
    "nmap"
    "inotify-tools"
    "sccache"
    "chromium-browser"
    "s-nail"
  )

  for app in "${apps[@]}"; do
    sudo nala install -y $app
  done

fi

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

# cadd list
export AUTOADD_DIRS=(
  "$HOME/.zsh.d/"
  "$HOME/.etc.d/"
  "$HOME/.tmux.d/"
  "$HOME/.config/dockge/"
  "$HOME/.config/hypr/"
  "$HOME/.config/nvim/lua/"
  "$HOME/.config/systemd/user/"
  "$HOME/.local/share/applications/"
  "$HOME/.docker/homepage/"
)

# ###  Brew  ##################################################################

# set remote
# export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
# export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
# export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"

# brew options
export HOMEBREW_PREFIX="$HOME/.linuxbrew";
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar";
export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX/Homebrew";
export HOMEBREW_NO_AUTO_UPDATE=true                               # 关闭自动更新
export HOMEBREW_AUTO_UPDATE_SECS=$((60*60*24))                    # 自动更新间隔时间
export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH:+:$MANPATH}";
export INFOPATH="$HOMEBREW_PREFIX/share/info:$INFOPATH";

# add brew to path
addPath "$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin";
addPath "$HOMEBREW_PREFIX/opt/llvm/bin";

# install brew
if ! hash brew &>/dev/null; then
  git clone --depth 1 https://github.com/Homebrew/brew $HOMEBREW_PREFIX
  brew update --force --quiet
  chmod -R go-w "$(brew --prefix)/share/zsh"
fi

# ###  Npm  ###################################################################

# add npm to path
addPath "$HOME/.npm/bin"

# install npm
hash node &>/dev/null || sudo apt install nodejs
hash npm &>/dev/null || curl -qL https://www.npmjs.com/install.sh | sh

# ###  Golang  ################################################################

# Set the Go proxy
export GOPROXY=https://goproxy.cn,https://mirrors.aliyun.com/goproxy,https://goproxy.io,direct

# Enable Go modules
export GO111MODULE=on

# Go checksum database
export GOSUMDB=off

# 1.13 开始支持，配置私有 module，不去校验 checksum
export GOPRIVATE=*.corp.example.com,rsc.io/private

# install golang
if ! hash go &>/dev/null; then
  go_version="1.22.2"
  wget -c "https://go.dev/dl/go${go_version}.linux-amd64.tar.gz" -P /tmp
  sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf /tmp/go$go_version.linux-amd64.tar.gz
fi

# ###  Rust  ##################################################################

# set cargo home
export CARGO_HOME="$HOME/.cargo"
addPath "$CARGO_HOME/bin"

# set build wrapper
hash sccache &>/dev/null && export RUSTC_WRAPPER="$(which sccache)"

# install rust
hash rustup &>/dev/null || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# ###  Starship  ##############################################################

# starship: shell prompts
export STARSHIP_CONFIG=~/.starship.toml
hash starship &>/dev/null && eval "$(starship init zsh)"

# ###  Zprof  #################################################################
# you need add `zmodload zsh/zprof` to the top of .zshrc file
# zprof | head -n 20; zmodload -u zsh/zprof
# echo "Runtime was: $(echo "$(date +%s.%N) - $start" | bc)"

