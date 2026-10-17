---
name: api-impact
description: Check the current diff (or a given target) for breaking or degrading impact on existing interfaces — response shape, semantics, request contract, wire format, and performance
argument-hint: "[PR-URL | branch | path]"
---
You are auditing **impact on existing consumers**. The question is not "is this
code good" but "does an already-deployed caller that worked yesterday still work
today, and still work as fast". You are reporting, not applying fixes.

## Phase 0 — Gather the diff

Review target: ${@:-(none given)}

If a target is named above (a PR number, branch name, or file path), review that
target and treat it as the review scope.

Otherwise run `git diff @{upstream}...HEAD` (or `git diff main...HEAD` /
`git diff HEAD~1` if there's no upstream) to get the unified diff under review.
If there are uncommitted changes, or the range diff is empty, also run
`git diff HEAD` and include the working-tree changes in scope — the audit often
runs before the commit. Treat that diff as the review scope.

## Phase 1 — Map the interface surface

List every **existing** contract the diff reaches. An interface here is anything
a party outside the change already depends on:

- HTTP routes / RPC / GraphQL resolvers — path, method, params, response body,
  status codes, headers
- Exported functions, types, traits and public class members of a library or SDK
- CLI commands, flags, positional args, exit codes, stdout/stderr format
- Serialized payloads that cross a process boundary: events, queue messages,
  cache entries, on-disk or on-wire formats
- DB schema and migrations, config keys and their defaults, environment
  variables

For each, find who consumes it: grep the repo for the symbol/route/flag, check
client code, tests, fixtures, generated schemas (OpenAPI/proto/JSON Schema),
docs. Note when a consumer is outside this repo and therefore invisible to
`grep` — that raises severity, it does not lower it.

**Purely new** surface (a route, field, or flag that did not exist before) is out
of scope: nothing depends on it yet. If the diff touches no existing interface,
say so in one line and stop — do not manufacture findings.

## Phase 2 — Run the machine check first

Before reasoning by hand, use whatever the repo already gives you. A schema
differ encodes hundreds of rules you would otherwise have to remember, and its
output is evidence rather than opinion. Check for the artifact, and if the tool
is installed (or trivially runnable via `npx`/`uvx`/`go run`), diff the target
revision against the base:

| Artifact in repo | Tool | Invocation shape |
|---|---|---|
| OpenAPI / Swagger spec | `oasdiff` | `oasdiff breaking <base.yaml> <head.yaml>` |
| `.proto` files | `buf` | `buf breaking --against '.git#branch=<base>'` |
| GraphQL SDL | `graphql-inspector` | `graphql-inspector diff <base> <head>` |
| Rust public crate API | `cargo-semver-checks` | `cargo semver-checks check-release` |
| Java jar / TS package | `japicmp` / `api-extractor` | per project config |

Do not add a new dependency just to run one of these; skip and say so if none is
available. **Tool silence is not proof of compatibility** — every one of these
has known gaps (e.g. `cargo-semver-checks` does not catch a changed field or
parameter *type*), and none of them sees semantics or performance at all. The
tool prunes Phase 3's work; it does not replace it.

If the repo generates its schema from code, regenerate it and diff the generated
file — an unregenerated schema is itself a finding.

## Phase 3 — Audit (5 angles)

Work each angle in turn over the surface list from Phase 1.

### Angle A — response / return shape

- Field removed, renamed, or retyped (`int` → `string`, scalar → object, single
  → array, `oneOf` wrapper added).
- Field that may now be absent, or `null` where it never was; a required
  property downgraded to optional.
- **Type generalized**, not just narrowed — widening a response type breaks
  clients that parse it into a narrow one, exactly as narrowing breaks writers.
- Enum / status value **added**: old clients hit an unhandled branch. Not a
  crash, but a behavior change — this is the classic `risky` finding.
- Error shape: status code, body layout, an exception type callers catch by name,
  a wrapper added or removed (`{data: …}`).
- Pagination, ordering, default page size, numeric precision, timestamp format.
- **Additions are not automatically safe.** A strict consumer — protobuf,
  generated clients, `serde` with `deny_unknown_fields`, a JSON Schema with
  `additionalProperties: false` — fails on an unknown field. Check which side is
  strict before ruling an addition safe.

### Angle B — request contract

Ask: what request did a caller send yesterday that now returns 4xx?

- A parameter became required, or lost its default.
- Constraint tightened — be specific, these are the ones that slip through:
  `max` decreased, `min` increased, `maxLength`/`minItems` changed, a `pattern`
  or `format` added, an enum value removed from an accepted set, a nullable
  input made non-nullable.
- An accepted value, alias, or legacy spelling dropped.
- Auth, scope, or permission newly demanded.
- A body-size, rate, or timeout limit lowered.
- A request property removed: the server ignores it now, so a caller that still
  sends it silently loses the effect it used to have.

### Angle C — semantics under an unchanged shape

The most dangerous class, because types check out and tests pass. No schema
differ detects any of it. Read the code path, not the signature.

- Same field, different meaning: unit (ms vs s, bytes vs KB), timezone,
  currency, absolute vs relative, inclusive vs exclusive bound, 0- vs 1-based.
- Sort order or tie-breaking changed; filtering now excludes rows it included.
- An operation that was idempotent no longer is; retry or dedup behavior changed.
- A side effect added or removed (a write, an email, a cache invalidation).
- A default value flipped, or a computed field's formula changed.
- Concurrency/ordering: work moved to async so a caller that read its result
  immediately after now races it.

### Angle D — performance and resource cost

Count the work per call, before vs after:

- Extra round trips: a query inside a loop (N+1), a new synchronous HTTP/RPC
  call, a lock or transaction held longer, a fan-out that scales with input size.
- A cache, index, batch, or short-circuit removed or now missed — including an
  index that a changed `WHERE`/`ORDER BY` no longer matches.
- Blocking or CPU-heavy work added to an async path, a request handler, or
  startup.
- Response payload growth: a newly-embedded relation, an unbounded list, a
  removed `limit` — both bytes on the wire and memory to build it.
- Algorithmic complexity change on a path whose input can grow (O(n) → O(n²)).

State the cost as a countable quantity — "1 query becomes 1 + N, N = number of
items in the response" — never as an adjective.

**Measurement discipline.** If the repo has a benchmark, load test, or timing
harness, run it on both the base and the head revision, not just head. A single
timing is noise, not evidence: take repeated runs and compare distributions
(p50/p95/p99), and report the percentile that matters for that path rather than
a mean. Treat a >15% regression at p95 as `degrading` and a >30% regression as
`breaking` for a latency-sensitive path, unless the repo states its own budget —
if it does, that budget wins. With no harness available, say so and give the
countable cost as `inferred`; do not invent a number.

### Angle E — rollout, migration, and deprecation

- **Mixed versions.** Old and new run simultaneously during a rolling deploy:
  does a new server still answer an old client, and an old server a new client?
- **DB migrations** must be backward-compatible with the currently-deployed
  code — a dropped or renamed column breaks the old binary mid-deploy. The safe
  shape is expand/contract: add the new column and dual-write, migrate readers,
  drop the old column in a *later* release. Flag a single migration that expands
  and contracts at once.
- **Persisted data.** Does the new code still read entries written by the old
  version — cache values, queued messages, on-disk state, saved config? And can
  the old code still read what the new code writes, in case of a rollback?
- **Deprecation lifecycle.** Was the removed surface deprecated first, for long
  enough, with the repo's own signal (a `Deprecation`/`Sunset` header, a
  `#[deprecated]` attribute, a changelog entry, a log warning)? Deleting a live
  endpoint or symbol with no deprecation window is a finding on its own, even
  when a replacement exists.
