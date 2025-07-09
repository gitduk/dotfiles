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

##############
### groups ###
##############

lazy_group ff <<EOF
alias ff="fzf"
EOF

lazy_group git <<EOF
alias gst="git status"
alias gco="git checkout"
alias gd="git diff"
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
