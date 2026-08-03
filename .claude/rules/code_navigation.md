## Picking the tool [NAV-1]

| Query | Tool |
|---|---|
| Semantic relations of a symbol (definition, references, call chain, trait impls) | LSP |
| Structural shape (`$X.unwrap()` and friends) | `ast-grep` — **not `sg`**, that is the system setgid binary |
| Plain text (string literals, comments, config keys, log formats) | Grep |

LSP operations: `goToDefinition` `findReferences` `hover` `documentSymbol` `workspaceSymbol`
`goToImplementation` `prepareCallHierarchy` `incomingCalls` `outgoingCalls`.
`goToImplementation` answers "who implements this trait"; `documentSymbol` maps a file
without reading it.

## Grep feeds LSP, it does not compete with it [NAV-2]

Every LSP operation needs `filePath` + `line` + `character`. Except for `workspaceSymbol`,
you must already know where the symbol sits — grep or Read locates it, LSP then answers the
semantic question. They chain; they are not alternatives.

Renaming a symbol needs both: `findReferences` for semantic uses, grep for the ones living
in strings, comments, macros and dynamic lookups. [CFG-4] Split/rename coupling asks
for the union, not either half.

## When LSP returns nothing [NAV-3]

An empty result has two causes that look identical from the outside: there really are no
usages, or the server is not serving this project. Falling back to grep without checking
dresses "I could not look" up as "it does not exist" — so verify before believing the
emptiness:

1. Is a server running — `pgrep`, process name in each language rules file
2. Is its cwd this project — `readlink /proc/<pid>/cwd`

Trust "no usages" only after both check out.

Language rules files add the server process name and language-specific caveats.
