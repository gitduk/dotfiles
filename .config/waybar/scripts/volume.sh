#!/usr/bin/env bash

SCRIPT_NAME=$(basename "$0")
VERSION="1.0.0"

# pamixer 检查
if ! command -v pamixer &>/dev/null; then
  notify-send "$SCRIPT_NAME" "pamixer is not installed."
  exit 1
fi

##############
### config ###
##############

declare -A CONFIG=(
  [step]=2
  [limit]=60
)

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Options:
  --get           Get current volume
  --inc           Increase volume
  --dec           Decrease volume
  --toggle        Toggle mute
  --toggle-mic    Toggle microphone mute
  --mic-inc       Increase microphone volume
  --mic-dec       Decrease microphone volume
  -h, --help      Show this help
  -v, --version   Show version

Examples:
  $SCRIPT_NAME --get
  $SCRIPT_NAME --inc
  $SCRIPT_NAME --toggle-mic
EOF
}

############
### main ###
############

get_volume() {
  local volume
  volume=$(pamixer --get-volume)
  if [[ "$volume" -eq 0 ]]; then
    echo "Muted"
  else
    echo "${volume}%"
  fi
}

inc_volume() {
  if [[ "$(pamixer --get-mute)" == "true" ]]; then
    toggle_mute
  else
    pamixer -i "${CONFIG[step]}" --allow-boost --set-limit "${CONFIG[limit]}"
  fi
}

dec_volume() {
  if [[ "$(pamixer --get-mute)" == "true" ]]; then
    toggle_mute
  else
    pamixer -d "${CONFIG[step]}"
  fi
}

toggle_mute() {
  if [[ "$(pamixer --get-mute)" == "false" ]]; then
    pamixer -m
  else
    pamixer -u
  fi
}

toggle_mic() {
  if [[ "$(pamixer --default-source --get-mute)" == "false" ]]; then
    pamixer --default-source -m
  else
    pamixer --default-source -u
  fi
}

get_mic_volume() {
  local volume
  volume=$(pamixer --default-source --get-volume)
  if [[ "$volume" -eq 0 ]]; then
    echo "Muted"
  else
    echo "${volume}%"
  fi
}

inc_mic_volume() {
  if [[ "$(pamixer --default-source --get-mute)" == "true" ]]; then
    toggle_mic
  else
    pamixer --default-source -i "${CONFIG[step]}"
  fi
}

dec_mic_volume() {
  if [[ "$(pamixer --default-source --get-mute)" == "true" ]]; then
    toggle_mic
  else
    pamixer --default-source -d "${CONFIG[step]}"
  fi
}

main() {
  [[ $# -eq 0 ]] && { usage; exit 1; }

  while [[ $# -gt 0 ]]; do
    case $1 in
      --get)        get_volume; shift ;;
      --inc)        inc_volume; shift ;;
      --dec)        dec_volume; shift ;;
      --toggle)     toggle_mute; shift ;;
      --toggle-mic) toggle_mic; shift ;;
      --mic-inc)    inc_mic_volume; shift ;;
      --mic-dec)    dec_mic_volume; shift ;;
      -h|--help)    usage; exit 0 ;;
      -v|--version) echo "$VERSION"; exit 0 ;;
      *)
        echo "Invalid option: $1"
        usage
        exit 1
        ;;
    esac
  done
}

main "$@"
