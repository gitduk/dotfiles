# Security

## Secrets & Configuration

- Never hardcode secrets, API keys, tokens, or passwords anywhere in source code — not even in tests
- All secrets via environment variables or a secrets manager (Vault, AWS Secrets Manager, etc.); provide `.env.example` with dummy values
- Secrets must never appear in logs, error messages, stack traces, or HTTP responses
- Rotate secrets immediately if they appear in git history; use `git-secrets` or similar pre-commit hooks to prevent it
- Separate config from secrets: config (non-sensitive) can live in version control; secrets cannot

```bash
# .env.example — commit this
DATABASE_URL=postgres://user:password@localhost/mydb
API_KEY=your-api-key-here

# .env — gitignore this
DATABASE_URL=postgres://realuser:realpassword@prod-host/mydb
API_KEY=sk-real-key-abc123
```

## Input Validation & Trust Boundaries

- Validate and sanitize all external input at system boundaries: HTTP requests, file uploads, CLI args, API responses, DB results
- Never trust data just because it came from your own database — validate on the way out too if it reaches a security boundary
- Use schema-based validation (Pydantic, serde) — don't write manual string checks
- Reject unknown fields in request bodies by default; don't silently ignore extra input
- File uploads: validate MIME type server-side (not client-declared), check file size limits, store outside the web root

## Injection Prevention

- Never interpolate user input into SQL strings — always use parameterized queries / ORM methods
- Never pass user input to shell commands; if unavoidable, use `shlex.quote` (Python) or `std::process::Command` with args list (Rust) — never string concatenation
- Avoid `eval`, `exec`, dynamic `import`, or `deserialize` on untrusted input
- Sanitize any user content rendered in HTML; use templating engines that auto-escape by default

```python
# Good
await db.execute("SELECT * FROM users WHERE id = $1", user_id)

# Bad — SQL injection risk
await db.execute(f"SELECT * FROM users WHERE id = {user_id}")
```

## Authentication & Authorization

- Check authorization on every request — never rely on the client to omit sensitive fields
- Fail closed: deny by default; grant access explicitly
- Use short-lived tokens (JWTs with expiry); implement refresh token rotation
- Never store plaintext passwords — use bcrypt, argon2, or scrypt with appropriate work factors
- Rate-limit authentication endpoints; implement lockout or CAPTCHA after repeated failures
- Log authentication events (success, failure, token issuance) with enough context to investigate incidents — but never log the credentials themselves

## Dependency Security

- Audit dependencies regularly: `cargo audit` (Rust), `uv run pip-audit` (Python)
- Pin exact versions in lock files; review dependency updates before merging — check changelogs for security fixes
- Minimize the dependency surface: each new dependency is potential attack surface; justify additions
- Prefer well-maintained, widely-used libraries over obscure ones for security-critical functionality (crypto, auth, parsing)
- Never use abandoned crates/packages for anything touching security or data parsing

## Logging & Error Handling

- Log security-relevant events: auth attempts, permission denials, config changes, large data exports
- Never log: passwords, tokens, full credit card numbers, SSNs, PII beyond what's necessary
- In production, return generic error messages to clients; log the full detail server-side
- Use structured logging (JSON) so security events can be queried and alerted on

```python
# Good — logs the event, not the secret
logger.warning("auth_failed", user_id=user_id, ip=request.client.host, reason="invalid_token")

# Bad — logs sensitive data
logger.warning(f"auth failed for token: {token}")
```

## Network & Transport

- Use HTTPS everywhere; never accept credentials over plain HTTP even internally
- Set security headers: `Content-Security-Policy`, `X-Frame-Options`, `X-Content-Type-Options`, `Strict-Transport-Security`
- Validate TLS certificates on all outbound HTTP calls — never `verify=False` or `danger_accept_invalid_certs(true)`
- Restrict CORS to known origins; never use `*` on endpoints that handle authenticated requests

## Code Review Security Checklist

Before committing any code that touches auth, data handling, or external input:

- [ ] No secrets in code or logs
- [ ] All external input validated at the boundary
- [ ] SQL / shell commands use parameterized forms
- [ ] Authorization checked, not just authentication
- [ ] Error responses don't leak internals
- [ ] New dependencies audited
- [ ] TLS verification enabled on all outbound calls
