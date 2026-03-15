# Standards

Non-default conventions only — Claude's built-in judgment covers the rest.

## Code Style

- Prefer immutability: return new objects, avoid mutation unless language-specific performance guidance requires it
- Markers: `TODO(context):` for gaps, `FIXME:` for bugs, `SAFETY:` for unsafe blocks
- Bash: build multi-line JSON with `jq -n` + heredoc, not `\n` concatenation
- Bash `set -e`: `grep -c` prints count to stdout then exits 1 on zero matches; `|| echo "0"` appends a second "0" — use `|| true` to suppress the exit code without duplicating output

## Testing

- Mocks are for external I/O only (network, DB, filesystem); never mock your own modules
- Quality gates before every commit: run your language's formatter, linter, type checker, and tests

## Security

- Audit deps regularly: `cargo audit` (Rust), `uv run pip-audit` (Python)
- Never `verify=False` or `danger_accept_invalid_certs(true)` on outbound HTTP calls
- Provide `.env.example` with dummy values; `.env` gitignored

## Tool Usage

- WebSearch: Use WebFetch as alternative if WebSearch fails to accept query parameter
- Memory files: Save to `~/.claude/projects/<project>/memory/`, not `~/.claude/memory/`
