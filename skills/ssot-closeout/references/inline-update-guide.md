# Inline Update Execution Reference

This file serves inline updates: when the agent decides to update SSOT, read this file on demand for execution details.

**When to read**: not at session start. Read it when `$ssot-preflight` or `$ssot-closeout` identifies that SSOT needs updating and is about to execute writes.

**Relationship to other reference files**:

| File | Scenario | When to read |
|---|---|---|
| This file | Inline update (immediate write during daily development) | When the agent decides to update SSOT |
| `commit-audit.md` | Proactive catch-up (commit-level batch review) | When user initiates catch-up |
| `conversation-audit.md` | Session self-check + proactive catch-up | At session end / when user initiates catch-up |

---

## Table of contents

- [1. Inline update flow](#1-inline-update-flow)
- [2. Write discipline](#2-write-discipline)
- [3. What not to write](#3-what-not-to-write)

## 1. Inline update flow

1. Re-read the target SSOT file and `SSOT/STATUS.md`.
2. Use [`update-routing.md`](update-routing.md) to judge impact, area mapping and whether cascade checks are needed.
3. If this run touches README/docs/ADR/runbook/PRD, product planning or user-supplied material, follow [`source-material.md`](../../ssot-preflight/references/source-material.md) for source-material lifecycle, classification, absorption, thin-documentation check and conflict adjudication; product promises, capability, journey, roadmap and product acceptance enter `product/` first.
4. Apply the write discipline below to update the single authoritative location; do not maintain the same fact in multiple areas, and do not hide action guidance inside a ledger.
5. Update `STATUS.md` area state, open gaps, open adjudications, source-material absorption matrix and stop-review records.

When the update leaves a fallback, compat shim, temporary workaround,
later-remove path, TODO/FIXME/HACK/WORKAROUND, or temporary waiver in current
scope, register it before final response. The registration must name owner,
reason, closure condition, revisit signal, and verification guard. If the only
current note is `待立 tech-debt`, `TODO debt`, `opportunistic follow-up`, or
`Pending action`, create or update the real owner entry instead of leaving the
note in STATUS or an index.

Inline updates are for immediate writes during daily development; commit-audit and conversation-audit use the same owner rules but have different batch inputs and waterline-advance flows.

---

## 2. Write discipline

### 2.0 Agent-actionability check

Before writing or rewriting a user-facing SSOT body file, check whether the edit helps the next agent act. The first screen of an owner or high-risk entry should answer, compactly:

- When should I read this?
- What current truth does this owner hold?
- Where should I inspect first?
- What should I not do?
- What minimal verification or evidence closes the loop?

If the answer needs full task history, move the history to an authorized evidence owner and write only the stable conclusion and pointer. If the same weakness would affect future projects, update the SSOT Skill protocol/templates/lint first when this repository owns them, then update the local SSOT using that improved rule.

### 2.1 Documentation language lock

Before updating any SSOT Markdown, read `documentation_language` and `documentation_language_evidence` from `SSOT/STATUS.md`:

- Field exists: new or modified SSOT body, headings, table labels and template structures must use the locked language.
- Field missing: detect the natural language only from root README, `docs/`, ADRs, runbooks, subsystem READMEs and user-provided external material; ignore code blocks, commands, paths, API names, enum values, code identifiers and verbatim quotations.
- Mixed language, insufficient evidence or no detectable documents: ask the user to choose the SSOT documentation language first; do not fall back to the current conversation language.
- Subsequent source-material language changes do not auto-switch `documentation_language`; if a switch is truly required, record an open adjudication and log the language-change review in the stop-review gate.

Code identifiers, paths, commands, API names, enum values and verbatim quotations stay in the original.

### 2.2 Source tagging

Inline updates written into SSOT should tag their source for later audit and verification:

| Source | Meaning | Tagging method |
|---|---|---|
| Direct derivation from code change | The commit itself is the evidence | No extra tag needed (default) |
| Deterministic conclusion from conversation | Long-lived SSOT knowledge produced by conversation | Inline annotation `(source: conversation, <date or session id>)` |
| Source-material absorption | Long-lived knowledge from README/docs/ADR/runbook or user-provided material | Record original path/URL/session id and classification (`absorb` / `link-only` / `stale/conflict` / `obsolete`) |
| Agent inference (no direct code evidence) | Verbal agreement, debugging inference, implicit coupling | Use the confidence frontmatter (see the state machine and write-annotation table in [`knowledge-integrity.md`](../../ssot-preflight/references/knowledge-integrity.md)) |

### 2.3 Cross-validation

When a conversation conclusion concerns code implementation, the agent should cross-validate against code:

- Validation passes -> source may be tagged `conversation` + `code-analysis`, raising confidence
- Conversation conclusion does not match code:
  - If the conclusion describes implemented facts -> code/config/schema/test wins; correct the thin documentation, or mark `stale/conflict` in the SSOT source-material absorption and write the adjudicated authoritative location
  - If the conclusion describes product intent, product promises, capability, journey, roadmap or product acceptance -> write into the `product/` owner; implementation gaps then link to architecture/testing/tech-debt
  - If the conclusion describes technical design intent, constraints or not-yet-landed decisions -> do not automatically declare code correct; update current/target/gap in architecture views/domains, mark `implementation_state: diverged` or `partial` in the related decision when needed, and write into `open adjudications` in `STATUS.md`

When source material conflicts with code or SSOT, follow the conflict-adjudication rules in [`source-material.md`](../../ssot-preflight/references/source-material.md). Do not overwrite SSOT with docs content, and do not stop at marking `stale/conflict`.

### 2.4 Re-read before write

Before updating any SSOT file, read its current content first to ensure:

- Not overwriting another person's update (especially STATUS.md)
- Not violating `documentation_language` in `STATUS.md`
- Not duplicating existing content
- New content stays consistent with existing content
- Not contradicting or negation-flipping an existing active entry: when a new conclusion reverses an old one, run a conflict / negation scan -- preserve both pieces of evidence or register an open adjudication; do not silently overwrite

### 2.5 STATUS.md sync

After updating area content, sync STATUS.md:

- Before advancing `tracked_commit` to the current HEAD (if this change is committed), the updater may self-review per the default self-review rule in status-protocol.md §7. Exceptions that require an independent reviewer: (1) bootstrap overall `passed`, (2) `documentation_language` change, (3) protocol upgrade `semantic_impact=high`, (4) first declaration of `coverage_result=converged`.
- Before advancing `tracked_skill_version` to the current `ssot-preflight` `metadata.protocol_version`, complete the protocol-upgrade review first. Start at the audit router `protocol-upgrades.md`; it points to `current-upgrade.md` or the archive range needed for the project waterline. Upgrades with `semantic_impact=none`, `low`, or `medium` may self-review; `medium` still needs a standalone checklist in the current/archive ledger; `high` requires an independent reviewer returning `no-more-required-changes`.
- Update affected area state (e.g. `gap` -> `covered`, `covered` -> `stale`); `covered` is a stop conclusion but area-level `covered` defaults to self-review per §7, `coverage_result=converged` is one of the 4 exceptions.
- Update the source-material absorption matrix: source material read or changed in this run must record classification, authoritative location, absorption state, conflict/adjudication and last check
- Update the open-gaps list
- Add or update adjudications discovered mid-run; remind the user once but do not block the current task by default

Open gaps must have an owner or next action. A gap row that says "create debt
later" is not routed; either create the debt entry now or mark the gap with the
explicit owner, trigger, and deferred reason.

Keep STATUS rows register-sized. Write only the changed state, owner, date,
result, gap/adjudication id, and evidence pointer; do not paste protocol
checklists, command output, full review reasoning, or proof-of-work prose into
STATUS. If the explanation needs a paragraph, write the paragraph in the
authoritative owner and leave STATUS as a pointer.

Re-read the latest version of STATUS.md before updating. If this run fills in or changes `documentation_language`, sync `documentation_language_evidence`; language changes must have adjudication / review evidence.

If the inline-check conclusion is `no-op` / "no update needed", record the no-op basis; if the scope falls under one of the 4 exceptions, proceed with independent review per status-protocol.md §7.

### 2.6 Adjudication registration

For situations that need adjudication but should not interrupt the current task, write into `open adjudications` in `STATUS.md`:

| Scenario | Action |
|---|---|
| Current implementation conflicts with `architecture/` or `decisions/` | Update architecture current/target/gap, mark the related decision `implementation_state: diverged` or record the constraint conflict, add/update the adjudication |
| Two design intents conflict with each other | Keep links to both sides, add/update the adjudication |
| Fact sources cannot be merged and will affect future implementation | Mark the related area `conflict`, add/update the adjudication |

New entries use `ADJ-YYYYMMDD-NN`, status defaults to `pending`. Remind once during the run:

```text
Found adjudication needed ADJ-YYYYMMDD-NN: <issue>. Not blocking the current task, recorded in STATUS.md.
```

If the user opts to defer, status becomes `deferred` and `revisit_condition` is recorded; if unspecified, use "re-adjudicate at next session".

### 2.7 Source-material absorption

When README/docs/ADR/runbook/PRD, product planning or user-supplied material changes, classify and process per [`source-material.md`](../../ssot-preflight/references/source-material.md). Product facts enter `product/`; technical-implementation / design facts enter architecture or the corresponding area. After updates, sync the source-material absorption matrix in `STATUS.md` with classification, lifecycle, authoritative location, downgrade fields, absorption state, conflict/adjudication and last check.

Working, historical, public-thin, and external source files outside `SSOT/`
must have either an in-file lifecycle header, a file/pattern inventory row, or
an audited exclusion. If they contain strong current-fact words but are not
authoritative, include `absorbed_to`, `do_not_use_for`, and `review_on` so a
future agent knows what not to rely on.

When research/PoC output is produced, closeout must choose exactly one of four
routes:

- create `SSOT/04-records/research/NNNN-<slug>.md` with the reproducible
  evidence packet and reusable claim rows;
- update an existing research record when this batch extends or invalidates the
  same packet;
- promote durable claim rows into the relevant product, architecture, decision,
  testing, bug, gotcha, or debt owner, linking back to the packet as evidence;
- discard the output with a concrete reason, such as non-reproducible,
  superseded, or no reusable claim.

Research records are not authority mirrors. Raw docs, external artifacts, and
working PoC files still follow source-material lifecycle downgrade rules.

---

### 2.8 Promote and demote check

During inline updates, when SSOT content with `confidence` tags is encountered, if relevant evidence is conveniently at hand (because of the current code task), promote or demote inline:

- The current code change confirms a `candidate` claim -> promote to `source-backed`, update the evidence pointer.
- The current code change refutes a claim -> demote or delete, record the demotion reason.
- The touched file/function overlaps with a `hypothesis` evidence pointer -> check whether the hypothesis still holds.

Promote and demote are not extra tasks -- they are natural extensions of the "re-read target file" step in inline updates. Full rules in [`knowledge-integrity.md`](../../ssot-preflight/references/knowledge-integrity.md).

---

## 3. What not to write

No SSOT update is needed in the following cases:

- Pure formatting / comment / typo fixes (unless they modified an architecture domain, an entry file or an authoritative-source path pointer)
- Implementation detail changes within a single file (not affecting architecture boundaries, state ownership, API contracts, external behaviour, resource lifecycle, locks/transactions/retry/rollback, failure semantics or high-risk algorithm flow)
- Exploratory discussion and rejected options (unless the rejection itself constitutes a decision)
- Intermediate speculation and temporary hypotheses
- Pure operational instructions ("change this file for me")
- Information directly derivable from code/scripts (e.g. full dependency tree, route list -- use pointers instead)
