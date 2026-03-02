---
name: dotfile
description: 'Create conventional commits for ~/.dotfiles.git bare repo. Analyzes changes, stages files, and generates semantic commit messages.'
license: MIT
model: haiku
allowed-tools: Bash, Read
---

# Dotfiles Commit Skill

Manage commits for a bare git repo (`~/.dotfiles.git`, worktree `$HOME`) using Conventional Commits.

## Git Command

`c` is a user shell alias — **not available in Bash tool**. Always use the full form:

```bash
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git <git-args>
```

## Workflow

### 1. Check status and diff

```bash
# Always run these three in parallel to understand current state
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git status --porcelain
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git diff --staged
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git diff
```

If nothing is staged, ask the user what to stage, or stage all changed tracked files.

### 2. Review recent commits for style consistency

```bash
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git log --oneline -10
```

### 3. Stage files

```bash
# Stage specific files (preferred - be explicit)
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git add ~/.zshrc ~/.config/nvim/init.lua

# Stage all tracked changes
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git add -u
```

**NEVER** stage secrets: `.env`, credentials, private keys, tokens.

### 4. Commit

```bash
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

<optional body>
EOF
)"
```

### 5. Push (if requested)

**Argument parsing**: Check if the user passed `push` as an argument (e.g., `/dotfile push`).

If `push` argument is present:

```bash
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git push
```

If push fails due to no upstream, set it:

```bash
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git push -u origin $(git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git branch --show-current)
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
