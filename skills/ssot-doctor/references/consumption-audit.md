# Consumption Audit Reference (Trigger-side L4 Behavioural Probe)

This file is the semantic owner of SSOT **trigger / consumption-side effectiveness**, fulfilling the **L4 behavioural probe** that `ssot-preflight/SKILL.md` and the CONSUMPTION check in [`doctor.md`](doctor.md) promised but never defined: evaluate whether SSOT is triggered, read correctly and used in real conversations, and based on that optimize the trigger side -- the side that "makes SSOT more likely to be used by the agent".

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
- Do not advance any tracked waterline.

**Relationship with CONSUMPTION static check**: check 9 in [`ssot-lint.sh`](../assets/scripts/ssot-lint.sh) and check item C in [`doctor.md`](doctor.md) are the **L1 static consumption chain** (does the adapter write `SSOT/`, does `SSOT/README.md` exist); this file is the **L4 behavioural probe** (was it actually used in real conversation). L1 is a necessary precondition for L4: a broken chain guarantees behaviour fails; an intact chain does not guarantee behaviour is effective.

## 2. Core rule: suggest by default, change only after authorization

`[MUST]` All optimization actions of consumption audit follow the same rule, whether project-level or skill-level:

```text
diagnose -> suggest -> user authorize -> change
```

- The diagnosis phase is **read-only, record-only, change nothing**.
- After the suggestion list is produced, **do not execute by default**, wait for the user to authorize item by item or as a whole.
- User authorization is equivalent to a manual stop-review reviewer: putting a human in the loop avoids the risk of "the updater self-certifying with a biased sample and then unilaterally changing the global trigger contract" (echoing the independent stop-review gate in `ssot-preflight/SKILL.md` §1.3).

Rationale: trigger-side configuration (especially `description` and the perception flow) is a **trigger contract**; if a misjudgement from a biased sample lands directly, it pollutes the trigger behaviour of all subsequent conversations and is hard to roll back. Suggest-by-default decouples "judgement" from "taking effect", so an error does not land directly.

## 3. L4 probe: two layers

The probe is near-field and far-field, with different cost and sample quality; use them together.

### 3.1 Near-field probe (self-observation)

`[SHOULD]` Embedded in Session self-check, near zero cost. The agent reviews **the current conversation itself**:

- Was this a substantive code task? (Read-only Q&A / chitchat / pure mechanical changes do not count, aligned with the skip conditions in `ssot-preflight/SKILL.md` §2.2.)
- In the perception phase did I read `SSOT/`, or did I go straight to source code / code editing and skip perception?
- Was my read surface right? (Did the required domain / contract get read, or did I read wrong, not enough, or waste context with a full read?)
- Did SSOT content actually influence my decision / output, or was reading equivalent to not reading?

Advantage of the near-field probe: the agent has first-hand judgement of its own just-finished behaviour, more accurate and cheaper than parsing a transcript afterwards.

### 3.2 Far-field probe (transcript analysis)

`[MAY]` Run on demand or when the user names it, to provide statistical evidence and locate systemic break points.

- **Data source and location**: reuse the Transcript location table in [`conversation-audit.md`](../../ssot-audit/references/conversation-audit.md) (Cursor at `agent-transcripts/<uuid>/<uuid>.jsonl`, includes `subagents/`). When location fails, degrade and record without blocking, same as conversation-audit's existing discipline.
- **Stateless**: far-field scans the trigger signals of the most recent N transcripts each time in real time; no persistent counter is maintained, no STATUS field is added.

**Sample-bias hard rule** `[MUST]`:

- A session currently doing SSOT maintenance / audit **cannot** be counted as a trigger-health sample -- the agent is reading and writing SSOT at this point and statistics would be severely overestimated.
- The most valuable samples are past **non-SSOT-task** ordinary coding conversations: that is the real test field of "SSOT should have been used".
- Subagent (`subagents/`) transcript trigger behaviour is governed by parent-agent instructions and is not independently counted into trigger health.

## 4. Signal extraction and trigger health

Signals are split into two layers, aligned with protocol L1 / L4 layering.

### 4.1 L1 mechanical signals (extractable from transcript structure)

From the transcript's `tool_use.name` and `input.path` it is possible to mechanically judge:

- Whether it is a substantive code task (read/write tool calls on source code).
- Whether there is any read of the `SSOT/` path (`Read` / `Glob` whose path hits `SSOT/`).
- Whether code was modified directly without reading SSOT (a strong signal for skipping perception).

### 4.2 L4 semantic signals (need agent judgment)

- After triggering, did SSOT content actually influence the output (decisions cite SSOT conclusions vs reading then ignoring).
- Does the read surface match the task (read right / read wrong / read insufficient / wasteful full read).

