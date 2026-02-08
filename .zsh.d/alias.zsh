#############
### Alias ###
#############

alias e="extract"
alias bt="bluetoothctl"
alias cmd="sudo chmod +x"
alias cwn="sudo chown -Rv $USER:$USER"
alias cre="crontab -e"
alias dis="sudo dpkg -i"
alias denv="deactivate"
alias dim="echo $(tput cols)x$(tput lines)"
alias fds="sudo fdisk -l | sed -e '/Disk \/dev\/loop/,+5d'"
alias jcl="journalctl"
alias jcu="journalctl -u"
alias jcuu="journalctl --user -u"
alias lv="lnav"
alias mk="mkdir -p"
alias nc="netcat -v"
alias nsl="nslookup"
alias nst="netstat"
alias ncl="nmcli"
alias nw="networkctl"
alias path='echo $PATH | tr ":" "\n" | fzf --preview=""'
alias pre="proxy"
alias prd="proxy -u"
alias rf="rm -rf"
alias rp="realpath"
alias rl="readlink -f"
alias rls="lsb_release -a"
alias rsy="rsync -avP"
alias rds="redis-cli"
alias tn="telnet"
alias umt="sudo umount"
alias uz="unzip"
alias wis="whereis"
alias wic="which"
alias wch="watch -c -n 1"
alias li="sudo lsof -i:"
alias mt="sudo mount /dev/sd"

# atuin
alias asy="atuin sync"

# bun
alias b="bun"
alias bx="bun x"
alias br="bun run"
alias bad="bun add"
alias bis="bun install -g"
alias brm="bun remove -g"
alias brs="bun run serve"

# bacon
alias bac="bacon"
alias bai="bacon --init"

# dotfiles
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

# cargo
alias ca="cargo"
alias cai="cargo init"
alias can="cargo new"
alias caad="cargo add"
alias cab="cargo build"
alias car="cargo run"
alias carb="cargo run --bin"
alias caf="cargo fetch"
alias caw="cargo watch -x run"
alias carm="cargo remove"
alias cac="cargo clean"
alias cack="cargo check"
alias cas="cargo sync"
alias cau="cargo update"
alias cais="cargo install"
alias caui="cargo uninstall"

# claude
alias cld="claude"

# dust
alias du="dust"

# dysk
alias ds="dysk"

# direnv
alias di="direnv"

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

alias disp="docker inspect"
alias dip="docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'"

# edit
alias ezs="v ~/.zshrc && source ~/.zshrc"
alias eas="v ~/.zsh.d/alias.zsh && source ~/.zsh.d/alias.zsh"
alias ecs="v ~/.custom.zsh && source ~/.custom.zsh"
alias epw="v ~/.pw.json"
alias ejs="v .justfile"
alias eis="v ~/.config/navi/cheats/install.cheat"
alias epd="v ~/.config/navi/cheats/podman.cheat"
alias ehs="v /etc/hosts"

# easytier
alias epr="easytier-cli peer"

# feedr
alias f="feedr"

# fscan
alias fs="fscan"

# fastfetch
alias ff="fastfetch"

# gmini
alias gm="gemini"

# go
alias gomi="go mod init"
alias gomt="go mod tidy"
alias gor="go run ."

# git
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

# hyprland
alias hc="hyprctl"

# just
alias js="just"
alias jse="just --edit"
alias jsl="just --list"

# json-server
alias jss="json-server"

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

# open
alias o="open"

# openclaw
alias oc="openclaw"

# opencode
alias ocd="opencode"

# pueue
alias p="pueue"
alias pad="pueue add"
alias prs="pueue restart"
alias pkl="pueue kill"
alias pcl="pueue clean"
alias ped="pueue edit"

# podman
alias pd="podman"
alias pdc="podman container"
alias pdls="podman container ls"
alias pdla="podman container ls --all"
alias pdr="podman run"
alias pds="podman stats"
alias pdst="podman start"
alias pdsp="podman stop"
alias pdrs="podman restart"
alias pdps="podman ps"
alias pdlg="podman logs --tail 100 --follow"
alias pdec="podman exec -it"
alias pdcp="podman cp"
alias pdrm="podman rm"
alias pdri="podman rmi"
alias pdsc="podman search"
alias pddf="podman diff"
alias pdis="podman inspect"
alias pdv="podman volume"
alias pdn="podman network"

# sttr
alias sr="sttr"

# snitch
alias sn="snitch"

# systemctl
alias scs="sudo systemctl status"
alias scst="sudo systemctl start"
alias scsp="sudo systemctl stop"
alias scrs="sudo systemctl restart"
alias scdr="sudo systemctl daemon-reload"
alias sce="sudo systemctl enable"
alias scd="sudo systemctl disable"

# systemctl --user
alias sus="systemctl --user status"
alias sust="systemctl --user start"
alias surs="systemctl --user restart"
alias susp="systemctl --user stop"
alias sudr="systemctl --user daemon-reload"
alias sue="systemctl --user enable"
alias sud="systemctl --user disable"
alias sued="systemctl --user edit"
alias suef="systemctl --user edit --force --full"

# vfox
alias vo="vfox"

# witr
alias wi="witr"
alias wip="witr --port"

# xh
alias x="xh"

