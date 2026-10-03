---
name: ssot-preflight
description: Repository SSOT preflight before substantive code, config, docs, review, debugging, refactoring, or planning work. Use to check SSOT/STATUS.md, open adjudications, documentation language, protocol version, minimal SSOT read routing, and in-task SSOT write triggers. Do not use for pure operations, trivial format-only edits, or non-repository chat.
metadata:
  protocol_version: "2.86"
  bundle: "SSOT Skill"
  semantic_impact: medium
---

# SSOT Preflight

You are at the start of substantive repository work. Identify which planned
actions depend on unresolved decisions and which durable facts to capture.
Read-only investigation may proceed to establish scope and evidence; clear
the applicable gates before changing code or docs in the affected scope.

## Clear the gate

Read `SSOT/STATUS.md` first. Before a substantive change, answer, in order:

- **Adjudications.** Read `## Open Adjudications` / `## 开放裁决项`
  (legacy `## 待裁决项`). A `pending` item, or a `deferred` item whose
  revisit condition has fired, blocks only actions that depend on its
  unresolved decision: match the affected scope/task and blocking condition,
  including shared contracts and explicitly repository-wide rules. Continue
  unrelated work and read-only investigation. A future deferred item does not
  block by itself; existing confirmed rules still bind. Apply an existing
  explicit user decision when it settles the item, recording its authority;
  do not ask for the same decision again or re-defer an item on your own.
  For unclear scope, inspect the owner and hold only potentially dependent
  changes while clarifying. See `references/status-protocol.md §5`.
- **Adjudication boundary (v2.64).** Rows under the `SSOT/README.md`
  `## 裁决边界` / `## Adjudication boundary` section are rules established
  by human decision. If your task would alter the behaviour a registered
  rule protects, that rule's owner body is mandatory reading. Changing the
  rule itself — its meaning, scope, or status — is a human decision
  recorded as a `04-records/decisions/` entry or explicit user directive;
  an agent files `ADJ-` for conflicts instead of rewriting the rule.
  `candidate` rows are proposals: respect them as strong defaults, but
  they do not block work the way `confirmed` rows do.
- **Documentation language.** Read `documentation_language` and its
  evidence; SSOT Markdown you write this task must match it — except for
  paths, commands, identifiers, enum values, API names, and direct quotes.
- **Protocol version.** Compare this file's `metadata.protocol_version`
  against `STATUS.md` `tracked_skill_version`. Project behind (or the version
  is missing / `unknown/legacy`) -> report the lag and route to `$ssot-audit`
  before any SSOT write or tracking-baseline advance. Read-only investigation
  and changes that write no SSOT may proceed meanwhile, and closeout must
  not write new-protocol content into an unaudited STATUS. Installed bundle
  behind project -> report stale install;
  never downgrade the project. If the user names a newer source checkout of
  the bundle (or one is vendored in the repository) than the installed copy
  currently being read, report the install as stale and reinstall from that
  checkout before relying on new protocol clauses.
- **Freshness floor (conditional).** This binds only where a coverage claim
  exists: any Area Status `covered` / `partial`, or `coverage_result:
  converged`. When it binds, `tracked_commit` must be ancestor-or-equal of
  `HEAD`; a `covered` / `partial` claim whose reviewed baseline is behind
  `HEAD` must be re-confirmed by a scoped self-review within the same task or
  demoted to `stale`. An honest `in_progress` / `bootstrap` / `catching_up`
  repo with no coverage claim owes no freshness proof.

## Route your reads, don't bulk-load

The mandatory floor is `SSOT/STATUS.md` (adjudications, language, version
— cleared above) plus `SSOT/README.md` as the project-specific router —
including its `## 裁决边界` register when present. Read
its task-entry map and read only the owners it routes for this task. The
`01-product/README.md` and `02-architecture/README.md` trunks are read only when
the task-entry map routes the task to them — not by default. If the
task-entry map is missing or does not route the current task, fall back to
reading `01-product/README.md` and `02-architecture/README.md` so a thin-router
repo still gets trunk coverage.

Skip this entire skill only for non-repository chat, pure command
execution, or mechanical typo/format edits that cannot alter architecture,
contracts, state, behaviour, workflows, tests, doc truth, or external
surfaces.

## Capture durable facts as they surface

While working, watch for facts that outlive this task — new/removed APIs,
schema, contracts, lifecycle, trust boundaries, deployment policy, test
policy, confirmed root causes, user-locked decisions, product promises,
"do not revive" paths, repeated-failure-derived agent discipline. When one
appears, either update the unique authority immediately (when clear), or
write a short delta and resolve it at `$ssot-closeout` before final
response, `claim_done`, or commit. Detail (including the `Rule / Trigger /
Why / Evidence / Failure-mode` discipline schema) lives in
`references/area-model.md §2.4` and in `$ssot-closeout` references — not
here.

## Surface task-relevant open risks

