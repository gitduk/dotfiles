---
paths:
  - "**/*.sh"
  - "**/*.bash"
---

- **[jq-json]** JSON: build with `jq -n` + heredoc, not `\n` concatenation
- **[grep-exit-guard]** Under `set -e`, `grep -c` needs `|| true` (no match exits 1 — same for `diff`, `cmp`, `pgrep`)
