# STATUS.md Protocol

This file owns the semantics of `SSOT/STATUS.md`. Read it when creating or
updating STATUS, advancing a tracking baseline, declaring a stop conclusion, processing
source material, reviewing startup/reference documents, or handling
adjudications.

`STATUS.md` is a state register, not an evidence archive or narrative owner.
Apply KISS here: cells carry state, owner, date, result, and evidence pointers.
Paragraph reasoning, command output, copied checklists, and review transcripts
belong in the authoritative owner or evidence artifact.

## 1. Exact STATUS schema

STATUS has one exact state schema, not an informal list of “five registers”.
Each section below owns one operational question. English and Chinese may
translate headings and column labels as shown in Appendix A, but the row IDs,
states, tracking-baseline fields, area tokens, and review verdicts remain protocol
tokens.

| Profile | Section | Operational question |
|---|---|---|
| `S01` | Event-Source Coverage | Which commit, session, protocol, language lock, and stop review have been reviewed? |
| `S02` | Area Status | Which exact SSOT areas are covered, gapped, stale, unknown, not applicable, or conflicted? |
| `S03` | Source Material Absorption | How is each durable source classified, trusted, absorbed, limited, reviewed, and routed on conflict? |
| `S04` | Core Reference Document Review | Which startup/reference files were reviewed at which baseline, and where does their durable truth or gap live? |
| `S05` | Stop Review Gate | Which reviewer and role authorised which stop claim, with what artifact? |
| `S06` | Open Adjudications and Open Gaps | Which stable item affects which task, who owns it, what retriggers it, how is it resolved, and what closes it? |
| `S07` | All STATUS tables | Are cells pointer-sized rather than narrative or execution ledgers? |
| `S08` | Open Gaps | Can a reader see task impact, blocking/retrigger condition, and a reachable resolving route? |
| `S09` | Quality, Risk, and Governance | Is every `Q01`-`Q21` concern disposed across product, architecture, process/evidence, and gap ownership? |
| `S10` | Pending Captures | What durable fact is awaiting absorption, from which source, into which proposed owner, why, at what priority/trigger, and who closes it? |
| `S11` | Source Inventory Exclusions | Which source patterns were deliberately excluded, by whom, when checked, and what forces review again? |

The Area Status baseline is exact: `product`, `architecture`, `process`,
`development`, `testing`, `benchmark`, `deployment`, `release`, `operations`,
`security-and-compliance`, `records`, `decisions`, `research records`,
`gotchas`, `bugs`, `tech-debt`, and `glossary` each appear once. `process` and
`records` are aggregate reader routers, not substitutes for their child rows.
An extension row uses `x-<slug>` and its Notes cell contains `extension:` plus
one resolving Markdown owner link. Any other token is a schema error.

Write the matching section when its fact changes. If the fact needs a causal
explanation, command transcript, or history, write that in the durable owner or
review artifact and leave one state plus one route in STATUS.

## 2. STATUS Decision Path

Follow this path before writing STATUS:

1. Re-read the current file. If another actor advanced a tracking baseline, review on
   the new baseline.
2. Check open adjudications. `pending` entries and due `deferred` entries block
   ordinary work until resolved, superseded, or re-deferred.
3. Check the language lock. New SSOT body text must match
   `documentation_language` except for paths, commands, identifiers, enum
   values, API names, and direct quotes.
4. Decide which exact STATUS section owns the fact. If the fact needs narrative, put the
   narrative in its owner and leave a pointer in STATUS.
5. If the write would support a stop claim or tracking-baseline advancement, record the
   stop review first. Without a `no-more-required-changes` review for the
   declared scope, the stop claim does not hold.
6. If protocol drift exists, route to the protocol upgrade ledger before
   advancing `tracked_skill_version`.

## 3. Coverage Rules

`coverage_result` is the whole-SSOT state:

| State | Meaning |
|---|---|
| `converged` | Current SSOT matches the reviewed commit, session, protocol, and language lock, and an independent reviewer returned `no-more-required-changes` for overall convergence. |
| `in_progress` | Daily maintenance; some areas may still have gaps or stale content. |
| `catching_up` | A large backlog is being reviewed in segments. |
| `bootstrap` | First-time SSOT establishment is incomplete. |

