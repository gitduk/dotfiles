---
paths:
  - "**/*.sh"
  - "**/*.bash"
---

# Bash

- Style: 2-space indent; shebang `#!/usr/bin/env bash`
- JSON: build with `jq -n` + heredoc, not `\n` concatenation
- Under `set -e`, `grep -c` needs `|| true`
