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

The SSOT root is fixed at `SSOT/` under the repository root; do not use `docs/` as a long-lived memory surface.

```text
SSOT/
  README.md          # Pure index entry; opens with the one-sentence repo positioning
  STATUS.md          # Maintenance status
  product/           # Long-lived product trunk
    README.md        # Product Reader Map / owner index
    prd.md           # Concise PRD spine
    product-model.md # Users, problems, promises, boundary, language, trade-offs
    roadmap-and-acceptance.md # Phases, roadmap intent, product acceptance
    capabilities/
      README.md      # Capability owner index
    journeys/
      README.md      # Users/operators journey owner index
  architecture/      # System concrete-design trunk
    README.md        # Whole-system architecture entry (carries tech stack and repository type in the design brief)
    views/           # Cross-domain architecture views
      README.md
      operating-model.md
      critical-journeys.md
      current-target-gap.md
    domains/         # Architecture domains of state/contract/failure/verification
      README.md
  glossary/          # Proprietary terms
  development/       # Local dev and run
  testing/           # Test strategy
  deployment/        # Deploy and distribute
  release/           # Release process
  decisions/         # ADR / major decisions
  gotchas/           # Pitfalls
  bugs/              # Fix knowledge
  tech-debt/         # Tech debt
  04-records/        # Structured record packets, not primary authority
    research/        # Research/PoC evidence packets
```

Core model:

- **Product trunk**: `product/`. Answers why the product exists, who it serves, what it promises, what it does not do, and how capabilities and journeys are accepted. PRD and product intent default to here.
- **Technical trunk**: `architecture/`. Answers how the system as a whole implements product constraints, how it operates, why it is split this way, and where current implementation differs from target design. Internally divisible into `views/` and `domains/` as two types of authoritative locations.
- **Context areas**: `glossary/`. Help the agent first understand what key terms mean.
- **Engineering operation areas**: `development/`, `testing/`, `deployment/`, `release/`. Answer how to run, how to test, how to deliver.
- **Emergent/historical areas**: `decisions/`, `gotchas/`, `bugs/`, `tech-debt/`. Record why, pitfalls, fix knowledge, and debt.
- **Record packets**: `04-records/research/`. Preserve reproducible
  research/PoC evidence packets and reusable claim rows. They are not
  authority mirrors; product, architecture, decision, and engineering owners
  absorb only promoted long-lived facts.

The Views + Domains structure of `architecture/` and the recursion protocol are maintained by [`architecture.md`](architecture.md). Do not add a top-level `SSOT/design/`; design documents are source material, product facts enter `product/`, and technical design facts enter architecture views/domains, decisions, bugs, gotchas, testing, and other authoritative locations by content.

Do not add a top-level `SSOT/research/`. Research and PoC records that belong
inside SSOT live under `SSOT/04-records/research/` as structured evidence
packets. Raw research notes, external artifacts, and working docs outside SSOT
still follow the source-material lifecycle and downgrade rules.

`product/` is a required top-level area. Even pure libraries, tools, or internal platforms must record users/operators, product promises, boundary, non-goals, and acceptance meaning; capabilities or journeys that do not apply should be written as `not_applicable` with a reason, rather than omitting `product/`.

`SSOT/README.md` is the cold-reader entry. It must open with a single-sentence repository positioning ("what this repo is, who it serves, what it does") before any Reader Map table. Tech stack, runtime form, and repository type belong to `architecture/README.md` as part of the design brief; primary capabilities belong to `product/prd.md` as part of the capability map. `SSOT/README.md` only states the one-sentence positioning and routes to those owners; it does not redefine them.

---

## 2. Area responsibilities

### 2.0 Writing posture (shared across every area below)

Every section of every user-facing SSOT body file is first written for the stranger who lands tonight knowing nothing; tables, codes and tags they cannot read are not paragraphs. Three guardrails follow: **prose before tables**, **define every term positively on first use**, and **a cell is not a paragraph**. Full text in [`ssot-bootstrap/references/bootstrap.md`](../../ssot-bootstrap/references/bootstrap.md) §3.7; enforced by Doctor `14I`.

KISS is the permanent SSOT design principle. Prefer the shortest prose that
builds the correct mental model, then add only the table rows needed for
routing, comparison, status, or evidence lookup. A table-heavy owner that makes
the reader reconstruct the story from cells should be fixed before it is
marked `covered`.

Every user-facing owner is also written as an agent action surface. After the opening explanation, a future agent should be able to answer six questions without reconstructing history from scattered evidence: **when should I read this**, **what current truth does this owner hold**, **where should I inspect first**, **what should I not do**, **what minimal verification or evidence closes the loop**, and (v2.51) **where can I go next, and what does this owner explicitly NOT answer (with a pointer to the owner that does)**. Keep the answers compact; the point is orientation, not a second playbook. If a missing answer is caused by a protocol gap rather than one local document, fix the SSOT Skill protocol first, then update the consumer SSOT from that improved rule.

### 2.0.2 Core recovery manifest (v2.45 / v2.46)

`covered` at an area level is unsafe unless the cold reader can see the finite
set of core things that had to be recovered. A consumer at protocol `>= 2.45`
therefore maintains a **Core recovery manifest** in the product trunk and in the
architecture trunk:

- `product/README.md` or `product/prd.md` first gives a short **Core
  completeness argument**: why this set is the project's core product surface,
  which user/operator, problem, promise, product boundary, acceptance semantics,
  and long-lived trade-off facts are part of the core, what near-miss items are
  deliberately excluded, and what wrong product conclusion a cold reader would
  reach if one class were omitted. The manifest then lists every core product
  posture / model row, capability, and journey that the product expects a cold
  reader to recover. Each row names the owner, required pillars
  (`product_intent`, `product_truth`, or `not_applicable` with reason), the
  current truth state (`contract`, `mixed`, `design`, `debt`, `Out`, or
  `not_applicable`), and the evidence / closure owner.
- `architecture/README.md` first gives a short **Core completeness argument**:
  why this set is the project's core design surface, which runtime-owner axis
  and cross-owner views make it complete, what near-miss implementation details
  are deliberately excluded, and what wrong design conclusion a cold reader
  would reach if one class were omitted. The manifest then lists every core
  runtime owner, cross-owner view, global invariant / operating-model fact, and
  current-target-gap posture that the architecture expects a cold reader to
  recover. Each row names the owner, required pillars (`design_intent`,
  `design_truth`, or `not_applicable` with reason), the current truth state
  (`contract`, `mixed`, `design`, `debt`, `poc`, `Out`, or `not_applicable`),
  and the evidence / closure owner.

