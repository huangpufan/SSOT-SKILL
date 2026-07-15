---
intent_recovery: gap
---
# Product

<!-- Writing style: implementation-delegator. Begin with a recognisable need and
     result, then concrete surfaces, incomplete outcomes/recovery, and evidence. -->

<!-- Open with two or three paragraphs. Name the people this product serves,
     the situation that brings them here, the result they need, and what they
     can rely on today. Use one concrete scene. Do not begin with an inventory. -->

The product area gives each recurring reader question one nearby owner:

```text
├── prd.md
├── product-model.md
├── roadmap-and-acceptance.md
├── capabilities/
├── journeys/
└── _manifest.md
```

## What a new reader should understand

<!-- Explain the product in ordinary language. Distinguish the current
     experience from the intended direction, and name the most important
     limitation or uncertainty. This section must stand on its own when every
     table and every linked file is hidden. -->

## A representative experience

<!-- Walk one real user or operator from their starting pressure to a visible
     result. Mention the entry surface, the important choice or control, what
     completion looks like, and what happens when the ordinary path cannot
     finish. Link the detailed journey only after telling the story. -->

## What people can use today

<!-- Describe the reachable product shape in prose: pages, entry modes,
     controls, settings, integrations, diagnostics, external channels,
     commands, public interfaces, output artifacts, notifications, and help or
     onboarding.
     Name the primary surfaces a reader needs to recognise, but do not repeat
     the status matrix here. The exhaustive list, stable Surface IDs, maturity,
     evidence fidelity, and unique owners live in the
     [product surface inventory](./_manifest.md#product-surface-inventory). -->

## Where each product question is answered

<!-- Introduce the hand-off in prose. Each fact has one narrative owner; these
     links route readers to it instead of restating its status or evidence. -->

- [Product brief](./prd.md) owns purpose, current promise, scope, success, and non-goals.
- [Product model](./product-model.md) owns people, product objects, lifecycle, access, language, and durable trade-offs.
- [Capabilities](./capabilities/README.md) own stable user outcomes and their boundaries.
- [Journeys](./journeys/README.md) own how people move from need to result, including recovery.
- [Roadmap and acceptance](./roadmap-and-acceptance.md) owns phase intent, acceptance gates, and named product gaps.

Use the [STATUS Q register](../STATUS.md#quality-risk-and-governance) for
Q01-Q21. For each applicable item, the linked product owner must explain the
person's expectation, visible success/failure/recovery, and acceptance in plain
language. Missing implementation is a gap, not a reason to omit product meaning.

## Boundaries and uncertainty

<!-- State what the product deliberately does not promise. For each limited or
     target experience, say what happens today, how that affects the user, and
     where the gap is closed. Silence is not a boundary. -->

## Source and confidence note

<!-- In one short paragraph, name the source families used for this overview,
     the last user-visible check, and the most important unsampled area. Keep
     detailed source disposition and review evidence in `_manifest.md`. -->
