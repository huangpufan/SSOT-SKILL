---
intent_recovery: gap
---
# Architecture views

<!-- Explain why cross-owner views are needed in this system. Name a question
     that no single runtime owner can answer, then describe how the views let a
     reader follow flow, state, trust, recovery, and evolution without copying
     domain detail. -->

This directory contains the default cross-owner explanations:

```text
├── operating-model.md
├── critical-journeys.md
├── state-and-data-lifecycle.md
├── contracts-and-trust-boundaries.md
├── failure-and-recovery.md
├── current-target-gap.md
└── _manifest.md
```

## How the views work together

<!-- Tell a short reading example: start with a critical journey, follow its
     writes into state/data, cross-check its contract and trust boundary, then
     inspect failure/recovery and current/target posture. -->

| Reader question | View | What it synthesises | Detail remains with |
|---|---|---|---|
| Why is the design optimised this way? | [Operating model](./operating-model.md) | Pressures, priorities, trade-offs, and technical non-goals | Decisions and runtime owners |
| How does a result cross owners? | [Critical journeys](./critical-journeys.md) | Current end-to-end paths and visible outcomes | Product journeys and runtime owners |
| How does information change and survive? | [State and data lifecycle](./state-and-data-lifecycle.md) | Write ownership, transitions, retention, rebuild, and recovery | Persistence and runtime owners |
| Who may call what, with which protection? | [Contracts and trust boundaries](./contracts-and-trust-boundaries.md) | Public/internal contracts, identity, permissions, secrets, and redaction | Contract and policy owners |
| What happens when work cannot continue? | [Failure and recovery](./failure-and-recovery.md) | Detection, retry, cancellation, restart, degradation, and diagnosis | Runtime owners and operational records |
| Which design is current or still moving? | [Current, target, and gap](./current-target-gap.md) | Cross-owner implementation evolution | Decisions, debt, and runtime owners |

## Coverage and exceptions

<!-- Name any merged or additional view and give the recurring cross-owner
     question that justifies it. Silence cannot support complete coverage. -->

| Question class | Coverage | Reason or closure owner |
|---|---|---|
| operating pressures and trade-offs | covered / gap / not_applicable | |
| critical end-to-end journeys | covered / gap / not_applicable | |
| state and data lifecycle | covered / gap / not_applicable | |
| contracts and trust boundaries | covered / gap / not_applicable | |
| failure and recovery | covered / gap / not_applicable | |
| current, target, and gap | covered / gap / not_applicable | |

## Evidence direction

<!-- Views are synthesis. Current claims link to domain evidence; product
     meaning links to product owners; intended design links to decisions. -->
