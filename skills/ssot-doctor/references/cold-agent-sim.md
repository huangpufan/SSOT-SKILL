# Cold-Agent Simulation Harness (v2.43)

This file is the protocol for the **cold-agent simulation gate** — a reproducible
black-box test of whether SSOT can route a cold coding agent from a commit's
user-visible intent to the correct `file:line` / SQL / test / DOM-selector
anchor in ≤ 5 hops.

It is the objective judge SSOT-SKILL uses to know when its own protocol is
sufficient: structural lint (`ssot-lint.sh`) tells you the SSOT is shaped right;
this harness tells you the SSOT is **useful**.

> Doctor and lint verify whether what is written is correct. The cold-agent
> simulation verifies whether what is written can answer the questions a real
> agent will ask.

## 0. When to run

Run this harness:

- **Per cycle of an SSOT-SKILL upgrade** (current bundle protocol cadence). The
  cycle gate is the 4-pillar floor defined in §3 (each pillar
  `≥ ceil(0.625·denom)` cells passing plus aggregate ratio `≥ 0.75`) plus
  zero rows in the `skill-fail` partition and a clean Core recovery manifest
  sweep for covered product / architecture areas.
- **After any large architecture-IA reorganization** of a consumer SSOT (domain
  split/merge, capability rewrite, or playbook addition).
- **On user request** ("does my SSOT actually answer the cold-agent question").

Do **not** run it on every commit; it is a quality gate, not lint.

## 1. Sampling

| Field | Rule |
|---|---|
| Sample size | 8 commits per run |
| Stratification | 2 architecture-core + 2 product-surface + 2 operational + 2 cross-cutting |
| Source | `git log --no-merges -n 30` (most recent 30 non-merge commits on the audited branch) |
| Exclusions | Pure SSOT-only commits (`SSOT/...` paths only); pure SSOT-SKILL bundle commits (`projects/SSOT-SKILL/...` paths only). These do not stress the SSOT-as-router question. |
| Determinism | `git log --no-merges -n 30 --format="%H %s" \| shuf --random-source=<(yes <cycle-id>)` ensures the same `<cycle-id>` reproduces the same sample |
| Strata definitions | architecture-core = touches `engine/`, `persistence/`, `domain/`, `web/app.py`/`services.py`/`deps.py`; product-surface = touches `frontend/`, `web/routes/`, capability/journey-bound code; operational = touches scripts, CI, deploy, test infra; cross-cutting = touches ≥2 strata at once |

When fewer than 30 commits exist, take all non-merge commits and stratify
best-effort; document the relaxed split in the report.

## 2. Cold agent setup

Spawn a `general-purpose` subagent with these constraints, **not** the project's
default agent (it has too much priming):

| Constraint | Rule |
|---|---|
| Read scope | `SSOT/**` and `projects/SSOT-SKILL/skills/**` only |
| Forbidden | Reading `src/`, `tests/`, `frontend/`, `docs/`, `poc/`, anything outside SSOT — the goal is to test SSOT, not the agent's code-reading ability |
| Tools | `Read`, `Grep`, `Glob` over the allowed scope; **no** `Bash`, **no** web/MCP, **no** other agents |
| Model | Pinned per cycle (record in report) |
| Temperature | `0` |
| Hop budget | **5** SSOT reads per trial (hard cap; exceeding the budget is fail even if the answer is correct — the harness measures locating efficiency, not exhaustive search) |
| Prompt input | Commit subject line plus the first paragraph of the commit body. **Not** the diff, file list, or hint about which area to read |
| Output schema | `{intent: str, pillar: "design_intent" \| "product_intent" \| "design_truth" \| "product_truth", hop1_path: str, hop2_anchor: str, hops_used: int, verdict: "PASS" \| "FAIL", miss_class: "missing-owner" \| "prose-fork" \| "broken-ref" \| "glossary-gap" \| "truth-state-gap" \| null, reasoning: str}` where `pillar` classifies what the cold agent was asked to recover (see §2.1); `hop2_anchor` is one of `file:line`, `tests/...::test_name`, `SQL identifier`, `DOM selector`, `route + handler path:line`, or `product-owner state row + closure owner`. `verdict` is the cold agent's own assessment of whether SSOT routed it successfully; `miss_class` is `null` when `verdict=PASS` and required when `verdict=FAIL` (see §3.1); `reasoning` is one short paragraph (≤80 words) explaining why. See "Routing-only mandate" below for what `verdict=FAIL` means. |

