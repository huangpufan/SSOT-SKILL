---
intent_recovery: gap
---
# Deployment and observability

<!-- Writing style: implementation-delegator. Start with the running situation
     and operator decision, then path, visible result/recovery, commands, proof. -->

<!-- Explain the current running system from an operator's point of view. A
     cold reader should learn where each load-bearing owner runs, how a change
     reaches it, which state survives replacement, and how to tell healthy,
     degraded, stuck, and failed work apart. Keep aspirational topology separate. -->

## The current running shape

<!-- Begin with connected prose: environments, deployable units, process or
     host boundaries, durable services, external dependencies, and the ingress
     through which real work arrives. Define local environment names. -->

```mermaid
<!-- diagram_type: component -->
flowchart LR
  person["User or operator"] --> ingress["Ingress"]
  ingress --> unitA["Deployable unit A"]
  unitA --> unitB["Deployable unit B"]
  unitA --> state[("Durable state")]
  unitB --> external["External dependency"]
  unitA --> telemetry["Logs, metrics, and traces"]
  unitB --> telemetry
```

## How a change reaches the running system

<!-- Narrate the current path from accepted change or artifact through build,
     configuration, rollout, readiness, traffic, and completion. Name the
     human or automated gate, the version identity visible at runtime, and the
     safe rollback or roll-forward path. Link release process detail rather
     than copying it. Cover Q07 mixed-version compatibility/migration/rollback
     and Q11 provenance/signing/SBOM/vulnerability/update evidence when applicable. -->

## Configuration, secrets, and environment differences

<!-- Explain where configuration comes from, when it is read, which values are
     secret, who can change them, and how drift is detected. Describe only
     differences that alter behaviour, trust, capacity, or evidence. Never put
     secret values in this document. -->

This deployment view owns each environment's configuration source, load time,
behaviour-changing differences, drift signal, rollout consequence, and recovery
path. The [contracts and trust-boundaries
view](./contracts-and-trust-boundaries.md#secrets-privacy-and-redaction)
separately owns who may read or change a value, how secrets cross boundaries,
what must be redacted, and how access is denied. Link that rule instead of
copying it here.

## What must survive restart or replacement

<!-- Follow durable state, in-flight work, leases, queues, caches, and derived
     projections through process restart, rolling replacement, failover, and
     restore. Route write semantics to state/data owners and recovery semantics
     to failure owners; state the deployment consequence locally. Cover Q06/Q08
     failover, continuity, backup/restore/DR, and Q09 blast radius where applicable. -->

## How operators know what is happening

<!-- Start with one diagnosis scene. From a user-visible symptom, show which
     health signal, log, metric, trace, audit record, or correlation handle an
     operator follows and what decision each signal supports. Name blind spots,
     retention limits, SLI/SLO, capacity/quota/cost signals, and signals that
     look healthy while work is actually stuck (Q04/Q06/Q09/Q10). Include
     signals and response for applicable privacy incidents (Q14), harmful or
     unfair outcomes and human intervention (Q15-Q17), maintainability and
     retirement (Q18), resource or energy impact (Q19), output quality/drift
     (Q20), and billing or entitlement integrity (Q21). -->

## Degradation, rollback, and recovery proof

<!-- Tell one representative rollout or infrastructure failure. Explain blast
     radius, detection, traffic or work protection, rollback/degradation action,
     state safety, and the observable proof that service and pending work have
     recovered. Link the general failure-and-recovery view where it owns the rule. -->

## Ownership and local detail

<!-- Route each deployable unit and operational surface to one runtime domain.
     Use stable `tech:<slug>` IDs from the
     [unique architecture surface registry](../_manifest.md#unique-architecture-surface-registry).
     Keep local ports, commands, dashboards, alerts, and runbook branches with
     the domain or process owner that maintains them. -->

## Current or intended state and gaps

<!-- Separate current deployment/observation truth from intended design. For
     every material blind spot, manual step, unsafe replacement, or unverified
     recovery claim, state the impact and unique closure owner. -->

## Evidence and last verification

<!-- Record the smallest real checks that support the topology, rollout, health,
     correlation, and recovery story. Prefer runtime identity, current config
     shape, actual telemetry, and an exercised rollback/restart path over static
     configuration alone. Detailed pins belong in the owning manifests. -->
