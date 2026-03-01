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

- Always use connection pools; never create a new connection per request
- All database access goes through a repository layer — handlers and services never touch the DB client directly
- Treat database errors as domain errors: map them to meaningful types at the repository boundary, don't let raw driver errors bubble up to API responses
- Never log full query results containing PII or secrets; log query intent and duration instead

## SQL (MySQL / PostgreSQL)

### Connection Pool

```rust
// Rust — sqlx
let pool = PgPoolOptions::new()
    .max_connections(20)
    .acquire_timeout(Duration::from_secs(3))
    .connect(&database_url)
    .await?;
```

- Set `max_connections` explicitly; never use the default (often unbounded)
- Set `acquire_timeout` to fail fast under load rather than queue indefinitely
- Pass `Pool` as shared state (`Arc<Pool>` or `State<PgPool>` in Axum); never clone it per request

### Query Safety

- Always use parameterized queries — never interpolate user input into SQL strings
- Use `sqlx::query!` / `sqlx::query_as!` macros for compile-time query verification where possible
- For dynamic queries (variable WHERE clauses), build with a query builder, not string concatenation

```rust
// Good — parameterized
sqlx::query_as!(User, "SELECT * FROM users WHERE id = $1", user_id)
    .fetch_one(&pool)
    .await?;

// Bad — injection risk
let sql = format!("SELECT * FROM users WHERE id = {user_id}");
```

### N+1 Prevention

- Never query inside a loop; fetch related data in bulk with `IN (...)` or a JOIN
- When loading a list with associations, use two queries (list + batch fetch) rather than N+1

```rust
// Bad — N+1
for user in users {
    let orders = fetch_orders(user.id).await?;
}

// Good — batch
let user_ids: Vec<i64> = users.iter().map(|u| u.id).collect();
let orders = sqlx::query_as!(
    Order,
    "SELECT * FROM orders WHERE user_id = ANY($1)",
    &user_ids
)
.fetch_all(&pool)
.await?;
```

### Indexes & Schema

- Every foreign key column must have an index
- Columns used in `WHERE`, `ORDER BY`, or `JOIN ON` clauses in frequent queries need indexes
- Prefer narrow indexes; avoid indexing columns with very low cardinality (e.g. boolean flags)
- Add indexes in a separate step from table creation in production — `CREATE INDEX CONCURRENTLY` to avoid locking
- Always define `NOT NULL` constraints unless NULL is genuinely meaningful for the column
- Use `BIGINT` / `i64` for primary keys; avoid `INT` for tables that may grow large

### Transactions

- Wrap multi-step writes in a transaction; never leave the DB in a partial state
- Keep transactions short — acquire late, release early; don't hold a transaction open across network calls
- Read-only queries don't need transactions unless you need snapshot consistency

```rust
let mut tx = pool.begin().await?;
sqlx::query!("UPDATE accounts SET balance = balance - $1 WHERE id = $2", amount, from_id)
    .execute(&mut *tx)
    .await?;
sqlx::query!("UPDATE accounts SET balance = balance + $1 WHERE id = $2", amount, to_id)
    .execute(&mut *tx)
    .await?;
tx.commit().await?;
```

### Performance

- Use `EXPLAIN ANALYZE` to verify query plans before deploying queries on large tables
- Avoid `SELECT *` in production code — select only the columns you need
- Use `LIMIT` on all user-facing list queries; never return unbounded result sets
- For bulk inserts, use `INSERT INTO ... VALUES ($1, $2), ($3, $4), ...` or `COPY` — not one insert per row

---

## Elasticsearch

### Index Design

- Define explicit mappings before indexing data; never rely on dynamic mapping in production
- Use `keyword` for exact-match fields (IDs, status enums, tags); use `text` with appropriate analyzer for full-text search
- Disable `_source` only if storage is critical and you never need to retrieve original documents
- Plan index aliases from day one — alias points to the real index, enabling zero-downtime reindexing

