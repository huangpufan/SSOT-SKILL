# Changelog

All notable changes to the SSOT Skill bundle protocol.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project adheres to a simple `MAJOR.MINOR` versioning scheme tied to
the bundle protocol. The single source of truth for the current version is
`metadata.protocol_version` in `skills/ssot-preflight/SKILL.md`; the `VERSION`
file at the repository root is the physical mirror enforced by
`tests/test-bundle-shape.sh`.

Each entry below is derived from the protocol-upgrade ledger rooted at
`skills/ssot-audit/references/protocol-upgrades.md`: that file routes to
`current-upgrade.md` for current/recent entries and to `archive/` for older
versions. This file only restates headline changes.

## [Unreleased]

### Changed
- Scrubbed origin-project references from shipped skill assets: replaced
  cold-agent-sim cycle transcripts with one synthetic example using a
  fictional project; replaced origin-project implementation paths in
  `ssot-preflight/references/` and `ssot-audit/references/` with synthetic
  placeholders; replaced real commit SHAs in audit history with `<commit>`.
- AGENTS.md commit discipline now explicitly scopes to maintainers and
  points external contributors at `CONTRIBUTING.md`.
- SKILL_STYLE.md now records the `ssot-preflight` gate/router exception
  alongside the bundle-wide anti-patterns.

### Added
- `What is SSOT?` section in `README.md` / `README.zh.md` that explicitly
  defines "Single Source of Truth", explains how the principle maps to
  `SSOT/` in this skill, and reiterates that code/schema/tests remain the
  truth for current implementation (bilingual parity preserved).
- `Requirements` and `Uninstall` sections in `README.md` / `README.zh.md`
  (bilingual parity preserved).
- OSS hygiene files: `SECURITY.md`, `CODE_OF_CONDUCT.md`,
  `.github/ISSUE_TEMPLATE/bug_report.md`,
  `.github/ISSUE_TEMPLATE/feature_request.md`,
  `.github/PULL_REQUEST_TEMPLATE.md`.
- `install.sh` bash-4+ guard with a macOS-specific `brew install bash`
  hint, plus `SSOT_SKILL_REPO_URL` env override for forks.
- `tests/test-bundle-shape.sh` now resolves links via portable
  `python3 os.path.realpath` instead of GNU `readlink -f`.
- `.github/workflows/ci.yml` runs `bash-syntax`, `bundle-shape`, and
  `installer-e2e` jobs on `ubuntu-latest` and `macos-latest`.

### Removed
- Obsolete `workflows/intent-recoverability-loop.workflow.js` (and the
  now-empty `workflows/` directory).

## [2.53] - 2026-06-30

`semantic_impact: medium` — adds the **active recommendation / non-silent
deferral floor**. Preflight now classifies task-overlapping open risks as
`fix-now`, `recommend-now`, `defer-visible`, or `ignore-for-scope`; closeout
must carry each recommendation to a visible disposition. Deferrals must keep an
owner or owner record, reason, closure condition, revisit signal, verification
guard, and next concrete action. Lint adds `[SILENT-DEFERRAL]` for obvious
future-work wording without owner/reference or retrigger signals.

### Changed
- **`VERSION`** -> `2.53`.
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version` -> `2.53`.
- **`ssot-preflight` / `ssot-closeout`** now require classification and
  closeout disposition of task-relevant risk recommendations.
- **`area-model.md`** `tech-debt/` rules now state active debt is not passive
  backlog and active entries should expose next action / must-handle triggers
  on the first screen.
- **`doctor.md`** documents the new `[SILENT-DEFERRAL]` tag and extends the
  open-risk deterministic summary.

### Added
- `ssot-lint.sh` check for `[SILENT-DEFERRAL]`, scoped to obvious "later /
  someday / future work" wording and locked-language equivalents that lack
  owner/reference or retrigger signals.
- Lint smoke tests for silent deferral failure and owner-backed deferral pass.

## [2.52] - 2026-06-30

`semantic_impact: medium` — adds the **open-risk and temporary-surface floor**.
Preflight now surfaces task-relevant active debt, gotchas, bugs, and open gaps;
closeout must either close, defer with owner/trigger/guard, or create a next
action. Temporary fallback, compat shim, later-remove, TODO/FIXME/HACK, and
waiver surfaces must be registered with owner, reason, closure condition,
revisit signal, and verification guard. Lint adds deterministic checks for
markdown fence balance, ADR/debt closure fields, covered-area placeholder
residue, STATUS aggregate contradictions, unowned gap rows, and pending-action
text hidden inside resolved capture sections. Bundle-shape adds public hygiene
guards for local paths, origin-project names, real commit SHAs, and unclosed
Markdown fences.

### Changed
- **`VERSION`** -> `2.52`.
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version` -> `2.52`.
- **`ssot-preflight` / `ssot-closeout`** now require task-relevant open-risk
  recommendations and closeout disposition.
- **`area-model.md`** `tech-debt/` rules now define temporary-surface
  registration fields.
- **`architecture.md` §16** now uses one owner per Capability -> Surface
  registry row plus link-only mirrors instead of duplicate product /
  architecture registry rows.

### Added
- `ssot-lint.sh` checks for `[MARKDOWN-FENCE]`, `[ADR-CLOSURE]`,
  `[DEBT-CLOSURE]`, `[TEMP-SURFACE]`, `[COVERED-PLACEHOLDER]`,
  `[STATUS-AGGREGATE]`, `[GAP-OWNER]`, and `[CAPTURE-LIFECYCLE]`.
- Lint smoke tests for the new deterministic checks.
- Bundle-shape checks for unclosed Markdown fences and public OSS leakage
  patterns.

## [2.51] - 2026-06-23

`semantic_impact: medium` — adds the **reader-scaffolds floor**. The v2.47–v2.50
floors all subtracted (cut shadow ledgers, table-only intent, language-drift
H1s, missing directory maps); v2.51 adds the additive complement: four
owner-template structural slots a cold agent uses to orient itself after
routing — `## Walkthrough`, `## Easily confused with`, `## Out of scope`,
`## See also` — plus a new `glossary-entry.md` per-term template,
diagram-typing comments in architecture Mermaid blocks, and a KISS mini-card
permitted form for first-mention canonical vocabulary that does not violate
`15F [VOCAB-PROSE-FORK]`. Self-reviewable per `status-protocol.md §7.1`; no
doctor stop-review required.

### Added
- **Owner-template structural slots** — every owner-archetype template in
  `skills/ssot-bootstrap/assets/templates/{en,zh}/` (`ssot-readme.md`,
  `architecture-readme.md`, `architecture-domain-readme.md`,
  `product-readme.md`, `dir-readme-map.md`) now carries `## Walkthrough`,
  `## Easily confused with`, `## Out of scope`, `## See also` H2 slots.
- **`glossary-entry.md` template** (en + zh) — per-term glossary entry skeleton:
  one-sentence positive definition, `Used in` inverse index,
  `Not to be confused with` boundary list, source pin.
- **`architecture-domain-readme.md`** gains a `### Walkthrough (canonical flow)`
  H3 above the Runtime Flows table (required when the table is non-empty).
- **`product-readme.md`** gains a `## Capabilities ↔ Journeys diagram`
  mermaid block.
- **Diagram-typing comments** — first mermaid block in each architecture
  template carries `<!-- diagram_type: component -->`; templates surface the
  one-type-per-block rule via an inline notice.
- **KISS mini-card permitted form** (`SKILL_STYLE.md` reader-scaffolds section):
  first-mention canonical vocabulary may appear inline as
  `**Term** (def: <≤ 15-word clause> → [CORE-REF: glossary/<term>.md])`
  without violating `15F [VOCAB-PROSE-FORK]`.
- **Doctor rows** `15R [WALKTHROUGH]`, `15S [BOUNDARY-DISAMBIG]`,
  `15T [OUT-OF-SCOPE-LINK]`, `15U [DIAGRAM-TYPE-TAG]`, `15V [DIAGRAM-FIRST]`
  appended to `skills/ssot-doctor/references/doctor.md` §2.2. All five ship
  WARN-only; `15R` graduates to FAIL next cycle.
- **`ssot-lint.sh` checks 18–22** mirror the five new doctor rows
  (structural grep only — heading presence, mermaid fence inspection,
  first-screen line-count check). No NLP.
- **Audit ledger entry** `### v2.51` added to
  `skills/ssot-audit/references/current-upgrade.md` with the
  semantic-impact-medium checklist.

### Changed
- **`VERSION`** -> `2.51`.
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version` -> `2.51`.
- **`skills/ssot-bootstrap/references/bootstrap.md`** §3.7: added
  `**Reader scaffolds (v2.51).**` subsection (four slots, per-archetype
  minimum scaffold set, additive-vs-subtractive framing).
- **`skills/SKILL_STYLE.md`**: added `## Reader scaffolds (v2.51)` section
  (six-slot summary, why no `archetype:` frontmatter, diagram typing,
  KISS mini-card permitted form).
