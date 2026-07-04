# Simplicity

Reflex *before* writing code — the minimal-solution ladder.

Decision ladder — walk top-to-bottom before writing any code. Stop at the first rung that holds:

1. **Does this need to exist?** Speculative need → skip it, say so in one line.
2. **Stdlib does it?** Use it.
3. **Native platform feature covers it?** Native > dependency (`<input type="date">` > picker lib, CSS > JS, DB constraint > app code).
4. **Already-installed dep solves it?** Use it. Never add a new dep for what a few lines can do.
5. **Can it be one line?** One line.
6. **Only then:** the minimum code that works.

Two rungs both hold → take the higher one and move on. The first lazy-but-correct solution is the right one.

## Never simplify away

Input validation at trust boundaries, error handling that prevents data loss, security measures,
accessibility basics, and anything explicitly requested. User insists on the full version → build
it, no re-arguing.
