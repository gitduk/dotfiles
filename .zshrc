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
setopt NO_NOMATCH    # 如果通配符找不到匹配项，不报错（而是原样输出）

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
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
    unset no_proxy NO_PROXY
    return 0
  fi

  if timeout 0.5 bash -c "echo >/dev/tcp/${proxy_host}/${proxy_port}" 2>/dev/null; then
    export http_proxy="http://${proxy_host}:${proxy_port}"
    export HTTP_PROXY="$http_proxy"
    export https_proxy="http://${proxy_host}:${proxy_port}"
    export HTTPS_PROXY="$https_proxy"
    export no_proxy="localhost,127.0.0.1"
    export NO_PROXY="$no_proxy"
    [[ "$slient" == "false" ]] && echo "Proxy enabled: ${proxy_host}:${proxy_port}"
  else
    [[ "$slient" == "false" ]] && echo "Proxy not available on ${proxy_host}:${proxy_port}"
  fi
}

[[ -n "$DISPLAY" ]] && proxy -s

# completion
export ZSH_COMPLETIONS="$HOME/.zsh.d/completions"
[[ ! -d "$ZSH_COMPLETIONS" ]] && mkdir -p "$ZSH_COMPLETIONS"
fpath+=$ZSH_COMPLETIONS

############
### MUST ###
############

