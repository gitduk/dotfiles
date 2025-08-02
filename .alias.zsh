################
### function ###
################

function lazy_group() {
  local cmd="$1"
  local content=""
  while IFS= read -r line; do
    case $line in
    alias* | ialias* | balias*)
      local alias_name="${line#*alias }"
      alias_name="${alias_name%%=*}"
      alias_name="${alias_name%"${alias_name##*[![:space:]]}"}"
      alias_name="${alias_name#"${alias_name%%[![:space:]]*}"}"
      lazy_map[$alias_name]="$line"
      ;;
    esac
    content+="$line; "
  done
  lazy_map[$cmd]="$content"
}

#########
### B ###
#########

lazy_group bun <<EOF
alias b="bun"
alias bx="bun x"
alias bad="bun add"
alias bis="bun install -g"
alias brm="bun remove -g"
EOF

lazy_group br <<EOF
alias br="brew"
EOF

#########
### C ###
#########

lazy_group curl <<EOF
alias cl="curl"
EOF

lazy_group claude <<EOF
alias cld="claude"
EOF

lazy_group cargo <<EOF
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
alias cais="cargo install --locked"
alias caui="cargo uninstall"
EOF

lazy_group curl <<EOF
alias curl="curlie"
EOF
lazy_group chmod <<EOF
alias cmd="sudo chmod +x"
alias cwn="sudo chown -Rv $USER:$USER"
EOF

lazy_group crontab <<EOF
alias cre="crontab -e"
EOF

#########
### D ###
#########

lazy_group direnv <<EOF
alias di="direnv"
EOF

lazy_group docker <<EOF
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
EOF

lazy_group du <<EOF
alias du="dust"
EOF

lazy_group dsk <<EOF
alias dsk="dysk"
EOF

lazy_group dpkg <<EOF
alias dis="sudo dpkg -i"
EOF

#########
### E ###
#########

lazy_group eidt <<EOF
alias eas="v ~/.alias.zsh"
EOF

lazy_group easytier <<EOF
alias eco="easytier-core"
alias ecl="easytier-cli"
EOF

#########
### F ###
#########
lazy_group fdisk <<EOF
alias fds="sudo fdisk -l | sed -e '/Disk \/dev\/loop/,+5d'"
EOF

lazy_group ff <<EOF
alias ff="fzf"
EOF

lazy_group ff <<EOF
alias ff="fzf"
EOF

#########
### G ###
#########

lazy_group git <<EOF
alias gad="git add ."
alias gst="git status"
alias gsth="git stash"
alias gsp="git stash pop"
alias gcm="git commit -m"
alias gps="git push"
alias gpl="git pull --rebase"
alias gcl="git clone --depth 1"
EOF

lazy_group go <<EOF
alias gomi="go mod init"
alias gomt="go mod tidy"
alias gor="go run ."
EOF

lazy_group git <<EOF
alias gst="git status"
alias gco="git checkout"
alias gd="git diff"
EOF

#########
### H ###
#########

lazy_group hr <<EOF
alias hr="hurl"
EOF

#########
### J ###
#########

lazy_group just <<EOF
alias js="just"
alias jse="just --edit"
alias jsl="just --list"
EOF

lazy_group jq <<EOF
alias jq="fx"
EOF

lazy_group journalctl <<EOF
alias jcl="journalctl"
alias jcu="journalctl -u"
alias jcuu="journalctl --user -u"
EOF

#########
### L ###
#########

ialias ls="eza"

lazy_group lsof <<EOF
balias li="sudo lsof -i:"
EOF

#########
### M ###
#########

lazy_group mount <<EOF
balias mt="sudo mount /dev/sd"
EOF

lazy_group mkdir <<EOF
alias mk="mkdir -p"
EOF

#########
### N ###
#########

lazy_group nala <<EOF
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
EOF

lazy_group network <<EOF
alias nc="netcat -v"
alias nsl="nslookup"
alias nst="netstat"
alias ncl="nmcli"
EOF

#########
### P ###
#########

lazy_group ps <<EOF
alias ps="procs"
EOF

lazy_group podman <<EOF
alias pd="podman"
alias pdc="podman container"
alias pdr="podman run"
alias pdls="podman container ls --format 'table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.RunningFor}}'"
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
alias pdc="podman cp"
alias pdsc="podman search"
alias pddf="podman diff"
alias pdis="podman inspect"

alias pdcp="podman compose"
alias pdcpu="podman compose up"
alias pdcpud="podman compose up -d"
EOF

lazy_group path <<EOF
alias path='echo $PATH | tr ":" "\n" | fzf'
EOF

lazy_group proxy <<EOF
alias pre="setup_proxy"
alias prd="unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY"
EOF

#########
### R ###
#########

lazy_group remove <<EOF
alias rf="rm -rf"
EOF

lazy_group realpath <<EOF
alias rp="realpath"
EOF

lazy_group readlink <<EOF
alias rl="readlink -f"
EOF

lazy_group os_release <<EOF
alias rls="lsb_release -a"
EOF

lazy_group rsync <<EOF
alias rsy="rsync -avP"
EOF

#########
### S ###
#########

lazy_group st <<EOF
alias st="sttr"
EOF

lazy_group src <<EOF
alias sc="source"
alias denv="deactivate"
EOF

lazy_group systemctl <<EOF
alias scs="sudo systemctl status"
alias scst="sudo systemctl start"
alias scstp="sudo systemctl stop"
alias scrst="sudo systemctl restart"
alias scdr="sudo systemctl daemon-reload"
alias sce="sudo systemctl enable"
alias scd="sudo systemctl disable"

alias sus="systemctl status --user"
alias sust="systemctl start --user"
alias sustp="systemctl stop --user"
alias surst="systemctl restart --user"
alias sudr="systemctl daemon-reload --user"
alias sue="systemctl enable --user"
alias sud="systemctl disable --user"
alias sued="systemctl edit --user"
alias suef="systemctl edit --user --force --full"
EOF

#########
### U ###
#########

lazy_group umount <<EOF
alias umt="sudo umount"
EOF

#########
### W ###
#########

lazy_group w <<EOF
alias wch="watch -c -n 1"
alias wis="whereis"
alias wic="which"
EOF

#########
### Y ###
#########

lazy_group y <<EOF
alias y="yazi"
EOF
