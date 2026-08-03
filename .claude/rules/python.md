---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
  - "**/uv.lock"
  - "**/requirements*.txt"
---

- **[PY-1]** Project: `uv` for deps and scripts (`uv run`); commit `uv.lock`; pin `requires-python`
- **[PY-2]** Paths: project files use `Path(__file__).parent` to calculate absolute paths; never use `./` relative paths (CWD-dependent)
- **[PY-3]** Types: all signatures typed; `X | None` over `Optional[X]`
- **[PY-4]** Errors: domain exceptions from base `AppError`; FastAPI global handler
- **[PY-5]** Async: async libs only (`httpx`, `aiosqlite`, `asyncpg`); `asyncio.to_thread` to escape a sync call; `asyncio.gather` for concurrent
- **[PY-6]** FastAPI: `Annotated` for deps/validation, Pydantic v2 for models
- **[PY-7]** FastAPI lifecycle: `lifespan` for startup/shutdown; responses typed, never raw ORM objects
- **[PY-8]** Security: never `verify=False` (requests / httpx) — TLS verification stays on
- **[PY-9]** Quality: `uv run ruff check . && uv run basedpyright .`; `uv run pytest` only when a test suite exists
  - formatting is owned by the git pre-commit hook — never run it manually

## Code navigation

See `code_navigation.md`; LSP server check: `pgrep -f 'langserver'`.