Before implementation or final planning, scan the owner files the router
actually routed the task to, plus `STATUS.md ## Open Gaps`. Report the
entries whose trigger, path glob, owner, capability, journey, runtime owner,
command, or failure mode overlaps the task. Cold-scanning the full
`04-records/tech-debt/`, `04-records/bugs/`, or `04-records/gotchas/` directories is the agent's call, not a
default obligation — do it when the routed owners or the task shape make it
worthwhile. These are recommendations, not automatic blockers: each one must be
handled during the task by fixing it, explicitly deferring it with the owner and
reason still valid, or naming the next action in closeout.

Classify each overlapping entry before work starts:

- `fix-now`: current facts are wrong, misleading to the agent, or block
  closeout alignment.
- `recommend-now`: low-cost, high-confidence repair that should be handled in
  this batch.
- `defer-visible`: not blocking this batch, but deferral must name the owner or
  owner record, reason, closure condition, revisit signal, verification guard,
  and next concrete action.
- `ignore-for-scope`: no task overlap after inspection; name why it is outside
  this batch.

`defer-visible` is a floor, not an excuse to disappear work. Vague wording such
as "later", "someday", "future work", or a locked-language equivalent of
"handle later" is invalid unless the same record or STATUS row carries the
owner/record pointer and the retrigger/guard that makes the deferral visible to
the next agent.

Do not treat downgraded working docs or historical source material as current
open risk unless STATUS or an owner entry promotes the risk. Do not hide a
fallback, compat shim, temporary workaround, TODO/FIXME/HACK, later-remove note,
or waiver behind ordinary prose; it must have a registered owner, reason,
closure condition, revisit signal, and verification guard in `04-records/tech-debt/`,
`04-records/bugs/`, `04-records/decisions/`, or `STATUS.md` as appropriate.

## Park user-directive signals

Watch the user's prompts for an explicit lift-or-kill directive
("promote this", "never again"), a repeated same-kind correction across
turns, or recent prompts clustering in one domain. When one surfaces
and the rule is not already a clear durable fact you can write into the
unique authority per the section above, park one `CAP-` row
in `SSOT/STATUS.md ## Pending Captures` using the sole schema in
`references/status-protocol.md §8 Appendix A`: start at `State: pending`,
retain the user-directive source and session/date anchor, and name a proposed
owner, responsible route, and review trigger. An inferred pattern is a
candidate interpretation, not a user-approved rule. Let `$ssot-closeout` or
`$ssot-audit` route it; parking the signal does not itself authorise promotion
or edits to another owner. Detail on the two evidence streams and move
semantics lives in `$ssot-closeout references/promotion-rationale.md`.

## When this skill is wrong, route out

| Situation | Skill |
|---|---|
| No `SSOT/` yet, `coverage_result: bootstrap`, or an active bootstrap manifest has unfinished phases (retained `.bootstrap/` review artifacts alone do not trigger this route) | `$ssot-bootstrap` |
| About to commit, `claim_done`, or finalise after substantive change | `$ssot-closeout` |
| Catch up commits / sessions, or protocol version is behind | `$ssot-audit` |
| Health check, independent stop review, CORE-REF / ADAPTER / CONSUMPTION | `$ssot-doctor` |
| Legacy `$ssot-skill` mention | route via `ssot-skill` shim back here |

**The bootstrap route needs the user's say.** Bootstrap writes a whole
documentation tree and can take several sessions, so it is not a side effect
of an unrelated task. When the route fires, the user has not asked for SSOT
creation, and no user-authorised bootstrap is under way, say that SSOT is
missing or unfinished, offer to bootstrap now, and otherwise do the requested
task without the SSOT lifecycle gates (an existing `STATUS.md` adjudication
that covers the task still applies). Remember the answer for the session. A
declined or deferred bootstrap leaves nothing to reconcile: closeout applies
once SSOT exists or the user authorises creating it.

## Load on demand

| When the task hits | Read |
|---|---|
| STATUS coverage states, adjudications, gaps, tracking baselines, stop gates | `references/status-protocol.md` |
| README/docs/ADR/runbook/PRD/core-ref classification and absorption | `references/source-material.md` |
| Candidate / hypothesis / source-backed knowledge | `references/knowledge-integrity.md` |
| Architecture root/views/domains, Reader Map, decomposition, coverage depth | `references/architecture.md` |
| Top-level area responsibilities and task-entry mapping rules | `references/area-model.md` |
| Writing or reviewing any reader-facing SSOT body; product/architecture use full task-based acceptance and process/records/glossary/root/STATUS use exact-scope acceptance | `references/reader-quality.md` |

## Things this gate must not be used for

- A second code/schema/router source. Current implementation comes from
  code, config, schema, tests, and actual behaviour — not SSOT.
- Copying full source documents into SSOT. Absorb durable facts into one
  authority with evidence; do not mirror.
- Carrying candidate or hypothesis claims inside authoritative architecture
  bodies.
- Self-advancing `tracked_commit`, `tracked_session`,
  `tracked_skill_version`, language lock, bootstrap `passed`, or
  `converged` without the required independent review.
- Re-expanding this preflight file with bootstrap, doctor, audit, or
  closeout procedures. Route to those skills.
