# Dotfiles Management

Dotfiles are managed with a **bare git repo** at `~/.dotfiles.git`, worktree is `$HOME`.

## Commands

The user's `c` function is a zsh autoloaded shortcut — **not available in Bash tool**. Always use the full form:

```bash
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git <git-args>
```

When the user says `c add`, `c restore`, etc., they mean this command with the corresponding git args.

## Important

- **Never use `git add -A` or `git clean`** — worktree is `$HOME`, this would be destructive
- Only operate on tracked files; untracked files in `$HOME` are intentionally ignored
- Functions live in `~/.zsh.d/functions/` and are autoloaded by zsh
- Commit dotfiles changes with the `/git-commit` skill (works with bare repos)
- Config files at `~/.config/<app>/`; sensitive files (tokens, credentials) must not be tracked
- When creating or modifying files under `~/.claude/rules/`, track them with `git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git add ~/.claude/rules/<file>`
- Flag any rule files under `~/.claude/rules/` not tracked by dotfiles — they may have been created by plugins, skills, or the user
