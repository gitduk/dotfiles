# Performance Analysis

Performance analysis begins with decomposition.

Do not analyze “the system is slow” as one problem.

## Latency Decomposition

Total Latency =

Queue
+ CPU
+ Network
+ Disk
+ Lock Wait
+ GPU
+ External Service

## Critical Path

Find the actual critical path:

Request
→ Queue
→ Database
→ Embedding
→ LLM Prefill
→ Decode
→ Response

Optimize the dominant stage first.

## Throughput Model

Identify:

- Arrival rate
- Processing rate
- Concurrency
- Queue length

If arrival rate > processing rate:

Queue Growth → Latency Growth → Resource Exhaustion

## Resource Classification

Classify expensive operations:

- CPU Bound
- Memory Bound
- Disk Bound
- Network Bound
- GPU Bound
- Lock Bound
- Queue Bound

## Investigation Flow

Symptom → Measurement → Critical Path → Resource Attribution → Bottleneck → Optimization

Never jump directly from symptom to optimization.
