---
id: RES-NNNN
record_status: draft
adoption_state: unpromoted
promotion_state: unpromoted
status: draft
kind: research
created_on: YYYY-MM-DD
owner: <owner-or-role>
promotion_targets:
  - SSOT/02-architecture/NN-<domain>/README.md
  - SSOT/03-process/benchmark/README.md
recheck_trigger: <dependency-change-or-new-evidence>
do_not_use_for: <current-production-authority-or-broader-claim>
---

# <NNNN> <Title>

<!-- Writing style: implementation-delegator. Start with the decision pressure,
     bounded question, and usable conclusion before method labels and evidence. -->

<!-- Completeness authority: reader-quality.md C01-C09, R01-R16, and applicable
     Q01-Q21. Covered records use the exact lightweight entry/index contract;
     keep fact/inference, both state axes, provenance, adoption, and invalidation explicit. -->

> Research, one-off benchmark study, or POC record. This file preserves a question, method, evidence, reusable claims, negative findings, and the promotion path into durable SSOT owners. It is not authority until individual claim rows are promoted.

## Record orientation

<State the record type, purpose, scope, trigger/time, lifecycle status, likely
impact, and owner. Separate observed facts from inference and name the source
snapshot that bounds freshness.>

`record_status` says whether the evidence packet is draft, validated, stale,
or superseded. `adoption_state` separately says whether its reusable claims
are unpromoted, partly promoted, promoted, or rejected by durable owners. The
compatibility field `status` mirrors only `record_status`; `promotion_state`
is a compatibility alias for `adoption_state` and must carry the same value.

## Question

What question was this research trying to answer? State the decision pressure or uncertainty in one or two paragraphs.

## Conclusion

What did the evidence show? Start with the current answer, then name the confidence level and the most important boundary.

## Applicability and Boundaries

Where does this conclusion apply, and where does it not apply? Include affected
versions, platforms, environments, tenants/workspaces, data classes,
compatibility window, workload, feature flag, provider, and repository boundary
when they matter. Name any security/privacy/compliance/customer exposure or
notification duty; do not retain sensitive evidence here.

`do_not_use_for`: repeat the strongest non-applicability boundary here in prose so future agents do not over-promote the packet.

## Candidates / Options

| Candidate | Why considered | Result | Boundary or trade-off |
|-----------|----------------|--------|-----------------------|
| Option A | | chosen / rejected / inconclusive | |
| Option B | | chosen / rejected / inconclusive | |

## Method / Environment

- Repository state: `<commit-or-release-or-source-snapshot>`
- Inputs: `<documents-datasets-fixtures-or-user-provided-material>`
- Environment: `<OS-runtime-tool-versions-or-not_applicable>`
- Example paths: `src/myapp/`, `web/src/components/<feature>/`

## Verification Steps

List the reproducible steps that support the conclusion. Include commands, scripts, browser checks, one-off benchmark setup, source comparison, or manual review procedure as applicable. Stable benchmark suites, workloads, floors, and comparison rules move to `SSOT/03-process/benchmark/README.md` when promoted.

```bash
<command>
```

## Evidence

| Evidence | Pointer | What it proves | Limit |
|----------|---------|----------------|-------|
| | `path:src/myapp/example.py` | | |

## Negative Findings

Record paths, options, or hypotheses that did not hold. These findings are useful when they prevent repeated exploration.

| Finding | Evidence | Why it matters |
|---------|----------|----------------|
| | | |

## Reusable Claim Rows

Each row is a candidate for promotion into a durable SSOT owner. Keep the claim narrow enough that a future agent can either promote, reject, or recheck it.

| Claim | Evidence | Confidence | Candidate owner | Promotion status |
|-------|----------|------------|-----------------|------------------|
| | | high / medium / low | `SSOT/...` | pending / promoted / rejected |

## Promoted SSOT Owners

When a claim is promoted, record exactly where the authoritative wording now lives. Do not leave the promoted owner ambiguous.

| Owner | Claim/action promoted | Date | Evidence |
|-------|-----------------------|------|----------|
| `SSOT/...` | | YYYY-MM-DD | |

## Follow-up Actions

List concrete next actions, their owner, and the trigger that makes the action relevant.

| Action | Owner | Trigger | Status |
|--------|-------|---------|--------|
| | | | pending / done / obsolete |

## Closure, supersession, and invalidation

<State what validation closes this packet, which promoted owner supersedes its
current use, what evidence invalidates it, and how to prevent or reproduce the
investigation when applicable.>
