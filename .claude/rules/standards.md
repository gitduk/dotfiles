# Standards

Non-default conventions only — Claude's built-in judgment covers the rest.

## Code Style

- Prefer immutability: return new objects, avoid mutation unless language-specific performance guidance requires it
- Markers: `TODO(context):` for gaps, `FIXME:` for bugs, `SAFETY:` for unsafe blocks

## Testing

- Mocks are for external I/O only (network, DB, filesystem); never mock your own modules
- Quality gates before every commit: run your language's formatter, linter, type checker, and tests

## Security

- Audit deps regularly: `cargo audit` (Rust), `uv run pip-audit` (Python)
- Never `verify=False` or `danger_accept_invalid_certs(true)` on outbound HTTP calls
- Provide `.env.example` with dummy values; `.env` gitignored
