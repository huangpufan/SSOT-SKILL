# Commit-level Audit Reference

This file is the detailed execution reference for the Commit audit part of proactive catch-up. Read on demand only when running commit-level full-scan audits or decision overturns.

---

## Table of contents

- [Execution flow](#execution-flow)
- [Size-adaptive strategy](#size-adaptive-strategy)
- [Diff-to-area mapping guide](#diff-to-area-mapping-guide)
- [Cascade checks](#cascade-checks)
- [Doctor verification](#doctor-verification)

## Execution flow

Independent of task execution, run a full scan over the `tracked_commit..HEAD` diff:

```text
1. Read tracked_commit, tracked_skill_version, documentation_language and documentation_language_evidence from STATUS.md
2. Assess change size (see "Size-adaptive strategy" below)
3. Pick a processing strategy based on size, obtain the diff
4. Use [`update-routing.md`](../../ssot-closeout/references/update-routing.md) to map diff file changes to affected areas
   - For repeated fix / revert / hotfix, cluster by specific failure mode; do not merge into broad themes
   - When the diff touches README/docs/ADR/runbook/PRD, product planning, user-supplied material, product promises or product routing, first classify per [`source-material.md`](../../ssot-preflight/references/source-material.md) and route to the product / architecture / testing authoritative location
   - For changes to `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/*`, `.windsurf/rules/*`, `GEMINI.md` or equivalent startup reference files, first classify per [`source-material.md`](../../ssot-preflight/references/source-material.md), then run core-reference-document review; do not handle them only as thin-adapter structures
   - Treat test run output in commits, logs, CI summaries, or release notes as evidence. Do not write chronological pass/fail history into `testing/` unless it changes a stable testing fact: strategy, selection matrix, gate, fixture contract, current baseline, known gap, or defensive-test map.
5. Check area by area: is the current documentation still accurate?
6. Update content in all affected areas; new/modified SSOT body, headings and table labels must use `documentation_language`
7. Request an independent reviewer to audit this commit-audit scope, affected-area updates and any `no-op` / "no update needed" conclusions
   - Reviewer returns `no-more-required-changes` -> continue
   - Reviewer returns `needs-fix` -> apply remaining changes and return to step 7
8. Update STATUS.md:
   - Advance tracked_commit to the current HEAD (or end-of-segment commit)
   - Update area states
   - Update open gaps
   - Update open adjudications (add new conflicts, resolve adjudicated items, or mark deferred/superseded)
   - Record stop-review gate evidence
```

---

## Size-adaptive strategy

Before obtaining the full diff, use `git diff --stat tracked_commit..HEAD` to estimate change size. The metric is **diff line count** (insertions + deletions total), not commit count -- 1 commit may change 5000 lines and 100 commits may each change 1 line.

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
2. Use `git diff --stat` to verify each segment's line count is below M; if still too large, further subdivide
3. Process segment by segment; after each segment completes and passes independent stop review, advance `tracked_commit` to the segment end commit
4. If a segment's diff is still too large and cannot be split by time boundary, batch by file type (configs/interfaces first, then implementation)

### Intermediate checkpoints

The agent may advance `tracked_commit` to a segment's end commit after that segment completes:

- Before advancing, confirm areas affected by that segment have been updated
- Before advancing, an independent reviewer must return `no-more-required-changes` for that segment
- Set `coverage_result` to `catching_up` (catching up, not yet at HEAD)
- After reaching HEAD, `coverage_result` may return to `converged` only after the final-scope stop review passes; otherwise it stays `in_progress`

### XL-size "re-extraction" judgement

When the proportion of files in an area touched by the diff exceeds 50% (e.g. mass reorganization of files under a domain in `architecture/`), re-extract that area directly from HEAD code rather than trying to understand the change chain from the diff. Other low-change areas still use incremental diff updates.

Judgement basis: among the files mapped to that area, the share of files touched by the diff over the area's total files.

---

## Diff-to-area mapping guide

The diff-file-type-to-area mapping has [`update-routing.md`](../../ssot-closeout/references/update-routing.md) as semantic owner. Commit audit only feeds the `tracked_commit..HEAD` diff into that mapping and verifies area by area that the current SSOT is still accurate.

For test-related diffs, separate stable testing facts from validation evidence. New or modified tests may update `testing/` when they change a durable test layer, selection rule, gate, fixture, current baseline, known gap, or defensive-test source. A CI log, command output, "latest green" note, runtime duration, or task-by-task validation summary is evidence for the audited change set, not a `testing/` fact.

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

The full checklist, architecture hard blockers, output tags and `passed` / `no-op` review rules are in [`doctor.md`](../../ssot-doctor/references/doctor.md). Commit audit only maps `tracked_commit..HEAD` code changes to affected authoritative locations; Doctor results and any Doctor stop conclusions must be handled separately per `doctor.md` and recorded under stop review.
