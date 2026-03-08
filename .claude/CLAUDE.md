## Core Principles

- **Simplicity**: Make every change as simple as possible. Only touch what's necessary.
- **Root causes**: Find root causes. No temporary fixes. Senior developer standards.
- **Stop and re-plan**: If execution goes sideways, stop immediately and re-plan — don't keep pushing a failing approach.

## Execution

- Use subagents liberally — offload research, exploration, and parallel analysis to keep main context clean. One tack per subagent.
- For non-trivial changes, pause and ask "is there a more elegant way?" Skip this for simple, obvious fixes.
- After completing a feature or fix, scan for repeated patterns and extract shared helpers.
- When compacting, preserve: modified file list, active task state, key architectural decisions, pending CLAUDE.md updates.

## Self-Improvement Loop

### Triggers (write to project `CLAUDE.md`)

Timing: never interrupt a user-facing operation to update CLAUDE.md. Write at natural pauses (between steps, awaiting input, task complete).

- **First contact** — when entering a project without a `CLAUDE.md`: skip if trivially small (<5 files) or a config/dotfiles directory. Otherwise, create with `## Architecture` (tech stack, module responsibilities, key conventions). Keep initial version concise — describe patterns, don't dump file trees or route lists.
- **Corrected** — recurring pattern or non-obvious mistake → `## Lessons`. Skip trivial one-offs.
- **Observed habit** — user workflow patterns, naming conventions, tool choices → `## Preferences`.
- **After code change** — new feature, architectural change, API addition, module restructuring → `## Architecture`. Record key decisions, new modules/files, patterns introduced. Skip minor fixes.
- **Discovered while reading** — undocumented project knowledge (architecture, module responsibilities, conventions, patterns, API surface) → `## Architecture`. Covers features the user built manually. Batch: accumulate up to 3 items, then write together; don't hold discoveries across long conversations where compaction may discard them.
- **Self-correction** — mid-task re-plan or abandoned approach that reveals a reusable lesson → `## Lessons`.
- **Effective strategy** — when a subagent delegation, task decomposition, or execution approach proves particularly effective or ineffective for this project → `## Execution`.
- **Stack change** — when evidence of a major technology change is encountered during normal work (new language, framework swap, API paradigm shift), review all `## Architecture` and `## Lessons` entries; remove or update those tied to the old stack.

### Maintenance

- **Update over append** — if an existing entry covers the same topic, update it in place; don't append a duplicate.
- **Size control** — keep each entry to one line; if details are needed, create a separate file and link from CLAUDE.md. Aim for the whole file to stay under 100 lines.
- **Cleanup** — remove entries that are outdated or proven incorrect; don't let stale knowledge accumulate.
- **Promote eagerly** — when writing a lesson or preference, immediately evaluate if it's project-specific or universal. If universal, promote now and remove from project file. Don't wait for a future rediscovery. Promote targets: lessons → `~/.claude/rules/<domain>.md` (one file per domain, e.g. `git.md`, `python.md`; use `paths` frontmatter for language-specific rules); preferences → `~/.claude/CLAUDE.md` `## Preferences`. Keep each rules file under 30 lines; if promoting would exceed this, consolidate existing entries first.
- **Survive resets** — when writing lessons from failed experiments or self-corrections, also write them to `~/.claude/projects/<project>/memory/` as backup. Project CLAUDE.md lives in the git worktree and can be lost to `git reset`; memory files survive. If a reset is observed in the current session, mention it and offer to re-apply from memory.
- **Transparency** — mention CLAUDE.md changes in conversation (e.g., "Updated ## Architecture with new module X"). For global rules changes, remind the user to commit to dotfiles.
- **Meta-rule boundary** — Core Principles, Execution, Self-Improvement Loop, and Consistency Check in `~/.claude/CLAUDE.md` are user-managed. Propose changes to the user, never auto-modify.

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
- Precedence: project `CLAUDE.md` > `~/.claude/rules/` > `~/.claude/CLAUDE.md` (more specific wins). Projects may override global rules with explicit justification, except Core Principles, Execution, Self-Improvement Loop, and Consistency Check which are always governed by `~/.claude/CLAUDE.md`.
- Overlapping rules files → propose merging into one file per domain.
- Redundant skills (functionality overlaps with another skill, or irrelevant to any active project) → flag for removal.

If issues are found, flag them to the user with a proposed fix before proceeding.

## Preferences

- Language: respond in Chinese (中文) unless the context is English-only code/docs
- Rules should be minimal — only write what Claude doesn't do by default; delete anything redundant with built-in behavior
- Language/framework-specific rules must use `paths` frontmatter for conditional loading
- Containers: prefer `podman` over `docker`
- JS/TS packages: prefer `bun` over `npm`
- Skills: install with `--copy` flag to copy files instead of symlinking (e.g., `bun x skills add <package> -g -y --copy`)
- Bash scripts: use 2 spaces for indentation
- Clipboard: use `wl-copy` to copy content directly to system clipboard (text, HTML, file paths, etc.)