### Routing-only mandate (v2.42)

The cold agent's job is **routing**, not validation. The prompt input gives
the user-visible intent; the agent's task is to find where SSOT documents
the change. It is not asked to judge whether the commit is correct,
well-designed, or aligned with SSOT consensus — those judgements are out
of scope and produce false-FAIL drift.

Concretely:

- Return `verdict=PASS` when a `hop2_anchor` is found that resolves per §3's
  grading rubric, regardless of whether the underlying commit "looks right"
  relative to SSOT history.
- Return `verdict=FAIL` only when SSOT cannot be routed — i.e. no file under
  the allowed scope provides a `file:line` / `tests/...::test_name` / SQL
  identifier / DOM selector / route+handler anchor for the commit's intent
  within the 5-hop budget. In that case `reasoning` must name the missing
  SSOT anchor (which file would have needed the row, what kind of anchor) —
  not a critique of the commit text against SSOT history.
- "The commit text and SSOT consensus disagree" is **not** a routing
  failure; it is a content concern out of harness scope. If the cold agent
  finds the anchor, record `verdict=PASS`; any content disagreement belongs
  to a separate review.

Cycles 3 and 4 surfaced ~25-30% of trials drifting from "route to owner"
into "validate commit text against SSOT consensus" mode under the prior
ambiguous prompt. Cycle 5 regression with this mandate explicitly restated
at trial-prompt time tests whether schema-deviation drops below 10%.

### 2.1 Pillar assignment (v2.43)

The trial harness derives `pillar` from the commit's user-visible intent
before issuing the prompt:

- **`design_intent`** — the commit changes architectural invariants,
  runtime ownership, decomposition basis, or CTG. Cold agent is asked
  "why does this commit exist architecturally" and must land on
  `architecture/` root|view|domain narrative + decomposition or invariant
  evidence.
- **`product_intent`** — the commit changes a product promise,
  capability scope, journey, or acceptance. Cold agent is asked "what
  does this commit promise the user" and must land on `product/`
  capability or journey narrative + acceptance row.
- **`design_truth`** — the commit moves a code anchor a design invariant
  points at. Cold agent is asked "which architecture anchor changed"
  and must land on a `[SYMBOL-PIN]` `path:LNN` or `[FAILURE-TRACE]`
  regression test.
- **`product_truth`** — the commit moves or clarifies current
  user-observable product reality: a shipped surface (route, handler,
  component, selector), a product gap, a design/debt state, or an explicit
  Out / not-applicable boundary. Cold agent is asked "what can the user
  rely on today, and what surface or gap owner proves it". It must land on
  either a `[SURFACE-PIN]` route + component + browser / route / CLI test
  for `state: contract`, or a product-owner state row that names
  `state: design` / `state: debt` / `Out` / `not_applicable` plus its
  closure owner (`DEBT-NNNN`, `ADJ-NNNN`, ADR closure condition, or named
  test-to-add). Product truth is current truth; it is not allowed to infer
  "not shipped yet" from silence.

A commit may produce trials in 1–4 pillars depending on its diff.
Cross-cutting commits (architecture+product) must produce trials in at
least one `*_intent` and one `*_truth` pillar. Each commit produces ≥3
trials per pillar (so a 4-pillar commit yields 12 trials; a single-
pillar commit yields 3 trials).

