---
name: ssot-closeout
description: SSOT closeout before final response, claim_done, or commit after substantive repository changes. Use to absorb code/diff/conversation/test changes into SSOT, resolve in-task SSOT deltas, and decide whether no-op, status updates, audit, or doctor are needed. Do not use for initial task preflight, full historical catch-up, or full health checks.
---

# SSOT Closeout

Reconcile the whole batch, not only the diff. Follow
[`update-routing.md`](references/update-routing.md) and
[`inline-update-guide.md`](references/inline-update-guide.md); load
[`reader-quality.md`](../ssot-preflight/references/reader-quality.md) before changing reader bodies. Stop only when every durable
change, failure, caveat, temporary surface, and tracking-baseline issue has one
owner or a concrete no-op disposition, and any required Doctor review passes.
