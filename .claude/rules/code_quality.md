# Code Quality

Code review workflow, standards, and skill usage.

## Review Discipline

Whether a change triggers this workflow is defined **solely** by the Change Protocol in `~/.claude/CLAUDE.md` — this file owns the workflow detail, not the trigger. Pure research/reading never triggers it.

### Workflow
1. Before writing, declare this change's review dimensions; incorporate the project's feedback-type memories.
1a. Before writing code that calls an external library's API, check context7 (`resolve-library-id` → `query-docs`) if: the library iterates quickly (e.g. Prisma, Next.js, Pydantic, axum), or I'm uncertain about the current API. Skip for standard libraries and stable primitives.
2. Implement the change, focused on the current intent; then verify it works by exercising the changed behavior, not just static checks.
3. Before declaring done, perform an adversarial re-read: walk the declared review dimensions item by item; report only what changed or was rejected — nothing to report means nothing to report. When fixing or improving anything, ask: where else might the same class of problem exist? Scan as wide as the problem's nature warrants — same function, same file, same module, or same conceptual domain. Fix trivial instances, flag non-trivial ones.
4. If escalation conditions trigger, run an external agent loop: collect findings, sort them into real bugs / accepted improvements / rejected suggestions; fix the first two, reject the third explicitly with reasoning; if this round changed anything, verify once more.
5. At handoff, report: review dimensions, what the adversarial re-read changed, agent rounds and convergence, rejected items, items needing the user's decision. Skip this report if the change is a single file with <30 lines changed. **If any skill ran (`/code-review`, `/simplify`, `/security-review`, …), lead with a `Skills invoked:` line — each skill + one-line verdict; mandatory even when the report is otherwise skipped.**

### Standard Review Dimensions
- Correctness: boundaries, null handling, off-by-one, concurrency, type safety
- Simplicity: duplication, over-abstraction, dead code, unused parameters
- Security: input validation, secrets, injection, permission checks
- Readability: naming, structural consistency, comments that explain WHY
- Performance (hot paths only): N+1, unnecessary allocation/copying, blocking in async
- Interface contracts: compatibility, breaking changes
- Tests (only when the user asked for tests): golden path + at least one edge case

### Escalation Triggers
Impact-based, not size-based. No quantitative threshold — the fallback judgment (e.g. "this sprawled wider than expected") belongs to the user, who orders escalation manually.

**Must escalate** — the trigger domain decides *whether*, the intensity ladder decides *how hard*; two independent judgments:

Trigger domains:
- Security / permission boundaries: auth, validation, key management — additionally run `/security-review`
- Public API / CLI contract changes: params, return values, protocol behavior
- Core business logic: algorithms, state-transition logic, core data transformations
- Critical dependency upgrades or swaps (ORM, web framework, crypto)
- Uncertain design judgment: `/code-review high` alone is enough

Intensity ladder — pick by the change's logic complexity, never by file/line count:
- **Light** — domain hit, but the logic is a single obvious transformation (no new invariants, no concurrency, no subtle boundaries): `/code-review medium` only. Skip `/simplify` — code-review already reports reuse/simplification findings, and simplify has no effort knob (always full multi-agent), so it is the expensive step to drop.
- **Standard** (default when unsure) — `/simplify` then `/code-review high`. Simplify mutates the tree, so code-review must run last to audit the final shipping code and catch anything simplify introduced.
- **Heavy** — security boundaries, crypto, algorithms with subtle invariants, or changes that couldn't be fully verified by exercising: `/simplify` then `/code-review xhigh` (plus `/security-review` when the security domain fired).

When the diff sprawls but the logic concentrates in a few files, scope simplify with `/simplify <paths>` — all four of its agents read the target, so narrowing it saves 4× the reading cost.

State the chosen tier and its rationale in the handoff; the user can order a re-run at a higher tier.

**Exempt** — adversarial re-read alone is fine:
- Mechanical changes: renames, formatting, import updates, generated files, lockfiles
- Documentation / comment-only updates
- Test-file-only changes that don't alter production logic

Between must-escalate and exempt: default to no escalation, but name the change's risk surface in the handoff so the user can order escalation.

### Loop Termination
Stop when: one round surfaces no new issue at severity ≥ medium, or 3 rounds total, or suggestions start oscillating. Agents are detectors, not authorities — I keep the right to reject stylistic suggestions.

When the same class of issue recurs, pick the intervention surface by its signature: a missing fact → feedback/project memory; a reusable procedure → skill (functionality sinks to skills, not rules); a working-discipline gap → propose a rule edit. Cheapest surface that stops the recurrence wins.

## Standards

- Security: never `verify=False` / `danger_accept_invalid_certs(true)`
