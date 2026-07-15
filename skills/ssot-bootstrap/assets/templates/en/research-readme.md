# Research and POC Records

<!-- Writing style: implementation-delegator. Route from a concrete question
     to one bounded result, its limit, and the next owner. -->

<!-- Completeness authority: reader-quality.md C01-C09, R01-R16, and applicable
     Q01-Q21. Covered collections use the exact lightweight R14 index-to-entry
     contract: unique ID, both state axes, and one resolving entry-owner link. -->

Research records preserve reusable findings from investigations before those findings become product, architecture, testing, benchmark, decision, gotcha, bug, or tech-debt owner text. This directory is for evidence and boundaries, not for speculative notes without a question or a reproducible method.

A cold reader starts from the question and trigger, opens one unique record,
checks lifecycle, fact-versus-inference, provenance/freshness, impact, method,
validation, owner/follow-up, and closure/invalidation, then follows only promoted
claim links. The index never turns a packet into current authority.

## Directory Map

```
04-records/research/
├── README.md              This index.
└── NNNN-<slug>.md         One research, spike, benchmark study, or POC record.
```

No numbered entry is created by the bootstrap skeleton. Create an entry only when there is a concrete question, method, evidence, and a possible promotion target.

## When To Create An Entry

Create a research entry when a finding may be reused later but is not yet ready to become authority in product, architecture, testing, benchmark, decisions, gotchas, bugs, or tech-debt. Common cases are proof-of-concepts, one-off benchmark comparisons, external-source checks, design spikes, feasibility studies, and negative findings that prevent a future agent from repeating the same path.

Do not create an entry for ordinary task notes, meeting summaries, or one-off command output unless the record contains a reusable claim and clear evidence.

## Research Index

| ID | Title | Record status | Adoption state | Kind | Created | Entry owner |
|----|-------|---------------|----------------|------|---------|-------------|
| RES-NNNN | <Title> | draft / validated / stale / superseded | unpromoted / partial / promoted / rejected | research / poc / spike / benchmark / experiment | YYYY-MM-DD | [Open entry](./NNNN-<slug>.md) |

When there are no research entries, delete the sample row and render this one
visible line. Remove the line as soon as a real entry exists:

Empty collection: reason=<named reason>; owner=[responsible owner](<resolving-path>); review when=<observable event>.

Every real entry appears exactly once. `ID` matches the entry frontmatter,
`Entry owner` resolves to that file, and both status cells mirror the entry.
`record_status` describes the evidence packet itself; `adoption_state`
describes whether durable owners accepted its reusable claims.

For compatibility, `status` may mirror `record_status`. The old overloaded
shape `status: promoted` migrates to `record_status: validated` plus
`adoption_state: promoted`; promotion is not a record lifecycle. Existing
`promotion_state` is an alias for `adoption_state`; when both exist they match.

`promotion_targets` name the SSOT owners that may receive promoted claims, such as `SSOT/02-architecture/NN-<domain>/README.md`, `SSOT/03-process/testing/README.md`, or `SSOT/03-process/benchmark/README.md`.

## Promotion Rules

A research record is not authority by itself. Promote only the claim rows that have enough evidence for a durable owner, then update the `Promoted SSOT owners` section in the entry. A one-off benchmark study stays here until its stable method, workload, metric, floor, comparison rule, or trend interpretation is promoted to `SSOT/03-process/benchmark/`. Leave unpromoted claims inside the research record with their boundaries and recheck trigger.

If a promoted owner contradicts the research record later, the promoted owner wins for current truth. Recheck this record, mark stale or superseded, and keep the historical evidence rather than rewriting it into a new conclusion.
