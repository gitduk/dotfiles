# ###  A  #####################################################################

# apt-fast
alias afi="apt-fast install -y"
alias afs="apt-fast search"
alias afr="apt-fast remove"
alias afu="apt-fast update"
alias afug="apt-fast upgrade"
alias affug="apt-fast full-upgrade"

# apt
alias als="sudo apt list"
alias ais="sudo apt install -y"
alias ari="sudo apt reinstall -y"
alias aifb="sudo apt install --fix-broken"
alias aud="sudo apt update"
alias aug="sudo apt upgrade"
alias aflu="sudo apt full-upgrade"
alias arm="sudo apt remove"
alias aar="sudo apt autoremove"
alias aac="sudo apt autoclean"
alias apl="sudo apt policy"
alias apg="sudo apt purge"
alias aso="sudo apt show"
alias asc="sudo apt search"

# download
alias arc="aria2c -c"
alias arcs="aria2c -c -s"

# alsamixer
alias am="alsamixer"

# ###  B  #####################################################################

# brew
alias bri="brew install"
alias brui="brew uninstall"
alias brl="brew list"
alias brs="brew search"
alias brif="brew info"
alias bru="brew update"
alias brug="brew upgrade"
alias brc="brew cleanup"

# bluetooth
alias btc="bluetoothctl"

# base encode
alias b32="base32"
alias b64="base64"

# ###  C  #####################################################################

# dotfiles
ialias c="git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git"
alias cs="c status"
alias cad="cadd"
alias clg="c log"
alias cme="c commit --edit"
alias cma="c commit --amend"
alias cmn="c commit --amend --no-edit"
alias cpl="c pull --rebase"
alias cps="c push"
alias cst="c stash"
alias csb="c submodule"
alias cls="c ls-tree -r master --name-only"

# conda
alias co="conda"
alias coa="conda activate"
alias cod="conda deactivate"
alias coi="conda install"
alias col="conda list"
alias coc="conda create -n"
alias coe="conda env"

# cargo
alias ca="cargo"
alias cai="cargo init"
alias caad="cargo add"
alias can="cargo new"
alias canl="cargo new --lib"
alias cab="cargo build"
alias car="cargo run"
alias caw="cargo watch -x run"
alias carr="cargo run --release"
alias carm="cargo remove"
alias cats="cargo test"
alias cac="cargo clean"
alias cack="cargo check"
alias cas="cargo search --registry=crates-io"
alias caf="cargo fetch"
alias cau="cargo update"
alias cais="cargo install"
alias caui="cargo uninstall"

# change
alias cmd="sudo chmod 744"
alias cwn="sudo chown -Rv $USER:$USER"

# crontab
alias cre="crontab -e"

# proxy
alias cclash="curlie -s http://127.0.0.1:3000/sub | tee config.yaml"
alias cspeed="clash-speedtest -c /home/wukaige/.config/clash/config.yaml -f 美国"

# bat
alias cat="bat"

# curlie
alias cl="curlie -s"

# copypath
alias cpath="copypath"

# ###  D  #####################################################################

# docker
alias dcv="docker volume"
alias dcpl="docker pull"
alias dcr="docker run"

alias dcc="docker container"
alias dcls="docker container ls"
alias dcla="docker container ls -a"
alias dcs="docker container stats"
alias dcst="docker container start"
alias dcrst="docker container restart"
alias dcstp="docker container stop"
alias dcrm="docker container rm"
alias dcat="docker container attach"
alias dcpr="docker container prune"

alias dils="docker image ls"
alias dirm="docker image rm"
alias dipr="docker image prune"

alias dcp="docker compose"
alias dcpu="docker compose up"
alias dcpud="docker compose up -d"
alias dcplg="docker compose logs"
alias dcpec="docker compose exec -it"

# dpkg
alias dis="sudo dpkg -i"

# tput: get terminal cols and lines
alias dim="echo $(tput cols)x$(tput lines)"

# dust
alias du="dust"

# deactivate python env
alias denv="deactivate"

# ###  E  #####################################################################

