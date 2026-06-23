# Source Material Reference

This file is the semantic owner of source material classification, absorption status, thin-documentation rules, conflict adjudication, and product and architecture source routing. `STATUS.md` only maintains the matrix and waterline fields; this file maintains how to judge and process source material.

## Table of Contents

- [1. Source material scope](#1-source-material-scope)
- [2. Classification and handling rules](#2-classification-and-handling-rules)
- [3. Thin-documentation rules](#3-thin-documentation-rules)
- [4. Conflict adjudication](#4-conflict-adjudication)
- [5. Source Routing](#5-source-routing)
- [6. Status synchronization](#6-status-synchronization)

## 1. Source material scope

Source material is raw information outside SSOT, including:

- Root README, `docs/`, ADR, PRD, design documents, runbooks, ARCHITECTURE.md, CONTRIBUTING.md, subsystem/service READMEs.
- `AGENTS.md`, `CLAUDE.md`, `.cursor/rules`, `.windsurf/rules`, `GEMINI.md` and other core reference documents: agent-startup-read, repo-level instructions, or IDE/Agent rules files.
- External material, specifications, design notes, historical documents, URLs, files, or context explicitly provided by the user in the current session.
- Structured design notes inside inline documentation comments.

Source material can serve as an exploration entry point, evidence source, public explanation, or derived artifact, but long-lived knowledge must be absorbed into a unique authoritative location in `SSOT/` for maintenance. When describing currently implemented facts, source material has lower credibility than code, configs, schemas, tests, and actual runtime behavior; when describing product intent, product promises, or PRD goals, source material must enter `product/`; when describing target technical design and historical technical intent, source material may be important evidence, but it still must enter architecture / decisions / status matrix.

Reader Map, claim-to-evidence, script/tool inventory, and diagram candidate governance are SSOT-native expressive capabilities and do not depend on any externally generated material. Externally generated diagrams, screenshots, dependency graphs, or automatic summaries explicitly provided by the user can only serve as candidate leads within ordinary external material; before absorption they must be cross-validated against code, configs, schemas, tests, or actual runtime behavior. Do not add parallel auto-generated knowledge surfaces, do not mirror full text, and do not copy external directory or topic structure as the SSOT authoritative structure; unverified content stays `pending`, `link-only`, or `stale/conflict`.

Source inventory may reuse the documentation language lock detection sources, but the language lock judges only based on natural-language evidence permitted by `SKILL.md` documentation language lock. Natural-language changes in source material may trigger language-lock review leads but must not auto-switch `documentation_language`.

### 1.1 Core reference documents

Core reference documents are not exceptions to the ordinary thin-entry rules. If they contain only SSOT routing, generated marker, and a few core-invariant summaries, treat them as SSOT-generated thin adapters; if they carry commands, directory maps, workflow state, architecture constraints, model/config rules, testing strategy, agent operation preconditions, or other long-lived facts, they are simultaneously source material and must undergo fact review. `thin-adapterize` is only a conditional suggestion: propose it only when long-lived facts have been migrated into SSOT, the project wants the file hosted by SSOT, or the user explicitly requests it; hand-written or mixed startup files may retain local facts but must accept `[CORE-REF]` review.

Handling rules:

- Compare item-by-item against code/config/schema/test, package manifests, Makefile, CI config, SSOT architecture/testing/development, and the current skill protocol.
- If a long-lived fact is valid but should not remain in the startup file, absorb it into the SSOT authoritative location, and propose `thin-adapterize` when the conditions above are met.
- If a fact is stale or wrong, mark `stale/conflict`, give a concrete `update-doc` suggestion; do not silently ignore startup-file drift after absorbing the correct fact into SSOT.
- If a fact expresses target design but implementation has not landed, enter Current / Target / Gap, decisions, or open adjudications, and mark `record-conflict` in the core reference document review table.
- If the file does not exist and the project does not require the corresponding harness, record `not_applicable`; do not mechanically create startup files just to pass review.

## 2. Classification and handling rules

Classify each piece of source material on two axes:

1. **Absorption handling**: whether long-lived facts must enter SSOT, stay as a
   link-only source, be treated as stale/conflicting, or be retired.
2. **Lifecycle**: whether the source is current public explanation, working
   material, historical material, external source material, or a thin public
   entry.

The old absorption values remain valid, but `docs/**/*.md` is no longer
implicitly one kind of source. A draft, a PoC plan, an execution log, a
superseded design, and a public README need different authority and downgrade
rules.

Classify absorption handling:

| Classification | Applicability | Handling |
|---|---|---|
| `absorb` | Contains system knowledge, design intent, constraints, processes, gotchas, decisions, or risks that should be preserved long-term | Distill long-lived knowledge into the corresponding authoritative location, retain source pointer and evidence level; do not mirror full text. |
| `link-only` | Original is valuable but should not be copy-maintained, e.g., full tutorials, external specs, long background material, or public docs | Keep summary + link at the authoritative location; do not duplicate full text; note when to re-read the original if necessary. |
| `stale/conflict` | Conflicts with code fact, current runtime behavior, or existing design intent, or is internally outdated | Cannot be marked then skipped; must adjudicate current fact, write into Current / Target / Gap, update decisions, or register an open adjudication. |
| `obsolete` | Already invalid, retains only historical value, or has been explicitly replaced | Not used as current-fact evidence; if necessary keep historical pointer, replacement material, and do-not-revive note. |

Classify lifecycle:

| Lifecycle | Applies to | Required downgrade / authority fields |
|---|---|---|
| `working/research` | Research notes and landscape scans | `authority`, `owner`, `absorbed_to`, `do_not_use_for`, `review_on` |
| `working/draft` | Draft docs, unfinished specs, proposed copy | `authority`, `owner`, `absorbed_to`, `do_not_use_for`, `review_on` |
| `working/proposal` | Unaccepted design/product proposals | `authority`, `owner`, `absorbed_to`, `do_not_use_for`, `review_on` |
| `working/experiment` | Experiment notes or measured trials | `authority`, `owner`, `absorbed_to`, `do_not_use_for`, `review_on` |
| `working/poc` | PoC plans/results not yet promoted into product/architecture | `authority`, `owner`, `absorbed_to`, `do_not_use_for`, `review_on` |
| `working/prototype` | Prototype docs or exploratory UI/flow material | `authority`, `owner`, `absorbed_to`, `do_not_use_for`, `review_on` |
| `working/execution-log` | Task logs and chronological execution records | `authority`, `owner`, `absorbed_to`, `do_not_use_for`, `review_on` |
| `working/closure` | Closure reports and proof-of-work artifacts | `authority`, `owner`, `absorbed_to`, `do_not_use_for`, `review_on` |
| `working/report` | Generated or manual reports that summarize a batch | `authority`, `owner`, `absorbed_to`, `do_not_use_for`, `review_on` |
| `working/handoff` | Handoff notes for a next agent or operator | `authority`, `owner`, `absorbed_to`, `do_not_use_for`, `review_on` |
| `historical/superseded` | Replaced docs whose old form still matters | `authority`, `owner`, `absorbed_to`, `do_not_use_for`, `review_on` |
| `historical/deprecated` | Deprecated docs that must not drive current work | `authority`, `owner`, `absorbed_to`, `do_not_use_for`, `review_on` |
| `external/source-material` | Vendor specs, user-provided source, copied external reference | `authority`, `owner`, `absorbed_to`, `do_not_use_for`, `review_on` |
| `public/thin-entry` | Public-facing entry that should point at SSOT owners | `authority`, `owner`, `absorbed_to` or `ssot_owner`, `review_on` |

The downgrade fields may live in a file header near the top of the source file,
or in the `STATUS.md` source-material inventory row. Use stable field names so
Doctor/lint can find them: `authority`, `owner`, `absorbed_to`,
`do_not_use_for`, and `review_on`. Pattern-level rows are allowed for large
historical directories when every file under the pattern shares the same
lifecycle and downgrade fields.

All root public documentation and `docs/**/*.md` files must be either:

- inventoried in `STATUS.md` at file or audited pattern level;
- marked in-file with the lifecycle/downgrade header fields above; or
- covered by an audited exclusion row declaring `pattern`, `reason`, `owner`,
  `last_checked`, and `review_trigger`.

Missing inventory/header/exclusion is a deterministic Doctor failure for v2.38
projects. The rule exists to stop thick working or historical docs from
silently becoming current authority.

When absorbing, follow:

1. Distill only long-lived knowledge; do not copy full source text.
2. If the fact can be derived directly from code/config/schema/test, SSOT writes summary + pointer + why/risk/constraint.
3. Record original path, URL, filename, session position, or other stable source identifier.
4. Material classified as `stale/conflict` must continue to be routed; it cannot stay in matrix state.
5. Material classified as `obsolete` must not support `covered` or current fact; if the old form may tempt future agents to regress, write into architecture evolution / migration ledger, gotchas, or decisions.

Working and historical source material may contain precise implementation
language such as "current API", "runtime", "SDK", "schema", "acceptance", or
"roadmap". That is allowed only when the downgrade fields make clear what the
reader must not use it for and which SSOT owner holds the current authority.
Without that downgrade, the source is pretending to be current authority.

## 3. Thin-documentation rules

READMEs, docs, ADRs, PRDs, public statements, installation tutorials, link pages, or summary pages may exist, but if they carry independent long-lived facts they should become thin documentation:

- Keep only human-facing or entry-point-purpose summaries.
- Link to the authoritative location in `SSOT/`, or declare content is derived from SSOT.
- Do not maintain product promises, PRD, capability boundaries, user journeys, acceptance, architecture boundaries, runtime flows, state ownership, contracts, target design, constraints, gotchas, RCA, or tech debt in parallel with SSOT.
- If a thin document conflicts with current implementation, adjudicate current fact by code/config/schema/test, and mark the conflict-handling result in the source-material absorption matrix.
- If a thin document conflicts with product intent, retain both pieces of evidence and update product owner, product roadmap/acceptance, or open adjudications. If a thin document conflicts with technical design intent, retain both pieces of evidence and update architecture Current / Target / Gap, decisions, or open adjudications.

A `public/thin-entry` document that presents current authority must name the
SSOT owner (`ssot_owner` or `owner`) it derives from. If it cannot point to an
owner, it is not thin; classify it as source material and absorb or downgrade
it before treating it as current.

## 4. Conflict adjudication

When source material conflicts with code or SSOT, handle per the following rules:

| Conflict type | Adjudication |
|---|---|
| Source material describes current implementation but code/config/schema/test/runtime behavior disagrees | Current fact is determined by code/config/schema/test/runtime behavior; record the adjudicated fact and source in SSOT, mark source material as `stale/conflict`. |
| Source material describes target design, constraint, or unlanded plan but current implementation differs | Do not automatically judge code as correct; record both current implementation and target intent in architecture Current / Target / Gap, mark the relevant decision's `implementation_state` as `diverged` or `partial` if needed. |
| Source material describes product promises, PRD, product boundary, user journeys, or acceptance intent but current implementation differs | Product facts enter `product/`; implementation gaps enter `architecture/views/current-target-gap.md`, the relevant domain, testing, or tech-debt, and link to the product owner. Do not rewrite product promises inside architecture. |
| Two source materials conflict with each other | Retain both sources; prefer code fact for current implementation; design-intent conflicts enter decisions or open adjudications. |
| Source material language changes | Treat only as language-lock review lead; do not auto-rewrite `documentation_language`. |
| Source material requests restoring an old plan, old surface, or deprecated concept | Check architecture evolution / migration ledger, decisions, gotchas; if the old plan is forbidden to revive, record the conflict and avoid restoring per the source material. |

Conflicts that do not fit the above tiers must retain both pieces of evidence and enter the adjudication queue.

## 5. Source Routing

Source material is first split between "product facts" and "technical implementation/design facts". Long-lived product facts in PRD, product planning, user research, business constraints, acceptance notes, product copy, and user journey descriptions enter `product/`. Architecture only records how the system responds to these product constraints, or the technical gap between current implementation and product constraints.

### 5.1 Product Source Routing

| Source material content | Authoritative location |
|---|---|
| PRD spine, product posture, core capability map, key non-goals, owner links | `product/prd.md` |
| Users/operators, problems, product promise, product boundary, product language, long-lived product trade-offs | `product/product-model.md` |
| Product phase, roadmap intent, product acceptance gates, product-level gaps | `product/roadmap-and-acceptance.md` |
| User value, boundary, non-goals, acceptance meaning, roadmap state of a stable capability | `product/capabilities/<capability>.md`; if it has not reached the split threshold, keep it in `product/prd.md` or `product/product-model.md` |
| Cross-capability user/operator journey, touchpoints, experience constraints, product acceptance | `product/journeys/<journey>.md`; if it has not reached the split threshold, keep it in `product/prd.md` or `product/product-model.md` |

`product/README.md`, `product/capabilities/README.md`, and `product/journeys/README.md` only do Reader Map and owner indexing; they do not copy product fact bodies. Product capability files should stay thin: define user-visible value, boundary, non-goals, acceptance meaning, product language, roadmap/gap, and links to architecture owners. They do not maintain runtime flow, API, SDK, schema, persistence, or implementation listings.

### 5.2 Architecture Source Routing

Route architecture-related source material to a unique authoritative location by content:

| Source material content | Authoritative location |
|---|---|
| Technical system positioning, operating philosophy, primary technical actor/caller, technical operating main path, non-functional success criteria, impact of product constraints on architecture | `architecture/views/operating-model.md`, linking product owner |
| System/runtime execution, stage lifecycle, failure/recovery, observability signals, cross-domain runtime flow overview | `architecture/views/critical-journeys.md`, linking product journey/capability owner if applicable |
| Implementation Current / Target / Gap, migration roadmap, migration intent, unlanded technical targets, implementation gap against product acceptance | `architecture/views/current-target-gap.md`, linking `product/roadmap-and-acceptance.md` or relevant product owner |
| Components, boundaries, state, locks, resource lifecycle, contracts, failure recovery, verification evidence, domain-specific diagrams | `architecture/domains/<domain>/README.md` or legacy-compatible direct child-domain |
| Script/tool inventory, build/test commands, model generation, session analysis, version sync, import rewriting and other engineering automation | Default route to `development/`, `testing/`, `release/`, or deployment-related area; only when a script carries model-generation pipeline, session analysis, release consistency, state migration, or other architecture behavior does it also enter the relevant architecture view/domain |
| Decisions, rejected plans, rollback choices, no-revive bans, trade-off rationales | `decisions/`, and sync architecture evolution / migration ledger pointer |
| Incidents, RCA, recurrence risk, regression tests | `bugs/`, `gotchas/`, `testing/`, and sync the relevant domain |
| Performance/capacity, extension points, compatibility strategy | If a product promise, enter `product/`; if a system design fact or risk source, enter architecture; otherwise enter the corresponding engineering area or do not record |
| Pure public explanation, user documentation, installation tutorials | Keep as thin documentation or engineering-operation-area summary; do not serve as long-lived design-fact source |

View cannot be pure tables. If source material contains PRD, current-stage product goals, product promises, product non-goals, product acceptance criteria, or product principles, they must first be absorbed into `product/`; architecture view only records the implementation design, technical constraints, or implementation gap responding to these product facts, and links to the product owner. If source material contains technical operating philosophy, system operating paths, technical acceptance/recovery signals, or migration intent, they should be absorbed into `operating-model.md`, `critical-journeys.md`, or `current-target-gap.md`, not just marked read in `STATUS.md`.

Architecture root/views/domains must not redefine users, product promises,
product roadmap, product non-goals, or product acceptance meaning. They may
link product constraints and then own implementation response: runtime owner,
state/resource, contracts, lifecycle/concurrency, failure/recovery,
verification, and implementation current/target/gap.

## 6. Status synchronization

`STATUS.md` must retain the source material absorption matrix. Every read or change of source material that still has long-lived value records:

- Source material title or path/source.
- Classification: `absorb` / `link-only` / `stale/conflict` / `obsolete`, plus lifecycle when applicable (`working/*`, `historical/*`, `external/source-material`, `public/thin-entry`).
- Authoritative location.
- Absorption status: `pending` / `absorbed` / `linked` / `conflict-recorded` / `obsolete`.
- Conflict/adjudication: `ADJ-...` or `none`.
- Last-check date or commit/session identifier.

For v2.38 and later, rows that cover root public docs or `docs/**/*.md` should
also carry the downgrade/authority fields (`authority`, `owner`, `absorbed_to`,
`do_not_use_for`, `review_on`) either as columns or as compact key-value text in
the row. Audited exclusions carry `pattern`, `reason`, `owner`, `last_checked`,
and `review_trigger`.

Core reference documents must additionally maintain the core reference document review table in `STATUS.md`. The source material absorption matrix records "where long-lived facts are absorbed"; the core reference document review table records "whether the startup/reference file itself is still correct, and what should be changed"; the two cannot substitute for each other.

During bootstrap `SSOT/.bootstrap/manifest.md` also records absorption progress; before bootstrap cleanup, the status of source material with long-lived value must be transcribed into `STATUS.md`.
