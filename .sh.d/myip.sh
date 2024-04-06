#!/usr/bin/env zsh

# Get my public IP address

hosts=(
	"ipinfo.io/ip"
	"ifconfig.me/ip"
	"icanhazip.com"
	"ident.me"
	"ipecho.net/plain"
	"checkip.amazonaws.com"
	"api.ipify.org"
	"icanhazip.com"
	"checkipv4.dedyn.io"
)

local external_ip

while true; do
	external_ip=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null)
	if [ ! $? -eq 0 ] || [ -z "$external_ip" ] || [[ ! $external_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
		count=${#hosts[@]}
		while [[ -z "$external_ip" ]]; do
			selectedhost=${hosts[$RANDOM % ${#hosts[@]}]}
			external_ip=$(curl -s "https://$selectedhost" | grep '[^[:blank:]]')
			[[ -n "$external_ip" ]] && [[ $external_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && break
			external_ip=""
		done
	fi
	echo -n $external_ip | tee /tmp/myip
	sleep 60
done

