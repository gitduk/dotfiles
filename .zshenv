# editor
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export VISUAL="$EDITOR"

# browser
export BROWSER=google-chrome

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
# then /etc/terminfo
# terminfo directory: ${HOME}/.terminfo
# then /lib/terminfo
# then /usr/share/terminfo
export TERMINFO="/lib/terminfo"
# Only set TERM if not already set to a meaningful value (preserve TERM=dumb from tools)
[[ -z "$TERM" || "$TERM" == "unknown" || "$TERM" == "linux" ]] && export TERM="xterm-256color"
export KEYTIMEOUT=20
export CLIPBOARD="$HOME/.clipboard"

# ld library
export LD_LIBRARY_PATH="/usr/lib"
export LD_LIBRARY_PATH="/usr/lib64:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/usr/local/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/usr/local/lib64:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="/opt/gcc-15/lib64:$LD_LIBRARY_PATH"

# pkg config
export PKG_CONFIG_PATH="/usr/lib/pkgconfig"
export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_PATH="/usr/local/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_PATH="/usr/share/pkgconfig:$PKG_CONFIG_PATH"
export PKG_CONFIG_PATH="/usr/local/share/pkgconfig:$PKG_CONFIG_PATH"

# path
[[ ! -d "$HOME/.local/bin" ]] && mkdir -p $HOME/.local/bin
export PATH="$HOME/.local/bin:$PATH"

