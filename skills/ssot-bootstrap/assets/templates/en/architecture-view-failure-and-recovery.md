---
intent_recovery: gap
---
# Failure and recovery

<!-- Writing style: implementation-delegator. Begin with a visible symptom and
     decision, then diagnosis, safe recovery, commands, and evidence. -->

<!-- Start with a representative cross-owner failure and the user or operator
     experience. Explain detection, state preservation, recovery, and diagnosis
     as one causal story before cataloguing failure classes. -->

## A failure from symptom to recovery

<!-- Follow one request through the point of failure. Name the correlation
     handle, committed and uncommitted state, retry/cancel/restart behaviour,
     visible degradation, operator action, and evidence that confirms recovery. -->

```mermaid
<!-- diagram_type: component -->
flowchart LR
  user["User or operator"] --> coordinator["Coordinator"]
  coordinator -->|owned work| owner["Runtime owner"]
  owner -->|dependency call| dependency["External dependency"]
  dependency -. timeout or error .-> owner
  owner -->|classified failure and correlation| coordinator
  coordinator -->|safe state and recovery choice| user
```

## Failure ownership

| Failure class | Detection owner and signal | State left behind | Recovery or degradation | User or operator view |
|---|---|---|---|---|
| | | | | |

## Retry, cancellation, and timeout

<!-- Explain which layer owns each deadline, how duplicate work is prevented,
     what cancellation propagates to, and which operations are safe to retry.
     Cover applicable Q04-Q06 and Q12 order, backpressure, idempotency, replay,
     continuity, asynchronous notification, reconnect, resume, and conflict. -->

## Restart, replay, and repair

<!-- Describe process restart, durable resume, event replay, cache rebuild,
     rollback, reconciliation, and manual repair where applicable. State which
     internal payload must survive for equivalent recovery. Include Q08 backup,
     restore, corruption, disaster recovery, RPO, and RTO where applicable. -->

## Degraded operation and external dependency loss

<!-- Explain fail-open/fail-closed choices, fallback scope, user messaging,
     capacity shedding, and when an operator must stop the system. Include safe
     fallback and recovery for applicable privacy exposure, harmful or unfair
     output, missing human review/appeal, drift or invalid output, and incorrect
     charge or entitlement (Q14-Q17/Q20-Q21). -->

## Diagnosis and observability

<!-- Name correlation identifiers, traces, logs, metrics, audit entries, and
     visible status used together. Avoid treating an uncorrelated log line as
     sufficient diagnosis. -->

| Operator question | Evidence and correlation | Owner | Recovery decision supported |
|---|---|---|---|
| | | | |

## Current direction and gaps

| Failure boundary | Current behaviour | Intended posture | Risk or gap | Closure owner |
|---|---|---|---|---|
| | | | | |

## Verification links

| Recovery claim | Domain or operational owner | Test, fault injection, or runtime evidence |
|---|---|---|
| | | |
