---
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
  - "**/Cargo.lock"
---

# Rust

- Errors: library use `thiserror`, never expose `anyhow::Error` in public APIs; binary use `anyhow::Result` with `.with_context(|| format!("..."))` on every `?`; no `.unwrap()` in production
- Async: `tokio` runtime; blocking work in `spawn_blocking`; don't hold `Mutex` across `.await`; `Arc<T>` for shared state; timeout external calls
- Performance: borrow in params (`&str`, `&[T]`, `&Path`); pre-allocate with `with_capacity`; profile with `criterion` before optimizing
- Axum: single `Arc<AppState>`; handlers return `impl IntoResponse`, never panic; separate DTOs from domain models
- Quality: `cargo fmt --check && cargo clippy -- -D warnings && cargo test`
