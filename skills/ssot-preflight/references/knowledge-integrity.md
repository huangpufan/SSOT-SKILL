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

### 1.1 Intent-recovery axis (v2.43)

Evidence backing (the confidence state machine above) is orthogonal to
whether a cold agent can recover the claim from user-visible intent. A
`verified` claim with sound `path:LNN` evidence can still be unreachable
from the user's prompt within the 5-hop budget defined in
[`ssot-doctor/references/cold-agent-sim.md`](../../ssot-doctor/references/cold-agent-sim.md).
The intent-recovery axis records this independently:

| State | Meaning | Source |
|---|---|---|
| `intent_recovery: covered` | The cold-agent-sim harness routed from at least one user-visible intent prompt to this owner's authoritative anchor within budget, in the most recent cycle that included the owner's slice. The harness recorded `verdict=PASS` for a trial whose `pillar` matches the owner's layer (`design_intent` / `product_intent` / `design_truth` / `product_truth`). | cold-agent-sim cycle report Results table |
| `intent_recovery: partial` | At least one cold-agent-sim trial in the owner's slice passed AND at least one in the same slice failed; OR the slice has trials in some but not all relevant pillars. The owner is partially routable — typically `[SYMBOL-PIN]` resolves but `[SURFACE-PIN]` does not, or `product_truth` passes while `product_intent` fails. | cold-agent-sim cycle report Skill-fail / Doc-fail rows |
| `intent_recovery: gap` | No cold-agent-sim trial has covered this owner in the most recent applicable cycle, OR every trial that targeted it failed (`miss_class` ∈ {`missing-owner`, `prose-fork`, `broken-ref`, `glossary-gap`, `truth-state-gap`}). | cold-agent-sim cycle report; or absence of any trial against the owner's slice |

**Product current-truth clause (v2.44)**: `product_truth` is not limited to
shipped contract surfaces. A trial PASSes when it routes to the product owner
and recovers the current state of the promised surface: `state: contract`
with a `[SURFACE-PIN]` anchor, `state: design` / `state: debt` with the
current user-visible behavior plus a falsifiable gap / closure owner, or an
explicit `Out` / `not_applicable` row with reason and revisit owner. A trial
FAILs with `miss_class=truth-state-gap` when the product owner names a surface
but does not say whether it is shipped, design/debt, Out, or not applicable;
when it says "later" without a closure owner; or when the current behavior can
only be inferred from architecture / tests instead of being stated in product.

**Core recovery manifest binding (v2.45 / v2.46)**: `intent_recovery: covered` for the
`product` or `architecture` area also requires the area-level Core recovery
manifest from `area-model.md §2.0.2` to be complete. Every manifest row whose
required pillar is not `not_applicable` must have a latest applicable PASS or a
state-tagged deferral with a Pending Capture that names the missing pillar and
closure owner. A sampled owner body cannot override a missing manifest row: if
the finite manifest omits a core capability, journey, runtime owner, or
cross-owner view, the area is `partial` at best. v2.46 also requires the
manifest's completeness argument to recover why the finite set is complete,
which product-model / operating-model classes are core, which near-miss items
are excluded, and what wrong conclusion an omission would cause. If the
manifest advertises a row as `contract` while the owner body still contains an
unresolved `design` / `debt` / `Out` current-truth row for that same
user-visible or design surface, the row is stale and Doctor reports
`[CORE-COVERAGE-MAP]`. Use `mixed` for core rows that intentionally combine
shipped contract truth with unresolved design/debt/out truth under the same
owner.

**Multi-pillar rule (cycle-2)**: when an owner declares
`intent_recovery_pillars: [..]` with ≥ 2 pillars, `intent_recovery:
covered` requires `verdict=PASS` in **every** declared pillar of the most
recent applicable cycle. If the latest cycle PASSed some declared pillars
and FAILed or did not sample others, the owner is `intent_recovery:
partial` and must carry an open `STATUS.md ## Pending Captures` row
naming the unsatisfied pillar(s) and the expected miss_class fix layer
per [`ssot-doctor/references/cold-agent-sim.md`](../../ssot-doctor/references/cold-agent-sim.md)
§3.1. A single PASS in a non-declared pillar does not promote the owner
to `covered`; declared-pillar coverage is what the doctor row 14Y gates.
A `partial` annotation is also legitimate when the latest cycle's §1.5
owner-pillar coverage matrix recorded the (owner, pillar) pair as
`pillar-not-applicable-to-cycle`. The Pending Capture row in that case
names the missing pillar AND the cycle id that deferred it.

