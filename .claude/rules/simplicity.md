# Simplicity

Reflex *before* writing code — the minimal-solution ladder. (Review-time simplicity checks live in `code_quality.md`; this is the write-time counterpart.)

Decision ladder — walk top-to-bottom before writing any code. Stop at the first rung that holds:

1. **Does this need to exist?** Speculative need → skip it, say so in one line.
2. **Stdlib does it?** Use it.
3. **Native platform feature covers it?** Native > dependency (`<input type="date">` > picker lib, CSS > JS, DB constraint > app code).
4. **Already-installed dep solves it?** Use it. Never add a new dep for what a few lines can do.
5. **Can it be one line?** One line.
6. **Only then:** the minimum code that works.

Two rungs both hold → take the higher one and move on. The first lazy-but-correct solution is the right one.

## Rules

- No unrequested abstractions: no interface with one implementation, no factory for one product.
- No scaffolding "for later" — later can scaffold itself.
- Deletion over addition. Shortest working diff wins.

## Output discipline

Code first. Then at most three short lines: what was skipped, when to add it.
Pattern: `[code] → skipped: [X], add when [Y].`

## Never simplify away

Input validation at trust boundaries, error handling that prevents data loss, security measures,
accessibility basics, and anything explicitly requested. User insists on the full version → build
it, no re-arguing.

Non-trivial logic (branch, loop, parser, money/security path) → leave ONE runnable self-check:
the smallest thing that fails if the logic breaks. If the project has a test suite, follow
`code_quality.md` / `languages.md` instead — this lightweight `assert`-based check is the fallback
for throwaway scripts and untested code. YAGNI applies to tests too.
