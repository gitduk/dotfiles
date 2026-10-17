# Debugging Analysis

Debugging is system reconstruction around a divergence.

Goal:

Expected Path vs Actual Path

Find where they first differ.

## Process

### 1. Define Symptom
- Expected
- Actual
- When
- Frequency
- Scope

### 2. Build Timeline
T0 Normal → T1 Change → T2 First Symptom → T3 Error → T4 Recovery/Crash

### 3. Reconstruct Expected Flow

Input → Expected Step A → Expected Step B → Success

### 4. Reconstruct Actual Flow

Input → Step A → Unexpected State → Failure

### 5. Find First Divergence

Do not focus only on the final error.

Ask: What was the first thing that became incorrect?

## Root Cause Tree

Symptom
├── Hypothesis A → Evidence
├── Hypothesis B → Evidence
└── Hypothesis C → Evidence

Eliminate hypotheses through evidence.

## Important Rule

Logs describe observations, not necessarily causes.

Map logs back to runtime state, execution flow, and resource lifecycle.
