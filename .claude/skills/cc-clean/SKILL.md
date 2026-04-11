---
name: cc-clean
description: Clean up accumulated junk in ~/.claude/ — failed telemetry queue, stale auto-named plans, old file-history snapshots. Use this skill whenever the user mentions their .claude directory getting large, clearing disk space in Claude Code, 清理 Claude Code 垃圾, 瘦身, reclaiming space, or asks anything like "why is ~/.claude so big". Also trigger if the user says they want to clean stale plans, telemetry, or edit history even without naming .claude explicitly.
---

# cc-clean

This skill runs `scripts/clean.sh` — a safe, reversible-by-dry-run cleanup of three well-understood junk categories in `~/.claude/`. It exists because Claude Code and its plugins accumulate state without TTL, and the user wants a portable, cross-PC way to reclaim space.

## What it cleans

Three targets, chosen because each has **clearly bounded value** (none of them are conversation memory or anything a future-you would want to resurrect):

1. **`telemetry/1p_failed_events.*.json`** — Claude Code's 1st-party telemetry retry queue. When upload fails, events get spooled to disk. There is no TTL and no successful-retry loop in practice, so they accumulate indefinitely. Always safe to delete the entire queue: worst case, Anthropic loses a few failed-upload records they already gave up on.

2. **`plans/<adj>-<verb>-<noun>.md`** older than `--days` (default 14) — The superpowers `writing-plans` skill creates plan documents with random three-word names (e.g., `glowing-honking-cray.md`). These are intermediate process artifacts, not deliverables. Anything with an explicit name (`README.md`, `ANALYSIS_COMPLETE.md`, `Something_Report.md`, anything capitalized or snake_case) is preserved — those are deliberate outputs.

3. **`file-history/<uuid>/` directories** older than `--days` (default 14) — Pre-edit snapshots that back the Edit tool's undo capability. After two weeks there's essentially zero chance anyone will undo an edit, so these become dead weight.

## What it never touches

These are load-bearing and must not be touched by this skill:

- **`projects/`** — Conversation transcripts, session state, and file snapshots. `/resume` depends on them. Deleting a session here erases a conversation permanently.
- **Plans with explicit names** — Treated as deliverables.
- **Recent files** (`mtime` within `--days`) — Still potentially in use.
- **`hooks/`, `rules/`, `skills/`, `agents/`, `CLAUDE.md`, settings** — Configuration, not junk.

## How to run

**Step 1: Dry-run first.** The script defaults to dry-run mode. Run with no args and it prints exactly what *would* be deleted, grouped by category, with size totals. Nothing is touched.

```bash
~/.claude/skills/cc-clean/scripts/clean.sh
```

**Step 2: Review the output with the user.** If there's anything unexpected in the list — especially in `plans/` — stop and ask. Do not execute just because the user said "go ahead" in the abstract; the actual list might contain something they want to keep.

**Step 3: Execute.** Once the user confirms the list looks right:

```bash
~/.claude/skills/cc-clean/scripts/clean.sh --execute
```

**Options:**

- `--execute` / `-y` — Actually delete. Without this, dry-run only.
- `--days N` — Age threshold for `plans/` and `file-history/` (default 14). Does not affect telemetry (always fully cleared).
- `--help` / `-h` — Print usage.

## Portability

The script uses `${CLAUDE_DIR:-$HOME/.claude}` so it works on any machine where this skill has been synced via dotfiles. No hard-coded paths. Do not edit the script to hard-code `/home/$USER` — that defeats the cross-PC design.

## When running this skill

1. Read `scripts/clean.sh` if you need to understand what it does before running — but prefer running dry-run first, which is self-documenting
2. Run dry-run, show the output to the user verbatim (or summarized if very long)
3. Get explicit confirmation before running with `--execute`
4. Report what was reclaimed (the script prints before/after sizes)

## Why no cron / systemd timer

The user explicitly wants this cleanup to be **portable across machines** — they use Claude Code on multiple PCs and don't want to configure a cron job on each one. A skill synced via dotfiles ships the cleanup logic everywhere automatically. The tradeoff is that cleanup only happens when invoked; that's acceptable because this skill is cheap to trigger and the user prefers deliberate action over background automation for anything involving `rm`.