```json
// Mapping example
{
  "mappings": {
    "properties": {
      "id":      { "type": "keyword" },
      "status":  { "type": "keyword" },
      "content": { "type": "text", "analyzer": "ik_max_word" },
      "created_at": { "type": "date" }
    }
  }
}
```

### Query Patterns

- Use `filter` context (not `query` context) for exact matches and range filters — filters are cached and faster
- Use `query` context only for full-text search where relevance scoring matters
- Always paginate with `search_after` + `sort` for deep pagination — avoid `from/size` beyond 10,000 results
- Set explicit `size` limits on all search requests; the default (10) is often wrong and silent

```json
// Good — filter for exact match, query for relevance
{
  "query": {
    "bool": {
      "filter": [{ "term": { "status": "active" } }],
      "must":   [{ "match": { "content": "search term" } }]
    }
  }
}
```

### Bulk Operations

- Use the Bulk API for all write-heavy operations; never index documents one by one in a loop
- Handle partial failures in bulk responses — the API returns 200 even when some items fail
- Set `refresh=false` (default) for bulk indexing; only use `refresh=true` / `wait_for` in tests

### Resource Management

- Always close scroll contexts after use; leaked scrolls consume heap on the cluster
- Set `timeout` on all search requests to prevent runaway queries from blocking the thread pool
- Monitor shard count — too many small shards degrade performance; aim for shard size 10–50 GB

---

## Milvus / Vector Database

### Collection Design

- Define the schema explicitly: field names, data types, vector dimension — don't use dynamic schema
- Choose the index type based on your trade-off: `IVF_FLAT` for accuracy, `HNSW` for speed, `IVF_SQ8` for memory efficiency
- Store only the vector and a reference ID in Milvus; keep metadata in the relational DB and join at query time

```python
# Good — lean schema, metadata stays in MySQL
fields = [
    FieldSchema("id", DataType.INT64, is_primary=True),
    FieldSchema("embedding", DataType.FLOAT_VECTOR, dim=1536),
]
```

### Search

- Always set `nprobe` (IVF) or `ef` (HNSW) search params explicitly — defaults are often too low for production accuracy
- Use `output_fields=["id"]` and fetch full data from the relational DB; avoid storing large payloads in Milvus
- Combine vector search with scalar filtering using `expr` to narrow the candidate set before ANN search

### Bulk Insert

- Use `insert` in batches (1,000–10,000 vectors); single-row inserts are inefficient
- Call `flush()` after bulk inserts if you need the data immediately searchable; otherwise let auto-flush handle it
- Load the collection into memory (`load()`) before searching; unload when not in use to free GPU/CPU memory

---

## Redis

### Key Design

- Use structured key names with separators: `{entity}:{id}:{field}` — e.g. `user:123:session`, `rate:ip:1.2.3.4`
- Always set TTL on cached data; never store without expiry unless the data is truly permanent
- Document the key schema in code comments or a `keys.md` file — Redis has no schema enforcement

### Usage Patterns

- Use Redis for: caching, rate limiting, session storage, pub/sub, distributed locks — not as a primary database
- For caching: cache-aside pattern (read from cache → miss → read from DB → write to cache); invalidate on write
- For distributed locks: use `SET key value NX PX ttl` — always set expiry to prevent deadlock on crash

```rust
// Cache-aside in Rust
async fn get_user(id: i64, redis: &Redis, db: &PgPool) -> Result<User> {
    let key = format!("user:{id}");
    if let Some(cached) = redis.get::<Option<String>>(&key).await? {
        return Ok(serde_json::from_str(&cached)?);
    }
    let user = sqlx::query_as!(User, "SELECT * FROM users WHERE id = $1", id)
        .fetch_one(db)
        .await?;
    redis.set_ex(&key, serde_json::to_string(&user)?, 300).await?;
    Ok(user)
}
```

### Data Safety

- Don't store sensitive data (passwords, tokens, PII) in Redis without encryption — Redis is often less secured than the primary DB
- Use `MULTI/EXEC` transactions for atomic multi-key operations
- In production, always enable `requirepass` and use TLS; never expose Redis port publicly
