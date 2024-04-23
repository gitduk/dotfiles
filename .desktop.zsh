#!/usr/bin/env zsh

# hyprland v0.38.1
hash hyprland &>/dev/null && exit 0

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
  && meson setup .. --prefix=/usr --buildtype=release \
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

# wl-copy
git clone https://github.com/bugaevc/wl-clipboard.git && cd wl-clipboard
mkdir build && cd build \
  && meson setup .. --prefix=/usr --buildtype=release \
  && sudo ninja -C . install