# edit file
alias ezs="$EDITOR $HOME/.zshrc"
alias epl="$EDITOR $HOME/.plugin.zsh"
alias eas="$EDITOR $HOME/.alias.zsh"
alias etm="$EDITOR $HOME/.tmux.conf"
alias ei3="$EDITOR $HOME/.config/i3/config"
alias eway="$EDITOR $HOME/.config/sway/config"
alias ebs="$EDITOR $HOME/.config/bspwm/bspwmrc"
alias exr="$EDITOR $HOME/.Xresources"
alias ehx="$EDITOR $HOME/.config/helix/config.toml"
alias eis="$EDITOR $HOME/.init.zsh"
alias ehr="$EDITOR $HOME/.config/hypr/hyprland.conf"
alias ev2="$EDITOR $HOME/.v2ray/config.json"
alias ehs="sudo $EDITOR /etc/hosts"

# editor
alias e="emacs --no-window-system"

# export
balias via="export proxy="

# eww
alias ew="eww"
alias ewo="eww open"
alias ewc="eww close"

# ###  F  #####################################################################

# fdisk
alias fds="sudo fdisk -l | sed -e '/Disk \/dev\/loop/,+5d'"

# flomo
alias fl="flomo-cli new"

# ftp
alias ftp="ftp -p"

# font
alias fls="fc-list | awk -F': ' '{print \$NF}' | fzf"

# rg with line number
alias frg="rg . -L| fzf --print0 -e | cut -d : -f1 | xargs -I f bash -c '[[ \"f\" != \"\" ]] && nvim f'"

# fortune
alias ft="fortune"

# fzf
alias ff="fzf"

# ###  G  #####################################################################

# git
alias gad="git add ."
alias gst="git status"
alias gsth="git stash"
alias gsp="git stash pop"
alias gcm="git commit -m"
alias gps="git push"
alias gpl="git pull --rebase"
alias gcl="git clone --depth 1"

# go
alias gomi="go mod init"
alias gomt="go mod tidy"
alias gor="go run ."

# gopeed
alias gp="gopeed"

# ###  H  #####################################################################

# hugo
alias h="hugo"
balias hnc="hugo new content posts/"
alias hns="hugo new site"
alias hs="hugo server"

# hyprctl
alias hc="hyprctl"
alias hcr="hyprctl reload"
alias hca="hyprctl activewindow"
alias hcb="hyprctl --batch"
alias hcd="hyprctl dispatch"
alias hcl="hyprctl layers"
alias hcw="hyprctl workspaces"
alias hcn="hyprctl notify -1 5000 'rgb(a3be8c)'"
alias hck="hyprctl keyword"
alias hcsd="hyprctl seterror disable"

# github
alias hub="sudo sh -c 'sed -i \"/# GitHub520 Host Start/Q\" /etc/hosts && curl https://raw.hellogithub.com/hosts >> /etc/hosts'"

# hurl
alias hr="hurl -k"

# ###  I  #####################################################################

# iptables
alias iptb="sudo iptables"
alias iptf="sudo iptables -F"
alias iptfi="sudo iptables -F INPUT"
alias iptfo="sudo iptables -F OUTPUT"
alias iptff="sudo iptables -F FORWARD"
alias iptl="sudo iptables -nvL"
alias iptli="sudo iptables -nvL INPUT"
alias iptlo="sudo iptables -nvL OUTPUT"
alias iptlf="sudo iptables -nvL FORWARD"
alias ipti="sudo iptables -I"
alias iptii="sudo iptables -I INPUT"
alias iptio="sudo iptables -I OUTPUT"
alias iptif="sudo iptables -I FORWARD"
alias ipta="sudo iptables -A"
alias iptai="sudo iptables -A INPUT"
alias iptao="sudo iptables -A OUTPUT"
alias iptaf="sudo iptables -A FORWARD"
alias iptd="sudo iptables -D"
alias iptdi="sudo iptables -D INPUT"
alias iptdo="sudo iptables -D OUTPUT"
alias iptdf="sudo iptables -D FORWARD"
alias iptp="sudo iptables -P"
alias iptpi="sudo iptables -P INPUT"
alias iptpo="sudo iptables -P OUTPUT"
alias iptpf="sudo iptables -P FORWARD"

