---
paths:
  - "**/*.sh"
  - "**/*.bash"
---

- **[BASH-1]** JSON: build with `jq -n` + heredoc, not `\n` concatenation
- **[BASH-2]** Under `set -e`, `grep -c` needs `|| true` (no match exits 1 — same for `diff`, `cmp`, `pgrep`)
