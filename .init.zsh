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
    "ag:silversearcher-ag"
  )
  for app in "${apps[@]}"; do
    read cmd pkg < <(echo $app | tr ":" " ")
    hash $cmd &>/dev/null || sudo nala install -y $pkg
  done
fi

# atuin
if ! hash atuin &>/dev/null; then
  info "Install atuin"
  bash <(curl https://raw.githubusercontent.com/atuinsh/atuin/main/install.sh)
fi

# LazyVim
if [[ ! -e "$HOME/.config/nvim" ]]; then
  info "Install lazyvim"
  mv $HOME/.local/share/nvim $HOME/.local/share/nvim.bak
  f.sh "LazyVim/starter" "$HOME/.config/nvim"
  rm -rf ~/.config/nvim/lua/*
  ln -s ~/.nvim/config ~/.config/nvim/lua/
  ln -s ~/.nvim/plugins ~/.config/nvim/lua/
  ln -s ~/.nvim/user ~/.config/nvim/lua/
fi

# ###  Cargo install  #########################################################

# just
hash just &>/dev/null || {info "Install just"; cargo install just --locked}

# pueue
if ! hash pueue &>/dev/null; then
  info "Install pueue"
  cargo install --locked pueue && pueue completions zsh $ZCOMP/
fi

# fdfind
hash fd &>/dev/null || {info "Install fdfind"; cargo install fd-find --locked}

# ###  Cargo build  ###########################################################

# alacritty
# TODO: 

# ###  Brew  ##################################################################

# yq
hash yq &>/dev/null || {info "Install yq"; brew install yq}

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

# curlie
hash curlie &>/dev/null || {info "Install curlie"; brew install curlie}

# hugo
hash hugo &>/dev/null || {info "Install hugo"; brew install hugo}

# sccache
hash sccache &>/dev/null || {info "Install sccache"; brew install sccache}

# ###  Snap  ##################################################################

# telegram
hash telegram-desktop &>/dev/null || {info "Install telegram"; sudo snap install telegram-desktop}

# ###  Go  ####################################################################

# mdfmt
hash mdfmt &>/dev/null || {info "Install mdfmt"; go install github.com/elliotxx/mdfmt/cmd/mdfmt@latest}

# gopeed
hash gopeed &>/dev/null || {info "Install gopeed"; go install github.com/GopeedLab/gopeed/cmd/gopeed@latest}

# ###  Binary  ################################################################

# docker-compose
f.sh -b "docker/compose" ".*-linux-x86_64" -n "docker-compose"

# nvim
f.sh -b "neovim/neovim" "nvim.appimage" -n "nvim"

# helix
f.sh -b "helix-editor/helix" "helix.*.AppImage" -n "helix"

# localsend
f.sh -b "localsend/localsend" "LocalSend-.*-linux-x86-64.AppImage" -n "localsend"

# sampler
f.sh -b "sqshq/sampler" "sampler-.*-linux-amd64" -n "sampler"

# ###  Archive  ###############################################################

# fzf
f.sh -a "junegunn/fzf" "fzf-.*-linux_amd64.tar.gz"

# frpc & frps
f.sh -a "fatedier/frp" "frp_.*_linux_amd64.tar.gz"

# navi
f.sh -a "denisidoro/navi" "navi-v.*-x86_64-unknown-linux-musl.tar.gz"

# clash & mihomo
f.sh -a "MetaCubeX/mihomo" "mihomo-linux-amd64-v.*.gz"

# tailspin
f.sh -a "bensadeh/tailspin" "tailspin-x86_64-unknown-linux-musl.tar.gz"

# ssh-chat
f.sh -a "shazow/ssh-chat" "ssh-chat-linux_amd64.tgz"

# wtf
f.sh -a "wtfutil/wtf" "wtf_.*_linux_amd64.tar.gz"

# starship
f.sh -a "starship/starship" "starship-x86_64-unknown-linux-musl.tar.gz"
starship completions zsh > $ZCOMP/_starship

# # ###  Deb  ###################################################################

# delta
f.sh -i "dandavison/delta" "git-delta_.*_amd64.deb"

# lsd
f.sh -i "lsd-rs/lsd" "lsd_.*_amd64.deb"

# bat
f.sh -i "sharkdp/bat" "bat_.*_amd64.deb"

# zoxide
f.sh -i "ajeetdsouza/zoxide" "zoxide_.*_amd64.deb"

# hurl
f.sh -i "Orange-OpenSource/hurl" "hurl_.*_amd64.deb"

# redis
f.sh -i "tiny-craft/tiny-rdm" "tiny-rdm_.*_linux_amd64.deb"

# weixin
if ! hash weixin &>/dev/null; then
  aria2c -c "http://archive.ubuntukylin.com/software/pool/partner/weixin_2.1.4_amd64.deb" -d "/tmp"
  sudo dpkg -i /tmp/weixin_2.1.4_amd64.deb
fi

# # ###  DISPLAY  ###############################################################

[[ -n "$DISPLAY" ]] && source $HOME/.display.zsh

