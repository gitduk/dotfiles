# System Map Methodology

## Runtime Over Structure

Repository structure describes organization. Runtime flow describes behavior.

Prefer:

Trigger → Entry → Processing → Side Effect → Result

over directory tours and file-by-file descriptions.

## Find the Execution Spine

Every system has a primary causal chain:

Trigger → Entry → Primary Operation → Important Decision → Side Effect → Result

Find this first. Ignore secondary branches until the spine is understood.

## Follow Data, Not Just Functions

At every important boundary ask:

- What data enters?
- What data leaves?
- What changed?
- Who owns it?
- Where does it live?
- How long does it live?

Represent transformations explicitly:

Raw Input → Request DTO → Domain Object → Persistent Record → Response DTO

## State Is More Important Than Variables

Look for meaningful state:

- Database records
- Caches
- Sessions
- Global singletons
- Connection pools
- Queues
- Files
- Process state
- GPU memory

For each state identify:

Owner, Location, Creation, Mutation, Read Path, Deletion, Lifetime.

## Every Boundary Changes the Problem

Mark transitions:

- Process → Database
- Process → Network
- CPU → GPU
- Memory → Disk
- Service → Queue
- Application → Framework

At boundaries investigate serialization, timeout, retry, failure, latency, and consistency.

## Build Maps Before Details

Always work:

Skeleton → Flow → State → Details

Do not start with random implementation details.

## Reconstruction Loop

1. Define the question.
2. Find the trigger.
3. Find the real entry.
4. Build the execution spine.
5. Build a preliminary map.
6. List unknowns.
7. Investigate unknowns deliberately.
8. Update the map.

## Evidence Discipline

Use:

- `[CONFIRMED]` Direct source evidence.
- `[INFERRED]` Strong architectural inference.
- `[UNKNOWN]` Insufficient evidence.

## Stopping Rule

Stop expanding when these are understood:

Trigger, Entry, Execution Spine, Data Flow, State, External Boundaries, Exit.

Go deeper only for unanswered questions.

## Mental Simulation Test

The analysis is complete only if the reader can answer:

“If X happens, what receives it, what runs next, what data changes, what state changes, what external resource is touched, and what result returns?”
