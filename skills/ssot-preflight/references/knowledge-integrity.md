# Knowledge Integrity Protocol

This file is the semantic owner of the SSOT knowledge confidence state machine, write-time annotation, promotion/demotion rules, and blocking logic. Read it when writing long-lived knowledge from inferred or conversational sources, when inline updates encounter content with confidence annotations, when Doctor checks confidence tags, or when Stop review evaluates coverage scope.

## Table of Contents

- [1. Confidence state machine](#1-confidence-state-machine)
- [2. Write-time annotation](#2-write-time-annotation)
- [3. Promotion and demotion](#3-promotion-and-demotion)
- [4. Blocking rules](#4-blocking-rules)
- [5. Frontmatter format](#5-frontmatter-format)
- [6. Backward compatibility](#6-backward-compatibility)

## 1. Confidence state machine

Every long-lived knowledge entry in SSOT has an implicit or explicit confidence state. The state determines which authoritative locations the knowledge may be written to, and whether it blocks coverage claims.

```text
hypothesis ──► candidate ──► source-backed ──► verified
                                                 │
                                          (implicit, no annotation)
```

| State | Meaning | Permitted authoritative locations |
|---|---|---|
| `hypothesis` | Agent inference, no direct evidence | gotchas (mark source), STATUS.md open gaps |
| `candidate` | Has initial evidence (code comments, commit messages, docs, conversational confirmation) but not code-level cross-verified | Emergent/historical areas (gotchas, bugs, tech-debt, decisions) + architecture gap/unknown annotations |
| `source-backed` | Has direct code/config/schema/test evidence | All authoritative locations |
| `verified` | Confirmed by independent reviewer or subsequent session | All authoritative locations; this is the default state, no confidence annotation needed |

States can only be promoted in order, but intermediate states may be skipped (e.g., agent infers and immediately finds code evidence, marks `source-backed` directly). Demotion may go from any state to any lower state or be deleted outright.

Confidence is separate from a bug's failure state. A confirmed failure may be
`failure_state: open` before its cause or fix is known; unknown cause and
unverified fix claims remain labeled as inference with fitting confidence.
`fixed_in` stays `none` until closure evidence names a real change. Do not move
an unresolved defect into technical debt merely to avoid representing `open`:
technical debt records an accepted repayment obligation, while the bug entry
owns the failure fact and its current state.

Research/PoC evidence packets under `SSOT/04-records/research/` usually support
at most `source-backed` claims. A reproducible packet can raise a distilled
claim row to `source-backed` when it names the method, inputs, artifacts, and
boundary clearly enough for recheck. It does not make the claim a normal
verified SSOT fact by itself. Promotion to the implicit `verified` default
requires the relevant product, architecture, decision, testing, bug, gotcha, or
debt owner to absorb the long-lived fact and a later independent review or
subsequent session to confirm that owner-level evidence still holds.

### 1.1 Product/architecture reader-recovery axis (v2.43; task-based v2.60)

Evidence backing (the confidence state machine above) is orthogonal to whether
a cold reader can recover and use a claim from a realistic task. For v2.60,
per-file `intent_recovery` and the structured artifact below apply only to
reader bodies under `01-product/` and `02-architecture/`. A `verified` claim
there can still be too remote, table-dependent, or contradicted by another
owner. The reader-recovery axis records this independently through the task protocol in
[`ssot-doctor/references/cold-agent-sim.md`](../../ssot-doctor/references/cold-agent-sim.md).

Root, process, record, and glossary bodies use the same plain-language and
completeness floor from `reader-quality.md`, but v2.60 does not require or
permit them to manufacture a product/architecture `intent_recovery` artifact.
Their coverage is governed by Area Status, confidence, deterministic body
checks, and a scoped semantic stop review. A future protocol may add structured
artifacts for those profiles only by defining their complete task matrix and
validator first.

| State | Meaning | Required evidence |
|---|---|---|
| `intent_recovery: covered` | The latest applicable task-based cold review includes this owner, stays inside its bounded read set and hop budget, finds no cross-owner truth conflict, and passes the full reader-quality gate. | Durable reader-review artifact and the task row that names this owner |
| `intent_recovery: partial` | At least one applicable task passes, but another required task, evidence sample, owner link, or locality check is missing or fails. | Durable artifact plus an open `STATUS.md ## Pending Captures` row naming the failed task and closure owner |
| `intent_recovery: gap` | No applicable task sampled the owner, every applicable task failed, or the latest artifact is stale against the owner/inventory baseline recorded by the review. | Missing or failing task row in the latest artifact |

**Product current-posture clause (v2.60).** A product task recovers the current
user-visible behaviour, product maturity, evidence fidelity, and evidence or
closure owner according to the vocabulary owned only by
[`reader-quality.md §3`](reader-quality.md#3-product-completeness). Product
documents never substitute architecture lifecycle state, and no review rule
defines a second product evidence vocabulary. If the current behaviour can
only be inferred from architecture, tests, or silence, the task fails.

**Inventory and manifest binding.** A covered product root needs a complete
surface inventory; a covered architecture root needs an owner inventory that
classifies runtime, support, and target owners, includes applicable cross-owner
views, and routes each technical surface to one owner. The location-specific
manifests remain finite recovery indexes. A sampled body cannot rescue an
omitted inventory or manifest row, and a manifest cannot rescue prose that a
reader cannot teach back with tables hidden.

**Task-coverage rule (v2.60).** Reviews are scheduled from realistic reader
tasks and the two inventories, not from intent/truth pillars. Every covered
root must pass the mandatory product, architecture, operations, and
product-to-architecture trace tasks that apply to it. Every covered child owner
must appear in a deterministic rotation or a risk-directed sample recorded in
the review artifact. A task omitted from the current rotation is a named
deferral, not evidence of coverage.

Default: when a fresh product or architecture body has not yet been sampled by a task-based cold
review, treat it as `intent_recovery: gap`. Reader recovery is an observed
property; unlike implicit confidence, it gets no free pass from static lint.

The two axes interact via the binding rule:

> A product or architecture scope marked `covered` cannot coexist with
> `intent_recovery: gap`. If the
> latest applicable cold review fails or does not sample the scope, demote the
> scope to `unknown` (or `gap` when retiring it) and record
> `demoted_reason: reader-review-gap-<review-id>` until a passing task closes
> the gap.

**Upgrade compatibility.** Pre-v2.60 pillar-based reports remain historical
evidence for a consumer whose tracked protocol predates v2.60; do not rewrite
those artifacts. On advancing the tracking baseline, replace pillar declarations with
task rows and a durable v2.60 reader-review artifact. An in-progress upgrade
may defer this for one review cycle only when `STATUS.md` names every affected
scope and closure task and does not claim `converged`; a second cycle demotes
the scope under the binding rule.

This product/architecture rule extends — does not replace — §4's existing
`hypothesis`/`candidate` block-`covered` rule. A scope must satisfy both the
confidence gate and reader recovery, with `partial` requiring a Pending Capture.
The §5 frontmatter format may add:

```yaml
---
intent_recovery: covered | partial | gap
intent_recovery_evidence: "SSOT/.bootstrap/reader-review-<id>.md#task-<id>"
---
```

Do not add this frontmatter to root, process, record, or glossary templates.
`intent_recovery_evidence` is required when product/architecture
`intent_recovery` is `covered` or
`partial`. Promotion and demotion are by-products of task-based review cycles,
not separate activities.

---

## 2. Write-time annotation

When writing long-lived knowledge to SSOT, the agent determines default confidence by knowledge source:

| Knowledge source | Default confidence | Description |
|---|---|---|
| Direct derivation from code/config/schema/test | No annotation needed (equivalent to `verified`) | Code itself is evidence |
| Conclusion confirmed by user in conversation | `candidate` | Conversational confirmation provides initial evidence, still needs code-level cross-verification |
| Agent code-analysis inference | `candidate` | Has analytic basis but inference may be wrong |
| Research/PoC record claim row | `candidate` or `source-backed` | Use `source-backed` only when the packet is reproducible and directly supports the claim; never treat the packet alone as `verified` |
| Agent inference, no direct evidence | `hypothesis` | Verbal agreement, guess, implicit coupling judgment |

Write rules:

- Default confidence may be adjusted upward based on actual evidence. E.g., if a conclusion confirmed by user in conversation is also verified by the agent against code, mark directly as `source-backed` rather than `candidate`.
- When marking `source-backed`, the `evidence` field must be provided simultaneously (see §5); otherwise use `candidate`.
- Default confidence may not be adjusted downward to bypass write-location restrictions.
- `hypothesis` must not be written to the authoritative body of architecture views/domains. It may exist as a gap annotation or STATUS.md open gap to mark "verification needed here".
- Research/PoC packet evidence promoted into an owner keeps a pointer to the
  packet and remains `source-backed` until owner absorption plus later review
  confirms the claim as normal SSOT truth.

---

## 3. Promotion and demotion

### 3.1 Promotion timing

Promotion is embedded in existing SSOT protocol touchpoints; no dedicated "promotion activity" is needed.

| Existing protocol touchpoint | Promotion direction | Trigger |
|---|---|---|
| Inline update | candidate → source-backed | When the agent modifies code and finds it touched code related to a candidate claim, and the code corroborates the claim |
| Commit review | candidate → source-backed | When reviewing the diff and finding a new commit corroborates a candidate claim |
| Conversation self-check | hypothesis → candidate | When the agent reviews this session and finds a hypothesis gained user confirmation or initial evidence in conversation |
| Stop review | source-backed → verified | When the independent reviewer reviews coverage scope and confirms source-backed claim evidence is valid; remove confidence annotation |

When an agent encounters content with confidence annotations, it does not need to actively seek evidence to promote it -- but if relevant evidence happens to be at hand (because doing a code task), update the annotation in passing. Promotion is a by-product of existing work, not an extra task.

### 3.2 Demotion timing

| Demotion trigger | Typical timing | Action |
|---|---|---|
| Code change refutes the claim | Commit review, inline update | Demote (source-backed → candidate or lower) or delete, record demotion reason |
| Pointer broken (file/function no longer exists) | Doctor L1 deterministic check | Demote or delete, record reason |
| New evidence conflicts with claim | Inline update, commit review | Demote or enter open adjudication |
| User explicit denial | Conversation | Delete or mark resolved/obsolete |

Demotion must record the reason; format is not enforced -- may add `demoted_reason` in frontmatter or annotate inline in body.

### 3.3 Role assignment

| State transition | Role |
|---|---|
| hypothesis → candidate | Working agent (updater) |
| candidate → source-backed | Working agent (updater) |
| source-backed → verified (remove annotation) | Independent reviewer (stop review) or agent in a different session confirms |
| Any demotion | Working agent, executes immediately on discovering evidence invalidation |

verified is an implicit state (no confidence annotation); promotion to verified is equivalent to deleting confidence frontmatter. This aligns with the existing "all SSOT content is trusted by default" principle -- only add confidence when uncertainty needs special marking.

---

## 4. Blocking rules

`hypothesis` and `candidate` block the `covered` state of their scope, equivalent to `gap`/`unknown`.

Specific rules:

- When a region or architecture domain contains `confidence: hypothesis` or `confidence: candidate` content, that scope cannot be marked `covered`.
- This means to reach `converged`, all hypothesis/candidate must be resolved -- either find evidence and promote to source-backed or verified, or demote to unknown and enter open gaps, or delete.
- `source-backed` does not block `covered`. It indicates "evidence exists but not yet independently confirmed", compatible with the meaning of `covered` ("content matches code and has stop review").
- If the team does not pursue `converged` (script/prototype projects), hypothesis/candidate may persist indefinitely without affecting daily development.
- (v2.60) In product and architecture, `intent_recovery: gap` blocks `covered` for the same scope, even when `confidence` is `verified`. To reach `converged`, every product/architecture owner in the scope must have at least `intent_recovery: partial` with a Pending Capture for the failed or deferred task. Root, process, record, and glossary areas instead use their Area Status row and scoped semantic stop review; they do not carry this frontmatter. Doctor `[INTENT-RECOVERY]` (14Y) gates the product/architecture scope.

---

## 5. Frontmatter format

Extend the existing `SKILL.md` §3.4 confidence frontmatter:

```yaml
---
confidence: hypothesis | candidate | source-backed
source: conversation | code-analysis | code-comment | git-history | documented
discovered_at: 2026-05-27
evidence: "src/auth/handler.ts#retryWithBackoff (retry logic)"
---
```

Field description:

| Field | Required | Description |
|---|---|---|
| `confidence` | Yes (if not verified) | Current state in the state machine |
| `source` | Yes | Knowledge source type |
| `discovered_at` | Yes | Discovery date |
| `evidence` | Required when `source-backed`; recommended for `hypothesis`/`candidate` | Evidence pointer (see §5.1 anchoring rules) |

### 5.1 Evidence pointer anchoring (v2.13)

When `evidence` points to code, `[SHOULD]` anchor to the **symbol name** rather than line number, in the form `path#symbol` (e.g., `src/auth/handler.ts#retryWithBackoff`):

- Line numbers (`path:line`) silently drift as code moves; symbol names resist movement and can be grep-rechecked for existence by [`assets/scripts/ssot-lint.sh`](../../ssot-doctor/assets/scripts/ssot-lint.sh) (invalid output is `[STALE]`).
- File-level facts may write only `path`; when pointing to a specific implementation, prefer `path#symbol`.
- `[MAY]` only for core invariants (architecture-level, security-level) append content-hash or commit SHA to lock version; do not compute hash for every evidence entry, otherwise meaningless code changes trigger noise alerts.

`verified` state needs no frontmatter -- content without confidence annotation is verified.

---

## 6. Backward compatibility

The old `confidence: inferred` + `needs_verification: true` format is treated as equivalent to `candidate`:

| Old format | Equivalent new state | Migration |
|---|---|---|
| `confidence: inferred` + `needs_verification: true` | `candidate` | Mechanical migration not required; agents handle per new protocol when encountered |
| `confidence: inferred` (no needs_verification) | `candidate` | Same as above |
| No confidence annotation | `verified` | No handling needed |

Protocol upgrade review (v2.11) does not require traversing all SSOT files for mechanical replacement of old annotations. Agents handle old formats by the equivalence relation when encountered in daily maintenance.

Similarly, the `path#symbol` evidence anchoring introduced in v2.13 does not require mechanical migration of existing `path:line` pointers; when an agent touches an invalid line-number pointer during inline update or Doctor recheck, change it to symbol anchor in passing.

Pillar-based `intent_recovery_pillars` and evidence strings from protocols
before v2.60 are also read-only compatibility data. When an owner is next
reviewed under v2.60, replace them with a task-row pointer to the durable
reader-review artifact; do not create new pillar declarations.
