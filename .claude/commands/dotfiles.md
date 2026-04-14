## Dotfiles Repo

Managed as a **bare git repo**: `~/.dotfiles.git`, worktree `$HOME`.

Always use the full form (the `c` alias is zsh-only, not available in Bash tool):

```bash
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git <git-args>
```

---

## Step 0 — One-time cleanup (run only if runtime files are tracked)

**Check if runtime files are being tracked:**

```bash
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git ls-files | grep -E '\
.claude/backups/|\
.claude/history\.jsonl|\
.claude/projects/.*\.jsonl|\
.claude/cache/|\
.claude/channels/|\
.claude/debug/|\
.claude/\.claude/|\
.claude/\.credentials\.json|\
.config/google-chrome/'
```

If any matches appear, these files should be untracked:

```bash
# Remove from git tracking (keep local files)
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git rm --cached -r \
  .claude/backups/ \
  .claude/history.jsonl \
  .claude/projects/ \
  .claude/cache/ \
  .claude/channels/ \
  .claude/debug/ \
  .claude/.claude/ \
  .claude/.credentials.json \
  .config/google-chrome/ \
  2>/dev/null || true

# Add to .gitignore if not already present
cat >> ~/.gitignore <<'EOF'
# Runtime state - never commit
.claude/backups/
.claude/history.jsonl
.claude/projects/
.claude/cache/
.claude/channels/
.claude/debug/
.claude/.claude/
.claude/.credentials.json
.config/google-chrome/
.config/*/Cache/
.config/*/GPUCache/
EOF

# Stage .gitignore and commit the cleanup
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git add ~/.gitignore
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git commit -m "chore: untrack runtime files and update .gitignore"
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git push
```

**Only run this step once.** After cleanup, proceed to Step 1.

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

**CRITICAL: NEVER use `git add -u` or `git add -A`** — these will stage runtime
files that are already tracked but shouldn't be committed.

### Staging Protocol

**1. Filter the modified files from Step 1 against the allowlist:**

Runtime files that must NEVER be staged (even if tracked):
- `.claude/backups/`
- `.claude/history.jsonl`
- `.claude/projects/`
- `.claude/cache/`
- `.claude/channels/`
- `.claude/debug/`
- `.claude/.claude/`
- `.claude/.credentials.json`
- `.config/google-chrome/`
- `.config/*/Cache/`
- `.config/*/GPUCache/`

**2. Stage only allowlisted files explicitly:**

```bash
# For each modified file from Step 1, check if it matches allowlist patterns:
# - .claude/CLAUDE.md, .claude/RTK.md, .claude/CX.md, .claude/settings.json
# - .claude/rules/*.md
# - .claude/hooks/*.sh (but NOT .claude/hooks/.*.sha256)
# - .claude/commands/*.md
# - .claude/skills/*/SKILL.md, .claude/skills/*/scripts/*
# - .zsh.d/functions/*, .zsh.d/*.toml, .zsh.d/*.zsh
# - .config/hypr/, .config/kitty/, .config/nvim/ (but NOT Cache subdirs)
# - .tmux.conf, .syc.cfg, .gitignore, .gitconfig

# Stage each allowlisted file individually:
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git add $HOME/<exact-path>
```

**3. Verify staged files before drafting commit message:**

```bash
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git diff --cached --name-only
```

If ANY runtime file appears in the staged list, **STOP and report the error**.
Do NOT proceed to commit.

**4. Draft commit message** following the project convention:
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
