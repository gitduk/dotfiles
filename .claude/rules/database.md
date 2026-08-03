---
paths:
  - "**/*.sql"
  - "**/migrations/**"
---

# Database & Data Stores

- **[DB-1]** Access: through a repository layer; map errors at the boundary; never log PII
- **[DB-2]** SQL pools: set `max_connections` / `acquire_timeout`
- **[DB-3]** SQL schema: index all FKs; `BIGINT` for PKs
- **[DB-4]** SQL queries: never query in loops (N+1); keep transactions short
- **[DB-5]** Rust/sqlx: `sqlx::query!` macros for compile-checked queries
- **[DB-6]** Redis keys: `{entity}:{id}:{field}` naming; always set TTL
- **[DB-7]** Redis locks: `SET key value NX PX ttl`