### 4.3 Trigger health

Based on a sample set (not a single run), give a tier:

- `healthy`: in substantive tasks, SSOT is steadily triggered and used.
- `partial`: triggering is unstable, or triggered but often read wrong / not used.
- `broken`: substantive tasks generally skip SSOT.

`[MUST]` Health-tier conclusions are based on multi-sample statistics; do not conclude from a single session; if samples are insufficient, record `unknown` with reason.

## 5. Failure attribution to optimization object

When the probe finds "should trigger but didn't / not used", locate the break point and map to the change object and tier:

| Broken link | Symptom | Change object | Tier |
|---|---|---|---|
| Skill not loaded | Harness did not include the SSOT Skill bundle / `ssot-preflight` for this task | `SKILL.md`'s `description` does not match task signals | skill level |
| Loaded but did not read SSOT | Skill triggered but perception skipped | `SKILL.md` §2 perception-flow gate / wording | skill level |
| No adapter / adapter does not route | Project lacks AGENTS.md etc., or it does not mention `SSOT/` | `AGENTS.md` / `CLAUDE.md` / `.cursor/rules` (see [`adapter-strategy.md`](adapter-strategy.md)) | project level |
| Navigation cannot find the right surface | Read SSOT but did not find the task-related domain | `SSOT/README.md` navigation | project level |
| Read the right surface but did not use it | Content read but ignored | Usually a **content quality** issue, redirect to Doctor / audit, not changed on the trigger side | not applicable |

This is guidance, not exhaustive; the agent attributes by actual evidence; one symptom may hit multiple links.

## 6. Optimization protocol: suggestion report and authorized execution

### 6.1 Suggestion report structure

Each trigger improvement suggestion contains:

- **Symptom**: evidence -- transcript `<uuid>` + specific behaviour, or current-session near-field observation.
- **Attribution**: which broken link in §5 it hits.
- **Change object + tier**: project level or skill level.
- **Specific change**: the suggested minimal change.
- **Risk and reversibility**: especially for skill-level, mark impact scope.
- **Status**: defaults to `suggested`; becomes `accepted` after authorization.

### 6.2 Authorization and execution

`[MUST]` Do not change any file by default. After user authorization:

- **Project level** (adapter / `SSOT/README.md`): change per [`adapter-strategy.md`](adapter-strategy.md) and existing write discipline.
- **Skill level**: see additional constraints in §6.3.

### 6.3 Additional constraints for changing the skill body

`[MUST]` Changing `SKILL.md` `description`, perception flow or adapter template is a high-impact change:

- Requires independent stop review (updater self-certification not allowed), aligned with `ssot-preflight/SKILL.md` §1.3.
- If it changes fields, state, gates, Doctor behaviour or other protocol obligations, must bump `metadata.protocol_version` and append [`protocol-upgrades.md`](../../ssot-audit/references/protocol-upgrades.md).
- `[SHOULD]` Before changing, remind the user: if the current operation is on an **installed skill copy** (not the source repo), the change does not flow back to the source repo and will be lost on `install.sh` reinstall. This protocol does not introduce an "author mode" auto-split -- the user knowingly accepts this at authorization time.

## 7. Landing point: embed in Session self-check

`[SHOULD]` Main trigger point embedded in the Session self-check of [`conversation-audit.md`](../../ssot-audit/references/conversation-audit.md):

- **Resident lightweight**: each Session self-check incidentally runs the §3.1 near-field probe, read-only, record-only, no heavy work triggered.
- **Upgrade on demand**: when the near-field probe hints insufficient triggering, or the user names "probe trigger effectiveness", escalate to §3.2 far-field full consumption audit and produce suggestions.

No new mandatory independent command is introduced, no forced far-field analysis per session (aligned with the context budget in `ssot-preflight/SKILL.md` §2.5 and the restrained tradition of "not forcing Doctor per session").

## 8. Boundary with other flows

- **vs conversation-audit**: [`conversation-audit.md`](../../ssot-audit/references/conversation-audit.md) extracts knowledge from transcripts and **writes into** SSOT; this file evaluates **how SSOT is used**, reverse-optimizing the trigger side. Both share transcript location, opposite direction.
- **vs Doctor**: [`doctor.md`](doctor.md) verifies **content** trustworthiness; this file verifies **trigger / usage** effectiveness. If "read the right surface but not used" attributes to a content issue, redirect to Doctor.
- **vs CONSUMPTION static check**: check 9 in [`ssot-lint.sh`](../assets/scripts/ssot-lint.sh) is the L1 static chain; this file is the L4 behavioural probe. L1 passing is a necessary precondition for L4 effectiveness.
