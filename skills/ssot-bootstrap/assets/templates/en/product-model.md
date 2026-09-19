---
intent_recovery: gap
---
# Product model

<!-- Writing style: implementation-delegator. Explain people, objects, and
     states in ordinary language and a concrete situation before internal names. -->

<!-- Explain how users understand the product: who participates, which objects
     they handle, how those objects change, and which visible truth they trust.
     Use product language here; implementation structure belongs in architecture. -->

## People and their working context

<!-- Describe the primary user and each secondary operator in prose. For each,
     explain the situation, desired result, constraint or risk, and the product
     responsibility created by that pressure. Do not reduce a person to a role
     label that a cold reader must decode. -->

## The objects people work with

<!-- Give each durable product object its own short subsection. Introduce what
     it means to a person, how they encounter or create it, which visible state
     they trust, and how it relates to other objects. Database entities and
     source types belong in architecture evidence, not in this mental model. -->

## A lifecycle in user language

<!-- Walk the most important object through entry, progress, completion,
     cancellation, failure, recovery, retention, and deletion where applicable.
     Explain who can act at every meaningful transition before summarising it. -->

```mermaid
<!-- diagram_type: state -->
stateDiagram-v2
  [*] --> Draft
  Draft --> Active: person starts
  Active --> Complete: result accepted
  Active --> NeedsAttention: blocked or failed
  NeedsAttention --> Active: person recovers
```

## Identity, access, and shared use

<!-- Explain sign-in assumptions, workspace or tenant boundaries, permissions,
     multi-user expectations, and what an unauthorised person experiences. If
     the product is intentionally single-user, give a named evidence link for
     why it is not applicable. Cover Q09 isolation and quota where applicable. -->

## Data, privacy, retention, and audit expectations

<!-- Describe what people expect to persist, what may be ephemeral, what can be
     exported or deleted, what is sensitive, and which actions need an audit
     trail. Include backup/restore/DR expectations and policy, consent,
     residency, licensing, or disclosure when applicable (Q08/Q13/Q14). Explain
     privacy choices and data-governance responsibilities rather than treating
     a retention table as privacy proof. Keep the expectation here and link its
     technical enforcement. -->

## Product language

<!-- Define only product concepts needed for this model. Give each one a
     positive sentence and distinguish the nearest confusing term. Canonical
     vocabulary has one prose owner in the glossary; secondary mentions here
     add only the user-facing angle and a link. -->

<!-- Also explain applicable Q01-Q03 and Q12 behaviour in the nearest existing
     section: accessible/inclusive use, locale/time-zone/format meaning,
     usability/onboarding/feedback/error prevention, and notification/offline/
     reconnect/resume/conflict. Route implementation and gaps through STATUS. -->

<!-- Route Q15-Q21 into the nearest existing product story: harmful outcomes
     and safe limits; human review, accountability, and appeal; fairness,
     transparency, and explanation; change or retirement promises; environmental
     lifecycle impact; output validity, uncertainty, robustness, and drift; and
     price, charge, quota, plan, or entitlement integrity. If a condition is not
     applicable, STATUS must carry the named reason and evidence. -->

## Durable product trade-offs

<!-- Give each long-lived tension a short subsection. Explain the pressure on
     both sides, the chosen posture, the user benefit, the accepted cost, and a
     signal that would reopen the choice. Do not turn temporary backlog status
     into a product trade-off. -->

## Product promises and the adjudication boundary

<!-- List here the product promises whose change is itself a human decision:
     user-visible, confirmed outcomes an agent must not rewrite or withdraw.
     Start each with its registry ID (e.g. **INV-05**), matching the
     `product-promise` rows in the [SSOT/README adjudication boundary](../README.md#adjudication-boundary);
     the table holds pointers, this section holds the promise body, its scope,
     and its establishing authority. Ordinary product description is not
     registered; this section is not a second feature list. -->

## Product constraints handed to architecture

<!-- In connected prose, name the constraints that materially shape runtime
     design and why people care. Link each constraint to its unique owner under
     [Architecture](../02-architecture/README.md); keep implementation details
     and open technical gaps there. -->
