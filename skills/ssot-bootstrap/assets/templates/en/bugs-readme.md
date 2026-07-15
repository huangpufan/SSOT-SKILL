# Bug Knowledge

<!-- Writing style: implementation-delegator. Route by failure signature and
     current lifecycle; keep the post-mortem in one entry owner. -->

<!-- Completeness authority: reader-quality.md C01-C09, R01-R16, and applicable Q01-Q21. -->

Use this index when a confirmed failure needs to remain findable across
sessions, resembles something the repository fixed before, or appears again
after a fix. Match the observable signature, open the entry, reproduce only
what is safe, and follow its current containment, next action, or regression
check before deciding what to delegate.

For example, a page that becomes blank after reconnect may look like an old
rendering defect. The matching bug entry should tell you which trigger and
root cause qualified, what fixed it, and which test distinguishes recurrence
from a new failure.

This is long-lived failure knowledge, not an issue tracker. Each entry owns its
trigger, timeline, lifecycle reason, facts and analysis, evidence freshness,
impact, root cause, alternatives, fix, validation, owner, prevention, and
recurrence or closure. The index only routes.

## Bug index

| ID | Failure mode | Record status | Failure state | Severity | Entry owner |
|---|---|---|---|---|---|
| BUG-NNNN | <Failure mode> | current / archived / superseded | open / fixed / recurred | critical / major / minor | [Open entry](./NNNN-<slug>.md) |

When there are no bug entries, delete the sample row and render this one
visible line. Remove the line as soon as a real entry exists:

Empty collection: reason=<named reason>; owner=[responsible owner](<resolving-path>); review when=<observable event>.

Every real entry appears exactly once. `ID` matches the entry frontmatter,
`Entry owner` resolves to that file, and both state cells mirror the entry.
`record_status` says whether the knowledge entry is current routing material;
`failure_state` says whether the failure is newly known without a verified fix,
fixed, or has happened again after an earlier fix.

Only `open`, `fixed`, and `recurred` are valid routing states. `open` means the
failure is confirmed but no fitting fix has been verified. `fixed` means the
entry contains a root-cause fix and fitting regression evidence. `recurred`
means later evidence reopened that same failure mode after an earlier fix; the
entry explains why it remains unresolved.

For compatibility, `status` may remain in the entry, but it must mirror
`failure_state`, not `record_status`.

## Creating or updating an entry

Create a full entry for every bug worth preserving as long-lived knowledge,
including a newly confirmed failure whose fix is still open. Critical, major,
and recurred bugs must be split by root cause, not by broad symptom. A trivial
minor fix with no reusable failure lesson does not need a record; if it is
indexed, it also needs one unique entry owner rather than a root-cause story
hidden in the table.

Add the index row after the entry exists. Start a newly confirmed unresolved
failure at `open`. When a bug recurs, update the entry's timeline and reason
first, then mirror `recurred` here. When fitting evidence closes either state,
update the entry and mirror `fixed`.

## Boundaries and freshness

Scheduling and assignment stay in the issue tracker. A known unresolved failure
stays here as `open` when its failure knowledge is worth preserving. A
deliberately accepted workaround or design compromise may also create
[technical debt](../tech-debt/README.md), but debt does not replace the bug's
failure state. A repeatable trap without a defect lifecycle belongs in
[gotchas](../gotchas/README.md). Recheck an entry when its trigger path, runtime,
fix, test, owner, or evidence source changes.
