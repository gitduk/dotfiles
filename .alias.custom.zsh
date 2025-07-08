#########
### A ###
#########
# claude code
alias cco="ccr code --dangerously-skip-permissions"

# aria2
alias arc="aria2c -c"
alias arcs="aria2c -c -s"

# alsamixer
alias am="alsamixer"

#########
### B ###
#########

# bluetooth
alias bt="bluetoothctl"

#########
### D ###
#########
# dotfiles
ialias c="git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git"
alias cs="c status"
alias cdf="c diff"
alias cds="c diff --staged"
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

# tput: get terminal cols and lines
alias dim="echo $(tput cols)x$(tput lines)"

#########
### G ###
#########

# gitui
alias gu="gitui"

# gemini
alias gm="gemini"

#########
### P ###
#########
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

#########
### R ###
#########

# redis
alias rcl="redis-cli"

#########
### U ###
#########

# unzip
alias uz="unzip"

#########
### Z ###
#########

# zellij
alias zl="zellij"
alias zr="zellij run --floating --width 50% --height 100% -x 50% -y 0% --"
alias zif="zipinfo"
