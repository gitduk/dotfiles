#################
### Installer ###
#################

# fzf
zinit ice wait"0" lucid as"program" from"gh-r" id-as"fzf" \
  atclone"./fzf --zsh > init.zsh" \
  atclone"mv ./fzf $BPFX/" \
  src"init.zsh" \
  atpull"%atclone"
zinit light junegunn/fzf

# navi
zinit ice wait"0" lucid as"program" from"gh-r" id-as"navi" \
  atload'
    export NAVI_PATH="$HOME/.config/navi/cheats"
    export NAVI_CONFIG="$HOME/.config/navi/config.yaml"
    [[ ! -d "$NAVI_PATH" ]] && mkdir -p $NAVI_PATH
    [[ ! -e "$NAVI_CONFIG" ]] && navi info config-example > $NAVI_CONFIG
    eval "$(navi widget zsh)"
    bindkey "^N" _navi_widget
    ' \
  atpull"%atclone"
zinit light denisidoro/navi

# fnm - node version manager
zinit ice wait"1" lucid as"program" id-as"fnm" \
  atclone"
    curl -fsSL https://fnm.vercel.app/install | bash
    ~/.local/share/fnm/fnm env --use-on-cd --shell zsh > init.zsh
    ~/.local/share/fnm/fnm completions --shell zsh > _fnm
    ln -fs ~/.local/share/fnm/fnm $BPFX/fnm
    " \
  src"init.zsh" \
  atpull"%atclone"
zinit light zdharma-continuum/null

# bun - Bun is an all-in-one toolkit for JavaScript and TypeScript apps.
zinit ice wait"1" lucid as"program" from"gh-r" id-as"bun" \
  bpick"bun-linux-x64.zip" \
  atclone"mkdir -p ~/.bun/bin && mv */bun ~/.bun/bin/" \
  atclone"SHELL=zsh ~/.bun/bin/bun completions" \
  atclone"mv ~/.bun/_bun _bun" \
  atclone"rm -rf */" \
  atpull"%atclone" \
  atload'
    export PATH="$HOME/.bun/bin:$PATH"
    export PATH="$HOME/.cache/.bun/bin:$PATH"
  '
zinit light oven-sh/bun

# zsh-completions
zinit ice wait"2" blockf lucid id-as"zsh-completions" \
  atpull"zinit creinstall -q ."
zinit light zsh-users/zsh-completions

# alacritty
zinit ice if'[[ -n $DISPLAY ]]' lucid as"program" id-as"alacritty" \
  atclone'export PATH="$HOME/.cargo/bin:$PATH"' \
  atclone"cargo build --release --no-default-features --features=wayland" \
  atclone"sudo cp target/release/alacritty /usr/bin" \
  atclone"sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg" \
  atclone"sudo desktop-file-install extra/linux/Alacritty.desktop" \
  atclone"sudo update-desktop-database" \
  atpull"%atclone"
zinit light alacritty/alacritty

# fd
zinit ice if'(( ! $+commands[fd] ))' lucid as"program" from"gh-r" id-as"fd" \
  atclone"mv */fd $BPFX/" \
  atclone"mv */autocomplete/_fd ." \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light sharkdp/fd

# nvim
zinit ice if'(( ! $+commands[nvim] ))' lucid as"program" from"gh-r" id-as"nvim" \
  bpick"nvim-linux-x86_64.appimage" \
  atclone"sudo mv nvim-linux-x86_64.appimage /usr/bin/nvim" \
  atpull"%atclone"
zinit light neovim/neovim

# hx
zinit ice if'(( ! $+commands[hx] ))' lucid as"program" from"gh-r" id-as"hx" \
  atclone"sudo mv */hx /usr/bin/" \
  atclone"mv */runtime ~/.config/helix/" \
  atclone"mv */contrib/completion/hx.zsh _hx" \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light helix-editor/helix

# sing-box
zinit ice if'(( ! $+commands[sing-box] ))' lucid as"program" from"gh-r" id-as"sing-box" \
  bpick"sing-box-*-linux-amd64.tar.gz" \
  atclone"mv */sing-box $BPFX/sing-box" \
  atclone"sudo setcap cap_net_admin=+ep $BPFX/sing-box" \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light SagerNet/sing-box

# atuin
zinit ice wait"0" lucid as"command" from"gh-r" id-as"atuin" \
  bpick"atuin-*.tar.gz" \
  atclone"mv */atuin atuin" \
  atclone"./atuin init zsh > init.zsh" \
  atclone"./atuin gen-completions --shell zsh > _atuin" \
  atclone"rm -rf */" \
  src"init.zsh" \
  atpull"%atclone"
zinit light atuinsh/atuin

# zoxide
zinit ice wait"1" lucid as"command" from"gh-r" id-as"zoxide" \
  atclone"./zoxide init zsh --cmd j > init.zsh" \
  src"init.zsh" \
  atpull"%atclone"
zinit light ajeetdsouza/zoxide

