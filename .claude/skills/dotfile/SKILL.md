---
name: dotfile
description: 'Create conventional commits for ~/.dotfiles.git bare repo. Analyzes changes, stages files, and generates semantic commit messages.'
license: MIT
allowed-tools: Bash, Read
---

# Dotfiles Commit Skill

Manage commits for a bare git repo (`~/.dotfiles.git`, worktree `$HOME`) using Conventional Commits.

## Git Command

All git operations MUST use this prefix:

```bash
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git <command>
```

Abbreviated as `dotgit` below for clarity. Always expand to the full form when executing.

## Workflow

### 1. Check status and diff

```bash
# Always run these three in parallel to understand current state
dotgit status --porcelain
dotgit diff --staged
dotgit diff
```

If nothing is staged, ask the user what to stage, or stage all changed tracked files.

### 2. Review recent commits for style consistency

```bash
dotgit log --oneline -10
```

### 3. Stage files

```bash
# Stage specific files (preferred - be explicit)
dotgit add ~/.zshrc ~/.config/nvim/init.lua

# Stage all tracked changes
dotgit add -u
```

**NEVER** stage secrets: `.env`, credentials, private keys, tokens.

### 4. Commit

```bash
dotgit commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

<optional body>
EOF
)"
```

### 5. Push (if requested)

**Argument parsing**: Check if the user passed `push` as an argument (e.g., `/dotfile push`).

If `push` argument is present:

```bash
dotgit push
```

If push fails due to no upstream, set it:

```bash
dotgit push -u origin $(dotgit branch --show-current)
```

If `push` argument is NOT present, do NOT push.

## Commit Convention

Format: `<type>(<scope>): <description>`

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `chore`

**Common scopes for dotfiles**:

| Scope      | Files                                  |
| ---------- | -------------------------------------- |
| `zsh`      | .zshrc, .zsh.d/, .zprofile, .zshenv   |
| `vim`      | .vimrc, .config/nvim/                  |
| `tmux`     | .tmux.conf, .config/tmux/             |
| `git`      | .gitconfig, .gitignore_global         |
| `ssh`      | .ssh/config                            |
| `claude`   | .claude/                               |
| `alacritty`| .config/alacritty/                     |
| `kitty`    | .config/kitty/                         |
| `starship` | .config/starship.toml                  |
| `homebrew` | Brewfile, .Brewfile                    |
| `shell`    | cross-shell scripts, .local/bin/       |

Omit scope if changes span multiple unrelated areas.

**Rules**:
- Imperative mood, present tense: "add", not "added"
- Description < 72 chars
- One logical change per commit
- Analyze the actual diff content to determine type and scope, don't guess

## Safety

- NEVER update git config
- NEVER run destructive commands (--force, hard reset) without explicit request
- NEVER skip hooks unless user asks
- If commit fails due to hooks, fix and create a NEW commit (don't amend)
