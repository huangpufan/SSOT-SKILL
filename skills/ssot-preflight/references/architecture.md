# Architecture Trunk Reference

This file owns the `architecture/` trunk, recursive decomposition, diagram
expectations, and coverage depth. Read it during bootstrap, architecture audit,
major refactor, or architecture-domain split/merge.

KISS rule: architecture is first a mental model, not a section checklist. A
reader should understand what the system is, what runtime owners matter, who
owns state/contracts/failure/trust, and where evidence lives before seeing any
matrix.

## ARCHITECTURE-INFORMATION-ARCHITECTURE

The default architecture information architecture is **Runtime Owner Map**.
Architecture explains how the implementation responds to product constraints:
runtime owners, state/resources, contracts, lifecycle/concurrency,
failure/recovery, verification, and implementation current/target/gap.

Do not use a universal 20-section domain checklist as the default. A checklist
can be an audit appendix, but it must not be the reader's primary architecture
surface.

## 1. Required Mental Model

Every architecture surface has three layers:

1. **Mental model**: a short prose explanation of the system, view, or domain.
   It names the main path, why the boundary exists, and what future agents must
   preserve.
2. **Owner boundary**: the unique place that owns each long-lived fact. Root and
   Reader Maps route to owners; views own only cross-owner technical views;
   domains own state/resources, contracts, failure/recovery, lifecycle,
   trust/config, and verification detail.
3. **Evidence direction**: links to code, config, schema, tests, runtime
   observations, decisions, source material, or gaps. Detailed ledgers are
   appendices only when they help the reader act.

Tables are allowed when they route, compare, register status, or index
evidence. They are not a substitute for the first prose paragraph.

## 2. Structure

For new bootstrap and user-requested major architecture reorganization, prefer:

```text
architecture/
  README.md
  views/
    README.md
    operating-model.md
    critical-journeys.md
    current-target-gap.md
  domains/
    README.md
    <domain>/
      README.md
```

Existing `architecture/<domain>/README.md` direct child-domain structures remain
valid. Small CLI/library repos may use single-level mode when the stop reason is
reviewed and recorded. Do not create `SSOT/design/`; design source material is
absorbed into architecture views/domains, decisions, and related owners.

Product facts stay in `product/`. Architecture records the technical response,
runtime shape, and implementation gap, and links product owners instead of
rewriting product promises.

## 3. Thin Defaults

### Root

`architecture/README.md` should let a new agent build the system goal, main
path, core invariants, and next reading path within one minute.

Default root content:

- design brief in prose;
- design intent / truth narrative in prose when `architecture` is marked
  `covered` (v2.47): why this runtime-owner axis exists, what is true today,
  what is design/debt/Out, which near-miss implementation inventories are
  excluded, and which owner to inspect first;
- Runtime Owner Map / Reader Map;
- core invariants with owner links;
- view index limited to cross-owner technical views;
- domain index limited to runtime owners;
- short Current / Target / Gap posture and gap index link;
- evidence and coverage pointer.

Root may summarize views/domains, but it does not own full flow, state,
contract, failure, or resource detail. If root needs long tables to be
understood, the missing model belongs in prose or in a lower owner. Root is not
a domain checklist.

The Core recovery manifest, when present, follows the prose narrative. It is a
finite index proving that every runtime owner, cross-owner view, global
invariant / operating-model fact, and CTG posture has an owner; it is not the
reader's first explanation of the design. If the only explanation of the core
design appears inside the manifest table cells, Doctor reports
`[INTENT-TRUTH-NARRATIVE]` (15H) in addition to any `[CORE-COVERAGE-MAP]` issue.

### Views

Views answer cross-owner technical questions. Keep only views that truly cross
runtime owners: critical runtime flows, contract map, failure/recovery map, and
global current/target/gap index. A view explains why it exists, which domains it
synthesizes, what design intent or constraint crosses domains, and where
current/target/gap evidence lives. Views do not take over domain-owned state,
resource, contract, failure, lifecycle, or verification detail.

Default view content:

