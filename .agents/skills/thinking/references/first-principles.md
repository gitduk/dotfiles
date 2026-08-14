# First Principles

## Workflow

Given a problem or question:

1. **State the problem** — one sentence, as concretely as possible.

2. **Surface the assumptions** — list what is currently taken for granted. Use the prompt: "What do we assume to be true here that we've never actually verified?"

3. **Decompose to fundamentals** — strip each assumption down using "Why?" until you hit bedrock: facts that cannot be broken down further and are verifiable.

   Use the Five Whys for each assumption:
   - Why do we believe X? → Because Y
   - Why Y? → Because Z
   - (continue until the chain bottoms out at a verifiable fact or an acknowledged unknown)

4. **Rebuild** — starting only from the verified fundamentals, construct a solution without reference to how things are currently done.

5. **Compare** — contrast the rebuilt solution against the conventional approach. Name what changed and why.

## Guardrails

- Distinguish between **constraints** (physical, mathematical, legal — cannot be engineered away) and **conventions** (inherited practices that happen to be common — can be questioned).
- A first-principles analysis that reaches the same answer as convention is still valid — it just confirms the convention is grounded.
- If the decomposition hits an acknowledged unknown, name it explicitly rather than skipping it.

## Output format

- List assumptions first, then the decomposition chain for each, then the rebuilt solution.
- Keep each "Why?" chain as a short indented list.
- End with the comparison: conventional approach vs. first-principles conclusion, and what the key difference is.
