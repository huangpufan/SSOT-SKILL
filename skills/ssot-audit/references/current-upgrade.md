# Current Protocol Upgrade

This file holds the current protocol entry and the nearest recent standalone
entries. If a project already has `tracked_skill_version >= 2.35`, this file is
the only upgrade ledger the audit needs to read.

For older or missing tracking baselines, start at [`protocol-upgrades.md`](protocol-upgrades.md)
and follow [`archive/index.md`](archive/index.md) to load only the needed range
files.

## Version Ledger

### v2.64

**Upgrade goal**: give the project's rules a human adjudication boundary.
Until v2.64 the protocol could say *where* an invariant lives (one owner,
`[CORE-REF]` mirrors) but could not answer *who may change it*. Review of
real consumer SSOTs showed the failure mode repeatedly: invariants existed
as embedded prose without IDs, the same red line was restated in the root
constraint file, the architecture root, and domain READMEs with no
designated owner, and nothing marked which rules an agent must not rewrite
on its own — so "stop and escalate" language was the only guard. v2.64
adds one canonical register — `SSOT/README.md ## 裁决边界` /
`## Adjudication boundary` — that turns the adjudication boundary itself
into enumerable, checkable data, and folds the standalone apex-maxim
registry into it.

1. **One register, four kinds** (`intent-ownership.md §6`). The table
   registers only rules whose meaning an agent must not change unaided:
   `arch-invariant`, `product-promise`, `process-rule` rows (`INV-NN`
   IDs), and `apex-maxim` rows (`CLAUDE-MAXIM-N` / `CORE-RULE-N`). Each
   row is pointer-sized: one-line rule name, one resolving
   `path#anchor` owner link, `Established by` (`DEC-NNNN`,
   `user-directive`, or `bootstrap`), and a closed `State` enum —
   `confirmed`/`candidate` for `INV-` rows, `core-ref-thin`/`inline-body`/
   `not_yet_owned` for maxims.
2. **Agent edits the constrained, not the constraint.** A registered rule
   does not freeze implementation: the agent may modify the code, docs,
   and tests the rule governs, but changing the rule's meaning, scope, or
   state requires a `decisions/` entry or an explicit user directive.
   When implementation reality contradicts a confirmed rule the agent
   files `ADJ-` under `STATUS.md ## Open Adjudications` — it does not
   silently rewrite the rule or silently bend the code around it.
3. **Candidate is a proposal, confirmed is a boundary.** Agents may
   register rows as `candidate`; only a human decision or explicit user
   directive flips a row to `confirmed`. Confirmed rows bind; candidate
   rows are visible strong defaults. This is the register's growth path:
   closeout promotes rule-shaped conclusions (an ADR's binding
   constraint, a repeated bug pattern now treated as a red line, a
   user-locked product promise) in as candidates per
   `update-routing.md §1.7`.
4. **Body-tag symmetry.** A `confirmed`/`core-ref-thin` row's owner body
   leads the rule with its registry ID (`**INV-03**`, `CLAUDE-MAXIM-2`),
   and every body tag must resolve back to exactly one row. Domain-local
   invariants stay ordinary prose — the register is a silent-violation
   register, not an importance index; the soft ceiling is ~25 rows. When
   nothing qualifies, the section keeps one reasoned empty note rather
   than fabricated rows.
5. **Supersedes the standalone apex-maxim registry.** At ≥2.64 the
   `CLAUDE-MAXIM-N`/`CORE-RULE-N` register moves into the adjudication
   boundary as `apex-maxim` rows; the §1.1 standalone registry remains
   the contract below v2.64. `MAXIM-OWNER` (14X) checks the unified
   register at the new baseline.
6. **Enforcement, not convention.** `[INV-REGISTRY]` (semantic doctor row
   16E) validates the section, unique IDs, closed enums, establishing
   authority, and single resolving owner link; `[INV-BODY]` (16F) checks
   registry↔body tag symmetry and warns on orphan body tags. Preflight
   adds a boundary gate: tasks touching registered-rule behavior read the
   rule owner first and know which claims they may not rewrite.

**Impact**: `semantic_impact=medium` — one new canonical section in
`SSOT/README.md`, a preflight gate, a closeout promotion duty, two doctor
rows, and a registry migration for consumers that already ship a §1.1
apex-maxim registry. No area added, no claim semantics changed;
pre-2.64 consumers are unaffected and keep the standalone maxim registry
contract.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Boundary section exists | `SSOT/README.md` | Add `## 裁决边界` / `## Adjudication boundary` with the six-column schema; when nothing qualifies, one reasoned empty note. | Section present; `[INV-REGISTRY]` clean. |
| Maxims migrated | `CLAUDE-MAXIM-N`/`CORE-RULE-N` rules | Move the standalone apex-maxim registry rows into `apex-maxim` rows; keep `not_yet_owned` for unresolved maxims. | Every named maxim has exactly one row; old standalone table removed. |
| Invariants registered | root constraint file, architecture root, product promises | Register only cross-task red lines — repository-wide invariants, human-established process rules, user-confirmed product promises — as `INV-NN` rows; leave domain-local rules as prose. | Rows ≤ ~25; each `Established by` resolves. |
| Body tags | owner documents of confirmed rows | Tag each confirmed/core-ref-thin rule's body with its registry ID at the rule anchor. | `[INV-BODY]` clean — no orphan tags, no untagged confirmed rows. |
| Candidate honesty | `State` column | Rows inferred by an agent stay `candidate`; only DEC/user-directive-established rules are `confirmed`. | No agent-self-confirmed row without authority. |

**Migration notes**:

- The register's primary harvest is the existing root constraint file
  (`CLAUDE.md`/`AGENTS.md` rules), binding `decisions/` entries, and
  confirmed product promises in `prd.md`/`product-model.md` — the same
  sources bootstrap seeds from. Do not bulk-register every invariant
  mention; altitude calls follow `promotion-rationale.md`.
- A consumer that already ships a §1.1 apex-maxim registry (e.g. in
  `glossary/README.md`) migrates those rows into the unified table and
  deletes the standalone section; a consumer with no maxims and no
  qualifying invariants keeps the section with the reasoned empty note.
- `ssot-lint`/`ssot-migrate` do not yet auto-generate rows; the audit
  performs the harvest and doctor validates the result.
- Frozen consumers (lifecycle frozen by local instruction) do not take
  the section until their freeze is lifted; note the deferral in the
  audit report rather than editing a frozen tree.


### v2.63

**Upgrade goal**: separate write provenance from coverage state. Until v2.63
`STATUS.md` was asked to answer two different questions — *what is covered
now* and *who wrote what, when* — and could only answer the first. Audits
reconstructed batch history from commit archaeology; a substantive closeout
that found nothing durable was indistinguishable from a closeout that never
ran. v2.63 adds a sibling register: `SSOT/HISTORY.md`, an append-only batch
write log, so the second question gets a first-class, machine-readable
answer.

1. **One row per writing-skill batch** (`update-routing.md §1.6`). Every
   substantive batch that runs bootstrap/closeout/audit/doctor on a consumer
   SSOT appends exactly one row to `SSOT/HISTORY.md`: `| Date | Commit |
   Actor | Result | Touched | Note |`. `Result` is `wrote` or `no-op` — a
   substantive no-op still logs, which is what distinguishes "checked,
   nothing durable" from "never checked". Trivial preflight-exempt work
   appends nothing.
2. **Append-only by contract.** Rows are never edited, reordered, or
   deleted; an erroneous row is corrected by a later row. This is
   convention plus git history — lint checks the row schema, not the
   log's immutability, which is what version control already guarantees.
3. **Provenance only, never a shadow ledger.** Rows carry pointers (touched
   SSOT-relative paths, batch slug, audit range) — never restated facts,
   decisions, or status reasons. Those stay in their proper owners; the
   moment a row starts carrying content it becomes a second STATUS and
   the one-fact-one-owner rule is broken.
4. **Bootstrap and audit wire in.** Bootstrap creates `HISTORY.md`
   header-only during skeleton creation and appends its first
   `wrote: skeleton` row when the batch completes. Commit and conversation
   audit read HISTORY as coverage evidence — a row in range means a
   writing skill already reconciled that batch — and append their own
   row per completed segment with the covered range in Note.
