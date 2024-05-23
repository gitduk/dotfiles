#!/usr/bin/env zsh

# ###  Scripts  ###############################################################

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

# Astrovim
if [[ ! -e "$HOME/.config/nvim" ]]; then
  info "Install astrovim"
  mv ~/.config/nvim ~/.config/nvim.bak
  mv ~/.local/share/nvim ~/.local/share/nvim.bak
  f.sh "AstroNvim/AstroNvim" "$HOME/.config/nvim"
  ln -s ~/.nvim ~/.config/nvim/lua/user
fi

# alacritty
if ! hash alacritty &>/dev/null; then
  sudo nala install -y libegl-dev libegl-amber0
  git clone https://github.com/alacritty/alacritty.git && cd alacritty
  cargo build --release --no-default-features --features=wayland
  cp target/release/alacritty $ZPFX/bin/alacritty
fi

# ###  Brew  ##################################################################

# tldr
hash tldr &>/dev/null || {info "Install tldr"; brew install tlrc}

# ###  Archive  ###############################################################

# fzf
f.sh -m "archive" "junegunn/fzf" "fzf-.*-linux_amd64.tar.gz"

# frpc & frps
f.sh -m "archive" "fatedier/frp" "frp_.*_linux_amd64.tar.gz"

# navi
f.sh -m "archive" "denisidoro/navi" "navi-v.*-x86_64-unknown-linux-musl.tar.gz"

# clash & mihomo
f.sh -m "archive" "MetaCubeX/mihomo" "mihomo-linux-amd64-v.*.gz" -n "clash"

# tailspin
f.sh -m "archive" "bensadeh/tailspin" "tailspin-x86_64-unknown-linux-musl.tar.gz"

# ssh-chat
f.sh -m "archive" "shazow/ssh-chat" "ssh-chat-linux_amd64.tgz"

# wtf
f.sh -m "archive" "wtfutil/wtf" "wtf_.*_linux_amd64.tar.gz" -n "wtf"

# starship
f.sh -m "archive" "starship/starship" "starship-x86_64-unknown-linux-musl.tar.gz"
hash &>/dev/null starship && starship completions zsh > $ZCOMP/_starship

# just
f.sh -m "archive" "casey/just" "just-.*-x86_64-unknown-linux-musl.tar.gz"

# yazi
f.sh -m "archive" "sxyazi/yazi" "yazi-x86_64-unknown-linux-musl.zip"

# gitu
f.sh -m "archive" "altsem/gitu" "gitu-.*-x86_64-unknown-linux-gnu.tar.gz"

# godu
f.sh -m "archive" "viktomas/godu" "godu_.*_Linux_x86_64.tar.gz"

# sccache
f.sh -m "archive" "mozilla/sccache" "sccache-v.*-x86_64-unknown-linux-musl.tar.gz"

# mdfmt
f.sh -m "archive" "elliotxx/mdfmt" "mdfmt_Linux_x86_64.tar.gz"

# uv
f.sh -m "archive" "astral-sh/uv" "uv-x86_64-unknown-linux-musl.tar.gz"

# broot
f.sh -m "archive" "Canop/broot" "broot-x86_64-unknown-linux-musl-v.*.zip"

# sd
f.sh -m "archive" "chmln/sd" "sd-.*-x86_64-unknown-linux-musl.tar.gz"

# procs
f.sh -m "archive" "dalance/procs" "procs-.*-x86_64-linux.zip"

# dog
f.sh -m "archive" "ogham/dog" "dog-.*-x86_64-unknown-linux-gnu.zip"

# lazygit
f.sh -m "archive" "jesseduffield/lazygit" "lazygit_.*_Linux_x86_64.tar.gz"

# go-musicfox
f.sh -m "archive" "go-musicfox/go-musicfox" "go-musicfox_.*_linux_amd64.zip" -n "musicfox"

# tailspin
f.sh -m "archive" "bensadeh/tailspin" "tailspin-x86_64-unknown-linux-musl.tar.gz"

# ###  Binary  ################################################################

# docker-compose
f.sh -m "binary" "docker/compose" ".*-linux-x86_64" -n "docker-compose"

# nvim
f.sh -m "binary" "neovim/neovim" "nvim.appimage" -n "nvim"

# helix
f.sh -m "binary" "helix-editor/helix" "helix.*.AppImage"

# pueue
f.sh -m "binary" "Nukesor/pueue" "pueue-linux-x86_64" -n "pueue"
f.sh -m "binary" "Nukesor/pueue" "pueued-linux-x86_64" -n "pueued"

# yq
f.sh -m "binary" "mikefarah/yq" "yq_linux_amd64$"

# jq
f.sh -m "binary" "jqlang/jq" "jq-linux-amd64$"

# fx
f.sh -m "binary" "antonmedv/fx" "fx_linux_amd64"

# direnv
f.sh -m "binary" "direnv/direnv" "direnv.linux-amd64"

# cliphist
f.sh -m "binary" "sentriz/cliphist" "v.*-linux-amd64"

# reor
f.sh -m "binary" "reorproject/reor" "Reor_.*.AppImage"

# ctop
f.sh -m "binary" "bcicen/ctop" "ctop-0.7.7-linux-amd64"

# nvtop
f.sh -m "binary" "Syllo/nvtop" "nvtop-x86_64.AppImage"

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

# vfox: package version manager
f.sh -m "deb" "version-fox/vfox" "vfox_.*_linux_x86_64.deb"

# duf
f.sh -m "deb" "muesli/duf" "duf_.*_linux_amd64.deb"

# dust
f.sh -m "deb" "bootandy/dust" "du-dust_.*_amd64.deb"

# hugo
f.sh -m "deb" "gohugoio/hugo" "hugo_extended_.*_linux-amd64.deb"

# rg
f.sh -m "deb" "BurntSushi/ripgrep" "ripgrep_.*_amd64.deb"

# bottom
f.sh -m "deb" "ClementTsang/bottom" "bottom_.*_amd64.deb"

# httpie
f.sh -m "deb" "ducaale/xh" "xh_.*_amd64.deb"

# ###  Fonts  #################################################################

fonts=(
  "Meslo"
)

for font in "${fonts[@]}"; do
  if [[ $(fc-list | grep -w "$font" | wc -l) -eq 0 ]]; then
    curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font.tar.xz -o /tmp/$font.tar.xz
    [[ -d "$HOME/.local/share/fonts/$font" ]] || mkdir -p $HOME/.local/share/fonts/$font
    tar -xvf /tmp/$font.tar.xz -C $HOME/.local/share/fonts/$font && fc-cache -fv
  fi
done

