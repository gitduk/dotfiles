# ###  Local  #################################################################

locals=(
  "fzf.plugin.zsh"
  "sudo.plugin.zsh"
  "dotenv.plugin.zsh"
)

for file in "${locals[@]}"; do
  [[ -f "$ZPLUG/$file" ]] && source "$ZPLUG/$file"
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
  "skywind3000/z.lua"
  "mfaerevaag/wd"
  "Aloxaf/fzf-tab"
  "zsh-users/zsh-autosuggestions"
  "zsh-users/zsh-history-substring-search"
  "zdharma-continuum/fast-syntax-highlighting"
)

for plugin in "${plugins[@]}"; do
  plugin="${plugin##*/}"
  if [[ -d "$ZPLUG/$plugin" ]]; then
    source "$ZPLUG/$plugin/$plugin.plugin.zsh"
  else
    git clone --depth=1 "https://github.com/$plugin.git" "$ZPLUG/$plugin"
    [[ $? -eq 0 ]] && source "$ZPLUG/$plugin/$plugin.plugin.zsh" || echo "Failed to clone $plugin"
  fi
  [[ -e "$ZPLUG/$plugin.custom.zsh" ]] && source "$ZPLUG/$plugin.custom.zsh"
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

