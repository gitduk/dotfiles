---
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
  - "**/Cargo.lock"
---

# Rust

- Errors: libraries use `thiserror`, never expose `anyhow::Error` in public APIs; binaries use `anyhow::Result` with `.with_context(|| format!("..."))` on every `?`
  - **New code**: no `.unwrap()` in production
  - **Existing code**: no refactor mandate for legacy unwraps — fix only if touching that code for other reasons
- Paths: small files use `include_str!("../../file.txt")` to embed at compile time; dev/test use `env!("CARGO_MANIFEST_DIR")`; production use config file or `current_exe()`; never use `./` relative paths (CWD-dependent)
- Quality: `cargo clippy -- -D warnings`; fmt is owned by the git pre-commit hook — never run it manually; `cargo test` only when a test suite exists; never `cargo build` (clippy compiles) or `cargo generate-lockfile` (side effect of clippy/test)

## Code navigation

Prefer the LSP tool for symbol queries — findReferences, incomingCalls/outgoingCalls, goToDefinition, workspaceSymbol. Structural shape queries ("all code shaped like `$X.unwrap()`") → ast-grep (installed at `~/.local/bin`). Grep is for plain-text search only (string literals, comments, config keys).

    if LSP returns empty: verify a server is running AND its cwd is this project (pgrep -x rust-analyzer; readlink /proc/<pid>/cwd)  # both failure modes look identical to "no usages"; never silently fall back to grep
