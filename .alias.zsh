#########
### C ###
#########
# change
alias cmd="sudo chmod +x"
alias cwn="sudo chown -Rv $USER:$USER"

# crontab
alias cre="crontab -e"

#########
### D ###
#########
# dpkg
alias dis="sudo dpkg -i"

#########
### E ###
#########

alias eas="v ~/.alias.zsh"

#########
### F ###
#########
# fdisk
alias fds="sudo fdisk -l | sed -e '/Disk \/dev\/loop/,+5d'"

#########
### J ###
#########

# journalctl
alias jcl="journalctl"
alias jcu="journalctl -u"
alias jcuu="journalctl --user -u"

#########
### L ###
#########
# ls
ialias ls="ls --color=auto"

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

# network
alias nc="netcat -v"
alias nsl="nslookup"
alias nst="netstat"
alias ncl="nmcli"

#########
### P ###
#########

# path line by line
alias path='echo $PATH | tr ":" "\n" | fzf'

# set proxy
alias pre="setup_proxy"
alias prd="unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY"

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

# rsync
alias rsy="rsync -avP"

#########
### S ###
#########

# source
alias sc="source"
alias denv="deactivate"

# systemctl
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

#########
### U ###
#########

# mount devices
alias umt="sudo umount"

#########
### W ###
#########

# watch
alias wch="watch -c -n 1"
alias wis="whereis"
alias wic="which"