- scope and why this view exists;
- narrative/model in prose;
- related domains and owner links;
- Current / Target / Gap;
- evidence/gap pointers.

### Domains

Domains are the stable owner for architecture facts that have their own state,
contract, failure, lifecycle, trust, verification, or evolution semantics. A
domain must answer why it is separate before it lists parts.

**Domain README intent triad** (v2.43): every architecture domain README
must open with three named H2 sections in this order, before the
runtime-owner / state / contract / lifecycle body —
`## Why`, `## 失败模式 (Failure Modes)`, `## 关闭条件 (Closing Conditions)`.
See [`area-model.md §2.2`](area-model.md#22-architecture). Doctor
`[INTENT-OWNER]` (14W) gates this. Lightweight-mode single-level
`architecture/README.md` (see §11) is exempt.

**Apex maxim and apex invariant single-owner rule** (v2.43): when an
architecture domain README owns an apex behavior maxim
(`CLAUDE-MAXIM-N` / `CORE-RULE-N`) or a repo-wide invariant declared by
the project's CORE-REF startup file (Web-First, Single Writer,
route-only-protocol-adapter, SdkAdapter-only, mission-only leaf, replay
equivalence, core-call traceability, or equivalent), the architecture
domain owns the prose body and the CORE-REF file holds at most a one-line
summary plus the `[CORE-REF: <owner_path#anchor>]` link defined in
[`intent-ownership.md`](intent-ownership.md) §3. Sibling architecture
domain READMEs, views, and product capability files reference the owner
by link — they do not restate the body. Doctor `[CORE-REF-PROSE]` (14Z)
catches body duplication; `[FORK]` (15D) catches the architecture-domain
↔ architecture-domain subset.

Default domain content:

