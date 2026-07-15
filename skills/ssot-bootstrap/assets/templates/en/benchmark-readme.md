# Benchmark Strategy

<!-- Writing style: implementation-delegator. Start with the decision and
     recognisable workload, then path, outcome/recovery, commands, and evidence. -->

<!-- Completeness authority: reader-quality.md C01-C09, PR01-PR16, and applicable
     Q01-Q21. Covered process owners use the exact strategy and finite-asset
     contract; give a reason/evidence pointer for every not_applicable item. -->

> This area records stable benchmark suites, canonical workloads, metrics, environments, floors, comparison rules, trend interpretation, and decision links. Benchmark run output is evidence, not a benchmark fact; do not keep chronological run logs here.

## When and for whom

<Explain which performance, cost, capacity, or provider decision triggers a
benchmark, who may run or interpret it, and the workload/environment
prerequisites that make two results comparable.>

## Why this benchmark method

<Explain why these workloads, environments, normalization rules, and floors
answer the repository's decision rather than merely producing numbers. Name
the conventions and invariants that keep comparisons coherent, the nearest
rejected method, the accepted cost/precision trade-off, and the evidence that
would justify changing the method.>

## Canonical path and branches

<Tell the ordered path from selecting the suite and workload through warmup,
measurement, normalization, comparison, and the branch for noisy,
non-comparable, or environment-changing results. Name paid or stateful effects,
and route applicable Q04/Q06/Q09/Q11 limits through STATUS.>

## Output and acceptance

<Describe the produced artifact, metric and uncertainty, the floor or decision
gate it can support, and what result is too weak to update a baseline.>

## Failure, recovery, and handoff

<Explain how an invalid run is detected, when to stop, what may be rerun or
reset, what cost/data cannot be recovered, and which product, architecture,
release, debt, or research owner receives the conclusion.>

## Reproduce and keep current

<Give the reproducible runner command and environment pin, current/target/gap,
evidence owner, and change trigger for workload, hardware, provider, metric, or
floor review.>

## Benchmark at a Glance / Reader Map

| Reader question | First stop | Authoritative owner | Evidence direction | Stop condition / risk |
|---|---|---|---|---|
| What benchmark do I run for a performance, cost, or capacity change? | [Benchmark suites](#benchmark-suites) | this file | benchmark scripts / CI performance jobs / profiling config | |
| Which workload, metric, and environment are canonical? | [Canonical workloads and environments](#canonical-workloads-and-environments) | this file | fixtures / datasets / provider or hardware config | |
| What floor or regression threshold matters? | [Metrics and floors](#metrics-and-floors) | this file | latest baseline-changing commit / CI artifact / release gate | |
| How do I compare two results without overreading noise? | [Comparison rules](#comparison-rules) | this file | runner docs / historical variance / benchmark research packet | |
| Which product, architecture, release, or debt decisions consume benchmark conclusions? | [Decision links](#decision-links) | this file plus linked owners | product / architecture / release / decisions / tech-debt | |

## Benchmark Suites

Describe the stable suite set in prose before the table. If no benchmark exists, write `not_applicable`, the reason, and the risk.

## Stable benchmark asset inventory

This is the finite routing list for every stable script, tool, suite, workload,
fixture, target, artifact, runbook, and control used by this benchmark process.
List each real asset once. Detailed suite/workload/metric sections may expand
the row but must not create a second inventory; one run result is evidence.

If none exists, delete the sample row and write: `No stable assets: reason=<specific reason>; owner=[responsible owner](<resolving-path>); review when=<observable event>.`

| Asset | Class | Purpose | Selection rule | Owner | Evidence | Risk | Retirement or replacement trigger |
|---|---|---|---|---|---|---|---|
| | script / tool / suite / workload / fixture / target / artifact / runbook / control / other | | | | | | |

| Suite | Purpose | Runner command | Required setup | Evidence | Owner / consumer |
|---|---|---|---|---|---|
| | latency / throughput / memory / capacity / provider-cost / model-token / other | | | benchmark script / CI job / config | |

## Canonical Workloads and Environments

Record the workload and environment a result must use before it can update a floor or guide a decision.

| Workload | Data shape / fixture | Environment | Warmup / cache rule | Evidence | Known limit |
|---|---|---|---|---|---|
| | | local / CI / staging / production-sampled / provider-specific | | | |

## Metrics and Floors

Record stable benchmark expectations. Update only when the floor, baseline, threshold, or owner changes.

| Metric | Current floor / baseline | Regression threshold | Evidence | Last floor-changing change | Risk |
|---|---|---|---|---|---|
| p50 / p95 / throughput / memory / tokens / cost / capacity | | | CI artifact / commit / research packet | | |

## Comparison Rules

Explain the comparison rule in prose first: what can be compared directly, what must be normalized, and what is too noisy to use as a decision signal.

| Rule | Applies when | Required normalization | Decision use | Evidence |
|---|---|---|---|---|
| | branch-to-branch / release-to-release / hardware change / provider change / workload change | | blocking / advisory / research-only | |

## Trend Interpretation

| Trend signal | Meaning | Action | Evidence owner |
|---|---|---|---|
| sustained regression / one-off spike / variance increase / capacity headroom / cost drift | | update floor / open debt / release gate / research packet / no-op | |

## Decision Links

| Benchmark conclusion | Consuming owner | How it is used | Evidence |
|---|---|---|---|
| | product / architecture / release / decisions / tech-debt | promise / design choice / release gate / accepted debt | |

## Known Gaps

| Gap / unknown | Required evidence | Blocking level | Owner / trigger |
|---|---|---|---|
| | | blocking / non-blocking | |

## Not a Run Log

Keep dated run tables, command transcripts, raw profiler dumps, and one-off benchmark comparisons out of this file. Preserve reusable one-off studies in `04-records/research/`; preserve batch proof in final responses, CI artifacts, release notes, stop-review evidence, or commit notes. This file keeps only stable benchmark methods, floors, comparison rules, trends, gaps, and decision links.

## Walkthrough
<!-- One concrete prose example: a change touches a performance/cost/capacity path, the reader picks a suite, runs the canonical workload, compares against the floor, and follows the consuming owner link. -->

## Easily confused with
<!-- Suggested boundaries:
     **[testing/](../testing/README.md)** — owns correctness strategy and pass/fail gates; benchmark owns measured workload, metric, floor, and interpretation.
     **[04-records/research/](../../04-records/research/README.md)** — owns one-off benchmark studies until a stable method or floor is promoted here. -->

## Out of scope
<!-- One line naming excluded questions and the owner that answers them. -->

## See also
<!-- 3-7 links with one-line hooks, commonly 03-process/testing/, 03-process/release/, 02-architecture/, 01-product/, 04-records/decisions/, 04-records/tech-debt/, and 04-records/research/. -->
