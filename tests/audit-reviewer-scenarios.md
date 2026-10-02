# Audit reviewer decision scenarios

Use the actual audit entrypoints and `status-protocol.md §6`. Supply only the
scenario and repository facts to a fresh reviewer, then inspect its chosen
reviewer and whether it advances the claim. These are decision trials, not a
measurement of long-running consumer audit reliability.

| Scenario | Required result |
|---|---|
| Ordinary commit segment, affected owners reconciled | Scoped self-review; advance only after a passing review. |
| Current-session no-op self-check | Scoped self-review; do not advance `tracked_session`. |
| First two of three audit segments reviewed | Advance only to the second segment; remain `catching_up`. |
| First `converged` declaration | Independent review. |
| Documentation language change | Independent review. |
| High-impact protocol upgrade | Independent review. |
| Bootstrap overall `passed` | Independent review. |
| Review returns `needs-fix` on a small batch | Fix and re-review; size does not permit advancement. |
| Restoring previously reviewed convergence | Apply §6; independence is not required solely because convergence is restored. |

2026-10-03: an independent agent applied the first eight candidate scenarios
and preserved every expected boundary. It found a remaining unconditional
independence statement in the convergence definition; that statement was
reconciled with §6. A separate frozen-v2.64 trial selected scoped self-review
for ordinary catch-up by preferring the shared owner despite contradictory
local instructions. This change removes ambiguity; that sample does not
establish a before/after improvement in completion time.
