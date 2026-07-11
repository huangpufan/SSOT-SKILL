# Product and Architecture Reader Quality

This file owns the explanatory-depth, completeness, and cold-reader acceptance
contract for `SSOT/01-product/` and `SSOT/02-architecture/`. Read it during
bootstrap, product or architecture audits, template work, and Doctor review of
a `covered` claim.

## 1. The outcome

KISS means the shortest reliable path to understanding, not the fewest words.
Remove duplication and machinery from the reader path, then write enough prose
for a newcomer to explain the product or system back in their own words.

Reader-facing documents use progressive disclosure:

1. **Orientation** — who or what this owner serves, why it exists, and one
   concrete scene.
2. **Explanation** — the causal story: normal path, state changes, boundaries,
   important variants, and failure/recovery.
3. **Reference** — compact comparisons, status, owner links, and evidence.
4. **Machine recovery** — manifests and audit metadata, outside the prose body.

Do not shorten layer 2 to make layer 3 denser. A long document can still be
unreadable when tables and identifiers carry the story; a shorter document can
still be incomplete when it omits a user surface, state owner, trust boundary,
or failure path.

## 2. Shared writing contract

Every core conclusion follows this order when the material applies:

1. context and pressure;
2. current truth in ordinary language;
3. one concrete example or end-to-end path;
4. boundary, variation, or failure/recovery;
5. owner and evidence direction.

The prose must stand on its own if tables are hidden. Tables may route,
compare, register state, or index evidence only after the prose has explained
the conclusion. Do not make a reader reconstruct causality from cells.

Define repository-specific terms positively on first use. Prefer product words
in product owners and system concepts in architecture owners. Function names,
test names, paths, state tags, protocol codes, and Doctor labels belong in a
short reference appendix or the matching manifest unless the identifier is
essential to the explanation.

Reader-facing prose must not teach the SSOT protocol. Visible references to
`ssot-bootstrap`, Doctor check numbers, adoption versions, pillar vocabulary,
or authoring instructions are meta leakage. Template authoring notes use HTML
comments and must be removed before an owner is marked `covered`.

Single ownership does not forbid orientation. A non-owner may give a short
contextual summary that says why the linked fact matters here, but it must not
redefine the contract, state, or acceptance rule. Link to the owner for the
authoritative body.

## 3. Product completeness

The product trunk collectively answers every applicable question below. A
missing class is written as a named gap or reasoned `not_applicable`; silence
cannot support `covered`.

### Product brief and model

- Who are the primary and secondary users or operators, and in what deployment
  or organisational setting do they work?
- What job are they trying to complete, what frustrates them today, and what
  user-visible result counts as success?
- What pages, entry modes, controls, settings, integrations, and diagnostic
  surfaces can they actually use today?
- What are the core product objects, how does a user understand their
  lifecycle, and which object is the source of visible truth?
- What does the product promise, limit, target, or explicitly keep out?
- What identity, access, multi-user, data-retention, privacy, and audit
  expectations affect the product experience?

### Capabilities

Each stable capability explains:

- why the user needs it;
- one current end-to-end scene;
- what the user can do today and what they see when it fails;
- important state, permission, and recovery boundaries in user language;
- current maturity and target posture;
- an example of product acceptance;
- architecture and test owners in a short evidence appendix.

Do not put implementation flow, SQL, line-number pins, or test inventories in
the product narrative. A capability may link a compact evidence row, but the
reader should not need it to understand the promise.

### Journeys

The journey set covers the primary happy path plus the important choice,
control, recovery, diagnosis, and target-only paths. Each journey names its
trigger, user goal, touchpoints, decision points, failure/recovery experience,
completion meaning, and capability links. Do not splice target-only steps into
a current journey.

### Product truth has two axes

Never use verification fidelity as product maturity. Record them separately:

| Axis | Vocabulary | Question answered |
|---|---|---|
| Product maturity | `current`, `limited`, `target`, `out` | What can the user rely on today? |
| Evidence fidelity | `browser`, `integration`, `unit`, `static`, `missing` | At what user-observable or internal layer has that claim been verified? |

`browser` means the real rendered interaction surface; `integration` means a
real API/SDK/runtime path without claiming the browser experience. `current`
with lower-fidelity evidence is a verification gap, not automatically a target
feature. `target` with a unit test is still not current. Every
`limited` or `target` product surface names current behaviour and a falsifiable
closure owner.

### Surface coverage

During bootstrap or product audit, inventory current user-visible routes,
navigation tabs, creation modes, primary controls, settings groups, operator
diagnostics, and external access channels from the real product surface. Each
item must route to a product owner or an explicit `not_product_surface`
decision. Source PRDs alone cannot establish a current surface; verify current
claims against the mounted route, handler, default DOM, CLI surface, or other
real entry point appropriate to the product.

## 4. Architecture completeness

The architecture trunk collectively answers every applicable question below.
The root teaches the system; views explain cross-owner relationships; domains
own detailed runtime truth.

### Architecture root

The root explains, in this order:

- a current request-to-result story visible to the user or operator;
- the system context and external actors;
- the runtime-owner decomposition and why it matches state/failure boundaries;
- the few global invariants and the pressure each one addresses;
- the first reading path for flow, state/data, trust/contracts,
  failure/recovery, and current/target/gap;
