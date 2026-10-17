---
paths:
  - "**/*.rs"
  - "**/Cargo.toml"
  - "**/Cargo.lock"
---

- **[R76 thiserror-threshold]** Errors: libraries use `thiserror` once the type has ≥2 variants or any variant carries a `source` — hand-writing `Display`+`Error`+`source` runs ~40 lines and is easy to get subtly wrong, so this deliberately overrides [R26 minimal-ladder] rung 4; single-variant wrappers may stay hand-rolled. Never expose `anyhow::Error` in public APIs; binaries use `anyhow::Result` with `.with_context(|| format!("..."))` on every `?`
- **[R77 no-new-unwraps]** `.unwrap()` — new code: none in production
- **[R78 legacy-unwraps-stay]** `.unwrap()` — existing code: no refactor mandate for legacy unwraps; fix only if touching that code for other reasons
- **[R79 rust-abs-paths]** Paths ([R39 no-cwd-relative-paths]) — the Rust mechanisms:
  - small files: `include_str!("../../file.txt")` embeds at compile time
  - dev/test: `env!("CARGO_MANIFEST_DIR")`
  - production: config file or `current_exe()`
- **[R80 rust-qa]** Quality: `cargo clippy -- -D warnings`; `cargo test` per [R42 tests-only-when-suite]; `cargo fmt` per [R82 fmt-before-staging]
  - no `cargo build` just to type-check (clippy already compiles) — build only when the binary itself is needed
  - never `cargo generate-lockfile` (it is a side effect of clippy/test)