5. **Schema-enforced, version-gated** (`[HISTORY-LOG]`). Lint validates the
   exact header, six-cell rows, ISO dates, known Actor/Result vocabulary,
   monotonic date order, `no-op`↔`none` consistency, and pointer-sized
   cells — gated on `tracked_skill_version >= 2.63`. Missing file at
   2.63+ is WARN (the next writing batch creates it); malformed schema is
   FAIL. `ssot-migrate.py` creates the header for consumers upgrading.

**Impact**: `semantic_impact=low` — one new register file, one new lint
tag, a batch-close obligation for writing skills. No removed columns, no
new area, no changed claim semantics; pre-2.63 consumers are unaffected
and upgrading consumers get the file from `ssot-migrate.py` or their next
writing batch. HISTORY is a register: `reader-quality.md` exempts it from
prose-body floors alongside `STATUS.md`.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| History file exists | `SSOT/HISTORY.md` | Create from `ssot-bootstrap` `history.md` template (or run `ssot-migrate.py`) if absent. | File exists with the exact six-column header. |
| Batch rows | `SSOT/HISTORY.md` rows | Append one row per substantive writing batch going forward; no backfill required. | Every post-upgrade batch leaves exactly one row. |
| Row schema | `SSOT/HISTORY.md` rows | Keep rows to the six-cell contract; correct bad rows by appending, never editing. | `[HISTORY-LOG]` clean. |
| Ownership boundary | `SSOT/HISTORY.md` vs `STATUS.md` | Keep facts/decisions/reasons in owners; HISTORY carries pointers only. | No row restates a durable fact or status reason. |

**Migration notes**:

- `ssot-migrate.py` creates `SSOT/HISTORY.md` (header only) when absent —
  same run that fixes legacy schemas; `--dry-run` reports without writing.
- Consumers below v2.63 are unaffected: `[HISTORY-LOG]` gates on
  `tracked_skill_version >= 2.63`, and a 2.63+ consumer missing the file
  gets WARN, not FAIL — the next writing batch creates it from the
  bootstrap template.
- Audit treats HISTORY as evidence, not exemption: a `wrote`/`no-op` row
  in the tracked range shows a writing skill ran; audit still reviews the
  underlying diff for semantic correctness.

### v2.62

**Upgrade goal**: make every durable claim *bound* — to a resolvable reference,
a registered blocker check, a reviewed baseline, and a reproducible artifact —
and close the two behavioral leaks a transcript study of real consumers
surfaced: verification that stops at proxy evidence, and batches that end in a
dirty worktree. v2.61 added honest intermediate states (`partial`,
re-confirmation); v2.62 adds the discipline that keeps claims, ledgers, and
evidence from drifting apart afterward.

1. **Two ledgers, one truth** (`[LEDGER-CONSISTENCY]`). The Area Status
   register and per-file `intent_recovery:` stamps describe the same coverage
   and were allowed to contradict: real consumers shipped files stamped
   `covered` under areas the register calls `gap`. A `covered` stamp under a
   `gap`/`stale`/`unknown`/`conflict` area is now a hard contradiction —
   demote the stamp or earn the area claim; `partial` under a weak area warns.
2. **Registered blockers constrain claims** (`[GAP-BLOCK]`). An Open Gaps row's
   Blocking/retrigger cell is now a machine-readable contract: when it names a
   protocol claim (`converged`, `covered`, `tracked_*`), that claim cannot be
   live while the row is open. A consumer had exactly this contradiction —
   an open blocker on `converged` beside `coverage_result: converged`.
3. **Baselines are reviewed claims** (`[BASELINE-REVIEW]`). Each live
   `tracked_commit`/`tracked_session`/`tracked_skill_version` must have a Stop
   Review Gate row naming that field; a baseline that moved without one asserts
   a review nobody performed. WARN-only.
4. **Content referentiality** (`[REF-RESOLVE]`). Inline-code repo references
   (`path`, `path:NN`, `path::symbol`) in SSOT bodies must resolve; dead pins
   keep teaching deleted runtimes. `retired:`/`historical:`/`deleted:` markers
   exempt intentional history. Prefer `path::symbol` over line numbers.
   WARN-only; the writing rule lives in reader-quality.md §2 floor item 6.
5. **Artifact-bound protocol identity** (`[SKILL-VERSION-BINDING]`).
   `tracked_skill_version` attests to a reproducible artifact in the checkout —
   not an installed-but-dirty worktree. FAIL when the claim outruns every
   installed/pinned artifact; WARN when the artifact is newer than the claim.
6. **Auditable re-confirmation** (`[RECONFIRM-TOKEN]`). `re-confirmed at`
   tokens must carry `on YYYY-MM-DD` and, when naming a commit, be on this
   branch's history — self-attested tokens must be checkable after the fact.
7. **Evidence durability** (`[EPHEMERAL-EVIDENCE]`). STATUS cells and
   `.bootstrap/` artifacts must not point at `/tmp` or per-user caches;
   evidence lives in the repo or carries a content hash. WARN-only.
8. **Git visibility** (`[GIT-TRACKED]`). An SSOT file git cannot see cannot be
   reviewed or shipped. Canonical names like `release/` collide with common
   build-output ignore rules — new files were silently dropped by `git add`
   in a real consumer. WARN-only.
9. **Supersession links** (`[SUPERSEDE-LINK]`). Records marked `superseded`/
   `deprecated`/`retracted` must name a successor (`superseded_by:` frontmatter
   or explicit body link); a superseded record without one is a dead end.
   WARN-only.
10. **Verification layer and worktree boundary** (behavioral, closeout).
    `update-routing.md §1.5` adds two closeout obligations: classify each
    user-visible claim as `user-path`/`proxy`/`unexercised` and route
    unexercised paths to a durable owner (installed+unit+screenshot is not a
    user-journey proof); and end every substantive batch committed or with a
    visible named reason — a dirty worktree is the next batch's contamination.
11. **Schema migration is a first-class route.** Legacy lean STATUS schemas
    (5–6-column Open Gaps etc.) previously hard-failed dozens of per-row checks
    that only restated one migration debt. Per-row actionability checks now
    run only against the canonical schema; a non-canonical table gets one
    migration WARN pointing at `ssot-migrate.py`, which upgrades lean STATUS
    tables and backfills record frontmatter in place.

**Impact**: `semantic_impact=medium` — new lint tags and closeout obligations,
no removed columns, no new top-level area, no new mandatory field, no new
stop-review trigger. New FAILs (`LEDGER-CONSISTENCY`, `GAP-BLOCK`,
`SKILL-VERSION-BINDING`, off-branch `RECONFIRM-TOKEN`) fire only on genuine
contradictions; the rest are WARN. Consumers on legacy schemas get a migration
route instead of permanent red.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Ledger consistency | File `intent_recovery:` stamps vs `## Area Status` | Walk each `covered`/`partial` stamp under a weak area row; demote the stamp or earn the area claim. | No `covered` stamp sits under a `gap`/`stale`/`unknown`/`conflict` area. |
| Registered blockers | `## Open Gaps` Blocking cells vs live claims | Name blocked claim tokens in Blocking cells; drop claims that open rows forbid. | No open row blocking `converged`/`covered`/`tracked_*` coexists with that claim live. |
| Baseline review | `## Event-Source Coverage` + `## Stop Review Gate` | Add a gate row naming each live baseline field it authorised. | Each `tracked_*` field with a live value is named by a gate row. |
| Reference integrity | SSOT body inline-code paths | Resolve or mark `historical:`/`retired:`/`deleted:`; prefer `path::symbol`. | No unmarked dead reference remains in a body. |
| Version binding | `tracked_skill_version` vs installed artifacts | Install the claimed artifact or lower the claim to what a fresh clone sees. | Claim ≤ newest reproducible artifact in checkout. |
| Evidence durability | STATUS cells, `.bootstrap/` artifacts | Replace `/tmp`/cache paths with in-repo artifacts or content hashes. | No evidence pointer decays on a fresh checkout. |
| Git visibility | SSOT files vs `.gitignore` | Add negation rules for ignored SSOT paths (e.g. `release/`); commit untracked files. | `git check-ignore`/`ls-files` clean for every SSOT file. |
| Supersession links | `decisions/`, `research/`, `tech-debt/`, `bugs/` records | Add `superseded_by:` (or body link) to every superseded record. | No dead-end superseded record. |
| Verification layer | Closeout behavior (§1.5) | Classify each user-visible claim `user-path`/`proxy`/`unexercised`; route unexercised paths to a testing/STATUS gap. | No done-claim rests silently on proxy evidence for an unexercised user path. |
| Worktree boundary | Closeout behavior (§1.5) | End each substantive batch committed, or record owner+reason where the next agent sees it. | No unexplained dirty-tree handoff. |
| Schema migration | Lean legacy STATUS/record schemas | Run `ssot-migrate.py` to reach the canonical schema, then re-lint. | Canonical-schema checks replace the migration WARN. |

