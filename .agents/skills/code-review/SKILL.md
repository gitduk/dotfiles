---
name: code-review
description: Review the current diff (or a given target) for correctness bugs plus reuse/simplification/efficiency/altitude/convention cleanups
argument-hint: "[PR-URL | branch | path]"
---
You are reviewing for **precision**: every finding you surface should be one
a maintainer would act on. You are not applying fixes — just reporting.

## Phase 0 — Gather the diff

Review target: ${@:-(none given)}

If a target is named above (a PR number, branch name, or file path), review that
target and treat it as the review scope.

Otherwise run `git diff @{upstream}...HEAD` (or `git diff main...HEAD` /
`git diff HEAD~1` if there's no upstream) to get the unified diff under review.
If there are uncommitted changes, or the range diff is empty, also run
`git diff HEAD` and include the working-tree changes in scope — the review often
runs before the commit. Treat that diff as the review scope.

## Phase 1 — Find candidates (8 angles)

Run the review by diff size:

- **Small diff (≤ ~300 changed lines)**: work through the 8 angles below
  yourself, in sequence, in this same context. Each surfaces candidate findings
  with `file`, `line`, a one-line `summary`, and a concrete `failure_scenario`.
- **Large diff (> ~300 changed lines or > ~15 files)**: shard and parallelize
  with `task` (see "Large-diff sharding" at the end of this phase), then merge
  the shard pools into one for Phase 2.

### Angle A — line-by-line diff scan

Read every hunk in the diff, line by line. Then read the enclosing function for
each hunk — bugs in unchanged lines of a touched function are in scope (the PR
re-exposes or fails to fix them). For every line ask: what input, state, timing,
or platform makes this line wrong? Look for inverted/wrong conditions,
off-by-one, null/undefined deref, missing `await`, falsy-zero checks,
wrong-variable copy-paste, error swallowed in catch, unescaped regex metachars.

### Angle B — removed-behavior auditor

For every line the diff DELETES or replaces, name the invariant or behavior it
enforced, then search the new code for where that invariant is re-established.
If you can't find it, that's a candidate: a removed guard, a dropped error
path, a narrowed validation, a deleted test that was covering a real case.

### Angle C — cross-file tracer

For each function the diff changes, find its callers (grep for the symbol) and
check whether the change breaks any call site: a new precondition, a changed
return shape, a new exception, a timing/ordering dependency. Also check callees:
does a parallel change in the same diff make a call unsafe?

### Reuse

The angles above hunt for bugs; this one and the next two hunt for cleanup in
the changed code. Flag new code that re-implements something the codebase
already has — grep shared/utility modules and files adjacent to the change,
and name the existing helper to call instead.

### Simplification

Flag unnecessary complexity the diff adds: redundant or derivable state,
copy-paste with slight variation, deep nesting, dead code left behind. Name
the simpler form that does the same job.

### Efficiency

Flag wasted work the diff introduces: redundant computation or repeated I/O,
independent operations run sequentially, blocking work added to startup or
hot paths. Also flag long-lived objects built from closures or captured
environments — they keep the entire enclosing scope alive for the object's
lifetime (a memory leak when that scope holds large values); prefer a
class/struct that copies only the fields it needs. Name the cheaper
alternative.

### Altitude

Check that each change is implemented at the right depth, not as a fragile
bandaid. Special cases layered on shared infrastructure are a sign the fix
isn't deep enough — prefer generalizing the underlying mechanism over adding
special cases.

### Conventions (AGENTS.md / CLAUDE.md)

Find the AGENTS.md/CLAUDE.md files that govern the changed code: any that sit
in a directory that is an ancestor of a changed file (a directory's file only
applies to files at or below it). Read each one that exists, then check the
diff for clear violations of the rules they state.

Only flag a violation when you can quote the exact rule and the exact line
that breaks it — no style preferences, no vague "spirit of the doc"
inferences. In the finding, name the file path and quote the rule so the
report can cite it. If none apply, return nothing for this angle.

Cleanup, altitude, and conventions candidates use the same `file`/`line`/
`summary` shape; in `failure_scenario`, state the concrete cost (what is
duplicated, wasted, harder to maintain, or which rule is broken) instead of a
crash. Correctness bugs always outrank cleanup, altitude, and conventions
findings when the output cap forces a cut.

### Large-diff sharding (task)

1. Split the diff into chunks by file group — never inside a hunk or function —
   keeping line counts roughly balanced; whole files per chunk when the diff is
   file-dominant. A chunk is the scope one subagent fully reviews.
2. Launch one `task` per chunk in a single message so they run in parallel.
   Each prompt must be self-contained — the subagent cannot reach you — so
   state exactly: the paths/lines it owns, to run `git diff <range>` scoped to
   them, a condensed 8-angle checklist (name + what each hunts), and the
   finding shape (`file`, `line`, `summary`, `failure_scenario`) to return.
3. After all return, merge the pools into one and run Phase 2 on the combined
   set; the 8-finding output cap applies to the merged pool, not per shard. A
   subagent sees only its own chunk, so the gaps between chunks are yours to
   close in this context: callers/callees crossing a chunk boundary (Angle C)
   and invariants deleted in one chunk that must be re-established in another
   (Angle B). Conventions is a cheap ancestor-search, so run it centrally on
   the full changed-file set rather than per shard.
## Phase 2 — Dedup and self-check

Dedup near-duplicates (same defect, same location, same reason → keep one).
Re-check each remaining candidate yourself against the diff before keeping it.
Do not refute a candidate just for being "speculative" when the triggering
state is realistic (concurrency races, nil/undefined on a rare-but-reachable
path, falsy-zero treated as missing, an unguarded boundary). Only drop a
candidate when you can point at the line that disproves or already guards it.

## Output

Return at most 8 findings, ranked most-severe first, as a numbered list. One
finding per item, in this shape:

1. **blocker** — `path/to/file.ext:123` — one-sentence statement of the bug.
   Failure: concrete inputs/state → wrong output/crash.

For cleanup, altitude, and conventions findings, the `Failure` line states the
concrete cost (what is duplicated, wasted, harder to maintain, or which rule is
broken) instead of a crash.

`Severity` is one of:
- `blocker` — crashes, data loss, security holes, wrong results on a
  reachable path; must fix before merge.
- `major` — realistic-state bugs (races, nil/undefined on rare-but-reachable
  paths, falsy-zero) that ship broken behavior for some inputs.
- `minor` — reuse/simplification/efficiency/altitude/conventions cleanup
  that costs maintenance, not correctness.

Correctness findings outrank cleanup findings of the same severity. If more
than 8 survive, keep the 8 most severe. If nothing survives, state that no
findings were kept.
