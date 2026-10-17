---
description: Sync $HOME config to the bare dotfiles repo via the `c` command — stage, scan for secrets (name + content), draft message, confirm, commit & push
argument-hint: "[push]"
---
# Dotfiles Repo

Bare repo `~/.dotfiles.git`, worktree `$HOME`. All git ops go through `c` (`~/.local/bin/c`, bash-compatible):
- `c add` — stage all changes incl. untracked pi config
- `c status` — show state
- `c commit`/`c push` — pass-through
- `c restore` — unstages; if unstaged edits exist it restores them from the worktree (discards them)

Mode: **${1:-ask}**

---

## Step 1 — Inspect, then stage precisely

Never run bare `c add` — it stages the whole `$HOME` worktree (1.6M untracked files: caches, containers, project dirs, credentials). Inspect first, then stage only the real dotfile paths:

```bash
cd "$HOME" && c status --porcelain -uall
```

From the porcelain output, identify the genuine dotfile changes (`.pi/agent/...`, `.zsh.d/...`, `.tmux.conf`, configs you manage) and stage only those paths explicitly — never the whole tree:

```bash
c add -A -- .pi/agent/... .zsh.d/...
```

Then run the mandatory secret gate — **on any match, STOP and report. Do NOT commit.**

Filename sweep (credential-shaped paths):
```bash
c diff --cached --name-only | grep -iE 'token|secret|password|credential|\.env|\.pem|\.key|\.p12|\.p8'
```

Content sweep (real secret shapes inside the staged diff — catches tokens hidden in ordinary filenames):
```bash
c diff --cached | grep -aiE 'BEGIN [A-Z ]*PRIVATE KEY|ghp_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[0-9A-Za-z-]{10,}'
```

Flag new modules — if any untracked extension or prompt is being added, call it out explicitly so the user knows it's in this commit. `--porcelain -uall` avoids ANSI color and untracked-directory collapsing (both of which hid files before):
```bash
c status --porcelain -uall | grep -E '^\?\? .pi/agent/(extensions|prompts)/'
```
After `c add`, if the porcelain above still lists `??` entries (a file `c add` missed), `git add` them explicitly before continuing:
```bash
git --git-dir="$HOME/.dotfiles.git" --work-tree="$HOME" add <missed-path>
```

---

## Step 2 — Propose commit

Message: `<type>[scope]: <imperative summary>` (≤72 chars)
- `ask` / no argument: show staged list + proposed message, wait for confirmation
- `push`: skip confirmation, go to Step 3

---

## Step 3 — Commit & push

```bash
cd "$HOME" && c commit -m "<message>" && c push
```

Only report success if `c status --short` prints nothing; otherwise list the remaining paths explicitly — do not claim completion.

---

## Constraints
- The Step 1 gate is mandatory — never commit tokens/credentials
- If the change set includes `.pi/agent/prompts/dotfiles.md` itself, don't treat this run as authoritative; rerun in a fresh session

