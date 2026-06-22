# Languages & Data Stores

Language-specific conventions and data store best practices.
The QA command chains in this file are the canonical definition; when changing them, sync `hooks/qa-gate.sh` (`required_for` / `hint_for_cat`).

---

## Rust

**Scope**: `**/*.rs`, `**/Cargo.toml`, `**/Cargo.lock`

- Errors: libraries use `thiserror`, never expose `anyhow::Error` in public APIs; binaries use `anyhow::Result` with `.with_context(|| format!("..."))` on every `?`
  - **New code**: no `.unwrap()` in production
  - **Existing code**: no refactor mandate for legacy unwraps — fix only if touching that code for other reasons
- Paths: small files use `include_str!("../../file.txt")` to embed at compile time; dev/test use `env!("CARGO_MANIFEST_DIR")`; production use config file or `current_exe()`; never use `./` relative paths (CWD-dependent)
- Quality: `cargo clippy -- -D warnings`; `cargo fmt` is auto-applied by the global git pre-commit hook at commit time — no need to run it manually before `git add` (qa-gate no longer requires a fmt record); run `cargo test` only when the project has a test suite (clippy handles compilation verification, not test); no separate `cargo build` — clippy already compiles, so a standalone build is redundant and wastes tokens; never run `cargo generate-lockfile` — clippy/test already update `Cargo.lock` as a side effect

---

## Python

**Scope**: `**/*.py`, `**/pyproject.toml`, `**/uv.lock`, `**/requirements*.txt`

- Project: use `uv` for deps; commit `uv.lock`; `uv run` for scripts; pin `requires-python`
- Paths: project files use `Path(__file__).parent` to calculate absolute paths; never use `./` relative paths (CWD-dependent)
- Types: all signatures typed; `from __future__ import annotations` at top; `X | None` over `Optional[X]`; `basedpyright` for type checking
- Errors: domain exceptions from base `AppError`; catch specific, never bare `except:`; FastAPI global handler
- Async: never blocking I/O in `async def` without `asyncio.to_thread`; use async libs (`httpx`, `aiosqlite`, `asyncpg`); `asyncio.gather` for concurrent
- FastAPI: `Annotated` for deps/validation; Pydantic v2; `lifespan` for startup/shutdown; typed responses, never ORM objects
- Quality: `uv run ruff check . && uv run basedpyright .`; `ruff format` is auto-applied by the global git pre-commit hook at commit time — no need to run it manually before `git add`; run `uv run pytest` only when the project has a test suite

---

## Bash

**Scope**: `**/*.sh`, `**/*.bash`

- Style: 2-space indent; shebang `#!/usr/bin/env bash`
- JSON: build with `jq -n` + heredoc, not `\n` concatenation
- Under `set -e`, `grep -c` needs `|| true`

---

## Database & Data Stores

**Scope**: `**/*.sql`, `**/migrations/**`

- All DB access through repository layer; map errors at boundary; never log PII
- SQL: set `max_connections`/`acquire_timeout` on pools; use `sqlx::query!` macros; never query in loops; index all FKs; use `BIGINT` for PKs; keep transactions short
- Redis: key naming `{entity}:{id}:{field}`; always set TTL; distributed locks `SET key value NX PX ttl`
