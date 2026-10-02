# Audit range and baseline scenarios

Use these cases to review the actual commit/session audit references and the
tracking-baseline owner in `status-protocol.md`. They specify decisions and
coverage boundaries; they are not automated tests or measurements of model
reliability. For a behavioral probe, give the task/state column to a fresh
reader and compare its decisions with the expected column.

| Case | Task and repository state | Expected decision and coverage boundary |
|---|---|---|
| Ordinary commit catch-up | Baseline A is an ancestor of B; all events and affected owners in A..B have passed review. | Advance to frozen B with exact review evidence and HISTORY range. |
| HEAD moves | Audit freezes B; another agent commits C before the review ends. Only A..B was examined. | Retain B as the target and maximum checkpoint; preserve C and record the remaining range. Do not claim current convergence from the B review. |
| Missing commit history | The baseline object is absent in a shallow checkout. | Recover history if available in the authorized environment; otherwise record the missing range and recovery action. Retain the baseline; an unavailable diff is not a no-op. |
| Diverged ancestry | Both A and B exist, but A is not an ancestor of B after a rewrite. | Reconcile lineage and coverage before changing the baseline. Do not substitute merge-base or B and silently discard the old claim. |
| Path-limited audit | The user asks to audit API files in A..D; database changes in the same range remain unexamined. | Complete the API subset and record its evidence; leave the global baseline unchanged unless every intervening event/area receives a reviewed disposition. |
| Later segment first | A..B is unread; B..D was reviewed first. | Preserve useful B..D evidence, retain A, and resume A..B. Advance only after the combined prefix passes review. |
| Reverted incident | A feature is introduced at B and reverted at C after a reproducible failure; A and C have identical trees. | Inspect B/C event evidence and disposition the durable incident. Empty net diff alone cannot support historical no-op. |
| Merge checkpoint | The first-parent commits are reviewed, but a newly merged side branch has not been inspected. | The merge checkpoint remains ineligible until all newly reachable parent-side events and relevant resolution changes have dispositions. |
| File-type segmentation | Configuration changes are reviewed; implementation changes from the same segment are still pending. | Keep the segment baseline unchanged, retain the completed subset, and finish the remaining type batches before advancement. |
| Latest session first | Baseline S1; inventory S2/S3/S4; only S4 is read and reviewed. | Retain S1, record S4's reviewed subset and S2/S3 gaps. Recency does not authorize S4 as the baseline. |
| Session gap recovery | S2 is unreadable, S3/S4 are reviewed; S2 later becomes readable and is reviewed. | Initially retain S1 and a recovery route. After S2 and combined-prefix review, reuse valid S3/S4 evidence and advance to S4. |
| Resumed old session | S2 was reviewed through event E10; baseline is S4; S2 later gains E11-E15. | Queue the new content through saved read boundaries even though S2 precedes S4. The old session marker cannot filter away new material. |
| Uncertain session order | Two harness exports have opaque IDs and no established sequence. | Establish and record ordering/scope evidence or report only the reviewed subset; do not infer global coverage from listing order. |
| Current-session self-check | Inline updates already captured all durable current-session conclusions. | Apply the scoped no-op review; do not advance the historical session baseline. |

Reviewer policy remains owned by `status-protocol.md §6`: these coverage
checks neither waive its four independent-review exceptions nor introduce a
new requirement for an independent reviewer on ordinary segments.

2026-10-03: an independent candidate reader applied ten raw scenarios covering
moving HEAD, shallow history, path subsets, out-of-order segments, reverted
incidents, latest-session-first, missing-session recovery, resumed old sessions,
uncertain ordering, and current-session self-check. It retained every coverage
boundary. Its first reading found ambiguity about an appended old session;
the protocol now preserves the prior snapshot marker while the new-content gap
blocks further advancement/current convergence, and the reader confirmed that
clarification. The frozen-v2.64 reader allowed advancement to S4 after only S4
was reviewed, while separately noting S2/S3 were unread. The candidate retained
S1 until that earlier gap closed. These are protocol decision trials, not a
full multi-session production audit.
