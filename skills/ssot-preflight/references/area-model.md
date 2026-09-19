# SSOT Area Model

This file is the semantic owner of `SSOT/` top-level area responsibilities, satellite area decomposition, recursive directory rules, task-entry map, and not-applicable area handling. Read it when judging "where should this long-lived knowledge be written" or when creating/reviewing the SSOT skeleton.

## Table of Contents

- [1. Structural model](#1-structural-model)
- [2. Area responsibilities](#2-area-responsibilities)
- [3. Recursive directory rules](#3-recursive-directory-rules)
- [4. Task-entry map](#4-task-entry-map)
- [4.1 Default fallback for unrouted durable knowledge](#41-default-fallback-for-unrouted-durable-knowledge)
- [5. Not-applicable areas](#5-not-applicable-areas)

## 1. Structural model

The SSOT root is fixed at `SSOT/` under the repository root; do not use `docs/` as a long-lived memory surface. The canonical physical layout is the v2.57 faceted layout below. Prose may say "product trunk" or "architecture trunk" as semantic shorthand, but any concrete path, link, template destination, CORE-REF, or example must use the numbered physical path. The unnumbered `product/`, `architecture/`, `testing/`, `decisions/`, and similar top-level paths are legacy-compatible only; upgrading a consumer should migrate them with `ssot-audit/assets/scripts/migrate-faceted-layout.py` before advancing `tracked_skill_version`.

```text
SSOT/
  README.md          # Pure index entry; opens with the one-sentence repo positioning
  STATUS.md          # Maintenance status
  HISTORY.md         # Append-only batch write log: write provenance (v2.63)
  01-product/        # Long-lived product trunk
    README.md        # Product Reader Map / owner index
    prd.md           # Current product brief and scope
    product-model.md # Users, problems, promises, boundary, language, trade-offs
    roadmap-and-acceptance.md # Phases, roadmap intent, product acceptance
    capabilities/
      README.md      # Capability owner index
    journeys/
      README.md      # Users/operators journey owner index
  02-architecture/   # System concrete-design trunk
    README.md        # Whole-system architecture entry (carries tech stack and repository type in the design brief)
    views/           # Cross-domain architecture views
      README.md
      operating-model.md
      critical-journeys.md
      state-and-data-lifecycle.md
      contracts-and-trust-boundaries.md
      failure-and-recovery.md
      deployment-and-observability.md
      current-target-gap.md
    NN-domain/       # Architecture domains of state/contract/failure/verification
      README.md
  glossary/          # Proprietary terms
  03-process/        # Engineering operation areas
    development/     # Local dev and run
    testing/         # Test strategy
    benchmark/       # Benchmark suites and measured floors
    deployment/      # Deploy and distribute
    release/         # Release process
    operations/      # Conditional: operate, maintain, diagnose, and recover
    security-and-compliance/ # Conditional: security/compliance control process and evidence
  04-records/        # Historical / emergent records and structured evidence packets
    decisions/       # ADR / major decisions
    gotchas/         # Pitfalls
    bugs/            # Fix knowledge
    tech-debt/       # Tech debt
    research/        # Research/PoC evidence packets
```

Core model:

- **Product trunk**: `01-product/`. Answers why the product exists, who it serves, what it promises, what it does not do, and how capabilities and journeys are accepted. PRD and product intent default to here.
- **Technical trunk**: `02-architecture/`. Answers how the system as a whole implements product constraints, how it operates, why it is split this way, and where current implementation differs from target design. Internally divisible into `views/` and direct `NN-<domain>/` owner folders as two types of authoritative locations.
- **Context areas**: `glossary/`. Help the agent first understand what key terms mean.
- **Engineering operation areas**: `03-process/development/`, `03-process/testing/`, `03-process/benchmark/`, `03-process/deployment/`, and `03-process/release/`, plus conditional `03-process/operations/` and `03-process/security-and-compliance/` owners. They answer how to run, test correctness, measure performance/cost/capacity, deliver, operate a live system, and execute security or compliance controls without duplicating product promises or architecture mechanisms.
- **Emergent/historical areas**: `04-records/decisions/`, `04-records/gotchas/`, `04-records/bugs/`, `04-records/tech-debt/`. Record why, pitfalls, fix knowledge, and debt.
- **Record packets**: `04-records/research/`. Preserve reproducible
  research/PoC evidence packets and reusable claim rows. They are not
  authority mirrors; product, architecture, decision, and engineering owners
  absorb only promoted long-lived facts.

The Views + direct numbered domains structure of `02-architecture/` and the recursion protocol are maintained by [`architecture.md`](architecture.md). Do not add a top-level `SSOT/design/`; design documents are source material, product facts enter `01-product/`, and technical design facts enter architecture views/domains, decisions, bugs, gotchas, testing, benchmark, and other authoritative locations by content.

Do not add a top-level `SSOT/research/`. Research and PoC records that belong
inside SSOT live under `SSOT/04-records/research/` as structured evidence
packets. Raw research notes, external artifacts, and working docs outside SSOT
still follow the source-material lifecycle and downgrade rules.

`01-product/` is a required top-level area. Even pure libraries, tools, or internal platforms must record users/operators, product promises, boundary, non-goals, and acceptance meaning; capabilities or journeys that do not apply should be written as `not_applicable` with a reason, rather than omitting the product trunk.

`SSOT/README.md` is the cold-reader entry. It must open with a single-sentence repository positioning ("what this repo is, who it serves, what it does") before any Reader Map table. Tech stack, runtime form, and repository type belong to `02-architecture/README.md` as part of the design brief; primary capabilities belong to `01-product/prd.md` as part of the capability map. `SSOT/README.md` only states the one-sentence positioning and routes to those owners; it does not redefine them.

---

## 2. Area responsibilities

### 2.0 Writing posture (shared across every area below)

Every section of every user-facing SSOT body file is first written for the stranger who lands tonight knowing nothing; tables, codes and tags they cannot read are not paragraphs. The unique shared writing floor, body scope, navigation rules, and reader-area profiles live in [`reader-quality.md`](reader-quality.md); `ssot-bootstrap` §3.7 only routes bootstrap authors there. Doctor `14I` and the v2.60 deterministic checks enforce the mechanically decidable part.

KISS is the permanent SSOT design principle. It means the shortest reliable
path to understanding, not the fewest words. Remove duplicate and machine-only
material from the reader path, then write enough causal prose for a newcomer to
teach the product or system back. Tables remain routing, comparison, status, or
evidence indexes. A table-heavy owner that makes the reader reconstruct the
story from cells must be fixed before it is marked `covered`. The complete
reader contract lives in [`reader-quality.md`](reader-quality.md).

Every user-facing owner is also written as an agent action surface. After the opening explanation, a future agent should be able to answer six questions without reconstructing history from scattered evidence: **when should I read this**, **what current truth does this owner hold**, **where should I inspect first**, **what should I not do**, **what minimal verification or evidence closes the loop**, and (v2.51) **where can I go next, and what does this owner explicitly NOT answer (with a pointer to the owner that does)**. Keep the answers compact; the point is orientation, not a second playbook. If a missing answer is caused by a protocol gap rather than one local document, fix the SSOT Skill protocol first, then update the consumer SSOT from that improved rule.

### 2.0.2 Core recovery manifest (v2.45 / v2.46; authority-aligned v2.60)

`covered` at an area level is unsafe unless the cold reader can see the finite
set of core things that had to be recovered. A consumer at protocol `>= 2.45`
therefore maintains a **Core recovery manifest** in the product trunk and in the
architecture trunk:

- `01-product/README.md` or `01-product/prd.md` first gives a clear **Core
  completeness argument**: why this set is the project's core product surface,
  which user/operator, problem, promise, product boundary, acceptance semantics,
  and long-lived trade-off facts are part of the core, what near-miss items are
  deliberately excluded, and what wrong product conclusion a cold reader would
  reach if one class were omitted. The manifest then lists every core product
  posture / model row, capability, and journey that the product expects a cold
  reader to recover. Each row names one product owner, the product maturity
  and evidence fidelity defined only in
  [`reader-quality.md §3`](reader-quality.md#3-product-completeness), and the
  evidence or closure owner. Product manifests do not use architecture
  lifecycle states.
- `02-architecture/README.md` first gives a clear **Core completeness argument**:
  why this set is the project's core design surface, which runtime-owner axis
  and cross-owner views make it complete, what near-miss implementation details
  are deliberately excluded, and what wrong design conclusion a cold reader
  would reach if one class were omitted. The manifest then lists every core
  runtime owner, cross-owner view, global invariant / operating-model fact, and
  current-target-gap posture that the architecture expects a cold reader to
  recover. Its owner inventory classifies each owner as `runtime`, `support`,
  or `target`, covers every applicable cross-owner view, and carries one
  unique technical-surface registry. Architecture lifecycle state and
  evidence rules come only from
  [`reader-quality.md §6`](reader-quality.md#6-manifest-archetypes); each row
  also names the evidence or closure owner.

The manifest is not a new top-level area and it is not a second fact store. It
is a finite routing and recovery index. A row must never claim stronger
maturity, evidence, or lifecycle posture than its linked owner. Product rows
are compared on the two product axes; architecture rows are compared on the
architecture lifecycle axis. A reasoned non-applicable row names the reason
and revisit owner; silence is never a disposition.

If a manifest row uses a spine owner such as `01-product/prd.md` instead of a
dedicated capability or journey file, that spine must expose a same-granularity
anchor or short subsection for the row. The reader must not have to reverse
engineer the row from decision files, architecture current-target-gap tables, or
source material. Index vocabulary follows the owner-specific contract in
`reader-quality.md`; do not translate a product row into architecture state or
an architecture row into product maturity.

Doctor reports `[CORE-COVERAGE-MAP]` (15G) when a `covered` product or
architecture area lacks this manifest, omits a core owner, lacks the v2.46
completeness argument, cannot explain near-miss exclusions, advertises a
posture stronger than the owner body, crosses the product/architecture
vocabulary boundary, or carries an unsampled or failed row without a Pending
Capture.

Historical note: pre-v2.60 manifests used intent/truth pillars and sometimes
applied architecture state labels to product rows. Existing review artifacts
may retain those labels as history, but current authors migrate live manifests
to the owner-specific contracts above instead of producing new pillar rows.

### 2.0.3 Product and architecture narrative before manifests (v2.47; clarified v2.60)

The Core recovery manifest is a recovery index, not the story. A product or
architecture trunk that makes the reader reconstruct "what matters and why" from
manifest cells has failed even when every row is accurate. At protocol
`>= 2.47`, `01-product/README.md`, `01-product/prd.md`, or the consumer's declared
product trunk owner must expose a self-contained **product story and current posture** narrative
before its Core recovery manifest. Likewise, `02-architecture/README.md` must expose
a self-contained **architecture story and current posture** narrative before its Core recovery manifest.

The narrative is not another fact store. It is the first-principles synthesis of
the owner facts that already live in the trunk, capability, journey, view, and
domain files. Keep the reading path direct, but do not compress away the
context, example, boundary, or failure/recovery needed to understand it. It
must answer:

- **intent** — why this product or architecture exists, what pressure shaped
  it, and which trade-off future agents must preserve;
- **current posture** — what is true today, what remains limited or future work
  under that owner's vocabulary, and where the evidence or closure owner lives;
- **boundary** — what near-miss interpretation is deliberately excluded and
  what wrong conclusion a cold reader would reach if that class were omitted;
- **reading path** — which owner a reader should inspect first after the
  narrative when they need details.

For product, the narrative must name the user/operator, problem, promise,
boundary/non-goal, acceptance meaning, and at least the core capability/journey
classes. For architecture, it must name the runtime-owner axis, cross-owner
views, apex invariants / operating model, current-target-gap posture, and the
class of implementation inventory deliberately excluded from the core.

The manifest table follows this narrative and stays narrow: owner, owner-specific
posture, and evidence / closure owner. If the manifest is
the only place where a core row's purpose, current truth, or exclusion rationale
is explained, Doctor reports `[INTENT-TRUTH-NARRATIVE]` (15H). If the narrative
introduces new facts that contradict the owner body, route to `[OWNER-ANCHOR]`
or `[PRODUCT-ARCH-DRIFT]` instead of treating prose as authority.

The legacy names "intent/truth pillars" may remain in pre-v2.60 historical
artifacts. They are not headings, columns, or authoring requirements for a
current product or architecture owner.

### 2.0.5 Manifest separation (v2.48)

Once a covered area carries v2.45–v2.47 machinery — the Core recovery manifest,
the Core completeness argument, the Apex maxim registry, the Capability →
Surface registry mirror, intent-recovery pillar matrices, evidence strings, and
README-self failure-mode entries — that machinery starts to crowd out the
product or architecture narrative the area is supposed to own. A cold reader
who lands on `01-product/README.md` or `02-architecture/README.md` should be able to
recover the project's product or design story in five minutes without first
having to learn SSOT skill vocabulary.

At protocol `>= 2.48`, covered product and architecture areas therefore
**separate SSOT self-maintenance machinery from the prose owner** into a sibling
`_manifest.md` file. The split is mechanical, not editorial:

- **Prose owners stay in the existing files** — `01-product/README.md`,
  `01-product/prd.md`, `01-product/product-model.md`, `01-product/roadmap-and-acceptance.md`,
  `01-product/capabilities/*.md`, `01-product/journeys/*.md`, `02-architecture/README.md`,
  `02-architecture/NN-<domain>/README.md`, `02-architecture/NN-<domain>/playbook.md`, and
  `02-architecture/views/*.md`. They keep the product / design narrative, the `§不变量`
  / `§设计简报` / `§运行模型` / `§[MUST]` prose, capability scope and acceptance anchors,
  and inline CORE-REF anchor links. Frontmatter shrinks to a single
  `intent_recovery: covered|partial|gap` token; evidence strings move out.
- **Self-maintenance machinery moves to `_manifest.md`** at the area root
  (`01-product/_manifest.md`, `01-product/capabilities/_manifest.md`,
  `01-product/journeys/_manifest.md`, `02-architecture/_manifest.md`,
  `02-architecture/views/_manifest.md`, `02-architecture/NN-<domain>/_manifest.md`). The
  exact content depends on its `manifest_archetype`: `product-root`,
  `product-collection`, `architecture-root`, `architecture-views`, or
  `architecture-domain`. Root-only registries do not appear as empty tables in
  collections or domains. Each manifest carries only the recovery rows,
  evidence, and document invalidation/retirement conditions owned by that
  archetype. See [`reader-quality.md §6`](reader-quality.md#6-manifest-archetypes).
- **Adoption-cycle version labels** (`v2.43`, `v2.44`, `v2.45`, `v2.46`, `v2.47`)
  belong in `_manifest.md`, `STATUS.md`, `CHANGELOG.md`, or `04-records/decisions/` — not in
  prose owners. Prose may reference the protocol generation as "manifest" /
  "recovery index" / "registry"; it does not stamp doctor codes (`14W`, `14X`,
  `14Z`, `15A`, `15D`, `15F`, `15H`, `[CORE-REF-PROSE]`, `[MAXIM-OWNER]`,
  `[INTENT-OWNER]`, `[INTENT-TRUTH-NARRATIVE]`) or pillar phrases
  (`product_intent + product_truth`, `design_intent + design_truth`,
  `必备 pillar`, `intent_recovery_pillars`).

The manifest is still SSOT-owned content, still subject to Doctor and lint.
It is **not** a second authority — every row links back to the prose owner via
`[CORE-REF: ...]` anchor; if a manifest row contradicts the owner body, the
owner wins and the manifest is the one that gets fixed. The point of separation
is purely audience: prose owners speak to a cold reader trying to learn the
product, manifest files speak to doctor / cold-agent-sim / audit cycles.

If a covered product or architecture prose file still carries doctor codes,
adoption-cycle version labels, pillar vocabulary, full `intent_recovery_evidence`
strings, README-self failure-mode sections, or registry mirror tables that
duplicate `_manifest.md` rows, Doctor reports `[META-LEAKAGE]` (15I). The fix is
mechanical: extract the machinery into the area's `_manifest.md` and replace any
remaining prose reference with a one-line link plus the product/design idea the
surrounding section actually needs.

At protocol `>= 2.59`, a manifest begins with
`manifest_archetype: <value>`. A `covered` area cannot contain TODOs, author
handoffs, placeholder paths, empty required cells, or sections forbidden for
that archetype. Optional sections are omitted, not left as empty cargo.

### 2.0.1 Apex invariants and CORE-REF prose ownership (v2.43)

Repo-wide invariants already declared in a CORE-REF startup file
(`AGENTS.md`, `CLAUDE.md`, `.cursor/rules/*`, `.windsurf/rules/*`,
`GEMINI.md`) — for example one durable-write owner, a public-adapter boundary,
or mandatory request correlation — must have **exactly one prose owner** inside SSOT (typically
`02-architecture/README.md` core-invariants section or the responsible
architecture domain README) and **exactly one CORE-REF mention**. Other
SSOT body files (root summary, views, sibling domain READMEs,
`03-process/development/`, `01-product/`, **and (cycle-2 broadened scope) `glossary/`,
`04-records/decisions/` (excluding the ADR that originally established the invariant —
that ADR is the sole exception), `04-records/tech-debt/`, `04-records/bugs/`, `04-records/gotchas/`,
`03-process/release/`, `03-process/testing/`, `03-process/operations/`,
`03-process/security-and-compliance/`**) must reference the owner by link plus a one-line
orientation; they must not restate the invariant body as a paragraph,
full-clause bullet, or invariant-table cell. CORE-REF mentions of the same
invariant thin to a one-sentence summary that points at the SSOT owner via
the `[CORE-REF: <owner_path#anchor>]` syntax defined in
[`intent-ownership.md`](intent-ownership.md) §3; CORE-REF and SSOT must not
both maintain the prose body.

**`glossary/` entries for repo-wide invariants** must be a one-clause
positive definition + evidence pointer to the SSOT owner, not a verb-
clause restatement of the invariant body. **Non-establishing `04-records/decisions/`,
`04-records/tech-debt/`, `04-records/bugs/`, `04-records/gotchas/` entries** that touch an apex invariant
link the owner instead of recopying its body.

**Worked example — legal vs. illegal restatement (cycle-2)**:

> **Legal** (link + orientation, fires nothing):
>
> > Persistence runtime is the runtime owner for the durable-write invariant
> > (`[CORE-REF: ../README.md#core-invariants]`). This domain expands
> > state / contracts / failure modes along that owner chain.
>
> **Illegal** (verb-clause restatement, fires 14Z):
>
> > Every durable write passes through the command service, and transport
> > handlers may not write storage directly.
>
> The test is mechanical: if the sentence has a finite verb predicating
> what the invariant *does* (`只做`, `不在...拥有`, `保持`, `串行化为`,
> `必须经`, `要求保留`), it is restating the invariant body and must be
> replaced with `<one-sentence summary> ([CORE-REF: <owner_path#anchor>])`
> plus the evidence pointer the surrounding section needs. If the
> sentence merely names the invariant as the reason this owner exists
> (`本域的存在原因是支撑 durable-write invariant`), it stays. Wrappers like
> `本域 contract 一句摘要` / `具体到本域的落地形态` /
> `domain-form restatement` / `本域如何承接` do NOT exempt the trailing
> clauses; if a verb predicate inside the wrapper restates what the
> invariant does, doctor 14Z still fires on the wrapper body, not on the
> wrapper heading.

> **Illegal — `本域落地形态` / domain-form fork** (cycle-3, fires 14Z):
>
> > Storage contract summary: durable-write ownership + request correlation —
> > full body lives in the architecture README
> > core-invariants section (`[CORE-REF]`; this file does not restate it).
> > Domain-form restatement: transport handlers may only parse requests,
> > every mutation must pass through the command service, and every call must
> > leave a correlation record.
>
> The opening sentence + `[CORE-REF: ...]` is legal, but the trailing
> domain-form clause restates the transport, write-ownership, and correlation
> invariants using finite verbs predicating what each invariant *does*.
> Naming the wrapper
> `落地形态` / `domain-form` / `具体到本域` does NOT exempt the verb
> clauses — the mechanical test still fires.
>
> **Legal rewrite** (link + per-clause domain anchor, fires nothing):
>
> > Persistence runtime owns the runtime anchors for the durable-write and
> > request-correlation invariants
> > (`[CORE-REF: ../README.md#core-invariants]`).
> > This domain only gives the corresponding `path:LNN` anchors and guards
> > in state / contract / failure sections; it does not restate the
> > invariant body.

**Legal vs. illegal glossary cell shape** (for §2.3 indexed terms or
repo-wide invariants both):

> **Legal** glossary entry:
>
> | Durable-write owner | The invariant that one runtime owner coordinates persistent mutations. | see [`02-architecture/README.md#durable-write-owner`](#) — `path:src/storage/writer.ts` |
>
> **Illegal** glossary entry (multi-clause verb-bearing cell):
>
> | Durable-write owner | The command service serializes all mutations and rejects writes from every transport and worker path. | ... |
>
> The illegal form fires `[CORE-REF-PROSE]` (14Z) because the cell carries
> the invariant body. Replace with `Durable-write owner: see [<owner>]` plus an
> evidence-pointer column.

Capability → surface registry rows (capability ↔ route + handler
`path:LNN` ↔ component path ↔ test) follow the same single-owner rule:
pick one runtime owner per registry row (architecture domain README **or**
product capability file, not both), and let the other location link out.
Doctor enforces this via `[CORE-REF-PROSE]` (14Z); `[FORK]` (15D) covers
only the architecture-domain-to-architecture-domain subset, and
`[OWNER-ANCHOR]` (14F) covers anchor existence rather than prose
duplication.

### 2.1 01-product/

**Responsibility**: Long-lived product trunk. Records PRD/product intent, current and target product posture, users/operators, problems, product promises, product boundary, product language, product-level trade-offs, roadmap intent, product acceptance gates, and owner pointers for stable capabilities and journeys.

**Internal authoritative locations**:

- `01-product/README.md`: Reader Map and ownership index. Only routes the reader to PRD spine, product model, roadmap/acceptance, capability owners, and journey owners; does not copy fact bodies.
- `01-product/prd.md`: Current product brief. Explains users, real current surfaces and entry choices, the primary current journey, limited/target/out posture, core capabilities, non-goals, and owner links.
- `01-product/product-model.md`: Users, problems, product promises, product boundary, product language, and long-lived product trade-offs.
- `01-product/roadmap-and-acceptance.md`: Phases, roadmap intent, product acceptance gates, product-level gaps.
- `01-product/capabilities/`: When a capability has long-lived user value, boundary, non-goals, acceptance meaning, or roadmap state, and keeping it in `prd.md` or `product-model.md` would bloat them, split out `01-product/capabilities/<capability>.md`.
- `01-product/journeys/`: When a journey spans multiple capabilities, influences release/roadmap decisions, owns independent product acceptance, or repeatedly drives priority trade-offs, split out `01-product/journeys/<journey>.md`.

**Applicability**: Always applicable. `01-product/README.md`, `prd.md`, `product-model.md`, `roadmap-and-acceptance.md`, `capabilities/README.md`, and `journeys/README.md` are the required skeleton for new bootstrap.

**Split rules**:

- Keep facts at the highest stable owner. Do not create capability/journey files for one-off features, tickets, UI scripts, test cases, implementation flows, or short-term tasks.
- `01-product/capabilities/<capability>.md` is only created when the capability has long-lived user value, product boundary, non-goals, acceptance meaning, or roadmap state.
- `01-product/journeys/<journey>.md` is only created when the journey spans multiple capabilities, independently influences roadmap/release decisions, owns independent product acceptance, or repeatedly drives priority trade-offs.
- If a statement changes because product promises change, write it into `01-product/`. If a statement changes because code/runtime architecture changes, write it into `02-architecture/`, `03-process/testing/`, or another technical area.
- `01-product/README.md`, `capabilities/README.md`, and `journeys/README.md` are Reader Map and owner indexes, not duplicated fact stores.

**Product / Architecture boundary**:

- Do not migrate `02-architecture/views/critical-journeys.md` as a whole into product. Product journeys own user intent, touchpoints, experience constraints, and product acceptance; architecture critical journeys own system/runtime execution, lifecycle, failure/recovery, observability signals, domain owners, and Mermaid runtime diagrams.
- `02-architecture/views/current-target-gap.md` tracks implementation current/target/gap; `01-product/roadmap-and-acceptance.md` tracks product roadmap/acceptance intent.
- Architecture views/domains must link product owner when implementing, rejecting, or marking a product-constraint gap, rather than redefining product facts.
- `01-product/` is the intent layer. It owns users/operators, problems, promises, product boundary, non-goals, product language, acceptance meaning, product-level roadmap, and product-level gap.
- `02-architecture/` is the implementation response layer. It owns runtime owners, state/resources, contracts, lifecycle/concurrency, failure/recovery, verification, implementation current/target/gap, and technical response to product constraints.
- Product capability files stay thin. They may link architecture owners, but they do not copy runtime flows, API/SDK/schema details, persistence layout, or implementation listings.
- Architecture owners may link product constraints, but they do not redefine users, product promises, roadmap, non-goals, or acceptance meaning.

**v2.60 product two-axis bridge (replaces the v2.44 legacy shape)**:

A product owner must let a cold reader recover **what the user can rely on
today**, not only the desired future. Every stable capability, journey, and
user-visible surface records the two independent product axes owned by
[`reader-quality.md §3`](reader-quality.md#3-product-completeness), plus the
current user-visible behaviour and evidence or closure owner required there.
Do not use architecture `state` tags in product documents and do not invent a
third evidence vocabulary in a template, manifest, or Doctor rule.

Pre-v2.60 artifacts may contain architecture-style product state rows. Treat
them as migration evidence only: recover the current behaviour and closure
owner, map the row to the two product axes, then remove the legacy state field
from the live product owner. Silence, stale pointers, and an unowned "later"
note remain gaps.

**Product intent / truth narrative (v2.47)**:

When `product` is marked `covered`, the product trunk must let a cold reader
recover the product story before any owner-index or manifest table. The narrative
may live in `01-product/README.md` when that file is the user's first product stop,
or in `01-product/prd.md` when `01-product/README.md` clearly routes to it in the
opening prose. It must state who the product serves, what problem it solves, the
current and target promise, what is out of scope, the acceptance meaning, and the
first owner to inspect for details. The Core recovery manifest may then index
capabilities/journeys, but it may not be the only place where product intent and
current product truth are recoverable.

**Writing style**: see §2.0.

**Completeness and acceptance**: use
[`reader-quality.md §3`](reader-quality.md#3-product-completeness). Product
maturity and evidence fidelity are separate axes. A major audit inventories the
real mounted routes, navigation, creation modes, controls, settings,
diagnostics, external channels, commands, public interfaces, output artifacts,
notifications, and help/onboarding instead of assuming an old PRD still
describes the current product.

For the shared `Q01`-`Q21` profile, product owns only the user-visible promise,
limit, choice, feedback, and acceptance meaning. It links the architecture
mechanism and process/evidence owner or a named gap; it does not copy their
technical or procedural body. Dispose every Q item, but do not create twenty-one
fixed product headings.

### 2.2 02-architecture/

**Responsibility**: System concrete-design trunk. Records current implementation, target design, and gaps; explains system boundaries, runtime owners, design units, runtime flows, architecture views/diagrams, state/data/resource ownership, configuration variability, lifecycle/concurrency model, cross-boundary contracts, invariants, deployment topology, observability and diagnosis, failure recovery, and verification.

**Internal authoritative locations**:

- `02-architecture/README.md`: Quick-mental-model entry, carrying design brief, Reader Map / quick understanding map, technical operating-model summary, major runtime journeys, core invariants, view index, domain index, and implementation Current / Target / Gap summary.
- `02-architecture/views/`: Technical design-intent layer and cross-domain views, carrying operating model, critical journeys, state/data lifecycle, contracts/trust boundaries, failure/recovery, deployment/observability, current-target-gap, and the implementation design of how architecture responds to product constraints.
- `02-architecture/NN-<domain>/`: Concrete architecture domains — the stable owners of detailed runtime facts inside the technical trunk. What a domain owns is defined solely by [`architecture.md §3`](architecture.md#3-thin-defaults); what a domain reader surface must teach is defined by [`reader-quality.md §4`](reader-quality.md#4-architecture-completeness). New domains are direct children of `02-architecture/` and carry a two-digit reading-order prefix.
- Legacy compatibility: existing unnumbered `architecture/<domain>/README.md` or `architecture/domains/<domain>/README.md` can still serve as a domain authoritative location until protocol audit migration runs. New bootstrap must not create `architecture/domains/`.

**Applicability**: Always applicable. New bootstrap and major architecture reorganization prefer `views/ + direct numbered domains`; small CLI/library may have only a single-level `02-architecture/README.md`; large kernels/monorepos must recursively decompose into architecture domains.

**Information architecture**: the default model is a Runtime Owner Map. Root
routes to runtime owners and global invariants; views keep only cross-owner
technical views; domains own the detailed runtime/state/contract/failure facts.

**Design intent / truth narrative (v2.47)**:

When `architecture` is marked `covered`, `02-architecture/README.md` must let a
cold reader recover the design story before any owner-map, apex-index, or Core
recovery manifest table. The narrative must say why the runtime-owner axis is
the right decomposition, what current runtime truth is enforced today, which
parts remain target, proof-of-concept, or debt, which near-miss implementation inventories are
excluded from the design core, and which view/domain to inspect first for
details. A table can then route to owners, but the architecture root must not
make the reader infer design intent or current design truth solely from row
cells.
Do not use a universal 20-section checklist as the default domain template.

**Domain reader surface** (v2.59): every direct domain starts with a mental
model, why/boundary explanation, and a first-screen component diagram when the
boundary is non-obvious. It explains a canonical current flow before reference
tables. Runtime failure/recovery stays in the prose body. Document-self drift,
merge, supersession, and retirement conditions live in the
`architecture-domain` manifest, resolving the earlier conflict between the
v2.43 intent triad and v2.48 manifest separation. The questions a domain must
answer and the cold-reader gate live in
[`reader-quality.md §4`](reader-quality.md#4-architecture-completeness); they
are not a mandatory heading checklist.

**Applicable architecture questions (v2.60)**: the root, views, and domains
collectively explain deployment units and environments, operator-visible
health/metrics/logs/traces, and how diagnosis reaches the runtime owner when
those concerns affect behaviour. They also preserve bidirectional
product-to-architecture traceability: a technical response links the product
constraint it implements, while the product owner links the unique technical
owner or a named gap without copying implementation detail. Missing or
reasoned non-applicable answers stay visible in the architecture owner
inventory; they are never inferred from silence.

The shared `Q01`-`Q21` profile in
[`reader-quality.md §2.4`](reader-quality.md#24-shared-quality-risk-and-governance-profile)
is handled through disposition and routing, not twenty-one fixed architecture
headings. Architecture owns the applicable mechanism, boundary, failure, and
evidence direction; product and process owners keep their own layer of the
same concern. Missing implementation or proof stays a named gap with an owner.

**Split signal**: See [`architecture.md`](architecture.md). This file only declares the technical-trunk role of `architecture/` in the area model.

### 2.3 glossary/

**Responsibility**: Repository-specific vocabulary. Records business-domain terms, technical abstraction names, internal convention abbreviations, and the precise meaning of these words in this repo's context.

**Applicability**: Always applicable. Even small projects have their own naming conventions and domain terms.

**Content requirements**: Record only terms specific to this repo, or terms with special meaning in this repo. Standard industry terms and framework concepts are not recorded if not redefined. Each term contains name, one-sentence definition, optional first-introduced architecture domain or usage context. May group by domain.

**Finite vocabulary inventory (v2.60)**: `glossary/README.md` has exactly one
inventory schema: the six vocabulary families below. It does not also maintain
an alphabetical index, an old protocol hard list, or one H2 per category.
Every real term entry appears exactly once in one family and links its unique
entry owner. A family with no repository-specific terms carries a reasoned
`not_applicable` disposition that names what was checked and what change would
trigger another review. Silence and invented filler terms both fail G08.

1. **Product and user concepts** — repository-specific user or operator roles,
   problems, promises, capabilities, journeys, plans, entitlements, and visible
   labels.
2. **Architecture and runtime concepts** — named runtime owners, components or
   domains, agent roles, deployable units, contracts, resources, and technical
   boundaries.
3. **State, lifecycle, and workflow terms** — persisted states, transitions,
   workflow-result codes, record states, and repository-specific lifecycle
   labels.
4. **Trust, identity, access, and data-governance terms** — named identities,
   roles, permissions, tenant/workspace boundaries, data classes, consent,
   privacy, and governance labels.
5. **Evidence, verification, and operating terms** — repository-specific gates,
   proof levels, signals, service objectives, operating labels, named rule
   families, and rule-placement vocabulary.
6. **Concurrency-control terms** — named queues, leases, locks, scheduler keys,
   quota keys, and concurrency limits.

These families are inventory buckets, not six mandatory kinds of terminology.
Existence triggers coverage. Scan root instructions, product and architecture
owners, process and record owners, schema/enum/config declarations, source and
tests. Examples from the retired hard list map into the new families instead
of creating a second classification: workflow results and task/node states map
to family 3; agent-tier terms map to family 2; rule-placement/altitude terms and
an apex-maxim umbrella term map to family 5; named concurrency identifiers map
to family 6. Other terms follow their meaning. A root file with numbered named
rules still needs one repository term for that rule family plus unique rule-to-
owner links under [`intent-ownership.md`](intent-ownership.md) when the project
actually uses such a term; a repository without that vocabulary simply gives
family 5 the appropriate evidence-backed disposition.

**Single-prose-owner rule for indexed vocabulary**: each real term listed in
the six-family inventory has exactly one prose owner in `glossary/`.
`01-product/product-model.md` product-language section, `02-architecture/views/*`,
`02-architecture/NN-<domain>/README.md`, and `03-process/development/discipline.md` may
reference an indexed term, but only as a thin pointer row containing **at
most**: term name, ONE sentence of user-visible / runtime-owner /
discipline-side angle (no schema-enum repetition, no claim-routing
consequence list, no string-form / state-transition prose, no `Avoid
saying` anti-pattern that itself reasserts the code semantics), and a
`[CORE-REF: glossary/README.md#<anchor>]` link. A second sentence of
prose, a redefinition under a different rubric ("product semantics" /
"runtime semantics"), or restating the schema-enum / `path:LNN` evidence
in the secondary location is doctor-blocked even when the secondary
location adds an `Avoid saying` column. If the secondary location requires
more than one sentence to make the term useful at that altitude, split
that prose into the corresponding `01-product/capabilities/<capability>.md`
body or `02-architecture/NN-<domain>/README.md` invariants block keyed to a
non-canonical-vocab capability term, and keep the term row at this
altitude one-sentence-thin.

Deferring a discovered term through `STATUS.md` or another area does not satisfy
the inventory. The term entry or a reasoned family disposition must be present
now. Doctor keeps the compatibility labels `[WORKFLOW-STATE-VOCAB]` (15A) and
`[VOCAB-PROSE-FORK]` (15F), but 15A now checks the one six-family inventory and
existence-trigger discovery rather than fixed category headings; 15F checks the
single-prose-owner rule for every indexed term. `[MAXIM-OWNER]` (14X) still
checks unique owner mapping when numbered maxims actually exist.

#### 2.3.1 `glossary/README.md` inventory shape

Use the localized `glossary-readme.md` template. The README has one
`Vocabulary-family coverage` table (or its locked-language heading), exactly
six family rows, and no second term index or fixed category H2 set. Each
applicable row links every term-entry owner in that family once. An owner may
be a dedicated `glossary/<term>.md` file or a unique term H2 anchor in
`glossary/README.md` or a topic file. Each `not_applicable` row gives a
repository-specific reason, one resolving evidence-owner link, and an
observable review trigger. The family table itself never becomes a
paragraph-sized definition store.

**Split signal**: When terms exceed 30 entries or span multiple distinct business domains, create sub-files by domain.

**Entry template.** A dedicated glossary file renders from [`ssot-bootstrap/assets/templates/{en,zh}/glossary-entry.md`](../../ssot-bootstrap/assets/templates/en/glossary-entry.md): one-sentence positive definition, `Used in` inverse index, `Not to be confused with` boundary list, and `Source pin`. Existing README/topic aggregation remains legal when every definition has one unique H2 anchor and the family inventory links that exact anchor once. Split into dedicated files only when the split signal improves reading or maintenance; v2.60 does not force a file-per-term migration.

### 2.3.2 Shared process strategy and asset floor

Every applicable `03-process/` child satisfies PR15 and PR16 in its own domain.
It first explains why its method is coherent: strategy, conventions, invariants,
constraints, rationale, nearest meaningful alternative, and accepted trade-off.
It then keeps one finite inventory of stable assets the process creates, reads,
changes, verifies, hands off, or retires. Use these fields (localized as needed):
`Asset`, `Class`, `Purpose`, `Selection rule`, `Owner`, `Evidence`, `Risk`, and
`Retirement or replacement trigger`. Asset classes are chosen from real
repository material—scripts, tools, suites, workloads, fixtures, targets,
artifacts, runbooks, controls, or a clearly named project-specific class.

The inventory is not a run log and does not copy asset contents. Detailed
command, suite, workload, fixture, or control sections may expand an inventory
row but do not create a competing list. A covered child has exactly one table
with the eight fields above and at least one real asset row, or no table data
row and one visible reasoned-empty sentence with a specific reason, one
resolving responsible-owner link, and an observable review trigger. It does
not invent a row for an absent class, and it does not need separate
not-applicable rows for every possible class. This shared floor applies to
development, testing, benchmark, deployment, release, and every created
operations or security/compliance owner.

### 2.4 03-process/development/

**Responsibility**: How to run the project, and how to write code correctly in this project. Local environment setup, build commands, development workflow, common commands, coding conventions, and pattern language.

**Applicability**: Always applicable.

**Content requirements**: Summarize common commands and point to `package.json`, `Makefile`, `Dockerfile`, and other source files. Record non-obvious steps and preconditions in the build chain. Follow §2.3.2 for strategy rationale and the finite stable-asset inventory. Choose asset classes by project semantics, e.g., build, dev-server, codegen, lint/format, import rewrite, session analysis, diagnostics; do not copy script source, only explain purpose, selection, constraints, evidence, ownership, risk, and retirement.

When the project has coding conventions beyond linter/formatter coverage, also record:

- **Pattern language**: Key coding paradigms and convention patterns the project adopts (e.g., error-handling paradigm, dependency-injection conventions, logging-call conventions), pointing to representative implementation files. Record only conventions "a new agent will violate when writing code"; do not record rules that can be derived from linter config.
- **End-to-end skeleton flow**: Files and step list to touch when adding a typical feature type (e.g., new API, new Worker, new CLI command). Use pointers to templates or existing examples; do not write full code.
- **Agent operation preconditions**: Non-obvious prerequisites that must be satisfied before running tests, builds, or deploys (e.g., start docker compose first, build dependency packages first, do not skip pre-commit hook), and silent-failure manifestation upon violation.
- **Agent operation discipline**: Cross-task imperative rules a future agent must obey when working on this repository, even though no single file/module path scopes them. Each entry records `Rule` (single-sentence imperative), `Trigger` (file-glob, task pattern, or conversation signal that fires the rule), `Why` (concrete failure history with evidence pointers to `04-records/bugs/`, `04-records/decisions/`, or commits), `Evidence` (tests, integration suites, or other artifacts that enforce or witness the rule), and `Failure mode` (what visibly breaks when an agent violates it). Recommended sub-file: `03-process/development/discipline.md` with `DISC-NNNN <slug>` entries. Apex behavior maxims declared in a project root constraint file (`CLAUDE.md`, `AGENTS.md`, `.cursor/rules/*`, `GEMINI.md`) — numbered named rules such as `CLAUDE-MAXIM-N` / `CORE-RULE-N` — must follow the apex-maxim → SSOT-owner mapping in [`intent-ownership.md`](intent-ownership.md) §1: each maxim has exactly one owner (typically a unique `DISC-NNNN`), and the root constraint file holds only a one-line `[CORE-REF: ...]` link, not the maxim body.
- **Boundary with `04-records/gotchas/`**: A `gotcha` is a file/module-scoped pitfall recorded as a `don't X / do Y instead` pair against a specific code surface (e.g., "do not import `foo.bar.legacy_helper`"). An entry under `03-process/development/` discipline is a task-pattern-scoped imperative rule that applies across files and tasks (e.g., "when modifying any SDK adapter, run the real-SDK integration suite before claiming done"). When in doubt: if a future agent's first failure mode is reaching for a wrong API in a known file, write a gotcha; if the failure mode is following a procedurally insufficient workflow across many files, write a discipline entry.
- **Split signal for discipline**: Create `03-process/development/discipline.md` the first time a recurring agent-operation rule is confirmed. When entries exceed 10 or fall into distinct domains (delivery, verification, dependency hygiene, etc.), split into sub-files (`discipline/delivery.md`, `discipline/verification.md`, …) under a `03-process/development/discipline/` sub-folder.

**Split signal**: In a monorepo where each workspace has an independent development flow, split into sub-files. When pattern language and skeleton flow are large, may split into a `conventions.md` sub-file. When agent operation discipline grows, follow the discipline-specific split signal above.

### 2.5 03-process/testing/

**Responsibility**: How to test correctness. Records the stable test strategy, test selection matrix, quality gates, fixtures / test data, current correctness baselines, known gaps, and defensive-test source map.

**Applicability**: Applicable when test files, test scripts, or test configs exist. When no tests, declare the current state and record the reason.

**Content requirements**: Summarize test commands and point to test config files. Record the why of test strategy, e.g., why the test layers are divided this way. When no evidence, write `unknown` or `gap`; do not guess test level from script name.

`03-process/testing/` is not a verification run ledger. Test results are evidence, not testing facts. Do not append batch-by-batch command transcripts, dates, green/red summaries, or "recent validation" rows unless the result changes a long-lived testing fact: a command/gate changed, a correctness baseline changed, a fixture contract changed, a known gap opened/closed, or a defensive-test mapping was added/removed. Use commit hashes, issue IDs, bug entries, CI links, or release notes as evidence pointers from the stable fact instead of carrying chronological run history in this area.

`03-process/testing/` also does not own benchmark methodology or performance/cost/capacity floors. If a performance check is a pass/fail test gate, `03-process/testing/` may name when the gate runs and what blocks merge or release, but the measured workload, metric, environment, floor, comparison rule, and trend interpretation live in `03-process/benchmark/`. Link to `03-process/benchmark/` instead of copying the benchmark table.

Recommended stable sections:

- **Test strategy**: layers, boundaries, trade-offs, and why those layers exist.
- **Test selection matrix**: what to run for each change family and why.
- **Quality gates**: PR/release/blocking gates, required setup, and failure semantics.
- **Current correctness baseline**: stable expected state such as "frontend lint baseline is 0 warnings" or "snapshot baseline is current"; update only when the baseline changes.
- **Fixtures / test data**: fixture owners, update risk, data contracts, and regeneration constraints.
- **Known gaps**: missing CI coverage, flaky suites, disabled tests, or manual-only verification with blocking level.
- **Defensive test sources**: key regression tests mapped to `critical` / `major` / `recurred` bugs or gotchas.

When `04-records/bugs/` contains `critical` / `major` / `recurred` fix records, optionally maintain a **defensive-test source** section: list key tests driven by bug regression (test file/case -> `04-records/bugs/` entry pointer). This lets an agent understand the reason for a test's existence when modifying protected code, avoiding accidental deletion or bypass. Exhaustiveness not required; record only entries where "deleting this test will let the historical bug recur".

**Split signal**: Split when unit/integration/e2e/contract/manual and other test types each have independent config and strategy. Do not split benchmark detail under `03-process/testing/`; route it to `03-process/benchmark/`.

### 2.6 03-process/benchmark/

**Responsibility**: How to benchmark. Records current benchmark suites, canonical workloads, metrics, environments, runner commands, baseline/floor policy, comparison rules, trend interpretation, known gaps, and links from promoted benchmark conclusions to product, architecture, release, debt, or decision owners.

**Applicability**: Applicable when the project has performance, cost, latency, throughput, memory, capacity, scale, model-token, provider-cost, or resource-use measurements that guide engineering decisions. When no benchmark exists, declare `not_applicable` or `gap` with the reason and risk.

**Content requirements**: A cold reader should be able to answer "what benchmark do I run and what floor matters?" from this area. Record the stable method, not every run. Include suite names, workload/data shape, metric units, environment/tooling assumptions, runner command, baseline source, floor or regression threshold, comparison rule, trend interpretation, and the owners that consume the conclusion.

Recommended stable sections:

- **Benchmark suites**: suite purpose, canonical workload, runner command, and required environment.
- **Metrics and floors**: metric units, current floor/baseline, regression threshold, and evidence pointer.
- **Comparison rules**: how to compare branches, hardware, data shape, provider/model, cache state, warmup, variance, and confidence.
- **Trend interpretation**: how to read sustained drift, one-off noise, capacity headroom, and cost changes.
- **Known gaps**: missing workloads, unstable environments, unmeasured surfaces, or floor uncertainty.
- **Decision links**: product promises, architecture choices, release gates, debt, or ADRs that consume benchmark conclusions.

`03-process/benchmark/` is not a chronological run log. A raw benchmark run, trial transcript, dated result table, or one-off comparison belongs in final response evidence, CI artifact, release note, stop-review evidence, or `04-records/research/` when reusable. Update `03-process/benchmark/` only when the stable suite, workload, metric, environment, floor, comparison rule, trend interpretation, known gap, or consuming decision link changes.

**Boundary with other owners**:

- `03-process/testing/` owns correctness checks, test selection, quality gates, fixtures, and defensive tests. It may link to a benchmark gate, but it does not own benchmark floors or interpretation.
- `04-records/research/` owns one-off benchmark studies, exploratory measured trials, POCs, and reusable evidence packets until a stable method, baseline, or rule is promoted into `03-process/benchmark/`.
- `02-architecture/` may consume benchmark conclusions as evidence for a design choice, risk, or current/target/gap row; it does not own benchmark methodology or current floors.
- `03-process/release/` may name a release gate that depends on a benchmark floor; the benchmark owner keeps the floor and comparison rule.

**Split signal**: Split when suites have independent workloads, metrics, environments, or consumers. Common splits are by runtime owner, workload family, provider/model, capacity tier, or cost surface.

### 2.7 03-process/deployment/

**Responsibility**: How to deploy or distribute. Deployment method, environments, infrastructure form, CI/CD pipeline.

**Applicability**: Applicable when deployment behavior exists. Pure libraries/pure tools declare not-applicable or describe distribution, e.g., package publish.

**Content requirements**: Summarize and point to `Dockerfile`, `k8s/`, `terraform/`, CI config, and other source files. Record non-obvious steps, environment differences, and rollback strategies in the deployment flow.

**Split signal**: Split when there are multiple environments, multiple deployment targets, or multiple independent deployment units.

### 2.8 03-process/release/

**Responsibility**: Release process and versioning strategy. How to release, version-number rules, changelog maintenance, release pipeline.

**Applicability**: Applicable when versions, tags, changelog, release scripts, package publish, or deploy release exist.

**Content requirements**: Summarize and point to release scripts, CI config, or version files. Record the why of versioning strategy and follow §2.3.2 for the finite stable-asset inventory. Include release-adjacent assets such as version sync, changelog generation, publish, artifact signing, or import rewriting when they exist. Sync-link consistency assets that affect architecture current/target/gap link to the corresponding architecture domain or decision.

**Split signal**: Split when multiple independently releasable artifacts exist.

### 2.8.1 03-process/operations/

**Responsibility**: How to operate a running system after delivery. Own the
stable operator path for health assessment, routine maintenance, incident
triage, capacity or quota response, backup/restore execution, continuity
drills, and handoff. Deployment owns putting a change into an environment;
the architecture deployment/observability view owns topology and signal
meaning; operations owns what an operator repeatedly does with those facts.

**Applicability**: Create this owner when the repository produces a deployed
service, long-running worker, managed data system, scheduled workload, or any
runtime with recurring operator duties. A distributable library or one-shot
tool may omit the directory and use a reasoned process-layer
`not_applicable` disposition in the STATUS quality register.

**Content requirements**: Explain triggers and authority, the ordinary path,
expected visible result, repeat/concurrent/partial-completion behaviour,
stop/escalation conditions, recovery, and fitting evidence. Link the unique
architecture and deployment owners; do not copy topology, signal definitions,
or one incident transcript. Cover each applicable `Q04`-`Q09`, `Q12`, and
`Q18`-`Q21` operating concern by owner or named gap rather than by empty
headings. For example, this owner may carry capacity response, continuity
drills, decommissioning, environmental operating evidence, model/data-drift
response, or billing and entitlement reconciliation when those are recurring
operator duties; it must not claim that every repository needs all of them.

**Split signal**: Split only when environments, runtime units, or operator
roles have materially different triggers, authority, recovery, or evidence.

### 2.8.2 03-process/security-and-compliance/

**Responsibility**: How the repository executes recurring security, privacy,
compliance, licensing, and disclosure controls. Own assessment and review
cadence, vulnerability or dependency response, access review, audit-evidence
collection, security-incident handoff, and customer or regulator notification
duties. Product owns user promises and consent meaning; architecture owns
trust boundaries and mechanisms; this process owner explains how controls are
performed and proved.

**Applicability**: Create this owner when the repository handles authentication
or authorization, personal/sensitive/regulated data, tenant isolation,
untrusted public input, signed or distributed artifacts, material dependency
or license obligations, or customer/regulatory duties. Otherwise omit the
directory and record a reasoned process-layer disposition; do not create an
empty compliance page.

**Content requirements**: Name scope, roles and authority, inputs, ordered
control path, evidence and retention, exposure and notification boundaries,
stop/escalation, and recheck triggers. Route applicable `Q09`-`Q11` and
`Q13`-`Q17` concerns to product, architecture, process/evidence, and gap owners
without copying their narratives. When an evaluation limit (`Q20`) or a paid
action (`Q21`) creates a recurring security, privacy, compliance, approval, or
disclosure duty, route that duty here while keeping technical validity and
commercial transaction correctness in their respective owners.

**Split signal**: Split only when independent regimes or control programs have
different owners, evidence, or notification paths.

### 2.8.3 Shared record index and state contract

The five record collections use the same lightweight R03/R14 shape without
forcing the same domain vocabulary. Every real entry has one stable ID. The
entry owner may be an independent file or, for an existing topic-aggregated
collection, one unique `## <ID>` heading anchor. The collection index contains
that entry exactly once, links the precise file or anchor with an `Entry owner`
Markdown link, mirrors both state axes, and keeps narrative reasons in the
entry. A covered collection has no orphan entry, unresolved link, duplicate ID,
or index/entry state mismatch.

The collection-root `README.md` is the one complete ID-and-state index for that
record type, including entries stored in subfolders. A nested `README.md` may
explain a subgroup and link its children, but it must not repeat the full state
rows or create a second index for the same IDs. This gives a reader one place
to answer "what records exist and what state is each one in?" while still
allowing large collections to have useful local navigation.

For topic-aggregated gotchas, every `## GOT-NNNN` block carries an explicit
**Record status / hazard state** line with `current` / `active` (localized
equivalently) before the next H2. Legacy “status and trigger” text aliases only
the hazard axis and cannot stand in for `record_status`.

| Record type | Record lifecycle axis | Separate domain axis | Compatibility |
|---|---|---|---|
| Decision | `record_status`: `accepted / deprecated / superseded` | `implementation_state`: `pending / partial / implemented / diverged / superseded` | legacy `status` mirrors `record_status` |
| Research | `record_status`: `draft / validated / stale / superseded` | `adoption_state`: `unpromoted / partial / promoted / rejected` | legacy `status` mirrors `record_status`; `promotion_state` aliases `adoption_state` |
| Bug | `record_status`: `current / archived / superseded` | `failure_state`: `open / fixed / recurred` | legacy `status` mirrors `failure_state` |
| Gotcha | `record_status`: `current / archived / superseded` | `hazard_state`: `active / resolved` | legacy `status` mirrors `hazard_state` |
| Technical debt | `record_status`: `current / archived / superseded` | `repayment_state`: `active / resolved / obsolete` | legacy `status` mirrors `repayment_state` |

Every record answers two different questions. First: "Is this document still a
valid source of guidance?" That is `record_status`. Second: "What has happened
to the decision, finding, failure, hazard, or debt described by the document?"
That is the type-specific domain axis. An accepted decision can still be
unimplemented. Validated research can still be unpromoted. A current bug record
can describe a failure that has been fixed, and a current gotcha can describe a
hazard that has been resolved but remains worth remembering. Keeping the two
answers separate stops document lifecycle from being mistaken for real-world
progress. Existing consumers may keep only a documented compatibility field
until the entry is touched or the collection is advanced to the v2.60 covered
contract; do not force meaningless file splits merely to migrate metadata.

### 2.9 04-records/decisions/

**Responsibility**: Major decisions and reasons. Why this and not that, decision context and consequences.

**Applicability**: Always applicable. Initially may be empty, grows with repo evolution.

**Content requirements**: `README.md` serves as the decisions index and follows
§2.8.3. Each major decision is an independent file containing background,
decision, consequences, scope of impact, and lifecycle fields:

- `record_status`: `accepted` / `deprecated` / `superseded`
- `status`: compatibility mirror of `record_status` when retained
- `implementation_state`: `pending` / `partial` / `implemented` / `diverged` / `superseded`
- `created_on`: ISO date (`YYYY-MM-DD`) the decision file was first written. Required. Anchors the decision in time so `status: deprecated` / `superseded_by` chains and conflict adjudications keep their temporal context.
- `updated_on`: ISO date of the most recent material edit to the decision body (status flip, implementation_state change, consequence rewrite). Required from the first edit after creation; equals `created_on` if untouched.
- `introduced_in`: 7+ char git SHA of the commit that first added this decision file to the repository. Required. Lets future agents jump from the decision to the originating change set.
- `updated_in`: list of 7+ char git SHAs for subsequent material edits, newest last (typically the commit referenced by `updated_on`). Required from the first edit after creation; omit when the file has only ever had its introducing commit.
- `superseded_by`: optional, pointer to the new decision that overrides this one.
- `supersedes`: optional, pointer to the old decision overridden by this one.
- `closure_condition` (v2.43): required when `implementation_state` is `pending`, `partial`, or `diverged`. A falsifiable predicate a future agent or Doctor can evaluate without re-litigating intent — e.g. `tests/web/test_routes_mutation_free.py::test_no_policy_in_routes passes`, `grep -E 'mutation|policy' src/myapp/web/routes/ returns no match`, `STATUS.md ADJ-NNNN closes with verdict=converged`, `src/myapp/engine/planner.py absent`. Narrative such as "remaining scope is clear" or "route-thinning continues" is not a closure_condition. Omit (or write `not_applicable` with a one-line reason in the body) only when `implementation_state` is `implemented` or `superseded`.
- `revisit_signal` (v2.43): required when `implementation_state` is `pending`, `partial`, or `diverged`. A concrete trigger that tells a future agent when to re-read this ADR — e.g. `path-glob:src/myapp/web/routes/**`, `commit touches schema.sql`, `new route family is introduced`, `STATUS.md adjudication ADJ-NNNN reopens`. Path globs, file patterns, test names, or named events are acceptable; "when relevant" or "from time to time" is not.

`implementation_state` indicates the relation between design intent and current implementation:

- `pending`: Decision accepted but landing not started.
- `partial`: Only part is landed; remaining scope is clear.
- `implemented`: Current code/config/schema/test matches decision intent.
- `diverged`: Current implementation conflicts with decision intent; must simultaneously write into `STATUS.md` open adjudications.
- `superseded`: Decision replaced by a new decision; no longer the current design intent.

Record only decisions that are hard to reverse or have cross-architecture-domain impact; do not record daily implementation details. Overridden old decisions stay in place and are marked, not physically archived, to preserve historical context and link integrity. Old ADRs imported during bootstrap or audit that legitimately lack a creation commit must still record `introduced_in` as the commit that brought them into `SSOT/04-records/decisions/`; `created_on` reflects the original authoring date when it is recoverable, otherwise the import date with a one-line note in the body explaining the gap.

A `pending`, `partial`, or `diverged` ADR without both `closure_condition`
and `revisit_signal` is doctor-blocked (`15B [ADR-CLOSURE]`). The two fields
are not narrative replacements for `consequences` — they exist so a cold
agent can decide in seconds whether the ADR is still open against today's
tree.

**Split signal**: Naturally multi-entry; one file per decision, naming format `NNNN-<slug>.md`.

### 2.10 04-records/gotchas/

**Responsibility**: Known pitfalls, failure modes, "don't touch here because X". Records tacit knowledge that code cannot express.

**Applicability**: Always applicable. Initially may be empty, grows with stepped-on-mine experience.

**Content requirements**: `README.md` follows §2.8.3 and indexes each pitfall by
unique ID, record lifecycle, hazard state, trigger, and exact entry-owner link.
An entry may be its own file or a unique `## GOT-NNNN` anchor in a topic file.
Each pitfall explains what it is, why it is dangerous, and scope of impact.
Mitigation `[SHOULD]` be given in pairs of "do not do X + do Y instead" to make
entries actionable rather than only record failure stories -- a gotcha that
only describes failure symptoms without an alternative has very low value.
Optional additions:

- **Trigger** `[SHOULD]`: Describe "when the agent does what operation it should first check this gotcha". Format is task type or file/module path matching. Examples: `Trigger: when modifying any file under src/auth/`, `Trigger: when adding a new database migration`. Triggers let the reading protocol route precisely -- the agent proactively drills into the gotcha before executing matching operations, rather than relying on the generic "read gotchas when changing code" rule. A cross-task procedural rule that applies regardless of file scope (e.g., "always run real SDK integration suite before claiming a fix done") is not a gotcha; route it to `03-process/development/` discipline (see §2.4) so future agents can find it via task-pattern routing rather than per-file gotcha scan.

Hazard state (`hazard_state`; legacy `status` mirrors it):

- `active`: The pitfall still exists.
- `resolved`: The pitfall no longer holds due to architecture change or fix; attach invalidation reason and related decision/change.

Resolved entries remain in the document as historical reference, but the index must mark them clearly to avoid agent risk misjudgment.

**Split signal**: When pitfalls exceed 10 entries, group by architecture domain or topic.

### 2.11 04-records/bugs/

**Responsibility**: Durable defect records. What is failing, who or what is
affected, what is known versus still uncertain, what action comes next, how the
failure was fixed when a fix exists, and what should be remembered.

**Applicability**: Always applicable. Initially may be empty; grows when a
confirmed failure has cross-session value because its trigger, impact,
diagnosis, remediation, or prevention must remain findable.

**Content requirements**: `README.md` follows §2.8.3 and indexes each preserved
failure mode by unique ID, record lifecycle, failure state, severity, and exact
entry-owner link.

- `critical` / `major`: Independent file containing symptom, established or
  still-uncertain cause, remediation plan, scope of impact, takeaway/pattern,
  prevention or containment, related areas, and external references.
- `minor`: A trivial fix with no reusable lesson need not be indexed. Once
  indexed, it still needs one lightweight entry owner (file or unique anchor);
  do not hide the root-cause narrative in the index row.

Agent quick entry:

- `critical`, `major`, `open`, `recurred`, or repeatedly referenced bug entries
  should start with a compact quick-entry surface before the full analysis.
- The quick entry answers: symptom/trigger signature, first places to inspect, do-not-do boundary, minimal verification/preventive test, and current status/evidence pointer.
- The quick entry does not replace root-cause analysis or recurrence timeline. It is the first screen for a future agent touching the related code.

Regression Granularity Rule:

- `critical`, `major`, `open`, or `recurred` bugs cannot be recorded only as
  broad topics; they must be split to failure-mode-level entries.
- A single record must answer trigger condition, symptom, known or suspected
  cause, next remediation or fix pattern, current validation/containment, and
  related gotcha / architecture / decision. Unknown cause or fix is written as
  `unknown` with an owner and the evidence that would resolve it, never guessed.
- Same symptom with multiple root causes must be split into multiple entries; same root cause recurring multiple times may append a recurrence timeline in the same entry.
- `minor` or trivial bugs do not enforce a full post-mortem unless they recur, escalate to major, or expose architecture/test gaps.

Failure state (`failure_state`; legacy `status` mirrors it):

- `open`: The failure is confirmed and has not yet been fixed. Record the
  current containment if any, remediation owner, next falsifiable action, and
  what evidence would allow `fixed`.
- `fixed`: Already fixed.
- `recurred`: Previously believed fixed but observed again. Link the earlier
  fix, explain the recurrence evidence, and name the next action and owner. If
  a new fix has not yet been verified, say so and record the evidence needed to
  return to `fixed`; do not invent a fix reference.

When a failure or fix reveals a gotcha, tech debt, decision, product gap, or
architecture defect, sync-update the corresponding area. SSOT does not replace
an issue tracker: the tracker owns scheduling and delivery workflow, while this
record owns durable failure knowledge and its current `open`, `fixed`, or
`recurred` truth. Do not create an SSOT entry for every transient issue.

**Split signal**: When entries exceed 15, group by architecture domain or time period.

### 2.12 04-records/tech-debt/

**Responsibility**: Technical-debt register. Known debts, temporary workarounds, planned refactorings.

**Applicability**: Always applicable. Initially may be empty.

**Content requirements**: `README.md` follows §2.8.3 and indexes each debt by
unique ID, record lifecycle, repayment state, priority, and exact entry-owner
link. Each debt item records what it is, why it was incurred, scope of
impact, repayment plan, priority, and the next concrete action or retrigger that
prevents the debt from becoming silent backlog. Repayment state
(`repayment_state`; legacy `status` mirrors it):

- `active`: The debt still exists.
- `resolved`: Debt repaid; attach resolution method and related change/decision.
- `obsolete`: Debt no longer relevant due to architecture change; attach reason and related decision.

Required lifecycle fields for active repayment entries (YAML frontmatter,
alongside `record_status`, `repayment_state`, and `priority`):

- `closure_condition`: a falsifiable predicate a future agent or Doctor can
  evaluate to flip this debt from `active` to `resolved` without re-debating
  intent — e.g. `tests/integration/test_engine_dfs_mission_only.py passes
  AND src/myapp/engine/planner.py is absent`,
  `02-architecture/NN-storage-runtime/current-target-gap.md row R-NNN deleted`,
  `BUG-NNNN closed and regression test green`,
  `grep -nR 'TODO(DEBT-0001)' src/ returns no match`. Narrative such as
  "synchronize when advancing X" or "review periodically" is not a
  closure_condition.
- `revisit_signal`: a concrete trigger for re-reading this debt entry —
  e.g. `path-glob:src/myapp/engine/**`, `schema.sql touched`,
  `new mission executor branch added`, `BUG-NNNN reopened`. Path globs,
  file patterns, test names, or named events are acceptable; "when
  relevant" is not.

Both fields are required on every `repayment_state: active` entry. `resolved` and
`obsolete` entries do not require these fields once closed (the closure
record itself supersedes them); historical entries imported during
bootstrap or audit may carry `closure_condition: not_applicable_imported`
with a one-line note in the body explaining the import gap.

An `active` debt entry without both `closure_condition` and
`revisit_signal` is doctor-blocked (`15C [DEBT-CLOSURE]`).

Active recommendation / non-silent deferral floor (v2.53): active debt is not a
passive backlog. When a task overlaps an active debt's trigger, path glob,
owner, failure mode, capability, command, or verification guard, the agent must
surface it as `fix-now`, `recommend-now`, `defer-visible`, or
`ignore-for-scope`. A debt may stay active, but the deferral must remain visible:
owner or owner record, reason, closure condition, revisit signal, verification
guard, and next concrete action. Generic repayment prose such as "later",
"someday", "future work", "handle this later", or a locked-language equivalent
is invalid unless it is attached to that visible deferral record. The issue
tracker may own scheduling and assignment; SSOT owns the signal that future
agents must not miss.

Temporary-surface registration (v2.52): every fallback, compat shim,
temporary workaround, later-remove path, TODO/FIXME/HACK/WORKAROUND marker, or
temporary waiver that is intentionally left in current code, config, tests, or
SSOT must be registered. The registration may live in `04-records/tech-debt/`, `04-records/bugs/`,
`04-records/decisions/`, or an open STATUS gap when no better owner exists, but it must
carry the same five fields:

- `owner`: the SSOT owner or engineering owner responsible for clearing it;
- `reason`: why the temporary surface is allowed to exist now;
- `closure_condition`: a falsifiable predicate that removes or resolves it;
- `revisit_signal`: the path/event/test trigger that makes agents re-read it;
- `verification_guard`: the command, grep predicate, test, or runtime evidence
  that proves the temporary surface did not silently become permanent.

For `04-records/tech-debt/` entries, use `temporary_surface: true` in frontmatter and add
`owner`, `reason`, and `verification_guard` beside `closure_condition` and
`revisit_signal`. A hidden temporary surface is worse than an honest active
debt: Doctor reports `[TEMP-SURFACE]`, and covered areas cannot rely on it as a
closed fact.

Resolved/obsolete entries remain in the document as historical reference and are marked clearly in the index.

Active, high-priority, or cross-cutting debt entries should include an agent
quick entry near the top: trigger/scope, first files or tests to inspect,
do-not-do boundary, repayment verification, next action or "must handle when"
condition, and current status/evidence pointer. Historical rationale can follow;
the first screen must help the next agent avoid deepening the debt.

**Split signal**: Naturally multi-entry; one file per major debt.

### 2.13 04-records/research/

**Responsibility**: Structured research and PoC evidence packets. This area
preserves reproducible methods, inputs, artifacts, observations, limitations,
and distilled claim rows that may be reused by future product, architecture,
decision, testing, bug, gotcha, or debt owners.

**Applicability**: Applicable when a task produces research, landscape review,
PoC, experiment, benchmark, spike, external comparison, or measured trial output
that is too valuable to discard but is not itself a stable product or
architecture fact. Do not create the directory merely because source-material
rows mention research. Do not create a top-level `SSOT/research/`.

**Content requirements**: `README.md` is only the index and follows §2.8.3.
Entries normally use independent files named `NNNN-<slug>.md`. Each entry has a
unique ID, `record_status`, and `adoption_state`, then records the research question, method,
inputs, environment or source set, artifacts, observations, known limitations,
`do_not_use_for` boundary, reusable claim rows, `promotion_targets`, and
`recheck_trigger`. Claim rows should be distilled enough to promote one by one:
claim, evidence packet anchor, confidence, boundary, and target owner. Existing
`promotion_state` is a compatibility alias for `adoption_state`; when both are
present they must match. The old overloaded `status: promoted` migrates to
`record_status: validated` plus `adoption_state: promoted`.

**Authority boundary**: Research records are not authority mirrors. They do not
own product promises, architecture contracts, decision outcomes, testing policy,
or current implementation truth. They store evidence packets and reusable claim
rows. Long-lived facts become normal SSOT facts only when the relevant owner
absorbs the promoted claim and links back to the packet as evidence. Owners
absorb the durable fact, not the whole packet.

**Source-material boundary**: Raw docs, external artifacts, copied notes, and
working PoC files remain source material. They still need lifecycle downgrade
fields or a STATUS inventory row per [`source-material.md`](source-material.md).
The research record may point to them as inputs or artifacts, but it does not
make those raw materials current authority.

**Split signal**: Naturally multi-entry; one file per research/PoC packet.

---

## 3. Recursive directory rules

Every folder must have a `README.md` as index. Content entries are independent `.md` files. When an entry needs further grouping, create a sub-folder and recursively apply the same rule.

A README, index, or Reader Map is an entry surface. It may route the reader, define area scope, list authoritative owners, and expose only stable index fields explicitly assigned to that index, such as ID, title, status, severity, priority, owner link, or evidence direction. It must not maintain chronological run history, latest verification rows, generated counts, child body facts, or child-entry state already owned by an entry file, frontmatter, CI artifact, bug entry, release note, stop-review record, or another owner. Protocol-authorized indexes remain allowed; keep status/severity/lifecycle fields minimal and do not copy body narrative.

Example:

```text
SSOT/02-architecture/
  README.md
  views/
    README.md
    operating-model.md
    critical-journeys.md
    state-and-data-lifecycle.md
    contracts-and-trust-boundaries.md
    failure-and-recovery.md
    deployment-and-observability.md
    current-target-gap.md
  10-query-engine/
    README.md
    _manifest.md
    parser.md
    planner.md
  20-storage-engine/
    README.md
    _manifest.md
    buffer-manager.md
    page-format.md
```

Architecture domains are direct, two-digit-numbered children of
`02-architecture/`. Do not reintroduce a `domains/` wrapper in a recursive
example; the number gives a cold reader the intended owner order.

Do not mechanically create SSOT hierarchy for source directories, package names, class names, or team names. A split must improve readability, explain independent boundaries, or reduce maintenance conflict.

Do not create ad hoc shadow ledgers in non-owner files. Chronological proof-of-work, task/run/status logs, latest-run rows, and dated pass/fail transcripts belong only in an authorized owner: STATUS stop-review evidence, source-material absorption matrix, core-reference review, bug entries, decision entries, gotcha entries, tech-debt entries, release notes, CI artifacts, commits, final responses, or the entry file whose lifecycle is being described. If a repeated incident creates a reusable diagnostic pattern or policy, write the stable pattern to the relevant owner and link to the incident owner instead of appending dated incident history.

---

## 4. Task-entry map

Do not add a mandatory top-level `task-playbooks/` or similar authoritative area. If git history, commit review, or long-running sessions show certain R&D task clusters are high-frequency or high-risk, may add a thin entry map `task-entry map` in `SSOT/README.md`.

Applicable signals include:

- Repeatedly fixing the same kind of failure.
- Frequently triggering cross-domain migration.
- Release, recovery, data migration, or compatibility operations prone to error.
- Long-term repeated user requests for the same type of high-risk review entry.

`task-entry map` only does entry indexing. Each row describes the task cluster, trigger signal, authoritative location to read first, and final review checkpoint. It must not maintain independent long-lived facts, must not copy playbook body; facts still go back to the corresponding authoritative location. When no clear high-frequency/high-risk task cluster exists, write `not_applicable` or do not create the section.

The task-entry map — not the preflight gate — decides whether a task reads the `01-product/README.md` or `02-architecture/README.md` trunks. The preflight mandatory read floor is `STATUS.md` plus `SSOT/README.md` as the router; the trunks are read only when the task-entry map routes the task to them. When the map is missing or does not route the current task, preflight falls back to reading both trunks so a thin-router repository still gets trunk coverage. This makes the task-entry map the single owner of trunk-read routing, consistent with the `trigger` / path-glob fields on `04-records/gotchas/` (§2.10), `04-records/bugs/` (§2.11), and `04-records/tech-debt/` (§2.12) entries.

---

## 4.1 Default fallback for unrouted durable knowledge

When a durable fact emerges from conversation or change review but does not clearly match any single mapping row in the conversation-signal table (`update-routing.md §3`) or the task-entry map above, use this fallback classifier rather than guessing or skipping the write:

| Signal | Drop target | Rationale |
|---|---|---|
| User problem, product promise, visible entry/action/result, product boundary, or acceptance meaning | The matching `01-product/` spine, capability, or journey owner | Product intent and user-visible truth belong with the product; link technical delivery instead of replacing the promise with code facts. |
| Current runtime behaviour, state owner, contract, trust/config boundary, deployment shape, failure, or recovery mechanism | The matching `02-architecture/` root, view, or direct numbered owner | Architecture owns how the current system responds; keep intended-but-unlanded product meaning in product and mark implementation gaps honestly. |
| Ordinary repeatable work path for developing, testing, measuring, deploying, releasing, operating, or assessing controls | The matching `03-process/` child owner | A normal procedure is broader than a development-discipline imperative; route by the result the contributor or operator must produce. |
| Imperative-procedural rule ("always X before Y", "never Z because the real service disagrees with the mock", "from now on, do W first") | `03-process/development/` discipline entry | Cross-task procedural rules owned by development practice. Do not collapse into a single bug entry. |
| Recurring live-operation rule (health, maintenance, incident, quota, backup/restore, continuity, or recovery handoff) | Conditional `03-process/operations/` owner | Operator procedure after delivery; link deployment and architecture signal/state owners instead of copying them. |
| Recurring security/privacy/compliance control or evidence duty | Conditional `03-process/security-and-compliance/` owner | Control execution and evidence process; link the product promise and architecture mechanism. |
| File/module-scoped trap ("do not call function A from module B", "config C has a quirk") | `04-records/gotchas/` entry | Scoped to a concrete code surface; future agents read by path trigger. |
| Trade-off or design constraint ("we chose X over Y because Z", "must not exceed N") | `04-records/decisions/` entry | Long-lived why record; future agents need the rationale to avoid re-litigation. |
| Bug root cause, symptom, and prevention ("the crash in component C was because...") | `04-records/bugs/<entry>.md` takeaway section | Fix history; high-severity entries carry a takeaway/prevention field and may cross-link to `03-process/development/` discipline if a recurring procedural gap is confirmed. |
| Bounded investigation, POC, measured trial, or reusable source comparison that is not yet current authority | `04-records/research/` entry | Preserve question, method, evidence, limits, and promotion route without pretending the packet is current product or architecture truth. |
| Known compromise, temporary path, incomplete migration, or refactor with a repayment route | `04-records/tech-debt/` entry | Keep impact, repayment state, closure condition, review trigger, owner, and guard visible. |
| Repository-specific word, state label, role, code, or abbreviation whose meaning changes a decision | One glossary owner linked once from the six-family inventory: a dedicated `glossary/<term>.md` file or a unique H2 anchor in the glossary README/topic file | Define the term once and link consumers; do not spread competing definitions across product, architecture, process, or records. |

When unsure between `04-records/gotchas/` and `03-process/development/` discipline, apply the boundary principle from §2.4: if the rule is scoped to a file/module and a future agent's first failure mode is reaching for the wrong API, write a gotcha; if the failure mode is following an insufficient workflow, write a discipline entry. **Never create a new top-level area** to absorb unrouted knowledge. The product, architecture, process, records, and glossary routes above form the complete fallback classifier; choose the earliest semantic owner and link the others instead of inventing a miscellaneous bucket.

## 5. Not-applicable areas

`01-product/`, `02-architecture/`, `glossary/`, `04-records/decisions/`, `04-records/gotchas/`, `04-records/bugs/`, and `04-records/tech-debt/` are always applicable.

Default engineering operation areas (e.g., `03-process/benchmark/`,
`03-process/deployment/`, `03-process/release/`) may be not applicable to
certain repos; in that case still create the folder and `README.md` with the
following content format:

```markdown
# <Area name>

This area is not applicable to the current repository.

**Reason**: <specific reason>
```

This ensures the structure is complete and unambiguous, and the agent will not mistakenly assume some area is "not filled in yet". `not_applicable` is a legal state, but must give a reason; if used for stop conclusion or `covered`-equivalent judgment, still requires an independent stop review.

`03-process/operations/` and `03-process/security-and-compliance/` are
conditional owners: create them only when their applicability signals fire.
When absent, the STATUS `Q01`-`Q21` register still records a named process-layer
`not_applicable` reason and a resolving boundary-evidence or owner link in the
same pointer-sized cell, so omission cannot be mistaken for an unaudited gap.

---
