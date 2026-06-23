# Testing Strategy

> Writing style: any cold reader. See `ssot-bootstrap` §3.7.

> This area records stable test strategy, selection rules, gates, fixture constraints, current baselines, known gaps, and high-risk regression protection. Test run results are evidence, not testing facts; do not keep batch-by-batch validation history here.

## Testing at a Glance / Reader Map

| Reader question | First stop | Authoritative owner | Evidence direction | Stop condition / risk |
|---|---|---|---|---|
| What tests do I run first after a change? | [Test commands](#test-commands) | this file | package.json / CI / Makefile / test config | |
| Why are the test levels divided this way? | [Test strategy](#test-strategy) | this file | test config / CI / fixture | |
| Which checks block merge, release, or claim_done? | [Quality gates](#quality-gates) | this file | CI / release workflow / startup instructions | |
| What is the current expected baseline? | [Current baseline](#current-baseline) | this file | CI / lint config / benchmark fixture / latest baseline-changing commit | |
| Which tests protect historical bugs? | [Defensive test sources](#defensive-test-sources) | this file | linked bug / gotcha / test code | |

## Test Strategy

Use a short narrative to describe test levels, boundaries, and trade-offs. If there are no tests, write `not_applicable`, the reason, and the risk.

| Test level | Coverage | Why split this way | Evidence | Known risk |
|---|---|---|---|---|
| unit / integration / e2e / performance / manual | | | test config / CI / fixture | |

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

Record stable expected test state, such as lint warning counts, benchmark floors, snapshot baselines, or known flaky-suite state. Update only when the baseline itself changes.

| Baseline | Current value | Evidence | Last baseline-changing change | Risk |
|---|---|---|---|---|
| | | CI / config / benchmark fixture / commit | | |

## Test Commands

> If commands come from a script inventory, external material, or auto summary, you must still cross-verify against the package manifest, CI, test config, or actual runs.

| Command | Purpose | Test level | Required setup | Evidence | Known risk |
|---|---|---|---|---|---|
| | | unit / integration / e2e / performance / manual | | package.json / CI / Makefile / test config | |

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

Keep task-specific command transcripts, pass/fail dates, durations, and "latest validation" lists out of this file. Preserve those facts in the final response, commit/release note, bug entry, or stop-review evidence when needed; this area keeps only stable testing policy, baseline, gap, fixture, gate, and defensive-map facts.
