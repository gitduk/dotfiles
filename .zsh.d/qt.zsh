##########
### Qt ###
##########

QT_VERSION="6.9.1"
if [[ -d "$HOME/.local/share/Qt/$QT_VERSION" ]]; then
  export QT_ROOT="$HOME/.local/share/Qt/$QT_VERSION"
  export PATH="$QT_ROOT/gcc_64/bin:$PATH"
  export Qt6_DIR="$QT_ROOT/gcc_64/lib/cmake/Qt6"
  export LD_LIBRARY_PATH="$QT_ROOT/gcc_64/lib:$LD_LIBRARY_PATH"
fi

