---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
  - "**/uv.lock"
  - "**/requirements*.txt"
---

- **[uv-project]** Project: `uv` for deps and scripts (`uv run`); commit `uv.lock`; pin `requires-python`
- **[py-abs-paths]** Paths ([no-cwd-relative-paths]) — the Python mechanism: `Path(__file__).parent`
- **[typed-signatures]** Types: all signatures typed; `X | None` over `Optional[X]`
- **[domain-exceptions]** Errors: domain exceptions from base `AppError`; FastAPI global handler
- **[async-libs-only]** Async: async libs only (`httpx`, `aiosqlite`, `asyncpg`); `asyncio.to_thread` to escape a sync call; `asyncio.gather` for concurrent
- **[fastapi-annotated]** FastAPI: `Annotated` for deps/validation, Pydantic v2 for models
- **[fastapi-lifespan]** FastAPI lifecycle: `lifespan` for startup/shutdown; responses typed, never raw ORM objects
- **[py-qa]** Quality: `uv run ruff check . && uv run basedpyright .`; `uv run pytest` per [tests-only-when-suite]; formatting per [fmt-owned-by-precommit]
