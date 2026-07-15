---
intent_recovery: gap
---
# Critical journeys

<!-- Writing style: implementation-delegator. Tell the current situation and
     visible result before paths; include failure, recovery, and fitting proof. -->

<!-- Choose the few current request-to-result paths whose correctness decides
     whether the system delivers a usable outcome. Start with one complete
     causal story; do not open with a catalogue of flows. -->

## The anchor journey

<!-- Describe the trigger, entry boundary, owner sequence, durable state
     changes, external calls, visible progress, and final result. Name the
     correlation handle an operator uses to follow the same work. -->

```mermaid
<!-- diagram_type: component -->
flowchart LR
  user["User or operator"] -->|request| entry["Entry boundary"]
  entry -->|validated work| coordinator["Coordinator"]
  coordinator -->|owned work| owner["Runtime owner"]
  owner -->|state and result| coordinator
  coordinator -->|completion| entry
  entry -->|visible outcome| user
```

## State changes and ownership

<!-- Explain which transition commits the request, which state is durable, and
     which owner may advance or reverse it. Link details to the data view and
     domains. -->

| Journey phase | Runtime owner | State or resource touched | Visible effect | Stable evidence |
|---|---|---|---|---|
| | | | | |

## Variants that change the design

<!-- Cover alternate entry modes, permissions, synchronous/asynchronous paths,
     external integrations, or target-only variants only when they alter owner
     order, state, contracts, or recovery. Include applicable non-page surfaces
     and Q01-Q21 effects, particularly accessibility/locale/usability, repeated
     or concurrent work, notification/offline/reconnect, and isolation. -->

## Failure and recovery in the journey

<!-- Tell a representative failed path in prose: where failure is detected,
     what remains committed, how retry/cancel/restart behaves, what the user
     sees, and how an operator diagnoses it. -->

| Failure point | Detection and correlation | Safe state | Recovery or degradation | Owner |
|---|---|---|---|---|
| | | | | |

## Journey inventory

| Journey | Trigger and visible result | Owners crossed | Product journey | Current evidence |
|---|---|---|---|---|
| | | | | |

## Acceptance and observability

| Runtime expectation | User or operator observation | Required trace, metric, log, or test | Owner |
|---|---|---|---|
| | | | |

## Current direction and gaps

| Journey | Current behaviour | Intended behaviour | Gap and closure owner |
|---|---|---|---|
| | | | |
