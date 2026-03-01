# Documentation & Comments

- Comments explain **why**, not what — the code shows what
- Every public function/struct/module gets a doc comment; private code only when non-obvious
- Stale docs are worse than no docs — update them when changing behavior
- Markers: `TODO(context):` for gaps, `FIXME:` for bugs, `SAFETY:` for unsafe blocks

## Rust

```rust
/// Loads and validates config from `path`.
///
/// Returns an error if the file is missing or the format is invalid.
pub fn load_config(path: &Path) -> anyhow::Result<Config> { ... }
```

## Python

```python
def load_config(path: Path) -> Config:
    """Load and validate config from path.

    Raises:
        FileNotFoundError: if path does not exist.
        ValueError: if the config format is invalid.
    """
```

## Project Docs

- `README.md`: setup steps, how to run tests, how to contribute — keep it current
- `docs/adr/`: one paragraph per non-obvious architectural decision is enough
- `.env` gitignored; provide `.env.example` with all keys and dummy values
- Common task scripts in `Makefile` or `scripts/`
