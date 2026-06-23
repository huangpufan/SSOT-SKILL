# Conversation-level Audit Reference

This file serves two flows of `$ssot-audit`:

- **Session self-check**: at each session's end, the agent uses this file's mapping tables to review the current conversation and confirm no inline updates were missed.
- **Proactive catch-up (Session audit part)**: when the user initiates catch-up, the agent uses this file's full flow to audit old transcripts.

Conversation audit and commit audit (`references/commit-audit.md`) are parallel protocols: commit audit extracts area-level changes from `git diff`, conversation audit extracts long-lived SSOT knowledge from the transcript. Both share `$ssot-closeout`'s write discipline and area-mapping logic.

---

## Table of contents

- [Use cases](#use-cases)
- [Full execution flow (used in proactive catch-up)](#full-execution-flow-used-in-proactive-catch-up)
- [Transcript location](#transcript-location)
- [Transcript reading strategy](#transcript-reading-strategy)
- [Transcript-to-area mapping](#transcript-to-area-mapping)
- [Source tagging](#source-tagging)
- [Size adaptation (applies to proactive catch-up)](#size-adaptation-applies-to-proactive-catch-up)
- [Coordination with commit audit](#coordination-with-commit-audit)
- [Relationship to Session self-check](#relationship-to-session-self-check)

## Use cases

| Scenario | Input | Which part of this file to use |
|---|---|---|
| Session self-check | Current session's conversation content | Transcript-to-area mapping table + attention signals |
| Proactive catch-up | Old transcript files | Full execution flow |

---

## Full execution flow (used in proactive catch-up)

```text
1. Locate the original transcript (see "Transcript location" below)
2. Read tracked_session, documentation_language and documentation_language_evidence from STATUS.md
3. Filter new transcripts after tracked_session
4. Read the transcript and identify long-lived SSOT knowledge (see "Transcript-to-area mapping" below)
5. Update affected areas per `$ssot-closeout` write routing
   -> New/modified SSOT body, headings and table labels use documentation_language
   -> Source tagged as conversation (with session id or timestamp)
   -> User-provided external material is classified per [`source-material.md`](../../ssot-preflight/references/source-material.md), the source pointer is retained, and the `STATUS.md` source-material absorption is synced
   -> Conclusions concerning code are cross-validated against code
6. Request an independent reviewer to audit this transcript scope, the write results and any `no-op` / "no update needed" conclusion
   -> `no-more-required-changes`: continue
   -> `needs-fix`: apply remaining changes, then re-review
7. Update STATUS.md:
   - Advance tracked_session to the most recent audited session
   - Update affected area states
   - Record stop-review gate evidence
```

> **Session self-check does not follow this flow** -- session self-check audits the current conversation directly, without locating transcript files or advancing tracked_session. But when the self-check concludes `no-op` / "no update needed", an independent reviewer must still check the current session scope.

---

## Transcript location

Different harnesses have different transcript locations and formats. Search in this priority order:

| Harness | Typical location | Format | Notes |
|---|---|---|---|
| Cursor | Project-level `agent-transcripts/*.jsonl` or IDE-managed transcript directory | JSONL (one message per line) | Contains role, content, tool_use fields etc. |
| Claude Code | Claude-managed JSONL transcript | JSONL | Accessed via hook stdin or session directory |
| Codex | Session log directory | Varies | -- |
| Other | Convention varies | -- | Agent determines per harness docs |

**On location failure**: if the agent cannot find a transcript file (harness keeps no record, no permission, unknown path), note the reason in STATUS.md and do not block other work. Conversation audit is "do it when material is available, skip when it is not" -- unlike commit audit, which can always `git log`.

**Special case for the current session**: the agent can audit the current conversation directly without locating a transcript file. This is the most common scenario -- at task end, review whether the current conversation produced long-lived SSOT knowledge worth recording.

---

## Transcript reading strategy

### Extraction target

Identify **long-lived SSOT knowledge** from the transcript -- information that falls within the architecture trunk or satellite areas and has long-lived value for future agents.

Extract only **deterministic conclusions**, not:

- Exploratory discussion ("Let's try X?" "First see if Y works")
- Rejected options (unless the rejection itself constitutes a decision)
- Intermediate speculation and temporary hypotheses
- Pure operational instructions ("change this file for me")

### Filter noise

Most of a transcript is operational (file reads/writes, tool calls, intermediate output). The following usually contains no long-lived SSOT knowledge and can be skipped quickly:

- Pure file-read operations and their output
- Repeated tool calls and intermediate state
- Intermediate steps of code generation (unless the why is discussed)
- Test command output, pass/fail summaries, durations, and "I ran X" statements when they only prove the current task
- Formatting, layout and other non-semantic operations

### Attention signals

The following conversation patterns often contain long-lived SSOT knowledge:

- User or agent explicitly says "we decided...", "chose X because..."
- Root-cause analysis discovered during debugging
- "Note this cannot be...", "the trap here is..."
- "This is a temporary fix, later we must..."
- "Current priority...", "this is not the current goal...", "success criterion is..."
- Constraint confirmation or clarification
- Confirmation of design rationale, design intent, non-goals, rejected approaches or do-not-revive concepts
- New term definitions or corrections to existing term meanings
- Discussion of system boundaries, design units, runtime flows, state ownership
- Strategy discussion of deployment, configuration, security
- Discussion of architecture diagrams, flow diagrams, Current/Target design diagrams, lifecycle/failure-recovery/trust-boundary diagrams
- Discussion that changes stable test policy: strategy, selection matrix, quality gates, fixtures, current baseline, known gaps, or defensive-test mapping
- User explicitly provides external material, specifications, design docs or historical documents and asks to use them as project background

---

## Transcript-to-area mapping

Transcript-to-area mapping has the "Conversation-signal-to-area mapping" in [`update-routing.md`](../../ssot-closeout/references/update-routing.md) as semantic owner. Conversation audit only extracts long-lived SSOT knowledge from the transcript and feeds it into that mapping.

Test results in the transcript are evidence, not testing facts. Do not promote "ran X and it passed/failed" into `testing/` unless the conversation also establishes a durable testing change: strategy, selection matrix, gate, fixture contract, current baseline, known gap, or defensive-test source. Otherwise keep the result as validation evidence for the current batch, commit, release, or bug record.

When the user explicitly provides external material, specifications, PRDs, design docs or historical documents, run source-material classification, absorption, thin-documentation check and conflict adjudication per [`source-material.md`](../../ssot-preflight/references/source-material.md).

---

## Source tagging

Content written into SSOT by conversation audit should tag its source as `conversation`. If the user explicitly provided external material, also record the material id (path, URL, filename or session position), source-material classification and `STATUS.md` source-material absorption state; classification semantics use [`source-material.md`](../../ssot-preflight/references/source-material.md). Tagging method is not mandated; it may be:

- Inline annotation: `(source: conversation, 2026-05-24 session)`
- Source field in entry metadata
- Footnote reference

When a conversation conclusion concerns code implementation, the agent should cross-validate against code. If validation passes, the source may be tagged `conversation` + `code-analysis`, raising confidence. If the conversation conclusion does not match code, use `$ssot-preflight`'s "implemented facts vs product/technical intent" rule and the conflict-adjudication rules in [`source-material.md`](../../ssot-preflight/references/source-material.md) to distinguish authority: when describing implemented facts, code/config/schema/test wins; when describing product intent, product promises, capability, journey, roadmap or product acceptance, the `product/` area owns the conclusion and the implementation gap is linked back to architecture/testing/tech-debt; when describing technical design intent, constraints or not-yet-landed decisions, do not auto-declare code correct -- update current/target/gap in architecture views/domains, mark `implementation_state: diverged` or record the constraint conflict if needed, and write into `open adjudications` in `STATUS.md`. `stale/conflict` cannot be marked and then skipped.

Before writing, obey the documentation language lock: if `STATUS.md` lacks `documentation_language`, detect only from root README, `docs/`, ADRs, runbooks, subsystem READMEs and user-provided external material; on mixed language, insufficient evidence or no detectable documents, ask the user first. Do not fall back to the current conversation language. Verbatim quotations, code identifiers, paths, commands, API names and enum values stay in the original.

---

## Size adaptation (applies to proactive catch-up)

| Situation | Strategy |
|---|---|
| Few (1-3) unaudited sessions | Read transcripts one by one and extract long-lived SSOT knowledge |
| Many unaudited sessions | Prioritize recent sessions; older sessions may be deprioritized or skipped -- conversation knowledge usually ages worse than commit changes |

**Recency judgement**: conversation knowledge may already be reflected or overturned by later commits. The agent should cross-validate conversation conclusions against the current code state to avoid writing stale information.

---

## Coordination with commit audit

In proactive catch-up, conversation audit and commit audit can run independently or together:

- **Independent execution**: each advances its own waterline (`tracked_commit` / `tracked_session`) through its own independent stop review
- **Joint execution**: during a full audit, catch up the backlog of both event sources simultaneously
- **Cross-validation**: changes discussed in conversation are usually landed via commit -- the two event sources can corroborate each other

Typical division of labor: decision records in `decisions/` are better extracted from conversation (because the why is in the conversation), while current facts in architecture are better extracted from commits (because the what is in the code).

---

## Relationship to Session self-check

Session self-check is a lightweight application of this file's mapping table -- only the current session, only checking for omissions, no tracked_session advance. Proactive catch-up uses the full flow.

If the agent already wrote all long-lived SSOT knowledge produced by the current conversation in inline updates, session self-check may propose `no-op`, but this stop conclusion holds only after an independent reviewer returns `no-more-required-changes`. When the reviewer finds an omission they return `needs-fix`, the agent fills in and re-reviews.

### Confidence scan

During session self-check, the agent should also revisit SSOT content written or modified in this session with `confidence` tags:

- Is the tag reasonable? (Are conclusions confirmed in conversation correctly tagged `candidate`? Are agent inferences correctly tagged `hypothesis`?)
- Is there new evidence in this session that can promote an existing hypothesis/candidate?
- Was a confirmed conclusion in the session missing a tag?

This is not an extra audit flow but an additional check dimension when session self-check reviews omissions. See [`knowledge-integrity.md`](../../ssot-preflight/references/knowledge-integrity.md).

### Near-field trigger probe (added in v2.14)

During session self-check, the agent should also run a **near-field trigger probe** -- review the current conversation itself and judge whether SSOT was actually triggered and used:

- Was this a substantive code task? In the perception phase did I read `SSOT/`, or skip perception and go straight to code?
- Was my read surface right? Did SSOT content actually influence output, or was reading equivalent to not reading?

This is read-only, zero-cost self-observation; **no file is changed**. If triggers are insufficient (should-have-read-but-did-not / read-wrong / not-used), follow the core rules of [`consumption-audit.md`](../../ssot-doctor/references/consumption-audit.md): by default only record and produce trigger improvement suggestions; only after user authorization optimize the trigger side (project adapter / `SSOT/README.md` navigation / skill body). When more sample evidence or systematic-break-point localization is needed, escalate to far-field transcript analysis.

Note the role separation: this file (conversation audit) extracts knowledge from transcripts and **writes into** SSOT; the near-field trigger probe and consumption audit evaluate **how SSOT is used**, the opposite direction, with [`consumption-audit.md`](../../ssot-doctor/references/consumption-audit.md) as semantic owner.
