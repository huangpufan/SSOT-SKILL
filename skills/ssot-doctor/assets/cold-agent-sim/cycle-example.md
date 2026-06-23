# Cycle Example — Cold-Agent Simulation Worked Example

This file is a single synthetic worked example illustrating one cycle's shape
for a fictional consumer project `myapp`. It is not a real cycle report. Real
cycle reports live next to it as `cycle-<N>.md` per the protocol in
[`references/cold-agent-sim.md`](../../references/cold-agent-sim.md).

## Setup

- Commit pool: 30 most recent non-merge commits of `myapp` as of `<commit-sha>`
- Sampling cycle-id: `cycle-example`
- Sampling method: `git log --no-merges -n 30 --format="%H %s" | shuf --random-source=<(yes cycle-example)`
- Model: pinned per cycle (record actual model id in real reports)
- Trials per `(commit, pillar)` cell: 3 (best-of-3 majority vote)
- Hop budget: 5
- Run date: `<ISO date>`

## Sample (1 commit shown — real cycles stratify to 8)

| # | SHA | Stratum | Subject |
|---|---|---|---|
| 1 | `<commit-sha>` | product-surface | `fix(myapp): widget toolbar tooltip clipped on narrow viewport` |

## Trial walk-through (commit 1, pillar = `product_truth`)

The cold agent receives only the commit subject + first body paragraph and the
allowed SSOT read scope. It does NOT see the diff.

- **hop1** — Agent greps `SSOT/` for `widget toolbar`. It opens
  `SSOT/STATUS.md` (the project's pointer-of-pointers).
- **STATUS pointer** — `STATUS.md:42` is a source-inventory row for the
  Widget Toolbar capability, naming `product/capabilities/widget-toolbar.md`
  as the owner and citing `<commit-sha>` under Pending Captures.
- **hop2** — Agent opens `product/capabilities/widget-toolbar.md` and lands
  on the contract row pinning the DOM selector `widget-toolbar-tooltip` to
  `src/myapp/widgets/Toolbar.tsx:88` plus the Playwright guard
  `tests/e2e/widget_toolbar_tooltip.spec.ts::tooltip stays inside viewport`.
- **Verification** — The named DOM selector and `path:LNN` both fall inside
  the commit's diff hunk (±10 lines); the Playwright test name is the
  regression the diff adds. The trial returns `verdict=PASS`,
  `hops_used=2`, `miss_class=null`.

## Results (one (commit, pillar) cell shown)

| # | SHA | pillar | trial-1 | trial-2 | trial-3 | cell_score | hop_died_at | miss_class | partition |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `<commit-sha>` | product_truth | PASS (2h) | PASS (2h) | PASS (3h) | 1/1 | — | null | — |

## Per-pillar score (illustrative for an 8-commit × 4-pillar cycle)

| pillar | passing cells | denominator | pillar_score | floor (≥5/8) | gate |
|---|---|---|---|---|---|
| design_intent | 5 | 6 | 0.83 | 0.625 | PASS |
| product_intent | 6 | 8 | 0.75 | 0.625 | PASS |
| design_truth | 5 | 7 | 0.71 | 0.625 | PASS |
| product_truth | 7 | 8 | 0.88 | 0.625 | PASS |
| **total** | 23 | 29 | 0.79 | ≥0.75 | PASS |

## Skill-fail and doc-fail partitions

| commit | pillar | miss_class | partition | note |
|---|---|---|---|---|
| — | — | — | — | none in this worked example |

## Cycle gate

**PASS** (illustrative) — all four pillars clear the `≥ceil(0.625·denom)`
floor, aggregate ratio `≥0.75`, glossary spot-check `2/2`, every mandatory
Core recovery manifest cell PASS / reasoned N/A, and zero `skill-fail`
rows.

## How to read this example

Real cycle reports follow the same section layout but cover 8 commits across
4 pillars (≥3 trials per `(commit, pillar)` cell). When a cycle FAILs a
pillar floor, the fail rows route per §3.1 / §4 of the protocol:
`skill-fail` rows go to the bundle captures backlog; `doc-fail` rows go to
the consumer's `STATUS.md ## Pending Captures`.
