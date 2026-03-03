---
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
  - "**/Cargo.lock"
---

# Rust

## Naming & Style

- `snake_case` variables/functions/modules, `PascalCase` types/traits/enums, `SCREAMING_SNAKE_CASE` constants
- Explicit types in public API signatures; type inference in function bodies
- Derive order: `Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize`
- `#[must_use]` on functions returning `Result` or values callers shouldn't ignore
- No `#[allow(...)]` suppressions — fix the issue; document `unsafe` with `// SAFETY:`

## Error Handling

- Library crates: `thiserror` for domain errors; never expose `anyhow::Error` in public APIs
- Application/binary crates: `anyhow::Result` for propagation convenience
- Always add context: `.with_context(|| format!("failed to read {}", path.display()))` not bare `?`
- No `.unwrap()` / `.expect()` in production paths; tests and provably-infallible cases only (comment why)
- Map errors at boundaries — domain errors → HTTP status / exit codes at the outermost layer

```rust
// Good
fn load_config(path: &Path) -> anyhow::Result<Config> {
    let content = fs::read_to_string(path)
        .with_context(|| format!("failed to read config at {}", path.display()))?;
    toml::from_str(&content).context("invalid config format")
}
```

## Module Structure

- Organize by domain/feature: `auth/`, `billing/` — not `models/`, `handlers/`, `services/`
- `main.rs` / `lib.rs` thin — wire dependencies, no logic
- Layer flow: `routes` → `handlers` → `services` → `repositories`; dependencies inward only
- `pub(crate)` by default; `pub` only for actual external API surface

## Async

- `tokio` as the runtime; never mix runtimes
- No blocking code in async functions — use `tokio::task::spawn_blocking`
- Don't hold `Mutex` guards across `.await` points
- `Arc<T>` for shared state across tasks; no `Rc<T>` in async
- Store `JoinHandle`s for tasks that must complete; don't silently drop them
- Timeout all external calls with `tokio::time::timeout`

```rust
// Good — blocking work off the async thread
async fn hash_password(password: String) -> anyhow::Result<String> {
    tokio::task::spawn_blocking(move || bcrypt::hash(&password, 12))
        .await
        .context("join error")?
        .context("bcrypt failed")
}
```

## Performance & Memory

- Borrow in function parameters: `&str`, `&[T]`, `&Path` over `String`, `Vec<T>`, `PathBuf`
- `Cow<'_, str>` when sometimes allocating, sometimes borrowing
- No cloning in hot paths; comment when unavoidable: `// perf: clone needed because ...`
- Pre-allocate: `Vec::with_capacity(n)`, `HashMap::with_capacity(n)`
- Profile before optimizing — `criterion` for benchmarks, not intuition

## Web (Axum)

- Single `AppState` struct with all shared resources, wrapped in `Arc`
- Handlers return `impl IntoResponse` or a type implementing `IntoResponse` — never panic
- Typed extractors with validated input structs; separate DTOs from domain models
- Middleware (tracing, auth, CORS) in router setup, not in handlers

## CLI (Clap)

- `#[derive(Parser)]` for all argument definitions; document every arg with `#[arg(help = "...")]`
- `fn main() -> anyhow::Result<()>` for automatic error formatting
- Separate `cli.rs` (arg parsing) from business logic; `main.rs` only wires them

## Testing

- Unit tests in the same file under `#[cfg(test)] mod tests`
- Integration tests in `tests/`; `#[tokio::test]` for async tests
- Test error paths explicitly

## Quality Gates

```bash
cargo fmt --check && cargo clippy -- -D warnings && cargo test
```
