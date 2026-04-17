# Code Quality

Code review workflow, standards, and skill usage.

## Review Discipline

Any code change goes through this workflow; pure research/reading does not trigger it.

### Workflow
1. Before writing, declare this change's review dimensions; overlay `~/.claude/projects/<CWD>/memory/checklist.md` if it exists.
2. Implement the change, focused on the current intent.
3. Before declaring done, perform an adversarial re-read: walk the checklist item by item and find at least one thing to improve; if truly trivial, say so explicitly.
4. If escalation conditions trigger, run an external agent loop: collect findings, sort them into real bugs / accepted improvements / rejected suggestions; fix the first two, reject the third explicitly with reasoning; if this round changed anything, verify once more.
5. At handoff, report: review dimensions, what the adversarial re-read changed, agent rounds and convergence, rejected items, items needing 凯歌's decision.

### Standard Review Dimensions
- Correctness: boundaries, null handling, off-by-one, concurrency, type safety
- Simplicity: duplication, over-abstraction, dead code, unused parameters
- Security: input validation, secrets, injection, permission checks
- Readability: naming, structural consistency, comments that explain WHY
- Performance (hot paths only): N+1, unnecessary allocation/copying, blocking in async
- Interface contracts: compatibility, breaking changes
- Tests: golden path + at least one edge case (if the project has tests)

### Escalation Triggers
- ≥3 files or ≥100 lines changed: `code-reviewer` + `simplify`
- Security-sensitive: `security-auditor`; uncertain design judgment: `code-reviewer`; project has a test framework: `tester`
- Single small file not meeting the above: adversarial re-read alone is fine

### Loop Termination
Stop when: one round surfaces no new issue at severity ≥ medium, or 3 rounds total, or suggestions start oscillating. Agents are detectors, not authorities — I keep the right to reject stylistic suggestions.

When the same class of issue recurs in a project, append it to the project's `memory/checklist.md`.

## Standards

- Bash: build JSON with `jq -n` + heredoc, not `\n` concatenation; under `set -e`, `grep -c` needs `|| true`
- Security: run `cargo audit` / `uv run pip-audit` periodically; never `verify=False` / `danger_accept_invalid_certs(true)`

## Skill Lookup

Don't guess skill names. Confirm the skill exists in the current session's available-skills list first; if it doesn't, fall back to built-in tools.
