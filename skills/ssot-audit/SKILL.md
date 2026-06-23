---
name: ssot-audit
description: Audit or catch up repository SSOT against commits, conversation sessions, or SSOT protocol versions. Use when the user asks to sync/catch up/audit SSOT, when tracked_commit/tracked_session/tracked_skill_version is behind, or when ssot-preflight detects protocol-version lag. Do not use for routine per-change closeout.
---

# SSOT Audit

You are on a deliberate catch-up: commits, sessions, or protocol versions
have drifted ahead of what `SSOT/` records, and you have been routed here
to close that gap — not to do new work. Pick the one drift signal that
applies and read only its catch-up procedure.

Segment large diffs and long transcripts before reading. Loading the full
backlog into one context is the failure mode this skill exists to prevent.

Waterline advancement must follow
`../ssot-preflight/references/status-protocol.md §7.1` and the upgrade router
in `references/protocol-upgrades.md`. Record an explicit review before
advancing `tracked_commit`, `tracked_session`, or `tracked_skill_version`; use
an independent `$ssot-doctor` stop review only for the §7.1 exceptions,
including `semantic_impact=high` protocol upgrades. `semantic_impact=none`,
`low`, and `medium` protocol upgrades may be self-reviewed when their checklist
is recorded.

## Scan the wide window

Run the large-window two-stream scan; closeout sees one batch, you see
many, so cross-batch incident concentration and apex/authority drift
only become visible here. Emit zero or more move blocks beside each
rule at its new location, using the schema and five self-check questions
in `../ssot-closeout/references/promotion-rationale.md`. Any move with
`from: apex` or `to: apex` goes through `$ssot-doctor` stop review;
moves that do not touch apex do not.

When this skill runs inside the SSOT-SKILL bundle repo, also harvest each
consumer's `## Pending Captures` rows with `status: deferred-export` and relay
them into `references/protocol-upgrades.md` `## Bundle Captures`.

If the transcript is lost, park a CAP- row with `signal_source: transcript`,
`status: deferred` so the gap stays durable.

## Load on demand

| Drift signal | Read |
|---|---|
| `tracked_commit` behind HEAD, or user asks commit sync | `references/commit-audit.md` |
| User asks conversation / session transcript catch-up | `references/conversation-audit.md` |
| `tracked_skill_version` behind `ssot-preflight` protocol version | `references/protocol-upgrades.md` router, then `references/current-upgrade.md` or `references/archive/index.md` as directed |
| Bundle-side inbox lookup during protocol-upgrades cadence | `references/protocol-upgrades.md` `## Bundle Captures` |
| Audit produced SSOT edits and you need write mechanics | `../ssot-closeout/references/update-routing.md` |
| Stop-review / health verification of the audit result | `../ssot-doctor/references/doctor.md` |
