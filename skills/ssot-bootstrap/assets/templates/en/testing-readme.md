# Testing Strategy

<!-- Writing style: implementation-delegator. Start with the change risk and
     test decision, then path, success/failure, commands, and evidence. -->

<!-- Completeness authority: reader-quality.md C01-C09, PR01-PR16, and applicable
     Q01-Q21. Covered process owners use the exact strategy and finite-asset
     contract; give a reason/evidence pointer for every not_applicable item. -->

> This area records stable correctness test strategy, selection rules, gates, fixture constraints, current correctness baselines, known gaps, and high-risk regression protection. Test run results are evidence, not testing facts; do not keep batch-by-batch validation history here. Measured performance, cost, and capacity floors live in [benchmark/](../benchmark/README.md).

## When and for whom

<Explain which change or risk triggers this testing process, who decides the
required depth, the environment/data prerequisites, and any permission needed
for browser, integration, destructive, or external-system checks.>

## Canonical path and branches

<Tell the ordered path from the smallest fitting check to broader gates. Explain
how UI, API, schema, migration, provider, or documentation changes branch, and
name fixture or environment side effects. Include applicable Q01-Q21 coverage
and repeated, concurrent, or partial-completion checks required by PR14.>

## Output and acceptance

<Describe the observable pass result, artifact, baseline, and acceptance rule.
Separate a stable gate from one batch's command transcript.>

## Failure, recovery, and handoff

<Explain failure detection, when to stop, safe retry or fixture reset, rollback
for destructive tests, and who decides whether a flaky or blocked result may be
accepted, deferred, or escalated.>

## Reproduce and keep current

<Give canonical reproducible commands, evidence owners, current gaps/target,
and the config, workflow, fixture, or product-surface change that invalidates
this strategy.>

## Testing at a Glance / Reader Map

| Reader question | First stop | Authoritative owner | Evidence direction | Stop condition / risk |
|---|---|---|---|---|
| What tests do I run first after a change? | [Test commands](#test-commands) | this file | package.json / CI / Makefile / test config | |
| Why are the test levels divided this way? | [Test strategy](#test-strategy) | this file | test config / CI / fixture | |
| Which checks block merge, release, or claim_done? | [Quality gates](#quality-gates) | this file | CI / release workflow / startup instructions | |
| What is the current expected correctness baseline? | [Current baseline](#current-baseline) | this file | CI / lint config / snapshot fixture / latest baseline-changing commit | |
| Which tests protect historical bugs? | [Defensive test sources](#defensive-test-sources) | this file | linked bug / gotcha / test code | |

## Test Strategy

Use a short narrative to describe test levels, boundaries, conventions,
invariants, and trade-offs. Explain why these layers and selection rules fit
the repository, which tempting alternative would miss a failure, and what
evidence would justify changing the strategy. If there are no tests, write
`not_applicable`, the reason, and the risk.

| Test level | Coverage | Why split this way | Evidence | Known risk |
|---|---|---|---|---|
| unit / integration / e2e / contract / manual | | | test config / CI / fixture | |

## Test Selection Matrix

Record what to run for each durable change family. Do not add rows for one-off task batches; update this matrix only when the stable selection rule changes.

| Change family | Required checks | Why these checks | Required setup | Evidence | Escalation trigger |
|---|---|---|---|---|---|
| source / API / schema / UI / docs / release | | | | package manifest / CI / test config | |

## Quality Gates

Record the checks that block merge, release, claim_done, or other durable workflow gates. A one-time successful run is evidence for the gate; it is not a new row.

| Gate | Blocking condition | Required checks | Evidence owner | Known bypass / risk |
|---|---|---|---|---|
| PR / release / claim_done / manual approval | | | CI / release workflow / startup instruction | |

## Current Baseline

Record stable expected correctness state, such as lint warning counts, snapshot baselines, contract fixture state, or known flaky-suite state. Update only when the baseline itself changes. Benchmark floors and trend rules belong in [benchmark/](../benchmark/README.md).

| Baseline | Current value | Evidence | Last baseline-changing change | Risk |
|---|---|---|---|---|
| | | CI / config / fixture / commit | | |

## Stable test asset inventory

This is the finite routing list for stable scripts, tools, suites, workloads,
fixtures, targets, artifacts, runbooks, and controls used by the testing
process. List each real asset once and use the detailed sections below to
explain commands or data contracts; a single test run is evidence, not an
asset.

If none exists, delete the sample row and write: `No stable assets: reason=<specific reason>; owner=[responsible owner](<resolving-path>); review when=<observable event>.`

| Asset | Class | Purpose | Selection rule | Owner | Evidence | Risk | Retirement or replacement trigger |
|---|---|---|---|---|---|---|---|
| | script / tool / suite / workload / fixture / target / artifact / runbook / control / other | | | | | | |

## Test Commands

> If commands come from a script inventory, external material, or auto summary, you must still cross-verify against the package manifest, CI, test config, or actual runs.

| Command | Purpose | Test level | Required setup | Evidence | Known risk |
|---|---|---|---|---|---|
| | | unit / integration / e2e / contract / manual | | package.json / CI / Makefile / test config | |

## Fixtures / Test Data

| Fixture / data source | Purpose | Owner | Update risk | Evidence |
|---|---|---|---|---|
| | | | | |

## Defensive Test Sources

> Only record the critical tests whose removal would let historical critical / major / recurred bugs regress; exhaustiveness is not required.

| Test | Failure mode it defends | Linked bug / gotcha | Evidence | Removal risk |
|---|---|---|---|---|
| | | | | |

## Open Gaps

| Gap / unknown | Required evidence | Blocking level |
|---|---|---|
| | | blocking / non-blocking |

## Not a Validation Ledger

Keep task-specific command transcripts, pass/fail dates, durations, and "latest validation" lists out of this file. Preserve those facts in the final response, commit/release note, bug entry, or stop-review evidence when needed; this area keeps only stable testing policy, correctness baseline, gap, fixture, gate, and defensive-map facts.
