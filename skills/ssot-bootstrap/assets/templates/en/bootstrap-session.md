# Session NNN: <scope description>

> Bootstrap temporary file. Each independent exploration unit (one run of a sub-Agent) produces one session file; before final cleanup, all sessions must pass stop review.
>
> **Write rule**: each Agent only writes its own session file and does not edit other sessions.

## Metadata

| Field | Value |
|---|---|
| Time | YYYY-MM-DD HH:mm |
| Assigned scope | |
| Prerequisites | recon.md |
| Documentation language lock | `<documentation_language>` |
| Language evidence | `<documentation_language_evidence>` |
| Produced files | |

## Exploration Log

> What was actually explored in this session (down to directory/file level).
> Record the exploration path and depth so later Agents know which areas have been covered.

## Source Material Handling

| Source material | Path/source | Lifecycle | Classification | Authority / downgrade | Authoritative location | Outcome |
|---|---|---|---|---|---|---|
| | | working/* / historical/* / external/source-material / public/thin-entry | absorb / link-only / stale/conflict / obsolete | authority=...; owner=...; absorbed_to=...; do_not_use_for=...; review_on=... | SSOT/... | |

## Architecture Decomposition Decisions

> If this session touched architecture, record candidate decomposition axes, evidence-guided signals, final choice, rejection reasons, owner anchor, bottom-up synthesis notes, coverage depth, view absorption scope, and domain validity decisions.

| Field | Value |
|---|---|
| Architecture scope handled | root / views / domains / legacy direct child-domain |
| Decomposition axis used | |
| Evidence-guided signals | entrypoints, call/dependency edges, shared state/resource, runtime flow, failure/recovery boundary, contract surface, tests, configs, scripts, ADR/source material |
| Rejected alternative axes | |
| Rejected signals / false friends | |
| Owner anchors | |
| Bottom-up synthesis notes | domain evidence -> view synthesis -> root Reader Map |
| Reasons to continue recursion / stop decomposition | |
| Coverage depth | `deep` / `sampled` / `inferred` / `unknown` |
| Coverage scope / sampling strategy | |
| View absorption scope | operating-model / critical-journeys / current-target-gap |
| Design intent coverage | mission / priorities / non-goals / success standards / journeys / current-target-gap |
| Required diagram inventory | boundary/context, decomposition/domain, runtime flow, state/resource, lifecycle/concurrency, failure/recovery, trust/config |
| Domain validity evidence | why separate + independence signal |
| Uncovered gaps | |
| Stop / recursion review challenge | reviewer + result (`no-more-required-changes` / `needs-fix`) + remaining changes |

> If this session concludes `single-level`, stop decomposition, an area as `done`, or `no update required`, record how stop review challenged that conclusion. Prefer an independent reviewer; if unavailable, record scope, basis, and skipped items under the `self-reviewed` degradation path. On `needs-fix`, do not report the scope as complete.

## Product Spine Decisions

> If this session covered product, record coverage judgements for PRD, product-model, roadmap-and-acceptance, and whether any capability / journey needs to be split into an independent owner file. Product facts are owned by product; architecture only records the technical response and implementation gaps.

| Field | Value |
|---|---|
| PRD coverage | covered / sampled / inferred / unknown; core promises, users/operators, non-goals, owner evidence |
| Product model coverage | covered / sampled / inferred / unknown; users, problems, promises, boundaries, product language |
| Roadmap / acceptance coverage | covered / sampled / inferred / unknown; phase, roadmap intent, product acceptance, product-level gap |
| Capability split decision | keep-in-spine / split-to-capability-owner / no-stable-capability; basis and owner |
| Journey split decision | keep-in-spine / split-to-journey-owner / no-stable-journey; basis and owner |
| Rejected product splits | Candidate capability / journey / product file and rejection reason |
| Product / Architecture boundary decision | product intent / acceptance / current-target-gap owner; architecture implementation / runtime / technical gap owner |
| Uncovered product gaps | |
| Stop / recursion review challenge | reviewer + result (`no-more-required-changes` / `needs-fix`) + remaining changes |

## Architecture Diagram Handling

### Diagram Index

| Diagram ID | Architecture path | Status | Coverage |
|---|---|---|---|
| | SSOT/02-architecture/.../README.md | current / target / stale | |

### Diagram Trace

| Diagram ID | Evidence | Linked table rows | Outcome |
|---|---|---|---|
| | | Runtime flows / Child Domains / Contracts / State / Lifecycle / Failure / trust-config | |

## Output Summary

> Which areas, architecture views, or architecture domain files were written, and a brief summary of core content.

## Tier 4 Findings

> decisions/gotchas/bugs/tech-debt material discovered during exploration, as well as leads that need to enter architecture constraints and gap records.
> The coordinator aggregates these into the Tier 4 Findings Roll-up in manifest.md.

| Finding | Type | Source tag | Source location |
|---|---|---|---|
| | gotcha / decision / bug / debt / architecture-constraint | documented / code-comment / code-analysis / git-history | file path or description |

## Blockers and Issues

> Points where progress cannot continue, areas with insufficient evidence, and items requiring help from other Agents.
> The coordinator uses this to decide whether to mark related areas as blocked.

## Stop Review Records

| scope | stop_claim | reviewer | result | Evidence reviewed | Remaining changes |
|---|---|---|---|---|---|
| | done / no-op / no update required / single-level / stop decomposition | | no-more-required-changes / needs-fix | | |

> High-impact bootstrap conclusions (overall `passed`, cleanup of `.bootstrap/`, final waterline advance) cannot be self-reviewed. Recorded here are reviewer challenges for stop conclusions associated with this session, or `self-reviewed` degradation records; under degradation, you must spell out checked and unchecked items. Final global convergence still defers to the records in manifest and STATUS.md.

## Suggestions for Next Session

> Based on this exploration, recommendations for follow-up work (what to explore first, which areas deserve deeper investigation, etc.).
