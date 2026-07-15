# Records: What Happened and What Still Needs Attention

<!-- Writing style: implementation-delegator. Start with a concrete lookup
     decision and action; keep record indexes thinner than entry owners. -->

<!-- Completeness authority: reader-quality.md C01-C09, R01-R16, and applicable Q01-Q21. -->

Treat this directory as the repository's case-file cabinet. It preserves both
closed history and named work that is still open. Come here to answer a
specific question—“Was this failure seen before?”, “Why was this choice made?”,
or “What known work must I avoid deepening?”—then open one record owner and act
on its current status, evidence, and follow-up.

For example, if a familiar failure appears while changing storage code, first
scan the bug and gotcha indexes by symptom or trigger. Open the matching entry,
check whether its evidence is still fresh, and run the preventive check it
names. Then return to the current architecture owner before changing runtime
behaviour.

This directory does not redefine current product promises or architecture.
[Product](../01-product/README.md) owns what users can rely on, and
[architecture](../02-architecture/README.md) owns how the system currently
works. A record may explain history, rationale, or an open risk and link those
owners; it cannot override them.

## Choose the record type

- [Decisions](./decisions/README.md) explain a hard-to-reverse choice, the
  alternatives considered, and its implementation state.
- [Research](./research/README.md) preserves a bounded evidence packet before
  a durable owner absorbs its reusable claims.
- [Gotchas](./gotchas/README.md) warn about a repeatable trap and pair “do not”
  with a safer alternative.
- [Bugs](./bugs/README.md) preserve failure-mode knowledge after a fix or when
  a previously fixed problem recurs.
- [Technical debt](./tech-debt/README.md) tracks a known compromise or unfinished
  change with a concrete repayment and closure path.

Choose by the decision the next reader must make, not by where the source file
lives. One event may link several records, but each fact, status reason, and
closure condition has one entry owner.

## Area route map

The table only shortens navigation. It does not carry child status reasons,
causal stories, validation results, or closure evidence.

| Reader question | Index | Action after opening an entry |
|---|---|---|
| Why did we choose this direction? | [Decisions](./decisions/README.md) | Check current implementation posture and supersession before changing it. |
| What did an investigation actually prove? | [Research](./research/README.md) | Use only the bounded claim; follow a promoted owner for current truth. |
| What trap should I avoid here? | [Gotchas](./gotchas/README.md) | Follow the safer alternative and its prevention check. |
| Has this failure happened before? | [Bugs](./bugs/README.md) | Reproduce the signature and run the named regression check. |
| What compromise remains open? | [Technical debt](./tech-debt/README.md) | Classify it for this task and follow its next action or visible deferral. |

## Index and entry ownership

Every child README is an index. It shows a stable identifier, the record's own
lifecycle state, the separate real-world state named by that record type, and
an explicit Markdown link to the entry owner. A decision uses implementation
state; research uses claim-adoption state; a bug uses failure state; a gotcha
uses hazard state; debt uses repayment state. Keeping both axes prevents “the
document is current” from being mistaken for “the work is finished.” The entry
file owns the
trigger and time, lifecycle reason, facts versus judgment, evidence and
freshness, impact, cause or rationale, alternatives, action, validation,
follow-up, closure or invalidation, R15 affected-scope boundary, and R16
security/privacy/compliance/customer-exposure duties. Applicable Q14-Q21 facts
remain with their product, architecture, or process owners; a record preserves
the decision, incident, evidence, gap, and recheck trigger without redefining
current privacy, safety, oversight, fairness, lifecycle, output, or commercial
truth. Never update only the index when the entry truth changes.

## Creating or updating a record

Create an entry only for a real decision, investigation, trap, confirmed
open/fixed/recurred failure, or debt. Start with the reader's decision and next
action, verify the facts against suitable evidence, name what would invalidate the record, and
then add one pointer-sized index row. If no existing entry type fits, stop and
name the ownership gap rather than hiding narrative in an index cell.

## Freshness and recovery

Recheck a record when its trigger path, owner, linked implementation, evidence
source, decision, or closure signal changes. If a record conflicts with a
current owner, preserve the historical record, mark its lifecycle honestly,
and route the reader to the current owner. Do not silently rewrite history into
today's conclusion.