# ipset
alias ips="sudo ipset"
alias ipsc="sudo ipset create"
alias ipsa="sudo ipset add"
alias ipsl="sudo ipset list"
alias ipst="sudo ipset test"
alias ipsf="sudo ipset flush"
alias ipsd="sudo ipset del"
alias ipsds="sudo ipset destroy"

# ip
alias ipa="ip addr"
alias ipaa="sudo ip addr add"
alias ipac="sudo ip addr change"
alias ipad="sudo ip addr delete"
alias ipaf="sudo ip addr flush"
alias ipag="sudo ip addr get"
alias ipah="sudo ip addr help"
alias ipar="sudo ip addr replace"
alias ipas="sudo ip addr show"

alias ipr="ip route"
alias ipra="sudo ip route add"
alias iprc="sudo ip route change"
alias iprcg="iprcg.sh"
alias iprd="sudo ip route delete"
alias iprf="sudo ip route flush"
alias iprg="sudo ip route get"
alias iprh="sudo ip route help"
alias iprr="sudo ip route replace"
alias iprs="sudo ip route show"

alias ipl="ip link"
alias iplh="sudo ip link help"
alias ipls="sudo ip link show"
alias iplst="sudo ip link set"

# ###  J  #####################################################################

# wd command
alias jad="wd add"
alias jrm="wd rm"

# journalctl
alias jcf="journalctl -f -t"
alias jcu="journalctl -xeu"

# jupyter
alias jki="ipython kernel install --user --name"
alias jkr="jupyter kernelspec remove"
alias jkl="jupyter kernelspec list"

# just
alias js="just"
alias jse="just --edit"
alias jsl="just --list"

# ###  K  #####################################################################

# kube
alias kbc="minikube kubectl --"

# pkill
alias kl="pkill"

# ###  L  #####################################################################

# lsof
balias li="sudo lsof -i:"

# ###  M  #####################################################################

# audio
alias mcl="mpc listall"
alias mca="mpc clear && mpc ls | mpc add"
alias mb="musicbox"

# mount
balias mt="sudo mount /dev/sd"

# pandoc
alias mto="for f in \`ls *.md\`; do pandoc -f markdown -t org -o \${f/.md/}.org \$f; done"

# mkdir
alias mk="mkdir -p"

# send mail
alias mgm="s-nail -A gmail"
alias mqq="s-nail -A qq"

# ###  N  #####################################################################

# nvim
alias n="nvim"

# nala
alias nai="sudo nala install -y"
alias nar="sudo nala remove"
alias nap="sudo nala purge"
alias nau="sudo nala update"
alias naug="sudo nala upgrade"
alias naf="sudo nala fetch"
alias nafx="sudo nala --fix-broken"
alias nas="sudo nala show"
alias nasc="sudo nala search"
alias nah="sudo nala history"
alias nac="sudo nala clean"

# nftables
alias nf="sudo nft"
alias nfa="sudo nft add table"
alias nfac="sudo nft add chain"
alias nfar="sudo nft add rule"
alias nfas="sudo nft add set"
alias nfi="sudo nft insert table"
alias nfic="sudo nft insert chain"
alias nfir="sudo nft insert rule"
alias nfis="sudo nft insert set"
alias nfl="sudo nft list table"
alias nfls="sudo nft list tables"
alias nflc="sudo nft list chain"
alias nflr="sudo nft list ruleset"
alias nff="sudo nft flush table"
alias nffc="sudo nft flush chain"
alias nfc="sudo nft chain"
alias nfd="sudo nft delete table"
alias nfdc="sudo nft delete chain"

# npm
alias nis="npm install -g"
alias nls="npm list -g"
alias nrm="npm remove -g"
alias nrs="npm run start"

# network
alias nst="netstat"
alias nsl="nslookup"
alias nc="netcat -v"
alias nt="nexttrace"

# nmcli
alias ncl="nmcli"

# ###  O  #####################################################################
# ###  P  #####################################################################

# podmain
alias pd="podman"
alias pdc="podman container"
alias pdv="podman volume"
alias pdpl="podman pull"
alias pdr="podman run"
alias pdls="podman container ls"
alias pdla="podman container ls -a"
alias pds="podman container stats"
alias pdst="podman container start"
alias pdrst="podman container restart"
alias pdstp="podman container stop"
alias pdrm="podman container rm"
alias pdat="podman container attach"
alias pdpr="podman container prune"
alias dnc="podman network create"
alias dnls="podman network ls"
alias dnrm="podman network rm"
alias pdps="podman ps"
alias pdlg="podman logs --follow"
alias pdec="podman exec -it"
alias pdcp="podman cp"
alias pdsc="podman search"
alias pddf="podman diff"
alias pdcm="podman commit"
alias pdis="podman inspect"