**Trial budget (cycle-2)**: the harness must cap total trials at 48 per
cycle (8 commits × 6 trials average). When a stratified sample produces
> 48 trials at the `≥3 per (commit, pillar)` rate, the harness reduces
to exactly 3 trials per `(commit, pillar)` cell and skips the over-quota
cells in this priority order: `product_truth` cross-cutting >
`design_truth` cross-cutting > `product_intent` operational >
`design_intent` operational. Skipped cells are recorded `N/A` in §5
results with `skipped_reason: budget-cap`; they do not count toward gate
denominators. A cycle that hits budget-cap on ≥2 pillars is flagged
inconclusive and the next cycle must re-stratify with fewer cross-cutting
commits. N/A cells from `budget-cap` are separable from N/A cells from
`pillar-not-applicable-to-commit` in the results table; the §3
inconclusive threshold (denom < 4) counts both.

**Pillar-roundtrip enforcement (v2.43, cycle-3).** The harness embeds
the assigned `pillar` value into the trial prompt as a fixed field
(e.g. `pillar_assigned: design_intent`) and instructs the cold agent to
echo it back unchanged. A trial whose returned `pillar` does not match
the harness-assigned `pillar` is recorded `verdict=FAIL` with the
synthetic class `pillar-mismatch` in the §5 results table; such trials
count toward the failing-cell denominator but are also flagged in §5
"Schema deviation" as a separate diagnostic and (when ≥ 10% of trials
in a cycle exhibit `pillar-mismatch`) escalate to `skill-fail` per §4
(the prompt template failed to constrain pillar labelling). The
per-pillar denominator in §3 is computed from harness-assigned pillars
only; agent-returned pillars are used solely for the roundtrip check.

### 1.5 Owner-pillar coverage requirement (v2.43, cycle-3)

Before the §1 stratified sample is finalised, the harness reads every
owner's `intent_recovery_pillars: [..]` declaration (per
`knowledge-integrity.md §1.1`) and computes the (owner, declared_pillar)
coverage matrix the cycle must hit. For each declared pillar of every
owner that is touched by ≥ 1 commit in the candidate sample, the cycle
MUST schedule ≥ 1 trial in that pillar against ≥ 1 such commit. When
the §1 stratified sample does not naturally satisfy this matrix, the
harness:

1. First, swaps in commits that touch the under-sampled owner's
   declared pillar (re-stratify within the candidate pool of 30).
2. If no candidate commit touches the under-sampled owner in the
   missing pillar, records the (owner, declared_pillar) pair as
   `pillar-not-applicable-to-cycle` in §5 results and carries it as an
   open `STATUS.md ## Pending Captures` row "owner X awaiting cycle
   that touches its declared pillar Y".
3. The pair is excluded from the multi-pillar `covered` gate per
   `knowledge-integrity.md §1.1` for this cycle; the owner remains
   `partial` until a future cycle's organic sample touches it.

The cycle report's §5 "Per-pillar score" table must include a new row
"declared-pillar coverage" listing how many declared (owner, pillar)
pairs were sampled vs. deferred. A cycle deferring ≥ 30% of declared
pairs is flagged inconclusive (the bundle protocol failed to drive
enough sampling pressure).

### 1.6 Canonical-vocab spot-check (v2.43.1, cycle-3)

