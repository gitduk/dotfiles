#!/usr/bin/env zsh

# ###  Desktop Manager  #######################################################

# hyprland v0.38.1
if ! has hyprland; then

  cd && mkdir Hyprland && cd Hyprland

  # build wayland
  git clone https://gitlab.freedesktop.org/wayland/wayland.git && cd wayland
  mkdir build && cd build \
    && meson setup .. --prefix=/usr --buildtype=release -Ddocumentation=false \
    && sudo ninja -C . install
  cd ../..

  # build wayland-protocols
  sudo nala install -y libcairo2-dev libpango1.0-dev libgbm-dev libliftoff-dev libdisplay-info-dev
  git clone https://gitlab.freedesktop.org/wayland/wayland-protocols.git && cd wayland-protocols
  mkdir build && cd build \
    && meson setup --prefix=/usr --buildtype=release \
    && sudo ninja -C . install
  cd ../..

  # build hyprlang
  git clone https://github.com/hyprwm/hyprlang.git && cd hyprlang
  cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
  cmake --build ./build --config Release --target hyprlang -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF`
  sudo cmake --install ./build
  cd ..

  # build hyprcursor
  sudo nala install -y libzip-dev librsvg2-dev libtomlplusplus-dev libxcb-util-dev libxcb-image0-dev
  git clone https://github.com/hyprwm/hyprcursor.git && cd hyprcursor
  cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
  cmake --build ./build --config Release --target all -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF`
  sudo cmake --install ./build
  cd ..

  # build hyprland
  sudo nala install -y meson wget build-essential ninja-build cmake-extras cmake gettext gettext-base fontconfig libfontconfig-dev libffi-dev libxml2-dev libdrm-dev libxkbcommon-x11-dev libxkbregistry-dev libxkbcommon-dev libpixman-1-dev libudev-dev libseat-dev seatd libxcb-dri3-dev libegl-dev libgles2 libegl1-mesa-dev glslang-tools libinput-bin libinput-dev libxcb-composite0-dev libavutil-dev libavcodec-dev libavformat-dev libxcb-ewmh2 libxcb-ewmh-dev libxcb-present-dev libxcb-icccm4-dev libxcb-render-util0-dev libxcb-res0-dev libxcb-xinput-dev xdg-desktop-portal-wlr libtomlplusplus3
  git clone --recursive https://github.com/hyprwm/Hyprland && cd Hyprland
  sudo make all && sudo make install
  cd ..

  # build hyprpaper
  sudo nala install -y libmagic-dev
  git clone https://github.com/hyprwm/hyprpaper.git && cd hyprpaper
  cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
  cmake --build ./build --config Release --target hyprpaper -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF`
  sudo cmake --install ./build
  cd ..

  # build hyprlock
  sudo nala install -y libpam0g-dev
  git clone https://github.com/hyprwm/hyprlock.git && cd hyprlock
  cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build
  cmake --build ./build --config Release --target hyprlock -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF`
  sudo cmake --install ./build
  cd ..

  # build hypridle
  sudo nala install -y libsdbus-c++-dev
  git clone https://github.com/hyprwm/hypridle.git && cd hypridle
  cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -S . -B ./build
  cmake --build ./build --config Release --target hypridle -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF`
  sudo cmake --install ./build && systemctl --user enable --now hypridle.service
  cd ..

  # build hyprnotify
  wget https://github.com/codelif/hyprnotify/releases/download/v0.6.2/hyprnotify.zip \
    && unzip hyprnotify.zip && mv hyprnotify $HOME/.local/bin/hyprnotify \
    && sudo chmod 744 $HOME/.local/bin/hyprnotify

  # build hyprpicker
  git clone https://github.com/hyprwm/hyprpicker.git && cd hyprpicker
  cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
  cmake --build ./build --config Release --target hyprpicker -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF`
  sudo cmake --install ./build

  # xdg-desktop-portal-hyprland
  sudo nala install -y qt6-base-dev
  git clone --recursive https://github.com/hyprwm/xdg-desktop-portal-hyprland && cd xdg-desktop-portal-hyprland
  cmake -DCMAKE_INSTALL_LIBEXECDIR=/usr/lib -DCMAKE_INSTALL_PREFIX=/usr -B build
  cmake --build ./build && sudo cmake --install build

fi

# ###  Applications  ##########################################################

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

# copyq: clipboard manager
hash copyq &>/dev/null || sudo nala install -y copyq

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

# switchhosts
f.sh -m "binary" "oldj/SwitchHosts" "SwitchHosts_linux_x86_64.*.AppImage" -n "switchhosts"

# redis manager
f.sh -m "deb" "tiny-craft/tiny-rdm" "tiny-rdm_.*_linux_amd64.deb"

# localsend
f.sh -m "binary" "localsend/localsend" "LocalSend-.*-linux-x86-64.AppImage" -n "localsend"

# logseq
f.sh -m "binary" "logseq/logseq" "Logseq-linux-x64-.*.AppImage" -n "logseq"

# db manager
if ! hash dataflare &>/dev/null; then
  aria2c -c "https://assets.dataflare.app/release/linux/x86_64/Dataflare.AppImage" -d "$ZPFX/bin"
  sudo chmod 744 "$ZPFX/bin/Dataflare.AppImage"
  mv "$ZPFX/bin/Dataflare.AppImage" "$ZPFX/bin/dataflare"
fi

# spacedrive
f.sh -m "deb" "spacedriveapp/spacedrive" "Spacedrive-linux-x86_64.deb"

# bruno:  exploring and testing APIs.
f.sh -m "deb" "usebruno/bruno" "bruno_.*_amd64_linux.deb"

# obsidian
f.sh -m "deb" "obsidianmd/obsidian-releases" "obsidian_.*_amd64.deb"

# weixin
# if ! hash weixin &>/dev/null; then
#   aria2c -c "http://archive.ubuntukylin.com/software/pool/partner/weixin_2.1.4_amd64.deb" -d "/tmp"
#   sudo dpkg -i /tmp/weixin_2.1.4_amd64.deb
# fi

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