- boundary and why separate;
- owned state/resources;
- contract surfaces;
- lifecycle and failure boundary;
- invariants only when load-bearing;
- **symbols** (v2.39) — `path:src/...:LNN` or `tests/...::test_*` anchor for each invariant / contract row, so a cold agent can hop in one read; doctor `[SYMBOL-PIN]` (14S) gates this;
- **surface anchors** (v2.39) — for each contract row, name the user-observable surface: API route + handler, SQL identifier, DOM selector + component + Playwright test, or CLI command location; doctor `[SURFACE-PIN]` (14T) gates this;
- **failure trace** (v2.39) — for each failure / recovery row, name the regression test or `BUG-NNNN` entry that owns it; doctor `[FAILURE-TRACE]` (14U) gates this;
- **state tags** (v2.39) — every invariant / contract row carries `state: contract | design | poc | debt` inline (see `ssot-bootstrap` §3.7); doctor `[STATE-TAG]` (14V) gates this;
- **playbook** (v2.39) — when the domain owns ≥3 mechanical task branches (e.g. "add a new SDK adapter", "migrate a schema column"), the domain ships a sibling `playbook.md` modeled on [`SSOT/02-architecture/sdk-agent-runtime/playbook.md`](#); the README stays thin and links it. Doctor `[PLAYBOOK]` (14R) gates this;
- verification/evidence;
- local Current / Target / Gap;
- verification and evidence.

Do not leave empty `not_applicable` sections everywhere. If several concerns are
absent, one short "Non-applicable concerns" appendix can say so.

## 4. Owner Anchors

Each key claim has one owner:

| Claim type | Common owner |
|---|---|
| State/resource write rights, lifecycle, cache, persistence, lock | architecture domain state/lifecycle section |
| API/CLI/SDK/protocol/schema compatibility semantics | architecture domain contract section or schema/API source plus domain note |
| Failure detection, recovery, demotion, rollback, termination | architecture domain failure/recovery section |
| Trust boundary, permission, secret, feature flag, environment difference | architecture domain trust/config section or deployment owner with architecture link |
| Technical system goals, priorities, non-goals, NFRs | `architecture/views/operating-model.md` or legacy root compensation |
| Cross-domain runtime journey and observability/recovery signal | `architecture/views/critical-journeys.md` with domain links |
| Implementation current/target/gap and migration stance | `architecture/views/current-target-gap.md` with domain/decision/debt/product links |
| Product promises, users, capabilities, journeys, acceptance | `product/` owners |
| Long-lived design trade-off | `decisions/` with architecture back-link |
| Apex behavior maxim from project root constraints (e.g. `CLAUDE.md` `CLAUDE-MAXIM-N`, `AGENTS.md`-style numbered named rules) | unique `development/discipline.md#DISC-NNNN` entry, capability invariant section, or architecture domain invariant; root constraint file holds only a one-line `[CORE-REF: ...]` link to the owner |

Non-owner locations link to the owner and give evidence direction. If the same
fact is maintained in multiple places, migrate it back to the owner or mark a
conflict.

Architecture root/views/domains may link product constraints but must not
redefine users, product promises, roadmap, non-goals, or acceptance meaning.
Those live in `product/`.

### Apex maxim indexing (v2.43)

When a project's root constraint file (e.g. `CLAUDE.md`) enumerates **apex
behavior maxims** — short, numbered, named rules that codify failure modes
the project must never re-enter (`CLAUDE-MAXIM-N`, `CORE-RULE-N`, etc.) —
each maxim is treated as a long-lived claim with the same single-owner
discipline as any other §4 claim. Each maxim must have **exactly one SSOT
owner**: a `development/discipline.md#DISC-NNNN` entry, a capability
invariant section, or an architecture domain invariant. The root
constraint file is a non-owner mirror; it links the owner via
`[CORE-REF: <owner_path#anchor>]` (see
[`intent-ownership.md`](intent-ownership.md) §3) and does not carry the
rule body. Cross-references to a maxim from non-owner DISC entries,
capability files, or architecture domains must stay one-line links — they
MUST NOT recopy the maxim body, otherwise the maxim becomes a shadow fact
under §12 anti-pattern "Same fact maintained in root, view, domain, and
engineering area". Doctor `[MAXIM-OWNER]` (14X) gates this.

The consumer-side **Apex maxim registry** table that 14X reads at a
single anchor is owned by [`intent-ownership.md`](intent-ownership.md)
§1.1; architecture domains and capability files do not duplicate it.

## 5. Domain Validity

A valid architecture domain states `why separate` and has at least one
independence signal:

| Independence source | Valid signal |
|---|---|
| State or resource owner | write rights, lifecycle, cache, persistence, handles, connection pool, lock |
| Failure/recovery boundary | independent demotion, retry, rollback, termination, isolation, alerting |
| Contract family | compatibility semantics for API, CLI, SDK, protocol, event, file format, schema |
| Invariant/trust boundary | dedicated permission, isolation, data consistency, security, resource constraint |
| Lifecycle/concurrency/scheduling | process, worker, queue, lock, init/shutdown order, scheduler |
| Current/target/gap | evolution path or debt differs from siblings |
| Verification method | dedicated tests, diagnostics, traces, metrics, fixtures, manual checks |

Directory names, package names, class names, team ownership, dependency graphs,
and external topic trees are only candidate clues. They do not prove a domain.

## 6. Split Decision

Choose the split axis from evidence, then state why alternatives were rejected.
Common axes include runtime boundary, technical subsystem, data/state lifecycle,
external contract boundary, critical runtime flow, and change boundary.

Continue splitting when one README would mix multiple state owners, failure
models, trust boundaries, contract families, lifecycle/concurrency models, or
divergent current/target/gap paths. Stop splitting when finer detail is only a
file/API/schema/env inventory that can be read from source, or when one README
can answer the domain's state, contract, failure, lifecycle, and verification
questions coherently.

Any `single-level`, `MUST stop`, or stop-splitting conclusion is a stop claim.
Record the stop reason and review result before using it to support coverage.

## 7. Decomposition Basis

Default `decomposition_basis` stays short and records why this owner exists:

```markdown
## decomposition_basis

- **Chosen split axis**: `single-level` / <axis>
- **Why this axis**: <why it best explains behavior and evolution risk>
- **Evidence summary**: <entrypoints/state/contracts/failure/tests/source material that matter>
- **Rejected alternatives**: <only meaningful false friends>
- **Owner anchor**: <unique owner of this layer's key claims>
- **Coverage depth**: `deep` / `sampled` / `inferred` / `unknown`
- **Coverage scope**: <covered scope and known gaps>
- **Stop review**: <reviewer + result + scope>
```

Use an appendix only when the repo needs a full signal matrix:

- entrypoints;
- call/dependency edges;
- shared state/resource;
- runtime flow;
- failure/recovery boundary;
- contract surface;
- tests/configs/scripts;
- ADR/source material;
- rejected false friends;
- diagram inventory;
- reviewer challenge.

## 8. Diagrams

Mermaid fenced blocks are the canonical architecture diagrams. PNG/SVG/PDF
exports are derived artifacts. Externally generated diagrams, screenshots, IDE
dependency diagrams, and auto dependency graphs are candidates until rewritten
as maintainable Mermaid with evidence.

Default required diagram: a boundary/context view at root or domain level when
the boundary is non-obvious. Additional diagrams are required when they explain
non-obvious or risky:

- decomposition/domain ownership;
- runtime flow;
- state/resource lifecycle;
- lifecycle/concurrency/scheduling;
- failure/recovery;
- trust/config.

Current and Target diagrams must be separate. Current diagrams need code,
config, schema, test, or runtime evidence. Target diagrams need decision, ADR,
issue, conversation, or source-material evidence.

Use a compact diagram ledger by default:

| Diagram ID | Covers | Status | Evidence |
|---|---|---|---|
| ARCH-... | boundary / flow / state / failure / trust | current / target / stale | pointer |

Put detailed row links and large diagram inventories in an optional appendix.

## 9. Bottom-Up Synthesis

For major bootstrap, architecture audit, and reorganization, converge in this
order:

1. Domains or single-level root confirm state/resource owners, contracts,
   runtime flows, failure/recovery, verification, and triggered diagrams.
2. Views synthesize operating model, critical journeys, and current/target/gap
   across domains.
3. Root updates the Reader Map, core invariants, indexes, and summaries.

Forbidden: writing broad root conclusions first and making domains fit them
later. If a root/view claim lacks an owner anchor or evidence, mark it
`gap`/`unknown` or move it to the right owner.

## 10. Coverage Depth

| Coverage depth | Meaning | Covered requires |
|---|---|---|
| `deep` | Key code, config, schema, test, and runtime entry points directly reviewed | evidence pointers, triggered diagrams, owner boundaries, stop review |
| `sampled` | Risk-based sampled review | sampling strategy, sample scope, uncovered scope, stop review |
| `inferred` | Mainly inferred from directory/name/source material | cannot alone support `covered`; supplement evidence or mark gaps |
| `unknown` | Evidence insufficient | cannot mark `covered` |

Large repos may converge in segments, but segment boundaries and uncovered scope
must be visible in STATUS or the owner.

## 11. Lightweight Mode

Small CLI/library repos may keep only `architecture/README.md` when there are no
multiple public API surfaces, adapters, persistent state owners, plugin
mechanisms, compatibility commitments, or independent failure boundaries.

Lightweight mode still needs:

- the mental model;
- owner anchor;
- stop reason;
- evidence summary;
- coverage depth/scope;
- boundary/context diagram when the boundary is not obvious;
- stop review.

When new independent state, contract, lifecycle, trust, failure, or verification
semantics appear, exit lightweight mode and split.

## 12. Anti-Patterns

| Anti-pattern | Why dangerous | Result |
|---|---|---|
| Mirror source directories as architecture domains | Directory is not architecture boundary | block related `covered` claim |
| Use dependency graph or external topic tree as current authority | Candidate clues lack verified semantics | redo decomposition basis |
| One file per class/document | Reader cannot find owner hierarchy | merge or reroute |
| Root/view global conclusion without domain evidence | Inverted synthesis order | mark gap or move to owner |
| Same fact maintained in root, view, domain, and engineering area | owner split | migrate to unique owner |
| Primarily tables, no design/constraint/trade-off prose | no mental model | rewrite before coverage |
| Mixed runtime/business/source/team axes without trade-off note | unstable split | record chosen axis and rejected alternatives |
| Domain lacks why separate | invalid domain | block coverage |
| Target written as current | false implementation fact | split current/target or adjudicate |
| Diagram lacks evidence/status or mixes current/target | unauditable | cannot support coverage |
| Copy full API/schema/env fields | duplicate source truth | replace with semantic owner pointer |
| Migration written as loose history | CTG and do-not-revive drift | move to evolution/CTG owner |

## 13. Repository Shape Hints

Use examples as starting points, not templates:

| Repository type | Common axis |
|---|---|
| Small CLI/script tool | single-level or external contract boundary |
| Compiler/toolchain | pipeline stage |
| Database/search/storage | data lifecycle and recovery boundary |
| Frontend SPA | user runtime and state/data flow |
| Backend monolith | runtime flow plus data ownership |
| Microservices/monorepo | bounded context plus runtime isolation |
| SDK/client library | public contract plus platform adapters |
| Agent/AI orchestration | control loop plus execution runtime |
| Infra/IaC/platform | deployment boundary plus resource lifecycle |

Real splits must be backed by repository evidence and `decomposition_basis`.

## 14. Source Material

README, docs, ADR, PRD, runbook, design docs, and user-provided material are
source material. They can guide exploration, but product facts enter `product/`
and technical architecture facts enter architecture views/domains, decisions, or
related owners.

Source-material classification and conflict rules are owned by
[`source-material.md`](source-material.md). This file keeps only the
architecture-side constraint: no top-level `SSOT/design/`, no product fact
duplication inside architecture, and no external generated surface as authority.

## 15. Doctor Verification

Doctor's full checklist and output tags live in
[`doctor.md`](../../ssot-doctor/references/doctor.md). When architecture hard
blocks, `[DECOMPOSITION]`, `[SYNTHESIS]`, `[OWNER-ANCHOR]`, `[READER-MAP]`,
`[READABILITY]`, `[KISS]`, or `[DIAGRAM]` items are hit, the related scope
cannot be marked `covered`. This blocks SSOT coverage state, not daily code
development.

## 16. Capability → Surface Registry (v2.39)

The `Capability → Surface registry` lets a cold agent jump from a named
capability to the route + component + test that proves it works today. Doctor
`[SURFACE-PIN]` (14T) gates this. Each registry row has exactly one owner:
either the runtime owner in architecture (usual case) or the product capability
file when the product capability is the more stable lookup surface. The other
location uses a link-only pointer and does not maintain a mirror row.

Default ownership rule:

- The architecture domain README owns the row when the row is primarily a
  runtime surface contract: API route/module, handler, component, test, state.
- The product capability file owns the row only when a capability intentionally
  aggregates several runtime owners and the product surface is the stable
  contract; architecture links to that row.
- `_manifest.md` may carry machine recovery indexes, but it is not a second
  authority. If the manifest row contradicts the owner row, fix the manifest.

Default registry shape:

```markdown
## Capability → Surface registry

| Capability | Route or module | Component | Test | state |
|---|---|---|---|---|
| [agent-console-runtime-visibility](../../product/capabilities/agent-console-runtime-visibility.md) | `GET /api/tasks/{id}/runtime-stream` (`src/myapp/web/routes/runtime_stream.py:LNN`) | `web/src/components/AgentConsole.tsx` | `web/e2e/agent-console-runtime.spec.ts::default tab shows participant tool calls` | `contract` |
```

Each row must carry the `state` tag (see §3.7 of `ssot-bootstrap`). `contract`
rows must resolve all three anchors today; `design` / `poc` rows link the
next-step evidence; `debt` rows link `DEBT-NNNN`. Empty cells are not
acceptable; mark the row `gap` if any anchor is missing.

This registry is what closes the loop on CLAUDE-MAXIM-2 (Browser DOM evidence
must be Playwright, not jsdom): a `contract`-state row in a capability file
that does not name a Playwright test is doctor-blocked.
