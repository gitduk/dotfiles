## Core Principles

- **Root causes**: Find root causes. No temporary fixes. Senior developer standards.
- **Subagents**: Use liberally — offload research, exploration, and parallel analysis. One tack per subagent.
- **Meta-rule boundary** — never auto-modify Core Principles; propose to user first. Precedence: project `CLAUDE.md` > `~/.claude/rules/` > `~/.claude/CLAUDE.md`.

## Preferences

- Language: respond in Chinese (中文) unless the context is English-only code/docs
- Containers: prefer `podman` over `docker`
- JS/TS packages: prefer `bun` over `npm`
- Skills: install with `--copy` flag (e.g., `bun x skills add <package> -g -y --copy`)
- Bash scripts: 2-space indent; shebang `#!/usr/bin/env bash`
- Clipboard: use `wl-copy`
- HTTP client: prefer `xh` over `curl`
- **CRITICAL**: Always explain what you did after tool execution. Never output only `.` or stay silent.

@RTK.md
