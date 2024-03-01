#!/usr/bin/env zsh

# ###  Scripts  ###############################################################

# pretty
source $HOME/.sh/pretty.sh

if ! hash nala &>/dev/null; then
  sudo apt update && sudo apt install -y nala
  apps=(
    "curl:curl"
    "lua:lua5.3"
    "aria2c:aria2"
    "cargo:cargo"
    "cmake:cmake"
    "meson:meson"
    "scdoc:scdoc"
    "tmux:tmux"
    "jq:jq"
    "rg:ripgrep"
    "ag:silversearcher-ag"
  )
  for app in "${apps[@]}"; do
    read cmd pkg < <(echo $app | tr ":" " ")
    hash $cmd &>/dev/null || sudo nala install -y $pkg
  done
fi

# Astrovim
if [[ ! -e "$HOME/.config/nvim" ]]; then
  info "Install astrovim"
  mv ~/.config/nvim ~/.config/nvim.bak
  mv ~/.local/share/nvim ~/.local/share/nvim.bak
  f.sh "AstroNvim/AstroNvim" "$HOME/.config/nvim"
  ln -s ~/.nvim ~/.config/nvim/lua/user
fi

# uv: pip alternative
if ! hash uv &>/dev/null; then
  info "Install uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# ###  Brew  ##################################################################

# dust
if ! hash dust &>/dev/null;then
  info "Install dust"
  brew tap tgotwig/linux-dust && brew install dust
fi

# godu
if ! hash godu &>/dev/null; then
  info "Install godu"
  brew tap viktomas/taps && brew install godu
fi

# gping
hash gping &>/dev/null || {info "Install gping"; brew install gping}

# hugo
hash hugo &>/dev/null || {info "Install hugo"; brew install hugo}

# sccache
hash sccache &>/dev/null || {info "Install sccache"; brew install sccache}

# ###  Snap  ##################################################################
# ###  Go  ####################################################################

# mdfmt
hash mdfmt &>/dev/null || {info "Install mdfmt"; go install github.com/elliotxx/mdfmt/cmd/mdfmt@latest}

# ###  Archive  ###############################################################

# fzf
f.sh -m "archive" "junegunn/fzf" "fzf-.*-linux_amd64.tar.gz"

# frpc & frps
f.sh -m "archive" "fatedier/frp" "frp_.*_linux_amd64.tar.gz"

# navi
f.sh -m "archive" "denisidoro/navi" "navi-v.*-x86_64-unknown-linux-musl.tar.gz"

# clash & mihomo
f.sh -m "archive" "MetaCubeX/mihomo" "mihomo-linux-amd64-v.*.gz" -r "clash"

# tailspin
f.sh -m "archive" "bensadeh/tailspin" "tailspin-x86_64-unknown-linux-musl.tar.gz"

# ssh-chat
f.sh -m "archive" "shazow/ssh-chat" "ssh-chat-linux_amd64.tgz"

# wtf
f.sh -m "archive" "wtfutil/wtf" "wtf_.*_linux_amd64.tar.gz"

# starship
f.sh -m "archive" "starship/starship" "starship-x86_64-unknown-linux-musl.tar.gz"
starship completions zsh > $ZCOMP/_starship

# just
f.sh -m "archive" "casey/just" "just-.*-x86_64-unknown-linux-musl.tar.gz"

# ###  Binary  ################################################################

# docker-compose
f.sh -m "binary" "docker/compose" ".*-linux-x86_64" -r "docker-compose"

# nvim
f.sh -m "binary" "neovim/neovim" "nvim.appimage" -r "nvim"

# helix
f.sh -m "binary" "helix-editor/helix" "helix.*.AppImage"

# sampler
f.sh -m "binary" "sqshq/sampler" "sampler-.*-linux-amd64"

# pueue
f.sh -m "binary" "Nukesor/pueue" "pueue-linux-x86_64" -r "pueue"
f.sh -m "binary" "Nukesor/pueue" "pueued-linux-x86_64" -r "pueued"

# yq
f.sh -m "binary" "mikefarah/yq" "yq_linux_amd64"

# ###  Deb  ###################################################################

# delta
f.sh -m "deb" "dandavison/delta" "git-delta_.*_amd64.deb"

# lsd
f.sh -m "deb" "lsd-rs/lsd" "lsd_.*_amd64.deb"

# bat
f.sh -m "deb" "sharkdp/bat" "bat_.*_amd64.deb"

# zoxide
f.sh -m "deb" "ajeetdsouza/zoxide" "zoxide_.*_amd64.deb"

# hurl
f.sh -m "deb" "Orange-OpenSource/hurl" "hurl_.*_amd64.deb"

# curlie
f.sh -m "deb" "rs/curlie" "curlie_.*_linux_amd64.deb"

# fd
f.sh -m "deb" "sharkdp/fd" "fd-musl_.*_amd64.deb"

# atuin
f.sh -m "deb" "atuinsh/atuin" "atuin_.*_amd64.deb"

# ###  Cargo build  ###########################################################

# alacritty
# TODO: 

# ###  Meson build  ###########################################################

# wl-copy
# f.sh -m "bugaevc/wl-clipboard" "meson setup build && cd build/ && ninja && sudo meson install \
#   && go install go.senan.xyz/cliphist@latest"

