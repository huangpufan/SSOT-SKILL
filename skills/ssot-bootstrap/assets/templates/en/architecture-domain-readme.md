---
intent_recovery: gap
---
# Runtime owner: Example boundary

<!-- Replace the title. Explain this owner as a runtime boundary, not a source
     directory: what responsibility it owns, who calls it, and which state,
     resource, contract, lifecycle, or failure would become ambiguous if this
     boundary disappeared. -->

## Mental model and boundary

<!-- Begin with two or three paragraphs and one concrete scene. Name what enters,
     what this owner decides or changes, what leaves, and what it deliberately
     delegates. Define local terms before using identifiers. -->

```mermaid
<!-- diagram_type: component -->
flowchart LR
  caller["Caller"] --> owner["This runtime owner"]
  owner --> state[("Owned state or resource")]
  owner --> dependency["Delegated dependency"]
  owner --> observer["Result or observable signal"]
```

## A canonical current flow

<!-- Narrate one load-bearing flow from trigger to user/operator outcome. Include
     cross-boundary calls, important state transitions, and the correlation
     handle used to follow the work. Keep target behaviour separate. -->

## Owned state and lifecycle

<!-- Explain creation, write ownership, reads or projections, transitions,
     persistence, retention, concurrency, rebuild, and deletion where they
     apply. If this owner is stateless, explain which owner's state it depends on. -->

| State or resource | Write owner | Readers | Lifecycle and persistence | Stable evidence |
|---|---|---|---|---|
| | this owner | | | |

## Contracts and trust boundaries

<!-- Describe three to five load-bearing contracts in prose before indexing
     them. Explain compatibility, callers, validation, permission, timeout,
     idempotency, secret, and redaction semantics when relevant. -->

| Contract | Promise to callers | Trust boundary | Stable surface anchor | Verification |
|---|---|---|---|---|
| | | | path::symbol / route / schema identifier / selector | |

## Failure and recovery

<!-- Tell one representative runtime failure: detection, committed state,
     retry/cancel/restart or degradation, visible effect, operator diagnosis,
     and proof of recovery. Then index only distinct failure boundaries. -->

| Failure boundary | Detection and correlation | Safe state | Recovery or degradation | Regression evidence |
|---|---|---|---|---|
| | | | | |

## Invariants and operational constraints

<!-- Explain the pressure behind each invariant. Cover concurrency,
     configuration, deployment, scaling, maintenance, and observability only
     when they change this owner's behaviour. -->

| Invariant or constraint | Why it exists | Consequence if broken | Enforcement and evidence |
|---|---|---|---|
| | | | |

## Current direction and gaps

| Topic | Current behaviour | Intended posture | Gap, risk, or next evidence |
|---|---|---|---|
| | | | |

## Verification and evidence

<!-- Give the minimal checks at the same observable boundary as the claim. Link
     stable symbols, tests, runtime traces, logs, metrics, and audit evidence;
     line numbers may be hints but never the only anchor. -->

| Claim or change family | Minimal sufficient proof | Stable owner or evidence |
|---|---|---|
| | | |

## Related owners and explicit exclusions

<!-- Name boundaries a newcomer may confuse with this owner and route each
     excluded responsibility to its authority. Link optional operational
     playbooks only when they contain a real multi-step branch. -->
