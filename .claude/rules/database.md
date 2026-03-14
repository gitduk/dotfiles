---
paths:
  - "**/*.sql"
  - "**/migrations/**"
  - "**/repository/**"
  - "**/models/**"
  - "**/db/**"
  - "**/docker-compose*.yml"
---

# Database

- All DB access through repository layer; map errors at boundary; never log PII
- SQL: set `max_connections`/`acquire_timeout` on pools; use `sqlx::query!` macros; never query in loops; index all FKs; use `BIGINT` for PKs; keep transactions short
- Elasticsearch: explicit mappings; `keyword` for exact, `text` for full-text; `filter` for exact/ranges (cached), `query` for scoring; `search_after` for deep pagination
- Redis: key naming `{entity}:{id}:{field}`; always set TTL; distributed locks `SET key value NX PX ttl`
