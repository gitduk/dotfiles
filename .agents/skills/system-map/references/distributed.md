# Distributed System Analysis

Distributed systems cannot be understood only through function calls.

Trace across:

Node → Process → Service → Network → Storage

## Required Maps

### Component Topology

Client
→ Gateway
→ Coordinator
→ Workers

### Request Flow

Client → RPC → Coordinator → Queue/Task → Worker

### Data Placement

For important data determine:

- Memory?
- Disk?
- Object storage?
- Replica?
- Cache?

### Ownership

Ask:

- Who owns this data?
- Who can mutate it?
- Who coordinates it?
- Who cleans it?

## Distributed State

Distinguish:

- Local State
- Shared State
- Replicated State
- Ephemeral State
- Persistent State

## Failure Analysis

Consider:

- Node failure
- Network partition
- Timeout
- Duplicate message
- Partial success
- Retry
- Leader failure

Ask: What happens if this component disappears?

## Backpressure

Trace:

Producer → Queue → Consumer

Determine arrival rate, processing rate, queue growth, and resource exhaustion.

## Data Lifecycle

Typical storage lifecycle:

Create → Buffer → Flush → Replicate → Compact → Index → Query → Delete
