# PRD spine

> Writing style: any cold reader. See `ssot-bootstrap` §3.7.

> Concise product spine. Do not mirror the full external PRD; keep only long-term product facts, owner links, and the current/target product posture.

## What this product is [MUST]

Use 1–3 paragraphs of plain natural language to answer "what is this product, who uses it, what problem does it solve for them". Include at least one concrete usage scene or one-sentence user story ("imagine a user at the moment they …"). Define every term positively the first time it appears ("X is …"); do not open with a negation.

## What this phase ships, and what it does not [MUST]

Use 1–2 paragraphs of prose to tell the "current posture → target posture" story: what we can deliver today, which user problem the next phase pushes forward and to what level, and why this ordering.

Non-goals must explain "why not now, and what would make us reconsider"; do not reduce them to four-word phrases or bare identifiers. The "Key non-goals" table below indexes this prose.

## Product posture

- **Current product posture**:
- **Target product posture**:
- **Primary users / operators**:
- **Core product promises**:
- **Key non-goals**:
- **Product owner evidence**:

## Core capability map

The `state` tag (`contract | design | poc | debt`) tells a cold agent whether the capability is enforced today or aspirational; see `ssot-bootstrap` §3.7. Doctor `[STATE-TAG]` (14V).

| Capability | User value | Current status | state | Owner | Acceptance link |
|---|---|---|---|---|---|
| | | current / target / gap / not_applicable | contract / design / poc / debt | [capabilities/README.md](./capabilities/README.md) or this file | [roadmap-and-acceptance.md](./roadmap-and-acceptance.md) |

## Product scope

| Scope item | In / Out / Later | Why | Owner / evidence |
|---|---|---|---|
| | | | |

## Key non-goals

| Non-goal | Why not | Revisit condition | Owner |
|---|---|---|---|
| | | | |

## Owner links

| Fact | Owner | Notes |
|---|---|---|
| Users / problems / promises | [product-model.md](./product-model.md) | |
| Roadmap / product acceptance | [roadmap-and-acceptance.md](./roadmap-and-acceptance.md) | |
| Runtime implementation | [../architecture/README.md](../architecture/README.md) | Architecture links here; do not duplicate product facts there |

## Capability → Surface registry

Product-side mirror of the architecture-side registry in `ssot-preflight/references/architecture.md` §16; each row pins how a capability lands on real routes / components / tests.

| Capability | Route or module | Component | Test | state |
|---|---|---|---|---|

## Evidence

| Claim | Source | Confidence | Next action |
|---|---|---|---|
| | PRD / README / user-provided source / release evidence | verified / documented / inferred / unknown | |