Area status values are:

| Status | Meaning |
|---|---|
| `covered` | The area matches the reviewed commit/session/protocol scope, contains no candidate/hypothesis content in covered scope, and has a stop review for that scope. |
| `gap` | Required or applicable content is missing or incomplete. |
| `stale` | Content lags behind reviewed code, conversation, or protocol. |
| `unknown` | Evidence is insufficient to judge. |
| `not_applicable` | The engineering-operation area does not apply, with reason in the owner. |
| `conflict` | Evidence sources conflict and have not been adjudicated. |

`covered` always requires the area's canonical owner `README.md` to exist.
`process: covered` additionally requires development, testing, benchmark,
deployment, release, operations, and security/compliance to be `covered` or
reasoned `not_applicable`; `records: covered` requires decisions, research,
gotchas, bugs, and technical debt to meet the same condition. A child gap,
stale state, unknown, or conflict therefore keeps its aggregate router from
`covered`.

Product and architecture do not add child rows to Area Status. Their one
aggregate row is synthesised from their manifests and structured reader
review. In particular, `architecture: covered` requires the architecture root,
the views collection, and every direct numbered domain to have its canonical
reader README and location-specific manifest; the root owner registry must be
one-to-one with those numbered domains, and every covered manifest must route
to a current passing review artifact. A missing or incoherent child therefore
keeps the architecture aggregate from `covered`, but never creates an
`architecture/views` STATUS row.

Only conditionally applicable engineering-operation rows (`testing`, `benchmark`,
`deployment`, `release`, `operations`, and `security-and-compliance`) and
`research records` may use `not_applicable`. Their Notes cell names the reason
and links the boundary owner. Product, architecture, process, records,
development, decisions, gotchas, bugs, technical debt, and glossary are always
applicable. A missing directory, implementation, automated test suite, live
environment, or research entry is not by itself proof of non-applicability. Use
`not_applicable` only when that lifecycle or question genuinely does not apply;
if it should exist but does not, use `gap`. A repository with no research
entries may use a covered-empty research index when the area still provides the
owner and intake route.
An empty status is permitted only while `coverage_result: bootstrap`; it is not
a completion claim.

`converged` is never inferred from all rows looking green; it is a stop
conclusion. `covered` is also a stop conclusion for that area/scope.

At protocol v2.60, `process: covered`, `records: covered`, and
`glossary: covered` each require the matching lightweight exact-scope review
defined by `reader-quality.md §7.7`. The Area Status Notes cell keeps a direct
canonical-owner link plus exactly one matching review-artifact link; the
matching Stop Review Gate row points to that same artifact.
`coverage_result: converged`
also requires distinct `root` and `status` exact-scope artifacts. Each artifact
includes the fixed semantic-truth sample, exact target-coverage matrix,
plain-language profile answers, and area-disposition fingerprint required by
`reader-quality.md §7.7`; a complete disposition table with only resolving links is not enough. These gates do
not apply below v2.60 or while the corresponding stop claim is not being made.

Product and architecture have extra coverage expectations because they are the
two trunks most likely to become fake coverage. Product coverage requires a
product spine and unique owners for promises, users/operators, capability,
journey, roadmap, non-goals, and acceptance. Architecture coverage requires a
reader mental model, owner boundaries, evidence-backed current facts,
appropriate Mermaid diagrams for non-obvious boundaries/flows/state/failure,
and explicit gaps for uncovered scope. Appendix B keeps the detailed checklist.

## 4. Register-Only Boundaries

STATUS tables may keep schemas, but cells stay small. If a cell needs more than
one short sentence, it is not a STATUS note anymore.

Allowed in STATUS cells:

- owner path, area, scope, status, date, result, reviewer, evidence pointer;
- open gap/adjudication IDs;
- short not-applicable rationale;
- short coverage-depth phrase for architecture.

Not allowed in STATUS cells:

- command transcripts, latest green/red run history, proof-of-work chronology;
- copied checklists or review transcripts;
- child-entry counts or derived child status;
- source-material summaries that should live in the owner.

