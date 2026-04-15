# Version Bump Before Commit

When a project policy requires version bumps on commit, treat that as part of the commit workflow rather than an optional release step.

**Why:** Repeatedly forgetting version bumps creates avoidable release drift and forces manual cleanup later.

**How to apply:** Before `git commit`, check the current project's instructions for versioning requirements. If the project says to bump version files on every commit, do it in the same logical change and include the version files in the commit.