---
name: ssot-preflight
description: Repository SSOT preflight before substantive code, config, docs, review, debugging, refactoring, or planning work. Use to check SSOT/STATUS.md, open adjudications, documentation language, protocol version, minimal SSOT read routing, and in-task SSOT write triggers. Do not use for pure operations, trivial format-only edits, or non-repository chat.
metadata:
  protocol_version: "2.50"
  bundle: "SSOT Skill"
  semantic_impact: medium
---

# SSOT Preflight

You are at the start of substantive repository work. Your job here is not to
do the work — it is to decide what's safe to read, what's blocked, and what
durable facts you must capture as you go. Do not write code or docs until
this gate clears.

## Clear the gate

Read `SSOT/STATUS.md` first. Treat any substantive change as blocked until
you have answered, in order:

- **Adjudications.** Any `pending` item under `## 开放裁决项` (or legacy
  `## 待裁决项`), or a `deferred` item whose revisit condition has fired,
  blocks ordinary work until resolved or re-deferred.
- **Documentation language.** Read `documentation_language` and its
  evidence; SSOT Markdown you write this task must match it — except for
  paths, commands, identifiers, enum values, API names, and direct quotes.
- **Protocol version.** Compare this file's `metadata.protocol_version`
  against `STATUS.md` `tracked_skill_version`. Project behind -> stop, route
  to `$ssot-audit`. Installed bundle behind project -> report stale install;
  never downgrade the project. If a source checkout under
  `projects/SSOT-SKILL/` is newer than the runtime-installed skill copy
  currently being read (`.agents/skills`, `.codex/skills`, `.claude/skills`,
  etc.), report the install as stale and reinstall from the source checkout
  before relying on new protocol clauses.

## Route your reads, don't bulk-load

Start from `SSOT/README.md` — its task-entry map is the project-specific
router. Read only what the task needs. Always include `product/README.md`
when the task may touch user value, PRD, capabilities, journeys, roadmap,
or acceptance; include `architecture/README.md` unless the task is clearly
product-only, operational, historical, or pure format.

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
`references/area-model.md §2.5` and in `$ssot-closeout` references — not
here.

## Park user-directive signals

Watch the user's prompts for an explicit lift-or-kill directive
("promote this", "never again"), a repeated same-kind correction across
turns, or recent prompts clustering in one domain. When one surfaces
and the rule is not already a clear durable fact you can write into the
unique authority per the section above, park one `CAP-` row
(`signal_source: user-directive`, `status: open`) in
`SSOT/STATUS.md ## Pending Captures` and let `$ssot-closeout` or
`$ssot-audit` route it. Do not promote, do not edit any other SSOT
file. Detail on the two evidence streams and the move schema lives in
`$ssot-closeout references/promotion-rationale.md`.

## When this skill is wrong, route out

| Situation | Skill |
|---|---|
| No `SSOT/` yet, `.bootstrap/` present, or `coverage_result: bootstrap` | `$ssot-bootstrap` |
| About to commit, `claim_done`, or finalise after substantive change | `$ssot-closeout` |
| Catch up commits / sessions, or protocol version is behind | `$ssot-audit` |
| Health check, independent stop review, CORE-REF / ADAPTER / CONSUMPTION | `$ssot-doctor` |
| Legacy `$ssot-skill` mention | route via `ssot-skill` shim back here |

## Load on demand

| When the task hits | Read |
|---|---|
| STATUS coverage states, adjudications, gaps, waterlines, stop gates | `references/status-protocol.md` |
| README/docs/ADR/runbook/PRD/core-ref classification and absorption | `references/source-material.md` |
| Candidate / hypothesis / source-backed knowledge | `references/knowledge-integrity.md` |
| Architecture root/views/domains, Reader Map, decomposition, coverage depth | `references/architecture.md` |
| Top-level area responsibilities and task-entry mapping rules | `references/area-model.md` |

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
