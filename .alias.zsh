#########
### A ###
#########

alias arc="aria2c -c"
alias arcs="aria2c -c -s"

alias am="alsamixer"

#########
### B ###
#########

alias b="bun"
alias bx="bun x"
alias bad="bun add"
alias bis="bun install -g"
alias brm="bun remove -g"

alias br="brew"

alias bt="bluetoothctl"

#########
### C ###
#########

alias cl="curlie -sk"

alias cld="claude"

alias ca="cargo"
alias cai="cargo init"
alias caad="cargo add"
alias cab="cargo build"
alias car="cargo run"
alias caw="cargo watch -x run"
alias carm="cargo remove"
alias cac="cargo clean"
alias cack="cargo check"
alias cas="cargo search --registry=crates-io"
alias cau="cargo update"
alias cais="cargo install --locked"
alias caui="cargo uninstall"

alias cmd="sudo chmod +x"
alias cwn="sudo chown -Rv $USER:$USER"

alias cre="crontab -e"

ialias c="git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git"

alias cs="c status"
alias cdf="c diff"
alias cds="c diff --staged"
alias cad="cadd"
alias crs="c restore"
alias cst="c stash"
alias csp="c stash pop"
alias clg="c log"
alias cme="c commit --edit"
alias cma="c commit --amend"
alias cman="c commit --amend --no-edit"
alias cmm="c commit -m"
alias cpl="c pull --rebase"
alias cps="c push"
alias cls="c ls-tree -r master --name-only"

#########
### D ###
#########

alias di="direnv"

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

alias disp="docker inspect"
alias dip="docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'"

alias du="dust"

alias ds="dysk"

alias dis="sudo dpkg -i"

#########
### E ###
#########

alias e="extract"

alias ezs="v ~/.zshrc"
alias eas="v ~/.alias.zsh"
alias eis="v ~/.installer.zsh"
alias epw="v ~/.pw.json"
alias ejs="v .justfile"

alias eo="easytier-core"
alias el="easytier-cli"

#########
### F ###
#########

alias fds="sudo fdisk -l | sed -e '/Disk \/dev\/loop/,+5d'"

alias f="fzf"

alias ff="fastfetch"

#########
### G ###
#########

alias gad="git add ."
alias gst="git status"
alias gdf="git diff"
alias gsth="git stash"
alias gco="git checkout"
alias gsp="git stash pop"
alias gcm="git commit -m"
alias gps="git push"
alias gpl="git pull --rebase"
alias gcl="git clone --depth 1"

alias gomi="go mod init"
alias gomt="go mod tidy"
alias gor="go run ."

alias gu="gitui"

alias gm="gemini"

#########
### H ###
#########

alias hr="hurl"

#########
### I ###
#########

alias ifs="ipfs"

#########
### J ###
#########

alias js="just"
alias jse="just --edit"
alias jsl="just --list"

alias jx="fx"

alias jcl="journalctl"
alias jcu="journalctl -u"
alias jcuu="journalctl --user -u"

alias jn="jupyter-notebook"

alias js="just"

#########
### L ###
#########

ialias ls="eza"

balias li="sudo lsof -i:"

#########
### M ###
#########

balias mt="sudo mount /dev/sd"

alias mk="mkdir -p"

alias ms="mise"

#########
### N ###
#########

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

alias nc="netcat -v"
alias nsl="nslookup"
alias nst="netstat"
alias ncl="nmcli"

alias np="nping"

#########
### O ###
#########

alias ox="sudo oryx"

alias oa="oha"

#########
### P ###
#########

alias ps="procs"

alias pd="podman"
alias pdc="podman container"
alias pdr="podman run"
balias pdls="podman container ls"
alias pdla="podman container ls -a"
alias pds="podman container stats"
alias pdst="podman container start"
alias pdrst="podman container restart"
alias pdstp="podman container stop"
alias pdrm="podman container rm"
alias pdat="podman container attach"
alias pdpr="podman container prune"
alias pdps="podman ps"
alias pdlg="podman logs --tail 100 --follow"
alias pdec="podman exec -it"
alias pdc="podman cp"
alias pdsc="podman search"
alias pddf="podman diff"
alias pdis="podman inspect"
alias pdv="podman volume"
alias pdvl="podman volume ls"

alias pdcp="podman compose"
alias pdcpu="podman compose up"
alias pdcpud="podman compose up -d"

alias path='echo $PATH | tr ":" "\n" | fzf'

alias pre="setup_proxy"
alias prd="unset_proxy"

#########
### R ###
#########

alias rf="rm -rf"

alias rp="realpath"

alias rl="readlink -f"

alias rls="lsb_release -a"

alias rsy="rsync -avP"

alias rcl="redis-cli"

#########
### S ###
#########

alias st="sttr"

alias sc="source"
alias denv="deactivate"

alias scs="sudo systemctl status"
alias scst="sudo systemctl start"
alias scstp="sudo systemctl stop"
alias scrst="sudo systemctl restart"
alias scdr="sudo systemctl daemon-reload"
alias sce="sudo systemctl enable"
alias scd="sudo systemctl disable"

alias sus="systemctl --user status"
alias sust="systemctl --user start"
alias sustp="systemctl --user stop"
alias surst="systemctl --user restart"
alias sudr="systemctl --user daemon-reload"
alias sue="systemctl --user enable"
alias sud="systemctl --user disable"
alias sued="systemctl --user edit"
alias suef="systemctl --user edit --force --full"

alias sm="somo"
alias sml="somo -tl"

#########
### T ###
#########

alias dim="echo $(tput cols)x$(tput lines)"

#########
### U ###
#########

alias umt="sudo umount"

alias uz="unzip"

#########
### W ###
#########

alias wch="watch -c -n 1"
alias wis="whereis"
alias wic="which"

#########
### X ###
#########

alias x="xh"

#########
### Y ###
#########

alias y="yazi"

