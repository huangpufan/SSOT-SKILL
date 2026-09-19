# SSOT Status

<!-- Writing style: implementation-delegator. Keep this register short; every
     label routes to plain-language owner narrative and a concrete next check. -->

> KISS register rule: this file is a state register, not the narrative owner.
> Cells carry state, owner, date, result, and evidence pointers. Move paragraph
> reasoning, command output, checklists, and review transcripts to the
> authoritative owner or evidence artifact.

<!-- Completeness authority: reader-quality.md STATUS S01-S11. At v2.60,
     normal data cells are at most 180 characters; Source Material Absorption
     cells may use 320. Split lifecycle/authority/owner/review across columns. -->

## Event-Source Coverage

| Field | Value |
|---|---|
| tracked_commit | `<commit-sha>` |
| tracked_session | `<ISO-timestamp-or-session-id>` |
| tracked_skill_version | `<ssot-preflight-protocol-version>` |
| documentation_language | `<locked-natural-language-or-BCP47-tag>` |
| documentation_language_evidence | `<source-path-or-user-decision>` |
| coverage_result | `bootstrap` / `catching_up` / `in_progress` / `converged` |
| last_stop_review | `<review-pointer>` |

## Area Status

| Area | Status | Notes |
|---|---|---|
| product | | |
| architecture | | |
| process | | Aggregate router; `covered` requires every applicable process child to be `covered` or `not_applicable`. |
| development | | |
| testing | | |
| benchmark | | |
| deployment | | |
| release | | |
| operations | | Conditional; use `not_applicable` only when the lifecycle has no operations concern. A missing owner directory is a `gap`. |
| security-and-compliance | | Conditional; use `not_applicable` only when the lifecycle has no security/compliance concern. A missing owner directory is a `gap`. |
| records | | Aggregate router; `covered` requires every applicable record child to be `covered` or `not_applicable`. |
| decisions | | |
| research records | | `04-records/research/` |
| gotchas | | |
| bugs | | |
| tech-debt | | |
| glossary | | |

> These exact baseline rows keep the two aggregate routers and conditional
> owners visible. Status values, allowed extensions, and covered preconditions:
> see `$ssot-preflight references/status-protocol.md`. Notes are one short
> pointer, not a child-state ledger.

<!-- Area Status vocabulary: `covered` / `partial` / `gap` / `stale` /
     `unknown` / `not_applicable` / `conflict`. `partial` is honest partial
     credit: owner README exists, the shared writing floor is met, Doctor L1 is
     clean for the scope, and a scoped self-review row authorises
     `area:<scope>:partial`. It is a floor, not a ceiling; `covered` semantics
     are unchanged.

     Large repos may add scoped rows named `<area>/<scope>` (for example a
     numbered architecture domain scope, or a per-suite testing scope);
     recursion caps at one level. The 17 baseline rows stay mandatory and roll
     up their scoped children: a scoped child at `gap`/`stale`/`unknown`/`conflict`
     blocks the baseline row's `covered`/`partial` claim, and the baseline never
     claims a Status or Coverage depth stronger than its weakest scoped child.

     Optional 4th column `Coverage depth` reuses the
     `deep` / `sampled` / `inferred` / `unknown` vocabulary from
     `architecture.md §10`. Single-tenant repos may keep the 3-column form
     above; once any row carries the column, every scoped row of that area
     must carry it. -->


## Quality, Risk, and Governance

<!-- This is the Q01-Q21 disposition register, not twenty-one narratives. Keep
     every cell pointer-sized. Use `applicable` or
     `not_applicable: <named reason>; [evidence](<owner-path>)`. For an applicable row, each of the three
     fact/evidence-owner cells is either a resolvable Markdown link or
     `not_applicable: <layer reason>; [evidence](<owner-path>)`. Gap owner is a
     resolving link or `none: <why no gap>; [evidence](<owner-path>)`. Missing
     implementation is a gap, never not_applicable. A globally not-applicable
     row may use `—` in the remaining cells. Put explanations in linked owners. -->

