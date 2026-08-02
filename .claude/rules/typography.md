# Chinese Typography (punctuation width)

Applies to all Chinese text I produce: replies, docs, commit messages, user-facing copy, and code comments when a project requires Chinese comments.

- Context test: strip the embedded code spans / English terms / numbers — if the sentence is still Chinese, punctuation is full-width (，。？！：；、""（）——). Adjacency to code is not a reason to use half-width.
- Half-width punctuation only inside genuine code syntax: backtick code spans, identifiers, file paths, version numbers, URLs, verbatim quotes.
- Separators between adjacent code spans (e.g. the comma in `a: 1`,`b: 2`) count as code syntax — keep half-width.
- Punctuation style must be uniform within a document.
