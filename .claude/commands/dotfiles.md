## Dotfiles Repo

Managed as a **bare git repo**: `~/.dotfiles.git`, worktree `$HOME`.

Always use the full form (the `c` alias is zsh-only, not available in Bash tool):

```bash
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git <git-args>
```

---

## Step 1 — Show status

Run these in parallel:

```bash
# Modified tracked files
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git status --short

# Unpushed commits
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git log @{u}..HEAD 2>/dev/null \
  || git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git log origin/master..HEAD 2>/dev/null \
  || echo "(no upstream configured)"
```

Then check for untracked rule/hook/command files:

```bash
find ~/.claude/rules ~/.claude/hooks ~/.claude/commands -type f -print0 2>/dev/null |
while IFS= read -r -d '' f; do
  git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git ls-files --error-unmatch "$f" \
    >/dev/null 2>&1 || echo "untracked: $f"
done
```

Report:
1. **Modified tracked files** (staged / unstaged)
2. **Untracked rule, hook & command files** (flag each — may need `add`)
3. **Unpushed commits**

---

## Step 2 — Propose a commit (if changes exist)

**NEVER use `git add -A`** — worktree is `$HOME`; scanning all of it hits
container storage dirs and causes Permission denied errors.

Stage only what was shown in Step 1. Always use **absolute paths**
(path args resolve relative to CWD, not `$HOME`):

```bash
# Update all tracked files in known dirs (bulk):
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git add -u -- $HOME/.claude/ $HOME/.config/ $HOME/.zsh.d/

# Add a new/untracked file that should be tracked:
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git add $HOME/<exact-path>
```

Draft a commit message following the project convention:
`<type>[scope]: <imperative summary>` (max 72 chars)

**Mode check** — read the args the user passed when invoking this skill:
- `/dotfiles` (no args): **preview only** — show the staged diff and proposed commit message, then ask the user to confirm before proceeding to Step 3.
- `/dotfiles push`: **auto-commit** — skip confirmation and go directly to Step 3.

---

## Step 3 — Commit & push

```bash
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git commit -m "<message>"
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git push
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git status --short
```

Only report success if the final `status --short` output is empty.
If any paths remain, explicitly report them and stop — do **not** claim the dotfiles update is complete.

---

## Constraints

- Config files live at `~/.config/<app>/`; never commit tokens or credentials
- When creating/modifying files under `~/.claude/rules/` or `~/.claude/hooks/`,
  track them immediately with `git ... add $HOME/<path>`
- If the current change set includes `~/.claude/commands/dotfiles.md` itself, do not treat the current `/dotfiles` run as authoritative validation of the updated command text. Validate with direct `git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git ...` commands, or rerun `/dotfiles` in a fresh session after the file is saved.
- Functions live in `~/.zsh.d/functions/` and are autoloaded by zsh
