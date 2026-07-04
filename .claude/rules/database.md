---
paths:
  - "**/*.sql"
  - "**/migrations/**"
---

# Database & Data Stores

- All DB access through repository layer; map errors at boundary; never log PII
- SQL: set `max_connections`/`acquire_timeout` on pools; use `sqlx::query!` macros; never query in loops; index all FKs; use `BIGINT` for PKs; keep transactions short
- Redis: key naming `{entity}:{id}:{field}`; always set TTL; distributed locks `SET key value NX PX ttl`
