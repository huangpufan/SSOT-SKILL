---
intent_recovery: gap
---
# Roadmap and product acceptance

<!-- Writing style: implementation-delegator. Start with the current experience
     and next decision; define visible success/failure/recovery before proof. -->

<!-- Explain why the phases are ordered this way and what observable improvement
     each phase gives users. This page owns product delivery meaning; technical
     test commands and implementation migration live with their own owners. -->

## From the current experience to the next useful one

<!-- Tell the phase story in prose. Name whose problem the current phase solves,
     the compromise it accepts, the next problem to remove, and why another
     apparently attractive feature is later or out. -->

## What delivered means

<!-- An acceptance gate describes a result a user or product owner can observe
     and agree is delivered. Explain normal, partial, blocked, failed, and
     recovery outcomes when they affect that agreement. Technical checks are
     evidence for the meaning, not a replacement for it. -->

<!-- Apply every relevant STATUS Q01-Q21 condition to the gate it can falsify.
     Acceptance must include repeated/concurrent/partial completion when those
     change the result, and non-page surfaces such as commands, public
     interfaces, artifacts, notifications, or onboarding where applicable.
     Explicitly test privacy, harmful outcomes, human appeal, fairness,
     retirement, environmental impact, output validity/drift, and commercial or
     entitlement integrity when they apply. -->

| Gate | User-observable result | Important conditions | Required evidence | Decision owner |
|---|---|---|---|---|
| | | | | |

## Phase map

| Phase | User problem addressed | Entry condition | Exit meaning | Product maturity |
|---|---|---|---|---|
| | | | | current / limited / target / out |

## Capability and journey direction

<!-- Keep a roadmap item only when it changes a durable capability, journey, or
     product boundary. Link the detailed owner and state what users experience
     before closure. -->

| Intended change | Product reason | Current experience | Intended experience | Owner | Status |
|---|---|---|---|---|---|
| | | | | | planned / active / deferred / delivered / retired |

## How we know value lasts across real work

One successful interaction is not enough. Define the few outcome measures and
counter-metrics that show whether the product keeps helping the intended people
across repeated real tasks without hiding abandonment, rework, delay, loss of
trust, or harm. Every metric states exactly what is counted, for whom, over
which observation window, and from which permitted source. Until fitting
evidence exists, the current baseline is `unknown`; do not replace it with an
estimate presented as fact.

| Metric | Outcome or counter-metric | Exact definition | Population | Observation window | Source and measurement privacy boundary | Current baseline | Decision trigger | Review and roadmap owner |
|---|---|---|---|---|---|---|---|---|
| | outcome / counter-metric | numerator, denominator, exclusions, and unit | | per task / rolling 7 days / rolling 30 days / release cohort / other | event, survey, support, acceptance artifact, or `missing`; include purpose, minimization, access, retention, and prohibited content | unknown — no fitting baseline evidence yet | threshold, sustained change, or review event that changes a product decision | |

Name the user feedback entry point and the path from a signal to a product
decision: who reviews it, how it is combined with outcome and counter-metrics,
which roadmap or acceptance owner changes, and how the reporter can see the
result when appropriate. Feedback text is not permission to retain secrets,
personal data, or task content beyond the stated measurement boundary.

| Feedback entry | Who can use it | Review cadence or trigger | Decision made | Roadmap/acceptance owner | Visible follow-through |
|---|---|---|---|---|---|
| | | | keep / change / stop / investigate | | |

## Product-level gaps

| Gap | User impact today | Product maturity | Evidence fidelity | Closure condition and owner |
|---|---|---|---|---|
| | | limited / target | browser / integration / unit / static / missing | |

## Release choices and rollback meaning

<!-- Explain any product-level rollout, staged access, compatibility, rollback,
     or communication promise that changes what users can rely on. -->

| Choice | Why | User-visible consequence | Revisit or rollback signal |
|---|---|---|---|
| | | | |
