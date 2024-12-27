#!/usr/bin/env zsh

OPTIONS="sr"
LONGOPTS="select,random"
ARGS=`getopt -a --options=$OPTIONS --longoptions=$LONGOPTS --name "${0##*/}" -- "$@"`
if [[ $? -ne 0 || $# -eq 0 ]]; then
  cat <<- EOF
$0: -[`echo $OPTIONS|sed 's/,/|/g'`] --[`echo $LONGOPTS|sed 's/,/|/g'`]
EOF
fi
eval set -- "$ARGS"

export FZF_DEFAULT_OPTS="
  --height 100%
  --bind 'ctrl-k:up'
  --bind 'ctrl-j:down'
  --bind 'ctrl-e:last'
  --bind 'ctrl-a:first'
  --bind 'ctrl-w:backward-kill-word'
  --bind 'ctrl-f:page-down'
  --bind 'ctrl-b:page-up'
  --bind 'ctrl-u:half-page-up'
  --bind 'ctrl-d:half-page-down'
  --bind 'ctrl-r:reload(mpc playlist|cat -n|shuf)'
"

play() {
  cat | fzf --prompt="Music: " | awk '{print $1}' | xargs -I {} mpc play {}
}

select_music() {
  mpc playlist | cat -n | play
}

select_random() {
  mpc playlist | cat -n | shuf | play
}

while true; do
  case "$1" in
    -s|--select)
      select_music
      ;;
    -r|--random)
      select_random
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Invalid option: $1"
      exit 1
      ;;
  esac
  shift
done

