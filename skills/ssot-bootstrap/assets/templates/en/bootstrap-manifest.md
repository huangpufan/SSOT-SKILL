# Bootstrap Manifest

> Temporary coordinator register. Delete `.bootstrap/` after bootstrap completes
> and stop reviews pass. Only the coordinator updates this file; worker agents
> do not edit it directly.
>
> Manifest tracks work progress (`pending` / `active` / `done` / `blocked`).
> `STATUS.md` tracks content quality (`covered` / `gap` / `stale` / `unknown` /
> `not_applicable` / `conflict`). Manifest `done` never auto-means STATUS
> `covered`.

## Repository Overview

| Field | Value |
|---|---|
| Size tier | `S` / `M` / `L` / `XL` |
| Recon report | [recon.md](./recon.md) |
| Documentation language lock | `<documentation_language>` |
| Language evidence | `<documentation_language_evidence>` |
| Cumulative session count | 1 |

## Phase Progress

| Phase | Status | Owner/session | Gate/result | Next/blocker |
|---|---|---|---|---|
| 0 Recon | pending | | | |
| 1 Skeleton | pending | | | |
| 2 Fill | pending | | | |
| 3 Convergence | pending | | | |
| 4 Cleanup | pending | | | |

> `done` is a stop conclusion. Write it only after the required reviewer returns
> `no-more-required-changes`; otherwise keep `active` / `pending` and name the
> blocker.

## Area Progress

| Area | Status | Owner/session | Gate/result | Next/blocker |
|---|---|---|---|---|
| product | pending | | | |
| architecture | pending | | | |
| process | pending | aggregate synthesis/review owner | | Close the process router after child work; do not copy child state here. |
| glossary | pending | | | |
| development | pending | | | |
| testing | pending | | | |
| benchmark | pending | | | |
| operations | pending | | | |
| security and compliance | pending | | | |
| deployment | pending | | | |
| release | pending | | | |
| records | pending | aggregate synthesis/review owner | | Close the records router after child work; do not copy child state here. |
| decisions | pending | | | |
| research records | pending | `04-records/research/` | | |
| gotchas | pending | | | |
| bugs | pending | | | |
| tech-debt | pending | | | |

## Product Spine

| Item | Status | Owner/session | Next/blocker |
|---|---|---|---|
| PRD spine | pending | | |
| Product model | pending | | |
| Roadmap and acceptance | pending | | |
| Capability index | pending | | |
| Journey index | pending | | |

## Product Surface Recovery

<!-- Coordination only. The concrete inventory and stable Surface IDs live in
     `01-product/_manifest.md`; do not duplicate its rows here. Every applicable
     class needs actual surfaces, and every inapplicable class needs a reason. -->

| Surface class | Inventory status | Owner/session | Inventory pointer | Next/blocker |
|---|---|---|---|---|
| `page` | pending | | `01-product/_manifest.md` | |
| `navigation` | pending | | `01-product/_manifest.md` | |
| `entry-mode` | pending | | `01-product/_manifest.md` | |
| `control` | pending | | `01-product/_manifest.md` | |
| `settings` | pending | | `01-product/_manifest.md` | |
| `diagnostic` | pending | | `01-product/_manifest.md` | |
| `external-channel` | pending | | `01-product/_manifest.md` | |
| `command` | pending | | `01-product/_manifest.md` | |
| `public-interface` | pending | | `01-product/_manifest.md` | |
| `output-artifact` | pending | | `01-product/_manifest.md` | |
| `notification` | pending | | `01-product/_manifest.md` | |
| `help-onboarding` | pending | | `01-product/_manifest.md` | |

## Quality, Risk, and Governance Recovery

<!-- Coordination only. STATUS owns the exact Q01-Q21 disposition rows. Do not
     copy those rows or their narrative here. Bootstrap is complete only when
     every applicable Q item has product, architecture, process/evidence, and
     gap-owner routing, and every not-applicable claim has a named reason. -->

| Register | Status | Owner/session | Remaining decision |
|---|---|---|---|
| `STATUS.md#quality-risk-and-governance` | pending | | Classify and route Q01-Q21 |

## Architecture Shape

| Field | Value |
|---|---|
| Chosen axis | |
| Why this axis | |
| Coverage depth / scope | `deep` / `sampled` / `inferred` / `unknown` |
| Created owners | |
| Open gaps | |
| Stop review | reviewer + result + scope |

## Architecture Domain and Surface Recovery

<!-- One row per justified runtime domain. Domain manifests enumerate local
     architecture surfaces; `02-architecture/_manifest.md` is the unique global
     registry and maps them back to product Surface IDs. -->

| Owner ID | Owner class | Narrative owner/session | Root registry status | Related product Surface IDs | Next/blocker |
|---|---|---|---|---|---|
| `owner:<slug>` | runtime / support / target | `02-architecture/NN-<domain>/README.md` | pending | | |

## Convergence

Large repositories may converge by tier, view, domain, or another explicit
segment. Keep the default register small:

| Segment | Reviewer | Result | Next/blocker |
|---|---|---|---|
| | | pending / passed / needs-fix | |

## Optional Appendices

Create these only when the repo needs the extra detail:

- `## Appendix: area scope` for covered/remaining scope and confidence notes.
- `## Appendix: architecture decomposition` for full signal matrix, rejected
  false friends, diagram inventory, and reviewer challenge.
- `## Appendix: source material` for detailed absorption rows.
- `## Appendix: tier-4 roll-up` for consolidated gotcha/bug/decision/research/debt
  findings before they are recorded in owners.
