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
- If a lesson or preference applies across all projects, propose promoting it to `~/.claude/rules/` (lessons to the relevant rule file, preferences to `rules/preferences.md`); after promotion, remove from the project file.
- Remove entries that are outdated or proven incorrect; don't let stale knowledge accumulate.

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.

## Subagent Strategy

- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One tack per subagent for focused execution

## Demand Elegance (Balanced)

- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes - don't over-engineer
