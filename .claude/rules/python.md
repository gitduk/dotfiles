---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
  - "**/uv.lock"
  - "**/requirements*.txt"
---

- **[R68 uv-project]** Project: `uv` for deps and scripts (`uv run`); commit `uv.lock`; pin `requires-python`
- **[R69 py-abs-paths]** Paths ([R39 no-cwd-relative-paths]) — the Python mechanism: `Path(__file__).parent`
- **[R70 typed-signatures]** Types: all signatures typed; `X | None` over `Optional[X]`
- **[R71 domain-exceptions]** Errors: domain exceptions from base `AppError`; FastAPI global handler
- **[R72 async-libs-only]** Async: async libs only (`httpx`, `aiosqlite`, `asyncpg`); `asyncio.to_thread` to escape a sync call; `asyncio.gather` for concurrent
- **[R73 fastapi-annotated]** FastAPI: `Annotated` for deps/validation, Pydantic v2 for models
- **[R74 fastapi-lifespan]** FastAPI lifecycle: `lifespan` for startup/shutdown; responses typed, never raw ORM objects
- **[R75 py-qa]** Quality: `uv run ruff check . && uv run basedpyright .`; `uv run pytest` per [R42 tests-only-when-suite]; formatting per [R41 fmt-owned-by-precommit]
