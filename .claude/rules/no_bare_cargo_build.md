# No Bare Cargo Build

Do not run bare `cargo build` as a compile check when `cargo clippy` is already part of the verification step.

**Why:** `cargo clippy` already compiles the code. Running `cargo build` separately is redundant, slows iteration, and wastes tokens.

**How to apply:** For routine Rust verification, prefer `cargo fmt` plus `cargo clippy` over a separate `cargo build`. Only run `cargo build` when the task specifically requires a build artifact or when `clippy` is not part of the intended check.
