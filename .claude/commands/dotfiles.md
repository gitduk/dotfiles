## Dotfiles Repo

Managed as a **bare git repo**: `~/.dotfiles.git`, worktree `$HOME`.

Always use the full form (the `c` alias is zsh-only, not available in Bash tool):

```bash
git --work-tree=$HOME --git-dir=$HOME/.dotfiles.git <git-args>
```

---

## Step 1 — Detect & stage (single bash call)

Run this compound script **in one Bash tool call**:

```bash
export GIT_DIR="$HOME/.dotfiles.git"
export GIT_WORK_TREE="$HOME"

is_allowed() { case "$1" in
  .claude/settings.json|.claude/settings.local.json|\
  .claude/*.md|.claude/rules/*.md|.claude/hooks/*.sh|\
  .claude/commands/*.md|\
  .claude/skills/*/SKILL.md|.claude/skills/*/scripts/*)
    return 0 ;;
  .zsh.d/functions/*|.zsh.d/*.toml|.zsh.d/*.zsh)
    return 0 ;;
  .config/hypr/*|.config/kitty/*)
    return 0 ;;
  .tmux.conf|.syc.cfg|.gitignore|.gitconfig)
    return 0 ;;
  *) return 1 ;;
esac; }

echo "=== Unpushed commits ==="
git log @{u}..HEAD --oneline 2>/dev/null \
  || git log origin/master..HEAD --oneline 2>/dev/null \
  || echo "(no upstream)"

echo ""
echo "=== Modified tracked files → staging ==="
git status --porcelain | while IFS= read -r line; do
  rel="${line:3}"
  [[ "$rel" == *" -> "* ]] && rel="${rel##* -> }"
  if is_allowed "$rel"; then
    git add "$HOME/$rel" && echo "  staged:   $rel"
  else
    echo "  skipped:  $rel"
  fi
done

echo ""
echo "=== Untracked claude files → staging ==="
{ find ~/.claude/rules ~/.claude/hooks ~/.claude/commands -type f -print0 2>/dev/null
  find ~/.claude/skills -type f \( -name "SKILL.md" -o -path "*/scripts/*" \) -print0 2>/dev/null
} |
while IFS= read -r -d '' f; do
  rel="${f#$HOME/}"
  git ls-files --error-unmatch "$f" >/dev/null 2>&1 && continue
  if is_allowed "$rel"; then
    git add "$f" && echo "  added:    $rel"
  else
    echo "  skipped:  $rel"
  fi
done

echo ""
echo "=== Staged diff ==="
git diff --cached --name-only
```

If any unexpected file appears staged in the diff, **STOP and report the error. Do NOT proceed.**

---

## Step 2 — Propose commit

Draft commit message from the staged files in the output above:
`<type>[scope]: <imperative summary>` (max 72 chars)

**Mode check:**
- `/dotfiles` (no args): show staged diff + message, ask user to confirm before Step 3
- `/dotfiles push`: skip confirmation, go directly to Step 3

---

## Step 3 — Commit & push (single bash call)

```bash
export GIT_DIR="$HOME/.dotfiles.git" GIT_WORK_TREE="$HOME"
git commit -m "<message>" && git push && git status --short
```

Only report success if `status --short` output is empty.
If any paths remain, report them explicitly — do **not** claim the update is complete.

---

## Constraints

- Never commit tokens or credentials
- When creating/modifying files under `~/.claude/rules/` or `~/.claude/hooks/`,
  track them immediately with `git ... add $HOME/<path>`
- If the current change set includes `~/.claude/commands/dotfiles.md` itself,
  do not treat the current `/dotfiles` run as authoritative. Rerun in a fresh
  session after the file is saved.
- Functions live in `~/.zsh.d/functions/` and are autoloaded by zsh
