---
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
  - "**/Cargo.lock"
scope: [new code, new modules, library APIs]
conflicts_with: null
---

# Rust

- Errors: library use `thiserror`, never expose `anyhow::Error` in public APIs; binary use `anyhow::Result` with `.with_context(|| format!("..."))` on every `?`
  - **New code**: no `.unwrap()` in production
  - **Existing code**: no refactor mandate for legacy unwraps — fix only if touching that code for other reasons
- Quality: `cargo fmt --check && cargo clippy -- -D warnings`; only run `cargo test` when the project has tests; do not run separate `cargo build` unless a build artifact is specifically needed (see `no_bare_cargo_build.md`)
- Format: Run `cargo fmt` immediately after every `cargo clippy` pass, not just before committing.

