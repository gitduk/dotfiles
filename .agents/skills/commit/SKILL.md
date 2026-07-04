---
name: commit
description: Use when ready to commit changes to git repository
model: sonnet
---

# Commit

## Overview

Structured git commit workflow that enforces project-specific requirements (version bumps, quality checks) and prevents common mistakes (missing files, wrong scope, duplicate commits).

## When to Use

- User says "commit", "提交", or equivalent
- After completing a logical unit of work
- Before switching branches or creating PR

**When NOT to use:**
- Mid-implementation (incomplete feature)
- Tests failing
- Quality checks not passing

## Commit Granularity

- One logical change per commit; all tests passing at each commit
- Batch all edits for a single feature/fix into one commit — never commit after each individual file edit
- Rust: `cargo clippy` cycles within a single logical change are **preparation steps**, not separate commits (formatting is handled automatically by the git pre-commit hook). Commit only after the full logical change is complete and verified.

## Workflow

```dot
digraph commit_flow {
    "User requests commit" [shape=doublecircle];
    "Run git status/diff/log in parallel" [shape=box];
    "Check unpushed commits" [shape=box];
    "Should squash?" [shape=diamond];
    "Squash first" [shape=box];
    "Check project requirements" [shape=box];
    "Missing version bump?" [shape=diamond];
    "Bump version + update lock" [shape=box];
    "Has CLAUDE.md?" [shape=diamond];
    "Check CLAUDE.md consistency" [shape=box];
    "Inconsistent?" [shape=diamond];
    "Draft CLAUDE.md updates" [shape=box];
    "User confirms update?" [shape=diamond];
    "Update CLAUDE.md + stage" [shape=box];
    "Analyze change type" [shape=box];
    "Draft commit message" [shape=box];
    "Run quality checks" [shape=box];
    "Stage files + commit" [shape=box];
    "Show commit report" [shape=box];
    "Done" [shape=doublecircle];

    "User requests commit" -> "Run git status/diff/log in parallel";
    "Run git status/diff/log in parallel" -> "Check unpushed commits";
    "Check unpushed commits" -> "Should squash?";
    "Should squash?" -> "Squash first" [label="yes"];
    "Should squash?" -> "Check project requirements" [label="no"];
    "Squash first" -> "Check project requirements";
    "Check project requirements" -> "Missing version bump?";
    "Missing version bump?" -> "Bump version + update lock" [label="yes"];
    "Missing version bump?" -> "Has CLAUDE.md?" [label="no"];
    "Bump version + update lock" -> "Has CLAUDE.md?";
    "Has CLAUDE.md?" -> "Check CLAUDE.md consistency" [label="yes"];
    "Has CLAUDE.md?" -> "Analyze change type" [label="no"];
    "Check CLAUDE.md consistency" -> "Inconsistent?";
    "Inconsistent?" -> "Draft CLAUDE.md updates" [label="yes"];
    "Inconsistent?" -> "Analyze change type" [label="no"];
    "Draft CLAUDE.md updates" -> "User confirms update?";
    "User confirms update?" -> "Update CLAUDE.md + stage" [label="yes"];
    "User confirms update?" -> "Analyze change type" [label="no, manual"];
    "Update CLAUDE.md + stage" -> "Analyze change type";
    "Analyze change type" -> "Draft commit message";
    "Draft commit message" -> "Run quality checks";
    "Run quality checks" -> "Stage files + commit";
    "Stage files + commit" -> "Show commit report";
    "Show commit report" -> "Done";
}
```

## Step-by-Step

### 1. Gather Context (parallel)

```bash
git status
git diff
git log --oneline -10
```

### 2. Check Unpushed Commits

```bash
git log @{u}..HEAD || git log origin/master..HEAD || git log origin/main..HEAD
```

If unpushed commits exist and belong to same logical change → squash before new commit.

### 3. Check Project Requirements

**Common patterns:**
- Version bump required? (check `CLAUDE.md`, `Cargo.toml`, `package.json`, `pyproject.toml`)
- Lock file must be included? (`Cargo.lock`, `package-lock.json`, `uv.lock`)
- Quality checks required? (auto-detect based on project type)

**Quality checks:** run the per-language QA chain defined in `~/.claude/rules/languages.md` — that file is the canonical definition (always loaded in context); do not restate commands here. At commit time use the applying variants (`cargo fmt`, `uv run ruff format .`), not `--check`. Mixed projects: run chains for all detected languages.

### 3.5. CLAUDE.md Consistency Check

**If project has CLAUDE.md at repo root:**

1. Read current CLAUDE.md content
2. Analyze staged changes (from `git diff --cached`):
   - Look for public interface changes: new/removed/modified functions, classes, types, exports
   - Look for behavior changes: new features, removed features, changed logic
   - Look for architecture changes: new dependencies, service integrations, data flow changes
3. Compare CLAUDE.md description against staged changes:
   - Does CLAUDE.md describe the interfaces/features being added/removed?
   - Does CLAUDE.md reflect the current architecture after these changes?
   - Are there new public APIs that CLAUDE.md doesn't mention?
   - Are there removed features that CLAUDE.md still describes?

