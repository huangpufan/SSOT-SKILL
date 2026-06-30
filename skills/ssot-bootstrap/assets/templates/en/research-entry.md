---
status: draft
kind: research
created_on: YYYY-MM-DD
owner: <owner-or-role>
promotion_targets:
  - SSOT/02-architecture/domains/<domain>/README.md
recheck_trigger: <dependency-change-or-new-evidence>
do_not_use_for: <current-production-authority-or-broader-claim>
---

# <NNNN> <Title>

> Writing style: any cold reader. See `ssot-bootstrap` §3.7.

> Research or POC record. This file preserves a question, method, evidence, reusable claims, negative findings, and the promotion path into durable SSOT owners. It is not authority until individual claim rows are promoted.

## Question

What question was this research trying to answer? State the decision pressure or uncertainty in one or two paragraphs.

## Conclusion

What did the evidence show? Start with the current answer, then name the confidence level and the most important boundary.

## Applicability and Boundaries

Where does this conclusion apply, and where does it not apply? Include version, environment, workload, feature flag, data-shape, provider, or repository-boundary limits when they matter.

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

List the reproducible steps that support the conclusion. Include commands, scripts, browser checks, benchmark setup, source comparison, or manual review procedure as applicable.

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
