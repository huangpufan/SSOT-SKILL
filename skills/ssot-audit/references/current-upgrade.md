# Current Protocol Upgrade

This file holds the current protocol entry and the nearest recent standalone
entries. If a project already has `tracked_skill_version >= 2.35`, this file is
the only upgrade ledger the audit needs to read.

For older or missing waterlines, start at [`protocol-upgrades.md`](protocol-upgrades.md)
and follow [`archive/index.md`](archive/index.md) to load only the needed range
files.

## Version Ledger

### v2.52

**Upgrade goal**: add the **open-risk and temporary-surface floor**. A consumer
SSOT can pass structure lint while hiding three kinds of unfinished work:
temporary surfaces left in current code/docs without a retirement owner, open
gaps that say "create debt later" instead of linking a real owner, and stop /
capture summaries that claim only/no remaining work while open gaps or active
high-risk records still exist. v2.52 makes those cases first-class protocol
surface.

**Impact**: `semantic_impact=medium` — adds closeout/preflight obligations, one
owner-boundary clarification for Capability -> Surface registry rows, and
deterministic lint checks 23-28. Consumers self-review per
`status-protocol.md §7.1`; no independent reviewer is required unless the
consumer also uses the upgrade to claim first-time `converged`.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Task-relevant open risks | `STATUS.md ## Open Gaps`, active `tech-debt/`, active/recurred `bugs/`, relevant `gotchas/` | During preflight, surface entries whose trigger/path/capability/failure mode overlaps the task; during closeout, record fixed / deferred-with-reason / next-action. | Closeout cannot end with an overlapped risk silently ignored. |
| Temporary-surface registration | Current fallback, compat shim, TODO/FIXME/HACK/WORKAROUND, temporary waiver, later-remove path | Register owner, reason, closure condition, revisit signal, and verification guard in `tech-debt/`, `bugs/`, `decisions/`, or an open STATUS gap. | Doctor/lint finds no hidden temporary surface in covered/current scope. |
| ADR/debt closure fields | `decisions/`, `tech-debt/` | Confirm pending/partial/diverged ADRs and active debts have falsifiable `closure_condition` and concrete `revisit_signal`; `temporary_surface: true` debt also has `owner`, `reason`, and `verification_guard`. | `ssot-lint.sh SSOT/` reports `[ADR-CLOSURE]`, `[DEBT-CLOSURE]`, and `[TEMP-SURFACE]` clean. |
| Covered placeholder blocker | Any area marked `covered` | Remove unresolved template residue such as TODO/FIXME, `review-needed`, starter skeleton text, `TBD`, or locked-language placeholder text from user-facing owners; otherwise demote the area. | `[COVERED-PLACEHOLDER]` clean. |
| STATUS aggregate consistency | `STATUS.md` stop/capture summaries | Reconcile "only/no remaining" wording against open gaps and active high/critical records. | `[STATUS-AGGREGATE]` clean. |
| Gap owner routing | `STATUS.md ## Open Gaps` | Replace "TODO debt", "create debt later", or equivalent unowned wording with a real owner link or explicit deferred owner/trigger. | `[GAP-OWNER]` clean. |
| Capture lifecycle hygiene | `STATUS.md` pending-capture / resolved-capture sections | Promote actionable follow-ups, defer them with owner/trigger, or expire them; do not leave "Pending action" inside a passed/resolved section. | `[CAPTURE-LIFECYCLE]` clean. |
| Markdown structure | All SSOT Markdown | Close all fenced code blocks. | `[MARKDOWN-FENCE]` clean. |

**Migration notes**:

- This upgrade intentionally does not raw-grep the whole repository for
  `TODO`/`fallback`; downgraded source material and tests may contain those
  words legitimately. The hard gate applies to current SSOT owners, STATUS
  registers, and active record metadata.
- A consumer may keep an open gap non-blocking, but it must be routed. "Not a
  blocker" is a priority claim, not an owner.
- Capability -> Surface registry rows now have one owner per row plus link-only
  mirrors. Existing duplicate mirrors should be thinned opportunistically or
  when touched.

### v2.51

**Upgrade goal**: add the **reader-scaffolds floor**. The v2.47–v2.50 floors
are all *subtractive* — they cut shadow ledgers, table-only intent narratives,
language-drift H1s, missing directory maps. v2.51 adds the *additive*
complement: four owner-template structural slots a cold agent needs to
orient itself after routing — `## Walkthrough`, `## Easily confused with`,
`## Out of scope`, `## See also` — plus a new `glossary-entry.md` per-term
template, diagram-typing comments in architecture Mermaid blocks, and a
KISS mini-card permitted form for first-mention canonical vocabulary that
does not violate `15F [VOCAB-PROSE-FORK]`.

