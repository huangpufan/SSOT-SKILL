---
intent_recovery: gap
---
# Operating model

<!-- Writing style: implementation-delegator. Begin with a recognisable pressure
     and decision, then the system response, trade-off, failure, and evidence. -->

<!-- Start with the pressures that shaped the architecture: workload, latency,
     consistency, safety, cost, deployment, team operation, or product
     constraints. Check all applicable STATUS Q01-Q21 concerns, especially Q04,
     Q06, Q09, Q10, and Q11. Explain the chosen posture as a causal story. -->

## The pressures the design must absorb

<!-- Describe the important actors and operating setting. Tell what would go
     wrong if the system optimised only for the most tempting local shortcut. -->

## How the system responds

<!-- Explain the order of priorities and the major trade-offs. Connect each
     principle to a concrete part of the main runtime story. State the few
     global invariants that every owner must preserve, and explain why the
     chosen owner decomposition fits the drivers and state/failure boundaries
     better than the nearest alternative. This is the A18 owner. -->

| Design principle | Pressure it answers | Practical consequence | Enforcement owners |
|---|---|---|---|
| | | | |

## Important trade-offs

<!-- Explain both sides of each tension before stating the chosen side. Include
     revisit signals so a future reader knows when the choice may change. -->

| Tension | Current choice | Benefit | Cost | Revisit signal |
|---|---|---|---|---|
| | | | | |

## Technical non-goals

<!-- Record tempting optimisations or architectural forms deliberately rejected
     here. Explain the harm avoided and the supported alternative. Product
     non-goals remain with the product brief. -->

| Rejected optimisation | Why it is not pursued | Supported alternative | Decision or owner |
|---|---|---|---|
| | | | |

## Operational posture

<!-- Describe deployment shape, capacity assumptions, observability,
     maintenance, and change safety when they influence cross-owner design.
     Link the detailed owners, process/evidence route, and any Q gap owner. -->

## Current direction and gaps

| Pressure or principle | Current response | Intended response | Gap and owner |
|---|---|---|---|
| | | | |

## Evidence links

| Claim | Domain or decision owner | Runtime or test evidence |
|---|---|---|
| | | |
