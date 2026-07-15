# Technical Debt

<!-- Writing style: implementation-delegator. Route by overlap and next action;
     keep repayment reasoning and closure in one entry owner. -->

<!-- Completeness authority: reader-quality.md C01-C09, R01-R16, and applicable Q01-Q21. -->

Use this index when a task overlaps a known compromise, temporary surface, or
unfinished refactor. Open the matching entry before changing the affected
area, decide whether to fix it now, recommend it now, defer it visibly, or
record why it is outside the task, and then follow the entry's next action and
verification guard.

For example, if an API change touches a compatibility shim marked as debt, do
not add another bypass before reading its closure condition. Either remove the
shim with the named checks, or leave a visible deferral that preserves its
owner, reason, trigger, and guard.

The index only routes by ID, title, short lifecycle, priority, and entry link.
Each debt entry owns the status reason, facts versus judgment, evidence
freshness, impact, cause, trade-offs, repayment action, validation, owner,
revisit trigger, closure, and obsolescence.

## Debt index

| ID | Debt | Record status | Repayment state | Priority | Entry owner |
|---|---|---|---|---|---|
| DEBT-NNNN | <Debt> | current / archived / superseded | active / resolved / obsolete | high / medium / low | [Open entry](./NNNN-<slug>.md) |

When there are no technical-debt entries, delete the sample row and render
this one visible line. Remove the line as soon as a real entry exists:

Empty collection: reason=<named reason>; owner=[responsible owner](<resolving-path>); review when=<observable event>.

Every real entry appears exactly once. `ID` matches the entry frontmatter,
`Entry owner` resolves to that file, and both state cells mirror the entry.
`record_status` says whether the knowledge entry is current routing material;
`repayment_state` says whether repayment is open, complete, or made irrelevant
by a later change.

`active` means the debt still affects decisions and has a falsifiable closure
path. `resolved` means repayment is complete and verified. `obsolete` means a
later architecture or decision removed the need, and the entry identifies that
invalidation. The entry owns the reason; this table mirrors only the word.

For compatibility, `status` may remain in the entry, but it must mirror
`repayment_state`, not `record_status`.

## How to classify overlap

- **Fix now** when the task already touches the debt's owner and can satisfy
  its closure condition safely.
- **Recommend now** when the debt materially changes the requested design or
  risk, but repayment needs separate authority or scope.
- **Defer visibly** when the current task can proceed without deepening the
  debt; preserve the reason, owner, next action, trigger, and verification
  guard in the entry or linked work item.
- **Outside scope** only when evidence shows the task does not overlap the
  debt's path, owner, failure mode, or acceptance boundary.

## Creating or updating an entry

Create an entry for a real compromise or unfinished change with impact and a
concrete repayment route—not for a vague wish. Add its index row after the
entry exists. When the status changes, update the entry's evidence and closure
or invalidation first, then mirror the lifecycle here.

## Boundaries and freshness

An observed defect with a root-cause fix lifecycle belongs in
[bugs](../bugs/README.md); a trap without planned repayment belongs in
[gotchas](../gotchas/README.md); a hard-to-reverse direction belongs in
[decisions](../decisions/README.md). Recheck a debt when its trigger path,
owner, temporary surface, architecture decision, closure condition, or
verification guard changes.
