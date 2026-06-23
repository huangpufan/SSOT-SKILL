# Product

> Writing style: any cold reader. Every section opens with prose before tables;
> tables are indexes, not paragraphs. Walkthrough / Easily confused with / Out
> of scope / See also are reader-facing structural slots — fill them or write
> explicit `not_applicable: <reason>`. See `ssot-bootstrap` §3.7 and
> `SKILL_STYLE.md` reader-scaffolds section.

> Product facts entry point. This area owns PRD, product promises, users/operators, product boundary, capability, journey, roadmap, and product acceptance. Architecture only links to owners in this area and records implementation design or gap.
>
> This file gives the first product mental model, then routes to owners. It
> does not duplicate detailed product fact bodies.

## Product Intent And Truth

Write 2-5 short paragraphs before any table. A cold reader should understand:
who the product serves, what problem it solves, what the current promise is,
what target posture or gap remains, what is out of scope, what acceptance means,
and which owner to inspect first for detail.

This section synthesizes existing owners; it does not create a second fact
store. Link `prd.md`, `product-model.md`, `roadmap-and-acceptance.md`,
capability owners, and journey owners when the detail belongs there.

## Product Reader Map

| Reader question | First stop | Authoritative owner | Evidence direction | Stop condition / risk |
|---|---|---|---|---|
| What does the product currently promise, what is the target posture, and what does it not do? | [prd.md](./prd.md) | PRD spine | PRD / README / user-provided product source | Can locate the owner of each core promise |
| Who are the users/operators, and what are the user problems and product language? | [product-model.md](./product-model.md) | Product model | user research / support docs / product source | Users, problems, promises, and boundary are not duplicated |
| What are the product roadmap, phases, and acceptance gates? | [roadmap-and-acceptance.md](./roadmap-and-acceptance.md) | Roadmap and acceptance | roadmap / issue / release / acceptance evidence | Product acceptance and technical tests are separated but cross-linkable |
| Does a given capability have an independent long-term product boundary? | [capabilities/README.md](./capabilities/README.md) | Capability owner index | PRD / roadmap / acceptance / support source | Do not create a capability for a one-off ticket or implementation flow |
| Does a given journey cross capabilities and affect priority? | [journeys/README.md](./journeys/README.md) | Journey owner index | journey map / product source / acceptance | User intent and touchpoints belong in product; runtime flow belongs in architecture |

## Owner index

| Product fact type | Owner | Notes |
|---|---|---|
| PRD spine / product posture | [prd.md](./prd.md) | Concise spine; not a full-PRD mirror |
| Users / problems / promises / boundaries | [product-model.md](./product-model.md) | Owns product language and long-term tradeoffs |
| Roadmap / acceptance / product gaps | [roadmap-and-acceptance.md](./roadmap-and-acceptance.md) | Owns product acceptance gates |
| Capability details | [capabilities/](./capabilities/README.md) | Only collects stable capability owners |
| Journey details | [journeys/](./journeys/README.md) | Only collects journeys that cross capabilities or have independent acceptance |

## Capabilities ↔ Journeys diagram

> Optional. Small product spines write `not_applicable` and reason. The diagram
> only shows capability/journey relationships at a glance and routes the reader
> to the owner; it does not carry independent product facts.

```mermaid
<!-- diagram_type: component -->
flowchart LR
  prd["PRD spine"] --> cap1["capability A"]
  prd --> cap2["capability B"]
  cap1 --> j1["journey 1"]
  cap2 --> j1
```

## Split rules

- Keep facts at the highest stable owner. Do not create product files for one-off features, tickets, UI scripts, test cases, or implementation flows.
- When a capability has durable user value, boundary, non-goals, acceptance meaning, or roadmap state, and keeping it in the spine would bloat it, split it into `capabilities/<capability>.md`.
- When a journey crosses multiple capabilities, affects roadmap/release decisions, owns independent product acceptance, or repeatedly drives priority tradeoffs, split it into `journeys/<journey>.md`.
- Product facts are owned by product; architecture only records implementation design, runtime execution, lifecycle, failure/recovery, observability, and technical gap.

## Walkthrough
<!-- One end-to-end concrete prose walk of THIS owner doing its job. Not a table.
     Skip with explicit `not_applicable: <reason>` when the owner is purely
     indexical (e.g., SSOT/README.md is an index, not a system). -->

## Easily confused with
<!-- 1-3 sibling owners that get confused with this one; one bullet each:
     `**[Sibling]** — [one-line boundary that disambiguates]`. -->

## Out of scope
<!-- 1-line statement of what this owner does NOT answer + pointer to the
     owner that does. Required even when "none" (write `none — covers complete intent`). -->

## See also
<!-- Forward-link bouquet (3-7 outbound links). Inline body MUST avoid
     navigation-only links once this section exists. Each link: one-line
     hook explaining why a reader might go there. -->

## Source material

| Source material | Category | Product owner | Architecture / testing cascade |
|---|---|---|---|
| | absorb / link-only / stale/conflict / obsolete | | |