# pueue
alias p="pueue"
alias pad="pueue add --"
alias pfl="pueue follow"
alias pkl="pueue kill"
alias prm="pueue remove"
alias pcl="pueue clean"
alias ped="pueue edit"
alias pg="pueue group"
alias pga="pueue group add"
alias pgr="pueue group remove"
alias ppu="pueue pause"
alias pwt="pueue wait"
alias ppl="pueue parallel"
alias plg="pueue log"
alias psd="pueue send"
alias pst="pueue start"
alias prst="pueue restart"
alias psts="pueue stash"
alias prs="pueue reset"

# pip
alias pis="pip install"
alias pls="pip list"
alias pui="pip uninstall"
alias pfz="pip freeze"

# mitmproxy
alias ptc="openssl x509 -outform der -in mitmproxy-ca-cert.pem -out mitmproxy-ca-cert.crt"
alias ptv="openssl x509 -inform PEM -subject_hash_old -in mitmproxy-ca-cert.pem | head -1"

# path line by line
alias path="echo $PATH | tr ':' '\n'"

# set proxy
alias pre="export http_proxy=http://${proxy:-127.0.0.1:7890} https_proxy=http://${proxy:-127.0.0.1:7890}"
alias prd="unset http_proxy https_proxy"

# gping
alias ping="gping"

# pid
alias pof="pidof"

# ###  Q  #####################################################################
# ###  R  #####################################################################

# route
alias rt="route"
alias rta="route add"
alias rtd="route del"
alias rtf="route flush"
alias rtv="route -v"

# remove
alias rf="rm -rf"

# get link path
alias rl="readlink -f"

# os release
alias rls="lsb_release -a"

# redis
alias rcl="redis-cli"

# rsync
alias ryc="rsync -avP --partial --progress"

# ###  S  #####################################################################

# change wallpaper
alias s="swww img --transition-type center"

# systemctl
alias scs="sudo systemctl status"
alias scst="sudo systemctl start"
alias scstp="sudo systemctl stop"
alias scrst="sudo systemctl restart"
alias scdr="sudo systemctl daemon-reload"
alias sce="sudo systemctl enable"
alias scd="sudo systemctl disable"
alias sced="sudo -E systemctl edit"

alias sus="systemctl --user status"
alias sust="systemctl --user start"
alias sustp="systemctl --user stop"
alias surst="systemctl --user restart"
alias sudr="systemctl --user daemon-reload"
alias sue="systemctl --user enable"
alias sud="systemctl --user disable"
alias sued="systemctl --user edit"

# Source configs
alias szs="source ~/.zshrc"
alias sxr="xrdb -merge $HOME/.Xresources || xrdb $HOME/.Xresources"
alias sis="source $HOME/.init.zsh"
alias sds="source $HOME/.display.zsh"

# swap on/off 
alias spon="sudo swapon -a && free -h"
alias spso="sudo swapon --show"
alias spof="sudo swapoff -a && free -h"

# python env
alias senv="source venv/bin/activate"

# ###  T  #####################################################################

# trans
alias t="trans :zh"

# compress file
alias trc="tar -cvf"
alias trx="tar -xvf"
alias trv="tar -tvf"

# touch
alias tc="touch"

# ###  U  #####################################################################

# mount devices
alias umt="sudo umount"

# alternative
alias uai="sudo update-alternatives --install"
alias uac="sudo update-alternatives --config"

# unzip
alias uz="unzip"

# ###  V  #####################################################################
# ###  W  #####################################################################

# watch
alias wch="watch -c -n 1"
alias wis="whereis"
alias wic="which"

# ###  X  #####################################################################
# ###  Y  #####################################################################
# ###  Z  #####################################################################

alias zif="zipinfo"

# ###  ?  #####################################################################

# copilot
ialias c?="gh copilot suggest"
ialias c??="gh copilot explain"

