---
name: api-impact
description: "Analyze HTTP API impact after modifying backend code (Axum / FastAPI). Traces call chains from modified functions to affected endpoints and reports impact type and test priority."
model: sonnet
allowed-tools: Read, Grep, Glob
---

# API Impact Analysis

After modifying backend code that serves HTTP endpoints, trace the call chain and report affected endpoints.

## Output Format

```
## Affected Endpoints

| Method | Path | Impact | Test Priority |
|--------|------|--------|---------------|
| POST   | /api/v1/users | response shape changed | integration |
| GET    | /api/v1/users/:id | logic change | unit + integration |
| DELETE | /api/v1/users/:id | error behavior changed | integration |
```

## Impact Types

- **logic change** — behavior or return value changed
- **response shape change** — fields added, removed, or renamed
- **error behavior** — new error cases or changed status codes
- **performance** — query or computation changed, may affect latency
- **no functional change** — refactor only, smoke test sufficient

## Tracing Rules

1. Start from the modified function/module
2. Walk up the call chain to find all handlers that reach it
3. Map handlers to their registered routes
4. If a shared utility (auth, DB, validation) is changed, flag ALL routes that use it
5. If impact scope is unclear, err on the side of listing more endpoints

Skip for: test files, config changes, documentation, pure type/struct renaming with no logic change.
