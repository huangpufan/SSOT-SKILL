---
intent_recovery: gap
---
# Architecture

<!-- Writing style: implementation-delegator. Start with a recognisable current
     situation and system response, then owner paths, success/failure/recovery,
     and only then technical labels and evidence. -->

<!-- Teach the system before indexing it. Begin with a current request-to-result
     story that a user or operator can recognise: where work enters, who changes
     state, how the visible result returns, and where one failure is recovered. -->

The architecture area keeps cross-owner explanations separate from the owner
that holds each runtime fact:

```text
├── views/
├── NN-example-owner/
└── _manifest.md
```

## From request to visible result

<!-- Write several connected paragraphs. Name only the system concepts needed
     to understand causality; defer paths and symbols to owner evidence. Mark
     the hand-off between owners and keep target design out of this current story. -->

## System context

<!-- Explain the people, upstream callers, runtime processes, storage systems,
     and external services around the system. State the deployment shape and
     the most important trust boundary before showing the diagram. -->

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

<!-- Give each runtime owner a short subsection. Explain its role in the main
     story, the state/resource/contract/lifecycle/failure boundary that makes it
     independent, and the nearest responsibility it does not own. Do not use a
     source directory or team name as the explanation. The complete domain and
     Surface-ID registries live in [the architecture manifest](./_manifest.md). -->

## Global invariants and their pressures

<!-- Explain only rules that cross owners. For each, tell the pressure that
     produced it, the harm it prevents, where it is enforced, and which owners
     must agree. Domain-local rules remain with the domain. Start from the
     [STATUS Q register](../STATUS.md#quality-risk-and-governance) and route
     every applicable Q01-Q21 condition to its enforcement, observation,
     recovery, process/evidence, and gap owners; do not create twenty-one headings.
     An invariant registered in the [SSOT/README adjudication boundary](../README.md#adjudication-boundary)
     carries its registry ID at the start of its bullet (e.g. **INV-03**);
     unregistered rules stay plain prose. -->

## Read the system by question

<!-- These views synthesise cross-owner truth; they do not duplicate domain
     internals. Introduce the route in prose, then keep this list short. -->

- [Operating model](./views/operating-model.md) explains pressures, priorities, trade-offs, and technical non-goals.
- [Critical journeys](./views/critical-journeys.md) follows load-bearing requests and visible results across owners.
- [State and data lifecycle](./views/state-and-data-lifecycle.md) explains write ownership, persistence, retention, rebuild, and recovery.
- [Contracts and trust boundaries](./views/contracts-and-trust-boundaries.md) explains compatibility, identity, permission, secrets, and redaction.
- [Failure and recovery](./views/failure-and-recovery.md) explains detection, retry, cancellation, restart, degradation, and diagnosis.
- [Deployment and observability](./views/deployment-and-observability.md) explains where the system runs, how a change reaches it, and how operators know its current state.
- [Current, target, and gap](./views/current-target-gap.md) separates implemented truth from intended design and named gaps.

## Current posture and important gaps

<!-- In prose, name only the few global facts needed to stop a reader from
     mistaking target design for current behaviour. Give the present effect,
     desired posture, risk, and unique owner; leave detailed ledgers in the
     evolution view or domain. -->

## Finding the local owner

<!-- Teach the routing rule: follow the owner of the state, resource,
     compatibility promise, or recovery boundary. Introduce each domain in one
     sentence and link its README. Do not copy its contracts, status, or evidence.
     The [unique architecture surface registry](./_manifest.md#unique-architecture-surface-registry)
     is the exhaustive lookup when a reader starts from a route, command, store,
     integration, or other runtime surface. -->

Include command, public-interface, output-artifact, notification, and
help-onboarding product surfaces in this routing. A non-page surface still
needs a runtime owner, contract/state boundary, failure path, and fitting proof.

## Source and confidence note

<!-- In one short paragraph, name the evidence families used for the overview,
     the last current-path check, and the most important unsampled boundary.
     Detailed pins and cold-reader evidence belong in manifests. -->