- **Version bump.** A breaking change with no major-version bump (or no version
  bump at all, where the repo publishes an artifact) is itself a finding — the
  consumer's version pin is what protects them, and it only works if the number
  moves.

### Format-specific traps (check the ones that apply)

- **Protobuf**: field or enum number deleted without `reserved`; field name
  deleted without `reserved` (breaks JSON encoding); `json_name` changed; field
  moved into or out of a `oneof`; cardinality shift (`repeated` ↔ `map`,
  presence changes); enum value removed; `package` renamed; RPC request/response
  type or client/server streaming flag changed; idempotency level changed.
- **JSON / OpenAPI**: `additionalProperties: false` combined with a new field;
  `required` list grown; a `$ref` retargeted; a media type dropped.
- **Typed library API (Rust/Java/TS)**: a method added to a public trait or
  interface without a default (breaks every external implementor); a field added
  to a struct that callers build with a literal; a variant added to an enum that
  is not `#[non_exhaustive]` / not exhaustively-matched-safe; a type losing
  `Send`/`Sync`/`Clone`; a sealed trait unsealed or sealed; a feature flag or
  MSRV changed; a new public item colliding with a glob import.
- **CLI**: exit code reused for a different meaning; stdout format changed while
  something pipes it; a flag made mutually exclusive with another.

## Phase 4 — Verify before you assert

Separate **verified** from **inferred**. For each candidate, take the cheapest
available proof and prefer it over reasoning:

- Run the existing test suite if one exists, and name any test whose assertion
  the diff had to change — an edited assertion in an existing test is direct
  evidence of a contract change, and one of the strongest signals available.
- Quote the schema-differ output from Phase 2 where it fired.
- Exercise the interface if it is cheap locally (call the function, hit the
  endpoint, run the CLI on both revisions).

Do not run destructive commands, and do not touch a live or shared environment.
Anything you could not check, keep — but mark it `inferred` and say what
observation would settle it. Drop a candidate only when you can point at the
line that disproves it.

## Output

输出全部**用中文**（正文、字段标签、严重度与结论）；代码、路径、接口名、文件名、版本号等标识符原样保留。

First, one line naming the interfaces in scope and how they were checked (which
differ ran, tests run, benchmark run, reasoning only).

Then the findings, every finding a compact vertical block with one field per line, ranked most-severe first, at most 10:

```
1. [严重度:breaking] 接口: GET /v1/orders
   角度: A | 变更: total int → string
   影响: 任何把它当作 number 解析的客户端，每次响应都会抛异常
   证据: verified: tests/api_test.py:88 断言在本 diff 中被改写
   缓解: 保留 `total`，新增 `total_str`
```

`Severity`（严重度）：
- `breaking` — 原本能用的既有调用方现在失败：解析错误、请求被拒、结果错误、崩溃。
- `degrading` — 仍能工作，但可测量地变差：更多往返、更大载荷、更高延迟、保证被削弱。
- `risky` — 大概率兼容，但建立在无法验证的假设上，或未破坏调用却改变了运行时行为。schema differ 的 `WARN`、GraphQL 的 `dangerous` 变更归于此：新增枚举值、移除请求属性、输入位置上可空字段改为必填。

`Angle` 是字母（A–E）。`Evidence` 以 `verified:` 或 `inferred:` 开头。`Mitigation`（缓解）是能保持兼容的最小改动——新增字段、默认值、别名、`reserved` 编号、版本门控、expand/contract 拆分、批量或缓存——而不是“谨慎一点”。

If more than 10 findings survive, keep the 10 most severe and note how many were
dropped. If nothing survives, output just the one-line note from above, without any numbered blocks,
that the diff is compatible with existing interfaces, naming what you checked.
