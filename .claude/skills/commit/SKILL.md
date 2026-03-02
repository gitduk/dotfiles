---
name: commit
description: 'Create conventional commits for git repositories. Analyzes staged/unstaged changes, generates semantic commit messages following project conventions, and commits. This skill should be used when the user asks to "commit", "git commit", "save changes", "create a commit", or mentions committing code changes.'
model: haiku
allowed-tools: Bash, Read
---

# Git Commit Skill

Analyze changes in the current git repository and create well-structured conventional commits.

## Workflow

### 1. Gather repository state

Run these three commands in parallel to understand the current state:

```bash
git status --porcelain
git diff --staged
git diff
```

Also run in parallel:

```bash
git branch --show-current
git log --oneline -10
```

### 2. Determine what to commit

**If changes are staged** (`git diff --staged` has output):
- Proceed with staged changes only.

**If nothing is staged but unstaged changes exist**:
- Ask the user what to stage, or suggest staging all modified tracked files with `git add -u`.
- NEVER blindly run `git add -A` or `git add .` — these can stage secrets, build artifacts, or untracked files the user didn't intend to commit.

**If nothing changed**:
- Inform the user there are no changes to commit. Stop.

### 3. Analyze changes

Read the diff carefully to understand:
- **What** changed (files, functions, logic)
- **Why** it changed (bug fix, new feature, refactor, docs, etc.)
- **Scope** of change (single module, cross-cutting, config-only)

### 4. Detect project commit style

Examine the last 10 commits from `git log --oneline -10`:
- If the project uses Conventional Commits (`type(scope): description`), follow that format.
- If the project uses a different style (e.g., prefixed tags, plain descriptions), match it.
- If no clear pattern exists, default to Conventional Commits.

### 5. Stage files

```bash
# Prefer explicit file paths
git add path/to/file1 path/to/file2

# Or stage all tracked changes if user confirms
git add -u
```

**NEVER** stage files that likely contain secrets: `.env`, `*.pem`, `*.key`, credentials, tokens.

### 6. Generate commit message

Follow the detected project style. For Conventional Commits:

```
<type>(<scope>): <description>

<optional body>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`

**Rules**:
- Imperative mood, present tense: "add feature", not "added feature"
- Description under 72 characters
- One logical change per commit
- Body explains **why**, not what (the diff shows what)
- Always analyze the actual diff content to determine type and scope
- Include `Co-Authored-By` trailer

### 7. Commit

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <description>

<optional body>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

### 8. Post-commit

After a successful commit, run `git status` to confirm clean state.

### 9. Push (if requested)

**Argument parsing**: Check if the user passed `push` as an argument (e.g., `/commit push`).

If `push` argument is present:

```bash
# Push to the current branch's upstream
git push
```

If push fails due to no upstream, set it:

```bash
git push -u origin $(git branch --show-current)
```

If `push` argument is NOT present, do NOT push.

## Safety

- NEVER update git config
- NEVER run destructive commands (`--force`, `reset --hard`, `checkout .`, `clean -f`) unless explicitly requested
- NEVER skip hooks (`--no-verify`) unless explicitly requested
- If commit fails due to pre-commit hooks, fix the issue and create a NEW commit (never amend the previous one)
- NEVER commit files that may contain secrets
- If uncertain about what to stage, ask the user
