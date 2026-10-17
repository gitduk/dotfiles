# AI System Analysis

AI systems should be analyzed as pipelines, not simply Input → LLM → Output.

## RAG Pipeline

User Query
→ Query Processing
→ Embedding
→ Vector Search
→ Filtering
→ Reranking
→ Context Assembly
→ Prompt Construction
→ LLM Inference
→ Post Processing
→ Response

For each stage determine:

- Input type
- Output type
- Model/component
- CPU/GPU usage
- Latency
- State
- Cache
- Failure behavior

## Data Ingestion Pipeline

Raw Document
→ Parse
→ Clean
→ Chunk
→ Metadata
→ Embedding
→ Vector Storage
→ Index

Ask:

- Where is the source of truth?
- Where is intermediate data stored?
- When is data durable?
- When does indexed data become visible?

## LLM Inference

Analyze:

Request
→ Tokenizer
→ Scheduler
→ Prefill
→ KV Cache
→ Decode
→ Sampling
→ Detokenization
→ Response

Track separately:

CPU, GPU, VRAM, KV Cache, Model Weights, Batch, Queue.

## GPU Memory

Distinguish:

- Model weights
- KV cache
- Activations / temporary memory
- CUDA graphs
- Communication buffers

Do not stop at “GPU memory is full.” Identify which category grows.

## Vector Database

Typical lifecycle:

Insert → Growing Data → Flush → Persistent Storage → Compaction → Index Build → Query

Track memory, object storage, index storage, metadata, and segments.

## AI Performance

Decompose latency:

Queue + Preprocessing + Embedding + Retrieval + Reranking + Prefill + Decode + Post Processing

Never optimize “LLM latency” as a single opaque number.
