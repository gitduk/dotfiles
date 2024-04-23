#!/usr/bin/env zsh

# ###  Scripts  ###############################################################

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

# tofi: application launcher
if ! hash tofi &>/dev/null; then
  git clone --depth=1 "https://github.com/philj56/tofi.git" && cd tofi
  meson setup build && sudo ninja -C build install
fi

# screenshot: flameshot
if ! hash flameshot &>/dev/null; then
  sudo nala install -y g++ cmake build-essential qtbase5-dev qttools5-dev-tools \
    libqt5svg5-dev qttools5-dev libkf5guiaddons-dev
  git clone https://github.com/flameshot-org/flameshot.git
  cd flameshot/
  cmake -S . -B build \
    -DUSE_WAYLAND_CLIPBOARD=true \
    -DUSE_WAYLAND_GRIM=ON \
    && cmake --build build \
    && sudo cmake --install build
fi

# plum: rime config manage
if ! hash rime_dict_manager &>/dev/null; then
  sudo nala install -y fcitx5 \
    fcitx5-chinese-addons \
    fcitx5-frontend-gtk4 fcitx5-frontend-gtk3 fcitx5-frontend-gtk2 \
    fcitx5-frontend-qt5 fcitx5-rime
  im-config -n fcitx5
  plum_dir="$HOME/.local/share/fcitx5/plum"
  git clone --depth 1 https://github.com/rime/plum.git $plum_dir
  rime_dir="$HOME/.local/share/fcitx5/rime" rime_frontend="fcitx5-rime" bash $plum_dir/rime-install iDvel/rime-ice:others/recipes/full
  rime_dir="$HOME/.local/share/fcitx5/rime" rime_frontend="fcitx5-rime" bash $plum_dir/rime-install iDvel/rime-ice:others/recipes/config:schema=flypy
  # auto install rime and rime-ice
  # git clone --depth=1 https://github.com/Mark24Code/rime-auto-deploy.git --branch latest
  # cd rime-auto-deploy && ./installer.rb
fi

# db manager
if ! hash dataflare &>/dev/null; then
  aria2c -c "https://assets.dataflare.app/release/linux/x86_64/Dataflare.AppImage" -d "$ZPFX/bin"
  sudo chmod 744 "$ZPFX/bin/Dataflare.AppImage"
  mv "$ZPFX/bin/Dataflare.AppImage" "$ZPFX/bin/dataflare"
fi

# weixin
# if ! hash weixin &>/dev/null; then
#   aria2c -c "http://archive.ubuntukylin.com/software/pool/partner/weixin_2.1.4_amd64.deb" -d "/tmp"
#   sudo dpkg -i /tmp/weixin_2.1.4_amd64.deb
# fi

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
has starship && starship completions zsh > $ZCOMP/_starship

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

# heynote
f.sh -m "binary" "heyman/heynote" "Heynote_.*_x86_64.AppImage"

# reor
f.sh -m "binary" "reorproject/reor" "Reor_.*.AppImage"

# switchhosts
f.sh -m "binary" "oldj/SwitchHosts" "SwitchHosts_linux_x86_64.*.AppImage" -n "switchhosts"

# localsend
f.sh -m "binary" "localsend/localsend" "LocalSend-.*-linux-x86-64.AppImage" -n "localsend"

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

# dbeaver
f.sh -m "deb" "dbeaver/dbeaver" "dbeaver-ce_.*_amd64.deb"

# redis manager
f.sh -m "deb" "tiny-craft/tiny-rdm" "tiny-rdm_.*_linux_amd64.deb"

# spacedrive
f.sh -m "deb" "spacedriveapp/spacedrive" "Spacedrive-linux-x86_64.deb"

# bruno:  exploring and testing APIs.
f.sh -m "deb" "usebruno/bruno" "bruno_.*_amd64_linux.deb"

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

