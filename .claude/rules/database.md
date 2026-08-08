---
paths:
  - "**/*.sql"
  - "**/migrations/**"
---

# Database & Data Stores

- **[repository-layer]** Access: through a repository layer; map errors at the boundary; never log PII
- **[pool-limits]** SQL pools: set `max_connections` / `acquire_timeout`
- **[schema-indexes]** SQL schema: index all FKs; `BIGINT` for PKs
- **[no-query-loops]** SQL queries: never query in loops (N+1); keep transactions short
- **[sqlx-macros]** Rust/sqlx: `sqlx::query!` macros for compile-checked queries
- **[redis-key-naming]** Redis keys: `{entity}:{id}:{field}` naming; always set TTL
- **[redis-locks]** Redis locks: `SET key value NX PX ttl`