Default: when a fresh SSOT area has not yet been sampled by any
cold-agent-sim cycle, treat it as `intent_recovery: gap` — the SSOT cannot
claim intent-routability without harness evidence (this mirrors the "no
annotation = verified" default of the confidence axis: there is no
symmetrical free pass on the intent axis because intent recovery is an
emergent surface, only knowable from harness behaviour, not from a static
lint).

The two axes interact via the binding rule:

> A scope marked `covered` (in `STATUS.md` coverage states) cannot
> coexist with `intent_recovery: gap`. If the cold-agent-sim has not
> validated intent recovery for the scope, the scope must be `gap` or
> `unknown` until the next cycle's harness run records a passing trial.
> Existing `covered` claims demoted by a new harness cycle's failure are
> downgraded to `unknown` with a `demoted_reason:
> intent-recovery-gap-cycle-<N>` annotation.

**Lag-deferral clause (v2.43.1, cycle-3).** A consumer SSOT whose
`STATUS.md` records `tracked_skill_version < 2.43` and whose
`coverage_result` is `in_progress` MAY temporarily carry `covered`
scopes alongside `intent_recovery: gap` for at most one cold-agent-sim
cycle (the per-area sampling cycle that adopts v2.43). The deferral is
legitimate only when (a) `STATUS.md` lists every affected scope in a
single Pending Capture row naming the v2.43 axis-adoption work,
(b) the next cold-agent-sim cycle's sample includes at least one trial
per declared pillar of every deferred owner, and (c) `coverage_result`
does not advance to `converged` while the deferral is open. After that
one cycle, automatic demotion per the binding rule above applies
unconditionally; a second consecutive cycle of deferral escalates to
`skill-fail` per cold-agent-sim §4 tie-breaker.

This rule extends — does not replace — §4's existing
`hypothesis`/`candidate` block-`covered` rule. A scope must satisfy
**both**: `confidence ∈ {source-backed, verified}` **and**
`intent_recovery ∈ {covered, partial}`, with `partial` requiring an open
Pending Capture entry in the consumer SSOT pointing at the missing pillar.
The §5 frontmatter format may add (when an owner has been sampled by the
harness):

```yaml
---
intent_recovery: covered | partial | gap
intent_recovery_evidence: "cold-agent-sim cycle-<N> commit-<SHA> pillar-<p> verdict-PASS"
intent_recovery_pillars: [design_intent, design_truth]
---
```

`intent_recovery_evidence` is required when `intent_recovery: covered` or
`partial`; it points to the row in
`assets/cold-agent-sim/cycle-<N>.md` Results table that justifies the
state. Promotion (gap → partial → covered) is a by-product of cold-agent-sim
cycles, not a separate activity; demotion fires automatically when a new
cycle records a failure for the slice.

---

## 2. Write-time annotation

When writing long-lived knowledge to SSOT, the agent determines default confidence by knowledge source:

| Knowledge source | Default confidence | Description |
|---|---|---|
| Direct derivation from code/config/schema/test | No annotation needed (equivalent to `verified`) | Code itself is evidence |
| Conclusion confirmed by user in conversation | `candidate` | Conversational confirmation provides initial evidence, still needs code-level cross-verification |
| Agent code-analysis inference | `candidate` | Has analytic basis but inference may be wrong |
| Agent inference, no direct evidence | `hypothesis` | Verbal agreement, guess, implicit coupling judgment |

Write rules:

- Default confidence may be adjusted upward based on actual evidence. E.g., if a conclusion confirmed by user in conversation is also verified by the agent against code, mark directly as `source-backed` rather than `candidate`.
- When marking `source-backed`, the `evidence` field must be provided simultaneously (see §5); otherwise use `candidate`.
- Default confidence may not be adjusted downward to bypass write-location restrictions.
- `hypothesis` must not be written to the authoritative body of architecture views/domains. It may exist as a gap annotation or STATUS.md open gap to mark "verification needed here".

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
- (v2.43) `intent_recovery: gap` blocks `covered` for the same scope, even when `confidence` is `verified`. To reach `converged`, every owner in the scope must have at least `intent_recovery: partial` with a Pending Capture for the missing pillar; truly user-irrelevant internal areas may carry `intent_recovery: not_applicable` with reason recorded (e.g. internal-only build script with no user-observable surface). Doctor `[INTENT-RECOVERY]` (14Y) gates this.

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
