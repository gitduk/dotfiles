# ###  Pkgconfig  #############################################################

export PKG_CONFIG_PATH="/usr/lib/pkgconfig:\
/usr/lib/x86_64-linux-gnu/pkgconfig:\
/usr/share/pkgconfig:\
/usr/local/lib/x86_64-linux-gnu/pkgconfig"

# ###  Lib Path  ##############################################################

export LD_LIBRARY_PATH="/usr/local/lib:\
/usr/lib/x86_64-linux-gnu:\
/usr/local/cuda/lib64:\
/usr/local/cuda/targets/x86_64-linux/lib:\
/usr/local/cuda/targets/x86_64-linux/lib/stubs"

# ###  System Options  ########################################################

# Term options
# terminfo directory: ${HOME}/.terminfo
# then /etc/terminfo
# then /lib/terminfo
# then /usr/share/terminfo
export TERMINFO="/lib/terminfo"
export TERM="xterm-256color"
export KEYTIMEOUT=20
export CLIPBOARD="$HOME/.clipboard"

# for cmake
# export CXX=/usr/bin/g++-11
# export CC=/usr/bin/gcc-11
# export LD=/usr/bin/g++-11

# input method set up
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export INPUT_METHOD=fcitx
export SDL_IM_MODULE=fcitx
export GLFW_IM_MODULE=fcitx
export IMSETTINGS_MODULE=fcitx

# editor
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export VISUAL="$EDITOR"

# browser
export BROWSER=google-chrome

# cursor
export XCURSOR_PATH="$HOME/.local/share/icons"
export XCURSOR_THEME=Vimix

# Skip the not really helping Ubuntu global compinit
export skip_global_compinit=1

# ###  Hyprland  ##############################################################

export MOZ_ENABLE_WAYLAND=1
export MOZ_WAYLAND_USE_VAAPI=1
export MOZ_DBUS_REMOTE=1
export MOZ_WEBRENDER=1
export GTK_USE_PORTAL=1
export GDK_BACKEND=wayland
export XDG_SESSION_TYPE=wayland
export SDL_VIDEODRIVER=wayland
export QT_QPA_PLATFORM=wayland
export CLUTTER_BACKEND=wayland
export XDG_SESSION_DESKTOP=wayland
export XDG_CURRENT_DESKTOP=wayland

# ###  Path  ##################################################################

function addPath {
  local paths="${(@s/:/)1}"
  for p in ${(s/:/)paths}; do
    [[ ":$PATH:" != *":$p:"* ]] && export PATH="$p:$PATH"
  done
}

# sh
addPath "/usr/sbin"
addPath "$HOME/.local/bin"
addPath "$HOME/.sh"

# brew
export HOMEBREW_PREFIX="$HOME/.linuxbrew";
export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar";
export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX/Homebrew";
addPath "$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin";
addPath "$HOMEBREW_PREFIX/opt/llvm/bin";

export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH:+:$MANPATH}";
export INFOPATH="$HOMEBREW_PREFIX/share/info:$INFOPATH";

# npm
addPath "$HOME/.npm/bin"

# snap
addPath "/snap/bin"

# go
export GOROOT="/usr/local/go"
export GOPATH="$HOME/go"
export GOENV="$HOME/go/env"
addPath "$GOROOT/bin"
addPath "$GOPATH/bin"

# cargo
export CARGO_HOME="$HOME/.cargo"
addPath "$CARGO_HOME/bin"

# sqlserver
addPath "/opt/mssql-tools/bin"

# dotnet
addPath "$HOME/.dotnet:$HOME/.dotnet/tools"

# cuda
addPath "/usr/local/cuda/bin"

# pnpm
export PNPM_HOME="/home/wukaige/.local/share/pnpm"
addPath "$PNPM_HOME"

# TiDB
addPath "$HOME/.tiup/bin"

# doom emacs
addPath "$HOME/.config/emacs/bin"

# conda
addPath "$HOME/anaconda3/bin"

# f.sh
addPath "$HOME/.f.sh"

# ###  Token  #################################################################

export ipinfo="c577b3ef143bc3"
export codeium="eyJhbGciOiJSUzI1NiIsImtpZCI6IjY5NjI5NzU5NmJiNWQ4N2NjOTc2Y2E2YmY0Mzc3NGE3YWE5OTMxMjkiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoia2FpZ2Ugd3UiLCJwaWN0dXJlIjoiaHR0cHM6Ly9saDMuZ29vZ2xldXNlcmNvbnRlbnQuY29tL2EvQUNnOG9jSWlpOUpjQXZGekYwRHVESXZBUVF0cXc1LWJQbzdNRkRURWtGb0k2dkphMWlvPXM5Ni1jIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL2V4YTItZmIxNzAiLCJhdWQiOiJleGEyLWZiMTcwIiwiYXV0aF90aW1lIjoxNzA3MDk5Mjk2LCJ1c2VyX2lkIjoibWNIN2lBdHlzeGVIbDR5RXBvajIxQnpoSXdWMiIsInN1YiI6Im1jSDdpQXR5c3hlSGw0eUVwb2oyMUJ6aEl3VjIiLCJpYXQiOjE3MDcwOTk5ODYsImV4cCI6MTcwNzEwMzU4NiwiZW1haWwiOiJ3dWthaWdlZUBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJnb29nbGUuY29tIjpbIjEwNjI0MzM4NjEzNDI1ODg2OTIyMiJdLCJlbWFpbCI6WyJ3dWthaWdlZUBnbWFpbC5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJnb29nbGUuY29tIn19.KaYvblUqLJ0H_rV_mFQPZ3hdHqnWf5SQbjjJEmDHNUp8EwvRZRLCqUZcc48xdpMppADinv-FdkckcuXGLHB1O7NnCZNrQnZq0Q6H8S2saSidpo80HBnN66Ua_zVZSJdEEdPqRRJ_VPlRjVEi7_j6ZWv1MinnEMFepifEhFdPFKA72Nud2awAxnkvY42LYSrtD-zp_o1a-0lOqTZ6viuzTCpVya3UkEMPCqIStoEcJf5W_dUtPEe7dHnlf2BwuliFf_MCTiemDrVEJmSo2H1sydancIytkNzP70zi0pvlM3YF46F4eUHlyGaqRq4MaK457q5DON0o6X0nRQ3nPj3YcQ"
export xfltd="https://4e27671ecbe40902.cdn.jiashule.com/api/v1/client/subscribe?token=e3b4087faa1bc13b7963f74af7d14cd1"

