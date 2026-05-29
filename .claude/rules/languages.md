# Languages & Data Stores

Language-specific conventions and data store best practices.

---

## Rust

**Scope**: `**/*.rs`, `**/Cargo.toml`, `**/Cargo.lock`

- Errors: libraries use `thiserror`, never expose `anyhow::Error` in public APIs; binaries use `anyhow::Result` with `.with_context(|| format!("..."))` on every `?`
  - **New code**: no `.unwrap()` in production
  - **Existing code**: no refactor mandate for legacy unwraps — fix only if touching that code for other reasons
- Paths: small files use `include_str!("../../file.txt")` to embed at compile time; dev/test use `env!("CARGO_MANIFEST_DIR")`; production use config file or `current_exe()`; never use `./` relative paths (CWD-dependent)
- Quality: `cargo fmt --check && cargo clippy -- -D warnings`; run `cargo test` only when the project has a test suite (clippy handles compilation verification, not test); no separate `cargo build` — clippy already compiles, so a standalone build is redundant and wastes tokens; never run `cargo generate-lockfile` — clippy/test already update `Cargo.lock` as a side effect
- Tests: split Rust tests into two categories. Feature tests can be written directly inside the project test suite; bug reproduction tests should be separate scripts and must not enter project code.
- Format: Run `cargo fmt` immediately after every `cargo clippy` pass, not just before committing.

---

## Python

**Scope**: `**/*.py`, `**/pyproject.toml`, `**/uv.lock`, `**/requirements*.txt`

- Project: use `uv` for deps; commit `uv.lock`; `uv run` for scripts; pin `requires-python`
- Paths: project files use `Path(__file__).parent` to calculate absolute paths; never use `./` relative paths (CWD-dependent)
- Types: all signatures typed; `from __future__ import annotations` at top; `X | None` over `Optional[X]`; `basedpyright` for type checking
- Errors: domain exceptions from base `AppError`; catch specific, never bare `except:`; FastAPI global handler
- Async: never blocking I/O in `async def` without `asyncio.to_thread`; use async libs (`httpx`, `aiosqlite`, `asyncpg`); `asyncio.gather` for concurrent
- FastAPI: `Annotated` for deps/validation; Pydantic v2; `lifespan` for startup/shutdown; typed responses, never ORM objects
- Quality: `uv run ruff format --check . && uv run ruff check . && uv run basedpyright .`; run `uv run pytest` only when the project has a test suite

---

## Database & Data Stores

**Scope**: `**/*.sql`, `**/migrations/**`

- All DB access through repository layer; map errors at boundary; never log PII
- SQL: set `max_connections`/`acquire_timeout` on pools; use `sqlx::query!` macros; never query in loops; index all FKs; use `BIGINT` for PKs; keep transactions short
- Elasticsearch: explicit mappings; `keyword` for exact, `text` for full-text; `filter` for exact/ranges (cached), `query` for scoring; `search_after` for deep pagination
- Redis: key naming `{entity}:{id}:{field}`; always set TTL; distributed locks `SET key value NX PX ttl`
