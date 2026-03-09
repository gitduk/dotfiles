---
description: Release workflow — version bump, changelog, git tag, push to trigger CI/CD
---

# Ship Release

Systematic release workflow: quality checks, version bump, changelog, git tag, push.

## When to Use

Invoke `/ship` when ready to cut a release after all features/fixes are merged and tests pass.

## Pre-Release Checklist

Before shipping, verify:

```bash
# 1. Quality gates pass (adapt to project language)
# Rust:   cargo fmt --check && cargo clippy && cargo test
# Python: ruff check . && pytest
# JS/TS:  bun run lint && bun test

# 2. Git is clean
git status  # "nothing to commit, working tree clean"
```

## Workflow

### Step 1 — Determine Version Bump

Semantic versioning (MAJOR.MINOR.PATCH):
- **MAJOR**: Breaking changes to public API or CLI
- **MINOR**: New features, new commands, new behavior
- **PATCH**: Bug fixes, performance improvements, refactors

### Step 2 — Update Version

Files to update (pick what applies):
- `Cargo.toml` → `version = "X.Y.Z"`
- `package.json` → `"version": "X.Y.Z"`
- `pyproject.toml` → `version = "X.Y.Z"`
- `CHANGELOG.md` → add new section at top

**CHANGELOG.md template**:
```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- ...

### Fixed
- ...

### Changed
- ...
```

### Step 3 — Build and Verify

```bash
# Clean build and run full quality checks
# Verify the binary/package reports the new version
```

### Step 4 — Commit Version Bump

```bash
git add Cargo.toml CHANGELOG.md  # (or package.json, pyproject.toml, etc.)
git commit -m "chore(release): bump version to vX.Y.Z"
```

### Step 5 — Create Annotated Tag

```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z

Added:
- ...

Fixed:
- ..."
```

### Step 6 — Push to Remote

```bash
git push origin main
git push origin vX.Y.Z
```

## Post-Release Verification

```bash
# Check CI/CD
gh run list --limit 1
gh run watch

# Verify release created
gh release view vX.Y.Z
```

## Rollback Plan

| Situation | Action |
|-----------|--------|
| Minor bug | PATCH release (preferred) |
| crates.io/npm only | `cargo yank` / `npm deprecate` |
| Critical — last resort | Delete tag, revert commit, force-push |

## Security Before Release

- [ ] No secrets in code (API keys, tokens, credentials)
- [ ] Dependencies scanned for known CVEs (`cargo audit` / `pip-audit` / `bun audit`)
- [ ] No `.env` files committed
