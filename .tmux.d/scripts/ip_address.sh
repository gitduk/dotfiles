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
local http_proxy=""
local https_proxy=""

while true; do
		selectedhost=${hosts[$RANDOM % ${#hosts[@]}]}
		external_ip=$(curl -s "https://$selectedhost" | grep '[^[:blank:]]')

		if [[ $external_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	    echo -n $external_ip | tee /tmp/ip_address
	    sleep 60
    fi
done