The manifest is not a new top-level area and it is not a second fact store. It
is a finite routing and recovery index. The row's state must be no stronger than
the strongest unresolved child fact: if an owner body still has a `design` /
`debt` product-truth row, the manifest or parent index must not advertise the
whole item as all-`contract`; it must name the design/debt row and closure
owner. Use `mixed` when the core item includes a shipped contract slice plus at
least one unresolved `design`, `debt`, `Out`, or unsampled slice owned by the
same row. Silence is not a valid `not_applicable` row.

If a manifest row uses a spine owner such as `product/prd.md` instead of a
dedicated capability or journey file, that spine must expose a same-granularity
anchor or short subsection for the row. The reader must not have to reverse
engineer the row from decision files, architecture current-target-gap tables, or
source material. Index state vocabulary must stay inside the state set above:
legacy labels such as `current`, `active`, `partial`, or `shipped` may appear
only as local prose after they have been mapped to `contract`, `mixed`,
`design`, `debt`, `poc`, `Out`, or `not_applicable`.

Doctor reports `[CORE-COVERAGE-MAP]` (15G) when a `covered` product or
architecture area lacks this manifest, omits a core owner, declares the wrong
pillars, lacks the v2.46 completeness argument, cannot explain near-miss
exclusions, advertises a state stronger than the owner body, uses unmapped
non-protocol state vocabulary, or carries an unsampled / failed manifest row
without a Pending Capture.

### 2.0.3 Intent / truth narrative before manifests (v2.47)

The Core recovery manifest is a recovery index, not the story. A product or
architecture trunk that makes the reader reconstruct "what matters and why" from
manifest cells has failed even when every row is accurate. At protocol
`>= 2.47`, `product/README.md`, `product/prd.md`, or the consumer's declared
product trunk owner must expose a short **Product intent and truth** narrative
before its Core recovery manifest. Likewise, `architecture/README.md` must expose
a short **Design intent and truth** narrative before its Core recovery manifest.

The narrative is not another fact store. It is the first-principles synthesis of
the owner facts that already live in the trunk, capability, journey, view, and
domain files. Keep it compact enough to read before opening any table. It must
answer:

- **intent** — why this product or architecture exists, what pressure shaped
  it, and which trade-off future agents must preserve;
- **truth** — what is true today, what is only design/debt/Out, and where the
  current evidence or closure owner lives;
- **boundary** — what near-miss interpretation is deliberately excluded and
  what wrong conclusion a cold reader would reach if that class were omitted;
- **reading path** — which owner a reader should inspect first after the
  narrative when they need details.

For product, the narrative must name the user/operator, problem, promise,
boundary/non-goal, acceptance meaning, and at least the core capability/journey
classes. For architecture, it must name the runtime-owner axis, cross-owner
views, apex invariants / operating model, current-target-gap posture, and the
class of implementation inventory deliberately excluded from the core.

The manifest table follows this narrative and stays narrow: owner, required
pillars, current truth state, and evidence / closure owner. If the manifest is
the only place where a core row's purpose, current truth, or exclusion rationale
is explained, Doctor reports `[INTENT-TRUTH-NARRATIVE]` (15H). If the narrative
introduces new facts that contradict the owner body, route to `[OWNER-ANCHOR]`
or `[PRODUCT-ARCH-DRIFT]` instead of treating prose as authority.

### 2.0.5 Manifest separation (v2.48)

Once a covered area carries v2.45–v2.47 machinery — the Core recovery manifest,
the Core completeness argument, the Apex maxim registry, the Capability →
Surface registry mirror, intent-recovery pillar matrices, evidence strings, and
README-self failure-mode entries — that machinery starts to crowd out the
product or architecture narrative the area is supposed to own. A cold reader
who lands on `product/README.md` or `architecture/README.md` should be able to
recover the project's product or design story in five minutes without first
having to learn SSOT skill vocabulary.

At protocol `>= 2.48`, covered product and architecture areas therefore
**separate SSOT self-maintenance machinery from the prose owner** into a sibling
`_manifest.md` file. The split is mechanical, not editorial:

- **Prose owners stay in the existing files** — `product/README.md`,
  `product/prd.md`, `product/product-model.md`, `product/roadmap-and-acceptance.md`,
  `product/capabilities/*.md`, `product/journeys/*.md`, `architecture/README.md`,
  `architecture/<domain>/README.md`, `architecture/<domain>/playbook.md`, and
  `architecture/views/*.md`. They keep the product / design narrative, the `§不变量`
  / `§设计简报` / `§运行模型` / `§[MUST]` prose, capability scope and contract anchors,
  and inline CORE-REF anchor links. Frontmatter shrinks to a single
  `intent_recovery: covered|partial|gap` token; evidence strings move out.
- **Self-maintenance machinery moves to `_manifest.md`** at the area root
  (`product/_manifest.md`, `product/capabilities/_manifest.md`,
  `product/journeys/_manifest.md`, `architecture/_manifest.md`,
  `architecture/views/_manifest.md`, `architecture/<domain>/_manifest.md`). The
  manifest carries: (a) the Core recovery manifest table plus its completeness
  argument; (b) the Apex / Maxim → Owner mirror table (architecture root only);
  (c) the Capability → Surface registry mirror rows (architecture root and
  view-level only); (d) intent-recovery pillar matrices and `intent_recovery_evidence`
  strings; (e) README-self failure-mode sections (where detection and recovery
  are documentation-drift on the manifest itself); (f) the adoption-cycle log
  recording when each v2.4x cycle's slice closed.
- **Adoption-cycle version labels** (`v2.43`, `v2.44`, `v2.45`, `v2.46`, `v2.47`)
  belong in `_manifest.md`, `STATUS.md`, `CHANGELOG.md`, or `decisions/` — not in
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

### 2.0.1 Apex invariants and CORE-REF prose ownership (v2.43)

