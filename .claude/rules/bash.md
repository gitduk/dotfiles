---
paths:
  - "**/*.sh"
  - "**/*.bash"
---

- **[R57 jq-json]** JSON: build with `jq -n` + heredoc, not `\n` concatenation
- **[R58 grep-exit-guard]** Under `set -e`, `grep -c` needs `|| true` (no match exits 1 — same for `diff`, `cmp`, `pgrep`)
