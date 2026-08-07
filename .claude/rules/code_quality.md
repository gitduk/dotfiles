When the review workflow fires, what it consists of, and how far to escalate.

## Change Protocol (CRITICAL) [CQ-1]

MUST, whenever an edit changes executable behavior — project code, or anything under `~/.claude` that runs (hooks, scripts, statusline) — bug fixes included: run the review workflow ([CQ-2]), from root-cause identification through the handoff report. Prose-only files, including rule files, are exempt. Pure research/reading never triggers it.

## Review Discipline

### Workflow [CQ-2]
0. If addressing a bug / test failure / unexpected behavior: identify the root cause first — start at investigation, not at the edit; skip only if unambiguous from the description.
1. Before writing, declare this change's review dimensions; incorporate the project's feedback-type memories.
1a. Check context7 (`resolve-library-id` → `query-docs`) only at self-announcing moments: adding a new dependency, a major-version upgrade/migration, or a compiler/LSP error against a library API that I can't explain. Routine calls into known deps: LSP diagnostics already catch stale-API mistakes — no pre-check.
2. Implement the change, focused on the current intent; if the user asked for tests, write them (recommend one when warranted even unasked); then verify it works by exercising the changed behavior, not just static checks — run tests if present.
3. Before declaring done, perform an adversarial re-read (blind spots are densest in code I just wrote): walk the declared review dimensions item by item; report only what changed or was rejected — nothing to report means nothing to report. When fixing or improving anything, ask: where else might the same class of problem exist? Scan as wide as the problem's nature warrants — same function, same file, same module, or same conceptual domain. Fix trivial instances, flag non-trivial ones.
4. If escalation conditions trigger, run an external agent loop: collect findings, sort them into real bugs / accepted improvements / rejected suggestions; fix the first two, reject the third explicitly with reasoning; if this round changed anything, verify once more.
5. At handoff, report: review dimensions, what the adversarial re-read changed, agent rounds and convergence, rejected items, items needing the user's decision, and a `Rules applied:` line listing the rule IDs actually activated — IDs belong in this report, not scattered through the prose. Section-level IDs carry their sub-reference (`[DIR-1] #2`), never bare. Skip this report if the change is a single file with <30 lines changed. **If any skill ran (`/code-review`, `/simplify`, `/security-review`, …), lead with a `Skills invoked:` line — each skill + one-line verdict; mandatory even when the report is otherwise skipped.**

### Standard Review Dimensions [CQ-3]
- Correctness: boundaries, null handling, off-by-one, concurrency, type safety
- Simplicity: duplication, over-abstraction, dead code, unused parameters
- Security: input validation, secrets, injection, permission checks
- Readability: naming, structural consistency, comments that survive the [CM-1] test (default none; WHY-only), comments that no longer match the code
- Performance (hot paths only): N+1, unnecessary allocation/copying, blocking in async
- Interface contracts: compatibility, breaking changes
- Tests (only when the user asked for tests): golden path + at least one edge case

### Escalation Triggers [CQ-4]
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

`/code-review` cannot be model-invoked (disabled since Claude Code v2.1.215) and needs a git repo — when a tier calls for it, prompt the user to run it at the stated level, then audit the findings. `/simplify` and `/security-review` remain model-invocable.

When the diff sprawls but the logic concentrates in a few files, scope simplify with `/simplify <paths>` — all four of its agents read the target, so narrowing it saves 4× the reading cost.

State the chosen tier and its rationale in the handoff; the user can order a re-run at a higher tier.

### Exempt from Escalation [CQ-6]
Adversarial re-read alone is fine:
- Mechanical changes: renames, formatting, import updates, generated files, lockfiles
- Documentation / comment-only updates
- Test-file-only changes that don't alter production logic

Between must-escalate ([CQ-4]) and exempt: default to no escalation, but name the change's risk surface in the handoff so the user can order escalation.

### Loop Termination [CQ-5]
Stop when: one round surfaces no new issue at severity ≥ medium, or 3 rounds total, or suggestions start oscillating. Agents are detectors, not authorities — I keep the right to reject stylistic suggestions.
