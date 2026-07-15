# Known Pitfalls

<!-- Writing style: implementation-delegator. Route by trigger and safe action;
     keep cause, evidence, and invalidation in the entry owner. -->

<!-- Completeness authority: reader-quality.md C01-C09, R01-R16, and applicable Q01-Q21. -->

Use this index when a change touches a path or operation with a known
counter-intuitive trap. Match the task to a trigger, open the entry, and follow
its “do not do this / do this instead” pair before editing or running the risky
step.

For example, if a migration helper looks reusable but a gotcha says it bypasses
the normal write owner, do not call it directly. Open the entry, verify that the
trigger still applies, use the safer path it names, and run its prevention
check.

The index only routes. Each gotcha entry owns the lifecycle reason, facts and
judgment, evidence freshness, impact, cause, safer alternative, validation,
owner, prevention, and resolution or invalidation.

## Pitfall index

| ID | Pitfall | Record status | Hazard state | Trigger hint | Entry owner |
|---|---|---|---|---|---|
| GOT-NNNN | <Pitfall> | current / archived / superseded | active / resolved | <path, task, or operation> | [Open entry](./<topic>.md#got-nnnn) |

When there are no gotcha entries, delete the sample row and render this one
visible line. Remove the line as soon as a real entry exists:

Empty collection: reason=<named reason>; owner=[responsible owner](<resolving-path>); review when=<observable event>.

Every real entry appears exactly once. `ID` matches entry frontmatter or the
exact stable `## GOT-NNNN` heading, `Entry owner` resolves to that file/anchor,
and both state cells mirror the entry. Put a topic entry's readable title on
the next line as an H3 or bold sentence so the `#got-nnnn` anchor stays stable.
`record_status` says whether the knowledge entry is current routing material;
`hazard_state` says whether the trap still exists.

Status here is a short mirror used for routing. `active` means the trap still
exists; `resolved` means the entry explains why it no longer applies and what
change invalidated it. The entry—not this index—owns that explanation.

For compatibility, `status` may remain in the entry, but it must mirror
`hazard_state`, not `record_status`.

## How to add or update a gotcha

Create an entry only after a repeatable, repository-specific trap is supported
by evidence. Name the operation or path that triggers it, the visible failure,
why the obvious move is dangerous, and the safer alternative. Add one index row
after the entry exists. When the trap disappears, update the entry first and
then mirror `resolved` here.

A repository may keep one entry per file or group related entries in a topic
file. Grouping does not change ownership: every entry still has one exact
`## GOT-NNNN` heading anchor, an explicit **Record status / hazard state** line
with `current` / `active` before the next H2, and one exact index link.
Legacy “status and trigger” text aliases only the hazard axis; it cannot supply
record lifecycle. Do not split an existing topic file merely to satisfy the
index shape.

Cross-task procedural rules that apply across unrelated files belong in
[development](../../03-process/development/README.md), not in this index. A
known unfinished remediation with a repayment plan belongs in
[technical debt](../tech-debt/README.md). A confirmed open, fixed, or recurred
defect belongs in [bugs](../bugs/README.md).

## Freshness

Recheck an entry when its trigger path, API, owner, failure signal, alternative,
or preventive test changes. If the index and entry disagree, treat the entry as
the owner and repair the index mirror.