Test/run evidence can support a stop claim, bug fix, release note, CI artifact,
final response, or stop-review evidence. It enters STATUS only when it changes
coverage state or points to a gap/adjudication.

## 5. Adjudications and Gaps

Open adjudications are the new-session gate. A `pending` item blocks ordinary
work. A `deferred` item blocks once its `revisit_condition` fires. Legal states:

| Status | Meaning |
|---|---|
| `pending` | Blocks new-session entry. |
| `deferred` | Does not block until `revisit_condition` is met. |
| `resolved` | Adjudicated; retained for history. |
| `superseded` | Replaced by another adjudication; pointer retained. |

The blocking prompt stays brief:

```text
The following pending adjudications must be processed before continuing:
- ADJ-YYYYMMDD-NN (scope): question; needed_by; links
Please choose for each: accept / reject / alternative plan / defer.
```

Open gaps record unresolved information gaps by area/view/domain. A gap may not
block daily code work, but it blocks `covered` for the affected scope. Do not
use `unknown` to hide evidence that exists; use the evidence or name the gap.

Both sections use the exact eight-column lifecycle schema in Appendix A. An
adjudication ID is `ADJ-YYYYMMDD-NN`; a gap ID is `GAP-YYYYMMDD-NN`. IDs are
unique across their section. Every real row names the affected scope or task, a
responsible owner, an observable blocking/retrigger condition, and one
resolving Markdown link or explicit `$ssot-*` route. `resolved` or
`superseded` rows additionally link closure or supersession evidence. Starter
rows may be completely empty; a partly filled row is a real row and must pass
the full contract.

## 6. Stop Review Gate

Each time you prepare to declare `converged`, `covered`, `passed`, `done`,
`no-op`, `no update needed`, accept `single-level` or a stop split, change
`documentation_language`, or advance `tracked_commit`, `tracked_session`, or
`tracked_skill_version`, first create a stop-review record.

The record says: scope, stop claim, reviewer, reviewer role, reviewed time,
result, evidence pointer, remaining changes, and exactly what the review
authorises. `result` is only `no-more-required-changes` or `needs-fix`. If
result is `needs-fix`, the stop conclusion is not accepted. The evidence cell
contains one resolving Markdown link; a chat statement or bare path is not a
durable review artifact.

For lightweight v2.60 exact-scope reviews, `scope` is `process`, `records`,
`glossary`, `root`, or `status`. Covered area rows use stop claim `covered` and
`authorises=area:<scope>:covered`. Root and STATUS rows use stop claim
`converged` and `authorises=coverage_result:converged`. Reviewer, role, review
date, authorisation, and verdict agree with the linked artifact. A scope has
exactly one passing row for the current authorisation; older rows must not
compete to authorise the same current claim.

Root and STATUS can be reviewed independently while overall coverage remains
`bootstrap`, `catching_up`, or `in_progress`. Those rows use stop claim
`covered` and `authorises=scope:root:covered` or
`scope:status:covered`. They prove only that document scope; convergence still
requires current root and STATUS artifacts that explicitly authorise
`coverage_result:converged`.

The default is a scoped self-review, recorded with
`reviewer_role: scoped-self-review`. Independent review is required only for
four exceptions:

1. Bootstrap overall `passed`.
2. `documentation_language` changes.
3. `semantic_impact=high` protocol upgrades.
4. First declaration of `coverage_result=converged`.

Daily advancement of `tracked_commit`, `tracked_session`, and
`tracked_skill_version` outside those four exceptions uses that scoped
self-review, but the review still must be explicit and scoped.

## 7. Tracking baseline and protocol version

The canonical reader-facing name is **tracking baseline**: the reviewed commit,
session, and protocol version recorded in STATUS. Localised templates translate
this term consistently; older names belong only to historical records.

The current SSOT Skill protocol version comes from `metadata.protocol_version`
in the loaded/installed `ssot-preflight/SKILL.md`. The applied project protocol
is `tracked_skill_version` in STATUS.

Rules:

- New SSOT initializes `tracked_skill_version` to the current protocol version.
- A missing legacy tracking baseline means `unknown/legacy`; run a baseline
  protocol-upgrade audit.
- When the loaded protocol is greater than `tracked_skill_version`, read the
  protocol upgrade router:
  [`protocol-upgrades.md`](../../ssot-audit/references/protocol-upgrades.md).
- Complete all unapplied version reviews before advancing
  `tracked_skill_version`.
- Every protocol bump must update the upgrade ledger: the router, current entry,
  or archive entry as applicable. A missing current-version entry makes the
  release incomplete.

Impact classification:

| Impact | Meaning | Review requirement | Ledger entry |
|---|---|---|---|
| `none` | Installer/packaging/no-op changes; no SSOT protocol semantics touched | No content stop review required; a no-op tracking-baseline change may use scoped self-review | Archive/current entry optional unless needed for completeness |
| `low` | Documentation/editorial changes; no new owner, area, or stop-review trigger | Self-review | May be summarized in archive/current entry |
| `medium` | New semantic check/tag, owner-boundary clarification, or cross-skill write-routing obligation without a new top-level area, STATUS field, lifecycle skill, or high-impact stop-review trigger | Self-review with explicit checklist | Standalone current/archive entry required |
| `high` | New SSOT area, new STATUS field owner, new stop-review trigger, new lifecycle skill, canonical physical-layout change, or upgrade helper that bulk-mutates a consumer tree | Independent reviewer required | Standalone current/archive entry required |

When `semantic_impact` is missing from `ssot-preflight/SKILL.md`, `ssot-lint`
reports a FAIL.

## 8. Appendix A: Exact table schemas

Event-source coverage:

| Field | Value |
|---|---|
| `tracked_commit` | Latest commit reviewed by SSOT. |
| `tracked_session` | Latest conversation/session reviewed by SSOT. |
| `tracked_skill_version` | Protocol version reviewed and applied. |
| `documentation_language` | Locked SSOT body language. |
| `documentation_language_evidence` | Evidence or user decision behind the language lock. |
| `coverage_result` | `converged` / `in_progress` / `catching_up` / `bootstrap`. |
| `last_stop_review` | Most recent stop-review pointer. |

Area status:

| Area | Status | Notes |
|---|---|---|
| product | covered / gap / stale / unknown / conflict | pointer-sized note |
| architecture | covered / gap / stale / unknown / conflict | pointer-sized note |
| ... | ... | ... |

Source material absorption:

| Source ID | Source material | Path/source | Lifecycle | Classification | Authority | Durable owner / absorbed_to | Do not use for | Review |
|---|---|---|---|---|---|---|---|---|
| SRC-YYYYMMDD-NN | title | path / URL / session marker | working/research / working/draft / working/proposal / working/experiment / working/poc / working/prototype / working/execution-log / working/closure / working/report / working/handoff / historical/superseded / historical/deprecated / external/source-material / public/thin-entry | absorb / link-only / stale/conflict / obsolete | current / downgraded / external / historical | one resolving owner link | named claim this source cannot support | review_on=YYYY-MM-DD; status=pending / absorbed / linked / conflict-recorded / obsolete; conflict=none / ADJ-ID |

`Source ID` is unique. Durable owner contains one resolving Markdown link. A
`stale/conflict` row names an adjudication or gap in `Review`; an absorbed,
linked, or obsolete row may use `conflict=none`. A completely empty starter row
is allowed.

Source inventory exclusions:

| Pattern | Reason | Decision owner | Last checked | Review trigger |
|---|---|---|---|---|
| path/glob | why this class is excluded | one resolving owner link | YYYY-MM-DD | observable condition |

Each pattern appears once. `Decision owner` resolves; `Last checked` is a real
date; and `Review trigger` is observable rather than “later”.

Core reference document review:

| Document | Role | Relation | Status | Reviewed baseline | Durable owner / scope | Gap / conflict route |
|---|---|---|---|---|---|---|
| AGENTS.md | startup / agent-rules / reference / none | thin-adapter / source-material / mixed | covered / stale / conflict / missing / not_applicable | commit=<sha>; session=<id-or-none> | one resolving Markdown owner/scope link | none: no gap / one resolving Markdown link / explicit `$ssot-*` route |

