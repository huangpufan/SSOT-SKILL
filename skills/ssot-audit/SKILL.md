---
name: ssot-audit
description: Audit or catch up repository SSOT against commits, conversation sessions, or SSOT protocol versions. Use when the user asks to sync/catch up/audit SSOT, when tracked_commit/tracked_session/tracked_skill_version is behind, or when ssot-preflight detects protocol-version lag. Do not use for routine per-change closeout.
---

# SSOT Audit

Close one drift signal at a time; do not mix catch-up with new work. Segment
large inputs before loading them. Read
[`commit-audit.md`](references/commit-audit.md),
[`conversation-audit.md`](references/conversation-audit.md), or
[`protocol-upgrades.md`](references/protocol-upgrades.md) for the matching
signal. Before SSOT writes, follow closeout routing and
[`reader-quality.md`](../ssot-preflight/references/reader-quality.md); stop
only after the applicable Doctor review.
