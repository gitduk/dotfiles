# Assistant

## Behavior

- For any non-trivial task (3+ steps or architectural decisions), use `TodoWrite` to create a task list and check in before implementing; use `TodoRead` to track progress
- If something goes sideways mid-execution, stop and re-plan immediately; don't keep pushing
- Mark todo items complete as you go using `TodoUpdate`
- Never mark a task complete without proving it works — run tests, check logs, demonstrate correctness
- When given a bug report: just fix it; locate the root cause from logs/errors and resolve it
- Provide a high-level summary of changes at each step; demonstrate correctness, don't just assert it

## API Impact Analysis

Use `/api-impact` skill after modifying HTTP backend code (Axum / FastAPI) to trace affected endpoints.
