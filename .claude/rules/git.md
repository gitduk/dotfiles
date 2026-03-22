# Git Workflow

## Commits

- Commit atomically: one logical change per commit, all tests passing at each commit; batch all edits for a single feature/fix into one commit — do not commit after each individual file edit
- Before committing, check unpushed commits (`git log @{u}..HEAD` — if `@{u}` fails, use `git log origin/master..HEAD` or `git log origin/main..HEAD`) and squash any that belong to the same logical change as the new commit
- Message format: `<type>[optional scope]: <imperative summary>` (max 72 chars)
  - Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `style`, `build`, `ci`, `revert`
  - Example: `feat: add rate limiting to auth endpoints`
  - Example with scope: `chore(release): bump version to v1.2.0`
- Write commit body (separated by blank line) when the *why* isn't obvious from the diff

## Branches

- Naming: `feat/description`, `fix/description`, `chore/description`
- Rebase feature branches onto main before merging; keep history linear
- Never force-push to main; force-push to personal feature branches is fine

## Releases & Versioning

- Tag releases with semver `v1.2.3`; annotated tags with a changelog summary
- When code changes affect behavior, features, APIs, or bug fixes, bump the version:
  - `patch` = bug fix, `minor` = new feature, `major` = breaking change
  - Update `Cargo.toml` / `package.json` / `pyproject.toml`
- Always flag if a version bump is missing
