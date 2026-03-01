# Assistant

## Behavior

- For any non-trivial task (3+ steps or architectural decisions), write the plan to `tasks/todo.md` with checkable items and check in before implementing
- If something goes sideways mid-execution, stop and re-plan immediately; don't keep pushing
- Mark todo items complete as you go; add a review section when done
- Never mark a task complete without proving it works — run tests, check logs, demonstrate correctness
- When given a bug report: just fix it; locate the root cause from logs/errors and resolve it
- Provide a high-level summary of changes at each step; demonstrate correctness, don't just assert it

## API Impact Analysis

After modifying any backend code (Axum / FastAPI) that serves HTTP endpoints, trace the call chain and report affected endpoints in this format. Skip if the project has no HTTP API layer.

```
## Affected Endpoints

| Method | Path | Impact | Test Priority |
|--------|------|--------|---------------|
| POST   | /api/v1/users | response shape changed | integration |
| GET    | /api/v1/users/:id | logic change | unit + integration |
| DELETE | /api/v1/users/:id | error behavior changed | integration |
```

Impact types:
- **logic change** — behavior or return value changed
- **response shape change** — fields added, removed, or renamed
- **error behavior** — new error cases or changed status codes
- **performance** — query or computation changed, may affect latency
- **no functional change** — refactor only, smoke test sufficient

Tracing rules:
1. Start from the modified function/module
2. Walk up the call chain to find all handlers that reach it
3. Map handlers to their registered routes
4. If a shared utility (auth, DB, validation) is changed, flag ALL routes that use it
5. If impact scope is unclear, err on the side of listing more endpoints

Skip this analysis for: test files, config changes, documentation, and pure type/struct renaming with no logic change.
