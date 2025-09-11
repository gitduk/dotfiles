lazy_group claude <<EOF
alias cco="ccr code --dangerously-skip-permissions"
EOF

lazy_group aria2 <<EOF
alias arc="aria2c -c"
alias arcs="aria2c -c -s"
EOF

lazy_group alsamixer <<EOF
alias am="alsamixer"
EOF

lazy_group bluetooth <<EOF
alias bt="bluetoothctl"
EOF

ialias c="git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git"
lazy_group dotfiles <<EOF
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
EOF

lazy_group terminal <<EOF
alias dim="echo $(tput cols)x$(tput lines)"
EOF

lazy_group gitui <<EOF
alias gu="gitui"
EOF

lazy_group gemini <<EOF
alias gm="gemini"
EOF

lazy_group just <<EOF
alias js="just"
EOF

lazy_group mitmproxy <<EOF
alias ptc="openssl x509 -outform der -in mitmproxy-ca-cert.pem -out mitmproxy-ca-cert.crt"
alias ptv="openssl x509 -inform PEM -subject_hash_old -in mitmproxy-ca-cert.pem | head -1"
EOF
alias rcl="redis-cli"

lazy_group redis <<EOF
EOF

lazy_group unzip <<EOF
alias uz="unzip"
EOF
