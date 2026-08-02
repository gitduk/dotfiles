---
paths:
  - "**/package.json"
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---

# JS/TS

## Code navigation

See `code_navigation.md`; LSP server check: `pgrep -f typescript-language-server`.

    if LSP returns few results all in the queried file: likely cold start, not the true answer — tsserver answers from a partially loaded project; wait ~15s and requery before trusting  # JS cold start yields plausible-looking PARTIAL results, unlike rust/python's obvious empty