# direnv
zinit ice wait"2" lucid as"command" from"gh-r" id-as"direnv" \
  atclone"mv direnv* direnv" \
  atclone"./direnv hook zsh > init.zsh" \
  atpull"%atclone" \
  src"init.zsh"
zinit light direnv/direnv

# nb
zinit ice wait"1" lucid as"command" from"gh-r" id-as"nb"
zinit light xwmx/nb

# just
zinit ice if'(( ! $+commands[just] ))' lucid as"command" from"gh-r" id-as"just" \
  atclone'./just --completions zsh > _just' \
  atpull"%atclone"
zinit light casey/just

# delta - A syntax-highlighting pager for git, diff, and grep output
zinit ice if'(( ! $+commands[delta] ))' lucid as"command" from"gh-r" id-as"delta" \
  atclone"mv */delta ." \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light dandavison/delta

# curlie
zinit ice if'(( ! $+commands[curlie] ))' lucid as"command" from"gh-r" id-as"curlie"
zinit light rs/curlie

# hurl
zinit ice if'(( ! $+commands[hurl] ))' lucid as"command" from"gh-r" id-as"hurl" \
  atclone"mv */bin/* ." \
  atclone"mv */completions/_hurl ." \
  atclone"mv */completions/_hurlfmt ." \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light Orange-OpenSource/hurl

# dust
zinit ice if'(( ! $+commands[dust] ))' lucid as"command" from"gh-r" id-as"dust" \
  atclone"sudo mv */dust /usr/bin/" \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light bootandy/dust

# eza - eza is a modern replacement for ls
zinit ice if'(( ! $+commands[eza] ))' lucid as"command" from"gh-r" id-as"eza"
zinit light eza-community/eza

# fx - Command-line tool and terminal JSON viewer
zinit ice if'(( ! $+commands[fx] ))' lucid as"command" from"gh-r" id-as"fx" \
  atclone"mv fx* fx"
zinit light antonmedv/fx

# gh
zinit ice if'(( ! $+commands[gh] ))' lucid as"command" from"gh-r" id-as"gh" \
  atclone"sudo mv */bin/gh /usr/bin/" \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light cli/cli

# glow - Glow is a terminal-based markdown reader designed from the ground up to bring out the beauty—and power—of the CLI
zinit ice if'(( ! $+commands[glow] ))' lucid as"command" from"gh-r" id-as"glow" \
  atclone"mv */glow ." \
  atclone"mv */completions/glow.zsh _glow" \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light charmbracelet/glow

# grex - A command-line tool and library for generating regular expressions from user-provided test cases
zinit ice if'(( ! $+commands[grex] ))' lucid as"command" from"gh-r" id-as"grex"
zinit light pemistahl/grex

# procs - procs is a replacement for ps written in Rust
zinit ice if'(( ! $+commands[procs] ))' lucid as"command" from"gh-r" id-as"procs"
zinit light dalance/procs

# ripgrep - ripgrep recursively searches directories for a regex pattern
zinit ice if'(( ! $+commands[rg] ))' lucid as"command" from"gh-r" id-as"rg" \
  atclone"sudo mv */rg /usr/bin/" \
  atclone"mv */complete/_rg ." \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light burntSushi/ripgrep

# frp - A fast reverse proxy to help you expose a local server behind a NAT or firewall to the internet
zinit ice if'(( ! $+commands[frpc] ))' lucid as"command" from"gh-r" id-as"frp" \
  atclone"mv */frpc $BPFX/" \
  atclone"mv */frps $BPFX/" \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light fatedier/frp

# yazi - file browser
zinit ice if'(( ! $+commands[yazi] ))' lucid as"command" from"gh-r" id-as"yazi" \
  bpick"yazi-x86_64-unknown-linux-musl.zip" \
  atclone"mv yazi*/* ." \
  atclone"mv comp*/_ya ." \
  atclone"mv comp*/_yazi ." \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light sxyazi/yazi

# uv - python package manager
zinit ice if'(( ! $+commands[uv] ))' lucid as"command" from"gh-r" id-as"uv" \
  atclone"mv */* . && ./uv generate-shell-completion zsh > _uv" \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light astral-sh/uv

# fscan
zinit ice if'(( ! $+commands[fscan] ))' lucid as"command" from"gh-r" id-as"fscan" \
  bpick"fscan"
zinit light shadow1ng/fscan

# sttr
zinit ice if'(( ! $+commands[sttr] ))' lucid as"command" from"gh-r" id-as"sttr" \
  atclone"./sttr completion zsh > _sttr" \
  atpull"%atclone"
zinit light abhimanyu003/sttr

# dysk - A linux utility to get information on filesystems, like df but better
zinit ice if'(( ! $+commands[dysk] ))' lucid as"command" from"gh-r" id-as"dysk" \
  atclone"mv */completion/_dysk ." \
  atclone"mv */x86_64-unknown-linux-musl/dysk ." \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light Canop/dysk

# rainfrog - a database management tui
zinit ice if'[[ -n $DISPLAY ]]' lucid as"command" from"gh-r" id-as"rain" \
  atclone"mv rainfrog rain" \
  atpull"%atclone"
zinit light achristmascarl/rainfrog
