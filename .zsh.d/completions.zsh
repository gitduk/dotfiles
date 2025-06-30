completions=(
  "nb:https://raw.githubusercontent.com/xwmx/nb/master/etc/nb-completion.zsh"
)

for c in "${completions[@]}"; do
  cmd="${c%%:*}"
  url="${c#*:}"
  if ! command -v "$cmd" &>/dev/null || ; then
    continue
  fi
  if [[ -f "$ZSH_COMPLETIONS/_$cmd" ]]; then
    continue
  fi
  wget "$url" -O "$ZSH_COMPLETIONS/_$cmd"
done
