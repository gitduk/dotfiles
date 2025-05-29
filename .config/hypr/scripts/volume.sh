#!/bin/bash

# pamixer warning
hash pamixer &>/dev/null || notify-send "volume.sh" "pamixer is not installed."

# options
OPTIONS=""
LONGOPTS="get,inc,dec,toggle,toggle-mic,mic-inc,mic-dec"
ARGS=$(getopt -a --options=$OPTIONS --longoptions=$LONGOPTS --name "${0##*/}" -- "$@")
if [[ $? -ne 0 || $# -eq 0 ]]; then
	cat <<-EOF
		$0: -[$(echo $OPTIONS | sed 's/,/|/g')] --[$(echo $LONGOPTS | sed 's/,/|/g')]
	EOF
fi
eval set -- "$ARGS"

# settings
STEP=2
LIMIT=60

# Get Volume
get_volume() {
	volume=$(pamixer --get-volume)
	if [[ "$volume" -eq "0" ]]; then
		echo "Muted"
	else
		echo "$volume%"
	fi
}

# Increase Volume
inc_volume() {
	if [ "$(pamixer --get-mute)" == "true" ]; then
		toggle_mute
	else
		pamixer -i $STEP --allow-boost --set-limit $LIMIT
	fi
}

# Decrease Volume
dec_volume() {
	if [ "$(pamixer --get-mute)" == "true" ]; then
		toggle_mute
	else
		pamixer -d $STEP
	fi
}

# Toggle Mute
toggle_mute() {
	if [ "$(pamixer --get-mute)" == "false" ]; then
		pamixer -m
	elif [ "$(pamixer --get-mute)" == "true" ]; then
		pamixer -u
	fi
}

# Toggle Mic
toggle_mic() {
	if [ "$(pamixer --default-source --get-mute)" == "false" ]; then
		pamixer --default-source -m
	elif [ "$(pamixer --default-source --get-mute)" == "true" ]; then
		pamixer -u --default-source u
	fi
}

# Get Microphone Volume
get_mic_volume() {
	volume=$(pamixer --default-source --get-volume)
	if [[ "$volume" -eq "0" ]]; then
		echo "Muted"
	else
		echo "$volume%"
	fi
}

# Increase MIC Volume
inc_mic_volume() {
	if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
		toggle_mic
	else
		pamixer --default-source -i $STEP
	fi
}

# Decrease MIC Volume
dec_mic_volume() {
	if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
		toggle-mic
	else
		pamixer --default-source -d $STEP
	fi
}

while true; do
	case "$1" in
	--get) get_volume ;;
	--inc) inc_volume ;;
	--dec) dec_volume ;;
	--toggle) toggle_mute ;;
	--toggle-mic) toggle_mic ;;
	--mic-inc) inc_mic_volume ;;
	--mic-dec) dec_mic_volume ;;
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
