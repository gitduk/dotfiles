---
name: simplify
description: Review the changed code for reuse, simplification, efficiency, and altitude cleanups, then apply the fixes
argument-hint: "[PR-URL | branch | path]"
---
You are improving the quality of the changed code, not hunting for bugs. Review
it for reuse, simplification, efficiency, and altitude issues, then fix what you
find. Do not look for correctness bugs — that is a separate review pass.

## Phase 0 — Gather the diff

Review target: ${@:-(none given)}

If a target is named above (a PR number, branch name, or file path), review that
target and treat it as the review scope.

Otherwise run `git diff @{upstream}...HEAD` (or `git diff main...HEAD` /
`git diff HEAD~1` if there's no upstream) to get the unified diff under review.
If there are uncommitted changes, or the range diff is empty, also run
`git diff HEAD` and include the working-tree changes in scope — the review often
runs before the commit. Treat that diff as the review scope.

## Phase 1 — Review (4 cleanup angles)

Run the review by diff size:

- **Small diff (≤ ~300 changed lines)**: review the diff against each angle
  below in turn. For each, note findings with `file`, `line`, a one-line
  `summary`, and the concrete cost (what is duplicated, wasted, or harder to
  maintain).
- **Large diff (> ~300 changed lines or > ~15 files)**: shard and parallelize
  with `task` (see "Large-diff sharding" at the end of this phase); each shard
  is reviewed and fixed by its own subagent.

### Reuse

Flag new code that re-implements something the codebase already has — grep
shared/utility modules and files adjacent to the change, and name the
existing helper to call instead.

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

### Large-diff sharding (task)

1. Split the diff into chunks by file group — never inside a hunk or function —
   keeping line counts roughly balanced and the file sets disjoint (fixes from
   different subagents must never touch the same file).
2. Launch one `task` per chunk in a single message so they run in parallel.
   Each prompt must be self-contained — the subagent cannot reach you — so
   state exactly: the paths it owns, to run `git diff <range>` scoped to them,
   the four cleanup angles, and that it should apply its own fixes and report
   the changed paths, any skips with reasons, and the exit status of a verify
   command (`git diff --check`, a build, or the test suite).
3. After all return, check in this context that fixes across chunk boundaries
   still agree — shared helpers or signatures changed in one chunk and used in
   another are your call to reconcile, since no subagent sees beyond its own
   files.

## Phase 2 — Apply the fixes

In sharded mode each subagent already applied its own chunk's fixes; apply the
rules below to its report and to the cross-chunk fixes you make here. In
small-diff mode apply them to the Phase 1 findings directly.
Dedup findings that point at the same line or mechanism, and fix each
remaining one directly. Skip any finding whose fix would change intended
behavior, require changes well outside the reviewed diff, or that you judge to
be a false positive — note the skip rather than arguing with it. Finish with a
brief summary of what was fixed and what was skipped (or confirm the code was
already clean).
