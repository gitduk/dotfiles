---
name: dotfiles
description: Sync config files to the bare dotfiles repo (~/.dotfiles.git, worktree $HOME). Use when the user runs /dotfiles, asks to commit/push dotfiles, 固化配置, or sync ~/.claude changes into version control. Stages tracked modifications and untracked claude config files (rules/hooks/skills), blocks secrets, then commits and pushes.
user-invocable: true
---

# Dotfiles Repo

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

is_blocked() { case "\$1" in
  # secrets / credentials — never commit these
  *token*|*secret*|*password*|*credential*|*.pem|*.key|*.p12|*.env|.env*)
    return 0 ;;
  # auto-generated memory / project-local state
  .claude/projects/*)
    return 0 ;;
  *) return 1 ;;
esac; }

echo "=== Unpushed commits ==="
git log @{u}..HEAD --oneline 2>/dev/null \
  || git log origin/master..HEAD --oneline 2>/dev/null \
  || echo "(no upstream)"

echo ""
echo "=== Pre-staged cleanup (unstage blocked files) ==="
git diff --cached --name-only | while IFS= read -r rel; do
  if is_blocked "$rel"; then
    git restore --staged -- "$rel" && echo "  unstaged(blocked): $rel"
  fi
done

echo ""
echo "=== Modified/deleted tracked files → staging ==="
git status --porcelain | while IFS= read -r line; do
  xy="${line:0:2}"
  rel="${line:3}"
  [[ "$xy" == "??" ]] && continue
  [[ "$rel" == *" -> "* ]] && rel="${rel##* -> }"
  if is_blocked "$rel"; then
    echo "  blocked:  $rel"
  elif [[ -e "$HOME/$rel" ]]; then
    git add "$HOME/$rel" && echo "  staged:   $rel"
  else
    git rm --cached -- "$rel" 2>/dev/null && echo "  staged(rm): $rel" \
      || echo "  skip(already-rm): $rel"
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
  if is_blocked "$rel"; then
    echo "  blocked:  $rel"
  else
    git add "$f" && echo "  added:    $rel"
  fi
done

echo ""
echo "=== Staged diff ==="
git diff --cached --name-only
```

After the staged diff, verify no blocked file appears in the output.
If any blocked file is still staged, **STOP and report. Do NOT proceed.**

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
- If the current change set includes `~/.claude/skills/dotfiles/SKILL.md` itself,
  do not treat the current `/dotfiles` run as authoritative. Rerun in a fresh
  session after the file is saved.
- Functions live in `~/.zsh.d/functions/` and are autoloaded by zsh
