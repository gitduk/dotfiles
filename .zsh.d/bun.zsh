#!/usr/bin/env zsh

if ! command -v bun &>/dev/null; then
  return 0
fi

pkgs=(
  "claude:@anthropic-ai/claude-code"
)

for item in "${pkgs[@]}"; do
  cmd="${item%%:*}"
  pkg="${item##*:}"
  if ! command -v "$cmd" &>/dev/null; then
    bun install -g "$pkg"
  fi
done
