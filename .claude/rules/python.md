---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
  - "**/uv.lock"
  - "**/requirements*.txt"
---

# Python

- Project: use `uv` for deps; commit `uv.lock`; `uv run` for scripts; pin `requires-python`
- Paths: project files use `Path(__file__).parent` to calculate absolute paths; never use `./` relative paths (CWD-dependent)
- Types: all signatures typed; `from __future__ import annotations` at top; `X | None` over `Optional[X]`; `basedpyright` for type checking
- Errors: domain exceptions from base `AppError`; catch specific, never bare `except:`; FastAPI global handler
- Async: never blocking I/O in `async def` without `asyncio.to_thread`; use async libs (`httpx`, `aiosqlite`, `asyncpg`); `asyncio.gather` for concurrent
- FastAPI: `Annotated` for deps/validation; Pydantic v2; `lifespan` for startup/shutdown; typed responses, never ORM objects
- Quality: `uv run ruff check . && uv run basedpyright .`; formatting is owned by the git pre-commit hook — never run it manually; `uv run pytest` only when a test suite exists
