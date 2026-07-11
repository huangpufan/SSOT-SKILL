---
manifest_archetype: product-root
intent_recovery: gap
---
# Product recovery manifest

<!-- Render this template as 01-product/_manifest.md. It is a recovery index,
     not product narrative. Replace the gap rows with repository evidence
     before changing intent_recovery to covered. Omit optional sections rather
     than leaving empty machinery. -->

## Product spine coverage

| Required product question | Narrative owner | Recovery coverage | Product maturity after verification | Evidence fidelity | Closure evidence or owner |
|---|---|---|---|---|---|
| Purpose, audience, current promise, surfaces, and non-goals | [Product brief](./prd.md) | gap | not_assessed | missing | Verify against current product sources and mounted surfaces |
| People, objects, lifecycle, access, privacy, and language | [Product model](./product-model.md) | gap | not_assessed | missing | Verify product objects, policy, and user expectations |
| Durable user outcomes | [Capabilities](./capabilities/README.md) | gap | not_assessed | missing | Inventory stable capabilities and their acceptance |
| Main, choice, control, recovery, and diagnosis paths | [Journeys](./journeys/README.md) | gap | not_assessed | missing | Build journey coverage from current experiences |
| Phase intent, acceptance, and product-level gaps | [Roadmap and acceptance](./roadmap-and-acceptance.md) | gap | not_assessed | missing | Link observable gates and named closure owners |

## Current surface coverage

| Surface class | Product owner | Coverage | Evidence fidelity | Closure action |
|---|---|---|---|---|
| Routes, pages, and navigation | [Product brief](./prd.md) | gap | missing | Inspect the real mounted product entry |
| Creation or entry modes and primary controls | [Product brief](./prd.md) | gap | missing | Exercise each current mode at its user-visible boundary |
| Settings and operator diagnostics | [Product model](./product-model.md) | gap | missing | Route every applicable surface or record a reasoned exclusion |
| External access channels and integrations | [Journeys](./journeys/README.md) | gap | missing | Verify each current channel and its failure experience |

## Source topic disposition

| Material topic | Disposition | Unique product owner | Evidence or closure |
|---|---|---|---|
| Product source corpus not yet reviewed | gap | [Product brief](./prd.md) | Classify each material topic as absorbed, linked, rejected-stale, or gap |

## Cold-reader evidence

| Review | Status | Score | Evidence |
|---|---|---|---|
| Product teach-back with tables hidden | needs-review | not-scored | Record an independent review before claiming covered |
