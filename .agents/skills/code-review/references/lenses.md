# Reviewer lenses

One prompt per lens. Paste the lens the reviewer owns, and fill `<repo>`, `<diff>`, and
`<scope>` before sending it. A subagent starts with no context, so leave nothing implicit.

Shared block, at the top of every prompt:

```
Review one change and report findings. You cannot ask questions; decide from the code.

Repository: <repo> (absolute path)
Diff: <diff> — read this file first. It is the review scope.
Scope: <one lens, or the file group this reviewer owns>

Read the diff. Then read the surrounding code it touches: callers, definitions, schema,
config. Report only what this change introduces or makes reachable, not pre-existing
problems elsewhere.

Report no findings when the change holds up. Do not pad the list.

One line per finding, nothing else:

<Critical|Major|Minor> | <file>:<line> | <issue in one sentence> | <evidence: the code or call path that shows it> | <smallest fix>

Start the evidence field with `unverified` when you could not confirm the claim from the
diff or the code you read.
```

## Security

```
Lens: security. Ignore style, performance, and naming.

Look for:
- Injection: SQL, NoSQL, shell, template, or LDAP built from input the change newly
  reaches. Check that queries stay parameterized.
- XSS: unescaped output, innerHTML, dangerouslySetInnerHTML, a route that skips the
  framework's escaping.
- Authentication and authorization: a fetched object used without an ownership or tenant
  check (IDOR), a role, user id, or price taken from the client, a check that runs after
  the side effect.
- Secrets in code, fixtures, logs, or error responses.
- Deserialization of untrusted input, path traversal from a request value, SSRF, open
  redirect, unquoted shell argument.
- Crypto: homegrown crypto, ECB or a static IV, fast hash for passwords, comparison that
  leaks timing.
- Fail-open handling: a permission or validation check whose error path allows the call.

Follow the input to the sink before calling it unsafe, and say where it is validated when
it is.
```

## Performance

```
Lens: performance. Ignore style and security.

Look for:
- Queries in a loop (N+1), or per item in a list, page, or render pass. Name the batched
  call that replaces them.
- Unbounded reads: a query or file read with no limit on a growing table or file.
- Complexity in a hot path: a nested scan over the same collection, an O(n^2) join in
  application code, sorting or a full scan inside a loop.
- Repeated work per call: a constant rebuilt, a config or regex compiled, a connection
  opened, a serialization done twice.
- Blocking work on an async or request path: sync file I/O, sleep, a CPU loop.
- Leaks and unbounded growth: timer, listener, subscription, or watcher added per call and
  never removed; a cache with no eviction; an array that only appends.
- Round trips: one request per item where the API takes a batch.

State the cost in a unit a reader can check: requests per call, work per item, bytes kept
alive. Say "unverified" when the call pattern depends on code you could not read.
```

## Correctness

```
Lens: correctness. Ignore style and naming.

Look for:
- Edge cases the change misses: empty collection, null or undefined, zero, negative,
  duplicate, very long input, a value at the boundary.
- Off-by-one in slices, ranges, pagination, retries, and loop bounds.
- Errors that vanish: a catch that returns a default, an ignored rejection, a failed write
  reported as success, a partial update with no transaction or rollback.
- Concurrency: check-then-act on shared state, a read-modify-write with no lock, a value
  cached across an await, a mutation of an object another caller holds.
- Async plumbing: an unawaited call, a fire-and-forget that loses its error, an ordering
  assumption between two awaits.
- Contracts: a changed return shape, status code, or ordering that a caller depends on.
  Grep the callers.
- Numbers and time: integer division, float equality, rounding on money, timezone and DST,
  a duration in the wrong unit.
- Parsing: a format assumed rather than validated, locale-dependent parse.

Name the input that breaks it. "May fail" is not a finding.
```

## Maintainability and tests

```
Lens: maintainability and tests. Ignore security.

Look for:
- Re-implementation: grep for the job by what it does, not by the name the change gave it,
  and name the existing helper to call.
- Naming and structure: a name that hides what the caller gets, a file or type now doing a
  second job, a flag parameter that splits one function into two behaviors.
- Dead weight: unused code, debug prints, commented-out blocks, a branch nothing reaches.
- Error messages and logs that omit the path, id, or value that failed.
- Comments that restate the code or contradict it after the change.
- Tests: changed behavior with no test, a fix with no regression test, a test asserting a
  constant or a glyph instead of the logic, a skipped or disabled test left behind.
- Trust boundaries: a new input that reaches storage or a child process unvalidated.

Prefer a finding that names the smaller shape ("two implementations of one job: call
`formatSize` at `src/util/bytes.ts:12`") over a general complaint.
```