**Impact**: `semantic_impact=medium` — adds five new Doctor rows
(`15R [WALKTHROUGH]` / `15S [BOUNDARY-DISAMBIG]` / `15T [OUT-OF-SCOPE-LINK]`
/ `15U [DIAGRAM-TYPE-TAG]` / `15V [DIAGRAM-FIRST]`) and five lint script
checks (18–22). All five ship as WARN-only in the first cycle so existing
converged SSOTs do not regress; `15R [WALKTHROUGH]` graduates to FAIL after
one adoption cycle. The `area-model.md §2.0` required-answer list extends
from five questions to six (added "Where can I go next, and what does this
owner explicitly NOT answer"). Consumers self-review per
`status-protocol.md §7.1`; no doctor stop-review is required.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Reader-scaffold slots on owner READMEs | Every `covered` owner README under `SSOT/` (top-level area READMEs, architecture domain READMEs, `dir-readme-map.md` rendered indexes) | Open each owner README; fill the four new slots from the upgraded `assets/templates/{en,zh}/` owner template, or write explicit `not_applicable: <reason>` where genuinely indexical. Walkthrough on `architecture/<domain>/README.md` references one canonical flow's surface/symbol pins; never duplicates the Runtime Flows table. | `ssot-lint.sh SSOT/` reports `[BOUNDARY-DISAMBIG]` / `[OUT-OF-SCOPE-LINK]` / `[WALKTHROUGH]` = 0 WARN, OR every WARN row is a deliberate `not_applicable: <reason>` documented in the area's `_manifest.md`. |
| Diagram typing in `architecture/` | All Mermaid fenced blocks under `architecture/` | Add `<!-- diagram_type: component\|sequence\|state\|flow -->` as the first non-blank line inside each Mermaid fence; split any block that mixes types (e.g. flowchart edges + sequence `participant` directives). | `ssot-lint.sh SSOT/` reports `[DIAGRAM-TYPE-TAG]` = 0 WARN. |
| First-screen diagram on architecture domain READMEs | Every `architecture/<domain>/README.md` whose `intent_recovery: covered` | Move or add a small component diagram above the first owned-facts table so a cold reader sees the boundary picture before parsing tables. Domains genuinely without a meaningful diagram downgrade to `partial`. | `ssot-lint.sh SSOT/` reports `[DIAGRAM-FIRST]` = 0 WARN. |
| Glossary entry template adoption | New glossary entries created after this upgrade | Render new glossary entries from `assets/templates/{en,zh}/glossary-entry.md` (`glossary/<term>.md`). Pre-v2.51 entries inside `glossary/README.md` grandfather in until next touched. | New entries follow the per-term file shape; touched entries migrate. |
| Required-answer count in `area-model.md §2.0` | Anyone authoring or auditing a user-facing owner README | When asserting an owner README is `covered`, confirm the sixth question ("Where can I go next, and what does this owner explicitly NOT answer") is answered by the `## See also` + `## Out of scope` slots, not by inline body navigation links. | Cold-reader review on `covered` owners confirms the sixth answer is locatable in dedicated slots. |

**Migration notes**:

- Self-reviewable per `status-protocol.md §7.1`; no doctor stop-review required.
- All five new checks ship as WARN-only for one adoption cycle so existing
  converged SSOTs do not regress.
- `15R [WALKTHROUGH]` graduates to FAIL in the next cycle's protocol entry;
  the other four rows stay WARN until their consumer adoption signal warrants
  promotion.
- The KISS mini-card permitted form is opt-in: existing `[CORE-REF: ...]`
  links remain valid; the mini-card is an additional shape, not a rewrite.

### v2.50

**Upgrade goal**: establish the **information-architecture (IA)
self-display floor**. A cold reader's first touch is `ls` / `tree`, not
`cat` — directory names, file-name prefixes, and the README directory-map
annotations must carry routing weight, with prose only filling the gap when
the name alone is ambiguous. v2.50 codifies this with four sub-rules in
`bootstrap.md §3.7` (A1.1–A1.4), four Doctor L1 checks
(`15N [DIR-MAP]` / `15O [READ-ORDER]` / `15P [META-FILE-ROUTING]` /
`15Q [JARGON-MAP-NOTE]`), one deterministic lint check
(`[DIR-MAP-MISSING]`), one cold-agent-sim probe (`§1.8 dir-tree-only`),
and a new `dir-readme-map.md` template (en/zh).

**Impact**: `semantic_impact=medium` — adds a new hard Doctor row
(`15N`) and three soft ones (`15O` / `15P` / `15Q`). Consumers that
previously had directory READMEs without an ASCII tree must add one.
The lint script's `[PRODUCT]` skeleton and `[INTENT-TRUTH-NARRATIVE]`
checks now also accept `SSOT/01-product/` and `SSOT/02-architecture/`
when those directories exist, so consumers may facet the top level
without breaking the skeleton check.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Directory map presence | Every directory holding ≥2 children | Open each directory's `README.md`; insert an ASCII tree (`├──` / `└──`) plus one-sentence plain-language annotations as the first content after H1. | `ssot-lint.sh SSOT/` reports `[DIR-MAP-MISSING]` = 0. |
| Read order | Architecture sub-domains, product spine files, numbered capability/journey sets | Confirm `NN-` prefix on ordered children; for unordered peers add a "recommended reading order" line under the map. | Doctor `15O` clean. |
| Meta-file routing | `_manifest.md` and any `_*.md` files | Add an explicit "machine-only, skip" marker (or the locked-language equivalent) on the meta row. | Doctor `15P` clean. |
| Jargon translation | Team-jargon file names in directory maps | Translate the file-name jargon into the annotation cell ("the layer that normalises calls to the AI model" rather than "the SDK agent runtime adapter"). | Doctor `15Q` clean. |
| Cold-reader probe | All directory READMEs the consumer ships | Run `cold-agent-sim §1.8 dir-tree-only` mandatory question pool; ≥80% PASS. | No mandatory question FAILs. |
| Top-level facet (optional) | Consumer's top-level SSOT shape | If the consumer faceted the top level (e.g. `SSOT/01-product/`), confirm `ssot-lint.sh` still passes — lint resolves the trunk path at runtime. | Lint PASS. |

**Doctor tags**:

- `[DIR-MAP]` (`15N`): hard blocker. A directory holding ≥2 children
  must open its README with an ASCII tree + plain-language annotations
  as the first content body.
- `[READ-ORDER]` (`15O`): hard blocker. Ordered children carry `NN-`
  prefix; unordered peer directories name a "recommended reading order"
  line.
- `[META-FILE-ROUTING]` (`15P`): hard blocker. `_manifest.md` / `_*.md`
  rows in the directory map carry an explicit "machine-only, skip"
  marker.
- `[JARGON-MAP-NOTE]` (`15Q`): hard blocker. Annotation cells in the
  directory map use plain language; team-jargon file names get translated.

**Backwards compatibility**: consumers that use the canonical un-faceted
shape (`SSOT/product/`, `SSOT/architecture/`) continue to pass the v2.50
lint unchanged. Consumers without ASCII trees in their directory READMEs
must add them; this is the only deterministic regression v2.50 introduces.

### v2.48

**Upgrade goal**: separate SSOT self-maintenance machinery from product /
architecture prose. v2.43–v2.47 layered a Core recovery manifest, Core
completeness argument, Apex / Maxim → Owner index, Capability → Surface
registry mirror rows, intent-recovery pillar matrices, evidence strings, and
README-self failure-mode sections onto product / architecture trunks. The
covered area still passes Doctor, but a cold reader who opens
`product/README.md` or `architecture/README.md` has to learn SSOT skill
vocabulary before they can recover the project's product or design story.
v2.48 hoists that machinery into a sibling `_manifest.md` so prose owners
carry only the product / design narrative.

**Impact**: `semantic_impact=medium` -- adds one hard Doctor row (15I
`[META-LEAKAGE]`), a deterministic lint check with a standalone
`--check-meta-leakage` flag, and a new `_manifest.md` template. No new
top-level SSOT area is required.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Manifest hoist | `product/`, `product/{capabilities,journeys}/`, `architecture/`, `architecture/views/`, each `architecture/<domain>/` | Create the area's `_manifest.md` and move Core recovery manifest, Apex / Maxim → Owner index, Capability → Surface registry mirror, intent-recovery pillar matrix, `intent_recovery_evidence` strings, README-self failure-mode sections, and adoption-cycle log into it. | Each covered area has its sibling `_manifest.md`; doctor / cold-agent-sim can recover the same evidence the v2.4x manifests covered. |
| Prose cleanup | Product / architecture prose files (`*.md` other than `_manifest.md`, `STATUS.md`, `decisions/`, `tech-debt/`, `CHANGELOG.md`) | Strip doctor code literals (`14W`/`14X`/`14Z`/`15A`/`15D`/`15F`/`15H`/`15I`/`[CORE-REF-PROSE]`/`[MAXIM-OWNER]`/`[INTENT-OWNER]`/`[INTENT-TRUTH-NARRATIVE]`/similar), adoption-cycle version literals (`v2.43`…`v2.48`), pillar vocabulary (`product_intent + product_truth`, `必备 pillar`, `intent_recovery_pillars`), long `intent_recovery_evidence:` frontmatter strings, README-self failure-mode sections, full `Apex-Maxim → Owner 索引` tables, mirror `Capability → Surface registry` rows, and `核心恢复清单` tables. Replace each with the product / design idea the section actually needs plus an inline `[CORE-REF: ...]` link to the manifest or owner. | `ssot-lint.sh --check-meta-leakage SSOT/01-product/ SSOT/02-architecture/` reports `FAIL=0`. |
| Frontmatter shrink | Covered prose files | Reduce per-file frontmatter to `intent_recovery: covered\|partial\|gap`; move full evidence strings to `_manifest.md`. | No prose file carries `intent_recovery_evidence: "<long string>"` frontmatter; the manifest does. |
| Doctor / lint coverage | `ssot-lint.sh`, Doctor review | Run `ssot-lint.sh SSOT/` and the standalone `--check-meta-leakage` mode; verify `15I` hits = 0 after migration. | Lint pass; the targeted grep shows no doctor codes / version literals / pillar phrases / mirror tables outside `_manifest.md`. |
| Bundle version sync | `VERSION`, `skills/ssot-preflight/SKILL.md` metadata | Confirm both equal `2.48`; rerun `tests/test-bundle-shape.sh`. | Bundle-shape test passes. |

**Doctor tags**:

- `[META-LEAKAGE]` (15I): a covered product / architecture prose file
  (`SSOT/01-product/*.md`, `SSOT/01-product/{capabilities,journeys}/*.md`,
  `SSOT/02-architecture/*.md`, `SSOT/02-architecture/*/*.md`,
  `SSOT/02-architecture/views/*.md`, in each case excluding `_manifest.md`)
  carries SSOT self-maintenance machinery that v2.48 hoists to the sibling
  `_manifest.md`. Hard blocker — the affected area cannot be marked `covered`
  until the prose is reduced to product / design narrative plus inline
  `[CORE-REF: ...]` anchors and the machinery is hoisted.

**No-op criteria**:

- Projects whose product / architecture areas are not yet marked `covered` may
  record v2.48 as pending adoption and leave the prose / manifest split open
  in `STATUS.md ## Pending Captures`.
- Projects that have already organized their product / architecture trunks
  around prose-only owners with no doctor codes / cycle labels / pillar
  vocabulary in body files (a stricter discipline than v2.47 required) may
  record no-op after the standalone `--check-meta-leakage` lint run reports
  zero hits and the new `_manifest.md` template is present (or explicitly
  not_applicable with reason in STATUS.md).

### v2.47

**Upgrade goal**: make the Core recovery manifest a proof index rather than the
first explanation a reader sees. v2.45/v2.46 made product and architecture core
sets finite, but a consumer could still satisfy the manifest while forcing a
cold reader to reconstruct product intent, product truth, design intent, and
design truth from table cells. v2.47 adds an intent/truth narrative gate before
the manifest.

**Impact**: `semantic_impact=medium` -- adds one semantic Doctor row and a
WARN-only lint heuristic. No new top-level SSOT area or lifecycle skill is
required.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Product intent/truth narrative | `product/README.md` or the declared product trunk owner | Add compact prose before owner maps / manifests: user/operator, problem, promise, boundary/non-goal, acceptance meaning, current truth vs target/debt/Out, and first owner to inspect. | A cold reader understands product truth before reading tables. |
| Architecture design/truth narrative | `architecture/README.md` | Add compact prose before dense owner maps / manifests: runtime-owner axis, current design truth, design/debt/Out boundary, near-miss exclusions, CTG posture, and first view/domain to inspect. | A cold reader understands the design truth before reading tables. |
| Manifest stays narrow | Product / architecture manifests | Remove paragraph reasoning from cells; keep owner, required pillars, state, evidence / closure owner. | The manifest is an index, not the story. |
| Lint/Doctor coverage | `ssot-lint.sh`, Doctor review | Run lint and inspect `[INTENT-TRUTH-NARRATIVE]` warnings semantically. | No covered product / architecture trunk relies on table-only core explanation. |
| Bundle version sync | `VERSION`, `skills/ssot-preflight/SKILL.md` metadata | Confirm both equal `2.47`; rerun `tests/test-bundle-shape.sh` and lint tests. | Bundle-shape and lint tests pass. |

**Doctor tags**:

- `[INTENT-TRUTH-NARRATIVE]` (15H): a covered product / architecture trunk lacks
  compact prose that explains intent and current truth before dense owner maps
  or the Core recovery manifest, or the only explanation of "why this is core"
  and "what is true today" appears inside table cells.

**No-op criteria**:

- Projects whose product / architecture areas are not marked `covered` may
  record v2.47 as pending adoption and leave the narrative as an open gap.
- Projects whose trunks already have explicit intent/truth prose before the
  manifest may record no-op after targeted Doctor review. High table-line
  density alone is not a fail when the prose narrative is clear and tables are
  narrow indexes.

### v2.46

**Upgrade goal**: make core recovery manifests prove completeness, not only
enumerate rows. v2.45 made product and architecture core sets finite, but a
consumer could still omit product-model facts such as users/problems/promises
or architecture operating-model facts while the remaining row table looked
complete. v2.46 adds a Core completeness argument and broadens 15G to cover the
classes that make product intent and design intent recoverable from first
principles.

**Impact**: `semantic_impact=medium` -- adds a semantic gate on existing
product / architecture manifests. No new top-level SSOT area, lifecycle skill,
or deterministic lint script is required.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Product completeness argument | `product/README.md` or `product/prd.md` | Explain why the core set is complete, including users/operators, problems, promises, boundaries, acceptance semantics, trade-offs, excluded near-misses, and omission risks. | A cold reader can tell why the product core is not just a feature list. |
| Architecture completeness argument | `architecture/README.md` | Explain why the runtime-owner axis plus cross-owner views, global invariants / operating model, and CTG posture form the design core; list excluded implementation inventories and omission risks. | A cold reader can tell why the architecture core is not just a domain list. |
| Manifest row coverage | Product / architecture manifests | Add any omitted posture/model/operating-model/CTG rows, and map state labels to the protocol state set. | No core row relies on unmapped `current` / `active` / `partial` labels or hidden spine prose. |
| Spine-owned rows | `product/prd.md` and `architecture/README.md` | When a core row points to a spine owner, provide a same-granularity anchor or short subsection. | The reader does not need to infer the row from decisions, architecture CTG, or source material. |
| Bundle version sync | `VERSION`, `skills/ssot-preflight/SKILL.md` metadata | Confirm both equal `2.46`; rerun `tests/test-bundle-shape.sh`. | Bundle-shape test passes. |

**Doctor tags**:

- `[CORE-COVERAGE-MAP]` (15G): now also fires when a covered product /
  architecture area lacks the completeness argument, omits product-model or
  operating-model core classes, cannot explain exclusions, uses unmapped state
  vocabulary, or routes a spine-owned row without a same-granularity anchor.

**No-op criteria**:

- Projects whose product or architecture area is not marked `covered` may record
  v2.46 as pending adoption and leave the completeness argument as an open gap.
- Projects whose v2.45 manifest already includes a prose completeness argument,
  product-model / operating-model rows, exclusion rationale, and protocol state
  vocabulary may record no-op after targeted Doctor review.

### v2.45

**Upgrade goal**: make "all core product/design intent and truth" a finite
recovery obligation rather than an inferred property of several indexes. v2.43
and v2.44 prove sampled owners and product current-truth rows, but a consumer
could still mark an area `covered` while omitting a core capability, journey,
runtime owner, or cross-owner view from the recoverability sweep. v2.45 adds a
Core recovery manifest requirement for product and architecture trunks.

**Impact**: `semantic_impact=medium` — adds a manifest gate and a Doctor row,
but no new top-level SSOT area or lifecycle skill. It affects consumers that
mark `product` or `architecture` as `covered`.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Product Core recovery manifest | `product/README.md` or `product/prd.md` | Enumerate every core capability and journey, owner, required pillars, current truth state, and closure / evidence owner. | A cold reader can see the finite set behind "all core product intent/truth". |
| Architecture Core recovery manifest | `architecture/README.md` | Enumerate every runtime owner and cross-owner view, owner, required pillars, current truth state, and closure / evidence owner. | A cold reader can see the finite set behind "all core design intent/truth". |
| State consistency | Product / architecture indexes and owner bodies | Downgrade any manifest/index state that is stronger than the owner body, using `mixed` when one core row combines shipped contract truth with unresolved design/debt/out truth; or close the underlying gap. | No parent row says all-`contract` while a child owner still has design/debt/out current-truth. |
| Cold-agent-sim manifest sweep | `skills/ssot-doctor/references/cold-agent-sim.md` reports | Add owner-directed synthetic trials for manifest rows not naturally touched by recent commits. | Mandatory manifest cells PASS or are reasoned `N/A` with revisit owner. |
| Runtime install freshness | Active installed skill copy | If local project installs `.agents/skills` / `.codex/skills` / `.claude/skills`, compare their metadata to source and reinstall when behind. | Future agents read the same protocol version recorded in `STATUS.md`. |
| Bundle version sync | `VERSION`, `skills/ssot-preflight/SKILL.md` metadata | Confirm both equal `2.45`; rerun `tests/test-bundle-shape.sh`. | Bundle-shape test passes. |

**Doctor tags**:

- `[CORE-COVERAGE-MAP]` (15G): product / architecture `covered` claims lack a
  complete Core recovery manifest, omit a core owner, declare incomplete
  pillars, advertise a state stronger than the owner body, or leave mandatory
  manifest rows unsampled without a Pending Capture.
- `[INTENT-RECOVERY]` (14Y): still gates declared owner pillars; v2.45 makes
  the manifest the finite source of which owners must be checked.

**No-op criteria**:

- Projects whose product or architecture area is not marked `covered` may record
  v2.45 as pending adoption and leave the manifest as an open gap.
- Tiny projects with one product promise and one architecture owner may keep the
  manifest as a short prose list, but it still must name owner, required
  pillars, state, and closure / evidence owner.

### v2.44

**Upgrade goal**: tighten `product_truth` so SSOT records recoverable
current product truth rather than only shipped surface contracts. v2.43's
4-pillar harness correctly caught product-owner gaps, but its
`product_truth` wording could push consumers toward a false binary:
either provide a full `[SURFACE-PIN]` route + component + browser-test row, or
remain unrecoverable. Real product truth also includes "this is design/debt",
"this is deliberately Out", and "this surface is not applicable"; those states
must be just as routeable and falsifiable.

**Impact**: `semantic_impact=medium` — changes `product_truth` scoring and
Doctor wording, but does not add a top-level SSOT area or a new lifecycle
skill. Existing `state: contract` rows remain governed by `[SURFACE-PIN]`.
The new requirement applies to product owners that declare
`intent_recovery_pillars` including `product_truth`, or to capability/journey
owners edited during the upgrade batch.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Product current-truth rows | `product/capabilities/*.md`, `product/journeys/*.md` | For each user-observable row, verify it says whether current truth is `state: contract`, `state: design`, `state: debt`, `Out`, or `not_applicable`. | A cold reader can answer "what works today, what is only design/debt, and what is out of scope" without reading code. |
| Contract surface evidence | Product rows with `state: contract` | Keep the `[SURFACE-PIN]` route + handler / component / browser-or-route test anchor. | Doctor 14T clean for shipped rows. |
| Design/debt/out truth | Product rows without contract-level evidence | Add current behavior, missing evidence, and a falsifiable closure owner (`DEBT-NNNN`, `ADJ-NNNN`, ADR closure condition, or named test-to-add). | No "later" / "pending" row lacks a closure owner; cold-agent fail rows do not show `truth-state-gap`. |
| Intent-recovery annotation | Owners declaring `product_truth` | Refresh `intent_recovery_evidence` only when a latest applicable trial or targeted review proves all declared pillars. | `covered` only when all declared pillars PASS; otherwise `partial` with a Pending Capture. |
| Bundle version sync | `VERSION`, `skills/ssot-preflight/SKILL.md` metadata | Confirm both equal `2.44`; rerun `tests/test-bundle-shape.sh`. | Bundle-shape test passes. |

**Doctor tags**:

- `[SURFACE-PIN]` (14T): still gates shipped `state: contract` surfaces.
- `[INTENT-RECOVERY]` (14Y): now also reports `truth-state-gap` when a
  product owner names a surface but omits its current state or closure owner.

**No-op criteria**:

- Product-only repos without capability/journey owners may record no-op after
  confirming `product/prd.md` and `product/product-model.md` already state
  current, target, out-of-scope, and closure owners in prose.
- Pure architecture / testing / release changes do not need a product sweep
  unless they edit product owners or declare `product_truth` pillars.

### v2.43

**Upgrade goal**: open the intent-recoverability cycle. After v2.42 stabilised
the cold-agent simulation harness routing-only mandate, cycle-1 of the
intent-recoverability loop introduces the bundle primitives needed to detect
*structural unrecoverability* — when SSOT is structurally shaped right but a
cold agent still cannot get from the user's user-visible intent to the right
owner inside the 5-hop budget. Six lens findings (`domain-why`,
`no-prose-fork`, `maxim-owner`, `adr-closure`, `glossary-states`,
`intent-eval`) inform this batch. Headline additions:

- new `skills/ssot-preflight/references/intent-ownership.md` — apex-maxim →
  SSOT-owner mapping; repo-wide invariant single-owner rule; the
  `[CORE-REF: <owner_path#anchor>]` syntax that lets a CORE-REF startup file
  point at a single SSOT owner without recopying the invariant body;
- architecture domain README **intent triad** (`## Why` /
  `## 失败模式 (Failure Modes)` / `## 关闭条件 (Closing Conditions)`)
  required before the runtime-owner / state / contract body;
- `glossary/` **canonical-vocabulary hard list** (workflow result codes,
  task/node lifecycle states, agent-tier semantics, altitude vocabulary)
  with `not_applicable` placeholders required when a category is absent;
- ADR and tech-debt entries gain falsifiable `closure_condition` +
  `revisit_signal` YAML fields for any open / active row;
- `knowledge-integrity.md` adds an **`intent_recovery` axis** (`covered` /
  `partial` / `gap`) orthogonal to the confidence axis; `covered` cannot
  coexist with `intent_recovery: gap`;
- `cold-agent-sim.md` gains a 4-pillar grading rubric (`design_intent` /
  `product_intent` / `design_truth` / `product_truth`) with `≥ 5/8` per-
  pillar floor plus `≥ 24/32` aggregate gate, and a closed-set
  `miss_class` taxonomy (`missing-owner` / `prose-fork` / `broken-ref` /
  `glossary-gap`) on every FAIL trial.

Doctor gains seven new rows in this batch: `14W [INTENT-OWNER]`,
`14X [MAXIM-OWNER]`, `14Y [INTENT-RECOVERY]`, `14Z [CORE-REF-PROSE]`,
`15A [WORKFLOW-STATE-VOCAB]`, `15B [ADR-CLOSURE]`, `15C [DEBT-CLOSURE]`.
The legacy `14W [FORK]` and `14X [FIRST-DAY]` rows are renumbered to
`15D [FORK]` and `15E [FIRST-DAY]` respectively to free the 14W/14X
slots; cross-references in §3 (hard blockers) and §4 (output tags) are
updated accordingly.

**Impact**: `semantic_impact=medium` — adds new doctor rows and a new
preflight reference file, but no new SSOT top-level area, no new STATUS
field owner, no new lifecycle skill, and no new high-impact stop-review
trigger. New rows fire as hard blockers only inside the active cycle's
slice scope (cycle-1 slice: as named by `protocol-upgrades.md`).
Outside the active slice they are WARN-only until promoted in a later
cycle.

**Review**: Self-review per `status-protocol.md §7.1`.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Architecture domain triad | `architecture/<domain>/README.md` (incl. legacy direct-child) | Confirm every domain README opens with `## Why` / `## 失败模式 (Failure Modes)` / `## 关闭条件 (Closing Conditions)` H2 sections, in that order, with positive content (not runtime-error rows). | Doctor `[INTENT-OWNER]` (14W) clean inside the slice scope. |
| Apex-maxim DISC ownership | `CLAUDE.md` / `AGENTS.md`, `development/discipline.md`, capability invariants | Confirm each apex maxim has exactly one SSOT owner; root file is reduced to one-line `[CORE-REF: ...]` link; non-owner DISC / capability / architecture refs are link-only. | Doctor `[MAXIM-OWNER]` (14X) clean inside the slice scope. |
| Cold-agent-sim 4-pillar regression | `skills/ssot-doctor/assets/cold-agent-sim/cycle-N.md` | Run cycle with the v2.43 harness; record per-pillar scores plus aggregate; group fails by `(pillar, miss_class)`. | Cycle gate passes (each pillar `≥ 5/8`, aggregate `≥ 24/32`, zero skill-fail rows). |
| Intent-recovery binding | `STATUS.md` coverage states, owners with `intent_recovery` annotation | Confirm every `covered` scope has `intent_recovery: covered` or `partial` (with Pending Capture) backed by the latest cycle report. | Doctor `[INTENT-RECOVERY]` (14Y) clean. |
| CORE-REF prose collapse | `architecture/README.md`, `architecture/<domain>/README.md`, `development/`, `product/` body files, CORE-REF startup files | Confirm apex repo invariants (Web-First, Single Writer, route-protocol-adapter, SdkAdapter-only, mission-only leaf, replay equivalence, core-call traceability) live as prose in exactly one SSOT owner; non-owners use one-line links plus `[CORE-REF: <owner_path#anchor>]`; CORE-REF holds at most a one-sentence summary. | Doctor `[CORE-REF-PROSE]` (14Z) clean inside the slice scope. |
| Canonical glossary vocabulary | `glossary/README.md` | Confirm workflow result codes, lifecycle states, agent-tier semantics, altitude vocabulary all have positive-definition entries or `<category>: not_applicable — <reason>` rows. | Doctor `[WORKFLOW-STATE-VOCAB]` (15A) clean. |
| ADR / debt closure fields | `decisions/`, `tech-debt/` | Confirm every pending/partial/diverged ADR and every active debt entry carries falsifiable `closure_condition` + `revisit_signal` YAML fields. | Doctor `[ADR-CLOSURE]` (15B) and `[DEBT-CLOSURE]` (15C) clean. |
| Bundle version sync | `VERSION`, `skills/ssot-preflight/SKILL.md` metadata | Confirm both equal `2.43`; rerun `tests/test-bundle-shape.sh`. | Bundle-shape test passes. |

**Doctor tags**:

- `[INTENT-OWNER]` (14W): architecture domain README missing the
  `## Why` / `## 失败模式 (Failure Modes)` /
  `## 关闭条件 (Closing Conditions)` H2 triad, or carries the heading
  with runtime-error prose instead of owner-doc recoverability content.
- `[MAXIM-OWNER]` (14X): an apex behavior maxim from a project root
  constraint file (e.g. `CLAUDE-MAXIM-N`) lacks a unique SSOT owner, or
  its body has been recopied into a non-owner DISC / capability /
  architecture file.
- `[INTENT-RECOVERY]` (14Y): a `covered` scope contains an owner whose
  `intent_recovery` is `gap`, stale relative to the latest cold-agent-sim
  cycle, or has unsatisfied pillars.
- `[CORE-REF-PROSE]` (14Z): an apex repo invariant body is maintained in
  ≥2 SSOT body locations, or CORE-REF and SSOT both maintain the body
  instead of one owner plus link-only mirror; also fires on
  `Capability → Surface registry` rows duplicated across architecture
  domain README ↔ product capability file ↔ `product/journeys/*.md`.
- `[WORKFLOW-STATE-VOCAB]` (15A): `glossary/` missing required
  canonical-vocabulary categories without an explicit `not_applicable`
  row.
- `[ADR-CLOSURE]` (15B): pending / partial / diverged ADR lacks
  falsifiable `closure_condition` + `revisit_signal` YAML.
- `[DEBT-CLOSURE]` (15C): active tech-debt entry lacks falsifiable
  `closure_condition` + `revisit_signal` YAML.

**No-op criteria**:

- Projects that have no apex behavior maxims in their root constraint
  file may record no-op for `[MAXIM-OWNER]` after confirming the absence.
- Projects with single-level lightweight architecture (per
  `architecture.md §11`) are exempt from the `[INTENT-OWNER]` triad
  until they exit lightweight mode.
- Projects whose `decisions/` or `tech-debt/` folders contain only
  `implemented` / `superseded` / `resolved` / `obsolete` entries do not
  need to add the closure fields to historical entries; only new or
  reopened entries land them.

**Not required**:

- Not required to retroactively add `intent_recovery` annotations to
  every owner before the first v2.43 cold-agent-sim cycle runs; the
  binding rule fires only on `covered` scopes once a cycle has been run
  and cited.
- Not required to migrate every existing CORE-REF mention into the new
  `[CORE-REF: <owner_path#anchor>]` syntax in one batch; the syntax is
  the target form, but inline updates may collapse forks per the
  knowledge-integrity demotion path.

#### v2.43 cycle-2 deltas (no version bump)

Cycle-2 of the intent-recoverability loop refines v2.43 in place; the
bundle protocol version remains `2.43`. Cycle-2 lens findings reshape
five surfaces:

- `[CORE-REF-PROSE]` (14Z) **scope broadened**: the prose-body location
  set now spans `glossary/`, `decisions/` (excluding the establishing
  ADR), `tech-debt/`, `bugs/`, `gotchas/`, `release/`, `testing/`
  alongside the original `architecture/`, `development/`, `product/`
  set; glossary entries restating an invariant in a verb-bearing cell
  fire 14Z. Doctor row 14Z and area-model `§2.0.1` carry a new
  `Worked example — legal vs. illegal restatement` block plus a
  `Legal vs. illegal glossary cell shape` example.
- `glossary/` **5th hard-list category**: when the consumer's root
  constraint file enumerates `*-MAXIM-N` / `*-RULE-N` rules,
  `glossary/README.md` must own a positively-defined `apex behavior
  maxim term` entry plus the rule→owner table (joint enforcement by
  doctor 14X `[MAXIM-OWNER]` and 15A `[WORKFLOW-STATE-VOCAB]`).
  area-model `§2.3.1` ships the recommended `glossary/README.md`
  skeleton (Owner block + H2-per-category + 3-column table).
- New doctor row **15F `[VOCAB-PROSE-FORK]`**: any non-glossary owner
  (`product/product-model.md`, `architecture/views/*`,
  `architecture/<domain>/README.md`, `development/discipline.md`)
  carrying canonical-vocab prose beyond a one-sentence angle +
  `[CORE-REF: glossary/README.md#<anchor>]` link is doctor-blocked.
  Row 15A's remediation column drops the duplicate-definition removal
  clause now owned by 15F.
- cold-agent-sim **§3 cycle gate** restated as ratio + absolute floor
  (`pillar_score ≥ 0.625` ratio, absolute passing-cell count ≥ 4) so
  the gate is unambiguous when `N/A` cells reduce a pillar denominator;
  **§2.1 trial budget cap** of 48 trials per cycle with priority-order
  skip rules (`product_truth` cross-cutting > `design_truth` cross-
  cutting > `product_intent` operational > `design_intent` operational);
  **§4 fail-row schema** retires the legacy `missing_evidence_kind`
  field — the new schema is `(commit_sha, pillar, hop_died_at,
  miss_class, expected_anchor_kind, actual_anchor_kind,
  proposed_fix_owner)` and consecutive cycles seeing the same
  `(pillar, miss_class)` pair auto-escalate the row from `doc-fail`
  to `skill-fail`; **§5 Results template** rewrites the per-cell row
  shape and adds per-pillar / miss-class distribution tables; **§5
  cycle-gate line** and **§6 Termination** drop the superseded flat-
  75% rule.
- `knowledge-integrity.md §1.1` adds the **multi-pillar rule**:
  `intent_recovery: covered` for an owner declaring
  `intent_recovery_pillars: [..]` with ≥ 2 pillars requires
  `verdict=PASS` in **every** declared pillar; partial coverage of
  declared pillars demotes to `partial` with a Pending Capture row.

**Cycle-2 deferred (consumer-side, not SKILL-side)**:

- discipline.md MAXIM-1 / MAXIM-2 owner blockquote-header
  normalisation, CLAUDE.md MAXIM-1..6 thinning to one-line `[CORE-REF:
  ...]` links, and the `apex-maxim-ownership` carried gap close — all
  three are consumer-execution findings, not SKILL-authoring findings;
  the SKILL surface is already complete on those axes (architecture.md
  §3 / §4 + intent-ownership.md §1 + doctor row 14X were authored in
  cycle-1).

#### v2.43 cycle-3 deltas (no version bump)

Cycle-3 of the intent-recoverability loop refines v2.43 in place; the
bundle protocol version remains `2.43`. Cycle-3 lens findings reshape
five surfaces:

- **Apex maxim registry, consumer side**: new
  `intent-ownership.md §1.1` ships the canonical 14X read anchor — a
  4-column table (Apex maxim | Slug | SSOT owner | Root-file link
  state) at `glossary/README.md`, `development/discipline.md` head
  matter, or `architecture/README.md` invariants. `not_yet_owned` rows
  are explicit, not silent. `architecture.md §4 Apex maxim indexing`
  ends with a one-line cross-reference. Doctor row `14X [MAXIM-OWNER]`
  rewritten to enumerate three firing cases (missing owner, missing or
  incomplete registry, non-owner body recopy) and explicitly disclaim
  root-constraint-file inline body as `[CORE-REF-PROSE]` (14Z)
  territory; example block expanded from one to three demarcated
  examples.
- **CORE-REF prose-fork wrapper pattern**: `area-model.md §2.0.1`
  gains a third illegal worked example covering wrapper restatement
  (`本域 contract 一句摘要` / `具体到本域的落地形态` /
  `domain-form restatement` / `本域如何承接`) where a secondary owner
  thinks "I'm describing this domain's implementation shape, not restating the
  invariant body`. Mechanical-test paragraph now states the wrappers
  do not exempt trailing verb clauses.
- **`glossary/` 6th hard-list category — concurrency-control
  vocabulary**: every named scheduling/concurrency identifier the
  consumer's apex docs reference as a noun (e.g. `workspace_path`,
  `project_limit`) needs a positively-defined entry with `path:LNN`
  evidence; consumers without named identifiers record
  `concurrency_control: not_applicable`.
- **Cold-agent-sim ratio formulation + new gate clauses**: §3
  cycle-gate restated as `ceil(0.625·denom)` per pillar plus aggregate
  ratio `≥ 0.75` (dropping the conflicting `absolute passing-cell
  count ≥ 4` clauses); §6 termination updated to match. New §1.5
  Owner-pillar coverage requirement computes the (owner,
  declared_pillar) coverage matrix before sample finalisation; new
  §1.6 Canonical-vocab spot-check adds 2 deterministic synthetic
  trials per cycle drawn from `glossary/README.md` plus apex-doc nouns
  absent from glossary, scored as a fifth `glossary_vocab` pillar with
  `2/2` floor (gate condition 7). New §3.2 Authoritative-owner check
  downgrades any `verdict=PASS` whose resolved file would be flagged
  by `15D [FORK]` or `14Z [CORE-REF-PROSE]` to `verdict=FAIL` with
  `miss_class=prose-fork`. §2.1 Pillar-roundtrip enforcement embeds
  `pillar_assigned` in trial prompts and adds `pillar-mismatch` row
  to the §3.1 miss-class taxonomy.
- **Lag-deferral clause + mandatory demotion**:
  `knowledge-integrity.md §1.1` gains a Lag-deferral clause allowing
  one cycle of `covered` + `intent_recovery: gap` coexistence when
  `tracked_skill_version < 2.43` and `coverage_result=in_progress`,
  capped at exactly one cycle; multi-pillar `partial` rule extended to
  recognise `pillar-not-applicable-to-cycle` deferrals. Doctor row
  `14Y [INTENT-RECOVERY]` body rewritten to make demotion mandatory
  ("MUST be auto-demoted") rather than conditional ("If ... demote"),
  and explicitly cites the lag-deferral clause as the only legitimate
  exception.

**Cycle-3 deferred (consumer-side, not SKILL-side)**:

- `SSOT/glossary/README.md` current/target/gap row staleness (claims
  `product-model.md` collapse is still pending when cycle-2 closure
  already landed it) and the actual `workspace_path` /
  `project_limit` glossary entries are consumer-execution findings.
  The SKILL surface (area-model §2.3 hard-list category 6, doctor row
  `15A [WORKFLOW-STATE-VOCAB]` joint gating) is now complete; the
  consumer must run an inline-update batch to land the rows under
  the scheduling/concurrency-vocabulary H2 plus the row-thinning
  correction.

### v2.42

**Upgrade goal**: tighten the cold-agent simulation harness §2 prompt template
so the cold agent stops drifting from "route to SSOT owner" into "validate
commit text against SSOT consensus" mode. The output schema goes from a 3-field
`{intent, hop1_path, hop2_anchor}` payload to a 6-field
`{intent, hop1_path, hop2_anchor, hops_used, verdict, reasoning}` payload, and
a new "Routing-only mandate" subsection in `cold-agent-sim.md §2` explicitly
defines `verdict=FAIL` as "cannot find an SSOT anchor for this intent within
the hop budget" (NOT "the commit appears unaligned with SSOT consensus").

**Impact**: `semantic_impact=medium` — the harness protocol clause is
tightened (no new SSOT top-level area, no new STATUS field, no new lifecycle
skill, no new high-impact stop-review trigger). Cycle-5 of the SSOT-SKILL ×
SSOT iterative loop runs the regression on the same 8 commits as cycle-4 with
the v2.42 prompt template to test whether schema-deviation drops below 10%
(cycle-3 + cycle-4 baseline ~25-30%).

**Drift catch-up**: this bump also fixes a pre-existing version drift —
`VERSION` had been pinned at `2.38` while `ssot-preflight/SKILL.md`
`metadata.protocol_version` advanced through `2.39 → 2.40 → 2.41` across
cycles 1–4 (bundle-shape test was passing only because VERSION matched its
own stale value). This bump aligns both files to `2.42`.

**Review**: Self-review per `status-protocol.md §7.1`.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Cold-agent prompt template | `skills/ssot-doctor/references/cold-agent-sim.md` §2 | Confirm 6-field output schema row + "Routing-only mandate" subsection are present and the harness header reads `(v2.42)`. | Cycle-5 trial prompts emit 6-field JSON; `verdict=FAIL` reasoning names a missing SSOT anchor type, not a commit-vs-SSOT critique. |
| Bundle version sync | `VERSION`, `skills/ssot-preflight/SKILL.md` metadata | Confirm both equal `2.42`; rerun `tests/test-bundle-shape.sh`. | Bundle-shape test passes the `protocol_version matches VERSION` and `current-upgrade current version heading count` rows. |
| Routed CAP record | `skills/ssot-audit/references/protocol-upgrades.md` | Confirm `CAP-20260619-02` row is `routed (cycle-5 phase 1; cold-agent-sim.md §2 v2.42 prompt-template clause now in force)`. | The CAP no longer shows `proposed`. |
| Cycle-5 evidence | `skills/ssot-doctor/assets/cold-agent-sim/cycle-5.md` | Confirm the regression report is committed before consumer projects bump `tracked_skill_version`. | Report shows pass-rate, schema-deviation %, and cycle-4-vs-cycle-5 delta. |

**Doctor tags**: no new tags. Tightening is local to `cold-agent-sim.md §2`
prompt-template wording and output schema; existing routing tags
(`[FORK]` 14W hard-blocker promoted in v2.41, `[SURFACE-PIN]` 14T leaf
enumeration promoted in v2.40) are unchanged.

### v2.38

**Upgrade goal**: add document lifecycle governance and make architecture
information architecture explicit. SSOT-external thick docs can remain outside
`SSOT/`, but root/core/docs Markdown must be inventoried, downgraded, or
audited as excluded. Product becomes the intent layer; architecture becomes the
implementation response layer. Architecture defaults to a Runtime Owner Map
instead of a universal domain checklist.

**Impact**: `semantic_impact=medium` (new semantic Doctor tags, version-gated
lint hard failures for source lifecycle shape, and template/routing
clarification; no new SSOT top-level area, STATUS field owner, lifecycle skill,
or high-impact stop-review trigger).

**Review**: Self-review per `status-protocol.md §7.1`.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Source inventory | `STATUS.md`, root Markdown, `docs/**/*.md` | Check whether each root/core/docs Markdown file has a lifecycle header, a source inventory row, or an audited exclusion. | No SSOT-external thick doc can masquerade as current authority. |
| Working/historical downgrade | working, historical, external, public-thin docs | Check for authority, owner, absorbed target, do-not-use boundary, and review date. | Strong current-fact language has `absorbed_to`, `do_not_use_for`, and owner pointers. |
| Product/architecture boundary | `product/`, `architecture/`, source routing | Check whether product owns intent and architecture owns implementation response. | Product capability docs stay thin; architecture links product owners instead of redefining product facts. |
| Runtime Owner Map | architecture root/views/domains | Check whether root routes runtime owners and invariants, views are cross-owner, and domains own state/contracts/lifecycle/failure/verification. | Architecture is readable as a runtime owner map, not a universal 20-section checklist. |
| Lint/Doctor behavior | `ssot-lint.sh`, Doctor output | Run lint after waterline update and inspect new v2.38 tags. | Deterministic failures catch missing inventory/header/exclusion; semantic drift remains reviewer-confirmed. |

**Doctor tags**:

- `[SOURCE-INVENTORY]`: root public Markdown or `docs/**/*.md` lacks lifecycle
  inventory, in-file header, or audited exclusion.
- `[SOURCE-LIFECYCLE]`: working/historical/external material carries strong
  current-fact language without downgrade fields.
- `[SOURCE-EXCLUSION]`: audited exclusion row is missing required shape.
- `[THIN-DOCS]`: public thin docs lack a named SSOT owner or carry independent
  long-lived facts.
- `[PRODUCT-ARCH-DRIFT]`: product/architecture boundary drift.
- `[ARCH-CHECKLIST-HEAVY]`: architecture owner looks like a universal checklist
  instead of a Runtime Owner Map.

**No-op criteria**:

- Projects with no root public Markdown or `docs/` tree may record no-op for
  source inventory after confirming the absence.
- Projects whose docs already have complete lifecycle headers or STATUS
  inventory rows do not need per-file rewrites.
- Existing architecture may record a non-blocking gap instead of immediate
  rewrite when the current task is a protocol upgrade and the owner map
  migration is out of scope.

**Not required**:

- Not required to move every thick doc into `SSOT/`.
- Not required to rewrite every consumer `product/` or `architecture/` owner in
  the same batch.
- Not required to create a new top-level docs or design area.

### v2.37

**Upgrade goal**: make the KISS rule operational inside SSOT-SKILL itself.
Protocol references now lead with prose decision paths, bootstrap templates
default to thin registers, architecture rules define a small required mental
model before optional appendices, and protocol-upgrade history moves out of the
default read path into current + archive layers.

**Impact**: `semantic_impact=medium` (audit/read-routing and template-pressure
clarification; no new SSOT top-level area, STATUS field, lifecycle skill, or
high-impact stop-review trigger).

**Review**: Self-review per `status-protocol.md §7.1`.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| STATUS register path | `STATUS.md` and bootstrap STATUS templates | Check whether STATUS readers can understand the five registers before reading schema details. | STATUS keeps pointer-sized cells; table schemas are lookup material, not the first operating path. |
| Closeout routing path | `$ssot-closeout` usage and local SSOT maintenance docs | Check whether update routing starts from source type, owner, and cascade decision rather than forcing row-by-row table lookup. | Agents can route ordinary diffs/conversation signals through the decision path; full tables remain fallback reference. |
| Bootstrap template pressure | New `.bootstrap/` files and freshly instantiated STATUS templates | Check whether default templates ask only for state, owner/session, result/gate, next blocker, and short evidence pointers. | Complex matrices appear only in optional appendix blocks when the repo actually needs them. |
| Protocol ledger layering | `$ssot-audit` protocol drift flow | Check whether current/recent upgrades are readable without loading the whole historical ledger, and whether older versions remain reachable. | `protocol-upgrades.md` routes; `current-upgrade.md` covers current/recent versions; archive index covers every historical version. |
| Architecture KISS tiering | `architecture/` root/views/domains | Check whether architecture first supplies mental model, owner boundary, and evidence direction; optional diagrams/tables only expand when triggered by real complexity. | Root/domain docs are not forced to carry empty conditional sections or diagram matrices for non-applicable concerns. |

**Doctor tags**:

- Reuse `[KISS]`, `[KISS-TABLE-DENSITY]`, `[READABILITY]`,
  `[READER-MAP]`, and `[OWNER-ANCHOR]`. v2.37 adds no new Doctor tag.

**No-op criteria**:

- Projects whose `STATUS.md`, architecture owners, and `.bootstrap/` artifacts
  already follow prose-first/register-only KISS may record no-op.
- Existing completed bootstrap artifacts do not need to be recreated.
- Projects already at `2.36` only need to check for local references that assume
  the protocol ledger is one giant file.

**Not required**:

- Not required to delete useful tables.
- Not required to rewrite every existing SSOT owner immediately.
- Not required to create archive files inside consumer repositories.

### v2.36

**Upgrade goal**: make KISS the permanent SSOT design principle. SSOT should
let a cold reader get the shortest useful mental model first, then use tables
as indexes or registers. A table is not wrong by itself; a document is wrong
when the reader must reconstruct the explanation from rows, or when a register
cell carries paragraph reasoning, command output, copied checklists, or
proof-of-work transcripts.

**Impact**: `semantic_impact=medium` (new semantic Doctor tag and WARN-only
lint heuristic; no new top-level area, STATUS field, lifecycle skill, or
high-impact stop-review trigger).

**Review**: Self-review per `status-protocol.md §7.1`.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| KISS mental model | user-facing SSOT owner files, especially `architecture/` root/views/domains | Check whether prose explains the system before tables and whether the main story can be understood without row-by-row reconstruction. | Owner starts with the mental model; tables serve route/comparison/evidence lookup only. |
| Register-only rows | `STATUS.md`, `.bootstrap/`, stop-review surfaces, CAP rows, promotion blocks | Check whether cells hold only state/owner/date/result/evidence pointer and not paragraph reasoning, command output, copied checklist, or transcript. | Registers carry conclusions and pointers; narrative/evidence lives in the authorized owner or artifact. |
| Template pressure | instantiated SSOT from bootstrap templates | Check whether templates have pushed agents into table-first writing, especially architecture domain sections and STATUS. | Table-heavy template sections have prose-first placeholders or explicit register-only notes. |
| Lint visibility | `ssot-lint.sh` output | Run lint and inspect `[KISS-TABLE-DENSITY]` WARNs; do not treat WARN-only heuristics as semantic proof. | True positives are routed to owner rewrites; justified indexes/registers may remain. |

**Doctor tags**:

- `[KISS]`: an SSOT owner is technically structured but not simple to read:
  tables carry the main explanation, duplicate sections restate the same fact,
  or a register carries paragraph reasoning/checklists instead of pointers.
- `[KISS-TABLE-DENSITY]`: a deterministic table-density heuristic found a
  likely table-first document. It is a triage signal, not proof.

**No-op criteria**:

- Projects whose SSOT owners already explain the mental model in prose and use
  tables only as route/evidence indexes may record no-op.
- Index-like files such as Reader Maps, diagram indexes, source-material
  absorption, and STATUS registers may keep tables when rows stay pointer-sized.
- Historical files do not need a one-shot rewrite unless they are active owner
  surfaces for current tasks.

**Not required**:

- Not required to delete all tables.
- Not required to rewrite every architecture domain immediately.
- Not required to make lint WARNs fail CI; `--strict` remains opt-in.

### v2.35

**Upgrade goal**: make SSOT readable as an action surface, not only as a fact
archive. A future agent should be able to land on an owner or entry and answer:
when do I read this, what current truth does it own, where do I inspect first,
what must I avoid, and what minimal verification/evidence closes the loop?

**Impact**: `semantic_impact=medium` (new semantic Doctor tag and WARN-only lint
heuristics; no new top-level area, STATUS field, lifecycle skill, or high-impact
stop-review trigger).

**Review**: Self-review per `status-protocol.md §7.1`.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Agent actionability | user-facing SSOT owner files | Check whether the reader can identify trigger, current owner truth, first inspection points, do-not-do boundaries, and minimal verification/evidence without reconstructing the whole history. | Owner files and high-risk entries expose enough action surface for a future agent to act without reverse-engineering from ledgers. |
| Bug/debt quick entry | `bugs/[0-9]*.md`, `tech-debt/[0-9]*.md` | For high-impact, active, recurred, or major entries, check whether the file starts with a compact quick entry: symptom/trigger, first checks, do-not-do, minimal verification, current status/evidence pointer. | A future agent modifying related code can see the failure signature and prevention path before reading the post-mortem body. |
| Stop-review ledger boundary | `STATUS.md` stop-review fields | Check whether `last_stop_review`, stop-review gate rows, or summary fields contain full batch transcripts, command ledgers, or long proof-of-work text. | STATUS carries the conclusion, reviewer, date/session/commit, and owner links; detailed evidence stays in final response, commit/release note, CI artifact, bug entry, or the authorized stop-review evidence block. |
| Readability heuristics | all SSOT Markdown | Run lint and inspect `[READABILITY-LONG-LINE]`, `[ENTRY-ACTIONABILITY]`, and `[STATUS-STOP-REVIEW-LEDGER]` WARNs. | True positives are routed to owners; false positives may be documented, but WARNs are not semantic proof by themselves. |

**Doctor tags**:

- `[ACTIONABILITY]`: an SSOT entry is technically present but does not help a
  future agent decide when to read it, where to inspect first, what not to do,
  or how to verify closure.
- `[ENTRY-ACTIONABILITY]`: a numbered bug or tech-debt entry lacks a compact
  quick-entry surface for symptom/trigger, first checks, do-not-do, minimal
  verification, or current status/evidence.
- `[STATUS-STOP-REVIEW-LEDGER]`: `STATUS.md` stop-review fields carry full
  proof-of-work or batch transcript content instead of a conclusion plus
  pointers.
- `[READABILITY-LONG-LINE]`: a deterministic readability heuristic found a very
  long Markdown line that likely hides paragraph content inside a table cell or
  compressed note.

**No-op criteria**:

- Projects whose owner files already expose trigger, owner truth, first checks,
  non-goals, and verification guidance may record no-op.
- Minor bug/debt rows that are intentionally kept only in an index do not need
  full quick-entry bodies unless they recur, escalate, or expose a prevention
  rule.
- A short stop-review pointer in `STATUS.md` is enough when detailed evidence is
  already preserved in an authorized owner.

**Not required**:

- Not required to rewrite every historical entry immediately.
- Not required to create a new top-level `playbook/`, `runbook/`, or
  `agent-guide/` area.
- Not required to make the WARN heuristics fail CI unless the project opts into
  `--strict`.