<!-- The Q01-Q21 meanings are owned by
     `$ssot-preflight references/reader-quality.md`; use that exact profile
     when filling this register instead of maintaining a local summary. -->

| Q ID | Applicability | Product owner | Architecture owner | Process/evidence owner | Gap owner |
|---|---|---|---|---|---|
| Q01 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |
| Q02 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |
| Q03 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |
| Q04 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |
| Q05 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |
| Q06 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |
| Q07 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |
| Q08 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |
| Q09 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |
| Q10 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |
| Q11 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |
| Q12 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |
| Q13 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |
| Q14 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |
| Q15 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |
| Q16 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |
| Q17 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |
| Q18 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |
| Q19 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |
| Q20 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |
| Q21 | applicable / not_applicable: `<named reason>; [evidence](<owner-path>)` | | | | |

## Source Material Absorption

<!-- Real IDs use SRC-YYYYMMDD-NN. Lifecycle, classification, authority, and
     review states are fixed by status-protocol.md. Durable owner is one
     resolving Markdown link. A completely empty starter row is allowed. -->

| Source ID | Source material | Path/source | Lifecycle | Classification | Authority | Durable owner / absorbed_to | Do not use for | Review |
|---|---|---|---|---|---|---|---|---|
| | | | | | | | | |

## Source Inventory Exclusions

| Pattern | Reason | Decision owner | Last checked | Review trigger |
|---|---|---|---|---|
| | | | | |

## Core Reference Document Review

<!-- Role: startup / agent-rules / reference / none. Relation: thin-adapter /
     source-material / mixed. Status: covered / stale / conflict / missing /
     not_applicable. Reviewed baseline records commit=<sha>; session=<id-or-none>.
     Owner/scope and gap/conflict cells carry resolving routes. -->

| Document | Role | Relation | Status | Reviewed baseline | Durable owner / scope | Gap / conflict route |
|---|---|---|---|---|---|---|
| | | | | | | |

## Stop Review Gate

<!-- Stop claim: converged / covered / no-op / tracked_commit / tracked_session /
     tracked_skill_version / protocol-upgrade / documentation_language. Reviewer
     role: scoped-self-review / independent-reviewer /
     independent-cold-reader. Product or architecture high-impact adoption uses
     independent-cold-reader; other independent-review exceptions use
     independent-reviewer. Result:
     no-more-required-changes / needs-fix. Evidence is exactly one Markdown
     artifact link; Authorises names the exact area or tracking baseline claim. -->

| Scope | Stop claim | Reviewer | Reviewer role | Reviewed at | Result | Evidence | Remaining changes | Authorises |
|---|---|---|---|---|---|---|---|---|
| | | | | | | | | |

## Open Adjudications

<!-- Real IDs use ADJ-YYYYMMDD-NN. State: pending / deferred / resolved /
     superseded. Open rows use `none: open` for closure evidence. -->

| ID | State | Affected scope / task | Question / missing evidence | Responsible owner | Blocking / retrigger condition | Resolving route | Closure / supersession evidence |
|---|---|---|---|---|---|---|---|
| | | | | | | | |

## Pending Captures

<!-- Real IDs use CAP-YYYYMMDD-NN. State: pending / routed / absorbed / deferred /
     expired. Open rows use `none: open` for closure evidence. -->

| ID | Source | Proposed owner | Reason | Priority / trigger | Responsible owner | State | Closure evidence |
|---|---|---|---|---|---|---|---|
| | | | | | | | |

## Open Gaps

<!-- Real IDs use GAP-YYYYMMDD-NN. State: gap / unknown / resolved / superseded.
     Open rows use `none: open` for closure evidence. -->

| ID | State | Affected scope / task | Question / missing evidence | Responsible owner | Blocking / retrigger condition | Resolving route | Closure / supersession evidence |
|---|---|---|---|---|---|---|---|
| | | | | | | | |

## Optional Appendices

Create appendix sections only when needed:

- `## Appendix: core-reference details` for wide startup-file review fields.
- `## Appendix: adjudication details` for source, needed_by, resolution, and links.
- `## Appendix: stop-review evidence` for pointers to detailed review artifacts.