**Migration notes**:

- `skills/ssot-doctor/assets/scripts/ssot-migrate.py` rewrites lean STATUS
  tables (e.g. 5–6-column Open Gaps) into the canonical Appendix-A schema in
  place, preserving row content into the closest canonical columns, and can
  backfill missing record frontmatter keys. Run it before treating exact-schema
  FAILs as content defects; `--dry-run` prints the planned rewrite.
- Consumers below v2.62 are unaffected: all new checks gate on
  `tracked_skill_version >= 2.60` (or `2.61` for RECONFIRM-TOKEN) and the
  legacy-schema WARN appears only where the canonical gate cannot run.
- The verification-layer and worktree-boundary rules are closeout obligations,
  not lint gates — they change what a done-claim must disclose, not what lint
  counts.

### v2.61

**Upgrade goal**: close the four structural gaps a multi-dimensional review of a
real consumer surfaced, with the smallest possible machinery. The protocol
already had every atom; the gaps came from atoms wired to the wrong grain
(all-or-nothing), the wrong surface (README prose instead of STATUS), or left
unenforced at the gate. v2.61 rewires each atom to its correct grain and stops
there, deliberately declining federation, ladders, and arbitrary-depth recursion
as unproven complexity.

1. **Graduated coverage / on-ramp.** `covered` was all-or-nothing at full v2.60
   rigor, so consumers with strong content stalled at all-`gap`. v2.61 admits
   `partial` as a first-class Area Status value: honest partial credit that
   claims the content is real and readable while disclaiming the independent
   verification `covered` adds. `partial` requires the owner `README.md`, the
   shared writing floor, Doctor L1 clean, and a scoped self-review
   (`authorises=area:<scope>:partial`) — never the six-task cold review, 16-leaf
   score, §7.7 artifact, or independent review. It is a floor, not a ceiling;
   `covered`/`converged` semantics are unchanged, and the v2.60 review blockers
   now gate `covered` only, not `partial`.
2. **Freshness floor.** `tracked_commit`/`tracked_session` drift previously had
   no hard gate, so achieved coverage rotted silently. v2.61 adds a *conditional*
   freshness floor: it binds only where a coverage claim exists (any area
   `covered`/`partial`, or `coverage_result: converged`). A claim whose reviewed
   baseline is behind `HEAD` and not re-confirmed by a same-task scoped
   self-review demotes to `stale`. Honest `in_progress`/`bootstrap`/
   `catching_up` repos owe no freshness proof. Lint FAILs at `converged` when
   `tracked_commit` is not ancestor-or-equal of `HEAD`, and only WARNs below.
3. **Single-owner (the protocol applied to itself).** Two forks are closed.
   The CAP-row eight-column schema is now owned solely by
   `status-protocol.md §8 Appendix A`; `promotion-rationale.md` keeps only the
   move/rationale semantics and demotes `altitude_guess`/`signal_source` to cell
   content. `architecture.md §3` is declared the sole normative owner of "what a
   domain owns"; `reader-quality.md §4` (acceptance rubric) and
   `area-model.md §2.2` (area role) now derive and link instead of restating.
4. **Large-repo coverage.** The single global `coverage_result` plus 17 flat
   Area rows could not represent per-scope coverage. v2.61 makes the Area Status
   table optionally two-dimensional: opt-in scoped `<area>/<scope>` rows and an
   optional `Coverage depth` column (reusing `deep`/`sampled`/`inferred`/
   `unknown` from `architecture.md §10`). The 17-row baseline stays mandatory and
   is the honest computed roll-up of its scoped children (a `gap`/`stale`/
   `unknown`/`conflict` child blocks a parent `covered`/`partial` claim; baseline
   depth is the weakest child depth), enforced via `[STATUS-AGGREGATE]`.
   Recursion caps at one level; single-tenant repos keep the 3-column form
   unchanged.

**Impact**: `semantic_impact=medium` — additive and opt-in throughout. No STATUS
or artifact schema column is removed or retyped, no new top-level area, no new
mandatory field, no new stop-review trigger (scoped rows reuse the existing
per-scope covered trigger). A consumer below v2.61 is unaffected: the 3-column,
17-row, single-`coverage_result` STATUS remains valid, `partial` is opt-in, and
the freshness floor only hard-fails at `converged`.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Graduated `partial` | `STATUS.md ## Area Status`, Stop Review Gate | Where content is strong but the full review has not passed, flip the area from `gap` to `partial` with a scoped self-review; do not leave it reading as all-gap. | `partial` claims have owner README + L1 clean + a scoped self-review row; the v2.60 review blockers no longer demote `partial`; `coverage_result` stays `in_progress` until every applicable area is `covered`. |
| Freshness floor | Preflight gate, Doctor L2 `COVERAGE-FRESHNESS`, lint | Re-confirm or demote any `covered`/`partial`/`converged` claim whose reviewed baseline is behind `HEAD`. | No `covered`/`partial` claim sits on a stale baseline without a later scoped self-review; lint FAILs a `converged` STATUS whose `tracked_commit` is not ancestor-or-equal of `HEAD`. |
| CAP-schema single owner | `STATUS.md ## Pending Captures`, closeout routing | Write CAP rows only against the `status-protocol.md §8 Appendix A` 8-column schema; treat `altitude_guess`/`signal_source` as cell content, not columns. | No consumer or bundle file emits the retired `captured_at/about/altitude_guess/rule/evidence/signal_source` column set. |
| Domain-ownership single owner | Architecture reference docs | Take the "what a domain owns" list from `architecture.md §3`; let the acceptance rubric and area role derive and link. | No forked ownership enumeration remains across `architecture.md`, `reader-quality.md`, and `area-model.md`. |
| Scoped coverage & depth (opt-in) | `STATUS.md ## Area Status` (large repos) | Decompose a large area into scoped `<area>/<scope>` rows and/or add the `Coverage depth` column; keep the baseline rows as the computed roll-up. | Scoped rows carry their own Status/depth; a weak child honestly blocks the parent; `[STATUS-AGGREGATE]` fires on any parent over-claim; single-tenant repos are byte-unchanged. |

**Migration notes**:

- Every change is additive/opt-in. A consumer tracking `< 2.61` needs no action;
  advancing the baseline is a declaration, not a rewrite.
- A consumer stalled at all-`gap` with strong content can, in one pass, flip
  each content-strong area to `partial` with a scoped self-review — no six-task
  review required — and immediately stop reading as "all-gap", then advance to
  `covered` area-by-area as the full review passes.
- The roll-up uses the existing asymmetric aggregation algebra (as in
  `process`/`records`), not a new total order: a weak scoped child blocks a
  parent `covered`/`partial` claim, and the parent depth is its weakest child.
- The old CAP columns map losslessly into the Appendix-A cells (`rule` →
  `Reason`; `signal_source`/`altitude_guess` → `Priority / trigger` content).
- Federation, sub-SSOT roots, hierarchical scope trees, multi-writer
  concurrency, and a relaxed 4-hop budget are explicitly deferred as unproven
  complexity; revisit only with evidence from a real large consumer.