- **`skills/ssot-preflight/references/area-model.md`** §2.0: required-answer
  list extended from five questions to six (added "Where can I go next, and
  what does this owner explicitly NOT answer").
- **`skills/ssot-preflight/references/area-model.md`** §2.3: added
  `**v2.51 entry template.**` note pointing new glossary entries at
  `glossary-entry.md`; pre-v2.51 entries grandfather in until next touched.
- **All five owner-archetype templates**: writing-style banner upgraded
  from one-line `> Writing style: ...` to multi-line form that names the
  reader-scaffold slots and links both `bootstrap.md §3.7` and
  `SKILL_STYLE.md` reader-scaffolds section.
- **`skills/ssot-bootstrap/references/templates-index.md`**: added
  `glossary-entry.md` row.

### Compatibility
- `semantic_impact: medium` — self-reviewable; consumers bump
  `tracked_skill_version` to `2.51` without an external reviewer.
- All five new lint checks ship as WARN-only in this cycle so existing
  converged SSOTs do not regress on the upgrade itself.
- `15R [WALKTHROUGH]` graduates to FAIL in the next cycle's protocol entry;
  the other four stay WARN until consumer-adoption signal justifies
  promotion.
- The KISS mini-card permitted form is opt-in; existing
  `[CORE-REF: ...]` links remain valid.

## [2.50] - 2026-06

`semantic_impact: medium` — adds the **information-architecture (IA)
self-display floor**: a cold reader's first touch is `ls` / `tree`, not
`cat`. Directory names, file-name prefixes, and the README directory-map
annotations must carry routing weight; prose is the fallback when the name
alone cannot disambiguate. New `bootstrap.md` §3.7 sub-rules A1.1–A1.4,
new Doctor rows `15N` / `15O` / `15P` / `15Q`, new `ssot-lint.sh`
`[DIR-MAP-MISSING]` check, new `cold-agent-sim.md §1.8 dir-tree-only`
probe, and a new `dir-readme-map.md` template (en/zh).

### Changed
- **`VERSION`** -> `2.50`.
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version` -> `2.50`.
- **`skills/ssot-bootstrap/references/bootstrap.md`** §3.7: added
  "Information-architecture self-display (v2.50)" block introducing
  sub-rules A1.1 (directory README = directory map), A1.2 (numeric
  prefix for read-ordered directories), A1.3 (file names spoken in plain
  words), A1.4 (meta files routed explicitly).
- **`skills/ssot-doctor/references/doctor.md`** §2.1 L1 checklist and §4
  output-tag list: added rows `15N [DIR-MAP]`, `15O [READ-ORDER]`,
  `15P [META-FILE-ROUTING]`, `15Q [JARGON-MAP-NOTE]` plus §3 coverage
  hard-blocker entries for each.
- **`skills/ssot-doctor/references/cold-agent-sim.md`** §1.8:
  added the `dir-tree-only` routing probe with mandatory question pool
  and `navigation-gap` / `boundary-gap` / `meta-routing-gap` /
  `read-order-gap` miss classes.
- **`skills/ssot-doctor/assets/scripts/ssot-lint.sh`**: added check 17
  `[DIR-MAP-MISSING]` (15N) verifying that every directory README's
  first 60 lines carries an ASCII tree (├── / └── glyphs). Made checks
  9 and 10 (intent-truth-narrative + product skeleton) resolve the
  product / architecture trunk path at runtime so consumers can facet
  the top level (e.g. `SSOT/01-product/`, `SSOT/02-architecture/`)
  without breaking the skeleton check.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/dir-readme-map.md`**:
  new template — H1 + one-sentence purpose + ASCII tree with
  plain-language annotation rows + recommended-reading-order line +
  one-paragraph "why this split".

### Compatibility
- Existing consumers that use the canonical un-faceted shape
  (`SSOT/product/`, `SSOT/architecture/`) continue to pass the v2.50
  lint unchanged.
- Consumers that previously had directory READMEs without an ASCII tree
  must add one. The `[DIR-MAP-MISSING]` check is a FAIL.
- The `[PRODUCT]` skeleton check now also accepts `SSOT/01-product/`
  when that directory exists; the canonical `SSOT/product/` is still
  the default fall-through.

## [2.49] - 2026-06

`semantic_impact: low` — codifies SSOT document naming, frontmatter
uniformity, and H1 language conventions in a single reference
(`skills/ssot-bootstrap/references/formatting-conventions.md`) and gives
`ssot-lint.sh` four new deterministic checks plus matching Doctor L2 rows
so the conventions can be enforced mechanically.

### Changed
- **`VERSION`** -> `2.49`.
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version` -> `2.49`.
- **`skills/ssot-bootstrap/references/formatting-conventions.md`**: new file
  — naming (`NN-` ordered prefix vs `NNNN-` ledger prefix vs unordered
  kebab-case), same-directory frontmatter uniformity, the
  `intent_recovery:` propagation rule under `product/` and `architecture/`,
  and the H1-leads-with-locked-language rule.
- **`skills/ssot-bootstrap/references/bootstrap.md`**: adds §3.8 pointing at
  the new formatting-conventions reference.
- **`skills/ssot-doctor/references/doctor.md`**: adds rows
  `15J [PEER-FRONTMATTER]`, `15K [NUMBERED-PREFIX]`, `15L [H1-LANGUAGE]`,
  `15M [INTENT-RECOVERY-UNIFORM]`; adds matching hard-blocker bullets
  (15J / 15K / 15M block `covered`, 15L WARN-only) and output tag entries.
- **`skills/ssot-doctor/assets/scripts/ssot-lint.sh`**: adds checks 13–16
  (15J–15M) — sibling frontmatter key-set uniformity, ordered-directory
  numbering, pure-English H1 detection under `documentation_language: zh`,
  and `intent_recovery:` presence on `product/` and `architecture/` prose.

## [2.48] - 2026-06

`semantic_impact: medium` — separates SSOT self-maintenance machinery from
product / architecture prose. Doctor / lint / cold-agent-sim machinery
introduced by v2.43–v2.47 (Core recovery manifest, Core completeness argument,
Apex / Maxim → Owner index, Capability → Surface registry mirror rows,
intent-recovery pillar matrix, `intent_recovery_evidence` strings, README-self
failure-mode sections, adoption-cycle version labels) now lives in a sibling
`_manifest.md` per covered area. Prose owners (`product/*.md`,
`product/{capabilities,journeys}/*.md`, `architecture/*.md`,
`architecture/*/*.md`, `architecture/views/*.md` — excluding `_manifest.md`)
carry only the product / design narrative plus inline `[CORE-REF: ...]`
anchors. Doctor gains hard row `15I [META-LEAKAGE]`; `ssot-lint.sh` gains a
deterministic grep check (always run as part of normal lint) plus a standalone
`--check-meta-leakage` flag.

### Changed
- **`VERSION`** -> `2.48`.
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version` -> `2.48`.
- **`skills/ssot-preflight/references/area-model.md`**: adds §2.0.5 Manifest
  separation defining the prose/manifest split and the v2.48 forbidden-token
  list for covered prose files.
- **`skills/ssot-doctor/references/doctor.md`**: adds `15I [META-LEAKAGE]`
  row, tag entry, and hard-blocker bullet; extends the L1 automation prefix.
- **`skills/ssot-doctor/assets/scripts/ssot-lint.sh`**: adds always-on `15I`
  grep (FAIL on hit) plus standalone `--check-meta-leakage [DIR ...]` mode
  for targeted invocation against `SSOT/01-product/` and `SSOT/02-architecture/`.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/_manifest.md`**: new
  template for area-level `_manifest.md` (Core recovery manifest + Apex /
  Maxim mirror + Capability surface registry + README-self failure modes +
  intent-recovery evidence + adoption-cycle log).
- **`skills/ssot-audit/references/current-upgrade.md`**: adds v2.48 ledger
  entry with impact checklist and no-op criteria.

### Migration
- Run `ssot-lint.sh --check-meta-leakage SSOT/01-product/ SSOT/02-architecture/`
  to enumerate current `15I` hits.
- For each covered area, create `<area>/_manifest.md` from the new template
  and move Core recovery manifest, Apex / Maxim mirror, Capability surface
  registry rows, intent-recovery evidence, README-self failure-mode sections,
  and adoption-cycle labels into it. Frontmatter on prose files reduces to
  `intent_recovery: covered|partial|gap`.
- Re-run the targeted lint; `FAIL=0` is the v2.48 acceptance bar.

## [2.47] - 2026-06

`semantic_impact: medium` — adds an intent/truth narrative gate for product and
architecture trunks. Covered product / architecture areas must explain product
intent + product truth or design intent + design truth in compact prose before
Core recovery manifests or dense owner maps; the manifest remains a narrow
recovery index. Doctor gains `15H [INTENT-TRUTH-NARRATIVE]`, and `ssot-lint.sh`
adds a WARN-only heuristic for covered trunks that have a Core recovery manifest
but no obvious intent/truth narrative heading.

### Changed
- **`VERSION`** -> `2.47`.
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version` -> `2.47`.
- **`skills/ssot-preflight/references/area-model.md`**: adds §2.0.3
  intent/truth narrative before manifests.
- **`skills/ssot-preflight/references/architecture.md`** and
  **`skills/ssot-bootstrap/references/bootstrap.md`**: require prose-first
  product/design intent and truth before dense tables.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/{product-readme.md,architecture-readme.md}`**:
  add product/design intent-truth sections.
- **`skills/ssot-doctor/references/doctor.md`**: adds
  `15H [INTENT-TRUTH-NARRATIVE]`.
- **`skills/ssot-doctor/assets/scripts/ssot-lint.sh`** and its test runner:
  add the WARN-only intent/truth narrative heuristic.
- **`skills/ssot-audit/references/current-upgrade.md`**: prepends the v2.47
  medium-impact upgrade entry.

## [2.46] - 2026-06

`semantic_impact: medium` — tightens the Core recovery manifest into a
first-principles completeness check. Product and architecture trunks that claim
`covered` must now explain why their finite core set is complete, which
product-model / operating-model classes are included, which near-miss items are
excluded, and what wrong conclusion an omitted class would cause. Doctor
`15G [CORE-COVERAGE-MAP]` now covers missing completeness arguments, omitted
product posture/model or architecture operating-model/CTG rows, unmapped state
labels such as `current`, and spine-owned rows that lack a same-granularity
anchor.

### Changed
- **`VERSION`** -> `2.46`.
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version` -> `2.46`.
- **`skills/ssot-preflight/references/area-model.md`**: extends the Core
  recovery manifest with the Core completeness argument and spine-row anchor
  rule.
- **`skills/ssot-preflight/references/knowledge-integrity.md`**: binds
  `intent_recovery: covered` to the completeness argument as well as manifest
  row coverage.
- **`skills/ssot-doctor/references/cold-agent-sim.md`**: adds the
  completeness probe and omission-risk prompt dimension to manifest sweeps.
- **`skills/ssot-doctor/references/doctor.md`**: broadens
  `15G [CORE-COVERAGE-MAP]`.
- **`skills/ssot-audit/references/current-upgrade.md`**: prepends the
  standalone v2.46 medium-impact upgrade entry.

## [2.45] - 2026-06

`semantic_impact: medium` — adds a finite Core recovery manifest requirement
for product and architecture recoverability. Consumers that mark `product` or
`architecture` as `covered` must enumerate the core capabilities, journeys,
runtime owners, and cross-owner views whose product/design intent and truth must
be recoverable; each row names required pillars, current truth state, owner, and
closure/evidence owner. `mixed` is the explicit state for a row that combines
shipped contract truth with unresolved design/debt/out truth. Cold-agent-sim now
performs owner-directed manifest trials for core rows not touched by recent commits, and Doctor gains
`15G [CORE-COVERAGE-MAP]`.

### Changed
- **`VERSION`** -> `2.45`.
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version` -> `2.45`
  and explicitly reports stale runtime-installed skill copies when a project
  source checkout is newer.
- **`skills/ssot-preflight/references/area-model.md`**: adds the Core recovery
  manifest rule for product and architecture trunks.
- **`skills/ssot-preflight/references/knowledge-integrity.md`**: binds
  `intent_recovery: covered` to complete manifest coverage.
- **`skills/ssot-doctor/references/cold-agent-sim.md`**: adds manifest sweep
  scheduling, synthetic owner-directed trials, result reporting, and cycle-gate
  criteria.
- **`skills/ssot-doctor/references/doctor.md`**: adds
  `15G [CORE-COVERAGE-MAP]`.
- **`skills/ssot-audit/references/current-upgrade.md`**: prepend the standalone
  v2.45 medium-impact upgrade entry.

## [2.44] - 2026-06

`semantic_impact: medium` — tightens the intent-recoverability model for
current product truth. A product `product_truth` trial no longer treats
"no contract-level browser surface exists yet" as automatically equivalent to
unrecoverable truth when the product owner explicitly marks the row as
`state: design`, `state: debt`, `Out`, or `not_applicable` and gives the
current user-visible behavior plus a falsifiable gap / decision / debt anchor.
This prevents the harness from forcing product files to pretend a planned or
negative surface is a shipped contract just to satisfy `[SURFACE-PIN]`.

### Changed
- **`VERSION`** -> `2.44`.
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version` -> `2.44`.
- **`skills/ssot-preflight/references/area-model.md`**: `product/`
  capability owners must carry current-truth anchors for contract,
  design/debt, Out, and not-applicable rows.
- **`skills/ssot-preflight/references/knowledge-integrity.md`**:
  `product_truth` intent recovery explicitly accepts state-tagged negative /
  design current-truth anchors when the current behavior and closure owner are
  recoverable.
- **`skills/ssot-doctor/references/cold-agent-sim.md`**: `product_truth`
  pillar, output schema, grading rubric, and miss-class taxonomy gain
  `truth-state-gap`.
- **`skills/ssot-doctor/references/doctor.md`**: `[SURFACE-PIN]` (14T) and
  `[INTENT-RECOVERY]` (14Y) distinguish contract surface anchors from
  state-tagged current-truth anchors.
- **`skills/ssot-audit/references/current-upgrade.md`**: prepend the
  standalone v2.44 medium-impact upgrade entry.

## [2.43] - 2026-06

`semantic_impact: medium` — opens the intent-recoverability cycle. Adds an
apex-maxim → SSOT-owner mapping protocol (new
`skills/ssot-preflight/references/intent-ownership.md`), an architecture
domain README intent triad (`## Why` / `## 失败模式` / `## 关闭条件`), a
canonical-vocabulary hard list for `glossary/`, falsifiable
`closure_condition` + `revisit_signal` fields for ADRs and tech-debt
entries, and an `intent_recovery: covered | partial | gap` axis on
`knowledge-integrity.md` that binds `STATUS.md` `covered` to passing
cold-agent-sim trials. The cold-agent simulation harness now scores per
4 pillars (`design_intent` / `product_intent` / `design_truth` /
`product_truth`) with a `≥ 5/8` floor per pillar plus `≥ 24/32` aggregate
gate, and every FAIL trial records a closed-set `miss_class` of
`missing-owner` / `prose-fork` / `broken-ref` / `glossary-gap`. Doctor
gains seven new rows: `14W [INTENT-OWNER]`, `14X [MAXIM-OWNER]`,
`14Y [INTENT-RECOVERY]`, `14Z [CORE-REF-PROSE]`,
`15A [WORKFLOW-STATE-VOCAB]`, `15B [ADR-CLOSURE]`,
`15C [DEBT-CLOSURE]`; the legacy `[FORK]` and `[FIRST-DAY]` rows are
renumbered to `15D` and `15E` respectively to free the 14W/14X slots.

### Changed
- **`VERSION`** -> `2.43`.
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version` -> `2.43`.
- **NEW `skills/ssot-preflight/references/intent-ownership.md`**: apex-maxim → SSOT-owner mapping; repo-wide invariant single-owner rule; `[CORE-REF: <owner_path#anchor>]` syntax definition.
- **`skills/ssot-preflight/references/area-model.md`**: §2.0.1 apex invariants and CORE-REF prose ownership; §2.2 architecture domain README intent triad; §2.3 canonical-vocabulary hard list (workflow result codes, lifecycle states, agent-tier semantics, altitude vocabulary); §2.4 cite intent-ownership.md for apex-maxim DISC ownership; §2.8 ADR `closure_condition` + `revisit_signal` required for pending/partial/diverged; §2.11 tech-debt `closure_condition` + `revisit_signal` required for active entries.
- **`skills/ssot-preflight/references/architecture.md`**: §3 Domains apex-maxim and apex-invariant single-owner rule; §4 Owner Anchors apex-maxim row + apex-maxim indexing subsection.
- **`skills/ssot-preflight/references/knowledge-integrity.md`**: §1.1 intent-recovery axis; §4 binding rule that `intent_recovery: gap` blocks `covered` even when `confidence: verified`.
- **`skills/ssot-doctor/references/cold-agent-sim.md`**: §2 trial schema gains `pillar` + `miss_class` fields; §2.1 pillar assignment subsection; §3 grading rubric switches to per-pillar `≥ 5/8` floor + aggregate `≥ 24/32` gate; §3.1 closed-set `miss_class` taxonomy.
- **`skills/ssot-doctor/references/doctor.md`**: append rows `14W [INTENT-OWNER]`, `14X [MAXIM-OWNER]`, `14Y [INTENT-RECOVERY]`, `14Z [CORE-REF-PROSE]`, `15A [WORKFLOW-STATE-VOCAB]`, `15B [ADR-CLOSURE]`, `15C [DEBT-CLOSURE]`; renumber legacy `14W [FORK]` → `15D` and `14X [FIRST-DAY]` → `15E`; §3 hard-blocker bullets and §4 output-tag examples + tag-semantics list updated.
- **`skills/ssot-audit/references/current-upgrade.md`**: prepend the standalone v2.43 medium-impact upgrade entry.

### Cycle-2 deltas (in-place, no version bump)

- **`skills/ssot-doctor/references/doctor.md`**: row `14Z [CORE-REF-PROSE]` scope broadened to include `glossary/`, `decisions/` (excluding the establishing ADR), `tech-debt/`, `bugs/`, `gotchas/`, `release/`, `testing/` and gains a `Worked example — legal vs. illegal restatement` block; row `15A [WORKFLOW-STATE-VOCAB]` extended to require the apex-behavior-maxim umbrella term + numbered-rule→owner table when the consumer's root constraint file enumerates `*-MAXIM-N` / `*-RULE-N` rules; new row `15F [VOCAB-PROSE-FORK]` enforces the canonical-vocabulary single-prose-owner rule across non-glossary owners; §3 hard-blocker bullets and §4 output tags + tag-semantics list updated for both 15A scope and 15F.
- **`skills/ssot-preflight/references/area-model.md`**: §2.0.1 mirrors the broadened CORE-REF-PROSE location set, adds the legal-vs-illegal restatement worked example and the legal-vs-illegal glossary cell shape; §2.3 hard list gains the 5th category (apex behavior maxim term) and a single-prose-owner rule paragraph; new §2.3.1 ships the recommended `glossary/README.md` skeleton (Owner block + H2-per-category + 3-column table).
- **`skills/ssot-doctor/references/cold-agent-sim.md`**: §2.1 adds the 48-trial-per-cycle budget cap with priority-order skip rules; §3 cycle gate restated as ratio + absolute floor (`pillar_score ≥ 0.625`, absolute passing-cell count ≥ 4); §4 fail-row schema retires `missing_evidence_kind` and adds `(pillar, miss_class)` consecutive-cycle escalation; §5 Results template rewritten to per-cell rows + per-pillar / miss-class distribution; §5 cycle-gate line and §6 Termination drop the superseded flat-75% rule.
- **`skills/ssot-preflight/references/knowledge-integrity.md`**: §1.1 adds the multi-pillar rule for `intent_recovery: covered` (every declared pillar must PASS).
- **`skills/ssot-audit/references/current-upgrade.md`**: append cycle-2 deltas sub-section under the v2.43 entry.

### Cycle-3 deltas (in-place, no version bump)

- **`skills/ssot-preflight/references/intent-ownership.md`**: new §1.1 **Apex maxim registry (consumer side)** subsection — consumers must ship a single positive-existence registry table at `glossary/README.md` (preferred), `development/discipline.md` head matter, or `architecture/README.md` invariants section, with one row per apex maxim including `not_yet_owned` rows. Registry shape (Apex maxim | Slug | SSOT owner | Root-file link state) is the canonical 14X read anchor.
- **`skills/ssot-preflight/references/area-model.md`**: §2.0.1 gains a third **Illegal — `本域落地形态` / domain-form fork** worked example covering the wrapper pattern (`本域 contract 一句摘要` / `具体到本域的落地形态` / `domain-form restatement` / `本域如何承接`) that survived cycle-2 closure on backend-runtime line 91; mechanical-test paragraph now states explicitly that wrappers do not exempt trailing verb clauses. §2.3 hard list gains 6th category **Concurrency-control vocabulary** for named scheduling/concurrency identifiers used as nouns in apex docs (e.g. `workspace_path`, `project_limit`).
- **`skills/ssot-preflight/references/architecture.md`**: §4 Apex maxim indexing subsection now ends with a one-line cross-reference pointing 14X readers at `intent-ownership.md §1.1` for the consumer-side registry.
- **`skills/ssot-preflight/references/knowledge-integrity.md`**: §1.1 gains **Lag-deferral clause (v2.43.1)** allowing one cycle of deferral when `tracked_skill_version < 2.43`; multi-pillar `partial` rule extended to recognise `pillar-not-applicable-to-cycle` deferrals from the new §1.5 owner-pillar coverage matrix.
- **`skills/ssot-doctor/references/cold-agent-sim.md`**: §2.1 gains **Pillar-roundtrip enforcement** — harness embeds `pillar_assigned` in trial prompts and records `pillar-mismatch` for any mismatch (skill-fail when ≥10% of cycle trials drift). New §1.5 **Owner-pillar coverage requirement** computes the (owner, declared_pillar) coverage matrix before sample finalisation; new §1.6 **Canonical-vocab spot-check** adds 2 deterministic synthetic trials per cycle drawn from `glossary/README.md` plus apex-doc nouns absent from glossary, scored as a fifth `glossary_vocab` pillar with `2/2` floor as gate condition 7. §3 cycle-gate restated as ratio formulation `ceil(0.625·denom)` per pillar plus aggregate `total_score / sum(denom) ≥ 0.75`, dropping the conflicting `absolute passing-cell count ≥ 4` clauses. New §3.2 **Authoritative-owner check** downgrades any `verdict=PASS` whose resolved file would be flagged by `15D [FORK]` or `14Z [CORE-REF-PROSE]` to `verdict=FAIL` with `miss_class=prose-fork`. §3.1 miss-class table gains `pillar-mismatch` row and `prose-fork` Trial-signature column extended for §3.2. §6 termination conditions restated in ratio form and gain `glossary_vocab = 2/2` clause.
- **`skills/ssot-doctor/references/doctor.md`**: row `14X [MAXIM-OWNER]` body rewritten to enumerate the three firing cases (missing owner, missing/incomplete Apex maxim registry, non-owner body recopy) and explicitly disclaim root-constraint-file inline body as `[CORE-REF-PROSE]` (14Z) territory; example block expanded from one to three demarcated examples (registry missing, non-owner DISC body recopy, root-file no-owner registered). Row `14Y [INTENT-RECOVERY]` body rewritten to make demotion mandatory ("MUST be auto-demoted") rather than conditional ("If ... demote"), and explicitly cites the lag-deferral clause as the only legitimate exception (capped at one cycle); example refreshed.

## [2.38] - 2026-06

`semantic_impact: medium` - adds source-document lifecycle governance and the
Runtime Owner Map architecture IA. Root public Markdown and `docs/**/*.md` now
need lifecycle inventory, an in-file header, or an audited exclusion once a
consumer advances to v2.38. Working, historical, external, and public-thin docs
carry authority/downgrade fields so thick docs can exist without pretending to
be current SSOT. Product owns intent; architecture owns implementation
response. Architecture templates default to runtime owners rather than a
universal section checklist.

### Changed
- **`VERSION`** -> `2.38`.
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version` -> `2.38`; `semantic_impact: medium`.
- **`skills/ssot-preflight/references/source-material.md`**: adds lifecycle classes, downgrade fields, audited exclusions, and public-thin owner requirements.
- **`skills/ssot-preflight/references/area-model.md`** and **`architecture.md`**: sharpen product intent vs architecture implementation response, and define Runtime Owner Map as the default architecture IA.
- **`skills/ssot-closeout/references/{update-routing.md,inline-update-guide.md}`**: route systemic consumer docs/IA problems through SSOT-SKILL first and then consumer migration.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/{status.md,recon-report.md,bootstrap-session.md,architecture-readme.md,architecture-domain-readme.md}`**: add lifecycle inventory fields and replace checklist-heavy architecture templates with owner-map templates.
- **`skills/ssot-doctor/references/doctor.md`**, **`skills/ssot-doctor/assets/scripts/ssot-lint.sh`**, and **`run-tests.sh`**: add v2.38 source lifecycle checks and Runtime Owner Map drift heuristics.
- **`skills/ssot-audit/references/current-upgrade.md`** and **`archive/index.md`**: add the standalone v2.38 medium-impact upgrade entry.

## [2.37] - 2026-06

`semantic_impact: medium` - applies the v2.36 KISS principle to SSOT-SKILL's
own protocol surfaces. STATUS and closeout routing now lead with prose decision
paths and keep wide tables as appendices; bootstrap STATUS/manifest/recon
templates default to thin registers; architecture protocol requires a mental
model, owner boundary, and evidence direction before optional matrices; protocol
upgrade history is split into a small router, `current-upgrade.md`, and archive
range files so ordinary audits no longer load the whole historical ledger.

### Changed
- **`VERSION`** -> `2.37`.
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version` -> `2.37`; `semantic_impact: medium`.
- **`skills/ssot-preflight/references/status-protocol.md`**: rewritten around five STATUS registers and a STATUS decision path; table schemas and detailed product/architecture coverage rules moved to appendices.
- **`skills/ssot-closeout/references/update-routing.md`**: rewritten around five routing questions, frequent routes, and targeted cascade checks; full mapping tables moved to appendices.
- **`skills/ssot-preflight/references/architecture.md`**: reframed architecture as mental model + owner boundary + evidence direction; domain/diagram/appendix requirements now trigger from real complexity instead of empty mandatory sections.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/{status.md,bootstrap-manifest.md,recon-report.md}`**: thinner default registers and optional appendix blocks for wide details.
- **`skills/ssot-audit/references/protocol-upgrades.md`**, **`current-upgrade.md`**, and **`archive/`**: protocol upgrade ledger split into router/current/archive layers; previously CHANGELOG-only v2.20 and v2.25-v2.31 coverage is explicit in the archive.
- **`tests/test-bundle-shape.sh`** and **`tests/test-installer-e2e.sh`**: assert the new audit ledger shape and installed archive/current files.

## [2.36] - 2026-06

`semantic_impact: medium` - makes KISS the permanent SSOT design principle.
SSOT owners must give the mental model in prose and use tables only for
routing, comparison, state registers, or evidence lookup. `STATUS.md`,
bootstrap manifests, promotion metadata, and protocol ledgers remain allowed
registers, but their cells must stay pointer-sized; paragraph reasoning,
command output, copied checklists, and proof-of-work transcripts move to the
authoritative owner or evidence artifact. Doctor gains semantic tag `[KISS]`;
`ssot-lint.sh` adds a WARN-only `[KISS-TABLE-DENSITY]` heuristic; STATUS and
architecture-domain templates now make the register/prose boundary explicit.

### Changed
- **`VERSION`** -> `2.36`.
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version` -> `2.36`; `semantic_impact: medium`.
- **`AGENTS.md`**: declares KISS as the permanent SSOT design principle and extends readability discipline to register-only cells.
- **`skills/SKILL_STYLE.md`**: adds a KISS bridge so references/templates cannot reverse-incentivize table-first documents.
- **`skills/ssot-bootstrap/references/bootstrap.md`** and **`skills/ssot-preflight/references/area-model.md`**: add the KISS rule and register-only row budget.
- **`skills/ssot-preflight/references/status-protocol.md`**, **`skills/ssot-closeout/references/inline-update-guide.md`**, and **`promotion-rationale.md`**: make STATUS and PLTL metadata pointer-sized registers.
- **`skills/ssot-doctor/references/doctor.md`**: adds `[KISS]` / `[KISS-TABLE-DENSITY]` review language.
- **`skills/ssot-doctor/assets/scripts/ssot-lint.sh`** and **`run-tests.sh`**: add WARN-only table-density smoke coverage.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/status.md`**: adds register-only KISS notes for STATUS rows, stop-review evidence, and CAP rows.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/architecture-domain-readme.md`**: adds prose-first placeholders to table-heavy sections and fixes optional-block wording that conflicted with deleting unused blocks.
- **`skills/ssot-audit/references/protocol-upgrades.md`**: adds the standalone v2.36 medium-impact review entry.

## [2.35] - 2026-06

`semantic_impact: medium` - adds an agent-actionability layer on top of the existing cold-reader readability and owner-boundary rules. SSOT entries must help a future agent decide what to do next: why to read the entry, what current truth it owns, where to inspect first, what not to do, and what minimal verification/evidence closes the loop. High-risk `bugs/` and `tech-debt/` entries gain an "agent quick entry" expectation. `STATUS.md` stop-review fields must stay pointers and conclusions, not full batch transcripts. Doctor gains semantic tag `[ACTIONABILITY]`; `ssot-lint.sh` adds WARN-only heuristics for overlong lines, stop-review ledger bloat, and missing quick-entry surfaces on numbered bug/debt entries.

### Changed
- **`VERSION`** -> `2.35`.
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version` -> `2.35`; `semantic_impact: medium`.
- **`skills/ssot-preflight/references/area-model.md`**: adds the agent-actionability posture and explicit quick-entry expectations for `bugs/` and `tech-debt/`.
- **`skills/ssot-closeout/references/update-routing.md`** and **`inline-update-guide.md`**: route SSOT-quality / protocol-gap signals through "fix the protocol first when the repository owns it, then repair local SSOT" and require actionability checks before writing.
- **`skills/ssot-doctor/references/doctor.md`**: adds `[ACTIONABILITY]`, `[ENTRY-ACTIONABILITY]`, `[STATUS-STOP-REVIEW-LEDGER]`, and `[READABILITY-LONG-LINE]` review language.
- **`skills/ssot-doctor/assets/scripts/ssot-lint.sh`**: adds WARN-only deterministic heuristics for the new tags.
- **`skills/ssot-doctor/assets/scripts/test/run-tests.sh`**: adds smoke scenarios for the new WARN checks.
- **`skills/ssot-audit/references/protocol-upgrades.md`**: adds the standalone v2.35 medium-impact review entry.

## [2.34] - 2026-06

`semantic_impact: medium` — generalizes the v2.33 testing-ledger boundary into a broader owner/index/ledger boundary. `STATUS.md` Notes are now project-level coverage pointers, not child-entry status, recent validation, or run-history ledgers. README/index/Reader Map files may route readers and expose protocol-authorized minimal index fields, but must not mirror child body facts, generated counts, latest activity, or non-authoritative lifecycle state. Doctor gains semantic tags `STATUS-NOTES-LEDGER`, `INDEX-DERIVED-STATE`, and `SHADOW-LEDGER`; `ssot-lint.sh` adds WARN-only heuristics for these patterns so projects see owner-boundary drift without hard-failing normal maintenance.

### Changed
- **`VERSION`** -> `2.34`.
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version` -> `2.34`; `semantic_impact: medium`.
- **`skills/ssot-preflight/references/status-protocol.md`**: expands Notes-column guidance into `STATUS-NOTES-LEDGER`, covering derived child state, latest validation, and run-history bloat.
- **`skills/ssot-preflight/references/area-model.md`**: adds general README/index and non-owner shadow-ledger boundaries.
- **`skills/ssot-doctor/references/doctor.md`**: adds Doctor checks/tags and coverage hard blockers for STATUS notes ledgers, index-derived state, and shadow ledgers.
- **`skills/ssot-doctor/assets/scripts/ssot-lint.sh`**: adds WARN-only deterministic heuristics for the three new tags.
- **`skills/ssot-doctor/assets/scripts/test/run-tests.sh`**: adds smoke scenarios for the new WARN checks.
- **`skills/ssot-audit/references/protocol-upgrades.md`**: adds the standalone v2.34 medium-impact review entry.

## [2.33] - 2026-06

`semantic_impact: medium` — clarifies the boundary between stable testing facts and verification run evidence. `testing/` now owns test strategy, selection matrix, quality gates, fixtures/test data, current baselines, known gaps, and defensive-test mappings; it must not become a chronological validation ledger. Closeout and audit now explicitly treat command pass/fail output as evidence for the final answer, commit/release notes, bug entries, or stop-review evidence unless that output changes durable testing policy. Doctor gains semantic check/tag `TESTING-LEDGER`; bootstrap testing templates now include Test Selection Matrix, Quality Gates, Current Baseline, and a "not a verification ledger" guard. Existing projects: audit `testing/` and split/remove recent-run tables or command transcripts, keeping only current baseline/gap/map facts with evidence pointers.

### Changed
- **`VERSION`** -> `2.33`.
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version` -> `2.33`; `semantic_impact: medium`.
- **`skills/ssot-preflight/references/status-protocol.md`**: defines `semantic_impact=medium` as self-reviewed but standalone in the protocol upgrade ledger.
- **`skills/ssot-audit/references/protocol-upgrades.md`**: adds v2.33 testing-ledger review guidance and backfills the v2.32 identity-removal review entry under the new medium-impact rule.
- **`skills/ssot-audit/SKILL.md`**: aligns waterline advancement review wording with `status-protocol.md §7.1` so medium-impact protocol upgrades can be self-reviewed with a checklist while high-impact exceptions still route to `$ssot-doctor`.
- **`skills/ssot-closeout/SKILL.md`** and **`skills/ssot-closeout/references/inline-update-guide.md`**: align closeout waterline wording with the same §7.1 review split.
- **`skills/ssot-preflight/references/area-model.md`** `testing/`: defines the stable owner set and forbids batch-by-batch command transcripts, dates, green/red summaries, and recent validation rows unless they change a durable testing fact.
- **`skills/ssot-closeout/SKILL.md`**: states that test command output is evidence, not automatically a `testing/` fact.
- **`skills/ssot-closeout/references/update-routing.md`** and **`skills/ssot-audit/references/{commit-audit,conversation-audit}.md`**: require agents to ask whether a test change/result changes future test selection before updating `testing/`.
- **`skills/ssot-doctor/references/doctor.md`**: adds semantic check/tag `TESTING-LEDGER` and includes testing-ledger bloat in coverage hard blockers.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/testing-readme.md`**: adds Test Selection Matrix, Quality Gates, Current Baseline, and a verification-ledger exclusion section.

## [2.32] - 2026-06

`semantic_impact: medium` — removes `identity/` as a top-level SSOT area. The four facts it carried are absorbed by existing owners that already held the same content: the one-sentence repository positioning moves to the opening line of `SSOT/README.md` (right after the writing-style note); tech stack, runtime form and repository type fold into `architecture/README.md` as part of the design brief; primary capabilities stay where they already lived, in `product/prd.md`'s capability map. Rationale: identity duplicated content already owned by `product/`, `architecture/` and the SSOT root entry — three places to keep in sync for one fact each, the exact anti-pattern the protocol bans elsewhere. The remaining unique role (a short, citable cover-sheet for thin adapters) is served better by the README opening line, which the adapter template already wants as its first source. Doctor `14I` and the readability hard blocker drop `identity/` from their scope lists; thin-adapter `SSOT-source` switches from `identity/README.md` to `README.md`; the `<identity-one-liner>` placeholder renames to `<repo-positioning-one-liner>`. Status/manifest/recon templates drop the identity row. Existing projects: identity content is already either in or one paragraph from its new home; the audit pass needs only to lift the positioning line into `SSOT/README.md`, confirm `architecture/README.md` covers tech stack/repository type, and delete `SSOT/identity/`.

### Changed
- **`VERSION`** → `2.32`.
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version` → `2.32`; `semantic_impact: medium`.
- **`skills/ssot-preflight/references/area-model.md`**: deletes §2.3 `identity/`; renumbers §2.4–§2.12 → §2.3–§2.11; removes `identity/` from the structural-model tree, "Context areas" line, and §5 always-applicable list; adds a paragraph after the product-required paragraph requiring `SSOT/README.md` to open with a one-sentence repository positioning and stating where tech stack / repository type / primary capabilities live; updates the `architecture/README.md` tree comment to note the design brief carries tech stack and repository type; updates two `(see §2.5)` internal cross-references to `(see §2.4)`.
- **`skills/ssot-bootstrap/references/bootstrap.md`**: replaces the Tier 1 `identity` row with an `SSOT/README.md` row noting the one-sentence positioning opening line; removes the `identity` row from the evidence-source map; drops `identity/` from §3.7 scope; updates the S/M sharding example to drop `identity`; expands the Phase 1 Output #2 description to require `SSOT/README.md` to open with the one-sentence positioning.
- **`skills/ssot-preflight/references/status-protocol.md`** §3 coverage state table: drops the `identity` row.
- **`skills/ssot-doctor/references/adapter-strategy.md`** §2: `Project identity` source changes from `SSOT/identity/` to "the opening line of `SSOT/README.md`".
- **`skills/ssot-doctor/references/doctor.md`**: drops `identity/` from `14I` scope and from the hard-blocker scope.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/adapter-thin.md`**: `SSOT-source` first source changes from `SSOT/identity/README.md` to `SSOT/README.md`; `<identity-one-liner>` placeholder renames to `<repo-positioning-one-liner>`.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/ssot-readme.md`**: adds a `## What this repo is` / `## 仓库定位` section with the one-sentence positioning placeholder and a one-line pointer to `architecture/README.md` (tech stack/runtime/type) and `product/prd.md` (capabilities); drops the `Repository identity` / `仓库身份` row from the Area Index.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/status.md`**: drops the `identity` row from the Area Status table.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/bootstrap-manifest.md`**: drops the `identity` row from both the Assignment and Workflow tables; the Tier-order footnote drops `identity` from Tier 1.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/recon-report.md`**: source-material example row example areas list drops `identity`.
- **`AGENTS.md`** writing-style scope sentence drops `identity/`.

## [2.31] - 2026-06

`semantic_impact: medium` — extends `decisions/` entries with required lifecycle fields (`created_on`, `updated_on`, `introduced_in`, `updated_in`) so ADRs carry their own temporal and git anchors; adds bilingual `decision-entry.md` and `decisions-readme.md` bootstrap templates for single-decision files and the decisions area index; adds doctor check `11` (check 21 reference) to validate frontmatter completeness on all `decisions/NNNN-<slug>.md` entries, exempting bootstrap-archaeology archives; updates bootstrap archive phase to apply the new `decision-entry.md` template for `0000-bootstrap-recon.md`.

### Added
- **`skills/ssot-preflight/references/area-model.md`** §2.9 `decisions/`: `created_on`, `updated_on`, `introduced_in`, `updated_in` fields. Explains each field's purpose — date anchor for temporal context, commit anchor for git provenance. Historic/imported ADR carveout (`introduced_in` = the commit that brought the file into `SSOT/04-records/decisions/`; `created_on` falls back to import date).
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/decision-entry.md`** — new single-decision template. YAML frontmatter with all lifecycle fields plus body sections: Background, Decision (with options-considered table), Consequences, Scope of Impact.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/decisions-readme.md`** — new decisions area index template. Table with ID, Title, Status, Implementation state, Date, Owner / reviewer columns.
- **`skills/ssot-doctor/assets/scripts/ssot-lint.sh`** check 11: scans `decisions/NNNN-<slug>.md` for required frontmatter fields (`status`, `implementation_state`, `created_on`, `introduced_in`); exempts `bootstrap-archaeology` type entries.
- **`skills/ssot-doctor/references/doctor.md`** L1 check 21 row documenting the new doctor check.
- **`skills/ssot-doctor/assets/scripts/test/run-tests.sh`** S11, S12, S13: decision missing-field FAIL, complete decision PASS, bootstrap-archaeology exemption.

### Changed
- **`VERSION`** → `2.31`.
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version` → `2.31`.

## [2.30] - 2026-06

`semantic_impact: medium` — extends the cold-reader readability floor SSOT-wide, and replaces v2.29's five-rule blockquote-on-every-template scaffolding with one posture sentence + three guardrails + a one-line pointer per template. The scope is now every SSOT area the bundle generates (`product/`, `architecture/` root/views/domains, `development/`, `testing/`, `release/`, deployment, `decisions/`, `gotchas/`, `bugs/`, `tech-debt/`, `identity/`, `glossary/`, root `SSOT/README.md`) except infra files (`STATUS.md`, `.bootstrap/`, thin adapters). Single posture sentence: "Every section is first written for the stranger who lands tonight knowing nothing; tables, codes and tags they cannot read are not paragraphs." Three guardrails: prose before tables; define every term positively on first use; a cell is not a paragraph. v2.29's per-template multi-sentence `[MUST]` blockquotes are intentionally retired in favour of a single-line pointer — this is a deliberate course-correction, not a regression. The manual-style blockquote anti-pattern was teaching the model what its defaults already know once the posture loads; the pointer is the activator, not the rule. Doctor `14I` globalizes (renamed `Product readability` → `SSOT readability`); the `[PRODUCT-READABILITY]` tag merges into `[READABILITY]`; the product-specific hard blocker collapses into one general readability blocker.

### Changed
- **`skills/ssot-bootstrap/references/bootstrap.md`** §3.7 retitled `Product docs must be readable cold` → `SSOT docs must be readable cold`; opening prose replaced with scope sentence + posture sentence + "trust your defaults on everything else"; five rules collapse to three guardrails; closing "shared readability floor for product/ + architecture/views/" paragraph removed (subsumed by the new scope sentence).
- **`skills/ssot-doctor/references/doctor.md`** `14I` row renamed `Product readability (v2.29)` → `SSOT readability (v2.30)`; question column rewritten as three short checks aligned with the three guardrails, applied to every user-facing SSOT body file. Hard-blocker list: the v2.29 product-specific readability bullet becomes one general bullet covering all user-facing SSOT body files; the standalone scene-anchor blocker is removed (subsumed by the posture). `[PRODUCT-READABILITY]` tag retired; its semantics merged into `[READABILITY]`.
- **`skills/ssot-preflight/references/area-model.md`** new §2.0 prelude before `## 2. Area responsibilities` content: quotes the posture, names the three guardrails by phrase, links to `ssot-bootstrap` §3.7. §2.1 `product/` Writing-style block pruned to one line referencing §2.0. No per-area Writing-style subsections added elsewhere — the §2.0 prelude is enough.
- **`AGENTS.md`** `## Writing Style (Global)` shrunk to three sentences: posture, scope, pointer. Defensive prose ("long-running self-check phase", "immediate target is product and architecture", "tighten as needed, loosen only when …") removed.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/product-readme.md`**, **`product-prd.md`**, **`product-model.md`**, **`product-roadmap-and-acceptance.md`**, **`product-capabilities-readme.md`**, **`product-journeys-readme.md`**, **`product-capability-entry.md`**, **`product-journey-entry.md`** — the v2.29 multi-sentence cold-reader blockquote and the v2.29 in-body `[MUST]` explanatory paragraphs (e.g. product-prd.md's "Do not satisfy this section by rearranging …" paragraph) are removed; replaced by the single-line pointer `> Writing style: any cold reader. See \`ssot-bootstrap\` §3.7.` (zh: `> 行文风格：写给任何冷读者。详见 \`ssot-bootstrap\` §3.7。`) immediately under the title.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/architecture-readme.md`**, **`architecture-views-readme.md`**, **`architecture-view-operating-model.md`**, **`architecture-view-critical-journeys.md`**, **`architecture-view-current-target-gap.md`**, **`development-readme.md`**, **`testing-readme.md`**, **`release-readme.md`**, **`ssot-readme.md`** — same one-line pointer added immediately under the title.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/architecture-domain-readme.md`** — same one-line pointer added under the title; the existing Readable Authority intro paragraph is preserved.
- **`VERSION`** → `2.30`.
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version` → `2.30`.

## [2.29] - 2026-06

`semantic_impact: medium` — introduces a cold-reader readability floor for `product/`. The primary reader of SSOT is still the next agent; the framing matters because what is unreadable to a person who does not know the system is also unreadable to an agent that does not — plain language, prose before tables, positive term definitions and concrete scenes are the conditions under which any cold reader (agent or human) can attach meaning to the identifiers, references and constraints. Five product spine / capability / journey templates now require an opening prose section ([MUST]) before any table, plus a concrete usage scene; `ssot-bootstrap` §3.7 documents the rules; Doctor gains check `14I Product readability`, a new hard blocker covering the same surface, and the `[PRODUCT-READABILITY]` tag. `14B` Readable Authority extends from `root/view/domain` to `root/view/domain/product`. `area-model.md` §2.1 absorbs the rules so preflight readers see the constraint too. Top-level `AGENTS.md` gains a `Writing Style (Global)` posture for the long-running readability self-check phase.

### Added
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/product-prd.md`** — `## What this product is [MUST]` and `## What this phase ships, and what it does not [MUST]` opening prose sections; non-goals must explain why-not and revisit conditions.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/product-model.md`** — `## Users and the world they live in [MUST]` and `## What we promise and what we do not [MUST]` opening prose sections; positive-first term definitions required.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/product-roadmap-and-acceptance.md`** — `## The story from this phase to the next [MUST]` and `## What acceptance means here [MUST]` opening prose sections.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/product-capability-entry.md`** — `## Tell this capability in one breath [MUST]` three-layer structure (one-sentence summary / concrete scene / why independent owner) replaces the weaker "1-3 paragraphs" hint.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/product-journey-entry.md`** — `## A real user from A to B [MUST]` walks the journey as a real user experiences it; `## Why this journey is separate [MUST]` names each split reason explicitly.
- **`skills/ssot-bootstrap/references/bootstrap.md`** new `### 3.7 Product docs are written for humans` with the five rules (prose-before-tables, plain language, cell-is-not-paragraph, prefer-one-extra-sentence, always-anchor-on-a-concrete-scene). Shared readability floor for `product/` and `architecture/views/`.
- **`skills/ssot-doctor/references/doctor.md`** new L2 check `14I Product readability`; new hard-blocker bullet for product readability; new `[PRODUCT-READABILITY]` output tag with semantics.
- **`AGENTS.md`** new `## Writing Style (Global)` section: declares the long-running readability self-check posture for any template/protocol/Doctor change.

### Changed
- **`skills/ssot-preflight/references/area-model.md`** §2.1 `product/` adds a `**Writing style**:` subsection summarizing the five rules and pointing to `ssot-bootstrap` §3.7 so preflight readers see the constraint.
- **`skills/ssot-doctor/references/doctor.md`** `14B` Readable Authority extends scope from `root/view/domain body` to `root/view/domain/product body` — single readability authority across `architecture/` and `product/`.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/product-readme.md`**, **`product-capabilities-readme.md`**, **`product-journeys-readme.md`** — added the helper line "this file only routes the reader; the body (written for humans in plain language) lives in the linked owner files", with a pointer to `ssot-bootstrap` §3.7.

## [2.28] - 2026-06

`semantic_impact: low` — introduces PLTL v3, the Promotable Long-Term Lessons mechanism. Collapses prior rank distinctions into three altitudes (Apex / Authority / Inbox) and replaces threshold-based promotion with explicit agent judgement fed by two evidence streams (repo + conversation reality; user interactive directives). Promotion or demotion across any altitude is a single move; `$ssot-doctor` stop-review is required only on moves that touch apex. No lint check, no new STATUS field, no new top-level SSOT area, no new Doctor label. Per v2.22 §8.1, low-impact entries are not promoted to a standalone `protocol-upgrades.md` section; this CHANGELOG entry is the only version-level record (the new `## Bundle Captures` section in `protocol-upgrades.md` is the inbox surface, not a version entry).

### Added
- **`skills/ssot-closeout/references/promotion-rationale.md`** (new): semantic owner of PLTL v3. Defines the three altitudes, the two evidence streams, the five self-check questions, the `rule` / `move` / `CAP-` schemas, the doctor stop-review trigger, the migration rule for pre-v2.28 rules, and worked promote/demote examples.
- **`skills/ssot-preflight/SKILL.md`** `## Park user-directive signals`: capture-side hook letting preflight park a `CAP-` row in `STATUS.md ## Pending Captures` with `signal_source: user-directive` when the user's prompt names a constraint. Preflight does not promote — it files the signal for closeout or audit to act on.
- **`skills/ssot-closeout/SKILL.md`** `## Distill & promote`: small-window two-stream scan over rules touched or cited in the current batch; emits zero or more `move` blocks. Apex moves are routed to `$ssot-doctor` stop-review; non-apex moves land directly.
- **`skills/ssot-audit/SKILL.md`** `## Scan the wide window`: large-window two-stream scan where cross-batch concentration and apex/authority drift become visible. New drift-signal row in `## Load on demand` routes bundle-side inbox lookups to `references/protocol-upgrades.md ## Bundle Captures`.
- **`skills/ssot-doctor/SKILL.md`** `## Reviewing promotion rationale`: stop-review posture for `move` blocks. Doctor never writes content; it confirms `stream_a` and `stream_b` anchors resolve and actually support the direction of the move, returning `no-more-required-changes` or `needs-fix` per the existing verdict schema.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/status.md`** `## Pending Captures` (zh: `## 待捕获项`): inbox section with the `CAP-` row schema and a single `>` footnote routing to `$ssot-closeout references/promotion-rationale.md` for enum definitions.
- **`skills/ssot-audit/references/protocol-upgrades.md`** `## Bundle Captures`: bundle-side inbox mirror. The bundle does not dogfood; consumer-staged `deferred-export` rows are relayed here during the audit protocol-upgrades cadence.
- **`AGENTS.md`** top-of-file blockquote: `> AGENTS.md should fit in the reader's working memory; if a section grows past comfortable reading, consolidate or demote before adding.` Sits above `## What This Repo Is` so every reader hits it before any section grows.

### Changed
- **`skills/ssot-preflight/SKILL.md`** `metadata.protocol_version`: `2.27` → `2.28`.
- **`VERSION`**: `2.27` → `2.28` (physical mirror enforced by `tests/test-bundle-shape.sh`).

### Not required
- No change to `ssot-lint.sh`. PLTL v3 is enforced by skill discipline plus doctor stop-review on apex moves; there is no lint-time check for altitude transitions, evidence anchors, or `move` block schema.
- No change to `skills/ssot-bootstrap/`. Bootstrap continues to instantiate the existing template set; the new `## Pending Captures` section is the only template-side change and it lives under `assets/templates/`, not in the bootstrap workflow.
- No new top-level SSOT area, owner field, STATUS field, JSON/YAML state file, or Doctor label.

## [2.27] - 2026-06

`semantic_impact: low` — third pass of `assets/templates/` ceremony reduction: condition-marker convention for legacy-mode and optional sections, plus wide-table splits. No new SSOT area, owner field, STATUS field, or stop-review trigger.

### Changed
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/architecture-readme.md`**: wrapped the five legacy-only sections (`Design Brief`, `System Principles / Operating Model`, `Primary User / Operating Journeys`, `Core Invariants`, `Current / Target / Gap Summary`) in three separate `<!-- LEGACY-ONLY-START / END -->` blocks. The three blocks split around the two always-required Reader Map / View Index / Domain Index sections so deleting the legacy blocks in views+domains mode leaves the views-mode spine intact. The intro blockquote was rewritten to make views+domains the explicit default and to document the three-block convention. Per `references/architecture.md` §2.1.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/architecture-domain-readme.md`**: wrapped six conditional sections (`### External Diagram Candidates`, `### Conditional Current Diagrams`, `### Target Diagrams`, `## Configuration / Variability Model`, `## Lifecycle / Concurrency / Scheduling Model`, `## Evolution / Migration Ledger`) in independent `<!-- OPTIONAL-START / END -->` blocks. Each marker carries a specific trigger condition and an explicit instruction: delete the entire block when not applicable; do not leave it as `not_applicable` boilerplate. Required sections (Boundary, Design Intent, Design Constraints, decomposition_basis, Runtime Flows, State/Data/Resources, Cross-Boundary Contracts, Invariants and Constraints, Failure and Recovery, Verification, Current/Target/Gap, Diagram Index, and the three current-mode Mermaid blocks) stay unwrapped. Per SKILL_STYLE.md anti-pattern "Filling empty-shell documents".
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/status.md`** `## Core Reference Document Review`: split the 10-column table into two narrower joined tables (`### Facts` with 5 columns and `### Review` with 6 columns, sharing the `Document` key column). The intro blockquote explicitly cites `status-protocol.md` §4.1 as still treating them as one logical 10-field ledger; the split is a rendering choice only.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/bootstrap-manifest.md`** `## Area Status`: split the 9-column table into `### Assignment` (Area | Status | Assignment | Confidence) and `### Workflow` (Area | Covered scope | Remaining scope | Stop reviewer | Stop result | Remaining changes) tables. All 12 areas appear in identical order in both. Trailing prose notes (status enum, Tier ordering, etc.) preserved.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/bootstrap-session.md`** `## Architecture Diagram Handling`: split the 7-column table into `### Diagram Index` (Diagram ID | Architecture path | Status | Coverage) and `### Diagram Trace` (Diagram ID | Evidence | Linked table rows | Outcome) tables.

### Not required
- No new SSOT top-level area, STATUS field, JSON/YAML state file, schema, command, skill, Doctor label, or `ssot-lint.sh` check.
- No new requirement on consumer projects. `tracked_skill_version` may advance to `2.27` as a no-op; previously-instantiated SSOT files continue to function — the new markers and table splits only affect future template instantiations.

## [2.26] - 2026-06

`semantic_impact: low` — second pass of `assets/templates/` ceremony reduction. No new SSOT area, owner field, STATUS field, or stop-review trigger. Per v2.22 §8.1, low-impact entries are not promoted to a standalone `protocol-upgrades.md` section; this CHANGELOG entry is the only record.

### Changed
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/status.md`**: collapsed seven dense inline blockquote paragraphs (~150 words each) into nine one-line pointers into `$ssot-preflight references/status-protocol.md` (§2.1 / §7.1 / §3.1 / §3 / §3.0 / §4 / §4.1 / §7 / §5.1 / §6). The blockquotes had been duplicating protocol prose owned by `status-protocol.md`; per `SKILL_STYLE.md` the body should name *when to load* the reference, not what it contains. Column headers and intra-cell enum hints are preserved.
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/bootstrap-manifest.md`**: added an explicit orthogonality blockquote between the existing Write rule and the Repository Overview section, stating that manifest tracks the *work-progress* axis (`pending` / `active` / `done` / `blocked`) while `STATUS.md` tracks the *content-quality* axis (`covered` / `gap` / `stale` / `unknown` / `not_applicable` / `conflict`), and that Phase 4 cleanup must set each area's final STATUS from its own stop-review evidence rather than auto-mapping manifest `done` to STATUS `covered`. The two common mappings (manifest `done` + scope-empty → STATUS `not_applicable`; manifest `done` + stop-review-passed + content-complete → STATUS `covered`) are spelled out inline. This was implicit in `status-protocol.md` §1 but absent from the template.
- **Reader Map column schema unified across 8 templates** (en+zh): `ssot-readme.md`, `architecture-readme.md`, `architecture-views-readme.md`, `architecture-domain-readme.md`, `product-readme.md` (already canonical, untouched), `development-readme.md`, `testing-readme.md`, `release-readme.md`. Canonical 5 columns: `Reader question | First stop | Authoritative owner | Evidence direction | Stop condition / risk`. Where the original used 6 columns (architecture-readme split Stop condition vs Risk; architecture-domain had separate Subtopic / One-line answer / Authoritative location / Evidence links / Why-or-risk columns) the data was merged or reshaped preserving row intent; the `One-line answer` and `Subtopic` columns were dropped per SKILL_STYLE (Reader Map rows route, they don't carry independent answers). In `ssot-readme.md` the legacy `Core` / `Reference` prioritization signal was folded into `Stop condition / risk` as the leading hint.

### Not required
- No new SSOT top-level area, STATUS field, JSON/YAML state file, schema, command, skill, Doctor label, or `ssot-lint.sh` check.
- No new requirement on consumer projects. `tracked_skill_version` may advance to `2.26` as a no-op; previously-instantiated STATUS.md files in consumer SSOTs continue to function — the removed blockquotes were always redundant restatements of `status-protocol.md`.

## [2.25] - 2026-06

`semantic_impact: low` — first pass of `assets/templates/` ceremony reduction. No new SSOT area, owner field, STATUS field, or stop-review trigger. Per v2.22 §8.1, low-impact entries are not promoted to a standalone `protocol-upgrades.md` section; this CHANGELOG entry is the only record.

### Changed
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/*.md`**: removed 40 redundant "Template instantiation note" HTML comments (20 EN + 20 ZH) that duplicated the same language-discipline rule on every template. The rule is now owned by a single new subsection in `references/bootstrap.md` (see Added).
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/adapter-thin.md`**: new merged adapter template. Replaces the two near-identical `adapter-agents-md.md` and `adapter-claude-md.md` files (the difference was a single `## Key Reminders` section). The new template wraps `Key Reminders` with an `<!-- OPTIONAL: keep when ... drop for ... -->` marker so a single template covers both AGENTS.md (drop the section) and CLAUDE.md / GEMINI.md (keep it) targets. Placeholders also normalized from `{PROJECT_NAME}` / `{INVARIANT_1}` / `{DATE}` style to the bundle-standard `<project-name>` / `<invariant-1>` / `<date>` form, eliminating the only remaining `{FOO}`-style placeholders in the bundle.
- **`skills/ssot-bootstrap/assets/templates/en/bootstrap-manifest.md`**: added missing `| Tier 0 | | | pending | | |` row in the Convergence Checks table (the ZH counterpart already had it; this restores en/zh structural parity).
- **`skills/ssot-bootstrap/references/bootstrap.md`**: rewrote item 9 of Phase 1 Outputs to point at the new single `adapter-thin.md` and explain the optional `Key Reminders` toggle.

### Added
- **`skills/ssot-bootstrap/references/bootstrap.md` §2 → "Language discipline when instantiating templates"**: new subsection owning the language-translation rule that was previously duplicated 40 times in templates. Covers both rendered SSOT files and bootstrap-only files (`recon.md`, `manifest.md`, session logs) before they are archived or deleted at Phase 4.
- **`skills/ssot-bootstrap/references/templates-index.md`**: maintainer index of all 23 templates under `assets/templates/{en,zh}/`, with columns `Template / Purpose / Default destination / Section in bootstrap.md`. Adds a single place to update when templates are added or removed, removing the requirement to hand-edit each path reference in `bootstrap.md`.

### Removed
- **`skills/ssot-bootstrap/assets/templates/{en,zh}/adapter-agents-md.md`** and **`adapter-claude-md.md`** (4 files total): replaced by the single `adapter-thin.md` (see Changed).

### Not required
- No new SSOT top-level area, STATUS field, JSON/YAML state file, schema, command, skill, Doctor label, or `ssot-lint.sh` check.
- No new requirement on consumer projects. `tracked_skill_version` may advance to `2.25` as a no-op; templates that have already been instantiated into a consumer's `SSOT/` are not affected (the removed comments are merely no longer added to *new* instantiations).

## [2.24] - 2026-06

`semantic_impact: low` — second pass of `SKILL.md` body distillation against `SKILL_STYLE.md`; no new area, owner field, or stop-review trigger. Per v2.22 §8.1, low-impact entries are not promoted to a standalone `protocol-upgrades.md` section; this CHANGELOG entry plus the collapsed bullet under v2.22 are the only record.

### Changed
- **`skills/ssot-bootstrap/SKILL.md`**: body distilled from 19 lines / ~140 words to 22 lines / ~150 words (line count unchanged, register replaced). Removed "Use this skill only…" description echo and "protocol version is owned by `$ssot-preflight`" lifecycle restatement. Replaced the 6-step workflow with a second-person posture ("you are creating a repository's first authoritative SSOT…") that reframes bootstrap as evidence absorption rather than template-filling, an explicit `assets/templates/` anti-pattern guardrail, an outcome-conditioned self-certification ban, and a 4-row Load-on-demand table.
- **`skills/ssot-closeout/SKILL.md`**: body distilled from 22 lines / ~280 words to 25 lines / ~210 words. Removed description echoes and the 9-step workflow. Replaced with a "reconcile what just happened against `SSOT/`" posture sentence (covering diff / tests / user confirmations / preflight deltas — not just file changes), a folded no-op clause, an explicit "do not invoke full `$ssot-doctor` here" guardrail, and an outcome-conditioned ban on self-certifying waterline / `covered/converged` / language-lock / bootstrap `passed`.
- **`skills/ssot-audit/SKILL.md`**: body distilled from 27 lines / ~250 words to 19 lines / ~160 words. Removed description echoes, the duplicate "Route" vs "Rules" structure, and the lifecycle restatement. Replaced with a "you have been routed here, not to do new work" posture sentence, an explicit "segment large diffs and long transcripts" anti-pattern (the failure mode this skill exists to prevent), an outcome-conditioned self-certification ban on `tracked_commit / tracked_session / tracked_skill_version`, and a 5-row Load-on-demand table that doubles as the drift-signal router.
- **`skills/ssot-doctor/SKILL.md`**: body distilled from 23 lines / ~220 words to 22 lines / ~190 words. Removed description echoes and the 5-step workflow. Replaced with a "you are the independent check on SSOT credibility" posture sentence (also reframing doctor as *not* an editor and *not* an audit catch-up), an explicit "run `ssot-lint.sh` before subjective review" guardrail, the stop-reviewer signature scope as the only signature that may advance a waterline / claim `converged` / set bootstrap `passed` / change a language lock, and an outcome-conditioned return rule (`no-more-required-changes` only when reviewed scope has zero remaining required fixes; otherwise `needs-fix` with concrete items — never a soft "looks fine"). Removed the `assets/scripts/test/run-tests.sh` line from the load table (maintainer-only, not loaded during a doctor pass).

### Engineering bucket (no protocol bump on its own)
- **`.github/workflows/ci.yml`**: `shellcheck` invocation upgraded from `-e SC2034` to `-S warning -e SC2034` so `shellcheck 0.9`'s elevated `SC2016` (info: expansions in single quotes) no longer fails CI on intentional literal patterns in `ssot-lint.sh`. Real warnings still fail.

### Not required
- No new SSOT top-level area, STATUS field, JSON/YAML state file, schema, command, skill, Doctor label, or `ssot-lint.sh` check.
- No new requirement on consumer projects. `tracked_skill_version` may advance to `2.24` as a no-op once it is confirmed no project-local material quoted the prior SKILL.md wording verbatim.

## [2.23] - 2026-06

`semantic_impact: low` — SKILL.md body distillation; no new area, owner field, or stop-review trigger. Per v2.22 §8.1, low-impact entries are not promoted to a standalone `protocol-upgrades.md` section; this CHANGELOG entry is the only record.

### Added
- **`skills/SKILL_STYLE.md`**: contributor-facing acceptance standard for `SKILL.md` prose bodies, reverse-engineered from Anthropic's `grill-me` skill. Five criteria (mode-switch / outcome-condition / structural metaphor / single anti-pattern guardrail / second-person imperative) plus a bundle-specific anti-pattern list. Includes a PR review procedure requiring per-sentence criterion annotation.

### Changed
- **`skills/ssot-skill/SKILL.md`** (compatibility shim): body distilled from 22 lines / ~230 words to 11 lines / ~60 words. Removed duplicated routing list; kept the single trigger-to-skill mapping. Posture sentence rewritten as second-person imperative. No semantic change; same five lifecycle routes.
- **`skills/ssot-preflight/SKILL.md`**: body distilled from 94 lines / ~1100 words to ~45 lines / ~470 words. Replaced the 8-step preflight checklist with a posture sentence plus three outcome-conditioned dimensions (adjudications / language / version). Folded the 14-row routing table into default-on rules plus pointer to `SSOT/README.md` task-entry map and `references/area-model.md` (full mapping unchanged, just delegated). Folded the durable-fact bullet list into a single comma-list; the `Rule / Trigger / Why / Evidence / Failure-mode` discipline schema now lives only in `references/area-model.md §2.5`, which the body explicitly points to. Frontmatter `semantic_impact: low` (introduced by v2.22) retained.
- **`skills/ssot-doctor/assets/scripts/ssot-lint.sh`** and **`run-tests.sh`** (engineering bucket): all script output and comments translated from Chinese to English; test fixture content (which exercises `documentation_language: 中文` semantics) intentionally retained in Chinese.

### Not required
- No new SSOT top-level area, STATUS field, JSON/YAML state file, schema, command, skill, Doctor label, or `ssot-lint.sh` check.
- No new requirement on consumer projects. `tracked_skill_version` may advance to `2.23` as a no-op once it is confirmed no project-local material quoted the prior SKILL.md wording verbatim.

## [2.22] - 2026-06

### Changed (preview)
- **Self-review 减负（v2.22 优化方案系列）**: 削减 B 类仪式性流程（自审计/账本/归零检查），保留 A 类长期记忆骨架（决策/Bug/Gotcha/Discipline/Architecture）。
  - STATUS.md 分层：停载 batch closeout blockquote、验证账本全表、stop-review 全表；目标 ~70 行。
  - `ssot-lint.sh` check#2 `converged` + drift 冲突从 FAIL 降为 WARN（`self-reference` 闭环）。
  - `status-protocol.md §7` 改为默认 self-reviewed + 4 个硬性独立 reviewer 例外。
  - `SKILL.md` frontmatter 新增 `semantic_impact` 字段（`none | low | high`），协议升级税按 impact 分级。
  - `protocol-upgrades.md` 按 high-impact 列条目，none/low 归入下一个 high entry 的 collapsed list。
  - `ssot-lint.sh` 移除副本一致性检查（`diff -qr` 永远 PASS）。
  - `SKILL.md §1.3` `[MUST]/[SHOULD]/[MAY]` 三级分类删除。
  - DEC 锚点规则收紧：`src/**` 或 `tests/**` 中 `# DEC-NNNN` 注释机械引用为充要条件。
- 详情见 v2.22 最终决议各 Phase 实现。

## [2.21] - 2026-06

### Added
- **Agent operation discipline routing**: `area-model.md §2.5` now defines
  `development/` discipline as the owner of cross-task imperative rules
  (`Rule / Trigger / Why / Evidence / Failure mode`), with a recommended
  `development/discipline.md` sub-file carrying `DISC-NNNN` entries. Discipline
  is task-pattern-scoped; `gotchas/` remains file/module-scoped.
- `area-model.md §4.1 Default fallback for unrouted durable knowledge`:
  imperative rule → `development/`; file-scoped trap → `gotchas/`; trade-off →
  `decisions/`; bug instance takeaway → `bugs/<entry>.md`. Explicitly forbids
  creating new top-level areas to absorb unrouted knowledge.
- `update-routing.md §2` new file-type row for external SDK / third-party API
  integration code (`*sdk*`, `*adapter*`, `integrations/`, manifest version
  bumps of an external SDK / LLM client / remote-service client) routed to
  architecture/, `development/` discipline, and bugs/ when applicable.
- `update-routing.md §3` four new conversation-signal rows for: long-term
  lesson / "from now on always X", mock-only-passed-real-service-differed,
  hotfix-of-hotfix on the same external behaviour, and the meta-question
  "where should this lesson live?" (which dispatches to §4.1 fallback).
- `update-routing.md §4` cascade row for discovery of long-term agent-operation
  discipline, requiring sync to `development/`, originating bug/decision and
  optionally `testing/` for the enforcement test.
- `ssot-preflight/SKILL.md §3` in-task write trigger for user-confirmed
  cross-task agent operation discipline.

### Changed
- `area-model.md §2.10 gotchas/` upgrades the `Trigger` field from
  `(recommended)` to `[SHOULD]` and adds an explicit boundary note: cross-task
  procedural rules belong in `development/` discipline, not in `gotchas/`.

### Not required
- No new SSOT top-level area, STATUS field, JSON/YAML state file, schema,
  command or skill.
- No new Doctor label; reuse `[CONSUMPTION]` and `[OWNER-ANCHOR]` when
  discipline entries are unreferenced or duplicate a bug takeaway without a
  clear owner.
- No `ssot-lint.sh` or `test-bundle-shape.sh` changes; v2.21 is a semantic
  protocol extension (same posture as v2.18).
- No mechanical migration of historical `gotchas/` entries; only the trigger
  field convention is reaffirmed.

## [2.20] - 2026-06

### Added
- **Installer agent registry expanded from 4 to 70 agents** to align with the
  Vercel `vercel-labs/skills` (skills.sh) ecosystem. Newly supported agents
  include Gemini CLI, GitHub Copilot, OpenCode, Cline, Roo Code, Continue,
  Augment, Zed, Goose, Aider, Junie, Trae (+CN), Crush, Warp, OpenHands,
  Replit, Devin, Droid, Qwen Code, Lingma, Kilo, ForgeCode, Tabnine CLI,
  Amp, Antigravity (+CLI), AstrBot, Autohand, IBM Bob, CodeArts, CodeBuddy,
  Codemaker, Code Studio, Command Code, Cortex, Deep Agents, Dexto,
  Firebender, Hermes, iFlow, inference.sh, Jazz, Kimi Code CLI, Kiro CLI,
  Kode, Loaf, MCPJam, Mistral Vibe, Moxby, Mux, Neovate, OpenClaw, Ona,
  Pi, Pochi, PromptScript, Qoder (+CN), Reasonix, Rovo Dev, Terramind,
  Tinycloud, Zencoder, Zenflow, AdaL, and a `universal` target writing to
  `.agents/skills`.
- `--list-agents` flag prints `KEY / NAME / DETECT / GLOBAL PATH` for every
  registered agent plus a detection summary for the current system.
- Legacy short keys (`claude`, `codeium`, `copilot`, `gemini`, `aider`,
  `tabnine`, `iflow`, `kimi`, `kiro`, `autohand`, `hermes`, `codearts`) are
  preserved as aliases that resolve to canonical Vercel keys (`claude-code`,
  `windsurf`, `github-copilot`, `gemini-cli`, `aider-desk`, `tabnine-cli`,
  `iflow-cli`, `kimi-code-cli`, `kiro-cli`, `autohand-code`, `hermes-agent`,
  `codearts-agent`). Existing CLI invocations and CI scripts keep working
  unchanged.

### Changed
- The interactive multi-select widget is now paginated and searchable. With
  70 supported agents the previous full-list redraw would overflow most
  terminals; the new widget shows a scrolling viewport with `/` filter,
  PageUp/PageDown, toggle-all-visible (`a`), and deselect-all (`q`) keys.
  Detected agents are still pre-selected.
- Multiple agents sharing the same physical install path (for example
  `cline`, `dexto`, and `loaf` all writing to `.agents/skills`) are now
  deduplicated with a single warning; the bundle is copied once.
- Project-only agents (currently `promptscript`) with no global install
  location now fail loudly under `--scope global` instead of silently
  installing to an empty path.
- Installer detection respects `$XDG_CONFIG_HOME`, `$CLAUDE_CONFIG_DIR`,
  `$CODEX_HOME`, `$VIBE_HOME`, `$HERMES_HOME`, `$AUTOHAND_HOME`,
  `$APPDATA`, and `$FLATPAK_XDG_CONFIG_HOME` where the corresponding agent
  uses them, matching `vercel-labs/skills` behaviour.

### Notes
- The SSOT protocol semantics, lifecycle skills, references, and templates
  are unchanged from 2.19 — only the installer's packaging surface and
  agent coverage move. The `VERSION` bump exists because
  `tests/test-bundle-shape.sh` enforces VERSION == `metadata.protocol_version`
  and because the installer surface is part of the publicly observed bundle.

## [2.19] - 2026-06

### Added
- **`SSOT/01-product/` as a mandatory top-level area** — the product trunk now owns
  the PRD, product promise, users / operators, product boundary, capabilities,
  journeys, roadmap, and product acceptance. Architecture only records
  technical implementation, runtime execution, failure / recovery,
  observability, and implementation gap, and links back to the product owner.
- Product bootstrap templates: `product-readme.md`, `product-prd.md`,
  `product-model.md`, `product-roadmap-and-acceptance.md`,
  `product-capabilities-readme.md`, `product-capability-entry.md`,
  `product-journeys-readme.md`, `product-journey-entry.md`.
- Doctor semantic labels: `[PRODUCT]`, `[PRODUCT-OWNER]`,
  `[PRODUCT-ARCH-DRIFT]`.
- `ssot-lint.sh` deterministic checks for the required product skeleton and
  for the `product` row in the `STATUS.md` coverage table.

### Changed
- Source material routing: PRD, product promise, users / operators,
  capability, journey, roadmap, and product acceptance now default to the
  product owner. This supersedes the v2.8 / v2.9 routing that absorbed PRD
  content into `architecture/views/`.
- `STATUS.md` coverage table MUST include a `product` row.
- Architecture views and domains MUST link to the product owner instead of
  re-defining product promise, product non-goals, user journeys, or product
  acceptance. Implementation gap links back to the product owner.

## [2.18] - 2026-06

### Added
- Architecture evidence-guided decomposition: `decomposition_basis` must record
  entrypoints, call/dependency edges, shared state, runtime flow, failure
  boundaries, contract surface, tests, configs, scripts and ADR material,
  including rejected axes and false friends.
- Bottom-up writing order for architecture: `domain evidence -> view synthesis
  -> root Reader Map`. Root/view claims must trace back to domain evidence or
  be marked `gap` / `unknown`.
- Reader Map as a reader route (intent, first stop, authoritative owner,
  evidence direction, stop condition, risk); it must not host independent
  long-lived facts.
- Authoritative owner anchor: each long-lived claim has exactly one owner
  (domain, view, engineering area, decision or other existing authority);
  non-owner sites only link.
- Architecture rubric in Doctor output: 1-minute mental model, view raison
  d'etre, domain why-separate, owner/evidence/why/risk/constraint, required
  diagrams, and current/target/gap separation.
- Doctor labels `[DECOMPOSITION]`, `[SYNTHESIS]`, `[OWNER-ANCHOR]`; existing
  `[READER-MAP]`, `[READABILITY]`, `[DIAGRAM]`, `[ARCH-ROOT]`, `[ARCH-VIEWS]`,
  `[ARCH-DOMAINS]` continue to apply.

### Changed
- Architecture rubric tightened; root README must not carry independent
  long-lived facts and must not pre-write global conclusions without
  domain-level evidence.

### Not required
- No new SSOT top-level area, STATUS field, JSON/YAML state file, schema,
  command or skill.
- No mechanical migration of legacy projects to the latest `views/ + domains/`
  template; only authority, evidence and reader-routing scope is touched.
- No Tree-sitter, LSP, automatic dependency graph, code indexer or generator.
- No `ssot-lint.sh` changes; these are L2 semantic checks.

## [2.17] - 2026

### Added
- SSOT Skill bundle: formal entry skill `ssot-preflight`; process skills
  `ssot-bootstrap`, `ssot-closeout`, `ssot-audit`, `ssot-doctor`; legacy
  `ssot-skill` retained only as a lightweight compatibility shim.
- Open adjudication parser: canonical heading `## 开放裁决项`, with backward
  compatibility for `## 待裁决项`.
- Doctor label `[SKILL-SPLIT]` for bundles missing the formal entry, a process
  skill, the shim, the protocol owner or process trigger descriptions.

### Changed
- Entry skill renamed: task start now triggers `$ssot-preflight` instead of
  `$ssot-skill`.
- Protocol-version owner migrated to `skills/ssot-preflight/SKILL.md`
  (`metadata.protocol_version`); `tracked_skill_version` now refers to the
  bundle protocol version rather than the old `ssot-skill/SKILL.md`.
- Adapter / core-ref boundary clarified: the 50-line size cap and SSOT-source
  hash apply only to files carrying the SSOT-generated marker. Handwritten or
  mixed startup files are no longer flagged `[ADAPTER]` for missing the
  marker; missing SSOT routing reports as `[CONSUMPTION]`, factual drift as
  `[CORE-REF]`.

### Not required
- No new SSOT top-level area, JSON/YAML state file or product-grade Web/API
  truth.
- No per-skill separate installation; phase 1 installs the bundle together.
- No mechanical renaming of historical text; only triggers, protocol watermark
  and runtime prompts in authoritative positions are updated.

## [2.16] - 2026

### Removed
- All naming entries, source-material classifications and special routes for
  legacy externally generated repository-knowledge surfaces. Reader Map,
  claim-to-evidence, script/tool inventories and diagram-candidate governance
  are now native protocol capabilities, not external imports.

### Changed
- Source material scope limited to README / docs / ADR / PRD / runbook /
  design docs / subsystem README / user-provided external material; external
  auto-summaries are accepted only as ordinary candidate material.
- Reader Map provenance: generated from `decomposition_basis`, reader
  questions, authoritative positions and evidence; never borrowed from
  external topic trees.
- External generated diagrams, screenshots, IDE dependency graphs and auto
  dependency graphs are candidates only; they must be rewritten as
  maintainable Mermaid with Diagram ID, Status, Covers, evidence and owner
  before counting as authoritative.

### Added
- Doctor label `[LEGACY-SURFACE]` for residual parallel generated knowledge
  surfaces, legacy-named entries, dedicated source-material categories, or
  external topic trees being treated as authority.

### Not required
- No migration scripts; the protocol-upgrade audit is sufficient.
- No mechanical rewrite of all existing SSOT files to the latest template.
- No active fetching of external generated material.
- No new SSOT area, STATUS field, schema or generator.

## [2.15] - 2026

### Added
- `[CORE-REF]` review slice: `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/*`,
  `.windsurf/rules/*`, `GEMINI.md` and equivalent startup-time / agent-rules
  files are now first-class source material. New `STATUS.md` 核心参考文档审查
  table; new Doctor `[CORE-REF]` L1/L2 checks.
- Reader Map / 快速理解地图 protocol for entry routing: entries only link to
  authoritative positions and must not host independent long-lived facts.
- Readable Authority / 可读权威正文: prose body must establish a mental model
  via short narrative, claim, evidence, why, risk and constraint; tables and
  lists alone are insufficient.
- Claim-to-evidence writing as standard for key assertions in architecture
  views/domains and engineering operating areas.
- Engineering script/tool inventory fields under `development/`, `testing/`,
  `release/` and deployment areas.
- Diagram-candidate governance: external generated diagrams, screenshots and
  dependency graphs accepted only as candidates; authoritative diagrams must
  be Mermaid fenced blocks with metadata, evidence, status and
  current/target separation.
- Doctor labels `[CORE-REF]`, `[READER-MAP]`, `[READABILITY]`; extended
  `[DIAGRAM]` for misuse of external generated diagrams as authoritative.

### Changed
- L2 semantic checks scoped: `ssot-lint.sh` remains deterministic and is not
  asked to judge command, workflow or architecture-fact semantics; those
  remain with the Doctor reviewer.
- `[ADAPTER]` continues to cover thin-adapter file shape only;
  `[CONSUMPTION]` continues to cover SSOT trigger linkage; `[CORE-REF]`
  covers factual correctness of startup-time references.

### Not required
- No new `SSOT/core-reference/` or other top-level area.
- No mechanical replacement of user-authored `AGENTS.md` / `CLAUDE.md`;
  default output is specific recommendations only.
- No `[CORE-REF]` automation inside `ssot-lint.sh`.
- No new top-level parallel knowledge area, schema, STATUS field or generator.

## [2.14] - 2026

### Added
- L4 behaviour-layer trigger / consumption-side audit: new
  `skills/ssot-doctor/references/consumption-audit.md` as the semantic owner
  for verifying whether SSOT was actually triggered and consumed in real
  transcripts. Honours the L4 probe promise outstanding since v2.13.
- Near-field trigger probe during session self-check (zero-cost, always on).
- Far-field consumption audit available on demand (`[MAY]`) when the user
  names it or near-field signals are insufficient.

### Changed
- `[CONSUMPTION]` Doctor label scope extended: L1 static link breaks continue
  to use it; L4 behaviour-layer attribution and trigger-side optimisation
  flow through the consumption audit without a new label.

### Not required
- No mandatory far-field transcript analysis every session.
- No automatic rewriting of trigger-side files; recommendations only by
  default.
- No new SSOT area, STATUS field or required-to-create files.

## [2.13] - 2026

### Added
- Pre-write conflict / negation scan in SKILL.md §3.1.
- Evidence pointer symbol anchor (`path#symbol`) preferred over `path:line`
  to survive code movement; legacy line pointers are not mechanically
  migrated.
- Gotcha executable contract: high-risk active gotchas must give a
  "don't do / do instead" pair.
- Optional SSOT-source hash line on SSOT-generated thin adapters for drift
  detection (`SSOT-source: <path>@<hash>`).
- SSOT consumption link check (`[CONSUMPTION]` Doctor label): adapter must
  carry SSOT read instruction and route to SSOT; `SSOT/README.md` navigation
  entry must exist.
- `ssot-lint.sh` L1 automation extended to checks #6 (confidence: hypothesis
  in `architecture/`), #7 (SSOT-generated thin adapter <=50 lines and
  optional source hash) and the consumption link check.

### Not required
- No mechanical migration of existing `path:line` evidence pointers.
- No requirement to fill executable contracts for all gotchas (high-risk
  first).
- Source hash on thin adapters is `[MAY]`, not required.
- No new SSOT area, STATUS field or required-to-create files.

## [2.12] - 2026

### Added
- Protocol layering with `[MUST]` / `[SHOULD]` / `[MAY]` markers in SKILL.md
  to lower Agent execution friction under high task load.
- `self-reviewed` downgrade path in the STATUS independent stop-review gate:
  medium-impact updaters may self-review with explicit recording.
- Legacy direct-child-domain compensation: when no `architecture/views/`
  exists, root `architecture/README.md` MUST carry `设计简报`, `核心不变量`,
  `Current / Target / Gap 摘要` sections.
- `decomposition_basis` template for architecture splits.
- Architecture migration trigger when the domain count is >= 4 or a journey
  crosses >= 3 domains (see `architecture.md`).
- Bootstrap recon archive path: `recon.md` is archived as
  `decisions/0000-bootstrap-recon.md` rather than deleted during Phase 4
  cleanup; manifest and session logs are still cleaned up.
- `ssot-lint.sh` script available as `[MAY]` CI / Doctor pre-gate; can be
  invoked directly from the skill path without copying into the project.

### Changed
- `STATUS.md` coverage tables (`区域 / 状态 / 备注`) must not maintain
  derivable information (entry counts, sub-directory entry status, recent
  test results); the 备注 column becomes a pointer to sub-directory README,
  carrying only unique semantics.

### Not required
- No traversal of historical stop-review entries to back-fill
  `self-reviewed`.
- No new SSOT files or directories.
- No new required-to-create file or area.

---

[Unreleased]: https://github.com/huangpufan/SSOT-SKILL/compare/v2.21...HEAD
[2.21]: https://github.com/huangpufan/SSOT-SKILL/releases/tag/v2.21
[2.19]: https://github.com/huangpufan/SSOT-SKILL/releases/tag/v2.19
[2.18]: https://github.com/huangpufan/SSOT-SKILL/releases/tag/v2.18
[2.17]: https://github.com/huangpufan/SSOT-SKILL/releases/tag/v2.17
[2.16]: https://github.com/huangpufan/SSOT-SKILL/releases/tag/v2.16
[2.15]: https://github.com/huangpufan/SSOT-SKILL/releases/tag/v2.15
[2.14]: https://github.com/huangpufan/SSOT-SKILL/releases/tag/v2.14
[2.13]: https://github.com/huangpufan/SSOT-SKILL/releases/tag/v2.13
[2.12]: https://github.com/huangpufan/SSOT-SKILL/releases/tag/v2.12
