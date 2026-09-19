# Intent Ownership Protocol (v2.43; reader orientation revised v2.59; adjudication boundary v2.64)

This file is the semantic owner of four intersecting rules:

1. **Apex behavior maxim → SSOT-owner mapping** — every numbered named
   rule a project root constraint file enumerates (`CLAUDE-MAXIM-N`,
   `CORE-RULE-N`, etc.) must have exactly one SSOT owner.
2. **Repo-wide invariant single-owner rule** — invariants such as
   Web-First, Single Writer, route-only-protocol-adapter, SdkAdapter-only,
   mission-only leaf, replay equivalence, and core-call traceability must
   live as prose in exactly one SSOT body location plus exactly one CORE-REF
   one-line summary.
3. **`[CORE-REF: <owner_path#anchor>]` syntax** — the reserved cross-link
   form a CORE-REF startup file uses to point at its single SSOT owner
   without recopying the invariant body.
4. **Adjudication boundary registry (v2.64)** — the single canonical list
   of every rule whose change is a human decision, not an agent edit.
   See §6.

Read this file when:

- Bootstrapping or auditing a repository whose root constraint file
  (`CLAUDE.md`, `AGENTS.md`, `.cursor/rules/*`, `.windsurf/rules/*`,
  `GEMINI.md`, or equivalent) enumerates apex behavior maxims or repo-wide
  invariants.
- Adjudicating between "put this body in SSOT" and "put this body in
  CORE-REF" or detecting that the body lives in both.
- Deciding which DISC entry, capability invariant section, or architecture
  domain invariant should own a specific maxim.
- Verifying compliance with doctor rows `14W [OWNER-ORIENTATION]`,
  `14X [MAXIM-OWNER]`, and `14Z [CORE-REF-PROSE]`.

## Table of contents