- A real cold-read exercise confirmed v2.61 makes a *single-team,
  single-level-decomposable* large repo usable (one exercised at ~40k words,
  single writer, 40 logical domains), with the mechanism agreeing across all
  three surfaces (the `status-protocol.md §3` scoped-row contract, the lint
  roll-up arithmetic, and the status-template guidance). It also confirmed the
  remaining structural ceiling: a *genuinely giant monorepo* — many teams
  concurrently writing one `STATUS.md`, domains nested three deep, 100k+ words
  needing multiple routing tiers — is still out of reach. The root cause is the
  single-file single-writer STATUS model versus scoped multi-team write
  ownership; recursion capping at one level (`status-protocol.md` physically
  forbids a second slash) cannot express domain-within-domain coverage
  layering, and the 4-hop budget is structurally insufficient for deeply buried
  owners. The highest-leverage follow-up, deliberately *not* built in v2.61 and
  left for evidence from a real giant consumer, is sharding STATUS write
  authority by scope: let each `<area>/<scope>` row's authoritative state live
  in that team's scope shard file while the global STATUS keeps only
  lint-verifiable roll-up pointers — preserving "one fact, one owner" plus the
  17-row baseline roll-up while dissolving the multi-team concurrent-write
  conflict. Until that evidence exists, v2.61's honest posture is
  "usable at medium scale".

### v2.60

**Upgrade goal**: remove the false-positive path where mechanically complete
product/architecture Markdown passes lint but a cold reader cannot recover a
consistent current story. v2.60 makes `reader-quality.md` the unique owner of
the universal reader floor, completeness profiles, product maturity and
evidence-fidelity semantics, replaces verdict-string
review pointers with structured task evidence, inventories finite product and
technical surfaces, adds deployment/observability and product-to-runtime
routing, adds an exact cross-layer `Q01`-`Q21` quality/risk/governance
disposition, and requires a bottom-up regeneration loop after every
`needs-fix`. Process, records, glossary, root, and STATUS now use exact-scope
reviews with durable semantic truth samples; records separate knowledge
lifecycle from the real-world state they describe. It treats the implementation delegator as the default reader:
ordinary-language explanation, a concrete delegated action, observable result,
evidence, and stop/escalation boundary come before repository vocabulary.

**Impact**: `semantic_impact=high` -- changes covered-claim evidence,
product-root and architecture-root manifests, the default architecture view set,
and cold-reader scoring. The first adoption or repair of a false `covered` claim
requires an independent cold reader under `status-protocol.md §6`.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Unique reader contract | Preflight/bootstrap/Doctor/closeout/audit adapters | Remove live legacy product `contract/design/debt` or `production` interfaces; route the shared writing floor, product maturity, and evidence fidelity to `reader-quality.md`. | Every reader-facing body can reach the shared floor on demand; product/architecture use the full task-based gate, while process/records/glossary/root/STATUS use the exact lightweight gate; adapters do not define a parallel vocabulary. |
| Universal completeness profiles | Root, process, records, glossary, STATUS and their bilingual templates | Use the exact common/root/process/record/glossary/STATUS IDs owned by `reader-quality.md`, plus `Q01`-`Q21`. For every exact row, write a short plain-language answer or boundary finding instead of an owner-name string. Build the finite target matrix for every applicable process child, record collection and real entry/anchor, glossary term owner, root, and STATUS register; compute the current `area_disposition_fingerprint` beside content and Q fingerprints. | Process and records pass 46-row profiles, glossary 38, root 37, STATUS 32; every exact row has a plain answer and fitting owner/evidence link; every finite target appears once and is semantically checked; content, area-disposition, and Q fingerprints are current; required changes, visible verdict, Area Status, and Stop Review authority agree. |
| Plain-language delegation | Every reader-facing body | Lead with the reader's scene, decision, delegated action, visible outcome/evidence, and stop/escalation condition; define unavoidable terms before use and keep tables as reference. | The implementation delegator passes `RF1`, `LA2`, `CP-D`, and table-hidden teach-back without reading source. |
| Process method and assets | Process root and every applicable process owner | Explain the strategy, rationale, invariants, nearest rejected alternative, trade-offs, ordered path, repeat/concurrent/partial behaviour, and recovery before reference commands. Inventory every stable created/read/changed/verified/handed-off/retired asset with class, purpose, selection, owner, evidence, risk, and retirement trigger. | `PR01`-`PR16` all have truthful dispositions; the process review confirms method and finite asset coverage rather than accepting a command list. |
| Record truth and routing | Decisions, research, gotchas, bugs, technical debt and their indexes | Keep `record_status` separate from implementation/adoption/failure/hazard/repayment state, preserve documented legacy aliases, and link every real ID exactly once to its unique entry or stable topic anchor. A confirmed unresolved defect uses bug `failure_state: open`; it is not disguised as technical debt. | Missing axes, state disagreement, missing/duplicate/orphan index rows, broken anchors, and paragraph-sized index copies fail; `R01`-`R16` pass. |
| Glossary completeness | Glossary index and entries | Use one six-family inventory for product/user, architecture/runtime, state/workflow, trust/data, evidence/operations, and concurrency-control terms; route every repository-specific term exactly once to a unique entry file or H2 owner. | All six families have entries or a repository-grounded empty reason; aliases, machine/user labels, translations, examples, non-examples, lifecycle, and invalidation remain locatable. |
| Quality/risk/governance disposition | `STATUS.md`, linked product/architecture/process/record owners | Dispose `Q01`-`Q21` exactly once in the pointer-sized register; link each applicable layer owner or named gap. Missing implementation is not evidence of non-applicability. | `[QUALITY-DISPOSITION]` passes and both product/architecture artifacts include the exact shared Q rows. |
| Area schema normalization | `STATUS.md ## Area Status` / `## 区域状态` | Rewrite the table to exactly three columns (`Area`, `Status`, `Notes`) and the 17 exact baseline rows: product, architecture, process, development, testing, benchmark, deployment, release, operations, security-and-compliance, records, decisions, research records, gotchas, bugs, tech-debt, glossary. Merge evidence from legacy child rows such as `architecture/views` into the architecture root/views/domain manifests and aggregate review, then delete those child rows. Add only `x-<slug>` extensions with exactly one resolving owner link. | `[AREA-STATUS]` passes; product/architecture child state is synthesised from manifests/reviews rather than mirrored in STATUS, process/records aggregate rows agree with their children, and no legacy child or unknown row remains. |
| STATUS register boundary | `STATUS.md` | Split paragraph/checklist/command/history cells into owner or appendix evidence and leave state plus pointers; split compound source lifecycle fields across the schema columns. | `[STATUS-REGISTER-CELL]` passes the v2.60 180/320-character and prose-shape gate. |
| Product surface inventory | `01-product/_manifest.md` | Enumerate stable `surface:<slug>` rows for page, navigation, entry-mode, control, settings, diagnostic, external-channel, command, public-interface, output-artifact, notification, and help-onboarding classes; route each to one product owner or a reasoned `not_applicable`. | `[SURFACE-INVENTORY]` passes and every real page or non-page surface has maturity, fidelity, and stable evidence/closure. |
| Sustained product value | Product brief and roadmap/acceptance | Define every outcome metric and counter-metric with its audience, observation window, source, privacy boundary, current baseline (`unknown` is valid), feedback route, and exact threshold or event that makes an owner change the roadmap. | P23 can be reviewed without invented numbers: the reader knows what repeated success means, what adverse result balances it, and what decision follows new evidence. |
| Architecture owner inventory | `02-architecture/_manifest.md` | Classify every direct owner as runtime/support/target; register stable `tech:<slug>` entry, write-store, contract, operator, and external-integration surfaces; make each kind-disposition cell name the exact registered IDs of that kind; add the product-to-architecture bridge. | `[OWNER-INVENTORY]` rejects unknown, wrong-kind, duplicate, or omitted IDs and passes with one narrative owner per row. |
| Deployment and observability | Architecture views | Add `views/deployment-and-observability.md` or a reasoned exception, then connect topology, health signals, telemetry, alerts, and operator diagnosis to runtime owners. | The view manifest and default reader route include the seventh cross-owner view. |
| Trust versus deployment configuration | Trust/contracts and deployment/observability views | Keep access, sensitivity, and redaction rules in the trust owner; keep configuration source, loading/reloading, environment variation, rollout, drift detection, and recovery in deployment/observability. Cross-link any setting that affects both. | A08 no longer hides configuration lifecycle inside a generic secrets paragraph, and the deployment view does not redefine access or redaction policy. |
| Reader locality and consistency | Product/architecture roots and derived summaries | Keep the core story in a bounded first-day route; sweep duplicated current/target summaries for conflicts before review. | The reviewer does not need a collection tour to recover the normal path, visible result, failure posture, and main gaps. |
| Structured cold review | Durable review artifact linked by covered manifests and STATUS | Start each of six exact scope tasks at `SSOT/README.md`; hide tables; record bounded reads/hops, per-task evidence, five cold proofs, 16 leaf minima, exact `C + scope + Q` completeness dispositions, and the complete finite owner/surface/view/bridge target population. Add the stable `reviewer` and exact `authorises=area:product:covered|area:architecture:covered`, then close the claim through one current STATUS stop row that matches reviewer, role, date, verdict, artifact, and authorisation. | `[READER-REVIEW-EVIDENCE]` passes: every finite target is listed once and semantically read; every owner/evidence link recorded inside the artifact stays inside the consumer SSOT and outside `.bootstrap`, while the matching STATUS Evidence link resolves to this artifact; current shared-surface and normalized STATUS-Q fingerprints match; >=29/32 with no zero and all family/persona floors; no critical truth error; zero unresolved required change; one visible matching final verdict; and result `no-more-required-changes`. |
| Regeneration loop | Source bundle, installed copy, consumer SSOT | Freeze the failure, map symptoms to protocol, inventory coverage, rewrite unique owners before indexes/views/roots, lint, then run the full or lightweight semantic review required for that scope. On every retry, regenerate exact-row plain answers, the complete finite target matrix, and the `area_disposition_fingerprint`; repeat every `needs-fix` rather than carrying a family sample or old child disposition forward. | Source/installed/consumer all report `2.60`; deterministic gates, product/architecture cold reviews, and all applicable exact-scope reviews pass with no omitted target, no owner-name-only exact row, and fingerprints matching current content, Q disposition, and Area Status. |
| Validation | Bundle source | Run document-quality contract/lint, bundle-shape, Doctor, installer, and migration regression suites. | All relevant suites pass before commit/push or consumer tracking-baseline advancement. |

