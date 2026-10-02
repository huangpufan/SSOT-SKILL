# Capture lifecycle scenarios

These are behavioural review cases for capture-producing skill instructions.
They are not evidence that a model has passed the cases. Run the same prompt
against baseline and candidate instructions; retain the generated row or
action, verdict, and reasoning. Check generated consumer rows with the STATUS
schema validator as well as reviewing their source and authority semantics.

The fixture has an existing `SSOT/STATUS.md`, development and decision intake
owners, and a documentation-language lock. It has no authorised bundle or
global-instruction edit unless a case explicitly grants one.

| Case | Task and evidence | Expected result |
|---|---|---|
| Explicit correction awaiting placement | The user says not to present mock-only evidence as a real-provider check; the durable rule's owner is not yet decided. | One canonical eight-column CAP row starts at `pending`, retains the user/session source, links an existing proposed intake owner, and names the responsible route and review trigger; closure is `none: open`. No extra `signal_source` column or `State: open`. |
| Inferred recurring pattern | Several prompts mention difficult retries, but the user has not requested a global retry rule. | If capture is useful, its reason labels the proposed rule as an inference; the source anchors the prompts. No invented human approval or automatic global promotion. |
| Already authorised durable fact | The user explicitly changes an existing project rule, identifies its unique owner, and authorises updating it. | Update that owner within scope and retain decision evidence; do not force an unnecessary pending capture solely because the source is conversational. |
| Owner still uncertain | A durable signal spans two owners and the agent cannot yet select one. | Use the narrowest existing intake-owner link with a provisional-placement reason and responsible review route; do not invent a nonexistent owner or silently omit the capture. |
| Deferred bundle export | A consumer capture awaits a future authorised bundle-maintenance batch. | State is `deferred`; the export condition, including any legacy `deferred-export` wording, is trigger context. Do not write another repository without authority. |
| Routing without absorption | A capture has been handed to a concrete owner, but that owner has not incorporated the fact. | State may become `routed` with its reachable receiving route; it must not become `absorbed` without owner/closure evidence. |
| Expiry versus unfinished work | A proposed rule is superseded, while another capture remains required but inconvenient. | The superseded capture may expire with linked rationale; the required capture remains visible and cannot be expired merely to clear the queue. |
| Historical bundle rows | An audit encounters the frozen pre-v2.61 table and a new signal resembling an old row. | Preserve old rows verbatim. Use the current schema for any new row, link historical provenance, and recheck current evidence rather than inheriting an old free-text `routed` conclusion. |

## Observed application — 2026-10-03

An independent reader, without the expectation table, generated captures for
four raw cases. A repeated correction produced a traceable `pending` row;
an explicitly authorized fact with a unique owner was applied directly;
unauthorized cross-repository export remained `deferred` with an export trigger;
an existing capture retained its ID and stayed `routed` until absorption
proof existed. The three generated rows each had exactly eight cells and legal
states. This was a protocol application exercise, not a full consumer closeout.
The three frozen historical rows, header, and separator retained identical
bytes (SHA256 `92e307d79fc35d3264f780b7470965bd77c066f82f7a0057ff7ec0ba52bd57b6`).