# install tool
function inster() {
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

# uget - download release from repo
uget() {
  local repo="$1" pattern="$2" output="${3:-/tmp/$(basename "$1").deb}"
  local url="https://api.github.com/repos/$repo/releases/latest"
  local urls=() download_url line

  while IFS= read -r line; do
    urls+=("$line")
  done < <(
    curl -s -H "User-Agent: uget-script" "$url" |
      jq -r '.assets[]?.browser_download_url' |
      grep -E "$pattern"
  )

  if [[ ${#urls[@]} -eq 0 ]]; then
    echo "$repo: No file found for pattern: $pattern" >&2
    return 1
  fi

  if [[ ${#urls[@]} -gt 1 ]]; then
    if command -v fzf >/dev/null 2>&1; then
      download_url=$(printf '%s\n' "${urls[@]}" | fzf --header="Select a file to download" --preview="")
    else
      echo "Multiple matches found:"
      select download_url in "${urls[@]}"; do
        [ -n "$download_url" ] && break
      done
    fi
  else
    download_url="${urls[0]}${urls[1]}"
  fi

  [[ -z "$download_url" ]] && {
    echo "$repo: No selection made."
    return 1
  }

  echo "Downloading \e[32;1m$download_url\e[0m ..."
  wget -q --show-progress "$download_url" -O "$output"
}


if ! command -v nala &>/dev/null; then
  case "$OS" in
    debian | ubuntu)
      sudo apt install -y nala
      ;;
  esac
fi

command -v git &>/dev/null || inster git
command -v git &>/dev/null || inster curl

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
export LPFX="$HOME/.local/bin"
[[ ! -d "$LPFX" ]] && mkdir -p $LPFX

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
    command -v ssh &>/dev/null || inster ssh || ok=1
    command -v gcc &>/dev/null || inster build-essential || ok=1
    command -v cmake &>/dev/null || inster cmake || ok=1
    command -v pkg-config &>/dev/null || inster pkg-config || ok=1
    command -v sccache &>/dev/null || inster sccache || ok=1
    command -v openssl &>/dev/null || inster openssh || ok=1
    command -v ddcutil &>/dev/null || inster ddcutil || ok=1
    command -v nodejs &>/dev/null || inster nodejs || ok=1
    command -v tmux &>/dev/null || inster tmux || ok=1
    command -v unzip &>/dev/null || inster unzip || ok=1
    command -v jq &>/dev/null || inster jq || ok=1
    dpkg -l | grep libssl-dev | grep ii &>/dev/null || inster libssl-dev || ok=1
    [[ $ok -eq 0 ]] && touch ~/.must.ok
  '
zinit light zdharma-continuum/null

# display
zinit ice if'[[ -n $DISPLAY && ! -f ~/.desktop.ok ]]' lucid as"program" id-as"display" \
  atload'
    ok=0
    command -v foot &>/dev/null || inster foot || ok=1
    command -v kitty &>/dev/null || inster kitty || ok=1
    [[ $ok -eq 0 ]] && touch ~/.display.ok
  '
zinit light zdharma-continuum/null

############
### Brew ###
############

# brew
zinit ice wait"0" lucid as"program" run-atpull id-as"brew" \
  atclone'
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    /home/linuxbrew/.linuxbrew/bin/brew shellenv > init.zsh
  ' \
  atpull"%atclone" \
  atload'
    export HOMEBREW_NO_AUTO_UPDATE=true
    export HOMEBREW_AUTO_UPDATE_SECS=$((60 * 60 * 24))
  ' \
  src"init.zsh"
zinit light zdharma-continuum/null
export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"

#################
### Languages ###
#################

# rustup
zinit ice wait"1" lucid as"program" run-atpull id-as"rustup" \
  atclone'
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    $HOME/.cargo/bin/rustup completions zsh > _rustup
    $HOME/.cargo/bin/rustup completions zsh cargo > _cargo
  ' \
  atload'export CARGO_INSTALL_ROOT=$HOME/.local' \
  atload'command -v sccache &>/dev/null && export RUSTC_WRAPPER=$(command -v sccache)' \
  atpull"%atclone"
zinit light zdharma-continuum/null
export PATH=$HOME/.cargo/bin:$PATH

# golang
zinit ice wait"1" lucid as"program" run-atpull id-as"golang" \
  atclone'
    version=$(curl -s https://raw.githubusercontent.com/actions/go-versions/main/versions-manifest.json|jq -r ".[0].version")
    wget -c https://go.dev/dl/go${version}.linux-amd64.tar.gz -P /tmp
    [[ -d /usr/local/go ]] && sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go$version.linux-amd64.tar.gz
  ' \
  atload'
    export GOPROXY="https://goproxy.cn,https://mirrors.aliyun.com/goproxy,https://goproxy.io,direct"
    export GOPRIVATE="*.corp.example.com,rsc.io/private"
    export GOSUMDB="sum.golang.org"
    export GO111MODULE=on
  ' \
  atpull"%atclone"
zinit light zdharma-continuum/null
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"

##############################
### Custom Config & Script ###
##############################

# settings & functions
zinit ice wait"0" lucid as"program" id-as"autoload" \
  atinit"fpath+=~/.zsh.d/functions" \
  atload'
    autoload -Uz ~/.zsh.d/functions/**/*(:t)
    [[ -f ~/.env.zsh ]] && source ~/.env.zsh || touch ~/.env.zsh
    for script (~/.zsh.d/*.zsh(N)) source $script
    [[ -f ~/.alias.zsh ]] && source ~/.alias.zsh || touch ~/.alias.zsh
    [[ -f ~/.alias.custom.zsh ]] && source ~/.alias.custom.zsh || touch ~/.alias.custom.zsh
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
    bindkey -M viins '^e' autosuggest-execute
    bindkey -M vicmd '^e' autosuggest-execute
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

# zsh-completions
zinit ice wait"1" blockf lucid id-as"zsh-completions" \
  atpull"zinit creinstall -q ."
zinit light zsh-users/zsh-completions

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

#############
### Tools ###
#############

# bat
zinit ice if'(( ! $+commands[bat] ))' lucid as"program" from"gh-r" id-as"bat" \
  atclone"uget sharkdp/bat bat_.\*_amd64.deb" \
  atclone"sudo dpkg -i /tmp/bat.deb" \
  atclone"rm -rf ./*" \
  atclone"bat --completion zsh > _bat" \
  atpull"%atclone"
zinit light sharkdp/bat

# eza - eza is a modern replacement for ls
zinit ice if'(( ! $+commands[eza] ))' lucid as"command" from"gh-r" id-as"eza" \
  atclone"sudo mv eza /usr/bin" \
  atpull"%atclone"
zinit light eza-community/eza

# direnv
zinit ice wait"1" lucid as"command" from"gh-r" id-as"direnv" \
  atclone"mv direnv* direnv" \
  atclone"./direnv hook zsh > init.zsh" \
  atpull"%atclone" \
  src"init.zsh"
zinit light direnv/direnv

# delta - A syntax-highlighting pager for git, diff, and grep output
zinit ice if'(( ! $+commands[delta] ))' lucid as"command" from"gh-r" id-as"delta" \
  atclone"mv */delta ." \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light dandavison/delta

# zoxide - quick jump dir
zinit ice wait"1" lucid as"command" from"gh-r" id-as"zoxide" \
  atclone"./zoxide init zsh --cmd j > init.zsh" \
  src"init.zsh" \
  atpull"%atclone"
zinit light ajeetdsouza/zoxide

# atuin - command history
zinit ice wait"0b" lucid as"command" from"gh-r" id-as"atuin" \
  bpick"atuin-*.tar.gz" \
  atclone"mv */atuin atuin" \
  atclone"./atuin init zsh > init.zsh" \
  atclone"./atuin gen-completions --shell zsh > _atuin" \
  atclone"rm -rf */" \
  src"init.zsh" \
  atpull"%atclone"
zinit light atuinsh/atuin

# navi
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

# fzf
zinit ice wait"0a" lucid as"program" from"gh-r" id-as"fzf" \
  atclone"./fzf --zsh > init.zsh" \
  atclone"mv ./fzf $LPFX/fzf" \
  src"init.zsh" \
  atpull"%atclone"
zinit light junegunn/fzf

# fd
zinit ice if'(( ! $+commands[fd] ))' lucid as"program" from"gh-r" id-as"fd" \
  atclone"sudo mv */fd /usr/bin/fd" \
  atclone"mv */autocomplete/_fd ." \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light sharkdp/fd

# dust
zinit ice if'(( ! $+commands[dust] ))' lucid as"command" from"gh-r" id-as"dust" \
  atclone"sudo mv */dust /usr/bin" \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light bootandy/dust

# just
zinit ice if'(( ! $+commands[just] ))' lucid as"command" from"gh-r" id-as"just" \
  atclone'./just --completions zsh > _just' \
  atpull"%atclone"
zinit light casey/just

# nvim
zinit ice if'(( ! $+commands[nvim] ))' lucid as"program" from"gh-r" id-as"nvim" \
  bpick"nvim-linux-x86_64.appimage" \
  atclone"sudo mv nvim-linux-x86_64.appimage /usr/bin/nvim" \
  atpull"%atclone"
zinit light neovim/neovim

# easytier
zinit ice if'(( ! $+commands[easytier-cli] ))' lucid as"command" from"gh-r" id-as"easytier" \
  extract"!" \
  atclone"sudo mv * /usr/bin" \
  atpull"%atclone"
zinit light EasyTier/EasyTier

# lnav
zinit ice if'(( ! $+commands[lnav] ))' lucid as"program" from"gh-r" id-as"lnav" \
  atclone"brew install lnav" \
  atclone"rm -rf ./*" \
  atpull"%atclone"
zinit light tstack/lnav

# fastfetch
zinit ice if'(( ! $+commands[fastfetch] ))' lucid as"program" from"gh-r" id-as"fastfetch" \
  atclone"uget fastfetch-cli/fastfetch amd64.deb" \
  atclone"sudo dpkg -i /tmp/fastfetch.deb" \
  atclone"rm -rf ./*" \
  atpull"%atclone"
zinit light fastfetch-cli/fastfetch

# bun - Bun is an all-in-one toolkit for JavaScript and TypeScript apps
zinit ice wait"1" lucid as"program" from"gh-r" id-as"bun" \
  bpick"bun-linux-x64.zip" \
  atclone"sudo mv */bun /usr/bin" \
  atclone"SHELL=zsh bun completions > _bun" \
  atclone"rm -rf */" \
  atpull"%atclone" \
  atload'
    export BUN_INSTALL="$HOME/.local"
  '
zinit light oven-sh/bun

# uv - python package manager
zinit ice if'(( ! $+commands[uv] ))' lucid as"command" from"gh-r" id-as"uv" \
  atclone"mv */* . && ./uv generate-shell-completion zsh > _uv" \
  atclone"rm -rf */" \
  atclone"sudo mv uv* /usr/bin" \
  atpull"%atclone"
zinit light astral-sh/uv

# fnm - node version manager
zinit ice wait"1" lucid as"program" from"gh-r" id-as"fnm" \
  atclone"
    ./fnm env --use-on-cd --shell zsh > init.zsh
    ./fnm completions --shell zsh > _fnm
  " \
  src"init.zsh" \
  atpull"%atclone"
zinit light Schniz/fnm

# wallust
zinit ice wait"1" lucid as"program" run-atpull id-as"wallust" \
  atclone"cargo install --locked wallust" \
  atclone"command -v wallust &>/dev/null && wallust theme base16-default-dark -s" \
  atpull"%atclone"
zinit light zdharma-continuum/null

# feedr
zinit ice wait"1" lucid as"program" from"gh-r" id-as"feedr" \
  atclone"mv feedr* feedr" \
  atpull"%atclone"
zinit light bahdotsh/feedr

# pueue
zinit ice wait"1" lucid as"program" from"gh-r" id-as"pueue" \
  atclone"chmod +x pueue*" \
  atclone"mv pueue* $LPFX/pueue" \
  atpull"%atclone"
zinit light Nukesor/pueue

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
