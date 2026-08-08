---
paths:
  - "**/package.json"
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---

# JS/TS

- **[tsserver-cold-start]** LSP returns few results, all inside the queried file → suspect cold start before trusting it: tsserver answers from a partially loaded project, and a partial answer looks like a real one (no empty result to tip you off). Check `pgrep -f typescript-language-server`, wait ~15s, requery.