In addition to the §1 commit-derived stratified sample, every cycle
adds a **vocab spot-check** stratum: 2 synthetic trials drawn from the
consumer's canonical-vocabulary registry (`glossary/README.md` + any
`[WORKFLOW-STATE-VOCAB]` (15A) targets) and from any term used
normatively in apex constraint files (e.g. `CLAUDE.md` / `AGENTS.md`)
but absent from `glossary/`. Selection is deterministic: the harness
greps the apex constraint files for typographic markers (\``\`-fenced
identifiers and `MUST/SHOULD/MAY` neighbourhoods), filters out terms
already glossary-defined, and picks the 2 with the highest reference
count. The trial prompt for these synthetic spot-checks is: "What does
<term> mean in this SSOT and where is its authoritative definition?".

The 2 spot-check trials are scored under the same §3 / §3.1 rules as
commit trials; FAIL with `miss_class=glossary-gap` is the expected
catch. Spot-check trials are tagged `pillar=glossary_vocab` (a fifth
pillar reserved for this stratum) and gated as a sixth gate condition:
`pillar_score[glossary_vocab] = 2/2`. A FAIL here is always `doc-fail`
(the consumer's glossary owes the entry); never `skill-fail`.

### 1.7 Core recovery manifest sweep (v2.45 / v2.46 / v2.47)

Before the §1 commit-derived sample is finalised, the harness reads the
consumer's Core recovery manifest from `product/README.md` or `product/prd.md`
and from `architecture/README.md` (defined by
`ssot-preflight/references/area-model.md §2.0.2`). The manifest produces a
finite set of mandatory `(core_item, owner, pillar)` cells.

Before row sampling, v2.46 adds one completeness probe per trunk. v2.47 expands
that probe so the cold agent must recover the prose intent/truth narrative
before relying on the manifest rows. The probe asks why the listed items are the
finite core, which product-model / operating-model classes are included, which
near-miss items are deliberately excluded, what is true today, what is
design/debt/Out, what wrong product or design conclusion would follow from
omitting a class, and which owner the reader should inspect next. A missing,
table-only, or heading-only argument is a mandatory FAIL even when every row has
an owner.

For each manifest row:

1. If the row declares a pillar as `not_applicable`, the row is recorded `N/A`
   only when it gives a reason and a revisit owner.
2. If the row's owner is touched by a commit in the candidate pool, the normal
   commit-derived trial covers that row.
3. If no candidate commit touches the row, the harness schedules one
   owner-directed synthetic trial per required pillar. The prompt input is the
   manifest row's user-visible / design-facing item name and asks the cold
   agent to recover the row's owner, current truth state, evidence / closure
   owner, and omission risk. Synthetic trials use the same hop budget and
   schema, but the `hop2_anchor` is graded against the manifest row or owner
   body rather than a commit diff hunk.

The cycle report records a "Core recovery manifest" table with one row per
mandatory cell plus one `completeness_argument` / `intent_truth_narrative` row
per trunk. A missing manifest, omitted core item, missing required pillar,
missing completeness argument, unexplained near-miss exclusion, unmapped
non-protocol state label, state stronger than the owner body (including
all-`contract` where `mixed` is required), or failed synthetic trial is
`miss_class=missing-owner` or `truth-state-gap` as appropriate and routes to
Doctor `[CORE-COVERAGE-MAP]` (15G). A missing/table-only prose narrative routes
to `[INTENT-TRUTH-NARRATIVE]` (15H); if the same document also omits a manifest
row or state, report both 15H and 15G. A cycle with any failing mandatory
manifest or narrative cell cannot support an area-level `intent_recovery:
covered` claim even if the ordinary 8-commit sample passes.

### 1.8 Directory-tree routing probe (v2.50, `dir-tree-only`)

Before the §1 commit-derived sample, the harness runs one routing-only probe
that gives the cold agent only `tree SSOT/ -L 3` output plus the first 40 lines
of the relevant directory README. Reading file bodies is forbidden — the test
is whether directory names, file names, and the README directory map are
enough to route the agent to the right owner.

| Field | Rule |
|---|---|
| Input | `tree SSOT/ -L 3` output (or `ls -R SSOT/` if `tree` unavailable) + first 40 lines (≈ one terminal screen) of `SSOT/README.md` and, when the question scopes deeper, the first 40 lines of the immediate parent directory README. **No file body reads.** |
| Hop budget | 2 (open at most one sub-directory README's first screen) |
| Question pool | Routing prompts the harness samples 5–8 per cycle; mandatory questions every cycle: (a) "I want to understand what the product promises the user — where do I go?", (b) "I want to read the front-end implementation — where do I go?", (c) "Should I open `_manifest.md`?", (d) "What's the relation between `control-plane` and `control-plane-benchmark` (or your closest equivalent pair)?", (e) "There are multiple files under `capabilities/` — which one do I read first?", (f) "I want to see known bugs — which directory?", (g) "I want to see the development workflow — which directory?". Add 2–4 questions sampled from the consumer's actual recent confusion log. |
| Verdict | `PASS` if the agent names the correct directory path and (when applicable) the correct file or file ordinal; `FAIL` otherwise. |
| `miss_class` (extends §3.1) | `navigation-gap` — the directory name itself does not display its role; `boundary-gap` — sibling directories' boundaries are not displayed (e.g. `bugs/` vs `tech-debt/` vs `gotchas/`); `meta-routing-gap` — the reader cannot tell whether to open `_manifest.md` (or any `_*.md`) from the map; `read-order-gap` — multiple peer files but the map does not name a reading order. |

Aggregate rule: at least 80% of the question pool must `PASS`. A FAIL on any
mandatory question (a)–(g) is a cycle-level signal — route the affected
directory through Doctor `15N` / `15O` / `15P` / `15Q` depending on the
`miss_class`. The probe runs whether or not the §1 commit sample fires; it is
the cheap up-front gate for IA self-display per
[`bootstrap.md` §3.7 A1](../../ssot-bootstrap/references/bootstrap.md#37-ssot-docs-must-be-readable-cold).

## 3. Grading rubric

Each commit gets ≥3 trials per pillar with majority vote (best-of-3, ≥2
trials must succeed) per `(commit, pillar)` cell. A trial is `pass` only
when:

1. `hop1_path` is a real file under `SSOT/` (Reader-Map / domain README / capability / playbook acceptable).
2. `hop2_anchor` resolves: the file:line lands inside the commit's diff hunk **±10 lines** (or is named anywhere in the diff); the test name appears in the diff or is the regression test the diff explicitly cites; the DOM selector / route / SQL identifier appears verbatim in the diff.
3. Hops used ≤ 5.
4. Output is well-formed (matches the schema; no "I cannot find" answer).

Any one failure ⇒ trial fail. Trial vote per `(commit, pillar)`:
- ≥ 2 of 3 trials pass → that `(commit, pillar)` cell scores 1/1.
- otherwise → that `(commit, pillar)` cell scores 0/1.

**Cycle scoring (v2.43, per-pillar plus aggregate, on an 8-commit × 4-pillar grid)**:

- `pillar_score[p] = sum of (commit, pillar=p) cells / 8 commits`, per
  pillar `p ∈ {design_intent, product_intent, design_truth, product_truth}`.
- `total_score = sum of pillar_score[p] over all 4 pillars`, max `32/32`.

**Cycle gate (all conditions must hold)**:

1. `pillar_score[design_intent] ≥ ceil(0.625 · denominator[design_intent])` cells passing, denominator ≥ 4 (else inconclusive per §3 closing paragraph)
2. `pillar_score[product_intent] ≥ ceil(0.625 · denominator[product_intent])`, denominator ≥ 4
3. `pillar_score[design_truth] ≥ ceil(0.625 · denominator[design_truth])`, denominator ≥ 4
4. `pillar_score[product_truth] ≥ ceil(0.625 · denominator[product_truth])`, denominator ≥ 4
5. `total_score / sum(denominators) ≥ 0.75`, evaluated as a ratio so the rule survives N/A reduction (at full 8×4=32 the ratio collapses to the announced ≥ 24/32 floor; with N/A the same 0.75 floor is enforced against the reduced denominator)
6. zero rows in the skill-fail partition (§4)
7. `pillar_score[glossary_vocab] = 2/2` (per §1.6); a FAIL here routes to `STATUS.md ## Pending Captures` as `glossary-gap` doc-fail.
8. every mandatory Core recovery manifest cell is PASS or `N/A` with a reason
   and revisit owner (per §1.7).

When any pillar denominator falls below 4 commits the cycle is
inconclusive (per the existing rule below); the gate is not evaluated.

The per-pillar floor (`5/8`) prevents a strong pillar from masking a
collapsed pillar; the aggregate floor (`24/32`) prevents four borderline
pillars from all sitting at `5/8` (which would average 62.5% — below the
prior 75% bar). When a commit produces no trials in a pillar (e.g. a
pure architecture-core commit has no `product_truth` trial), that cell
is recorded as `N/A` and the pillar denominator drops accordingly; if
any pillar denominator falls below 4 commits the cycle is inconclusive
and the sample must be re-stratified.

The §0 "When to run" reference to `pass rate ≥ 75% (≥ 6/8 trials)` from
v2.42 is superseded by this 4-pillar rule.

### 3.1 Miss-class taxonomy (v2.43)

Every FAIL trial must record exactly one `miss_class` drawn from the
closed set below. The cold agent emits `miss_class` in the trial output
(extending the §2 schema; `null` is required for `verdict=PASS` and
forbidden for `verdict=FAIL`):

| miss_class | Definition | Trial signature | Routing fix layer |
|---|---|---|---|
| `missing-owner` | No SSOT file claims authority over the commit's pillar-appropriate intent/truth. The cold agent exhausted the hop budget without finding any candidate file whose body would house the answer. | hop1 fails: every Reader Map / index points to areas that disclaim ownership; or grep over `SSOT/` for the intent's keywords yields zero authoritative-body hits. | New owner row in architecture/domain README, product capability file, or `decisions/` entry. Often surfaces a `[PRODUCT-OWNER]` or `[ARCH-DOMAINS]` gap. |
| `prose-fork` | The fact exists in ≥2 SSOT locations with overlapping prose, and the cold agent landed on the non-authoritative copy (anchor was stale or partial). Same root cause as Doctor `[FORK]` (15D) but observed from the routing side. | hop2 anchor resolves but the resolved file has been demoted to a thin link OR the diff hunk is owned by a sibling file the cold agent did not visit within budget OR hop2 anchor resolves but post-trial `ssot-lint.sh` reports the resolved file is the non-authoritative copy of a forked fact (see §3.2). | Migrate the fact to its unique runtime owner; non-owners become single-line links. Always pairs with a `[FORK]` (15D) or `[CORE-REF-PROSE]` (14Z) doctor row. |
| `broken-ref` | The owner exists and points at the right anchor kind, but the pointer itself is stale: `path:LNN` drifted, symbol renamed, route moved, test renamed, or capability surface registry row out of date. The cold agent did not exceed budget — the pointer just resolved to the wrong line/symbol or to a deleted file. | hop2 anchor matches the schema but ±10-line check fails OR target file does not exist OR named symbol/test/selector is not in the diff. | Update the pointer (`[SYMBOL-PIN]` / `[SURFACE-PIN]` / `[FAILURE-TRACE]` anchor refresh). Lint script `ssot-lint.sh` #2 catches the mechanical case; semantic drift needs Doctor row 20 `[CORE-REF]` / `[SYMBOL-PIN]` (14S). |
| `glossary-gap` | The intent prompt uses a term that has no positive-definition-on-first-use anywhere in SSOT (or has multiple inconsistent definitions across owners). The cold agent could not disambiguate which owner the term routed to. | Multiple hop1 candidates each plausibly own the term; OR no file defines the term and the cold agent cannot map the user-visible word to an SSOT entity. | Add the term to `glossary/` with a positive definition and a unique owner pointer. Often surfaces a `[READABILITY]` (14I) negation-only definition or an undefined product-capability noun, or a missing `[WORKFLOW-STATE-VOCAB]` (15A) canonical-vocabulary entry. |
| `truth-state-gap` (v2.44) | The product owner names a current/planned user-observable surface but does not state whether today's truth is shipped contract, design/debt, Out, or not applicable; OR it records `state: design` / `state: debt` / "later" without a falsifiable closure owner. | `product_truth` trial reaches the right capability/journey but the row has no `state`, no current user-visible behavior, no missing-evidence description, or no `DEBT/ADJ/ADR/test` closure pointer. | Add a product current-truth row per `area-model.md §2.1`: `state: contract` + `[SURFACE-PIN]`, or `state: design/debt/Out/not_applicable` + current behavior + closure owner. This is a doc-fail unless the bundle protocol omitted the row shape. |
| `pillar-mismatch` (cycle-3) | The agent-returned `pillar` does not equal the harness-assigned `pillar`. Indicates prompt-template instability rather than a routing or owner failure. | `pillar` field in trial output ≠ `pillar_assigned` field in trial prompt. | Tighten the §2.1 prompt template; this is a `skill-fail` when ≥10% of trials in a cycle exhibit it. |

Fail rows extend the §4 schema to `(commit_sha, pillar, hop_died_at,
miss_class, expected_anchor_kind, actual_anchor_kind,
proposed_fix_owner)`. Cycle reports must group fails by
`(pillar, miss_class)` so cycles can detect convergence (same pair
appearing two cycles in a row escalates from doc-fail to skill-fail per
§4 tie-breaker logic).

### 3.2 Authoritative-owner check (v2.43.1, cycle-3)

A `verdict=PASS` trial is downgraded to `verdict=FAIL` with
`miss_class=prose-fork` whenever the resolved `hop2_anchor` lives in a
file that doctor row `15D [FORK]` or `14Z [CORE-REF-PROSE]` would flag
against the same fact in the same cycle. Concretely, after the cold
agent emits its trial output, the harness runs `ssot-lint.sh` against
the resolved file and the canonical owner (located via the Reader-Map
/ glossary lookup); if the lint reports that the resolved file's body
duplicates prose owned by another file, the trial is recorded as
`prose-fork` regardless of the agent's self-assessment.

This closes the silent-pass path that lets a forked fact satisfy §3
grading without surfacing the fork. It is the only place where harness
post-processing overrides the agent's `verdict`; in all other cases
`verdict` is taken at face value per the routing-only mandate
(§2 routing-only mandate).

## 4. Failure partition (skill-fail vs doc-fail)

The judgement that fixes SSOT-SKILL versus the judgement that fixes the
consumer SSOT must be split, or the skill never converges:

| Partition | Definition |
|---|---|
| `doc-fail` | The bundle protocol already requires the anchor type the cold agent needed (e.g. `[SYMBOL-PIN]`, `[SURFACE-PIN]`, `[FAILURE-TRACE]`) but the consumer SSOT did not provide it. Doctor on the same slice flags it. → routed to consumer's `STATUS.md ## Pending Captures` for the next cycle's doc rewrite phase. |
| `skill-fail` | The bundle protocol does **not** require the anchor type the cold agent needed (or required it only at WARN level, never as a hard gate). Doctor on the same slice is clean but the cold agent still fails. → routed to `projects/SSOT-SKILL/skills/ssot-audit/references/protocol-upgrades.md ## Bundle Captures` for the next cycle's skill phase, prioritised before doc work. |
| Tie-breaker | If doctor is dirty *and* the cold agent fails on the same row, treat as `doc-fail` first — the doc fix may also fix the cold agent fail. Re-classify on the next cycle if it persists. |

Each fail row records: `(commit_sha, pillar, hop_died_at, miss_class,
expected_anchor_kind, actual_anchor_kind, proposed_fix_owner)` per §3.1.
Subsequent cycles group related fails by `(pillar, miss_class)`; a pair
appearing in two consecutive cycles escalates the row from `doc-fail` to
`skill-fail` automatically (the bundle protocol failed to gate what the
consumer SSOT failed to provide twice in a row, so the responsibility
crosses the partition boundary). The legacy `missing_evidence_kind` field
is retired — `miss_class` carries the same information with a closed
vocabulary.

## 5. Reproducibility

Each run produces:
`projects/SSOT-SKILL/skills/ssot-doctor/assets/cold-agent-sim/cycle-example.md`

With these sections:

```markdown
# Cycle <N> Cold-Agent Simulation Report

## Setup
- Commit pool: <git rev range>
- Sampling cycle-id: <id>
- Model: <pinned id>
- Trials per commit: 3
- Hop budget: 5
- Run date: <ISO>

## Sample (8 commits)
| # | SHA | Stratum | Subject |
| ...

## Results (per (commit, pillar) cell, v2.43)
| # | SHA | pillar | trial-1 | trial-2 | trial-3 | cell_score (0/1) | hop_died_at | miss_class | partition |
| ...

A `(commit, pillar)` row appears once per pillar the commit produces trials in (1–4 rows per commit). `cell_score` is 1 when ≥2 of 3 trials pass per §3, else 0. `miss_class` is `null` when `cell_score=1`; required and drawn from §3.1's closed set otherwise.

## Per-pillar score
| pillar | passing cells | denominator | pillar_score | floor (≥5/8 = 0.625) | gate |
|---|---|---|---|---|---|
| design_intent | … | … | … | … | PASS / FAIL |
| product_intent | … | … | … | … | PASS / FAIL |
| design_truth | … | … | … | … | PASS / FAIL |
| product_truth | … | … | … | … | PASS / FAIL |
| **total** | … | …/32 | … | ≥24/32 | PASS / FAIL |

## Core recovery manifest (v2.45 / v2.47)
| area | core_item | owner | pillar | trial_kind | state | verdict | miss_class | closure_owner |
| ...

## Miss-class distribution (FAIL cells)
| pillar | missing-owner | prose-fork | broken-ref | glossary-gap |
| ...

## Skill-fail rows (route to bundle captures)
| commit | pillar | expected_anchor_kind | actual_anchor_kind | miss_class | proposed_fix_owner | proposed bundle change |
| ...

## Doc-fail rows (route to consumer Pending Captures)
| commit | pillar | expected_anchor_kind | actual_anchor_kind | miss_class | proposed_fix_owner | proposed doc change |
| ...

## Cycle gate
PASS / FAIL — per §3: `pillar_score[p] ≥ 5/8` for all p ∈ {design_intent, product_intent, design_truth, product_truth} AND `total_score ≥ 24/32` AND `glossary_vocab = 2/2` AND every mandatory Core recovery manifest cell is PASS / reasoned N/A AND zero skill-fail rows. The flat 75% rule from v2.42 does not apply.
```

The full transcript of each trial is archived under
`assets/cold-agent-sim/transcripts/cycle-<N>/<commit-sha>-trial-<n>.md`.

## 6. Termination

The SSOT-SKILL × consumer-SSOT iterative cycle terminates when **two consecutive cycles** simultaneously satisfy the §3 cycle gate in full:

1. `pillar_score[design_intent] ≥ ceil(0.625·denom)` cells passing, and
2. `pillar_score[product_intent] ≥ ceil(0.625·denom)`, and
3. `pillar_score[design_truth] ≥ ceil(0.625·denom)`, and
4. `pillar_score[product_truth] ≥ ceil(0.625·denom)`, and
5. `total_score / sum(denominators) ≥ 0.75`, and
6. `pillar_score[glossary_vocab] = 2/2`, and
7. every mandatory Core recovery manifest cell is PASS or reasoned N/A, and
8. zero `skill-fail` rows in either cycle.

A single passing cycle is not enough — the gate must be stable across one
slice rotation to confirm the bundle anticipates rather than memorises.
The pre-v2.43 flat-75% rule does not satisfy termination even when both
cycles report ≥ 75% aggregate; a collapsed single pillar blocks
termination even if the other three carry the average.
