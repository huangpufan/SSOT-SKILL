# Major Decisions

<!-- Writing style: implementation-delegator. Route from a concrete decision
     pressure to one entry and its current consequence. -->

<!-- Completeness authority: reader-quality.md C01-C09, R01-R16, and applicable
     Q01-Q21. Covered collections use the exact lightweight R14 index-to-entry
     contract: unique ID, both state axes, and one resolving entry-owner link. -->

This index preserves consequential product, architecture, engineering-process,
and operating choices. Each entry explains the alternatives, trade-offs, and
conditions behind a lasting rule. A choice can matter even when it is easy to
reverse or affects one module. Before changing such a rule, find its rationale
here; routine edits without a lasting trade-off do not need new entries.

## How to use this index

Start with the decision pressure, then open exactly one entry owner for context,
facts versus rationale, alternatives, impact, evidence, validation, follow-up,
and closure or supersession. This index may show routing lifecycle fields, but
it does not copy decision bodies, current implementation truth, or proof logs.

## Decision Index

| ID | Title | Record status | Implementation state | Date | Entry owner |
|----|-------|---------------|----------------------|------|-------------|
| DEC-NNNN | <Title> | accepted / deprecated / superseded | pending / partial / implemented / diverged / superseded | YYYY-MM-DD | [Open entry](./NNNN-<slug>.md) |

When there are no decision entries, delete the sample row and render this one
visible line. Remove the line as soon as a real entry exists:

Empty collection: reason=<named reason>; owner=[responsible owner](<resolving-path>); review when=<observable event>.

Record status: `accepted` / `deprecated` / `superseded`

Implementation state: `pending` → `partial` → `implemented` / `diverged` / `superseded`

Every real entry appears exactly once. `ID` matches the entry frontmatter,
`Entry owner` is a Markdown link to that file, and both status cells mirror its
frontmatter. The entry—not this row—owns reasons, evidence, and consequences.

For compatibility, an entry may also carry `status`; when present it must equal
`record_status`. `implementation_state` remains the established implementation
axis and is not renamed.
