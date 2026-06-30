---
name: ssot-closeout
description: SSOT closeout before final response, claim_done, or commit after substantive repository changes. Use to absorb code/diff/conversation/test changes into SSOT, resolve in-task SSOT deltas, and decide whether no-op, status updates, audit, or doctor are needed. Do not use for initial task preflight, full historical catch-up, or full health checks.
---

# SSOT Closeout

You are at the end of a substantive change batch, before final response,
`claim_done`, or commit. Your job here is to reconcile what just happened
against `SSOT/`: the diff, the tests, the user's confirmations, the bugs
found, the in-task SSOT deltas you wrote down at preflight — not just the
file changes — and to write durable facts into their *single* authoritative
location, never duplicated across areas.

Test commands and their pass/fail output are evidence for the final answer
or for a durable fact elsewhere; they are not automatically facts for
`testing/`. Update `testing/` only when this batch changes test strategy,
selection matrix, gates, fixtures, current baseline, known gaps, or
defensive-test mappings.

Closeout is a no-op when the batch is purely mechanical, docs-wording
without durable facts, test-only without policy change, or implementation
detail with no architecture / contract / behaviour impact. Record no-op
only after actually inspecting the affected scope, not by default.

Run only the targeted checks needed for the files you touched. Do not
invoke full `$ssot-doctor` here.

Before final response, resolve the risk recommendations surfaced by preflight
and anything newly discovered during the batch:

- If the batch closes an active debt, bug, gotcha, adjudication, or open gap,
  update its owner and STATUS pointer.
- If the batch produced research/PoC output, choose exactly one disposition:
  create `SSOT/04-records/research/NNNN-<slug>.md`, update an existing research
  entry, promote durable claim rows into their product/architecture/decision or
  other owners, or discard the output with a concrete reason. Do not create
  top-level `SSOT/research/`, and do not mirror the packet into an authority
  owner.
- If the batch touches the same trigger/path/capability but does not close it,
  explicitly defer with the still-valid owner, reason, closure condition,
  revisit signal, verification guard, and next action. Do not leave
  "TODO later", "fallback for now", "compat shim", "future work", "someday",
  or "temporary waiver" as unregistered prose.
- Carry every preflight recommendation into a closeout disposition:
  `fixed`, `deferred-visible`, `expired/out-of-scope`, or `converted-to-owner`.
  A closeout that says only "create a later task" or "out of scope" without the
  risk, recommendation, owner/record pointer, retrigger condition, and guard is
  not aligned.
- If a consumer SSOT problem exposed a repeatable protocol/template/lint gap and
  this repository owns SSOT-SKILL, update the bundle first, refresh the runtime
  copy, then update the consumer SSOT from the improved rule.

You cannot self-certify high-impact moves. If closeout would hit one of the
independent-review exceptions in
`../ssot-preflight/references/status-protocol.md §7.1` -- such as bootstrap
overall `passed`, documentation-language change, `semantic_impact=high`
protocol upgrade, or first `coverage_result=converged` -- stop and route to
`$ssot-doctor` or `$ssot-audit`. Other daily waterline updates follow the
self-review path in that same section.

## Distill & promote

Run a small-window two-stream scan over the rules you actually touched
or cited in this batch — repo/conversation reality (Stream A) and
user-directive signals parked since last batch (Stream B) — and emit
zero or more move blocks beside each rule at its new location. The
schema and the five self-check questions live in
`references/promotion-rationale.md`. Do not issue moves on rules you
did not examine this batch.

Also scan `STATUS.md ## Pending Captures` for CAP- rows older than 30
commits and either route them now or mark `status: deferred` with a
one-line reason.

Any move with `from: apex` or `to: apex` requires `$ssot-doctor`
stop-review; moves that do not touch apex do not.

## Load on demand

| When the task hits | Read |
|---|---|
| Impact levels, file-to-area mapping, cascade checks | `references/update-routing.md` |
| Write procedure and STATUS synchronisation | `references/inline-update-guide.md` |
| Stop gates, waterlines, adjudications | `../ssot-preflight/references/status-protocol.md` |
| README / docs / ADR / PRD / product promise routing | `../ssot-preflight/references/source-material.md` |
| Candidate / hypothesis / source-backed knowledge edits | `../ssot-preflight/references/knowledge-integrity.md` |
