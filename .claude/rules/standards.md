# Standards

Non-default conventions only — Claude's built-in judgment covers the rest.

## Code Style

- Prefer immutability: return new objects, never mutate in place
- Markers: `TODO(context):` for gaps, `FIXME:` for bugs, `SAFETY:` for unsafe blocks

## Testing

- Mocks are for external I/O only (network, DB, filesystem); never mock your own modules
- Quality gates before every commit — see `rust.md` / `python.md` for language-specific commands

## Security

- Audit deps regularly: `cargo audit` (Rust), `uv run pip-audit` (Python)
- Never `verify=False` or `danger_accept_invalid_certs(true)` on outbound HTTP calls
- Provide `.env.example` with dummy values; `.env` gitignored
