# editor
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export VISUAL="$EDITOR"

# Skip the not really helping Ubuntu global compinit
export skip_global_compinit=1

# cache
export XDG_CACHE_HOME=$HOME/.cache

# lang
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

# Term options
# terminfo directory: ${HOME}/.terminfo
# then /etc/terminfo
# then /lib/terminfo
# then /usr/share/terminfo
export TERMINFO="/lib/terminfo"
export TERM="xterm-256color"
export KEYTIMEOUT=20
export CLIPBOARD="$HOME/.clipboard"

# pkg config
export PKG_CONFIG_PATH="/usr/lib/pkgconfig:\
/usr/lib/x86_64-linux-gnu/pkgconfig:\
/usr/share/pkgconfig:\
/usr/local/lib/x86_64-linux-gnu/pkgconfig"

# ld library
export LD_LIBRARY_PATH="/usr/local/lib:\
/usr/lib/x86_64-linux-gnu:\
/usr/local/lib/x86_64-linux-gnu:\
/usr/local/cuda/lib64:\
/usr/local/cuda/targets/x86_64-linux/lib"

# for cmake
# export CXX=/usr/bin/g++-11
# export CC=/usr/bin/gcc-11
# export LD=/usr/bin/g++-11
