# Commit-level Audit Reference

This file is the detailed execution reference for the Commit audit part of proactive catch-up. Read on demand only when running commit-level full-scan audits or decision overturns.

---

## Table of contents

- [Execution flow](#execution-flow)
- [Range and coverage boundary](#range-and-coverage-boundary)
- [Size-adaptive strategy](#size-adaptive-strategy)
- [Diff-to-area mapping guide](#diff-to-area-mapping-guide)
- [Cascade checks](#cascade-checks)
- [Doctor verification](#doctor-verification)

## Execution flow

Audit the requested commit range against a fixed endpoint. For ordinary
catch-up, the range starts at `tracked_commit` and ends at HEAD as resolved
when the audit starts; later commits are a separate range.

Reviewer choice follows [`status-protocol.md §6`](../../ssot-preflight/references/status-protocol.md#6-stop-review-gate):
use a scoped self-review by default, including each segment and any `no-op`
conclusion. When a claim falls under one of that owner's four exceptions,
obtain the required independent review before accepting it; splitting the
audit into segments does not waive that requirement.

```text
1. Read tracked_commit, tracked_skill_version, documentation_language and documentation_language_evidence from STATUS.md; establish the fixed range and coverage boundary below
2. Inspect the ordered commit list and net diff summary; assess change size (see "Size-adaptive strategy" below)
3. Pick a processing strategy, obtain the net diff and the event patches/evidence needed to disposition each commit or coherent cluster
4. Use [`update-routing.md`](../../ssot-closeout/references/update-routing.md) to map net changes and historical events to affected areas
   - For repeated fix / revert / hotfix, cluster by specific failure mode; do not merge into broad themes
   - When the fixed range contains fix / hotfix / regression-fix clusters, explicitly ask whether each cluster needs a durable disposition in `bugs/`, `tech-debt/`, `gotchas/`, `decisions/`, or `STATUS.md` rather than leaving the fix only in git history
   - When the diff touches README/docs/ADR/runbook/PRD, product planning, user-supplied material, product promises or product routing, first classify per [`source-material.md`](../../ssot-preflight/references/source-material.md) and route to the product / architecture / testing / benchmark authoritative location
   - For changes to `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/*`, `.windsurf/rules/*`, `GEMINI.md` or equivalent startup reference files, first classify per [`source-material.md`](../../ssot-preflight/references/source-material.md), then run core-reference-document review; do not handle them only as thin-adapter structures
   - Treat test run output in commits, logs, CI summaries, or release notes as evidence. Do not write chronological pass/fail history into `testing/` unless it changes a stable testing fact: strategy, selection matrix, gate, fixture contract, correctness baseline, known gap, or defensive-test map.
   - Treat benchmark run output, profiler dumps, CI performance summaries, and dated score tables as evidence. Do not write chronological measurement history into `benchmark/` unless it changes a stable benchmark fact: suite, workload, metric, environment, runner command, floor, comparison rule, trend interpretation, known gap, or consuming owner link.
5. Check area by area against the audited endpoint: does documentation distinguish the implemented state there from retained historical lessons and later work?
6. Update content in all affected areas; new/modified SSOT body, headings and table labels must use `documentation_language`
7. Run the applicable scoped stop review for this commit-audit scope, affected-area updates and any `no-op` / "no update needed" conclusions
   - Review returns `no-more-required-changes` -> continue
   - Review returns `needs-fix` -> apply remaining changes and return to step 7
8. Update STATUS.md:
   - Advance tracked_commit only to the fully reviewed endpoint or segment end allowed by the coverage boundary below
   - Update area states
   - Update open gaps
   - Update open adjudications (add new conflicts, resolve adjudicated items, or mark deferred/superseded)
   - Record stop-review gate evidence
   - Append one `SSOT/HISTORY.md` row per completed segment (Actor `audit`; Note carries the covered range `<old-tracked>..<new-tracked>`) per `update-routing.md §1.6`
```

## Range and coverage boundary

Resolve the old baseline and the requested start/end to full commit SHAs before
reading diffs (`base` below is the requested start, normally `tracked_commit`).
Inspect the requested range; earlier uncovered history remains a gap rather
than silently expanding the task. Record these SHAs, the requested path/event
scope, and exclusions in the audit evidence. Verify the commits exist, the
range has valid ancestry, the old baseline is an ancestor of any intended
global checkpoint, and the required history is available
(for example with `git cat-file -e` and `git merge-base --is-ancestor`). A
missing object, truncated shallow history, or rewritten/diverged ancestry is
a coverage gap, not an empty range. Recover the required history when available
within the authorized environment; otherwise retain the baseline, name the
missing range and recovery action, and continue independent work. A missing
baseline needs an explicitly scoped initial audit, not a guessed starting SHA.

Use both the ordered event list (for example,
`git log --reverse --topo-order <base>..<end>`) and the endpoint comparison
(`git diff <base> <end>`). Include merged-side commits and inspect merge
resolution changes when relevant. The net diff explains the resulting state;
the event history exposes reverted experiments, incidents, rejected approaches,
and constraints that may remain useful after their code disappears. Commit
messages guide inspection; patches, source records, or other evidence support
the conclusion. An empty net diff alone cannot justify a historical no-op.

Read relevant `SSOT/HISTORY.md` rows and their range/session pointers for prior
closeout evidence. Their Commit cell is HEAD at append time, not necessarily
the commit that later stored the row. A missing row means no recorded closeout
evidence was found; it does not prove closeout never ran. Rows guide attention
without replacing event and endpoint review.

Advance the global baseline only when every event and affected area between
the old baseline and the proposed checkpoint has a reviewed disposition.
A path-limited audit, a later range that skips earlier commits, or one completed
file-type batch may have useful results without advancing `tracked_commit`.
Record that reviewed subset and the remaining gap in the audit evidence so it
can be resumed. For a merge checkpoint, coverage includes all newly reachable
parent-side history, not only the first-parent log. Out-of-order work becomes
eligible for advancement after its preceding gaps are closed and the combined
scope passes review.

Keep the frozen endpoint if HEAD moves during the audit; new commits and dirty
worktree changes are outside its coverage. Preserve those changes. Before
updating STATUS, re-read its baseline and verify the proposed checkpoint still
belongs to the current history; reconcile concurrent baseline movement or a
rewrite instead of overwriting it or substituting the new HEAD. The review
artifact and HISTORY range must name the endpoint actually reviewed.

---

## Size-adaptive strategy

Before obtaining full patches, inspect `git diff --stat <base> <end>` and the
ordered event list. Diff line count (insertions + deletions) estimates endpoint
reading cost; commit count, intermediate churn, merges, and reversals estimate
history-reading cost. A small net diff may still require segmentation when
many intermediate changes cancel out.

| Size | diff lines | Strategy |
|---|---|---|
| S | < 1000 lines | Process the full diff directly in a single pass |
| M | 1000-5000 lines | Full diff still feasible, but consider splitting into logical segments by merge commit or release tag, preserving commit-message semantics |
| L | 5000-20000 lines | Must process in segments (see segmenting strategy), with intermediate checkpoints |
| XL | 20000+ lines | For high-change areas, consider "re-extraction" rather than tracking diffs one by one |

> Thresholds are empirical references. The agent should combine change concentration (spread over 100 files vs concentrated in 3 files) and own context-window margin when judging.

### Segmenting strategy

When size >= L:

1. Identify natural boundaries: release tag > merge commit > time window (per week)
2. Use `git diff --stat` and the event list to keep each segment within context; if endpoint size or intermediate churn is still too large, further subdivide
3. Process segment by segment; after each segment completes and passes the applicable scoped stop review, advance `tracked_commit` to the segment end commit
4. If a segment's diff is still too large and cannot be split by time boundary, batch by file type (configs/interfaces first, then implementation)

### Intermediate checkpoints

The agent may advance `tracked_commit` to a segment's end commit after that segment completes:

- Before advancing, confirm every event and affected area up to that checkpoint has a reviewed disposition; file-type batches or later-only segments leave the baseline unchanged until their gaps close
- Before advancing, the applicable scoped stop review must return `no-more-required-changes` for that segment
- Set `coverage_result` to `catching_up` while the fixed target still has unaudited material
- Finishing the fixed range does not imply current-HEAD convergence. Any later commits remain a separate gap; `coverage_result` may return to `converged` only when the current scope is accounted for and the final-scope stop review passes

### XL-size "re-extraction" judgement

When the proportion of files in an area touched by the diff exceeds 50% (e.g. mass reorganization of files under a domain in `architecture/`), consider re-extracting its current facts from the frozen endpoint. Still inspect the event list for durable incidents and decisions; re-extraction does not establish historical coverage by itself. Other low-change areas can use incremental diff updates.

Judgement basis: among the files mapped to that area, the share of files touched by the diff over the area's total files.

---

## Diff-to-area mapping guide

The diff-file-type-to-area mapping has [`update-routing.md`](../../ssot-closeout/references/update-routing.md) as semantic owner. Commit audit feeds the fixed range's net changes and historical events into that mapping, checking current facts against the audited endpoint and retaining useful historical conclusions in their proper owners.

For test-related diffs, separate stable testing facts from validation evidence. New or modified tests may update `testing/` when they change a durable test layer, selection rule, gate, fixture, correctness baseline, known gap, or defensive-test source. A CI log, command output, "latest green" note, runtime duration, or task-by-task validation summary is evidence for the audited change set, not a `testing/` fact.

For bug-fix-heavy ranges, `git log` is only a prompt to inspect the durable
capture. A commit message saying `fix`, `hotfix`, or `regression` is not itself
a fact source, but it is a strong audit signal that the failure mode may need a
bug packet, debt owner, gotcha, or explicit no-op disposition.

For benchmark-related diffs, separate stable benchmark facts from run evidence. New or modified benchmark scripts may update `benchmark/` when they change a durable suite, workload, metric, environment, runner command, floor, comparison rule, trend interpretation, known gap, or consuming owner link. A raw run result, profiler output, dated score table, CI performance summary, or "latest benchmark green" note is evidence for the audited change set or a research packet, not a `benchmark/` fact.

When the diff touches README/docs/ADR/runbook/PRD, core reference documents or other source material, run classification, absorption, thin-documentation check and conflict adjudication per [`source-material.md`](../../ssot-preflight/references/source-material.md), and sync the source-material absorption matrix in `STATUS.md`. Product intent, product promises, capability, journey, roadmap and product acceptance are owned by the `product/` area; architecture records only the technical response and implementation gap.

When the diff touches `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/*`, `.windsurf/rules/*`, `GEMINI.md` or equivalent startup reference files, also sync the core-reference-document review table in `STATUS.md`:

- `[ADAPTER]` only checks marker, size, optional source hash and summary boundary of SSOT-generated thin adapters; handwritten / mixed files without a marker are not reported under this tag for lacking a marker.
- `[CONSUMPTION]` checks whether startup reference files route the agent to `SSOT/` or `$ssot-*`, and whether the `SSOT/README.md` navigation entry exists.
- `[CORE-REF]` checks whether the commands, directory map, workflow state, architectural constraints, model/config rules, test strategy and agent operational prerequisites inside them are still consistent with code, manifests, CI, SSOT and the current protocol.
- Output must include concrete recommended actions: `update-doc`, `thin-adapterize`, `absorb-to-SSOT`, `record-conflict` or `no-op`.

---

## Cascade checks

The cascade checks for high-impact changes and decision overturns have [`update-routing.md`](../../ssot-closeout/references/update-routing.md) as semantic owner. When commit audit hits a corresponding scenario, follow that file to check the associated area set; otherwise do not perform a mechanical full-scan.

---

## Doctor verification

Doctor is the default companion step of proactive catch-up and may also run independently. It does not catch up new changes; it verifies whether existing SSOT content is still trustworthy.

The full checklist, architecture hard blockers, output tags and `passed` / `no-op` review rules are in [`doctor.md`](../../ssot-doctor/references/doctor.md). Commit audit reconciles the fixed commit range; Doctor results and any Doctor stop conclusions must be handled separately per `doctor.md` and recorded under stop review.
