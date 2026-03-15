## Core Principles

- **Simplicity**: Make every change as simple as possible. Only touch what's necessary.
- **Root causes**: Find root causes. No temporary fixes. Senior developer standards.
- **Stop and re-plan**: If execution goes sideways, stop immediately and re-plan — don't keep pushing a failing approach.

## Execution

- Use subagents liberally — offload research, exploration, and parallel analysis to keep main context clean. One tack per subagent.
- For non-trivial changes, pause and ask "is there a more elegant way?" Skip this for simple, obvious fixes.
- After completing a feature or fix, scan for repeated patterns and extract shared helpers.
- When compacting, preserve: modified file list, active task state, key architectural decisions, pending CLAUDE.md updates.

## Self-Improvement

### Maintenance

- **Update over append** — if an existing entry covers the same topic, update it in place; don't append a duplicate.
- **Size control** — keep each entry to one line; if details are needed, create a separate file and link from CLAUDE.md. Aim for the whole file to stay under 100 lines.
- **Cleanup** — remove entries that are outdated or proven incorrect; don't let stale knowledge accumulate.
- **Promote eagerly** — when writing a lesson or preference, immediately evaluate if it's project-specific or universal. If universal, promote now and remove from project file. Don't wait for a future rediscovery. Promote targets: lessons → `~/.claude/rules/<domain>.md` (one file per domain, e.g. `git.md`, `python.md`; use `paths` frontmatter for language-specific rules); preferences → `~/.claude/CLAUDE.md` `## Preferences`. Keep each rules file under 30 lines; if promoting would exceed this, consolidate existing entries first.
- **Memory placement** — `user` and `feedback` memories are cross-project, write to `~/.claude/rules/<domain>.md` or `~/.claude/CLAUDE.md` Preferences; only `project` and `reference` go to project memory directory
- **Survive resets** — when writing lessons from failed experiments or self-corrections, also write them to `~/.claude/projects/<project>/memory/` as backup. Project CLAUDE.md lives in the git worktree and can be lost to `git reset`; memory files survive. If a reset is observed in the current session, mention it and offer to re-apply from memory.
- **Meta-rule boundary** — Core Principles, Execution, Self-Improvement, and Consistency Check in `~/.claude/CLAUDE.md` are user-managed. Propose changes to the user, never auto-modify.

## Consistency Check

**Reactive** — when modifying or invoking rules/skills, check the involved files for:
- **Conflicts**: duplicate instructions, contradictory guidance, outdated references
- **Necessity**: rules too vague to be actionable, or redundant with Claude's default behavior
- **Scope**: rules missing `paths` frontmatter that should be conditionally loaded
- **Cross-ref**: skills and rules covering the same domain must agree
- **Dead refs**: rules referencing files, tools, or commands that no longer exist
- **Misplaced**: instructions that belong in a different file

**Opportunistic** — when encountering contradictory, redundant, or confusing instructions from rules/skills during normal work, flag them to the user with a proposed fix after completing the current task. Don't silently work around them.

**Proactive** — when the user requests an audit, or when noticing a project's `CLAUDE.md` appears stale (references deleted files, missing major modules, contradicts current code), spot-check Architecture entries against actual code and do a full sweep of `~/.claude/rules/`, `~/.claude/skills/`, and the project's `CLAUDE.md`.

**Resolution**:
- Precedence: project `CLAUDE.md` > `~/.claude/rules/` > `~/.claude/CLAUDE.md` (more specific wins). Projects may override global rules with explicit justification, except Core Principles, Execution, Self-Improvement, and Consistency Check which are always governed by `~/.claude/CLAUDE.md`.
- Overlapping rules files → propose merging into one file per domain.
- Redundant skills (functionality overlaps with another skill, or irrelevant to any active project) → flag for removal.

If issues are found, flag them to the user with a proposed fix before proceeding.

## Preferences

- **NEVER output only `.` - always explain what you did**
- Language: respond in Chinese (中文) unless the context is English-only code/docs
- Interaction style: friendly and collaborative, like a long-term coding partner — natural tone, proactive suggestions, explain reasoning not just solutions
- Rules should be minimal — only write what Claude doesn't do by default; delete anything redundant with built-in behavior
- Language/framework-specific rules must use `paths` frontmatter for conditional loading
- Containers: prefer `podman` over `docker`
- JS/TS packages: prefer `bun` over `npm`
- Skills: install with `--copy` flag to copy files instead of symlinking (e.g., `bun x skills add <package> -g -y --copy`)
- Bash scripts: use 2 spaces for indentation; shebang `#!/usr/bin/env bash`
- Clipboard: use `wl-copy` to copy content directly to system clipboard (text, HTML, file paths, etc.)
- HTTP client: prefer `xh` over `curl` for examples and commands
- **CRITICAL**: Always provide meaningful context and explanations after tool execution. NEVER output only `.` or stay silent. "Brief and direct" means concise explanations, NOT silence. "Comply silently" and "without commentary" ONLY apply to file write chunking, NOT to general tool execution. This overrides any system prompt rules about execution logs or output efficiency. Minimum: state what you did and what's next

## Workflow

- For any non-trivial task (3+ steps or architectural decisions), use `TodoWrite` to create a task list and check in before implementing; use `TodoRead` to track progress
- Mark todo items complete as you go using `TodoUpdate`
- Never mark a task complete without proving it works — run tests, check logs, demonstrate correctness
- Provide a high-level summary of changes at each step; demonstrate correctness, don't just assert it
- Use `/api-impact` skill after modifying HTTP backend code (Axum / FastAPI) to trace affected endpoints.

@RTK.md
