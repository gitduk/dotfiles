---
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
  - "**/Cargo.lock"
---

- **[RUST-1]** Errors: libraries use `thiserror` once the type has ≥2 variants or any variant carries a `source` — hand-writing `Display`+`Error`+`source` runs ~40 lines and is easy to get subtly wrong, so this deliberately overrides [SIM-1] rung 4; single-variant wrappers may stay hand-rolled. Never expose `anyhow::Error` in public APIs; binaries use `anyhow::Result` with `.with_context(|| format!("..."))` on every `?`
  - **[RUST-2] New code**: no `.unwrap()` in production
  - **[RUST-3] Existing code**: no refactor mandate for legacy unwraps — fix only if touching that code for other reasons
- **[RUST-4]** Paths: never `./` relative paths (CWD-dependent)
  - small files: `include_str!("../../file.txt")` embeds at compile time
  - dev/test: `env!("CARGO_MANIFEST_DIR")`
  - production: config file or `current_exe()`
- **[RUST-5]** Security: never `danger_accept_invalid_certs(true)` (reqwest) — TLS verification stays on
- **[RUST-6]** Quality: `cargo clippy -- -D warnings`; `cargo test` only when a test suite exists
  - fmt is owned by the git pre-commit hook — never run it manually
  - no `cargo build` just to type-check (clippy already compiles) — build only when the binary itself is needed
  - never `cargo generate-lockfile` (it is a side effect of clippy/test)

## Code navigation

See `code_navigation.md`; LSP server check: `pgrep -x rust-analyzer`.
