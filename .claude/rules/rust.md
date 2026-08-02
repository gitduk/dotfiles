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
- Security: never `danger_accept_invalid_certs(true)` (reqwest) — TLS verification stays on
- Quality: `cargo clippy -- -D warnings`; fmt is owned by the git pre-commit hook — never run it manually; `cargo test` only when a test suite exists; no `cargo build` just to type-check (clippy already compiles) — build only when the binary itself is needed; never `cargo generate-lockfile` (side effect of clippy/test)

## Code navigation

See `code_navigation.md`; LSP server check: `pgrep -x rust-analyzer`.
