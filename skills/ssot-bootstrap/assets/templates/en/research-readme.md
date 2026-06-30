# Research and POC Records

> Writing style: any cold reader. See `ssot-bootstrap` §3.7.

Research records preserve reusable findings from investigations before those findings become product, architecture, testing, decision, gotcha, bug, or tech-debt owner text. This directory is for evidence and boundaries, not for speculative notes without a question or a reproducible method.

## Directory Map

```
04-records/research/
├── README.md              This index.
└── NNNN-<slug>.md         One research, spike, benchmark, or POC record.
```

No numbered entry is created by the bootstrap skeleton. Create an entry only when there is a concrete question, method, evidence, and a possible promotion target.

## When To Create An Entry

Create a research entry when a finding may be reused later but is not yet ready to become authority in product, architecture, testing, decisions, gotchas, bugs, or tech-debt. Common cases are proof-of-concepts, benchmark comparisons, external-source checks, design spikes, feasibility studies, and negative findings that prevent a future agent from repeating the same path.

Do not create an entry for ordinary task notes, meeting summaries, or one-off command output unless the record contains a reusable claim and clear evidence.

## Research Index

| ID | Title | Status | Kind | Owner | Created | Promotion targets | Recheck trigger |
|----|-------|--------|------|-------|---------|-------------------|-----------------|
| | | draft / validated / promoted / stale / superseded | research / poc / spike / benchmark / experiment | | YYYY-MM-DD | | |

`promotion_targets` name the SSOT owners that may receive promoted claims, such as `SSOT/02-architecture/domains/<domain>/README.md` or `SSOT/03-process/testing/README.md`.

## Promotion Rules

A research record is not authority by itself. Promote only the claim rows that have enough evidence for a durable owner, then update the `Promoted SSOT owners` section in the entry. Leave unpromoted claims inside the research record with their boundaries and recheck trigger.

If a promoted owner contradicts the research record later, the promoted owner wins for current truth. Recheck this record, mark stale or superseded, and keep the historical evidence rather than rewriting it into a new conclusion.
