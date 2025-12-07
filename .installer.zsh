#################
### Installer ###
#################

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

# sing-box
zinit ice if'(( ! $+commands[sing-box] ))' lucid as"program" from"gh-r" id-as"sing-box" \
  bpick"sing-box-*-linux-amd64.tar.gz" \
  atclone"mv */sing-box $BPFX/sing-box" \
  atclone"sudo setcap cap_net_admin=+ep $BPFX/sing-box" \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light SagerNet/sing-box

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

# fx - Command-line tool and terminal JSON viewer
zinit ice if'(( ! $+commands[fx] ))' lucid as"command" from"gh-r" id-as"fx" \
  atclone"mv fx* fx"
zinit light antonmedv/fx

# gh
zinit ice if'(( ! $+commands[gh] ))' lucid as"command" from"gh-r" id-as"gh" \
  atclone"sudo mv */bin/gh /usr/bin" \
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
  atclone"sudo mv */rg /usr/bin" \
  atclone"mv */complete/_rg ." \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light burntSushi/ripgrep

# yazi - file browser
zinit ice if'(( ! $+commands[yazi] ))' lucid as"command" from"gh-r" id-as"yazi" \
  bpick"yazi-x86_64-unknown-linux-musl.zip" \
  atclone"mv yazi*/* ." \
  atclone"mv comp*/_ya ." \
  atclone"mv comp*/_yazi ." \
  atclone"rm -rf */" \
  atpull"%atclone"
zinit light sxyazi/yazi

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

# codex
zinit ice if'(( ! $+commands[codex] ))' lucid as"program" id-as"codex" \
  atclone"bun install -g @openai/codex" \
  atpull"%atclone"
zinit light zdharma-continuum/null

# claude-code
zinit ice if'(( ! $+commands[claude] ))' lucid as"program" id-as"claude" \
  atclone"bun install -g @anthropic-ai/claude-code" \
  atpull"%atclone"
zinit light zdharma-continuum/null

# ccstatusline
zinit ice if'(( ! $+commands[ccstatusline] ))' lucid as"program" id-as"ccstatusline" \
  atclone"bun install -g ccstatusline@latest" \
  atpull"%atclone"
zinit light zdharma-continuum/null

# gonzo - The Go based TUI for log analysis
zinit ice if'(( ! $+commands[gonzo] ))' lucid as"program" id-as"gonzo" \
  atclone"/usr/local/go/bin/go install github.com/control-theory/gonzo/cmd/gonzo@latest" \
  atpull"%atclone"
zinit light zdharma-continuum/null

# xh
zinit ice if'(( ! $+commands[xh] ))' lucid as"program" id-as"xh" \
  atclone"curl -sfL https://raw.githubusercontent.com/ducaale/xh/master/install.sh | sh" \
  atpull"%atclone"
zinit light zdharma-continuum/null

# tw - view and query tabular data files, such as CSV, TSV, and parquet
zinit ice if'(( ! $+commands[tw] ))' lucid as"program" from"gh" id-as"tw" \
  atclone"uget shshemi/tabiew tabiew-x86_64-unknown-linux-gnu.deb" \
  atclone"sudo dpkg -i /tmp/tabiew.deb" \
  atpull"%atclone"
zinit light zdharma-continuum/null

# nping
zinit ice if'(( ! $+commands[nping] ))' lucid as"program" from"gh-r" id-as"nping" \
  bpick"nping-x86_64-unknown-linux-gnu.tar.gz"
zinit light hanshuaikang/Nping

# mise - dev tools, env vars, task runner
zinit ice if'(( ! $+commands[mise] ))' lucid as"program" id-as"mise" \
  atclone"curl https://mise.run | sh" \
  atpull"%atclone" \
  atload'eval "$(mise activate zsh)"'
zinit light zdharma-continuum/null

# oryx - sniffing network traffic using eBPF on Linux
zinit ice if'(( ! $+commands[oryx] ))' lucid as"program" from"gh-r" id-as"oryx" \
  bpick"oryx-x86_64-unknown-linux-musl" \
  atclone"sudo mv oryx-x86_64-unknown-linux-musl /usr/bin/oryx" \
  atpull"%atclone"
zinit light pythops/oryx

# oha - HTTP load generator, inspired by rakyll/hey with tui animation
zinit ice if'(( ! $+commands[oha] ))' lucid as"program" from"gh-r" id-as"oha" \
  bpick"oha-linux-amd64" \
  atclone"mv oha-linux-amd64 oha" \
  atpull"%atclone"
zinit light hatoo/oha

# heynote - A dedicated scratchpad for power users
zinit ice if'(( ! $+commands[heynote] ))' lucid as"program" from"gh-r" id-as"heynote" \
  bpick"Heynote_*_x86_64.AppImage" \
  atclone"mv heynote_*_x86_64.appimage $BPFX/heynote" \
  atpull"%atclone"
zinit light heyman/heynote

# yaak - The most intuitive desktop API client
zinit ice if'(( ! $+commands[yaak] ))' lucid as"program" from"gh" id-as"yaak" \
  atclone"uget mountain-loop/yaak deb" \
  atclone"sudo dpkg -i /tmp/yaak.deb" \
  atpull"%atclone"
zinit light zdharma-continuum/null

# xan - The CSV magician
zinit ice if'(( ! $+commands[xan] ))' lucid as"program" from"gh-r" id-as"xan"
zinit light medialab/xan

