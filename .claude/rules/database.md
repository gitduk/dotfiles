---
paths:
  - "**/*.sql"
  - "**/migrations/**"
---

# Database & Data Stores

- **[R60 repository-layer]** Access: through a repository layer; map errors at the boundary; never log PII
- **[R61 pool-limits]** SQL pools: set `max_connections` / `acquire_timeout`
- **[R62 schema-indexes]** SQL schema: index all FKs; `BIGINT` for PKs
- **[R63 no-query-loops]** SQL queries: never query in loops (N+1); keep transactions short
- **[R64 sqlx-macros]** Rust/sqlx: `sqlx::query!` macros for compile-checked queries
- **[R65 redis-key-naming]** Redis keys: `{entity}:{id}:{field}` naming; always set TTL
- **[R66 redis-locks]** Redis locks: `SET key value NX PX ttl`
