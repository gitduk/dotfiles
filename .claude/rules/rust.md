# Rust

- Errors: library use `thiserror`, never expose `anyhow::Error` in public APIs; binary use `anyhow::Result` with `.with_context(|| format!("..."))` on every `?`; no `.unwrap()` in production
- Quality: `cargo fmt --check && cargo clippy -- -D warnings && cargo test`
- Format: Run `cargo fmt` immediately after every `cargo clippy` pass, not just before committing.

