#!/usr/bin/env bash

SCRIPT_NAME=$(basename "$0")
VERSION="1.0.0"

##############
### config ###
##############

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Options:
  -s, --select    Select music from playlist
  -r, --random    Play random music from playlist
  -h, --help      Show this help
  -v, --version   Show version

Examples:
  $SCRIPT_NAME --select
  $SCRIPT_NAME --random
EOF
}

# 默认 FZF 配置
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
  --bind 'ctrl-r:reload(mpc playlist | cat -n | shuf)'
"

############
### main ###
############

play() {
  cat | fzf --prompt="Music: " | awk '{print $1}' | xargs -r -I {} mpc play {}
}

select_music() {
  mpc playlist | cat -n | play
}

select_random() {
  mpc playlist | cat -n | shuf | play
}

main() {
  [[ $# -eq 0 ]] && { usage; exit 1; }

  while [[ $# -gt 0 ]]; do
    case $1 in
      -s|--select)
        select_music
        shift
        ;;
      -r|--random)
        select_random
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -v|--version)
        echo "$VERSION"
        exit 0
        ;;
      --)
        shift
        break
        ;;
      *)
        echo "Invalid option: $1"
        usage
        exit 1
        ;;
    esac
  done
}

main "$@"
