# STATUS.md Protocol

This file owns the semantics of `SSOT/STATUS.md`. Read it when creating or
updating STATUS, advancing a waterline, declaring a stop conclusion, processing
source material, reviewing startup/reference documents, or handling
adjudications.

`STATUS.md` is a state register, not an evidence archive or narrative owner.
Apply KISS here: cells carry state, owner, date, result, and evidence pointers.
Paragraph reasoning, command output, copied checklists, and review transcripts
belong in the authoritative owner or evidence artifact.

## 1. Five Registers

STATUS has five durable registers. Each answers a different operational
question; do not make one register carry another register's job.

**Event-source coverage** says which commit, conversation/session, protocol
version, and documentation language the SSOT has reviewed. Write it at
bootstrap, audit catch-up, protocol upgrades, language-lock decisions, and final
waterline advancement.

**Area status** says whether each top-level SSOT area is covered, stale, gapped,
unknown, not applicable, or conflicted. Write it when an area's durable owner is
created, materially updated, found stale, or reviewed as covered.

**Source-material and core-reference review** records where README/docs/ADR/PRD
and startup agent files were absorbed or checked. Write it when a source
artifact is read for durable facts, when a startup file is found, or when a
source conflict appears.

**Open adjudications and open gaps** keep blockers visible. Write adjudications
when a human choice is needed; write gaps when evidence is missing, scope is
uncovered, or a covered claim would otherwise hide uncertainty.

**Stop review and protocol waterline** records the review that allows a stop
claim or waterline advance. Write it before claiming `covered`, `converged`,
bootstrap `passed`, `no-op`, language-lock changes, or final advancement of
`tracked_commit`, `tracked_session`, or `tracked_skill_version`.

## 2. STATUS Decision Path

Follow this path before writing STATUS:

1. Re-read the current file. If another actor advanced a waterline, review on
   the new baseline.
2. Check open adjudications. `pending` entries and due `deferred` entries block
   ordinary work until resolved, superseded, or re-deferred.
3. Check the language lock. New SSOT body text must match
   `documentation_language` except for paths, commands, identifiers, enum
   values, API names, and direct quotes.
4. Decide which register owns the fact. If the fact needs narrative, put the
   narrative in its owner and leave a pointer in STATUS.
5. If the write would support a stop claim or waterline advance, record the
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

`converged` is never inferred from all rows looking green; it is a stop
conclusion. `covered` is also a stop conclusion for that area/scope.

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

## 6. Stop Review Gate

Each time you prepare to declare `converged`, `covered`, `passed`, `done`,
`no-op`, `no update needed`, accept `single-level` or a stop split, change
`documentation_language`, or advance `tracked_commit`, `tracked_session`, or
`tracked_skill_version`, first create a stop-review record.

The record says: scope, stop claim, reviewer, reviewed time, result, evidence
pointer, and remaining changes. `result` is only `no-more-required-changes` or
`needs-fix`. If result is `needs-fix`, the stop conclusion is not accepted.

Default reviewer is `self-reviewed`. Independent review is required only for
four exceptions:

1. Bootstrap overall `passed`.
2. `documentation_language` changes.
3. `semantic_impact=high` protocol upgrades.
4. First declaration of `coverage_result=converged`.

Daily advancement of `tracked_commit`, `tracked_session`, and
`tracked_skill_version` outside those four exceptions is self-reviewed, but the
review still must be explicit and scoped.

## 7. Protocol Waterline

The current SSOT Skill protocol version comes from `metadata.protocol_version`
in the loaded/installed `ssot-preflight/SKILL.md`. The applied project protocol
is `tracked_skill_version` in STATUS.

Rules:

- New SSOT initializes `tracked_skill_version` to the current protocol version.
- Missing legacy waterline means `unknown/legacy`; run a baseline
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
| `none` | Installer/packaging/no-op changes; no SSOT protocol semantics touched | No content stop review required; no-op waterline may self-review | Archive/current entry optional unless needed for completeness |
| `low` | Documentation/editorial changes; no new owner, area, or stop-review trigger | Self-review | May be summarized in archive/current entry |
| `medium` | New semantic check/tag, owner-boundary clarification, or cross-skill write-routing obligation without a new top-level area, STATUS field, lifecycle skill, or high-impact stop-review trigger | Self-review with explicit checklist | Standalone current/archive entry required |
| `high` | New SSOT area, new STATUS field owner, new stop-review trigger, or new lifecycle skill | Independent reviewer required | Standalone current/archive entry required |

When `semantic_impact` is missing from `ssot-preflight/SKILL.md`, `ssot-lint`
reports a FAIL.

## 8. Appendix A: Table Schemas

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

| Source material | Path/source | Classification | Authoritative location | Absorption status | Conflict/adjudication | Last check |
|---|---|---|---|---|---|---|
| `<title>` | path / URL / session marker | absorb / link-only / stale/conflict / obsolete | SSOT/... | pending / absorbed / linked / conflict-recorded / obsolete | ADJ-... / none | ISO date or commit |

Core reference document review:

| Document | Role | Authority relation | Status | Evidence/action |
|---|---|---|---|---|
| AGENTS.md / CLAUDE.md / Cursor rules | startup / agent-rules / reference / none | thin-adapter / source-material / mixed | covered / stale / conflict / missing / not_applicable | pointer to evidence and next action |

Open adjudications:

| id | status | scope | question | next trigger |
|---|---|---|---|---|
| ADJ-YYYYMMDD-NN | pending / deferred / resolved / superseded | impact scope | question to adjudicate | needed_by or revisit_condition |

Open gaps:

| Area | Status | Gap description | Blocking level |
|---|---|---|---|
| architecture/query-engine | gap | state boundary unconfirmed | non-blocking |

Stop review gate:

| scope | stop_claim | reviewer | reviewed_at | result | evidence | remaining_changes |
|---|---|---|---|---|---|---|
| `<scope>` | covered / converged / no-op / tracked_* / protocol-upgrade | self-reviewed / reviewer-id | ISO time | no-more-required-changes / needs-fix | pointer | required fixes or none |

When a case needs the former wide core-reference or adjudication fields
(`check scope`, `last checked`, `source`, `links`, etc.), place those details in
an appendix/evidence artifact and keep this register as the route.

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

Advancing a tracked waterline to the final target requires a scoped
`no-more-required-changes` stop review. Daily advancement is self-reviewed; the
four exceptions in §6 require independent review.
