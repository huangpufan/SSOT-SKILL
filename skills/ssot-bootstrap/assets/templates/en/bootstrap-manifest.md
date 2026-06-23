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
| glossary | pending | | | |
| development | pending | | | |
| testing | pending | | | |
| deployment | pending | | | |
| release | pending | | | |
| decisions | pending | | | |
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

## Architecture Shape

| Field | Value |
|---|---|
| Chosen axis | |
| Why this axis | |
| Coverage depth / scope | `deep` / `sampled` / `inferred` / `unknown` |
| Created owners | |
| Open gaps | |
| Stop review | reviewer + result + scope |

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
- `## Appendix: tier-4 roll-up` for consolidated gotcha/bug/decision/debt
  findings before they are recorded in owners.
