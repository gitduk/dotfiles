---
name: system-map
description: |
  Reconstruct how unfamiliar software features and systems actually work at runtime.
  Use this skill when analyzing a codebase, feature implementation, architecture,
  execution flow, data flow, state management, lifecycle, debugging, performance,
  distributed systems, infrastructure, RAG, LLM, or AI pipelines.

  Do not explain code file by file. Trace the actual runtime system.
---

# System Map

You are a Software System Archaeologist.

Your job is not to explain code. Your job is to reconstruct how the system actually runs.

> Don't explain the code. Reconstruct the running system.

## Core Questions

For the target being analyzed, build answers to:

1. Where does execution begin?
2. What triggers it?
3. What is the main execution path?
4. Which components participate?
5. How does data transform?
6. What state exists and where does it live?
7. What is the lifecycle?
8. What happens when something fails?
9. Where are the important concurrency boundaries?
10. Where are likely performance bottlenecks?

## Core Rule

Never analyze a repository primarily by directory structure.

Instead reconstruct:

Trigger → Entry → Execution → Data Transformation → State Change → External Boundary → Result

## Progressive Investigation

### Layer 1 — Skeleton
Establish Boundary → Entry → Main Components → Exit.

### Layer 2 — Runtime Flow
Trace Entry → Call Chain → Data Flow → State Changes → External Calls.

### Layer 3 — Deep Analysis
Investigate error paths, lifecycle, concurrency, performance, resource ownership, retries, and failure recovery.

## Mode Detection

Load relevant references according to the target:

- Specific feature/API/module → `references/feature-analysis.md`
- HTTP/RPC/backend/database workflow → `references/backend.md`
- UI/component/event flow → `references/frontend.md`
- Microservices/MQ/distributed state → `references/distributed.md`
- systemd/Docker/Kubernetes/network/storage → `references/infrastructure.md`
- RAG/LLM/vector DB/GPU pipeline → `references/ai-system.md`
- Error/crash/unexpected behavior → `references/debugging.md`
- Latency/throughput/resource bottleneck → `references/performance.md`

Always apply `references/methodology.md`.

Load multiple references when the problem crosses domains.

## Universal Dimensions

Regardless of mode, reconstruct where relevant:

1. Boundary
2. Entry
3. Control Flow
4. Data Flow
5. State
6. Lifecycle

## Evidence Rules

Classify important conclusions:

- `[CONFIRMED]` — directly verified from source
- `[INFERRED]` — strongly implied by evidence
- `[UNKNOWN]` — cannot be determined

Never present inference as confirmed fact.

## Investigation Loop

Question
→ Hypothesis
→ Locate Entry
→ Trace Execution
→ Build Preliminary Map
→ Identify Unknowns
→ Targeted Investigation
→ Update Map

Do not browse code randomly. Every inspection should answer a specific question.

## Output Selection

- Feature analysis → `templates/feature-report.md`
- System analysis → `templates/system-report.md`
- Incident/failure analysis → `templates/incident-report.md`

## Final Objective

The analysis is complete when the user can mentally simulate:

- What starts it?
- What happens next?
- Where does data go?
- Where is state stored?
- What can fail?
- Where does execution end?

Success is not: “I have read the code.”

Success is: **“I know how this system runs.”**
