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

## General Principles

- All database access goes through a repository layer — handlers/services never touch the DB client directly
- Map database errors to domain error types at the repository boundary; never expose raw driver errors
- Never log full query results containing PII; log query intent and duration instead

## SQL (MySQL / PostgreSQL)

- Set `max_connections` and `acquire_timeout` explicitly on connection pools; never use defaults
- Pass `Pool` as shared state; never clone per request
- Use `sqlx::query!` / `sqlx::query_as!` macros for compile-time verification where possible
- For dynamic queries, use a query builder — never string concatenation
- Never query inside a loop; batch with `IN (...)` or JOIN
- Every foreign key column must have an index
- Use `BIGINT` / `i64` for primary keys
- Keep transactions short — acquire late, release early; don't hold across network calls
- Avoid `SELECT *` in production; select only needed columns
- Use `LIMIT` on all user-facing list queries

## Elasticsearch

- Define explicit mappings; never rely on dynamic mapping in production
- Use `keyword` for exact-match fields, `text` with analyzer for full-text search
- Use `filter` context for exact matches/ranges (cached); `query` context only for relevance scoring
- Paginate with `search_after` + `sort` for deep pagination; avoid `from/size` beyond 10k
- Use Bulk API for writes; handle partial failures in bulk responses
- Always close scroll contexts after use; set `timeout` on all search requests
- Plan index aliases from day one for zero-downtime reindexing

## Milvus / Vector DB

- Store only vector + reference ID in Milvus; metadata stays in the relational DB
- Set `nprobe` (IVF) / `ef` (HNSW) search params explicitly; defaults are too low for production
- Use `output_fields=["id"]` and fetch full data from relational DB
- Insert in batches (1k–10k vectors); call `flush()` only when immediate searchability is needed
- Load collection before search; unload when not in use to free memory

## Redis

- Key naming: `{entity}:{id}:{field}` — e.g. `user:123:session`
- Always set TTL on cached data; no expiry only for truly permanent data
- Use for: caching, rate limiting, sessions, pub/sub, distributed locks — not as primary DB
- Caching: cache-aside pattern; invalidate on write
- Distributed locks: `SET key value NX PX ttl` — always set expiry to prevent deadlock
- Never store sensitive data without encryption; always enable `requirepass` + TLS in production
