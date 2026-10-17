# Feature Analysis

Use this reference for a specific feature, API, function, module, or user action.

## Objective

Reconstruct one complete runtime path:

User/Event → Feature Entry → Validation → Core Logic → Data Transformation → State Mutation → External Effects → Result

## Phase 1 — Define Boundary

Determine:

- Feature
- Trigger
- Input
- Output
- Success condition
- Failure conditions
- Explicit scope

## Phase 2 — Find Entry

Trace:

External Trigger → Framework Entry → Application Entry → Feature Function

Confirm the entry through source code.

## Phase 3 — Trace Happy Path

First reconstruct:

Step 1 → Step 2 → Step 3 → Success

For each step ask:

- Who executes it?
- What data enters?
- What data leaves?
- What state changes?

## Phase 4 — Trace Data Transformations

Build:

Input Type → Transformation → Internal Type → Transformation → Persistence Type → Transformation → Output Type

## Phase 5 — Trace State

Identify state created, modified, or deleted by the feature.

## Phase 6 — Trace Failure Paths

Only after understanding the happy path, trace validation failures, conflicts, timeouts, retries, and cleanup.

## Required Output

1. What This Feature Does
2. Feature Boundary
3. Entry Point
4. Complete Execution Flow
5. Component Responsibilities
6. Data Flow
7. State Changes
8. External Dependencies
9. Error Paths
10. Important Design Decisions
11. Complete Mental Model

Do not explain unrelated components.

Goal: complete understanding of one runtime path, not partial understanding of the entire repository.
