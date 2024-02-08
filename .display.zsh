# ###  Git Repo  ##############################################################

# plum: rime config manage
PLUM_ROOT="$HOME/.local/share/fcitx5/plum"
if ! hash rime_dict_manager &> /dev/null || [[ ! -e "$PLUM_ROOT" ]]; then
  git clone --depth=1 "https://github.com/rime/plum.git" $PLUM_ROOT
  rime_frontend=fcitx5-rime bash $PLUM_ROOT/rime-install iDvel/rime-ice:others/recipes/full
  rime_frontend=fcitx5-rime bash $PLUM_ROOT/rime-install iDvel/rime-ice:others/recipes/all_dicts
fi

# ###  AppImage  ##############################################################

# switchhosts
hash switchhosts &> /dev/null \
  || f.sh "oldj/SwitchHosts" "SwitchHosts_linux_x86_64.*.AppImage" "$ZPFX/bin/switchhosts"

# ###  Deb  ###################################################################

# google-chrome
if ! hash google-chrome &> /dev/null; then
  aria2c -c "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" -d /tmp
  sudo dpkg -i /tmp/google-chrome-stable_current_amd64.deb
fi

