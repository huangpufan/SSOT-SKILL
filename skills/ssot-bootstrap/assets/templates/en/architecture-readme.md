---
intent_recovery: gap
---
# Architecture

<!-- Teach the system before indexing it. Begin with a current request-to-result
     story that a user or operator can recognise. Explain where work enters,
     which owners change state, how the visible result returns, and where a
     representative failure is detected and recovered. -->

## From request to visible result

<!-- Write several connected paragraphs. Name only the system concepts needed
     to understand causality; defer paths and symbols to owner evidence. Keep
     target design out of this current story. -->

The architecture area separates cross-owner explanations from runtime-owner detail:

```text
├── views/
├── NN-example-owner/
└── _manifest.md
```

## System context

<!-- Explain the people, upstream callers, runtime processes, storage systems,
     and external services around the system. State deployment assumptions and
     the most important trust boundary. -->

```mermaid
<!-- diagram_type: component -->
flowchart LR
  person["User or operator"] --> entry["Product entry"]
  entry --> coordinator["Work coordinator"]
  coordinator --> owner["Runtime owner"]
  owner --> store[("Durable state")]
  owner --> external["External dependency"]
  owner --> entry
```

## Why the system is divided this way

<!-- Introduce the runtime-owner decomposition in prose. Explain which state,
     lifecycle, contract, or failure boundary makes each owner independently
     changeable. Source directories and team names are not sufficient reasons. -->

| Runtime owner | Responsibility in the main story | State or resource owned | Failure boundary | Detailed owner |
|---|---|---|---|---|
| | | | | |

## Global invariants and their pressures

<!-- Keep only rules that cross owners. Explain the pressure that produced each
     rule and the user or operator harm it prevents. Domain-local rules remain
     with the domain. -->

| Invariant | Pressure it answers | Owners involved | Consequence if broken | Evidence direction |
|---|---|---|---|---|
| | | | | |

## Read the system by question

<!-- Introduce how the six views complement one another. These pages synthesise
     cross-owner truth; they do not duplicate domain internals. -->

| Question | View |
|---|---|
| Which pressures and trade-offs shape the design? | [Operating model](./views/operating-model.md) |
| How do load-bearing requests cross owners? | [Critical journeys](./views/critical-journeys.md) |
| Where does state live, change, persist, expire, and recover? | [State and data lifecycle](./views/state-and-data-lifecycle.md) |
| Which contracts cross trust boundaries and how are they protected? | [Contracts and trust boundaries](./views/contracts-and-trust-boundaries.md) |
| How are failure, cancellation, restart, and diagnosis handled? | [Failure and recovery](./views/failure-and-recovery.md) |
| What is implemented, intended, or still unresolved? | [Current, target, and gap](./views/current-target-gap.md) |

## Current posture and important gaps

<!-- Summarise only the few global facts needed to keep a reader from assuming
     target design is current. Link detailed gaps to the evolution view or a
     domain owner. -->

| Topic | Current architecture | Intended posture | Risk or gap | Owner |
|---|---|---|---|---|
| | | | | |

## Where detail lives

<!-- Explain how to choose a domain: follow the owner of state, resource,
     compatibility promise, or recovery boundary. Then provide a short index. -->

| Domain | Why it is separate | Owns | Read when |
|---|---|---|---|
| | | | |

## Evidence trail

| Material topic | Disposition | Architecture owner | Stable evidence direction |
|---|---|---|---|
| | absorbed / linked / rejected-stale / gap | | |
