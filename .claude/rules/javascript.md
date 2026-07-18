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

Prefer the LSP tool for symbol queries — findReferences, incomingCalls/outgoingCalls, goToDefinition, workspaceSymbol. Structural shape queries ("all code shaped like `require($M)`") → ast-grep (installed at `~/.local/bin`). Grep is for plain-text search only (string literals, comments, config keys).

    if LSP returns few results all in the queried file: likely cold start, not the true answer — tsserver answers from a partially loaded project; wait ~15s and requery before trusting  # JS cold start yields plausible-looking PARTIAL results, unlike rust/python's obvious empty
    if LSP returns empty: verify a server is running AND its cwd is this project (pgrep -f typescript-language-server; readlink /proc/<pid>/cwd)  # never silently fall back to grep
