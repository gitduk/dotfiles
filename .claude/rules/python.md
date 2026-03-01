---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
  - "**/uv.lock"
  - "**/*.pyi"
---

# Python

## Project Setup

- Use `uv` for all dependency and environment management; never use bare `pip install` in a project context
- Pin dependencies in `pyproject.toml`; commit `uv.lock` to version control
- Use `uv run` to execute scripts in the project environment; avoid activating venv manually in CI
- Minimum Python version declared in `pyproject.toml` under `[project] requires-python`

```toml
# pyproject.toml
[project]
requires-python = ">=3.11"

[dependency-groups]
dev = ["ruff", "mypy", "pytest", "pytest-asyncio"]
```

## Type Annotations

- All function signatures must have type annotations — parameters and return types
- Use `from __future__ import annotations` at the top of every file (deferred evaluation, cleaner forward refs)
- Prefer `X | None` over `Optional[X]`; prefer `X | Y` over `Union[X, Y]` (Python 3.10+ syntax)
- Use `TypeAlias` for complex types used in multiple places; name them clearly: `UserId = NewType("UserId", int)`
- Run `mypy` in strict mode: `mypy --strict`; fix all errors, never use `# type: ignore` without a comment explaining why

## Code Style

- Formatter and linter: `ruff format` + `ruff check`; configure in `pyproject.toml`, not separate config files
- Max line length: 100 (set in ruff config)
- Imports: stdlib → third-party → local, separated by blank lines; use `ruff` isort rules to enforce
- Prefer `pathlib.Path` over `os.path` for all filesystem operations
- Use f-strings over `.format()` or `%` formatting

```toml
[tool.ruff]
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM", "TCH"]
```

## Error Handling

- Define domain-specific exceptions inheriting from a base project exception, not bare `Exception`
- Always catch specific exceptions; never use bare `except:` or `except Exception:` without re-raising or logging
- Use `contextlib.suppress` only for truly ignorable errors, with a comment explaining why
- FastAPI: define a global exception handler; never let unhandled exceptions return 500 with stack traces to clients

```python
# Good
class AppError(Exception):
    """Base exception for this project."""

class ConfigNotFoundError(AppError):
    def __init__(self, path: Path) -> None:
        super().__init__(f"Config not found: {path}")
        self.path = path
```

## Module Structure

- Organize by feature/domain, not by type: `auth/`, `billing/` — not `models/`, `routers/`, `services/`
- Keep `__init__.py` files minimal — only re-export the public API surface
- One class or closely related set of functions per file; avoid 1000-line god modules
- Use `__all__` in modules that are imported from externally

## Async

- Use `async def` consistently — don't mix sync and async in the same call stack without bridging
- Never call blocking I/O (file, DB, HTTP) from inside `async def` without `asyncio.to_thread` or an async library
- Use `asyncio.gather` for concurrent independent tasks; `asyncio.TaskGroup` (3.11+) for structured concurrency
- Always use async-native libraries: `httpx` not `requests`, `aiosqlite` not `sqlite3`, `asyncpg` not `psycopg2`

```python
# Good — concurrent independent calls
results = await asyncio.gather(
    fetch_user(user_id),
    fetch_permissions(user_id),
)
```

## FastAPI

- Use `Annotated` for dependency injection and field validation — keeps function signatures clean
- Define request/response models with Pydantic v2; never return ORM objects directly from endpoints
- Separate routers by feature; register them in `main.py` with a prefix and tags
- Use `lifespan` context manager for startup/shutdown (DB pools, HTTP clients) — not deprecated `@app.on_event`
- Return typed responses: `-> list[UserResponse]` not `-> dict`

```python
# Good
@router.get("/users/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: Annotated[int, Path(gt=0)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> UserResponse:
    ...
```

## Data Processing & AI Integration

- Validate all external data (API responses, files, DB results) with Pydantic before use
- Stream large datasets; never load everything into memory: use generators, `yield`, async iterators
- For AI API calls: always set timeouts; handle rate limits with exponential backoff; log token usage
- Isolate AI client calls behind a service interface so they can be mocked in tests

## Scripts & Automation

- Every script must have a `main()` function and a `if __name__ == "__main__":` guard
- Use `typer` or `argparse` for CLI argument parsing — never parse `sys.argv` manually
- Scripts that touch production data must have a `--dry-run` flag
- Log to stderr (`logging`), output results to stdout

## Testing

- Use `pytest` with `pytest-asyncio`; set `asyncio_mode = "auto"` in config
- Use `pytest-httpx` or `respx` to mock HTTP calls; never make real network calls in unit tests
- FastAPI: use `httpx.AsyncClient` with `app` transport for endpoint testing
- Fixtures in `conftest.py`; scope them appropriately

## Quality Gates

```bash
uv run ruff format --check .
uv run ruff check .
uv run mypy --strict .
uv run pytest
```