- a short current/target/gap posture.

One useful context diagram is better than several overlapping inventories.
Root detail stops where a view or domain becomes the owner.

### Cross-owner views

For non-trivial services, the default cross-owner set is:

- `operating-model.md` — design pressures, priorities, trade-offs, and
  technical non-goals;
- `critical-journeys.md` — end-to-end current paths and their visible result;
- `state-and-data-lifecycle.md` — durable and ephemeral state, write owners,
  transitions, retention, rebuild, and recovery;
- `contracts-and-trust-boundaries.md` — public/internal contracts,
  authentication, permissions, secrets, redaction, environment, and external
  integration boundaries;
- `failure-and-recovery.md` — detection, retry, cancellation, rollback,
  restart, degradation, and operator diagnosis across owners;
- `current-target-gap.md` — implementation evolution only.

Small repositories may merge a view with a reason. Large repositories may add
a view only for a recurring cross-owner question. Views synthesize owner facts;
they do not mirror domain tables.

### Runtime-owner domains

A domain reader surface explains:

1. a mental model and why this boundary is separate;
2. a first-screen component diagram for every covered domain, because a
   separately named runtime owner must display the boundary that justifies it;
3. one canonical current flow and its user/operator outcome;
4. owned state/resources and lifecycle;
5. three to five load-bearing contracts;
6. a representative runtime failure and recovery path;
7. concurrency, configuration, trust, deployment, or operations when they
   change this owner's behaviour;
8. local current/target/gap and verification direction.

These are questions, not a mandatory heading checklist. Combine related
answers and remove non-applicable sections. Machine pins and exhaustive rows
belong in the domain manifest or a dedicated reference appendix.

Document-self drift and retirement conditions belong in the domain manifest.
They do not appear as `Failure Modes` or `Closing Conditions` before the
runtime mental model. The prose body owns runtime failure/recovery only.

Prefer `path::symbol`, route names, SQL identifiers, selectors, or test names
over volatile line-number pins. A line number may be an auxiliary hint, never
the only stable anchor.

## 5. Source-to-owner coverage

File-level `absorbed` is not enough for a major product or architecture audit.
Build a topic disposition for the audited corpus. Each material topic is one
of:

- `absorbed` — current durable fact has an owner;
- `linked` — the source remains the appropriate evidence surface;
- `rejected-stale` — contradicted or superseded, with current owner named;
- `gap` — important but not yet proven or owned, with closure owner.

Sample the real routes, state transitions, persistence, failures, auth,
deployment, operations, and user-visible surfaces most likely to invalidate
source material. Do not promote uncommitted worktree candidates into current
authority.

## 6. Manifest archetypes

Bootstrap chooses a manifest by owner type instead of copying one universal
table everywhere:

| Archetype | Required recovery content | Forbidden cargo |
|---|---|---|
| `product-root` | core product spine/capability/journey rows, maturity, evidence/closure | apex registry, runtime surface mirror |
| `product-collection` | one row per child owner, maturity, evidence/closure | root completeness rows, apex registry |
| `architecture-root` | runtime owners, views, global invariants, CTG, unique surface registry | child symbol inventories |
| `architecture-views` | one row per cross-owner view and required question class | apex registry, domain symbols |
| `architecture-domain` | boundary, core state/contracts/flows, stable evidence pins, document invalidation/retirement conditions | global apex or capability mirrors |

Every manifest starts with `manifest_archetype: <value>`. A `covered` manifest
contains no TODO, author handoff, placeholder path, empty required cell, or
section forbidden for its archetype. Optional machinery is omitted rather than
left as an empty table.

Bootstrap `gap` is recovery coverage, never product maturity. Until evidence is
reviewed, a product manifest keeps maturity `not_assessed` beside a separate
`gap` coverage cell; before `covered`, replace it with
`current|limited|target|out`. Architecture rows analogously use
`contract|design|poc|debt|mixed` only after verification.

## 7. Cold-reader acceptance

Routing and comprehension are separate gates. Keep the existing hop-limited
anchor probe, then run a comprehension review against the actual Markdown.

The reviewer teaches the material back without reading code first:

- Product: audience, problem, current surfaces, main and recovery journeys,
  promise/non-goals, acceptance, target/gaps.
- Architecture: context, main path, runtime owners, state/write ownership,
  contracts/trust, failure/recovery, operations, current/target/gap.
- Sampled capability/domain: normal scene, failure scene, boundary,
  current/target distinction, evidence direction.

Score each dimension from 0 to 2:

1. orientation and audience;
2. causal narrative;
3. current truth;
4. target and gaps;
5. boundaries and non-goals;
6. normal and failure/recovery paths;
7. understandable terminology;
8. owner and evidence reachability.

Passing requires no zero, at least 14/16, no critical truth error, and a clean
manifest check. Hide tables and repeat the teach-back: prose must still explain
the story. Adoption of a high-impact reader-contract upgrade uses the existing
`semantic_impact=high` independent-review exception in
`status-protocol.md §6`; it does not create a fifth exception. Include the
consumer's first covered-claim-under-the-upgrade in that adoption review.
Ordinary later covered claims use the reviewer selected by §6 unless another
listed exception applies. The only result values are `needs-fix` and
`no-more-required-changes`; do not soften or rename them.
