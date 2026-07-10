---
name: ssot-closeout
description: SSOT closeout before final response, claim_done, or commit after substantive repository changes. Use to absorb code/diff/conversation/test changes into SSOT, resolve in-task SSOT deltas, and decide whether no-op, status updates, audit, or doctor are needed. Do not use for initial task preflight, full historical catch-up, or full health checks.
---

# SSOT Closeout

Reconcile the whole batch against `SSOT/` before final response, `claim_done`,
or commit: diff, tests, user decisions, failures, caveats, and the deltas parked
at preflight. Write each durable fact once, at its authoritative owner. Test and
benchmark runs are evidence unless the batch changed stable testing or
benchmark policy.

Do not call the batch fixed or aligned until every user-visible failure,
fix/hotfix, validation caveat, preflight recommendation, unresolved fallback,
and overdue waterline has one durable disposition: update its existing owner,
create the right bug/debt/gotcha/decision/research record or STATUS gap, or
record a concrete no-op reason. Working docs, walkthroughs, handoffs, plans,
`link-only` inventory, and git history are not durable owners by themselves.
If the cause is a repeatable SSOT-SKILL protocol/template/lint gap, fix the
bundle, refresh the installed copy, then update the consumer.

Closeout is a no-op only after inspecting the affected scope and finding no
durable architecture, contract, behaviour, product, workflow, test-policy, or
operational truth change. Run targeted checks for the files touched; route full
health checks to `$ssot-doctor`. Waterlines and high-impact claims follow the
review exceptions owned by
`../ssot-preflight/references/status-protocol.md §6`.

Run the small-window two-stream promotion scan only over rules touched or cited
in this batch. Route or explicitly defer stale Pending Captures; apex moves
require `$ssot-doctor` review. The move schema lives in
`references/promotion-rationale.md`.

## Load on demand

| When the task hits | Read |
|---|---|
| Impact levels, file-to-area mapping, cascade checks | `references/update-routing.md` |
| Write procedure and STATUS synchronisation | `references/inline-update-guide.md` |
| Stop gates, waterlines, adjudications | `../ssot-preflight/references/status-protocol.md` |
| README / docs / ADR / PRD / product promise routing | `../ssot-preflight/references/source-material.md` |
| Candidate / hypothesis / source-backed knowledge edits | `../ssot-preflight/references/knowledge-integrity.md` |
