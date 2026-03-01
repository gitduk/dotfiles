# Testing

- Test behavior, not implementation — tests should survive internal refactors
- Each test has one clear failure reason; test names describe the scenario: `test_login_fails_with_expired_token`
- Always test error/failure paths explicitly, not just the happy path
- Keep tests fast: unit tests < 10ms; integration tests isolated from prod systems
- Mocks are for external I/O only (network, DB, filesystem); don't mock your own modules
- Coverage is a signal, not a goal — 80% meaningful coverage beats 100% trivial coverage

## Structure: Arrange / Act / Assert

```python
def test_invoice_total_applies_discount():
    invoice = Invoice(items=[Item(price=100)], discount=0.1)  # Arrange
    total = invoice.calculate_total()                          # Act
    assert total == 90                                         # Assert
```

## Quality Gates

Run before every commit. See `rust.md` and `python.md` for language-specific commands.

- Never disable linter rules project-wide; suppress per-line only with a justification comment
- Keep dependencies minimal; add a new one only if it saves significant complexity
- Pin versions in lock files; review updates deliberately
