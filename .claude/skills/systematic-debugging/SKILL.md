---
name: systematic-debugging
description: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
---

# Systematic Debugging

Root-cause discipline itself (root cause before any fix, failing test first, verify) lives in the Change Protocol's bug branch — this skill does not repeat it. It carries what the protocol doesn't: evidence-gathering techniques and the anti-thrashing circuit breaker.

## Evidence before hypotheses

**Multi-component systems** (CI → build → signing, API → service → DB): before proposing any fix, instrument every component boundary —

- Log what data enters and exits each component
- Verify environment/config propagation across boundaries
- Check state at each layer

Run once to show WHERE it breaks, then investigate that component. Don't reason about which layer fails — make the system tell you.

**Error deep in a call stack**: trace backward to where the bad value originates and fix at the source, not at the symptom. Full technique: `root-cause-tracing.md` in this directory.

## Hypothesis discipline

- One hypothesis at a time, stated explicitly: "I think X is the root cause because Y"
- Smallest possible change to test it; one variable at a time
- Fix didn't work → form a NEW hypothesis. Never stack another fix on top of a failed one.
- Count your fix attempts — the counter feeds the circuit breaker below.

## Circuit breaker: 3 failed fixes = architecture problem

After the 3rd failed fix, STOP. Do not attempt fix #4.

Signs the problem is architectural, not a failed hypothesis:

- Each fix reveals new shared state or coupling somewhere else
- Fixes keep requiring "massive refactoring" to implement
- Each fix creates new symptoms elsewhere

This means the pattern itself is wrong. Question whether the design is fundamentally sound, and discuss with 凯歌 before attempting any further fix.

## Red flags — STOP and return to evidence gathering

- "Just try changing X and see if it works"
- "Add multiple changes, then run tests"
- "It's probably X, let me fix that"
- "I don't fully understand this, but this might work"
- Proposing solutions before tracing data flow
- "One more fix attempt" when already 2+ failed

## Supporting techniques (this directory)

- `root-cause-tracing.md` — trace bugs backward through the call stack to the original trigger (includes `find-polluter.sh` for bisecting test pollution)
- `defense-in-depth.md` — add validation at multiple layers after the root cause is found
- `condition-based-waiting.md` — replace arbitrary timeouts with condition polling