- [1. Apex behavior maxim mapping](#1-apex-behavior-maxim-mapping)
  - [1.1 Apex maxim registry (consumer side, cycle-3)](#11-apex-maxim-registry-consumer-side-cycle-3)
- [2. Repo-wide invariant single-owner rule](#2-repo-wide-invariant-single-owner-rule)
- [3. `[CORE-REF: <owner_path#anchor>]` syntax](#3-core-ref-owner_pathanchor-syntax)
- [4. Boundary with `[FORK]` and `[OWNER-ANCHOR]`](#4-boundary-with-fork-and-owner-anchor)
- [5. Doctor enforcement](#5-doctor-enforcement)
- [6. Adjudication boundary registry (v2.64)](#6-adjudication-boundary-registry-v264)

## 1. Apex behavior maxim mapping

A project's root constraint file may enumerate a numbered series of
**apex behavior maxims** — short, named rules that codify failure modes
the project must never re-enter. Examples in this protocol's reference
consumer:

- `CLAUDE-MAXIM-1`: diagnostics are not a compliance channel.
- `CLAUDE-MAXIM-2`: jsdom / happy-dom is not browser evidence.
- `CLAUDE-MAXIM-3`: a single-step fixture is not a subagent test.
- `CLAUDE-MAXIM-4`: participant inference happens at a single point.
- `CLAUDE-MAXIM-5`: subagent visibility tasks must run a real-SDK end-to-end suite.
- `CLAUDE-MAXIM-6`: closure documents are not author-self-evaluated.

Mapping rule:

> Each apex maxim has **exactly one** SSOT owner. The owner is one of:
> - a unique `development/discipline.md#DISC-NNNN` entry,
> - a capability invariant section (`product/capabilities/<cap>.md` invariants block),
> - or an architecture domain invariant (`architecture/<domain>/README.md` invariants block).
>
> The root constraint file holds at most a one-line link to the owner. Other
> non-owner DISC entries, capability files, or architecture domains may
> reference the maxim, but only as a one-line link — not as a recopied body.

Owner selection guide:

| Maxim shape | Default owner |
|---|---|
| Cross-task procedural rule (workflow / verification cadence / commit discipline) | `development/discipline.md#DISC-NNNN` |
| Capability-scoped invariant (a specific user-observable surface must always do X) | the capability's invariants section |
| Architecture-scoped invariant (a runtime owner / contract / state never violates X) | the architecture domain's invariants section |

When in doubt, prefer `development/discipline.md`: cross-task procedural
rules are the largest class of apex maxims, and a single discipline file
keeps cold-agent routing predictable.

A maxim too narrow to deserve its own DISC entry is folded into an
existing owner; the standalone listing in the root constraint file is
then deleted, not kept as a parallel authority.

### 1.1 Apex maxim registry (consumer side, cycle-3)

The consumer project MUST maintain a single canonical **Apex maxim
registry**. At protocol v2.64 and later, that registry is the
`SSOT/README.md ## 裁决边界` table defined in §6 — maxim rows there carry
kind `apex-maxim` and keep the `Link state` cell from the legacy shape.
Before v2.64, the registry lives at one of (in priority order):
`glossary/README.md`, `development/discipline.md` head matter, or
`architecture/README.md` invariants section. Only one location may hold
rows at a time; a protocol upgrade moves legacy rows into the boundary
table and leaves a pointer line behind.

The registry is the doctor `[MAXIM-OWNER]` (14X)
read anchor — without it, 14X must walk every DISC header, capability
invariants section, and architecture invariants section to reconstruct
the mapping, and a missing owner registers as silence rather than a
positive `not_yet_owned` row.

Legacy (pre-2.64) registry shape:

| Apex maxim | Slug | SSOT owner | Root-file link state |
|---|---|---|---|
| `CLAUDE-MAXIM-1` | diagnostics-not-compliance-channel | `development/discipline.md#DISC-NNNN` | `core-ref-thin` / `inline-body` |
| `CLAUDE-MAXIM-2` | jsdom-not-browser-evidence | `development/discipline.md#DISC-NNNN` | `core-ref-thin` / `inline-body` |
| ... | ... | ... | ... |

- `SSOT owner` is one of the three forms in §1:
  `development/discipline.md#DISC-NNNN`, a capability invariants
  section, or an architecture domain invariants section. Empty cells
  are not acceptable; a maxim that has no chosen owner yet uses
  `not_yet_owned — <reason + revisit signal>` and routes to
  `[MAXIM-OWNER]` (14X).
- `Root-file link state` records whether the root constraint file
  (`CLAUDE.md` / `AGENTS.md`) entry for this maxim has thinned to a
  one-line `[CORE-REF: <owner_path#anchor>]` link (`core-ref-thin`) or
  still carries the inline rule body (`inline-body`). A row whose state
  is `inline-body` is NOT a missing-owner row — it is a CORE-REF
  prose-thinning gap and routes to `[CORE-REF-PROSE]` (14Z), not
  `[MAXIM-OWNER]` (14X). See §4.
- Non-owner DISC entries, capability files, and architecture domains
  that reference the maxim do so via one-line links only, not via
  registry rows.

## 2. Repo-wide invariant single-owner rule

Repo-wide invariants — the sentence-shaped statements that govern every
file in the repository — are governed by the same single-owner rule as
apex maxims. The reference consumer's invariants:

- Web-First: user-facing capabilities go through Web API/Dashboard.
- Single Writer: database writes are serialized through the Web process.
- Route only does protocol adaptation, not business truth.
- All AI calls go through `SdkAdapter`.
- Core calls leave a traceable `request_id` / `task_id` / `node_id` chain.
- Mission-only leaf for the task-tree engine.
- Replay Equivalence for terminal/interview transcripts.

Rule:

> A repo-wide invariant has **exactly one prose owner** inside SSOT
> (typically `architecture/README.md` core-invariants section or the
> responsible architecture domain README) and **exactly one CORE-REF
> one-line summary**. Other SSOT body files (root summary, views, sibling
> domain READMEs, `development/`, `product/`) reference the owner by link
> plus a one-line orientation; they do not restate the invariant body as a
> paragraph, full-clause bullet, or invariant-table cell. CORE-REF mentions
> of the same invariant thin to a one-sentence summary that points at the
> SSOT owner via `[CORE-REF: <owner_path#anchor>]`. CORE-REF and SSOT must
> not both maintain the prose body.

The same single-owner rule applies to **`Capability → Surface registry`**
rows (capability ↔ route + handler `path:LNN` ↔ component path ↔ test):
pick one runtime owner per registry row (architecture domain README **or**
product capability file, not both); the other location links out.

## 3. `[CORE-REF: <owner_path#anchor>]` syntax

`[CORE-REF: <owner_path#anchor>]` is the reserved cross-link form a
CORE-REF startup file uses to point at the SSOT owner of an apex maxim or
repo-wide invariant.

Shape:

```
[CORE-REF: <ssot-relative-path>#<anchor>]
```

- `<ssot-relative-path>` is a path under `SSOT/` written without the
  leading `SSOT/` prefix when the CORE-REF file lives at the repository
  root and the project's CORE-REF reading convention strips that prefix
  (otherwise include it). Examples: `development/discipline.md`,
  `architecture/backend-runtime/README.md`,
  `product/capabilities/agent-console-runtime-visibility.md`.
- `<anchor>` is a Markdown heading slug or an explicit `<a id="...">`
  anchor inside the owner file. Examples: `#DISC-0008`,
  `#single-writer`, `#capability-runtime-visibility-invariants`.

Usage in a CORE-REF startup file:

```markdown
- **CLAUDE-MAXIM-3** [CORE-REF: development/discipline.md#DISC-0008]:
  subagent fixture must contain ≥2 inner tool_use + tool_result pairs,
  ≥1 inner text, lifecycle started/completed.
```

Constraints:

- The CORE-REF mention is a **one-sentence summary** plus the
  `[CORE-REF: ...]` link. Multi-sentence prose, full-clause bullet lists,
  or invariant-table cells inside CORE-REF are forbidden — that body
  belongs in the SSOT owner.
- The summary must be derivable from the owner; it must not introduce
  facts the owner does not state.
- Exactly one `[CORE-REF: ...]` per maxim / invariant. If a maxim is
  conceptually shared across two owners, pick one as primary owner and
  let the other link out from its body, not from CORE-REF.

Doctor `[CORE-REF-PROSE]` (14Z) detects violations: a CORE-REF startup
file that carries the prose body instead of the one-line summary, or
that omits the `[CORE-REF: ...]` link entirely while restating the
invariant.

## 4. Boundary with `[FORK]` and `[OWNER-ANCHOR]`

- `[FORK]` (doctor row 15D, formerly 14W) catches the
  architecture-domain-to-architecture-domain subset: the same long-lived
  fact maintained in ≥2 architecture domain READMEs. It does not fire on
  CORE-REF ↔ SSOT duplication or product-capability ↔ architecture-domain
  duplication.
- `[OWNER-ANCHOR]` (doctor row 14F) catches anchor presence: every key
  long-lived claim must have a unique owner. It is silent when the claim
  exists in two locations as long as both *carry* the same anchor — it
  does not detect prose-body duplication.
- `[CORE-REF-PROSE]` (14Z) catches apex-invariant prose duplication
  across {`architecture/README.md`, `architecture/views/*.md`,
  `architecture/<domain>/README.md`, `development/README.md`,
  `development/discipline.md`, `product/` body files, CORE-REF startup
  files} and `Capability → Surface registry` rows duplicated across
  {architecture domain README, product capability file,
  `product/journeys/*.md`}.

Apply the most specific rule first: an architecture-domain ↔
architecture-domain duplication of an invariant body is `[FORK]`; an
architecture-domain ↔ CORE-REF duplication of an invariant body is
`[CORE-REF-PROSE]`; a missing anchor entirely is `[OWNER-ANCHOR]`.

## 5. Doctor enforcement

| Doctor row | What it catches | Owner |
|---|---|---|
| `14W [OWNER-ORIENTATION]` | Covered architecture domain does not teach its mental model, boundary, and one canonical current flow before reference tables, or leaves document-self drift/retirement machinery in reader prose | `reader-quality.md §4`, `area-model.md §2.2` |
| `14X [MAXIM-OWNER]` | Apex maxim lacks a unique SSOT owner, or its body is recopied into a non-owner DISC / capability / architecture file | this file §1 |
| `14Z [CORE-REF-PROSE]` | Apex invariant body maintained in ≥2 SSOT body locations, or CORE-REF holds the body instead of the one-line summary, or `Capability → Surface registry` rows duplicated across architecture-domain ↔ product-capability ↔ product-journey | this file §2, §3 |

These rows are the intent-recoverability enforcement surface for owner
orientation, prose forks, and apex-maxim findings. Since v2.59, 14W judges
reader meaning rather than an exact heading triad; document-self invalidation
and retirement conditions live in the matching domain manifest. The rows work
alongside `[FORK]` (15D), `[OWNER-ANCHOR]` (14F), and `[FIRST-DAY]` (15E).

## 6. Adjudication boundary registry (v2.64)

An **adjudication boundary** is a repository rule whose change is a human
decision, not an agent edit. It covers: repo-wide architecture invariants
(§2), apex behavior maxims (§1), product promises the user confirmed, and
cross-task process rules that were human-established. The boundary answers
the question a working agent cannot answer from prose alone: *"may I change
this, or must a human decide?"*

The semantics:

- An agent may change code, docs, and tests that a registered rule
  *constrains*. It may not change the rule's *meaning*.
- Changing a registered rule requires a human decision recorded as a new
  `04-records/decisions/` entry or an explicit user directive; the registry
  row's `Established by` cell points at that authority.
- An agent that finds reality conflicting with a registered rule files an
  `ADJ-` row under `STATUS.md ## Open Adjudications`. It does not rewrite
  the rule, and it does not silently bend code around it without the
  conflict being visible.
- An agent may *propose* a boundary row at state `candidate`; only a human
  decision (DEC entry or explicit user directive) turns it `confirmed`.
  Confirmed rows bind; candidate rows are visible proposals.

Canonical location: `SSOT/README.md`, section `## 裁决边界` (English:
`## Adjudication boundary`). `SSOT/README.md` is on the mandatory preflight
floor, so the boundary is read before every substantive task — not only
when the task-entry map happens to route through a trunk.

Exact schema:

| ID | Kind | Rule | Owner | Established by | State |
|---|---|---|---|---|---|
| `INV-NN` | `arch-invariant` / `product-promise` / `process-rule` | one-line rule name | one resolving `path#anchor` Markdown link to the prose owner | `DEC-NNNN` link / `user-directive` / `bootstrap` | `confirmed` / `candidate` |
| `CLAUDE-MAXIM-N` / `CORE-RULE-N` | `apex-maxim` | one-line rule name | one resolving `path#anchor` link (`DISC-NNNN`, capability, or domain owner) | promotion evidence link or `user-directive` | `core-ref-thin` / `inline-body` / `not_yet_owned` |

Rules:

- The table is a register. One line per rule; cells stay pointer-sized.
  The rule's prose body — pressure, scope, consequences, exceptions —
  lives at the owner link, never inside the table.
- **Bidirectional tag.** The owner body of every `confirmed` /
  `core-ref-thin` row carries its registry ID at the rule's anchor
  (`INV-03`, `CLAUDE-MAXIM-2`), so a reader of the body sees that the rule
  is registered and lint can verify registry ↔ body both ways. A `candidate`
  row's owner may carry the tag early; `not_yet_owned` rows carry none.
- Registry ↔ body checks: lint `[INV-REGISTRY]` validates the section and
  row schema; `[INV-BODY]` fails a `confirmed`/`core-ref-thin` row whose
  owner body lacks the ID tag, and warns on an `INV-`/`MAXIM-` tag in a
  body file that has no registry row.
- Rows are capped at rules a stranger must not violate silently —
  typically under 25. Domain-local technical invariants stay prose in
  their domain README unless promoted; an established rule demoted by a
  later decision is removed from the table, with the DEC link recorded in
  the decision entry.
- Promotion route: a rule-shaped conclusion that other work could violate
  silently (an ADR's binding constraint, a repeated bug pattern turned
  into a boundary, a user-locked product promise) becomes a `candidate`
  row via `$ssot-closeout`; the altitude decision uses
  `promotion-rationale.md`. Most rules stay authority-level prose in their
  owner; only cross-task red lines register.
- When no rule qualifies yet (early bootstrap), the section carries one
  reasoned empty note rather than a fake row.
- This table also supersedes the §1.1 standalone maxim registry at v2.64+:
  one registry, one read anchor, maxim rows identified by `apex-maxim`
  kind.
