# Standards

Non-default conventions only — Claude's built-in judgment covers the rest.

## Code Style

- Bash: build multi-line JSON with `jq -n` + heredoc, not `\n` concatenation
- Bash `set -e`: `grep -c` exits 1 on zero matches; use `|| true` to suppress, not `|| echo "0"` (which duplicates output)

## Security

- Audit deps regularly: `cargo audit` (Rust), `uv run pip-audit` (Python)
- Never `verify=False` or `danger_accept_invalid_certs(true)` on outbound HTTP calls

## Tool Usage

- WebSearch: Use WebFetch as alternative if WebSearch fails to accept query parameter
