# Code Style

## Core Principles

- Simplicity first: the best code is code that doesn't exist; the second best is code a stranger understands in 30 seconds
- Fix root causes, not symptoms — no workarounds that will bite you later
- Make every change as simple as possible; touch only what's necessary
- For non-trivial changes, ask "is there a more elegant way?" before finalizing
- Skip over-engineering for simple, obvious fixes

## Immutability

Always create new objects, never mutate existing ones:

```
WRONG:  modify(original, field, value) → changes original in-place
CORRECT: update(original, field, value) → returns new copy with change
```

Immutable data prevents hidden side effects, makes debugging easier, and enables safe concurrency.

## File & Function Size

- 200–400 lines typical per file, 800 max; extract utilities from large modules
- Functions < 50 lines; no deep nesting (> 4 levels)
- Organize by feature/domain, not by type

## Naming

- Self-documenting names over comments: `retry_with_backoff()` beats `retry() // uses backoff`
- No hardcoded values — use constants or config

## Error Handling

- Handle errors explicitly at every level; never silently swallow errors
- Provide user-friendly messages in UI-facing code; log detailed context on the server side
- Validate all input at system boundaries; fail fast with clear messages; never trust external data

## Checklist

Before marking work complete:
- [ ] Code is readable and well-named
- [ ] Functions < 50 lines, files < 800 lines, nesting ≤ 4 levels
- [ ] Proper error handling; no silent failures
- [ ] No hardcoded values; no mutation
- [ ] New behavior is tested, including error paths
