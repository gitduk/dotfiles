## Consistency Check

When modifying or invoking rules/skills, check the involved files for:
- **Conflicts**: duplicate instructions, contradictory guidance, outdated references
- **Necessity**: rules too vague to be actionable, or redundant with Claude's default behavior
- **Scope**: rules missing `paths` frontmatter that should be conditionally loaded
- **Cross-ref**: skills and rules covering the same domain must agree
- **Dead refs**: rules referencing files, tools, or commands that no longer exist
- **Misplaced**: instructions that belong in a different file
If issues are found, flag them to the user with a proposed fix before proceeding.

## Self-Improvement Loop

- After a correction that reveals a **recurring pattern or non-obvious mistake**, append to the project's `CLAUDE.md` under `## Lessons`. Skip trivial one-offs. Deduplicate before writing.
- When observing **user habits or preferences** (workflow patterns, naming conventions, tool choices, communication style), append to the project's `CLAUDE.md` under `## Preferences`. Deduplicate before writing.
- If a lesson applies across all projects, propose promoting it to the relevant `~/.claude/rules/` file; after promotion, remove from the project file.
- If a preference applies across all projects, propose promoting it to `~/.claude/CLAUDE.md` under `## Preferences`; after promotion, remove from the project file.
- Remove entries that are outdated or proven incorrect; don't let stale knowledge accumulate.

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
- **Stop and Re-plan**: If execution goes sideways, stop immediately and re-plan — don't keep pushing a failing approach.

## Subagent Strategy

- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One tack per subagent for focused execution

## Demand Elegance (Balanced)

- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes - don't over-engineer
- After completing a feature or fix, scan for repeated patterns and extract shared helpers

## Compaction

When compacting, preserve: modified file list, active task state, key architectural decisions.

## Preferences

- Language: respond in Chinese (中文) unless the context is English-only code/docs
- Rules should be minimal — only write what Claude doesn't do by default; delete anything redundant with built-in behavior
- Language/framework-specific rules must use `paths` frontmatter for conditional loading
- Containers: prefer `podman` over `docker`
- JS/TS packages: prefer `bun` over `npm`
- Skills: install with `--copy` flag to copy files instead of symlinking (e.g., `bun x skills add <package> -g -y --copy`)

