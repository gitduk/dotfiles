# MyLinux

Dotfiles managed with a bare git repo (`~/.dotfiles.git`).

## Setup

```bash
git clone --bare <repo-url> ~/.dotfiles.git
alias c='git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git'
c checkout
```

## What's Included

### Shell (Zsh)

`.zshrc` `.zshenv` `.zprofile` `.zlogin` `.zlogout` `.zsh.d/`

### Custom Functions

| Command | Description |
|---------|-------------|
| `a` | Tmux session attach/switch with fzf |
| `c` | Dotfiles git wrapper (`c add` / `c restore` / `c ...`) |
| `cp` | Pipe stdin to clipboard, or fallback to `/usr/bin/cp` |
| `mx` | Kill tmux sessions with fzf |
| `pf` | Pueue task manager with fzf |
| `pn` | Set/manage tmux pane names |
| `proxy` | Set/unset shell proxy environment variables |
| `pw` | Password/UUID generator |
| `scp` | Smart scp with auto directory creation |
| `senv` | Auto-detect and activate Python virtualenv |
| `syc` | Sync dotfiles to remote hosts via rsync |
| `uget` | Download latest release from GitHub repos |
| `v` | Smart editor launcher (auto sudo if needed) |
| `y` | Yazi file manager with cwd sync |

### Terminal & Desktop

| App | Config Path |
|-----|-------------|
| Alacritty | `.config/alacritty/` |
| Foot | `.config/foot/` |
| Ghostty | `.config/ghostty/` |
| Tmux | `.tmux.conf` |
| Starship | `.starship.toml` |
| Hyprland | `.config/hypr/` |
| Waybar | `.config/waybar/` |
| Rofi | `.config/rofi/` |

### Editors

| App | Config Path |
|-----|-------------|
| Helix | `.config/helix/` |
| Zed | `.config/zed/` |
| Zellij | `.config/zellij/` |
| IdeaVim | `.ideavimrc` |

### CLI Tools

| App | Config Path |
|-----|-------------|
| Atuin | `.config/atuin/` |
| Yazi | `.config/yazi/` |
| Git / Delta | `.gitconfig` |
| Navi | `.config/navi/` |
| Lsd | `.config/lsd/` |
| Direnv | `.config/direnv/` |
| Btop | `.config/btop/` |

### Services

| App | Config Path |
|-----|-------------|
| Mihomo | `.config/mihomo/` |
| Sing-box | `.config/sing-box/` |
| Pueue | `.config/pueue/` |
| MPD | `.config/mpd/` |
| SmartDNS | `.config/smartdns/` |
| Systemd (user) | `.config/systemd/user/` |
