---
intent_recovery: gap
---
# State and data lifecycle

<!-- Start with the information a user or operator expects to survive, the
     information that may be ephemeral, and the owner that makes each change.
     Explain the lifecycle as a story before presenting an inventory. -->

## From input to durable truth

<!-- Follow one important datum or product object from entry through validation,
     write, projection, read, update, completion, retention, deletion, rebuild,
     and recovery where applicable. Name the single writer or coordination rule
     that prevents conflicting truth. -->

```mermaid
<!-- diagram_type: component -->
flowchart LR
  input["Validated input"] --> writer["Write owner"]
  writer --> durable[("Durable record")]
  durable --> projection["Read projection"]
  projection --> surface["User or operator view"]
  durable --> rebuild["Recovery or rebuild"]
```

## State owners and readers

| State or data class | Authoritative write owner | Readers and projections | Persistence and retention | Recovery or rebuild |
|---|---|---|---|---|
| | | | | |

## Lifecycle transitions

<!-- Explain which transitions are atomic, asynchronous, reversible, or
     terminal. Name who may trigger them and how stale or duplicate attempts
     are handled. -->

| Transition | Trigger | Write owner | Invariant | Visible or downstream effect |
|---|---|---|---|---|
| | | | | |

## Consistency, concurrency, and replay

<!-- Describe transaction boundaries, ordering, idempotency, leases, locks,
     caches, eventual consistency, and replay only where they change the truth
     a caller can observe. -->

## Retention, deletion, export, and redaction

<!-- State policies and actual enforcement separately. Link trust/privacy owners
     and record gaps when retention or deletion semantics are not verified. -->

## Loss, corruption, and recovery

<!-- Tell how missing, stale, duplicated, or corrupt data is detected, what can
     be reconstructed, what cannot, and which operator evidence proves recovery. -->

## Current direction and gaps

| Topic | Current behaviour | Intended posture | Risk or gap | Closure owner |
|---|---|---|---|---|
| | | | | |

## Evidence links

| Claim | Domain owner | Schema, storage, test, or runtime evidence |
|---|---|---|
| | | |
