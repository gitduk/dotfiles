################
### function ###
################

function lazy_group() {
  local cmd="$1"
  local content=""
  while IFS= read -r line; do
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

#########
### D ###
#########

lazy_group direnv <<EOF
alias di="direnv"
EOF

lazy_group docker <<EOF
alias dv="docker volume"
alias dpl="docker pull"
alias dr="docker run"

alias dcc="docker container"
alias dls="docker container ls"
alias dla="docker container ls -a"
alias ds="docker container stats"
alias dst="docker container start"
alias drst="docker container restart"
alias dstp="docker container stop"
alias drm="docker container rm"
alias dat="docker container attach"
alias dpr="docker container prune"

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

#########
### F ###
#########

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
alias jsi="just --init"
alias jse="just --edit"
alias jsl="just --list"
EOF

lazy_group jq <<EOF
alias jq="fx"
EOF

#########
### L ###
#########

lazy_group ls <<EOF
alias ls="eza"
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

alias pc="podman-compose"
EOF

#########
### S ###
#########

lazy_group st <<EOF
alias st="sttr"
EOF

#########
### Y ###
#########

lazy_group y <<EOF
alias y="yazi"
EOF

