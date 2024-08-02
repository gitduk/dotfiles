#!/usr/bin/env zsh

cd /tmp && [[ -e "./sing-box/" ]] && rm -rf ./sing-box/
git clone --depth 1 -b 'outbound-providers' https://github.com/PuerNya/sing-box.git
cd sing-box/

# linux
go install -v -trimpath -ldflags "-s -w -buildid=" -tags with_quic,with_wireguard,with_acme,with_gvisor,with_clash_api ./cmd/sing-box
sudo setcap cap_net_admin=ep $HOME/go/bin/sing-box

# android
# GOOS=android GOARCH=arm64 go build -v -trimpath -ldflags "-s -w -buildid=" -tags with_quic,with_wireguard,with_acme,with_gvisor,with_clash_api ./cmd/sing-box