**Migration notes**:

- Do not copy new tables into an old summary and call the migration complete.
  Repair conflicting current truth in the unique capability/domain owner first,
  then regenerate journeys/views and roots from it.
- Existing v2.59 prose may remain when it passes the new task-based review, but
  every `covered` manifest needs a v2.60 structured artifact and the new finite
  inventories.
- Rebuild each product/architecture full review with the exact 29-field
  frontmatter, a stable reviewer ID, scope-matching `authorises`, complete finite
  target coverage, relative in-SSOT evidence links, one visible final verdict,
  and one matching current STATUS stop row. High-impact adoption uses an
  independent cold reader; do not advance the tracking baseline from an old artifact
  that only contains a verdict string or sampled owner names.
- A `covered` process, records, or glossary row needs its matching exact-scope
  artifact. Root and STATUS may receive their own `covered` review before the
  repository converges; this does not claim that other areas are complete.
- Migrate record entries and collection indexes together. The record lifecycle
  and the state of the described decision/research/bug/hazard/debt are different
  questions, even when an older `status` alias is retained for compatibility.
- Add the STATUS Q register before claiming completeness. An applicable
  dimension with no current mechanism becomes a linked gap; it does not become
  `not_applicable`. Do not create twenty-one empty H2 sections in every owner.
- Add conditional `03-process/operations/` and
  `03-process/security-and-compliance/` owners or record named
  non-applicability; deployment alone does not own day-two operation or
  recurring security/compliance evidence.
- Passing deterministic lint is necessary, not sufficient. A `needs-fix`
  teach-back restarts the loop even when lint is clean.

### v2.59

**Upgrade goal**: make product and architecture owners understandable and
complete for a cold reader, not merely routable and mechanically recoverable.
Earlier versions established owner maps, directory maps, compact intent
narratives, and recovery manifests, but they could still mark a heading/table
skeleton as `covered`. They also imposed exact scaffold headings that encouraged
universal checklists, and used one manifest shape for unrelated owner levels.
v2.59 replaces that compression bias with a reader-quality contract: KISS is
the shortest reliable path to understanding; product intent precedes the
architecture response; narrative explanation precedes reference tables; five
location-specific manifests replace the universal manifest; and routing tests
are supplemented by independent comprehension review.

**Impact**: `semantic_impact=high` -- changes the product/architecture
completeness model, templates, manifest contract, Doctor hard blockers, and
cold-reader acceptance. A consumer must independently review the rewritten
reader surface before advancing `tracked_skill_version` to `2.59`.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Reader path | `01-product/`, `02-architecture/`, `SSOT/README.md` | Read the actual Markdown in first-day order: positioning, product intent/current surface, architecture response, view/domain owner, STATUS. Hide tables and confirm the causal story remains understandable. | Product and system can be explained back without reconstructing prose from table cells. |
| Product completeness | Product brief/model, capability and journey sets, roadmap/acceptance | Inventory real pages, entry modes, controls, settings, integrations, diagnostics, identity/privacy expectations, primary/choice/control/recovery/diagnosis journeys, and product maturity separately from evidence fidelity. | Every applicable surface/question has an owner; omissions are explicit gap or `not_applicable`, never silence. |
| Architecture completeness | Architecture root, views, runtime-owner domains | Establish a current request-to-result story and context; add/justify the six default views for operating model, critical journeys, state/data, contracts/trust, failure/recovery, and current-target-gap. | State ownership, trust boundaries, failure/recovery, deployment/operations, and current-vs-target truth are locatable without a source-tree tour. |
| Domain reader surface | Each covered architecture domain | Put a mental model, boundary, first-screen Mermaid diagram, and one canonical current flow before reference inventory. Move document-self invalidation/retirement conditions to the domain manifest. | `[OWNER-ORIENTATION]`, `[NARRATIVE-SUFFICIENCY]`, and `[DIAGRAM-FIRST]` pass; exact H2 scaffold names are not required. |
| Manifest migration | Product/architecture `_manifest.md` files | Replace the universal template with `product-root`, `product-collection`, `architecture-root`, `architecture-views`, or `architecture-domain`; fill required rows and remove unused sections. | `[MANIFEST-COMPLETENESS]` has no TODO/TBD, empty required cell, wrong archetype, or forbidden cargo. |
| Default surfaces | Product and architecture roots | Confirm the product spine and all applicable default architecture views exist, or record a visible reasoned exception. | `[SURFACE-COVERAGE]` passes. |
| Reader-facing hygiene | Product/architecture prose | Remove visible authoring/protocol machinery (`ssot-bootstrap`, `SKILL_STYLE`, Doctor numbers/labels, adoption versions) and move machine recovery content to manifests. | `[META-LEAKAGE]` and table-density review are clean. |
| Independent comprehension | Actual rendered consumer Markdown | Under the existing `semantic_impact=high` exception in `status-protocol.md §6`, a reviewer other than the author uses the 8-dimension rubric in `reader-quality.md §7`, writes a teach-back, and names factual uncertainty. Repeat after every `needs-fix`. | Score >=14/16, no zero dimension, no factual error, and reviewer result `no-more-required-changes`. |
| Bundle/version sync | Source bundle, installed copy, consumer tracking baseline | Run document-quality tests, bundle tests, install from the reviewed source, verify installed `VERSION`/metadata, then update consumer `STATUS.md`. | Source and installed bundle report `2.59`; consumer tracking baseline advances only after review. |

**Migration notes**:

- This is a content migration, not a mechanical rename. Do not advance the
  tracking baseline after only copying new templates or adding missing headings.
- Exact `Walkthrough` / `Easily confused with` / `Out of scope` headings from
  v2.51 may remain when natural, but Doctor now judges their meaning rather
  than their spelling.