Each document path appears once. A real row always records a reviewed commit
and session (use `none` only when that event source genuinely does not exist),
a durable owner or reviewed scope, and a gap/conflict route or a reasoned
`none:` disposition.

Open adjudications:

| ID | State | Affected scope / task | Question / missing evidence | Responsible owner | Blocking / retrigger condition | Resolving route | Closure / supersession evidence |
|---|---|---|---|---|---|---|---|
| ADJ-YYYYMMDD-NN | pending / deferred / resolved / superseded | scope and affected task | question | responsible owner | observable condition | one resolving link or `$ssot-*` route | closure link when resolved/superseded; otherwise `none: open` |

Open gaps:

| ID | State | Affected scope / task | Question / missing evidence | Responsible owner | Blocking / retrigger condition | Resolving route | Closure / supersession evidence |
|---|---|---|---|---|---|---|---|
| GAP-YYYYMMDD-NN | gap / unknown / resolved / superseded | scope and affected task | missing fact or proof | responsible owner | observable condition | one resolving link or `$ssot-*` route | closure link when resolved/superseded; otherwise `none: open` |

Pending captures:

| ID | Source | Proposed owner | Reason | Priority / trigger | Responsible owner | State | Closure evidence |
|---|---|---|---|---|---|---|---|
| CAP-YYYYMMDD-NN | source pointer | one proposed-owner link | why the fact is durable | priority plus observable trigger | one responsible-owner link or `$ssot-*` route | pending / routed / absorbed / deferred / expired | closure link when absorbed/expired; otherwise `none: open` |

Capture IDs are unique. This table does not retain the former `captured_at`,
`about`, `altitude_guess`, `rule`, `evidence`, or `signal_source` taxonomy; the
source, owner, reason, trigger, responsibility, and closure are the durable
questions.

Stop review gate:

| Scope | Stop claim | Reviewer | Reviewer role | Reviewed at | Result | Evidence | Remaining changes | Authorises |
|---|---|---|---|---|---|---|---|---|
| scope | covered / converged / no-op / tracked_commit / tracked_session / tracked_skill_version / protocol-upgrade / documentation_language | stable reviewer ID | scoped-self-review / independent-reviewer / independent-cold-reader | ISO date or time | no-more-required-changes / needs-fix | exactly one resolving Markdown artifact link | required fixes or none | exact tracking baseline or area claim authorised |

When a case needs additional chronology, reasoning, commands, or evidence,
place those details in an appendix/evidence artifact and keep these exact
tables as routes. Do not extend a STATUS row sideways to recreate an archive.

## 9. Appendix B: Product and Architecture Coverage

Product can be `covered` only when the product trunk exists and the current
scope has unique product owners for PRD posture, users/operators, promises,
boundaries/non-goals, capabilities, journeys, roadmap intent, and acceptance.
Capability/journey splits are only for stable product boundaries, not one-off
tickets, UI scripts, tests, or implementation flows. Architecture links product
owners and records technical response/gap; it does not redefine product facts.

Architecture can be `covered` only when a reader can get the system mental
model quickly, Reader Maps only route to owners, current claims have
code/config/schema/test/runtime evidence, target claims have design evidence,
domain boundaries pass the independence test, and required diagrams exist for
non-obvious boundary/flow/state/lifecycle/failure/trust concerns. Uncovered
scope is marked `gap` or `unknown`; a missing/stale required diagram blocks
coverage for the related scope.

## 10. Update Discipline

Before updating any SSOT file, read `documentation_language`. When the field is
missing, fill it first; when language evidence is mixed or insufficient, ask the
user. Subsequent source-material language changes do not automatically switch
the lock; use adjudication plus independent review.

Advancing a tracking-baseline field to the final target requires a scoped
`no-more-required-changes` stop review. Daily advancement uses
`reviewer_role: scoped-self-review`; the four exceptions in §6 require
independent review. Product or architecture high-impact adoption uses
`independent-cold-reader`; the other independent-review exceptions use
`independent-reviewer`.
