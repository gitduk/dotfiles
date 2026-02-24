#################
### Lazy Load ###
#################
# Lazy-loaded tools (install on first use via command_not_found_handler)
typeset -gA LAZY_REPO LAZY_ICE

command_not_found_handler() {
  local repo="${LAZY_REPO[$1]}"
  if [[ -n "$repo" ]]; then
    if [[ "$repo" == curl:* ]]; then
      curl -fsSL "${repo#curl:}" | bash
      rehash
    elif [[ "$repo" == bun:* ]]; then
      bun install -g "${repo#bun:}"
      rehash
    elif [[ "$repo" == cargo:* ]]; then
      cargo install "${repo#cargo:}"
      rehash
    elif [[ "$repo" == apt:* ]]; then
      sudo apt install -y "${repo#apt:}"
      rehash
    else
      local id="${repo##*/}"
      local -a ices=("${(z)LAZY_ICE[$1]}")
      ices=(${ices:#cmd*})
      ices=(${ices:#env\"*})
      (( ${ices[(I)as*]} )) || ices+=(as"program")
      (( ${ices[(I)from*]} )) || ices+=(from"gh-r")
      (( ${ices[(I)atpull*]} )) || ices+=(atpull"%atclone")
      zinit ice lucid id-as"$id" "${(Q@)ices}"
      zinit light "$repo"
    fi
    unset "LAZY_REPO[$1]" "LAZY_ICE[$1]"
    command "$@"
    return $?
  fi
  echo "zsh: command not found: $1" >&2
  return 127
}

# Parse sbin/cmd ice to extract command names
_parse_lazy_cmds() {
  local -a args=("${(Q@)${(z)1}}")
  for arg in "${args[@]}"; do
    if [[ "$arg" == cmd* ]]; then
      echo "${arg#cmd}"
    elif [[ "$arg" == sbin* ]]; then
      for entry in ${(s:;:)${arg#sbin}}; do
        entry="${entry#"${entry%%[![:space:]]*}"}"
        entry="${entry%"${entry##*[![:space:]]}"}"
        if [[ "$entry" == *" -> "* ]]; then
          echo "${entry##* -> }"
        else
          echo "${entry##*/}"
        fi
      done
    fi
  done
}

while read -r repo ice_opts; do
  [[ "$repo" =~ ^# || -z "$repo" ]] && continue
  # process env"KEY=VALUE"
  for t in "${(Q@)${(z)ice_opts}}"; do
    [[ "$t" == env* ]] && { local _v="${t#env}"; export "${_v%%=*}=${${_v#*=}/#\~/$HOME}"; }
  done
  local -a cmds=($(_parse_lazy_cmds "$ice_opts"))
  if (( ${#cmds} == 0 )); then
    typeset name="${repo#*:}"
    name="${name##*/}"
    cmds=("$name")
  fi
  for cmd in "${cmds[@]}"; do
    LAZY_REPO[$cmd]="$repo"
    LAZY_ICE[$cmd]="$ice_opts"
  done
done << 'LAZY_TOOLS'
# zinit ice
dandavison/delta sbin"delta"
sharkdp/fd sbin"fd" completions
burntSushi/ripgrep sbin"rg" completions
bootandy/dust sbin"dust" atclone'wget -q https://raw.githubusercontent.com/bootandy/dust/refs/heads/master/completions/_dust'
Canop/dysk sbin"dysk" completions atclone'mv */completion/_dysk .; mv */x86_64-unknown-linux-musl/dysk .; rm -rf */'
casey/just sbin"just" atclone'./just --completions zsh > _just'
neovim/neovim bpick"nvim-linux-x86_64.appimage" sbin"nvim-*.appimage -> nvim"
tstack/lnav sbin"lnav"
karol-broda/snitch sbin"snitch" atclone'./snitch completion zsh > _snitch'
lusingander/serie sbin"serie -> se"
fastfetch-cli/fastfetch bpick"fastfetch-linux-amd64.tar.gz" sbin"usr/bin/fastfetch -> fastfetch"
astral-sh/uv sbin"uv" atclone'./uv generate-shell-completion zsh > _uv'
bahdotsh/feedr sbin"feedr* -> feedr"
pranshuparmar/witr bpick"witr-linux-amd64" sbin"witr* -> witr"
abhimanyu003/sttr sbin"sttr" atclone'./sttr completion zsh > _sttr'
ducaale/xh sbin"xh" completions atclone'mv completions/_xh ./'
pamburus/hl bpick"hl-linux-x86_64-musl.tar.gz" sbin"hl"
antonmedv/fx sbin"fx* -> fx" atclone'./fx* --comp zsh > _fx'
shshemi/tabiew bpick"tw-x86_64-unknown-linux-gnu" sbin"tw* -> tw"
shadow1ng/fscan sbin"fscan"
achristmascarl/rainfrog sbin"rainfrog -> rain"
SagerNet/sing-box bpick"sing-box-*-linux-amd64.tar.gz" sbin"sing-box" atclone'sudo setcap cap_net_admin=+ep $PWD/sing-box'
cli/cli extract"!" sbin"bin/gh -> gh" atclone'./bin/gh completion -s zsh > _gh'
EasyTier/EasyTier sbin"easytier-cli; easytier-core"
Nukesor/pueue bpick"pueue-x86_64-unknown-linux-musl" bpick"pueued-x86_64-unknown-linux-musl" sbin"pueue*-musl -> pueue; pueued*-musl -> pueued" atclone'pueue completions zsh > _pueue'
sxyazi/yazi bpick"yazi-x86_64-unknown-linux-musl.zip" sbin"yazi; ya" completions atclone'mv comp*/_ya .; mv comp*/_yazi .'
mountain-loop/yaak bpick"yaak_*_amd64.AppImage" sbin"yaak* -> yaak"
explosion-mental/wallust as"null" from"codeberg.org" atclone"cargo +nightly install --path ."
alacritty/alacritty as"null" atclone'export PATH="$HOME/.cargo/bin:$PATH"; cargo build --release --no-default-features --features=wayland; sudo ln -sf $PWD/target/release/alacritty /usr/bin/alacritty; sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg; sudo desktop-file-install extra/linux/Alacritty.desktop; sudo update-desktop-database'
oven-sh/bun bpick"bun-linux-x64.zip" sbin"bun" atclone'wget https://raw.githubusercontent.com/oven-sh/bun/refs/heads/main/completions/bun.zsh -O _bun' env"BUN_INSTALL=~/.local"
eza-community/eza sbin"eza"
sharkdp/bat sbin"bat-*/bat" atclone"./bat-*/bat --completion zsh > _bat"
mozilla/sccache bpick"sccache-v*-x86_64-unknown-linux-musl.tar.gz" sbin"sccache"

# apt installer
apt:foot
apt:kitty

# curl installer
curl:https://raw.githubusercontent.com/lucasgelfond/zerobrew/main/install.sh cmd"zb"
curl:https://claude.ai/install.sh cmd"claude"

# bun installer
bun:@openai/codex
bun:@anthropic-ai/claude-code cmd"claude"

# cargo installer
cargo:bacon env"BACON_CONFIG=~/.config/bacon/bacon.toml"

LAZY_TOOLS