- Existing `current/target/gap` architecture tags remain valid. Product owners
  instead use the product-maturity axis (`current/limited/target/out`) plus a
  separate evidence-fidelity axis.
- Routing and anchor probes still run; they are necessary but cannot substitute
  for the independent comprehension gate.

### v2.58

**Upgrade goal**: close consumer-derived reliability gaps across capture,
canonical artifacts, installation, and review authority. Earlier versions required explicit closeout
positions, but still allowed user-visible bug fixes, walkthrough caveats,
transcript-only blockers, or stale tracking baselines to stop at `fixed`, `link-only`,
or generic follow-up prose. v2.58 closes that gap: closeout must adjudicate bug
packetization, fix-commit disposition, caveat extraction, and overdue tracking baselines;
audit must treat fix/hotfix clusters and transcript caveats as durable-capture
review prompts; doctor/lint must inspect canonical facets, accept valid research
frontmatter block lists, and reject v2.57 tracking baselines that still use legacy
physical paths. The faceted-layout helper is now idempotent and path-safe on
canonical trees. The installer ships owned bundle-level companion files without
overwriting or deleting unrelated shared-root files. Bootstrap and Doctor now
defer to the review exceptions owned by `status-protocol.md` instead of widening
independent review to every tracking baseline.

**Impact**: `semantic_impact=medium` -- changes closeout/audit/doctor behaviour,
not the consumer's area model. Consumers self-review per `status-protocol.md §6`; no independent reviewer is required unless the consumer also uses the
upgrade to claim first-time `converged`.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Closeout durable disposition | `$ssot-closeout` use | Confirm closeout now forces bug packetization threshold, fix-commit adjudication, caveat extraction, and overdue tracking-baseline fields instead of accepting `fixed` or `link-only` prose alone. | Representative bug-fix / caveat batches route to `bugs/`, `tech-debt`, `testing`, `gotchas/`, `decisions/`, or `STATUS.md` gaps. |
| Conversation/commit audit prompts | `$ssot-audit` use | Confirm transcript caveats (`unchecked`, `blocked`, `real-provider gated`, etc.) and fix/hotfix clusters are treated as durable-capture review prompts, not transcript/git-only history. | Audits explicitly ask for durable owner disposition when those signals appear. |
| Canonical artifact contract | Bootstrap templates, migration helper, Doctor | Confirm current templates use numbered facets/direct domains, canonical migration is a no-op, and v2.57+ lint scans and enforces canonical paths. | Template hygiene, migration idempotence, canonical Doctor fixtures, and real-consumer dry-run pass. |
| Research frontmatter | `04-records/research/*.md` | Confirm inline and block-list `promotion_targets` parse as values while empty forms still fail. | Doctor smoke covers valid block lists and invalid empty values. |
| Doctor/lint floor | `ssot-doctor` / `ssot-lint.sh` | Confirm placeholder debt / follow-up wording without file-level owner/trigger/guard fails while registered owners and quoted history do not false-fail. | `run-tests.sh` covers positive and negative owner lifecycle paths. |
| Review authority | Bootstrap / Doctor stop review | Confirm both skills reference the four exceptions in `status-protocol.md §6` and do not claim every tracking-baseline update requires independent review. | Ordinary tracking-baseline updates stay explicitly self-reviewed; only the four exceptions route to an independent reviewer. |
| Installer companion files | Installed skill root | Confirm project/global installs include an ownership-marked `SKILL_STYLE.md`, refuse unowned collisions, and remove only owned copies. | Installer E2E covers install, upgrade, collision, owned uninstall, and foreign-file preservation. |
| Bundle version sync | `VERSION`, `skills/ssot-preflight/SKILL.md` metadata | Confirm both equal `2.58`; rerun bundle-shape, migration, installer, and Doctor tests. | Version mirrors match and the full local validation matrix passes. |

**Migration notes**:

- This upgrade tightens protocol judgement; it does not create a new SSOT area.
  Existing consumer owners stay where they are.
- A consumer that already has stale `tracked_commit`, `tracked_session`, or
  caveat-heavy walkthrough/handoff material should use the tighter bundle to run
  a targeted `$ssot-audit` / `$ssot-closeout` pass before claiming the new skill
  version is fully absorbed.
- `link-only` remains valid for source-material inventory, but not as the final
  destination for a stable caveat that changes future closure interpretation.

### v2.57

**Upgrade goal**: make the numbered faceted SSOT layout the canonical physical
layout, and provide an audit-owned migration helper for consumers that still
use legacy unnumbered top-level directories. Earlier versions already accepted
faceted paths such as `SSOT/01-product/`, `SSOT/02-architecture/`,
`SSOT/03-process/`, and `SSOT/04-records/`, but parts of the protocol still
treated unnumbered paths like `product/`, `architecture/`, `testing/`, and
`decisions/` as normal physical locations. v2.57 closes that ambiguity: prose
may use semantic shorthand like "product trunk", but concrete paths, links,
template destinations, CORE-REF examples, and migration targets use the
numbered physical layout.

**Impact**: `semantic_impact=high` -- changes the canonical physical IA and
adds a helper that bulk-mutates consumer trees. Existing legacy layouts remain
readable before adoption, but advancing `tracked_skill_version` to `2.57`
requires running the helper, reviewing its diff, and obtaining an independent
review per `status-protocol.md §6`.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Physical layout | `SSOT/` tree | Run `python3 <installed ssot-audit>/assets/scripts/migrate-faceted-layout.py SSOT --dry-run`; if it reports moves and no conflicts, run it without `--dry-run` and review the resulting diff. | Legacy top-level `product/`, `architecture/`, `development/`, `testing/`, `benchmark/`, `deployment/`, `release/`, `decisions/`, `gotchas/`, `bugs/`, `tech-debt/`, and `research/` have moved to `01-product/`, `02-architecture/`, `03-process/*`, or `04-records/*` as applicable. |
| Architecture domains | `02-architecture/` | Confirm legacy `architecture/domains/<domain>/` entries were flattened to direct numbered domain folders such as `02-architecture/01-runtime/`; inspect numbering if existing numbered domains were already present. | Domains are direct children of `02-architecture/`; legacy `domains/README.md` is preserved as `domain-index.md` when present. |
| Markdown links and literals | `SSOT/**/*.md` | Review the helper's rewritten Markdown links and literal `SSOT/...` paths. Resolve any ambiguous prose manually instead of doing broad blind replacements. | Links resolve after directory moves and concrete SSOT paths name numbered physical locations. |
| Conflict handling | Existing mixed layouts | If the helper exits `2`, resolve the named target/source conflict manually before rerunning. Do not advance the tracking baseline while legacy and canonical folders both contain content for the same area. | Helper exits `0` and `git diff --check` passes. |
| Bundle version sync | `VERSION`, `skills/ssot-preflight/SKILL.md` metadata | Confirm both equal `2.57`; rerun `tests/test-bundle-shape.sh` and `tests/test-faceted-layout-migration.sh`. | Bundle-shape and migration helper tests pass. |

**Migration notes**:

- The helper is intentionally located in `ssot-audit` because protocol drift is
  caught during audit. It mutates only the consumer `SSOT/` tree it is pointed
  at; use `--dry-run` first for reviewable output.
- This migration is path and link hygiene, not semantic rewriting. It does not
  decide whether an area is `covered`, does not promote facts, and does not
  create missing content beyond move destinations required by existing files.
- Legacy unnumbered layouts remain compatibility input. New bootstrap output,
  examples, CORE-REFs, and durable protocol paths should use the numbered
  physical layout.

### v2.56