Repo-wide invariants already declared in a CORE-REF startup file
(`AGENTS.md`, `CLAUDE.md`, `.cursor/rules/*`, `.windsurf/rules/*`,
`GEMINI.md`) — for example Web-First, Single Writer, route-only-protocol-
adapter, SdkAdapter-only, mission-only leaf, replay equivalence, core-call
traceability — must have **exactly one prose owner** inside SSOT (typically
`architecture/README.md` core-invariants section or the responsible
architecture domain README) and **exactly one CORE-REF mention**. Other
SSOT body files (root summary, views, sibling domain READMEs,
`development/`, `product/`, **and (cycle-2 broadened scope) `glossary/`,
`decisions/` (excluding the ADR that originally established the invariant —
that ADR is the sole exception), `tech-debt/`, `bugs/`, `gotchas/`,
`release/`, `testing/`**) must reference the owner by link plus a one-line
orientation; they must not restate the invariant body as a paragraph,
full-clause bullet, or invariant-table cell. CORE-REF mentions of the same
invariant thin to a one-sentence summary that points at the SSOT owner via
the `[CORE-REF: <owner_path#anchor>]` syntax defined in
[`intent-ownership.md`](intent-ownership.md) §3; CORE-REF and SSOT must not
both maintain the prose body.

**`glossary/` entries for repo-wide invariants** must be a one-clause
positive definition + evidence pointer to the SSOT owner, not a verb-
clause restatement of the invariant body. **Non-establishing `decisions/`,
`tech-debt/`, `bugs/`, `gotchas/` entries** that touch an apex invariant
link the owner instead of recopying its body.

**Worked example — legal vs. illegal restatement (cycle-2)**:

> **Legal** (link + orientation, fires nothing):
>
> > Backend runtime is the runtime owner for Single Writer
> > (`[CORE-REF: ../README.md#core-invariants]`). This domain expands
> > state / contracts / failure modes along that owner chain.
>
> **Illegal** (verb-clause restatement, fires 14Z):
>
> > Routes only adapt HTTP/WS/SSE protocols; task-tree state, writes,
> > scheduling, and completion judgment are not owned by the route layer.
> > Keep Web-first stewardship, Single Writer, mission leaf execution, and
> > traceable SDK/control-plane calls.
>
> The test is mechanical: if the sentence has a finite verb predicating
> what the invariant *does* (`只做`, `不在...拥有`, `保持`, `串行化为`,
> `必须经`, `要求保留`), it is restating the invariant body and must be
> replaced with `<one-sentence summary> ([CORE-REF: <owner_path#anchor>])`
> plus the evidence pointer the surrounding section needs. If the
> sentence merely names the invariant as the reason this owner exists
> (`本域的存在原因是支撑 Single Writer`), it stays. Wrappers like
> `本域 contract 一句摘要` / `具体到本域的落地形态` /
> `domain-form restatement` / `本域如何承接` do NOT exempt the trailing
> clauses; if a verb predicate inside the wrapper restates what the
> invariant does, doctor 14Z still fires on the wrapper body, not on the
> wrapper heading.