**If inconsistency detected:**
- Show specific examples of what's inconsistent (e.g., "CLAUDE.md says vector model loads locally, but code now calls external service")
- Draft suggested CLAUDE.md updates to match the code changes
- Ask user: "CLAUDE.md 需要更新。我已经起草了建议的修改，要我直接更新吗？"
- If user confirms: update CLAUDE.md, stage it, continue commit
- If user declines: explain they should update CLAUDE.md manually before committing

**If consistent or no CLAUDE.md exists:**
- Continue to next step silently

**Bypass:**
- If commit message contains `[skip-claudemd]` tag, skip this check entirely

### 4. Analyze Change Type

Map changes to commit type:
- `feat`: new feature
- `fix`: bug fix
- `refactor`: code restructure, no behavior change
- `perf`: performance improvement
- `test`: test additions/changes
- `docs`: documentation only
- `chore`: maintenance (deps, config, release)
- `style`: formatting, whitespace
- `build`: build system changes
- `ci`: CI/CD changes

### 5. Draft Commit Message

Format: `<type>[optional scope]: <imperative summary>` (max 72 chars)

**Good:**
- `feat: add rate limiting to auth endpoints`
- `fix(parser): handle empty input without panic`
- `chore(release): bump version to v1.2.0`

**Bad:**
- `updated stuff` (vague)
- `Fixed bug` (not imperative, no context)
- `feat: added new feature for handling user authentication with JWT tokens and refresh token rotation` (too long)

Add body (separated by blank line) when WHY isn't obvious from diff.

### 6. Execute Commit

**Run the verification QA chain — `cargo clippy` / `cargo test` (commands per `rules/languages.md`) — BEFORE any `git add`. Do NOT run `cargo fmt` / `ruff format` manually: the global git pre-commit hook formats staged files and re-stages them automatically at commit time.**

```bash
# QA commands: see ~/.claude/rules/languages.md (canonical, always in context).
# Separate commands are fine — the QA gate accumulates each passing check.
<per-language QA chain>

# ONLY after all checks pass, stage and commit
git add <specific files>
git commit -m "$(cat <<'EOF'
<commit message>

<Co-Authored-By trailer — use the one the current harness specifies; never hardcode a model name here>
EOF
)"
```

**Critical ordering rule**: run verification (`cargo clippy`, plus `cargo test` when a suite exists — the qa-gate requires these, no longer fmt) BEFORE `git add`. These compile and rewrite `Cargo.lock`, so staging before they finish desyncs the index. **After QA passes**, run `git diff --name-only` to check which lock files changed (`Cargo.lock`, `uv.lock`, etc.) and include every changed lock file in `git add` — failing to do so leaves a dirty working tree after commit. **Formatting is not your job at commit time**: the global git pre-commit hook (`~/.config/git/hooks/pre-commit`) runs `cargo fmt` / `ruff format` on the staged files and re-stages them during `git commit`. So the flow is: clippy/test → check for changed lock files → `git add <files + lock files>` → `git commit` (hook formats). Never run `cargo fmt` before `git add` — that reintroduces the exact desync this hook exists to remove.

**Detection logic:**
- Check for `Cargo.toml` → Rust
- Check for `pyproject.toml` → Python
- Check for `package.json` → JS/TS
- Multiple files present → run all applicable checks

### 7. Show Commit Report

After successful commit, display a structured report:

```
✓ 提交完成

提交信息：
  <type>(<scope>): <summary>

已提交文件：
  - path/to/file1.rs
  - path/to/file2.rs
  - Cargo.toml (v0.1.5 → v0.1.6)
  - Cargo.lock

质量检查：
  ✓ cargo fmt passed
  ✓ cargo clippy passed

提交哈希：<short-hash>
```

**Report must include:**
- Commit message (full, including body if present)
- List of committed files with any special notes (version bumps, lock files)
- Quality check results
- Commit hash for reference

## Branches

- Naming: `feat/description`, `fix/description`, `chore/description`
- Rebase feature branches onto main before merging; keep history linear
- Never force-push to main; force-push to personal feature branches is fine

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Commit without checking unpushed commits | Always check `git log @{u}..HEAD` first |
| Forget version bump | Check project `CLAUDE.md` for requirements |
| Commit unrelated changes | Explicitly list files to stage, not `git add .` |
| QA updated lock file but wasn't staged | After clippy/test, run `git diff --name-only` and include any changed lock files in `git add` |
| Skip quality checks | Run project-specific checks before commit |
| Vague commit message | Use conventional commits format with clear summary |
| Commit with failing tests | Verify tests pass before committing |
| Missing commit report | Always show structured report after commit |
| CLAUDE.md out of sync with code | Check CLAUDE.md consistency before commit, update if needed |

## Red Flags

- "I'll commit everything in working tree" → Check if all changes belong together
- "Skip version bump this time" → Project requirements are not optional
- "Commit message: WIP" → Not a logical unit, don't commit yet
- "I'll run tests after committing" → Tests must pass before commit
- "Let me ask user to confirm first" → Commit skill executes directly, no confirmation needed
- "I'll run quality checks now" (after version bump check) → CLAUDE.md consistency check (Step 3.5) comes BEFORE quality checks; do not skip it when CLAUDE.md exists