**Upgrade goal**: narrow the preflight default read set so the agent decides
what to read, not the gate. Earlier versions defaulted `product/README.md`
and `architecture/README.md` on at the gate (a low "may touch user value"
threshold made the product trunk near-always-on; the architecture trunk was
on unless narrowly excluded) and cold-scanned `tech-debt/`, `bugs/`,
`gotchas/`, and `STATUS.md ## Open Gaps` as a per-task default obligation.
v2.56 makes the gate floor match the existing "Load on demand" reference
layer: the mandatory read is `SSOT/STATUS.md` plus `SSOT/README.md` as the
project-specific router. The task-entry map in `SSOT/README.md`, not the
gate, decides whether the `product/` or `architecture/` trunks are read.
When the task-entry map is missing or does not route the current task,
preflight falls back to reading both trunks so a thin-router repository
still gets trunk coverage. The open-risk scan narrows to the owner files the
router actually routed plus `STATUS.md ## Open Gaps`; cold-scanning the full
`tech-debt/`, `bugs/`, or `gotchas/` directories becomes the agent's call,
not a default obligation. `area-model.md §4` becomes the single owner of
trunk-read routing.

**Impact**: `semantic_impact=medium` -- narrows preflight read/risk-scan
defaults and relocates the trunk-read decision to the task-entry map
(`area-model.md §4`). No new SSOT area, owner field, or stop-review trigger.
Consumers self-review per `status-protocol.md §6`; no independent reviewer
is required unless the consumer also uses the upgrade to claim first-time
`converged`.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Preflight read floor | `skills/ssot-preflight/SKILL.md` gate section | Confirm the gate no longer defaults `product/README.md` or `architecture/README.md` on; the floor is `STATUS.md` plus `SSOT/README.md` as router, with a thin-router fallback to both trunks when the map is missing or does not route the task. | A substantive task enters with only `STATUS.md` + the router as mandatory reads; trunks are router-decided. |
| Trunk-read ownership | `skills/ssot-preflight/references/area-model.md §4` | Confirm §4 states the task-entry map, not the preflight gate, decides trunk reads, and names the thin-router fallback. | §4 is the single owner of who decides trunk reads. |
| Open-risk scan | `skills/ssot-preflight/SKILL.md` risk section | Confirm the scan targets the routed owner files plus `STATUS.md ## Open Gaps`; full `tech-debt/` / `bugs/` / `gotchas/` directory scans are agent self-decision, not a per-task default. | Cold-scanning every risk directory is no longer a per-task default obligation. |
| Closeout disposition | `$ssot-closeout` | Confirm the `fix-now` / `recommend-now` / `defer-visible` / `ignore-for-scope` taxonomy and the non-silent deferral floor are unchanged. | Closeout still carries every surfaced recommendation to a visible disposition. |
| Bundle version sync | `VERSION`, `skills/ssot-preflight/SKILL.md` metadata | Confirm both equal `2.56`; rerun `tests/test-bundle-shape.sh`. | Bundle-shape test passes. |

**Migration notes**:

- This is a read-routing tightening, not a new SSOT area or owner field. No
  consumer SSOT content needs to be moved or rewritten.
- Repositories with a populated task-entry map in `SSOT/README.md` get the
  narrowest read: `STATUS.md` + the router + only the routed owners.
  Repositories without one (thin-router) keep trunk coverage via the
  fallback to `product/README.md` + `architecture/README.md`.
- The classification taxonomy and deferral floor that closeout consumes are
  intentionally unchanged; only the default scan breadth narrows.

### v2.55

**Upgrade goal**: add **benchmark** as an independent engineering process
owner. Earlier protocol versions routed benchmark facts through `testing/` as a
baseline detail or through `04-records/research/` as a one-off evidence packet.
That left no stable owner for current benchmark suites, canonical workloads,
metrics, environments, runner commands, floors, comparison rules, trend
interpretation, known gaps, and decision links. v2.55 gives that stable policy
to `benchmark/` while preserving `testing/` for correctness and
`04-records/research/` for exploratory studies.

**Impact**: `semantic_impact=high` -- adds one process area, one paired
bootstrap template, closeout/audit routing obligations, and deterministic lint
for canonical owner presence / obvious misrouting. A new owner area requires
independent review per `status-protocol.md §6`.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Process area | `03-process/benchmark/README.md` | Create the README from `benchmark-readme.md` when adopting the faceted process layout or when benchmark evidence guides engineering decisions. Legacy top-level `benchmark/README.md` may stay until the next faceted-layout migration. | A cold reader can answer "what benchmark do I run and what floor matters?" from the benchmark owner. |
| Testing boundary | `testing/` | Remove benchmark floors, canonical workloads, comparison rules, and trend interpretation from `testing/`; keep only correctness strategy, selection, gates, fixtures, correctness baselines, gaps, and defensive tests. | `testing/` may link benchmark gates but does not own measured performance/cost/capacity policy. |
| Research boundary | `04-records/research/` | Keep one-off benchmark studies, exploratory measured trials, and reusable evidence packets in research until a stable method, floor, rule, or trend interpretation is promoted. | Research packets link promoted claims to `benchmark/` and do not become authority mirrors. |
| Architecture/product/release consumption | `architecture/`, `product/`, `release/`, `decisions/`, `tech-debt/` | Let consuming owners link benchmark conclusions as evidence for promises, design choices, release gates, or debt; do not make them own the benchmark method or current floor. | Consuming owners explain why the benchmark matters; `benchmark/` owns how to run and interpret it. |
| Ledger boundary | `benchmark/` and evidence surfaces | Move dated runs, command transcripts, raw profiler dumps, and one-off score tables to final evidence, CI artifacts, release notes, stop-review evidence, or research records. | `ssot-lint.sh SSOT/` reports no `[BENCHMARK-OWNER]` failures and no `[BENCHMARK-LEDGER]` warnings that block the intended `covered` claim. |

**Migration notes**:

- This is a process owner, sibling to `testing/`, not a records sub-area and not
  an architecture domain. Use `SSOT/03-process/benchmark/README.md` in the
  faceted layout.
- Existing projects with no benchmark evidence may create the area as
  `not_applicable` with a reason, or leave it until adopting the faceted process
  skeleton if their current layout does not yet use `03-process/`.
- Do not copy historical benchmark logs into `benchmark/`. Promote only stable
  method, workload, metric, floor, comparison, interpretation, gap, and decision
  link facts.

### v2.54

**Upgrade goal**: add **research / POC records** as first-class structured
evidence packets under `04-records/research/`. Research and POC work often
produces useful proof, but older protocol versions forced agents to either
bury it in source-material rows or over-promote it into product / architecture
owners. v2.54 gives that work a records home while preserving owner authority:
research records keep the question, method, environment, evidence, negative
findings, reusable claim rows, boundaries, and promotion targets; owners absorb
only promoted long-lived facts.

**Impact**: `semantic_impact=medium` — adds one records sub-area, two paired
bootstrap templates, closeout routing obligations, and deterministic lint for
canonical location / entry shape. Consumers self-review per
`status-protocol.md §6`; no independent reviewer is required unless the
consumer also uses the upgrade to claim first-time `converged`.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Records area | `04-records/research/README.md` | Create the README index when adopting v2.54 or during the next bootstrap refresh. Do not create dummy entries. | The area exists as an index when the consumer chooses the faceted `04-records/` shape; no top-level `SSOT/research/` is introduced. |
| Research entry shape | `04-records/research/NNNN-<slug>.md` | For real research / POC work, create or update a numbered entry with required frontmatter: `status`, `kind`, `created_on`, `owner`, `promotion_targets`, `recheck_trigger`. | `ssot-lint.sh SSOT/` reports no `[RESEARCH-RECORD]` failures. |
| Evidence packet boundary | Research / POC records | Preserve the question, conclusion, applicability/boundaries, candidates/options, method/environment, verification steps, evidence, negative findings, reusable claim rows, promoted owners, and follow-up actions. Include a concrete boundary or `do_not_use_for` signal. | A future agent can re-check the evidence without mistaking the POC for product or architecture authority. |
| Source-material lifecycle | `STATUS.md` source-material matrix and raw docs | Keep raw docs/external artifacts under ordinary lifecycle downgrade rules. Do not use a research record as an authority mirror for full source material. | Source material rows still carry lifecycle / authority / owner / absorbed_to / do_not_use_for / review_on where applicable. |
| Promotion to owners | `product/`, `architecture/`, `decisions/`, `testing/`, other owners | Promote only durable claim rows that have enough evidence for the owner. POC evidence normally supports at most `source-backed`; owner absorption plus later review is required before it becomes ordinary verified SSOT fact. | Owners contain concise promoted facts with links back to the research record as evidence; they do not mirror the research narrative. |
| Closeout disposition | `$ssot-closeout` | When a task produced research / POC output, choose one disposition: create research entry, update existing research entry, promote claims to owners, or discard with reason. | Closeout cannot silently drop research output or over-promote it into owners. |

