#########
### A ###
#########

# download
alias arc="aria2c -c"
alias arcs="aria2c -c -s"

# alsamixer
alias am="alsamixer"

#########
### B ###
#########

# brew
alias br="brew"

# bluetooth
alias bt="bluetoothctl"

# base encode
alias b32="base32"
alias b64="base64"

#########
### C ###
#########

# dotfiles
ialias c="git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git"
alias cs="c status"
alias cad="cadd"
alias crs="c restore"
alias clg="c log"
alias cme="c commit --edit"
alias cma="c commit --amend"
alias cman="c commit --amend --no-edit"
alias cmm="c commit -m"
alias cpl="c pull --rebase"
alias cps="c push"
alias cls="c ls-tree -r master --name-only"

# cargo
alias ca="cargo"
alias cai="cargo init"
alias caad="cargo add"
alias cab="cargo build"
alias car="cargo run"
alias caw="cargo watch -x run"
alias carm="cargo remove"
alias cac="cargo clean"
alias cas="cargo search --registry=crates-io"
alias cau="cargo update"
alias cais="cargo install"
alias caui="cargo uninstall"

# change
alias cmd="sudo chmod 744"
alias cwn="sudo chown -Rv $USER:$USER"

# crontab
alias cre="crontab -e"

# curl
alias cl="curl"

#########
### D ###
#########

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

alias dcisp="docker inspect"
alias dcip="docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'"

# dpkg
alias dis="sudo dpkg -i"

# tput: get terminal cols and lines
alias dim="echo $(tput cols)x$(tput lines)"

# dust
alias ds="dust"

#########
### E ###
#########

alias eas="v ~/.zsh.d/alias.zsh"

#########
### F ###
#########

# fdisk
alias fds="sudo fdisk -l | sed -e '/Disk \/dev\/loop/,+5d'"

# fzf
alias ff="fzf"

#########
### G ###
#########

# gitui
alias gu="gitui"

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

#########
### H ###
#########

# hyprctl
alias hc="hyprctl"

# hurl
alias hr="hurl -k"

#########
### J ###
#########

# journalctl
alias jcl="journalctl"
alias jcu="journalctl -u"

# just
alias js="just"
alias jsi="just --init"
alias jse="just --edit"
alias jsl="just --list"

#########
### K ###
#########

# kube
alias kbc="minikube kubectl --"

#########
### L ###
#########

# lsof
balias li="sudo lsof -i:"

#########
### M ###
#########

# mount
balias mt="sudo mount /dev/sd"

# mkdir
alias mk="mkdir -p"

#########
### N ###
#########

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

# network
alias nc="netcat -v"
alias nst="netstat"
alias nsl="nslookup"
alias ncl="nmcli"

#########
### P ###
#########

# pueue
alias p="pueue"

# podmain
alias pd="podman"
alias pdc="podman container"
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
alias pdps="podman ps"
alias pdlg="podman logs --follow"
alias pdec="podman exec -it"
alias pdcp="podman cp"
alias pdsc="podman search"
alias pddf="podman diff"
alias pdis="podman inspect"

# podman-compose
alias pc="podman-compose"

# mitmproxy
alias ptc="openssl x509 -outform der -in mitmproxy-ca-cert.pem -out mitmproxy-ca-cert.crt"
alias ptv="openssl x509 -inform PEM -subject_hash_old -in mitmproxy-ca-cert.pem | head -1"

# path line by line
alias path="echo \$PATH | tr ':' '\n'"

# set proxy
alias pre="host=127.0.0.1 port=7890 export http_proxy=http://\$host:\$port https_proxy=http://\$host:\$port"
alias prd="unset http_proxy https_proxy"

#########
### R ###
#########

# remove
alias rf="rm -rf"

# realpath
alias rp="realpath"

# reallink
alias rl="readlink -f"

# os release
alias rls="lsb_release -a"

# redis
alias rcl="redis-cli"

# rsync
alias rsy="rsync -avP"

#########
### S ###
#########

# source
alias sc="source"
alias senv="source .venv/bin/activate"
alias denv="deactivate"
alias szs="source ~/.zshrc"

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

#########
### U ###
#########

# mount devices
alias umt="sudo umount"

# alternative
alias uai="sudo update-alternatives --install"
alias uac="sudo update-alternatives --config"

# unzip
alias uz="unzip"

#########
### W ###
#########

# watch
alias wch="watch -c -n 1"
alias wis="whereis"
alias wic="which"

#########
### Y ###
#########

alias y="yazi"

#########
### Z ###
#########

alias zl="zellij"
alias zr="zellij run --floating --width 50% --height 100% -x 50% -y 0% --"
alias zif="zipinfo"

