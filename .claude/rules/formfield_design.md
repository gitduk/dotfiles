# FormField Design

When a UI/input struct carries fields or flags that are only meaningful in some contexts, do not force every caller to construct the full shape. Prefer purpose-specific constructors or split the type.

**Why:** Reusing one over-broad type across distinct contexts turns it into a god object: call sites carry irrelevant fields, intent becomes blurry, and names drift toward implementation details instead of actual meaning.

**How to apply:** If a shared type serves distinct use cases, either split it into narrower types or provide specialized constructors that set sensible defaults for each context. Name fields by intent rather than mechanism, and challenge any field whose meaning only makes sense inside one caller.
