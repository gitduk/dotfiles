Run quality gates for the current project. Auto-detect language and run the appropriate checks:

- **Rust**: `cargo fmt --check && cargo clippy -- -D warnings` (+ `cargo test` if tests exist)
- **Python**: `uv run ruff format --check . && uv run ruff check . && uv run basedpyright . && uv run pytest`
- **JS/TS**: detect package manager, run lint + typecheck + test

Report pass/fail for each step. If anything fails, show the relevant output and suggest a fix.
