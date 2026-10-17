# Backend System Analysis

Focus on the request lifecycle:

Client
→ Load Balancer / Server
→ Middleware
→ Router
→ Controller / Handler
→ Service
→ Repository
→ Database / External Service
→ Response

## Request Context

Track where relevant:

- Request ID
- Authentication
- Headers
- Context
- Transaction

## Validation

Trace:

Raw HTTP Input → Parse → Validation → DTO / Schema

## Business Boundary

Identify where transport concerns stop and domain logic begins.

## Persistence

Trace:

Domain Object → ORM / Query → SQL / Protocol → Database Record

Investigate:

- Transaction boundaries
- Connection ownership
- N+1 queries
- Caching
- Consistency

## Async

Determine whether work is:

- Synchronous
- Async
- Background task
- Queue-based
- Worker-based

## Response

Trace:

Domain Result → DTO → Serialization → HTTP Response

## Backend Mental Model

A backend feature is usually:

Transport → Validation → Domain Logic → Persistence/External Services → Domain Result → Transport Response