> **Illegal — `本域落地形态` / domain-form fork** (cycle-3, fires 14Z):
>
> > Backend contract summary: Web-first Single Writer + mission-only leaf
> > + Core-call traceability — full body lives in the architecture README
> > core-invariants section (`[CORE-REF]`; this file does not restate it).
> > Domain-form restatement: REST/SSE/WS routes are protocol adapters, do
> > not re-own the business state machine; fresh runtime accepts only
> > `execution_mode='mission'` leaf execution; every core call must leave
> > correlatable evidence.
>
> The opening sentence + `[CORE-REF: ...]` is legal, but the trailing
> The domain-form-restatement clause restates Routes-as-protocol-adapter
> ("are protocol adapters", "do not re-own"), Mission-only-leaf ("accepts
> only mission leaf execution"), and Core-call-traceability ("must leave
> evidence") using finite verbs predicating what each invariant *does*.
> Naming the wrapper
> `落地形态` / `domain-form` / `具体到本域` does NOT exempt the verb
> clauses — the mechanical test still fires.
>
> **Legal rewrite** (link + per-clause domain anchor, fires nothing):
>
> > Backend runtime owns the runtime anchors for Single Writer,
> > Routes-as-protocol-adapter, Mission-only-leaf, and
> > Core-call-traceability (`[CORE-REF: ../README.md#core-invariants]`).
> > This domain only gives the corresponding `path:LNN` anchors and guards
> > in state / contract / failure sections; it does not restate the
> > invariant body.

**Legal vs. illegal glossary cell shape** (for §2.3 hard-list terms or
repo-wide invariants both):

> **Legal** glossary entry:
>
> | Single Writer | The invariant that database writes are serialized only through the Web process. | see [`architecture/README.md#single-writer`](#) — `path:src/myapp/web/app.py` |
>
> **Illegal** glossary entry (multi-clause verb-bearing cell):
>
> | Single Writer | Database writes are serialized through a single Web process / command-layer path, preventing arbitrary runtimes from writing the DB directly. | ... |
>
> The illegal form fires `[CORE-REF-PROSE]` (14Z) because the cell carries
> the invariant body. Replace with `Single Writer: see [<owner>]` plus an
> evidence-pointer column.

Capability → surface registry rows (capability ↔ route + handler
`path:LNN` ↔ component path ↔ test) follow the same single-owner rule:
pick one runtime owner per registry row (architecture domain README **or**
product capability file, not both), and let the other location link out.
Doctor enforces this via `[CORE-REF-PROSE]` (14Z); `[FORK]` (15D) covers
only the architecture-domain-to-architecture-domain subset, and
`[OWNER-ANCHOR]` (14F) covers anchor existence rather than prose
duplication.

### 2.1 product/

**Responsibility**: Long-lived product trunk. Records PRD/product intent, current and target product posture, users/operators, problems, product promises, product boundary, product language, product-level trade-offs, roadmap intent, product acceptance gates, and owner pointers for stable capabilities and journeys.

**Internal authoritative locations**:

- `product/README.md`: Reader Map and ownership index. Only routes the reader to PRD spine, product model, roadmap/acceptance, capability owners, and journey owners; does not copy fact bodies.
- `product/prd.md`: Product spine. Keeps a concise PRD spine, recording current/target product posture, core capability map, key non-goals, and owner links.
- `product/product-model.md`: Users, problems, product promises, product boundary, product language, and long-lived product trade-offs.
- `product/roadmap-and-acceptance.md`: Phases, roadmap intent, product acceptance gates, product-level gaps.
- `product/capabilities/`: When a capability has long-lived user value, boundary, non-goals, acceptance meaning, or roadmap state, and keeping it in `prd.md` or `product-model.md` would bloat them, split out `product/capabilities/<capability>.md`.
- `product/journeys/`: When a journey spans multiple capabilities, influences release/roadmap decisions, owns independent product acceptance, or repeatedly drives priority trade-offs, split out `product/journeys/<journey>.md`.

**Applicability**: Always applicable. `product/README.md`, `prd.md`, `product-model.md`, `roadmap-and-acceptance.md`, `capabilities/README.md`, and `journeys/README.md` are the required skeleton for new bootstrap.

**Split rules**:

- Keep facts at the highest stable owner. Do not create capability/journey files for one-off features, tickets, UI scripts, test cases, implementation flows, or short-term tasks.
- `product/capabilities/<capability>.md` is only created when the capability has long-lived user value, product boundary, non-goals, acceptance meaning, or roadmap state.
- `product/journeys/<journey>.md` is only created when the journey spans multiple capabilities, independently influences roadmap/release decisions, owns independent product acceptance, or repeatedly drives priority trade-offs.
- If a statement changes because product promises change, write it into `product/`. If a statement changes because code/runtime architecture changes, write it into `architecture/`, `testing/`, or another technical area.
- `product/README.md`, `capabilities/README.md`, and `journeys/README.md` are Reader Map and owner indexes, not duplicated fact stores.

**Product / Architecture boundary**:

- Do not migrate `architecture/views/critical-journeys.md` as a whole into product. Product journeys own user intent, touchpoints, experience constraints, and product acceptance; architecture critical journeys own system/runtime execution, lifecycle, failure/recovery, observability signals, domain owners, and Mermaid runtime diagrams.
- `architecture/views/current-target-gap.md` tracks implementation current/target/gap; `product/roadmap-and-acceptance.md` tracks product roadmap/acceptance intent.
- Architecture views/domains must link product owner when implementing, rejecting, or marking a product-constraint gap, rather than redefining product facts.
- `product/` is the intent layer. It owns users/operators, problems, promises, product boundary, non-goals, product language, acceptance meaning, product-level roadmap, and product-level gap.
- `architecture/` is the implementation response layer. It owns runtime owners, state/resources, contracts, lifecycle/concurrency, failure/recovery, verification, implementation current/target/gap, and technical response to product constraints.
- Product capability files stay thin. They may link architecture owners, but they do not copy runtime flows, API/SDK/schema details, persistence layout, or implementation listings.
- Architecture owners may link product constraints, but they do not redefine users, product promises, roadmap, non-goals, or acceptance meaning.

**Product current-truth anchors (v2.44)**:

A product owner must let a cold reader recover **what the user can rely on
today**, not only the desired future. Each stable capability / journey row
that declares user-observable behavior must therefore carry one of these
current-truth shapes:

- `state: contract` — shipped behavior. The row carries the normal
  `[SURFACE-PIN]` anchor: route + handler, component / selector, and
  browser / route / CLI test appropriate to the surface.
- `state: design` or `state: debt` — promised or known surface that is not
  contract-level yet. The row names the current user-visible behavior, the
  missing contract evidence, and a falsifiable closure owner (`DEBT-NNNN`,
  `ADJ-NNNN`, ADR `closure_condition`, or a named test to add). It must not
  be silently omitted from the surface registry, and it must not be promoted
  to `contract` with unit-only evidence.
- `Out` / `not_applicable` — explicit non-goal or inapplicable surface. The
  row states the reason and the owner that would have to change before the
  surface re-enters scope.

This rule exists for `product_truth`: truth includes "this is shipped",
"this is only design/debt", and "this is deliberately not a product surface".
The cold-agent-sim harness treats a state-tagged design/debt/out row as a
valid current-truth anchor when the row is falsifiable and points at its
closure owner. It treats silence, stale pointers, or an unowned "later" note as
`truth-state-gap`.

**Product intent / truth narrative (v2.47)**:

When `product` is marked `covered`, the product trunk must let a cold reader
recover the product story before any owner-index or manifest table. The narrative
may live in `product/README.md` when that file is the user's first product stop,
or in `product/prd.md` when `product/README.md` clearly routes to it in the
opening prose. It must state who the product serves, what problem it solves, the
current and target promise, what is out of scope, the acceptance meaning, and the
first owner to inspect for details. The Core recovery manifest may then index
capabilities/journeys, but it may not be the only place where product intent and
current product truth are recoverable.

**Writing style**: see §2.0.

### 2.2 architecture/

**Responsibility**: System concrete-design trunk. Records current implementation, target design, and gaps; explains system boundaries, runtime owners, design units, runtime flows, architecture views/diagrams, state/data/resource ownership, configuration variability, lifecycle/concurrency model, cross-boundary contracts, invariants, failure recovery, and verification.

**Internal authoritative locations**:

- `architecture/README.md`: Quick-mental-model entry, carrying design brief, Reader Map / quick understanding map, technical operating-model summary, major runtime journeys, core invariants, view index, domain index, and implementation Current / Target / Gap summary.
- `architecture/views/`: Technical design-intent layer and cross-domain views, carrying operating model, critical journeys, current-target-gap, and the implementation design of how architecture responds to product constraints.
- `architecture/domains/`: Concrete architecture domains, carrying domain-level design intent, design constraints, trade-offs/rejected plans, state/resource ownership, contracts, invariants, failure recovery, verification evidence, and intra-domain diagrams.
- Legacy direct child domains compatible: existing `architecture/<domain>/README.md` can still serve as a domain authoritative location; migration is not forced.

**Applicability**: Always applicable. New bootstrap and major architecture reorganization prefer `views/ + domains/`; small CLI/library may have only a single-level `architecture/README.md`; large kernels/monorepos must recursively decompose into architecture domains.

**Information architecture**: the default model is a Runtime Owner Map. Root
routes to runtime owners and global invariants; views keep only cross-owner
technical views; domains own the detailed runtime/state/contract/failure facts.

**Design intent / truth narrative (v2.47)**:

When `architecture` is marked `covered`, `architecture/README.md` must let a
cold reader recover the design story before any owner-map, apex-index, or Core
recovery manifest table. The narrative must say why the runtime-owner axis is
the right decomposition, what current runtime truth is enforced today, which
parts are target/debt/Out, which near-miss implementation inventories are
excluded from the design core, and which view/domain to inspect first for
details. A table can then route to owners, but the architecture root must not
make the reader infer design intent or current design truth solely from row
cells.
Do not use a universal 20-section checklist as the default domain template.

**Domain README intent triad** (v2.43): every `architecture/<domain>/README.md` —
including legacy direct-child domain READMEs and `architecture/domains/<domain>/README.md` —
must carry three named H2 sections, in this order, before the runtime-owner /
state / contract / lifecycle body:

- `## Why` — why this owner is split out, and what cross-domain harm appears
  if it merges back. One opening paragraph plus, when relevant, a link to
  the originating decision/bug/gotcha. Prose, not a table.
- `## 失败模式 (Failure Modes)` — at least two concrete failure modes that
  have already bitten this owner, or that the owner is predicted to bite,
  each with a `BUG-NNNN` / regression-test (`tests/...::test_*`) / RCA
  pointer. Generic runtime-error rows under lifecycle / concurrency or
  failure / recovery sections do not satisfy this section: `失败模式` is the owner-doc's own
  recoverability surface ("what makes this README go stale, wrong, or
  impossible to land"), not the runtime's error budget.
- `## 关闭条件 (Closing Conditions)` — the explicit conditions under which
  this owner can be `resolved` / merged back / superseded / marked
  `not_applicable`, and the evidence pointer (decision / capability
  deletion / ADR / test removal) that would close it. If no closure path is
  currently foreseen, write `closure: open` plus a one-line revisit signal;
  do not omit the heading.

A domain README that omits any of the three sections, or carries the heading
but writes runtime-error / generic-recovery prose under it, cannot be marked
`covered`. Doctor `[INTENT-OWNER]` (14W) gates this.
[Lightweight-mode single-level `architecture/README.md`](architecture.md#11-lightweight-mode)
is exempt; the moment lightweight mode is exited and a domain folder is
created, the triad becomes mandatory.

**Split signal**: See [`architecture.md`](architecture.md). This file only declares the technical-trunk role of `architecture/` in the area model.

### 2.3 glossary/

**Responsibility**: Repository-specific vocabulary. Records business-domain terms, technical abstraction names, internal convention abbreviations, and the precise meaning of these words in this repo's context.

**Applicability**: Always applicable. Even small projects have their own naming conventions and domain terms.

**Content requirements**: Record only terms specific to this repo, or terms with special meaning in this repo. Standard industry terms and framework concepts are not recorded if not redefined. Each term contains name, one-sentence definition, optional first-introduced architecture domain or usage context. May group by domain.

**Required canonical vocabulary (v2.43, hard list, overrides split-signal threshold)**:
Regardless of total term count, when the consumer repository defines any of the
following four categories at the protocol, apex (`AGENTS.md` / `CLAUDE.md` /
`SKILL.md`), or schema-enum level, `glossary/` must own a positively-defined
entry per item with `path:LNN` or schema/enum evidence. A category that does
not apply must be recorded as an explicit `<category>: not_applicable —
<reason>` row in `glossary/README.md`; silent omission is a fail.

1. **Workflow execution-result vocabulary** — every protocol-level workflow
   result code (e.g. `SUCCESS / FAIL / SEVERE_FAIL / USER_GATE`) declared in
   `CLAUDE.md`, `AGENTS.md`, the apex `SKILL.md`, or a `domain/workflow/*` enum.
2. **Task / node lifecycle states** — every persisted lifecycle state value an
   agent can read or write (e.g. `planned / executing / paused / completed /
   failed`), keyed to the schema column or Python enum that defines it.
3. **Agent-tier semantics** — the product/runtime distinction between main
   agent, sub-agent, runtime-native participant, and any other named agent
   tier the consumer protocol treats as a first-class observable role.
4. **Altitude vocabulary** — the consumer's PLTL altitude triad (`apex /
   authority / inbox`) or whatever altitude names the consumer uses for rule
   placement, because closeout/audit move blocks are unreadable without it.
5. **Apex behavior maxim term (cycle-2)** — when the consumer's root
   constraint file (`AGENTS.md` / `CLAUDE.md` / `.cursor/rules/*` /
   `.windsurf/rules/*` / `GEMINI.md`) enumerates numbered named rules
   (e.g. `CLAUDE-MAXIM-N` / `CORE-RULE-N` / `<PROJECT>-MAXIM-N`) codifying
   failure modes the project must never re-enter, `glossary/README.md` must
   own a single positively-defined entry that (a) defines what an `apex
   behavior maxim` is in this repo, (b) lists every currently-numbered rule
   with its short subject, and (c) maps each rule to its unique SSOT owner
   per [`intent-ownership.md`](intent-ownership.md) §1 (`DISC-NNNN`,
   capability invariant section, or architecture domain invariant). Inline
   mentions of individual maxim numbers inside other glossary entries do
   not satisfy this — the term itself must have its own row. A consumer
   whose root constraint file does not enumerate numbered named rules
   records `apex_behavior_maxim: not_applicable — root constraint file uses
   only narrative prose, no *-MAXIM-N enumeration`.
6. **Concurrency-control vocabulary (cycle-3)** — every named
   scheduling/concurrency control identifier the consumer's apex docs
   (`AGENTS.md` / `CLAUDE.md`) reference as a noun (e.g. `workspace_path`,
   `project_limit`, lease keys, queue names). When apex prose says
   a phrase meaning "limited by X" or "at most N tasks per same X" using
   a named identifier X,
   `glossary/` must own a positively-defined entry per identifier with
   `path:LNN` evidence pointing at the schema column / config field /
   scheduler module that defines it. A consumer whose apex docs do not
   name any concurrency identifier records `concurrency_control:
   not_applicable — apex docs use only narrative descriptions, no named
   identifiers`.

**Single-prose-owner rule for canonical vocabulary (cycle-2)**: each
hard-list term has exactly one prose owner — `glossary/README.md` — once
it appears in the consumer's apex docs / schema enums / closeout protocol.
`product/product-model.md` product-language section, `architecture/views/*`,
`architecture/<domain>/README.md`, and `development/discipline.md` may
reference a hard-list term, but only as a thin pointer row containing **at
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
that prose into the corresponding `product/capabilities/<capability>.md`
body or `architecture/<domain>/README.md` invariants block keyed to a
non-canonical-vocab capability term, and keep the term row at this
altitude one-sentence-thin.

Deferring any of these to a future audit batch via `STATUS.md` notes or a
product/architecture carve-out **does not satisfy** this rule unless
`glossary/README.md` carries either the entry or the `not_applicable`
placeholder. This list also overrides the 30-entry split-signal: coverage of
these categories is required at any term count. Doctor
`[WORKFLOW-STATE-VOCAB]` (15A) gates the first four categories and (cycle-2)
the fifth (apex behavior maxim term) jointly with `[MAXIM-OWNER]` (14X) —
14X enforces single-owner mapping per maxim, 15A enforces glossary
ownership of the umbrella term and the rule→owner table; doctor
`[VOCAB-PROSE-FORK]` (15F, cycle-2) gates the single-prose-owner rule for
all five hard-list categories.

#### 2.3.1 Recommended `glossary/README.md` skeleton (cycle-2)

`glossary/README.md` opens with an **Owner block** declaring the file as
the single owner of the hard-list categories and pointing other trunks at
this file via `[CORE-REF: glossary/README.md#<anchor>]`. The body then
carries one H2 per hard-list category in this order, each opening with one
short orienting sentence (when to read, what it owns), then a 3-column
table:

```markdown
# Glossary

> Owner of the canonical-vocabulary hard list (workflow result codes,
> task/node lifecycle states, agent-tier semantics, altitude vocabulary,
> apex behavior maxim term). Other trunks link here via
> `[CORE-REF: glossary/README.md#<anchor>]` and do not restate these
> bodies.

## Workflow execution-result codes

The four/five outcomes a leaf/mission can land in. Read this when reading
`claim_done` payloads, scheduler decisions, or test verdict tables.

| Term | Meaning in this repository | Context / evidence |
| --- | --- | --- |
| SUCCESS | … | `path:src/.../enum.py:LNN` |
| FAIL | … | `path:src/.../enum.py:LNN` |
| … | … | … |

## Task / node lifecycle states

… (one sentence + 3-col table)

## Agent-tier semantics

… (main agent / sub-agent / runtime-native participant)

## Altitude vocabulary

… (apex / authority / inbox or consumer equivalent)

## Apex behavior maxim term

What an `apex behavior maxim` is in this repo, plus the numbered-rule →
owner table:

| Maxim | Short topic | SSOT owner |
| --- | --- | --- |
| CLAUDE-MAXIM-1 | … | `development/discipline.md#DISC-NNNN` |
| CLAUDE-MAXIM-2 | … | `development/discipline.md#DISC-NNNN` |
| … | … | … |
```

This skeleton is prose under §2.3.1 — not a separate asset file — so the
writing rules and the canonical layout live together. A consumer is free
to localise headings (e.g. translated H2 names) but must keep the H2-per-
category, owner-block-on-top, and 3-column-table shape so doctor `15A` /
`15F` can find the rows mechanically.

**Split signal**: When terms exceed 30 entries or span multiple distinct business domains, create sub-files by domain.

**v2.51 entry template.** New glossary entries SHOULD render from [`ssot-bootstrap/assets/templates/{en,zh}/glossary-entry.md`](../../ssot-bootstrap/assets/templates/en/glossary-entry.md), which collapses the reader-scaffold slots into per-term form: one-sentence positive definition, `Used in` inverse index, `Not to be confused with` boundary list, and `Source pin`. Pre-v2.51 entries inside `glossary/README.md` may stay as table rows until next touched; touching an entry means migrating it to a `glossary/<term>.md` file rendered from the new template.

### 2.4 development/

**Responsibility**: How to run the project, and how to write code correctly in this project. Local environment setup, build commands, development workflow, common commands, coding conventions, and pattern language.

**Applicability**: Always applicable.

**Content requirements**: Summarize common commands and point to `package.json`, `Makefile`, `Dockerfile`, and other source files. Record non-obvious steps and preconditions in the build chain. If there are script/tool directories, package manifests, CI, Makefile, or tool entries in configs, maintain a **script / tool inventory**. Recommended fields: `Filename` / `Purpose` / `Category` / `When to use` / `Evidence` / `Risk or prerequisite` / `Architecture link if any`. Choose categories by project semantics, e.g., build, dev-server, codegen, lint/format, import rewrite, session analysis, diagnostics; do not treat these categories as a new schema, do not copy script source, only explain purpose, constraints, and evidence.

When the project has coding conventions beyond linter/formatter coverage, also record:

- **Pattern language**: Key coding paradigms and convention patterns the project adopts (e.g., error-handling paradigm, dependency-injection conventions, logging-call conventions), pointing to representative implementation files. Record only conventions "a new agent will violate when writing code"; do not record rules that can be derived from linter config.
- **End-to-end skeleton flow**: Files and step list to touch when adding a typical feature type (e.g., new API, new Worker, new CLI command). Use pointers to templates or existing examples; do not write full code.
- **Agent operation preconditions**: Non-obvious prerequisites that must be satisfied before running tests, builds, or deploys (e.g., start docker compose first, build dependency packages first, do not skip pre-commit hook), and silent-failure manifestation upon violation.
- **Agent operation discipline**: Cross-task imperative rules a future agent must obey when working on this repository, even though no single file/module path scopes them. Each entry records `Rule` (single-sentence imperative), `Trigger` (file-glob, task pattern, or conversation signal that fires the rule), `Why` (concrete failure history with evidence pointers to `bugs/`, `decisions/`, or commits), `Evidence` (tests, integration suites, or other artifacts that enforce or witness the rule), and `Failure mode` (what visibly breaks when an agent violates it). Recommended sub-file: `development/discipline.md` with `DISC-NNNN <slug>` entries. Apex behavior maxims declared in a project root constraint file (`CLAUDE.md`, `AGENTS.md`, `.cursor/rules/*`, `GEMINI.md`) — numbered named rules such as `CLAUDE-MAXIM-N` / `CORE-RULE-N` — must follow the apex-maxim → SSOT-owner mapping in [`intent-ownership.md`](intent-ownership.md) §1: each maxim has exactly one owner (typically a unique `DISC-NNNN`), and the root constraint file holds only a one-line `[CORE-REF: ...]` link, not the maxim body.
- **Boundary with `gotchas/`**: A `gotcha` is a file/module-scoped pitfall recorded as a `don't X / do Y instead` pair against a specific code surface (e.g., "do not import `foo.bar.legacy_helper`"). An entry under `development/` discipline is a task-pattern-scoped imperative rule that applies across files and tasks (e.g., "when modifying any SDK adapter, run the real-SDK integration suite before claiming done"). When in doubt: if a future agent's first failure mode is reaching for a wrong API in a known file, write a `gotcha`; if the failure mode is following a procedurally insufficient workflow across many files, write a discipline entry.
- **Split signal for discipline**: Create `development/discipline.md` the first time a recurring agent-operation rule is confirmed. When entries exceed 10 or fall into distinct domains (delivery, verification, dependency hygiene, etc.), split into sub-files (`discipline/delivery.md`, `discipline/verification.md`, …) under a `development/discipline/` sub-folder.

**Split signal**: In a monorepo where each workspace has an independent development flow, split into sub-files. When pattern language and skeleton flow are large, may split into a `conventions.md` sub-file. When agent operation discipline grows, follow the discipline-specific split signal above.

### 2.5 testing/

**Responsibility**: How to test. Records the stable test strategy, test selection matrix, quality gates, fixtures / test data, current baselines, known gaps, and defensive-test source map.

**Applicability**: Applicable when test files, test scripts, or test configs exist. When no tests, declare the current state and record the reason.

**Content requirements**: Summarize test commands and point to test config files. Record the why of test strategy, e.g., why the test layers are divided this way. When no evidence, write `unknown` or `gap`; do not guess test level from script name.

`testing/` is not a verification run ledger. Test results are evidence, not testing facts. Do not append batch-by-batch command transcripts, dates, green/red summaries, or "recent validation" rows unless the result changes a long-lived testing fact: a command/gate changed, a baseline changed, a fixture contract changed, a known gap opened/closed, or a defensive-test mapping was added/removed. Use commit hashes, issue IDs, bug entries, CI links, or release notes as evidence pointers from the stable fact instead of carrying chronological run history in this area.

Recommended stable sections:

- **Test strategy**: layers, boundaries, trade-offs, and why those layers exist.
- **Test selection matrix**: what to run for each change family and why.
- **Quality gates**: PR/release/blocking gates, required setup, and failure semantics.
- **Current baseline**: stable expected state such as "frontend lint baseline is 0 warnings"; update only when the baseline changes.
- **Fixtures / test data**: fixture owners, update risk, data contracts, and regeneration constraints.
- **Known gaps**: missing CI coverage, flaky suites, disabled tests, or manual-only verification with blocking level.
- **Defensive test sources**: key regression tests mapped to `critical` / `major` / `recurred` bugs or gotchas.

When `bugs/` contains `critical` / `major` / `recurred` fix records, optionally maintain a **defensive-test source** section: list key tests driven by bug regression (test file/case -> `bugs/` entry pointer). This lets an agent understand the reason for a test's existence when modifying protected code, avoiding accidental deletion or bypass. Exhaustiveness not required; record only entries where "deleting this test will let the historical bug recur".

**Split signal**: Split when unit/integration/e2e/performance and other test types each have independent config and strategy.

### 2.6 deployment/

**Responsibility**: How to deploy or distribute. Deployment method, environments, infrastructure form, CI/CD pipeline.

**Applicability**: Applicable when deployment behavior exists. Pure libraries/pure tools declare not-applicable or describe distribution, e.g., package publish.

**Content requirements**: Summarize and point to `Dockerfile`, `k8s/`, `terraform/`, CI config, and other source files. Record non-obvious steps, environment differences, and rollback strategies in the deployment flow.

**Split signal**: Split when there are multiple environments, multiple deployment targets, or multiple independent deployment units.

### 2.7 release/

**Responsibility**: Release process and versioning strategy. How to release, version-number rules, changelog maintenance, release pipeline.

**Applicability**: Applicable when versions, tags, changelog, release scripts, package publish, or deploy release exist.

**Content requirements**: Summarize and point to release scripts, CI config, or version files. Record the why of versioning strategy. If there are release-adjacent tools like version sync, changelog generation, publish, artifact signing, or import rewriting, maintain a tool inventory. Recommended fields: `Filename` / `Purpose` / `Category` / `Release invariant` / `Evidence` / `Failure mode`. Sync-link consistency scripts that affect architecture current/target/gap to the corresponding architecture domain or decision.

**Split signal**: Split when multiple independently releasable artifacts exist.

### 2.8 decisions/

**Responsibility**: Major decisions and reasons. Why this and not that, decision context and consequences.

**Applicability**: Always applicable. Initially may be empty, grows with repo evolution.

**Content requirements**: `README.md` serves as the decisions index, containing at least `status` and `implementation_state`. Each major decision is an independent file containing background, decision, consequences, scope of impact, and lifecycle fields:

- `status`: `accepted` / `deprecated` / `superseded`
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

### 2.9 gotchas/

**Responsibility**: Known pitfalls, failure modes, "don't touch here because X". Records tacit knowledge that code cannot express.

**Applicability**: Always applicable. Initially may be empty, grows with stepped-on-mine experience.

**Content requirements**: `README.md` serves as the pitfall index, containing at least `status`. Each pitfall explains what it is, why it is dangerous, and scope of impact. Mitigation `[SHOULD]` be given in pairs of "do not do X + do Y instead" to make entries actionable rather than only record failure stories -- a gotcha that only describes failure symptoms without an alternative has very low value. Optional additions:

- **Trigger** `[SHOULD]`: Describe "when the agent does what operation it should first check this gotcha". Format is task type or file/module path matching. Examples: `Trigger: when modifying any file under src/auth/`, `Trigger: when adding a new database migration`. Triggers let the reading protocol route precisely -- the agent proactively drills into the gotcha before executing matching operations, rather than relying on the generic "read gotchas when changing code" rule. A cross-task procedural rule that applies regardless of file scope (e.g., "always run real SDK integration suite before claiming a fix done") is not a gotcha; route it to `development/` discipline (see §2.4) so future agents can find it via task-pattern routing rather than per-file gotcha scan.

Status:

- `active`: The pitfall still exists.
- `resolved`: The pitfall no longer holds due to architecture change or fix; attach invalidation reason and related decision/change.

Resolved entries remain in the document as historical reference, but the index must mark them clearly to avoid agent risk misjudgment.

**Split signal**: When pitfalls exceed 10 entries, group by architecture domain or topic.

### 2.10 bugs/

**Responsibility**: Bug-fix records. What problem was encountered, what is the root cause, how was it fixed, what was learned.

**Applicability**: Always applicable. Initially may be empty, grows with fix history.

**Content requirements**: `README.md` serves as the fix-record index, containing at least `status` and `severity`.

- `critical` / `major`: Independent file containing symptom, root-cause analysis, fix plan, scope of impact, takeaway/pattern, prevention, related areas, external references.
- `minor`: A single summary row in the index table suffices, containing symptom, root cause, and fix commit/PR reference.

Agent quick entry:

- `critical`, `major`, `recurred`, active, or repeatedly referenced bug entries should start with a compact quick-entry surface before the full post-mortem.
- The quick entry answers: symptom/trigger signature, first places to inspect, do-not-do boundary, minimal verification/preventive test, and current status/evidence pointer.
- The quick entry does not replace root-cause analysis or recurrence timeline. It is the first screen for a future agent touching the related code.

Regression Granularity Rule:

- `critical`, `major`, `recurred` bugs cannot be recorded only as broad topics; they must be split to failure-mode-level entries.
- A single record must answer trigger condition, symptom, root cause, fix pattern, preventive test, related gotcha / architecture / decision.
- Same symptom with multiple root causes must be split into multiple entries; same root cause recurring multiple times may append a recurrence timeline in the same entry.
- `minor` or trivial bugs do not enforce a full post-mortem unless they recur, escalate to major, or expose architecture/test gaps.

Status:

- `fixed`: Already fixed.
- `recurred`: Previously believed fixed but recurred; attach recurrence reason and new fix record link.

When a fix reveals a gotcha, tech debt, decision, or architecture defect, sync-update the corresponding area. SSOT does not replace Issue Tracker; Issue Tracker manages lifecycle; `bugs/` only records long-lived knowledge after fix completion.

**Split signal**: When entries exceed 15, group by architecture domain or time period.

### 2.11 tech-debt/

**Responsibility**: Technical-debt register. Known debts, temporary workarounds, planned refactorings.

**Applicability**: Always applicable. Initially may be empty.

**Content requirements**: `README.md` serves as the debt index, containing at
least `status`. Each debt item records what it is, why it was incurred, scope of
impact, repayment plan, priority, and the next concrete action or retrigger that
prevents the debt from becoming silent backlog. Status:

- `active`: The debt still exists.
- `resolved`: Debt repaid; attach resolution method and related change/decision.
- `obsolete`: Debt no longer relevant due to architecture change; attach reason and related decision.

Required lifecycle fields for `active` entries (v2.43, YAML frontmatter,
alongside `status` and `priority`):

- `closure_condition`: a falsifiable predicate a future agent or Doctor can
  evaluate to flip this debt from `active` to `resolved` without re-debating
  intent — e.g. `tests/integration/test_engine_dfs_mission_only.py passes
  AND src/myapp/engine/planner.py is absent`,
  `architecture/backend-runtime/current-target-gap.md row R-NNN deleted`,
  `BUG-NNNN closed and regression test green`,
  `grep -nR 'TODO(DEBT-0001)' src/ returns no match`. Narrative such as
  "synchronize when advancing X" or "review periodically" is not a
  closure_condition.
- `revisit_signal`: a concrete trigger for re-reading this debt entry —
  e.g. `path-glob:src/myapp/engine/**`, `schema.sql touched`,
  `new mission executor branch added`, `BUG-NNNN reopened`. Path globs,
  file patterns, test names, or named events are acceptable; "when
  relevant" is not.

Both fields are required on every `status: active` entry. `resolved` and
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
SSOT must be registered. The registration may live in `tech-debt/`, `bugs/`,
`decisions/`, or an open STATUS gap when no better owner exists, but it must
carry the same five fields:

- `owner`: the SSOT owner or engineering owner responsible for clearing it;
- `reason`: why the temporary surface is allowed to exist now;
- `closure_condition`: a falsifiable predicate that removes or resolves it;
- `revisit_signal`: the path/event/test trigger that makes agents re-read it;
- `verification_guard`: the command, grep predicate, test, or runtime evidence
  that proves the temporary surface did not silently become permanent.

For `tech-debt/` entries, use `temporary_surface: true` in frontmatter and add
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

### 2.12 04-records/research/

**Responsibility**: Structured research and PoC evidence packets. This area
preserves reproducible methods, inputs, artifacts, observations, limitations,
and distilled claim rows that may be reused by future product, architecture,
decision, testing, bug, gotcha, or debt owners.

**Applicability**: Applicable when a task produces research, landscape review,
PoC, experiment, benchmark, spike, external comparison, or measured trial output
that is too valuable to discard but is not itself a stable product or
architecture fact. Do not create the directory merely because source-material
rows mention research. Do not create a top-level `SSOT/research/`.

**Content requirements**: `README.md` is only the index. Entries are independent
files named `NNNN-<slug>.md`. Each entry records the research question, method,
inputs, environment or source set, artifacts, observations, known limitations,
`do_not_use_for` boundary, reusable claim rows, `promotion_targets`, and
`recheck_trigger`. Claim rows should be distilled enough to promote one by one:
claim, evidence packet anchor, confidence, boundary, and target owner.

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
    current-target-gap.md
  domains/
    README.md
    query-engine/
      README.md
      parser.md
      planner.md
    storage-engine/
      README.md
      buffer-manager.md
      page-format.md
```

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

---

## 4.1 Default fallback for unrouted durable knowledge

When a durable fact emerges from conversation or change review but does not clearly match any single mapping row in the conversation-signal table (`update-routing.md §3`) or the task-entry map above, use this fallback classifier rather than guessing or skipping the write:

| Signal | Drop target | Rationale |
|---|---|---|
| Imperative-procedural rule ("always X before Y", "never Z because the real service disagrees with the mock", "from now on, do W first") | `development/` discipline entry | Cross-task procedural rules owned by development practice. Do not collapse into a single bug entry. |
| File/module-scoped trap ("do not call function A from module B", "config C has a quirk") | `gotchas/` entry | Scoped to a concrete code surface; future agents read by path trigger. |
| Trade-off or design constraint ("we chose X over Y because Z", "must not exceed N") | `decisions/` entry | Long-lived why record; future agents need the rationale to avoid re-litigation. |
| Bug root cause, symptom, and prevention ("the crash in component C was because...") | `bugs/<entry>.md` takeaway section | Fix history; high-severity entries carry a takeaway/prevention field and may cross-link to `development/` discipline if a recurring procedural gap is confirmed. |

When unsure between `gotchas/` and `development/` discipline, apply the boundary principle from §2.4: if the rule is scoped to a file/module and a future agent's first failure mode is reaching for the wrong API, write a gotcha; if the failure mode is following an insufficient workflow, write a discipline entry. **Never create a new top-level area** to absorb unrouted knowledge — `development/`, `gotchas/`, `decisions/`, and `bugs/` cover all durable knowledge origins defined in the protocol.

## 5. Not-applicable areas

`product/`, `architecture/`, `glossary/`, `decisions/`, `gotchas/`, `bugs/`, `tech-debt/` are always applicable.

Engineering operation areas (e.g., `deployment/`, `release/`) may be not applicable to certain repos; in that case still create the folder and `README.md` with the following content format:

```markdown
# <Area name>

This area is not applicable to the current repository.

**Reason**: <specific reason>
```

This ensures the structure is complete and unambiguous, and the agent will not mistakenly assume some area is "not filled in yet". `not_applicable` is a legal state, but must give a reason; if used for stop conclusion or `covered`-equivalent judgment, still requires an independent stop review.

---
