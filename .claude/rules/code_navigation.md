# Code Navigation

Prefer the LSP tool for symbol queries — findReferences, incomingCalls/outgoingCalls, goToDefinition, workspaceSymbol. Structural shape queries ("all code shaped like `$X.unwrap()`") → ast-grep (installed at `~/.local/bin`). Grep is for plain-text search only (string literals, comments, config keys).

    if LSP returns empty: verify a server is running AND its cwd is this project (pgrep the server — name in each language rules file; readlink /proc/<pid>/cwd)  # both failure modes look identical to "no usages"; never silently fall back to grep

Language rules files add the server process name and any language-specific caveats.
