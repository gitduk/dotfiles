#!/usr/bin/env zsh

# ###  Desktop Manager  #######################################################

if ! hash hyprland; then
  # xdg-desktop-portal-hyprland
  git clone --depth 1 "https://github.com/Kistler-Group/sdbus-cpp.git"
  cd sdbus-cpp/
  mkdir build && cd build
  cmake .. -DCMAKE_BUILD_TYPE=Release ${OTHER_CONFIG_FLAGS}
  cmake --build . && sudo cmake --build . --target install
  cd .../
  
  git clone --depth 1 "https://github.com/hyprwm/hyprland-protocols.git"
  cd hyprland-protocols/
  meson setup build --prefix=/usr && ninja -C build && sudo ninja -C build install
  cd ..
  
  sudo nala install -y libpipewire-0.3-dev libinih-dev \
    librust-wayland-protocols-dev librust-wayland-client-dev
  git clone --recursive "https://github.com/hyprwm/xdg-desktop-portal-hyprland.git"
  cd xdg-desktop-portal-hyprland/
  cmake -DCMAKE_INSTALL_LIBEXECDIR=/usr/lib -DCMAKE_INSTALL_PREFIX=/usr -B build
  cmake --build build
  sudo cmake --install build
  
  # Hyprland
  sudo nala install -y build-essential cmake cmake-extras fontconfig \
    g++-11 gcc-11 gettext gettext-base glslang-tools grim
  sudo nala install -y libavcodec-dev libavformat-dev libavutil-dev \
    libcunit1-dev libdrm-dev libegl1-mesa-dev libegl-dev libffi-dev \
    libfontconfig-dev libgbm-dev libgles2 libgulkan-dev libinput-bin \
    libinput-dev libpixman-1-dev libsdl-pango-dev libseat-dev libsystemd-dev \
    libtoml11-dev libtomlplusplus3 libtomlplusplus-dev libudev-dev libvkfft-dev \
    libvulkan-dev libvulkan-volk-dev libxcb-composite0-dev libxcb-dri3-dev \
    libxcb-ewmh2 libxcb-ewmh-dev libxcb-icccm4-dev libxcb-present-dev \
    libxcb-render-util0-dev libxcb-res0-dev libxcb-xinput-dev libxkbcommon-dev \
    libxkbcommon-x11-dev libxkbregistry-dev libxml2-dev libwlroots-dev
  sudo nala install -y meson ninja-build qt6-wayland seatd swayidle valgrind \
    vulkan-validationlayers-dev wget xcb xdg-desktop-portal-wlr xwayland
  meson wrap install tomlplusplus
  sudo nala remove libdrm-dev
  cd /tmp
  tar -xvf $HOME/.static/libdrm-2.4.120.tar.xz -C /tmp
  cd libdrm-2.4.120 && meson build/ && ninja -C build && sudo ninja -C build install
  cd .. && git clone https://github.com/marzer/tomlplusplus.git
  [[ -e "/usr/include/toml++" ]] && sudo mv /usr/include/toml++ /usr/include/toml++.bak
  sudo mv /tmp/tomlplusplus/include/toml++ /usr/include/
  git clone --depth 1 https://github.com/hyprwm/hyprlang.git
  cd hyprlang/
  cmake --no-warn-unused-cli -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_INSTALL_PREFIX:PATH=/usr -S . -B ./build
  cmake --build ./build --config Release --target hyprlang -j`nproc 2>/dev/null || getconf NPROCESSORS_CONF`
  cd ..
  git clone --recursive https://github.com/hyprwm/Hyprland
  cd Hyprland && make all && sudo make install
fi

# ###  Applications  ##########################################################

# rofi: application launcher
if ! hash rofi &>/dev/null; then
  git clone --depth=1 "https://github.com/lbonn/rofi.git"
  sudo nala install -y flex
  meson setup build -Dxcb=disabled --prefix=$ZPFX
  ninja -C build && ninja -C build install
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
f.sh -b "oldj/SwitchHosts" "SwitchHosts_linux_x86_64.*.AppImage" -n "switchhosts"

# google-chrome
if ! hash google-chrome &>/dev/null; then
  aria2c -c "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" -d /tmp
  sudo dpkg -i /tmp/google-chrome-stable_current_amd64.deb
fi

# weixin
if ! hash weixin &>/dev/null; then
  aria2c -c "http://archive.ubuntukylin.com/software/pool/partner/weixin_2.1.4_amd64.deb" -d "/tmp"
  sudo dpkg -i /tmp/weixin_2.1.4_amd64.deb
fi

# redis manager
f.sh -d "tiny-craft/tiny-rdm" "tiny-rdm_.*_linux_amd64.deb"

# localsend
f.sh -b "localsend/localsend" "LocalSend-.*-linux-x86-64.AppImage" -n "localsend"

# db manager
if ! hash dataflare &>/dev/null; then
  aria2c -c "https://assets.dataflare.app/release/linux/x86_64/Dataflare.AppImage" -d "$ZPFX/bin"
  sudo chmod 744 "$ZPFX/bin/Dataflare.AppImage"
  mv "$ZPFX/bin/Dataflare.AppImage" "$ZPFX/bin/dataflare"
fi

