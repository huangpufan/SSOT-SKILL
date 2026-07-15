---
manifest_archetype: architecture-root
intent_recovery: gap
---
# Architecture recovery manifest

<!-- Writing style: implementation-delegator. Keep this as a concrete routing
     register; link to a plain-language system story before paths and labels. -->

<!-- Render this template as 02-architecture/_manifest.md. It recovers the
     architecture shape and evidence; system explanation stays in the root,
     views, and domains. Replace gap rows before claiming covered. -->

## Architecture trunk coverage

| Required architecture question | Unique narrative owner | Coverage | Evidence | Closure action |
|---|---|---|---|---|
| Current request-to-result story and system context | [Architecture root](./README.md) | gap | missing | Trace one real current path from entry to visible result |
| Runtime owners and boundary rationale | [Architecture root](./README.md) | gap | missing | Verify state, lifecycle, contract, and failure ownership |
| Cross-owner flow, state, trust, recovery, deployment, observation, and evolution | [Architecture views](./views/README.md) | gap | missing | Complete every applicable view question class |
| Detailed runtime truth | Domain READMEs | gap | missing | Link every runtime owner to one domain |
| Global invariants and their pressure | [Architecture root](./README.md) | gap | missing | Verify enforcement across all affected owners |
| Enforcement and operating consequences for applicable Q01-Q21 conditions | Architecture owner links from [STATUS](../STATUS.md#quality-risk-and-governance) | gap | missing | Trace each applicable product meaning to enforcement, observation, recovery, and a named gap owner |

## Runtime-owner registry

<!-- Keep one row for every direct numbered architecture directory. `Owner ID`
     is stable and local. `runtime` owns an independent current runtime boundary;
     `support` explains a current supporting concern without pretending to own
     that boundary; `target` is intended design and cannot be current evidence.
     Source folders or team names alone do not establish an owner. -->

| Owner ID | Owner class | Narrative owner | Current state | Evidence or closure |
|---|---|---|---|---|
| `owner:<slug>` | runtime / support / target | [Owner](./NN-<domain>/README.md) | contract / design / poc / debt / mixed | `closure: <falsifiable boundary/evidence condition>` |

## Product-to-runtime bridge

<!-- Copy every Product surface ID from 01-product/_manifest.md exactly once,
     including target and out rows. Current/limited/target rows use a registered
     owner ID; target may use an owner classified target. An out row uses a
     reasoned not_applicable disposition in all three architecture cells.
     This includes command, public-interface, output-artifact, notification,
     and help-onboarding surfaces—not only pages and controls. -->

| Product surface ID | Runtime owner ID | Contract or state boundary | Failure or operations view |
|---|---|---|---|
| `surface:<current-or-target-slug>` | `owner:<slug>` | `path::symbol` or planned boundary | [Failure and recovery](./views/failure-and-recovery.md) or [Current target gap](./views/current-target-gap.md) |
| `surface:<out-slug>` | `not_applicable: <reason>` | `not_applicable: <reason>` | `not_applicable: <reason>` |

## Unique architecture surface registry

<!-- Assign one stable `tech:<slug>` to every load-bearing technical surface.
     Allowed kinds are exactly `entry`, `write-store`, `contract`,
     `operator-surface`, and `external-integration`. Every row routes to one
     narrative owner; shared use does not mean shared ownership. Mirror the row
     in that owner's manifest and resolve overlap before claiming covered. -->

| Technical surface ID | Surface kind | Narrative owner | Current state | Stable anchor | Evidence or closure |
|---|---|---|---|---|---|
| `tech:<slug>` | entry / write-store / contract / operator-surface / external-integration | `owner:<slug>` | contract / design / poc / debt / mixed | `src/...::symbol` | evidence or `closure: <condition>` |

## Technical surface kind disposition

<!-- Keep these five kinds exactly once. `applicable` names at least one
     registered tech ID of the same kind. `not_applicable` gives a concrete
     reason and has no registry row; do not invent fake surfaces. -->

| Surface kind | Disposition | Registered surfaces | Disposition reason |
|---|---|---|---|
| entry | applicable / not_applicable | `tech:<slug>` / none | |
| write-store | applicable / not_applicable | `tech:<slug>` / none | |
| contract | applicable / not_applicable | `tech:<slug>` / none | |
| operator-surface | applicable / not_applicable | `tech:<slug>` / none | |
| external-integration | applicable / not_applicable | `tech:<slug>` / none | |

## Current, target, and gap coverage

| Scope | Current owner | Target owner | Open-gap owner | Evidence |
|---|---|---|---|---|
| Global implementation evolution | [Current, target, and gap](./views/current-target-gap.md) | [Current, target, and gap](./views/current-target-gap.md) | unresolved | Verify current claims before adopting target design |

## Cold-reader evidence

<!-- Render `reader-review.md` under `SSOT/.bootstrap/`, then record its real
     score, truth errors, required changes, and verdict. The review covers
     C01-C09, A01-A18, and Q01-Q21 exactly. -->

| Review scope | Artifact | Score | Critical truth errors | Unresolved required changes | Verdict |
|---|---|---|---|---|---|
| Architecture, with tables hidden | `SSOT/.bootstrap/<review-file>.md` | not-scored /32 | not-counted | not-counted | needs-review |
