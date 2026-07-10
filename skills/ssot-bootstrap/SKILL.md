---
name: ssot-bootstrap
description: Bootstrap or continue repository SSOT creation. Use when SSOT/ is missing, SSOT/.bootstrap/ exists, SSOT/STATUS.md coverage_result is bootstrap, or the user asks to create a repository SSOT. Do not use for normal code-task preflight or routine closeout in an already bootstrapped repo.
---

# SSOT Bootstrap

You are creating a repository's first authoritative SSOT, or resuming a
bootstrap that didn't finish. Your job is not to author docs from intuition —
it is to absorb evidence the project already commits to (code, README, ADR,
runbook, PRD, configs) into one shape under `SSOT/`, in the detected
`documentation_language`, until phase exit criteria hold and an independent
reviewer signs off.

Treat `assets/templates/` as scaffolding only. Filling a template is not
evidence; the absorbed material is.

Bootstrap overall `passed` and clearing bootstrap state require independent
`$ssot-doctor` review. Do not widen that exception: every other waterline uses
the reviewer policy owned by
[`status-protocol.md` §6](../ssot-preflight/references/status-protocol.md#6-stop-review-gate).

## Load on demand

| When the task hits | Read |
|---|---|
| Bootstrap phases, evidence requirements, exit criteria | `references/bootstrap.md` |
| README / docs / ADR / PRD classification, absorption rules | `../ssot-preflight/references/source-material.md` |
| Architecture root / views / decomposition / coverage depth | `../ssot-preflight/references/architecture.md` |
| Convergence and stop-review checks | `../ssot-doctor/references/doctor.md` |
