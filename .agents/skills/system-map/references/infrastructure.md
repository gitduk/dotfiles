# Infrastructure Analysis

Infrastructure analysis focuses on:

Ownership, Lifecycle, Resources, Boundaries.

## Process Ownership

Always determine:

- Who starts the process?
- Who owns it?
- Who monitors it?
- Who restarts it?
- Who stops it?

Example:

systemd → Gunicorn master → Workers

## Lifecycle

Configuration
→ Process Creation
→ Initialization
→ Ready
→ Serving
→ Shutdown Signal
→ Graceful Shutdown
→ Cleanup

## Resource Ownership

For CPU, Memory, GPU, Disk, Network, Port, and File Descriptors ask:

- Who allocates it?
- Who owns it?
- Who releases it?
- When is it released?

## Containers

Trace:

Image → Container → Process → Namespace → Volume → Network

Do not confuse container lifecycle with process lifecycle.

## Kubernetes

Trace:

Manifest → API Server → Scheduler → Node → Container Runtime → Container → Application Process

For failures compare:

Desired State vs Actual State

## Infrastructure Debugging

Always build a timeline:

T0 Start → T1 Allocation → T2 Ready → T3 Load → T4 Error → T5 Restart

Many infrastructure problems are lifecycle problems disguised as configuration problems.
