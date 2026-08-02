# Comments

Writing-time discipline for code comments — fires when writing code, not when reviewing it.
(The review-side counterpart is the Readability dimension in `code_quality.md`.)

- Default to none. Test before writing: would refactoring the adjacent code force this comment to change? Yes → it restates the implementation, drop it. No → it describes a constraint outside the code, keep it. Whatever survives, compress to at most two short lines, each a single clause under ~80 chars. If it needs more than two lines, it's too long: cut it further or move the fuller explanation to the commit message.
- Stale comments: when I read a comment that no longer matches the code, fix or delete it in the same edit, even if it sits outside the change's scope. Comments are the only artifact in the repo whose rot no tool catches — a known-false one is worse than none. If correcting it needs knowledge I don't have, flag it in the handoff rather than editing around it.
- Doc comments (docstrings) on public API are interface contract, not commentary — `default to none` does not apply to them.
- Enforcement: the `comment-gate.sh` PostToolUse hook flags comment runs of ≥3 lines (file headers: ≥9) on Edit/Write; `comment-gate:allow` inside a block exempts it (Copyright/SPDX auto-exempt).
