# Benchmark 策略

> 行文风格：写给任何冷读者。详见 `ssot-bootstrap` §3.7。

> 本区域记录稳定的 benchmark suites、canonical workloads、metrics、environments、floors、comparison rules、trend interpretation 和 decision links。Benchmark run output 是 evidence，不是 benchmark fact；不要在这里维护按日期排列的运行流水账。

## Benchmark 一眼看懂 / Reader Map

| 读者问题 | First stop | Authoritative owner | Evidence direction | Stop condition / risk |
|---|---|---|---|---|
| 性能、成本或容量改动后该跑哪个 benchmark？ | [Benchmark suites](#benchmark-suites) | this file | benchmark scripts / CI performance jobs / profiling config | |
| 哪个 workload、metric 和 environment 才是 canonical？ | [Canonical workloads and environments](#canonical-workloads-and-environments) | this file | fixtures / datasets / provider or hardware config | |
| 哪个 floor 或 regression threshold 重要？ | [Metrics and floors](#metrics-and-floors) | this file | latest baseline-changing commit / CI artifact / release gate | |
| 两次结果如何比较才不过度解读噪声？ | [Comparison rules](#comparison-rules) | this file | runner docs / historical variance / benchmark research packet | |
| 哪些 product、architecture、release 或 debt decisions 消费 benchmark 结论？ | [Decision links](#decision-links) | this file plus linked owners | product / architecture / release / decisions / tech-debt | |

## Benchmark Suites

先用散文说明稳定 suite 集合。若没有 benchmark，写 `not_applicable`、原因和风险。

| Suite | Purpose | Runner command | Required setup | Evidence | Owner / consumer |
|---|---|---|---|---|---|
| | latency / throughput / memory / capacity / provider-cost / model-token / other | | | benchmark script / CI job / config | |

## Canonical Workloads and Environments

记录结果必须使用什么 workload 和 environment，才可以更新 floor 或支持 decision。

| Workload | Data shape / fixture | Environment | Warmup / cache rule | Evidence | Known limit |
|---|---|---|---|---|---|
| | | local / CI / staging / production-sampled / provider-specific | | | |

## Metrics and Floors

记录稳定 benchmark 预期。只有 floor、baseline、threshold 或 owner 变化时才更新。

| Metric | Current floor / baseline | Regression threshold | Evidence | Last floor-changing change | Risk |
|---|---|---|---|---|---|
| p50 / p95 / throughput / memory / tokens / cost / capacity | | | CI artifact / commit / research packet | | |

## Comparison Rules

先用散文解释比较规则：哪些结果能直接比较、哪些需要归一化、哪些噪声太大不能作为 decision signal。

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

## 不是运行流水账

不要把按日期排列的运行表、命令转录、原始 profiler dump 或一次性 benchmark 对比写进本文件。可复用的一次性研究放入 `04-records/research/`；批次 proof 放入最终回复、CI artifacts、release notes、stop-review evidence 或 commit notes。本文件只保存稳定 benchmark method、floors、comparison rules、trends、gaps 和 decision links。

## 走查（Walkthrough）
<!-- 用一段具体散文说明：某个改动触及 performance/cost/capacity 路径，读者如何选择 suite、运行 canonical workload、对照 floor，并跳到 consuming owner。 -->

## 容易混淆（Easily confused with）
<!-- 建议边界：
     **[testing/](../testing/README.md)** — 负责 correctness strategy 与 pass/fail gates；benchmark 负责 measured workload、metric、floor 和 interpretation。
     **[04-records/research/](../../04-records/research/README.md)** — 负责一次性 benchmark studies，直到稳定 method 或 floor 被提升到这里。 -->

## 不回答（Out of scope）
<!-- 一句话说明本 owner 不回答什么，并指向回答它的 owner。 -->

## 延伸阅读（See also）
<!-- 3-7 条链接并附一句说明，通常包含 testing/、release/、architecture/、product/、decisions/、tech-debt/ 与 04-records/research/。 -->
