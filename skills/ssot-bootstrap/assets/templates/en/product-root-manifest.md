---
manifest_archetype: product-root
intent_recovery: gap
---
# Product recovery manifest

<!-- Writing style: implementation-delegator. Keep cells short and concrete;
     link to plain-language narrative before exposing repository labels. -->

<!-- Render this template as 01-product/_manifest.md. It is a recovery index,
     not product narrative. Replace gap rows with repository evidence before
     changing intent_recovery to covered. Narrative stays in its unique owner. -->

## Product spine coverage

| Required product question | Unique narrative owner | Recovery coverage | Product maturity after verification | Evidence fidelity | Closure evidence or owner |
|---|---|---|---|---|---|
| Purpose, audience, current promise, surfaces, and non-goals | [Product brief](./prd.md) | gap | not_assessed | missing | Verify against current product sources and reachable surfaces |
| People, objects, lifecycle, access, privacy, and language | [Product model](./product-model.md) | gap | not_assessed | missing | Verify product objects, policy, and user expectations |
| Durable user outcomes | [Capabilities](./capabilities/README.md) | gap | not_assessed | missing | Inventory stable capabilities and their acceptance |
| Main, choice, control, recovery, and diagnosis paths | [Journeys](./journeys/README.md) | gap | not_assessed | missing | Build journey coverage from current experiences |
| Phase intent, acceptance, and product-level gaps | [Roadmap and acceptance](./roadmap-and-acceptance.md) | gap | not_assessed | missing | Link observable gates and named closure owners |
| Non-page surfaces and applicable Q01-Q21 product meaning | Product owner links from [STATUS](../STATUS.md#quality-risk-and-governance) | gap | not_assessed | missing | Route P21 and every applicable Q item to plain-language product meaning and visible acceptance |
| Sustained value and feedback learning loop | [Product brief](./prd.md#sustained-value-and-feedback-loop) | gap | not_assessed | missing | Route P23 to current signals, counter-metrics, feedback-to-roadmap flow, privacy boundary, and a review trigger without inventing numbers |

## Product surface inventory

<!-- Assign a stable `surface:<slug>` to every actual user- or operator-reachable
     surface. Allowed classes are exactly `page`, `navigation`, `entry-mode`,
     `control`, `settings`, `diagnostic`, `external-channel`, `command`,
     `public-interface`, `output-artifact`, `notification`, and
     `help-onboarding`. Inventory every
     applicable surface separately. Each class uses real items XOR exactly one
     reasoned `not_applicable` row: never mix real and absent rows or write two
     absent rows for one class. A current/limited source anchor resolves to implementation.
     A planned surface with no code uses `planned_in: [roadmap owner](...)`,
     `target`, `missing`, and a falsifiable closure. Never invent a source path.
     Reuse IDs in prose, journeys, acceptance, and architecture. -->

| Surface ID | Surface class | Source surface anchor | Product owner | Product maturity | Evidence fidelity | Stable evidence or closure |
|---|---|---|---|---|---|---|
| `surface:<slug>` | page / navigation / entry-mode / control / settings / diagnostic / external-channel / command / public-interface / output-artifact / notification / help-onboarding | `src/...::symbol` / `planned_in: [Roadmap](./roadmap-and-acceptance.md#anchor)` / `not_applicable: <reason>` | [Product owner](./prd.md) | current / limited / target / out | browser / integration / unit / static / missing | Evidence pointer, or `closure: <falsifiable condition>`; absent class uses `out` + `static` + disposition |

## Source topic disposition

| Material topic | Disposition | Unique product owner | Evidence or closure |
|---|---|---|---|
| Product source corpus not yet reviewed | gap | [Product brief](./prd.md) | Classify each material topic as absorbed, linked, rejected-stale, or gap |

## Cold-reader evidence

<!-- Render `reader-review.md` under `SSOT/.bootstrap/`, then record its real
     score, truth errors, required changes, and verdict. The review covers
     C01-C09, P01-P23, and Q01-Q21 exactly. -->

| Review scope | Artifact | Score | Critical truth errors | Unresolved required changes | Verdict |
|---|---|---|---|---|---|
| Product, with tables hidden | `SSOT/.bootstrap/<review-file>.md` | not-scored /32 | not-counted | not-counted | needs-review |