**Migration notes**:

- This is a records sub-area, not a new top-level SSOT trunk. Use
  `SSOT/04-records/research/`, or the legacy-equivalent records folder only if
  the consumer has not yet adopted the v2.50 faceted layout.
- Existing source-material matrices that mention `docs/research/*` or POC docs
  do not fail merely because there is no research entry. Create entries only
  when a real research / POC conclusion needs a reusable evidence packet.
- Research entries are not authority mirrors. They keep re-checkable evidence
  and distilled claims; product / architecture / decision owners remain the
  authority after promotion.

### v2.53

**Upgrade goal**: add the **active recommendation / non-silent deferral
floor**. v2.52 made open risks and temporary surfaces visible; v2.53 closes the
remaining loophole where an agent can see a task-relevant debt or gap, say
"later" or "out of scope", and leave no retriggerable signal for the next
agent.

**Impact**: `semantic_impact=medium` — tightens preflight and closeout
disposition rules and adds one deterministic lint check for vague future-work
deferrals without an owner/reference signal. Consumers self-review per
`status-protocol.md §6`; no independent reviewer is required unless the
consumer also uses the upgrade to claim first-time `converged`.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Active recommendation classification | `STATUS.md ## Open Gaps`, active `tech-debt/`, open/recurred `bugs/`, relevant active `gotchas/` | During preflight, classify each overlapping entry as `fix-now`, `recommend-now`, `defer-visible`, or `ignore-for-scope`. | The final plan/closeout shows why task-overlapping risks were fixed, recommended, visibly deferred, or excluded. |
| Non-silent deferral | Deferred open gaps, active debt, open/recurred bugs, capture follow-ups | For every deferral, name owner or owner record, reason, closure condition, revisit signal, verification guard, and next concrete action. | No deferred risk relies on bare "later", "someday", "future work", or locked-language equivalent prose. |
| Closeout disposition | Preflight recommendations and newly discovered risks | Carry each recommendation to `fixed`, `deferred-visible`, `expired/out-of-scope`, or `converted-to-owner`. | Closeout cannot declare aligned while dropping a surfaced recommendation. |
| Tech-debt first screen | Active high-priority or cross-cutting debt entries | Add or confirm quick entry: trigger/scope, first checks, do-not-do boundary, repayment verification, next action / must-handle condition, status pointer. | Future agents can decide whether the debt overlaps their task without reconstructing history. |
| Lightweight lint | Current SSOT owners and STATUS registers | Run `ssot-lint.sh SSOT/`; inspect `[SILENT-DEFERRAL]` hits. | Lint reports no vague future-work deferral without owner/reference or retrigger signal. |

**Migration notes**:

- This is a tightening of v2.52, not a new backlog system. Issue trackers may
  still own scheduling; SSOT owns the signal that task-relevant debt must be
  surfaced and cannot be silently deferred.
- The lint check is intentionally narrow. It only fires on obvious
  future-work phrases that lack nearby `DEBT-`, `BUG-`, `DEC-`, `ADJ-`,
  `owner`, `closure_condition`, `revisit_signal`, `verification_guard`, or
  `next_action` signals.
- Consumers may leave a risk open, but "not this batch" must be visible enough
  for the next agent to know when to revisit it.

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
`status-protocol.md §6`; no independent reviewer is required unless the
consumer also uses the upgrade to claim first-time `converged`.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Task-relevant open risks | `STATUS.md ## Open Gaps`, active `tech-debt/`, open/recurred `bugs/`, relevant active `gotchas/` | During preflight, surface entries whose trigger/path/capability/failure mode overlaps the task; during closeout, record fixed / deferred-with-reason / next-action. | Closeout cannot end with an overlapped risk silently ignored. |
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
`status-protocol.md §6`; no doctor stop-review is required.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Reader-scaffold slots on owner READMEs | Every `covered` owner README under `SSOT/` (top-level area READMEs, architecture domain READMEs, `dir-readme-map.md` rendered indexes) | Open each owner README; fill the four new slots from the upgraded `assets/templates/{en,zh}/` owner template, or write explicit `not_applicable: <reason>` where genuinely indexical. Walkthrough on `architecture/<domain>/README.md` references one canonical flow's surface/symbol pins; never duplicates the Runtime Flows table. | `ssot-lint.sh SSOT/` reports `[BOUNDARY-DISAMBIG]` / `[OUT-OF-SCOPE-LINK]` / `[WALKTHROUGH]` = 0 WARN, OR every WARN row is a deliberate `not_applicable: <reason>` documented in the area's `_manifest.md`. |
| Diagram typing in `architecture/` | All Mermaid fenced blocks under `architecture/` | Add `<!-- diagram_type: component\|sequence\|state\|flow -->` as the first non-blank line inside each Mermaid fence; split any block that mixes types (e.g. flowchart edges + sequence `participant` directives). | `ssot-lint.sh SSOT/` reports `[DIAGRAM-TYPE-TAG]` = 0 WARN. |
| First-screen diagram on architecture domain READMEs | Every `architecture/<domain>/README.md` whose `intent_recovery: covered` | Move or add a small component diagram above the first owned-facts table so a cold reader sees the boundary picture before parsing tables. Domains genuinely without a meaningful diagram downgrade to `partial`. | `ssot-lint.sh SSOT/` reports `[DIAGRAM-FIRST]` = 0 WARN. |
| Glossary entry template adoption | New glossary entries created after this upgrade | Render new glossary entries from `assets/templates/{en,zh}/glossary-entry.md` (`glossary/<term>.md`). Pre-v2.51 entries inside `glossary/README.md` grandfather in until next touched. | New entries follow the per-term file shape; touched entries migrate. |
| Required-answer count in `area-model.md §2.0` | Anyone authoring or auditing a user-facing owner README | When asserting an owner README is `covered`, confirm the sixth question ("Where can I go next, and what does this owner explicitly NOT answer") is answered by the `## See also` + `## Out of scope` slots, not by inline body navigation links. | Cold-reader review on `covered` owners confirms the sixth answer is locatable in dedicated slots. |

**Migration notes**:

- Self-reviewable per `status-protocol.md §6`; no doctor stop-review required.
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

**Review**: Self-review per `status-protocol.md §6`.

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

**Review**: Self-review per `status-protocol.md §6`.

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

**Review**: Self-review per `status-protocol.md §6`.

**Impact checklist**:

| Check | Affected area | Audit action | Done criterion |
|---|---|---|---|
| Source inventory | `STATUS.md`, root Markdown, `docs/**/*.md` | Check whether each root/core/docs Markdown file has a lifecycle header, a source inventory row, or an audited exclusion. | No SSOT-external thick doc can masquerade as current authority. |
| Working/historical downgrade | working, historical, external, public-thin docs | Check for authority, owner, absorbed target, do-not-use boundary, and review date. | Strong current-fact language has `absorbed_to`, `do_not_use_for`, and owner pointers. |
| Product/architecture boundary | `product/`, `architecture/`, source routing | Check whether product owns intent and architecture owns implementation response. | Product capability docs stay thin; architecture links product owners instead of redefining product facts. |
| Runtime Owner Map | architecture root/views/domains | Check whether root routes runtime owners and invariants, views are cross-owner, and domains own state/contracts/lifecycle/failure/verification. | Architecture is readable as a runtime owner map, not a universal 20-section checklist. |
| Lint/Doctor behavior | `ssot-lint.sh`, Doctor output | Run lint after tracking baseline update and inspect new v2.38 tags. | Deterministic failures catch missing inventory/header/exclusion; semantic drift remains reviewer-confirmed. |

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

**Review**: Self-review per `status-protocol.md §6`.

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

**Review**: Self-review per `status-protocol.md §6`.

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

**Review**: Self-review per `status-protocol.md §6`.

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
