#!/usr/bin/env bash
# Block bare `cargo build` and suggest `cargo clippy` instead.
# Clippy already compiles the code, so bare build is redundant.

if ! command -v jq &>/dev/null; then
  exit 0
fi

CMD=$(jq -r '.tool_input.command // empty')

if [ -z "$CMD" ]; then
  exit 0
fi

if echo "$CMD" | grep -qP '(?<!\S)cargo\s+build\b'; then
  jq -n '{
    "decision": "block",
    "reason": "Use `cargo fmt && cargo clippy` instead of bare `cargo build`. Clippy already compiles the code."
  }'
fi
