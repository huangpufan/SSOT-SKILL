# Consumption Audit Reference (Trigger-side L4 Behavioural Probe)

This file owns SSOT **trigger / consumption-side effectiveness**: evaluate
whether SSOT is available, reached, read correctly, and used in real tasks.
Its L4 behavioural probe complements the static CONSUMPTION check in
[`doctor.md`](doctor.md); it supports evidence-based trigger improvements.

Positioning parallel to Doctor and orthogonal to the three event-source audits:

- **Doctor** verifies whether SSOT **content** is still trustworthy; **consumption audit** verifies whether SSOT **triggering / usage** is effective.
- It does not catch up `tracked_commit` / `tracked_session` / `tracked_skill_version`, and does not write new long-lived knowledge into SSOT.

---

## Table of contents

- [1. Role and boundary](#1-role-and-boundary)
- [2. Core rule: suggest by default, change only after authorization](#2-core-rule-suggest-by-default-change-only-after-authorization)
- [3. L4 probe: two layers](#3-l4-probe-two-layers)
- [4. Signal extraction and trigger health](#4-signal-extraction-and-trigger-health)
- [5. Failure attribution to optimization object](#5-failure-attribution-to-optimization-object)
- [6. Optimization protocol: suggestion report and authorized execution](#6-optimization-protocol-suggestion-report-and-authorized-execution)
- [7. Landing point: embed in Session self-check](#7-landing-point-embed-in-session-self-check)
- [8. Boundary with other flows](#8-boundary-with-other-flows)

## 1. Role and boundary

**What it does**:

- Probe SSOT trigger and consumption effectiveness in real conversations.
- Localize the broken link of "should trigger but didn't / triggered but not used".
- Produce **trigger improvement suggestions** covering the project-level trigger side (adapter, `SSOT/README.md` navigation) and skill-level trigger side (`SKILL.md` `description`, perception-flow wording, adapter templates).

**What it does not do**:

- `[MUST]` Do not extract long-lived knowledge from conversation and write it into SSOT -- that is the job of [`conversation-audit.md`](../../ssot-audit/references/conversation-audit.md).
- `[MUST]` Do not validate whether SSOT content matches code -- that is the job of [`doctor.md`](doctor.md).
- Do not advance any tracking-baseline field.

**Relationship with CONSUMPTION static check**: check 9 in
[`ssot-lint.sh`](../assets/scripts/ssot-lint.sh) and check item C in
[`doctor.md`](doctor.md) inspect startup routing and the README landing point.
They do not prove actual use. A missing startup route can coexist with observed
use through an explicit skill request, another harness entry, or supplied
context. Record that route separately: successful explicit use does not prove
automatic triggering, and a static-chain warning does not erase observed use.

## 2. Core rule: suggest by default, change only after authorization

`[MUST]` Diagnose before changing either project-level or skill-level routing:

```text
diagnose -> propose the repair -> check existing authorization -> change -> verify
```

- A diagnosis-only request produces findings and suggestions without edits.
- An explicit request to diagnose and fix supplies authorization for repairs
  within that scope. Honor still-applicable earlier authorization; do not ask
  again merely because diagnosis produced the concrete repair.
- If the repair reaches an unauthorized project, installed/global skill copy,
  or material contract change, prepare the concrete proposal and obtain only
  the missing authorization before writing there.
- Authorization permits an action; it is not evidence that the action works
  and is not a substitute for the applicable stop review. Review authority and
  impact classification belong to
  [`status-protocol.md` §§6-7](../../ssot-preflight/references/status-protocol.md#6-stop-review-gate).

Trigger changes can affect later tasks beyond the observed sample. Keep their
scope, evidence, and verification explicit rather than treating permission or
one successful session as proof of general effectiveness.

## 3. L4 probe: two layers

The probe is near-field and far-field, with different cost and sample quality; use them together.

### 3.1 Near-field probe (self-observation)

`[SHOULD]` Embedded in Session self-check, near zero cost. The agent reviews **the current conversation itself**:

- Was this task eligible under the current
  [`ssot-preflight` entry](../../ssot-preflight/SKILL.md)? Include substantive
  repository code, configuration, documentation, review, debugging, and planning;
  read-only work is not automatically exempt. Use that entry's skip conditions
  rather than inferring eligibility from whether a write tool ran.
- Was the relevant SSOT content available through a file read or supplied
  context before the decision? What can the visible conversation actually prove?
- Was my read surface right? (Did the required domain / contract get read, or did I read wrong, not enough, or waste context with a full read?)
- Did SSOT content actually influence my decision / output, or was reading equivalent to not reading?

Near-field review avoids transcript discovery, but remains self-observation.
Cite the visible read/context and decision evidence; unavailable earlier
context still limits the conclusion.

### 3.2 Far-field probe (transcript analysis)

`[MAY]` Run on demand or when the user names it, to provide statistical evidence and locate systemic break points.

- **Data source and location**: reuse the Transcript location table in [`conversation-audit.md`](../../ssot-audit/references/conversation-audit.md) (Cursor at `agent-transcripts/<uuid>/<uuid>.jsonl`, includes `subagents/`). When location fails, degrade and record without blocking, same as conversation-audit's existing discipline.
- **Stateless**: far-field scans the trigger signals of the most recent N transcripts each time in real time; no persistent counter is maintained, no STATUS field is added.

**Sample-bias hard rule** `[MUST]`:

- A session currently doing SSOT maintenance / audit **cannot** be counted as a trigger-health sample -- the agent is reading and writing SSOT at this point and statistics would be severely overestimated.
- Sample past **non-SSOT-task** repository work across the eligible task types;
  a coding-only sample cannot establish trigger health for reviews or planning.
- Separate ordinary automatic-use samples from explicit SSOT requests and
  controlled probes. The latter test an explicit route, not automatic discovery.
- Subagent (`subagents/`) transcript trigger behaviour is governed by parent-agent instructions and is not independently counted into trigger health.

## 4. Signal extraction and trigger health

Signals are split into two layers, aligned with protocol L1 / L4 layering.

### 4.1 Observable signals across harnesses

Normalize the harness's actual records before interpreting them. `Read` with
`input.path`, shell `cat`/`sed`/`rg` through `exec_command` or equivalent tools,
resource reads, and explicitly supplied SSOT context can all expose content.
Resolve working directories and inspect returned content or a successful read
event; an attempted command, file listing, `Glob`, filename mention, or failed
read alone does not prove content was available. A narrow search proves only
the returned excerpt, not a complete owner read.

For each sample record task eligibility, harness and installed-skill
availability, actual entry route, transcript/context completeness, and the
observed read and decision evidence. Use `unknown` for an unproved dimension.
In particular, do not assume a resumed session starts with an empty context.

### 4.2 L4 semantic signals (need agent judgment)

- Did the material influence a task-relevant decision, constraint, route, or
  verification? A citation alone does not prove use; explicit citation is not
  required when the decision's use of the content is otherwise observable.
- Was the read surface sufficient and proportionate to this task? Distinguish
  a missing owner read from an adequate excerpt or already supplied context.

Classify eligible samples from the combined evidence:

| Observation | Required evidence |
|---|---|
| `observed-used` | Sufficient relevant content was available before the decision and visibly informed it, with no observed required-consumption miss. |
| `observed-inadequate` | A specific required owner/constraint was demonstrably missed or disregarded; state the consequence and any successful reading/use elsewhere. |
| `observed-skipped` | The decision window and supplied context are sufficiently visible to establish that no SSOT body or excerpt was available before the decision. |
| `unobservable` | Logs, supplied context, read results, or decision evidence are insufficient to decide; name the missing evidence. |

Use one primary observation per sample for the counts. A proved complete
absence of SSOT content is `observed-skipped`; otherwise, a proved required
consumption miss is `observed-inadequate`. Successful use of another rule is
supporting detail, not a second counted success. If the required miss is proved
but the presence of other SSOT content is unknown, use `observed-inadequate`
and state that limit; do not infer complete skipping.
Use `unobservable` when the evidence cannot establish any of the other three
results; uncertainty about other unseen behaviour does not erase a confirmed
miss within the visible decision window.

Ineligible tasks are recorded as excluded, not as successful or failed triggers.
Missing tool calls in a partial transcript establish `unobservable`, not
`observed-skipped`. A confirmed unavailable installation is an availability
defect; do not attribute it to description wording even if reading was skipped.

### 4.3 Trigger health

For each reported cohort, give its eligible count, availability and visibility
limits, and counts for all four observations. Report exclusions and their
reasons. Any rate states its numerator and denominator; automatic trigger rates
use eligible, available, observable automatic-route samples. Report unavailable
and unobservable samples separately rather than silently dropping them or
counting them as failures. A small observable remainder cannot certify the
unobserved population.

Based on multiple comparable samples, give a tier with its exact scope:

- `healthy`: in the observed eligible cohort, SSOT is steadily triggered and used.
- `partial`: triggering is unstable, or triggered but often read wrong / not used.
- `broken`: substantive tasks generally skip SSOT.

Tiers are qualitative summaries of the reported counts and consequences;
state the rationale rather than presenting an unstated numerical threshold.

`[MUST]` Do not infer a health tier from one session or extend it to untested task
types/harnesses. If samples are insufficient or availability/visibility gaps
prevent the requested conclusion, report `unknown` with the limiting evidence.
Individual defects can still be reported and repaired without a health tier.

## 5. Failure attribution to optimization object

Before changing trigger wording, check whether the skill was installed,
enabled, visible to this harness/session, and at the intended version; whether
the startup route applied; and whether the record covers the relevant context
and decision. Investigate missing availability or visibility first. Then map
the evidenced break point to the responsible owner:

| Broken link | Symptom | Change object | Tier |
|---|---|---|---|
| Skill unavailable | Bundle absent, disabled, stale, or not exposed to this session | Installation / harness configuration; inspect the effective skill inventory | environment |
| Behaviour not observable | Partial transcript, hidden supplied context, or missing read results | Recover available evidence or report the limit; no trigger rewrite follows from absence alone | evidence |
| Available but not selected | Eligible task, sufficient observation, correct installation, and no applicable selection | Investigate description/task matching or harness selection; a description change remains a hypothesis until tested | skill / harness level |
| Selected but perception skipped | Skill reached, required content absent before the decision | Current preflight read-routing instructions or execution failure, as supported by evidence | skill / execution level |
| Startup route missing | This harness is expected to use the startup file, but its applicable route is absent | `AGENTS.md` / `CLAUDE.md` / `.cursor/rules` (see [`adapter-strategy.md`](adapter-strategy.md)); preserve any other observed route | project level |
| Navigation cannot find the right surface | Read SSOT but did not find the task-related domain | `SSOT/README.md` navigation | project level |
| Content did not support the decision | Required content was unclear, stale, conflicting, or visibly disregarded | Distinguish content quality from execution or an overriding instruction; route evidenced content defects to Doctor / audit | content / execution level |

This is guidance, not exhaustive; the agent attributes by actual evidence; one symptom may hit multiple links.

## 6. Optimization protocol: suggestion report and authorized execution

### 6.1 Suggestion report structure

Each trigger improvement suggestion contains:

- **Symptom**: evidence -- transcript `<uuid>` + specific behaviour, or current-session near-field observation.
- **Attribution**: which broken link in §5 it hits; distinguish the observed
  symptom from any still-untested causal hypothesis.
- **Change object + tier**: project level or skill level.
- **Specific change**: the suggested minimal change.
- **Risk and reversibility**: especially for skill-level, mark impact scope.
- **Authorization**: diagnosis-only, already authorized within a named scope,
  or awaiting a specific additional decision; cite the applicable directive.
- **Verification**: eligible and ineligible tasks, missed and false triggers,
  and reading cost to inspect after the change.

### 6.2 Authorization and execution

Apply §2's authorization boundary. A diagnosis-only request stops at the
report; an authorized repair proceeds without a duplicate permission step:

- **Project level** (adapter / `SSOT/README.md`): change per [`adapter-strategy.md`](adapter-strategy.md) and existing write discipline.
- **Skill level**: see additional constraints in §6.3.

### 6.3 Additional constraints for changing the skill body

Classify the actual semantic change using
[`status-protocol.md` §7](../../ssot-preflight/references/status-protocol.md#7-tracking-baseline-and-protocol-version),
not the filename or the fact that a description/template was touched:

- Use §6's applicable reviewer policy. Editorial changes do not become
  high-impact merely by location; changes that meet §7's high-impact criteria
  still require independent review.
- If it changes fields, state, gates, Doctor behaviour or other protocol obligations, must bump `metadata.protocol_version` and append [`protocol-upgrades.md`](../../ssot-audit/references/protocol-upgrades.md).
- Verify a local rule change with matching trigger and non-trigger scenarios.
  Broad routing changes need a baseline/candidate behavioural comparison with
  representative tasks and counterexamples. Report observed misses, false
  triggers, and reading cost; proposed checks are not completed evidence.
- Prefer the authorized source repository for durable changes. If only an
  installed copy is authorized, explain that reinstall may replace the edit;
  do not silently extend write scope to its upstream repository.

## 7. Landing point: embed in Session self-check

`[SHOULD]` Main trigger point embedded in the Session self-check of [`conversation-audit.md`](../../ssot-audit/references/conversation-audit.md):

- **Resident lightweight**: each Session self-check incidentally runs the §3.1 near-field probe, read-only, record-only, no heavy work triggered.
- **Upgrade on demand**: when the near-field probe hints insufficient triggering, or the user names "probe trigger effectiveness", escalate to §3.2 far-field full consumption audit and produce suggestions.

No new mandatory independent command or far-field analysis per session is
introduced. Keep routine self-observation proportionate to the current task.

## 8. Boundary with other flows

- **vs conversation-audit**: [`conversation-audit.md`](../../ssot-audit/references/conversation-audit.md) extracts knowledge from transcripts and **writes into** SSOT; this file evaluates **how SSOT is used**, reverse-optimizing the trigger side. Both share transcript location, opposite direction.
- **vs Doctor**: [`doctor.md`](doctor.md) verifies **content** trustworthiness; this file verifies **trigger / usage** effectiveness. If "read the right surface but not used" attributes to a content issue, redirect to Doctor.
- **vs CONSUMPTION static check**: check 9 in [`ssot-lint.sh`](../assets/scripts/ssot-lint.sh) inspects the configured startup chain; this file checks observed behaviour across actual routes. Neither result substitutes for the other.
