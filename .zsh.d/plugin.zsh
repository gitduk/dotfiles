# ###  Local  #################################################################

locals=(
  "fzf"
  "sudo"
  "dotenv"
)

for plugin in "${locals[@]}"; do
  [[ -f "$ZSH_DIR/plugins/$plugin.plugin.zsh" ]] && source "$ZSH_DIR/plugins/$plugin.plugin.zsh"
  [[ -f "$ZSH_DIR/plugins/$plugin.custom.zsh" ]] && source "$ZSH_DIR/plugins/$plugin.custom.zsh"
done

# ###  Raw  ###################################################################

raws=(
  "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/lib/directories.zsh"
  "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/copypath/copypath.plugin.zsh"
)

for url in "${raws[@]}"; do
  filename="${url##*/}"
  [[ -f "$ZPLUG/$filename" ]] && source "$ZPLUG/$filename" || wget -c "$url" -P "$ZPLUG"
done

# ###  Repo  ##################################################################

plugins=(
  "mfaerevaag/wd"
  "Aloxaf/fzf-tab"
  "zsh-users/zsh-autosuggestions"
  "zsh-users/zsh-history-substring-search"
  "zdharma-continuum/fast-syntax-highlighting"
)

for plugin in "${plugins[@]}"; do
  user="${plugin%%/*}"
  plugin="${plugin##*/}"
  if [[ -d "$ZPLUG/$plugin" ]]; then
    [[ -e "$ZPLUG/$plugin/$plugin.plugin.zsh" ]] && source "$ZPLUG/$plugin/$plugin.plugin.zsh"
    [[ -f "$ZPLUG/$plugin.custom.zsh" ]] && source "$ZPLUG/$plugin.custom.zsh"
    [[ -f "$ZSH_DIR/plugins/$plugin.custom.zsh" ]] && source "$ZSH_DIR/plugins/$plugin.custom.zsh"
  else
    git clone --depth=1 "https://github.com/$user/$plugin.git" "$ZPLUG/$plugin"
    [[ $? -eq 0 ]] && source "$ZPLUG/$plugin/$plugin.plugin.zsh" || echo "Failed to clone $user/$plugin"
  fi
done

# ###  Completion  ############################################################

completions=(
  "https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker"
  "https://raw.githubusercontent.com/conda-incubator/conda-zsh-completion/master/_conda"
  "https://raw.githubusercontent.com/alacritty/alacritty/master/extra/completions/_alacritty"
)

for url in "${completions[@]}"; do
  [[ -f "$ZCOMP/${url##*/}" ]] || wget -c "$url" -P "$ZCOMP"
done

