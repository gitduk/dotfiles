Writing-time discipline for test fixtures — fires when writing a test, not when reviewing it.
(The review-side counterpart is the Simplicity/duplication dimension of [CQ-3].)

- **[TEST-1]** The moment the same object needs full construction in a 2nd test file, extract a
  shared fixture/factory in its defining module (or a shared test-helpers module) instead of
  writing a 3rd inline copy. Language-agnostic: Rust structs without `Default`, Python
  dict/dataclass literals, TS object literals all rot the same way — duplicated construction
  drifts silently out of sync when the underlying shape changes, and nothing catches it until
  every copy is found by hand.
