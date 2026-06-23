## Core recovery manifest

> This file holds the SSOT self-maintenance machinery for its area. The product
> or design narrative lives in the prose owners (`README.md` / `prd.md` /
> `product-model.md` / capability / journey / domain files).

### Core completeness argument

<!-- Explain why this set is the core surface, what near-miss items are excluded,
     and what wrong conclusion a cold reader would reach if one class were omitted. -->

### Core items

| Core item | Owner | Required pillars | Current truth state | Evidence / closure owner |
|---|---|---|---|---|
| <!-- Item name, linked to prose owner --> | <!-- path or anchor --> | `product_intent` / `product_truth` / `not_applicable + reason` | `contract` / `mixed` / `design` / `debt` / `Out` / `not_applicable` | <!-- evidence pointer or closure owner --> |

## Apex / Maxim → Owner index

<!-- Architecture root _manifest only. Not present in product/ manifests. -->

| Maxim | Owner | DISC / capability / invariant anchor |
|---|---|---|
| <!-- e.g. CLAUDE-MAXIM-N --> | <!-- unique owner path --> | `[CORE-REF: ...]` |

## Capability → Surface registry

<!-- Architecture root _manifest only. -->

| Capability | Route + handler | Component path | Test |
|---|---|---|---|
| <!-- Name + owner link --> | `path:LNN` | `path` | `tests/...::test_*` |

## README-self failure modes

<!-- Only present when detection and recovery concern documentation drift on
     the manifest itself. -->

| Failure mode | Detection | Recovery |
|---|---|---|
| <!-- How this manifest can become invalid --> | <!-- automatic / human check --> | <!-- recovery action --> |

## intent_recovery evidence

| Area | Status | Latest cycle | Evidence |
|---|---|---|---|
| <!-- Corresponding area --> | `covered` / `partial` / `gap` | `cycle-N` | <!-- trial verdict / cold read date --> |

## adoption-cycle log

| Version | Date | Scope | Notes |
|---|---|---|---|
| v2.48 | 2026-06 | product/ + architecture/ manifest separation | <!-- recorded scope and topology --> |