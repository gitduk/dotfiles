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
### J ###
#########

# just
alias js="just"

#########
### P ###
#########

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
