# Thin-Adapter Protocol

This file is the semantic owner of the "thin adapter" relationship between SSOT and agent harness instruction files (AGENTS.md, CLAUDE.md, .cursor/rules etc.). Read on demand when creating or maintaining agent instruction files, when Bootstrap creates the skeleton, or when Doctor checks the form of generated adapter files. A thin adapter is an optional startup-entry form generated or hosted by SSOT; it is not the default goal for all startup files. If these files contain repository facts, commands, workflows, architectural constraints or test strategy, their fact correctness is owned by [`source-material.md`](../../ssot-preflight/references/source-material.md), the core-reference-document review in [`status-protocol.md`](../../ssot-preflight/references/status-protocol.md), and the `[CORE-REF]` check in [`doctor.md`](doctor.md); the SSOT trigger chain is owned by the `[CONSUMPTION]` check.

## Table of contents

- [1. Principles](#1-principles)
- [2. Adapter content spec](#2-adapter-content-spec)
- [3. Generation timing](#3-generation-timing)
- [4. Doctor integration](#4-doctor-integration)
- [5. Anti-patterns](#5-anti-patterns)

## 1. Principles

SSOT is canonical; startup entries generated/hosted by SSOT should remain in thin-adapter form. Handwritten or mixed startup files may keep repository commands, workflows, architectural constraints, model/config rules or test strategy, but these long-lived facts must accept `[CORE-REF]` review.

- **Single authoritative location**: long-lived knowledge is maintained only in `SSOT/`. Long-lived facts inside AGENTS.md, CLAUDE.md, .cursor/rules etc. are either absorbed and pointed at SSOT, or marked in the core-reference-document review as still needing to be kept and re-checked.
- **Generated adapter is a router**: an adapter with `<!-- SSOT-generated ... -->` marker is responsible for telling the agent "go read SSOT", not for restating SSOT content.
- **Generated output is rebuildable**: a generated adapter can be regenerated from SSOT at any time; losing it does not affect long-lived knowledge.
- **Do not overwrite user content**: before generating an adapter, check whether the target file already exists and is not SSOT-generated (no generated marker); on conflict, report rather than overwrite.
- **Role separation**: `[ADAPTER]` only checks marker, size, optional source hash and summary boundary of SSOT-generated thin adapters; `[CONSUMPTION]` checks whether a startup/reference file forms an effective SSOT trigger chain; `[CORE-REF]` checks whether facts in startup/reference files are still correct. Handwritten files without a marker are not reported under `[ADAPTER]` for lacking a marker.

Authority relationships:

| Type | Form | Check path |
|---|---|---|
| `thin-adapter` | Has SSOT-generated marker, contains only SSOT routing and a small summary | `[ADAPTER]` + `[CONSUMPTION]`; gives `[CORE-REF]` suggestions when the summary crosses the boundary |
| `mixed` | Handwritten or generated file with both SSOT routing and command/workflow/architecture/test/config facts | `[CONSUMPTION]` + `[CORE-REF]`; `[ADAPTER]` only when a generated marker is present |
| `source-material` | Mostly handwritten source material, may not have SSOT routing | `[CORE-REF]`; if the project expects the agent to consume SSOT automatically, also give a `[CONSUMPTION]` suggestion |

---

## 2. Adapter content spec

A generated thin-adapter file does not exceed 50 lines and contains the following blocks:

| Block | Required | Description |
|---|---|---|
| Generated marker | Yes | First-line comment `<!-- SSOT-generated | generated_at: ... -->`, marks SSOT generation with generation date |
| SSOT source hash line | Recommended | Second-line comment `<!-- SSOT-source: <path>@<hash> ... -->`, records the SSOT source file and content hash this generation was based on, for ssot-lint drift verification |
| Project identity | Yes | One-sentence positioning from the opening line of `SSOT/README.md` |
| SSOT read instruction | Yes | Tells the agent to use `$ssot-preflight` first, then navigate per the `SSOT/README.md` entry routing |
| Core invariants | Recommended | Core invariants from architecture, no more than 5 items, using source-backed or verified knowledge |
| Key gotcha summary | Optional | One-sentence summary + pointer of the 1-3 highest-risk active gotchas |

A generated thin adapter must not contain:

- Full protocol restatement or full-text of an area
- Detailed information that can be read directly from SSOT
- Knowledge with confidence hypothesis or candidate
- Independently maintained long-lived facts

---

## 3. Generation timing

| Timing | Condition | Action |
|---|---|---|
| Bootstrap Phase 1 | Recon finds the repo has or needs an agent instruction file | Generate a thin adapter from the template |
| Explicit user request | User asks to create or update AGENTS.md/CLAUDE.md etc. | Generate or update from the template |
| SSOT core-invariant change | Inline update modifies architecture core invariants | Remind the user the adapter may need syncing (do not auto-update) |

Pre-generation checks:

1. Does the target file already exist?
2. If so, does it have a generated marker (first line matches `<!-- SSOT-generated` or equivalent comment)?
3. Has marker -> may update. No marker -> report conflict, do not overwrite.
4. On conflict, report and classify as `mixed` or `source-material`; only when the repo wants the file to be SSOT-hosted, or when long-lived facts have already been moved into SSOT and the user authorizes, recommend replacing with a thin adapter.

Generation method (v2.13): the adapter is instantiated by the agent from the template. **No independent generator program is introduced on purpose**, to control complexity. During generation, `[SHOULD]` compute the content hash of the referenced SSOT source file and write the SSOT source hash line; algorithm `sha256sum <file> | cut -c1-12` (use `shasum -a 256` when `sha256sum` is unavailable, consistent with [`assets/scripts/ssot-lint.sh`](../assets/scripts/ssot-lint.sh)). ssot-lint later compares the current hash to detect source drift -- this is the minimal "generate by agent, verify by script" combination.

---

## 4. Doctor integration

Adapter checks are split into L1 deterministic and L2 semantic layers, consistent with Doctor's layered verification protocol. Here L1 only covers thin adapters with the SSOT-generated marker; handwritten or mixed startup files are not reported as `[ADAPTER]` for lacking a marker or exceeding 50 lines. Here L2 only covers "is the adapter summary out of bounds"; the correctness of repository commands, directory map, workflows, architectural constraints, model/config rules or test strategy belongs to `[CORE-REF]`; the reachability of the SSOT read chain belongs to `[CONSUMPTION]`; neither belongs to `[ADAPTER]`.

**L1 deterministic checks** (auto pass/fail):

- Does the SSOT-generated thin-adapter marker exist with correct format?
- Is the optional `SSOT-source` hash line correctly formatted, does the source file exist, and does the hash match?
- Does the SSOT-generated thin adapter exceed 50 lines?
- If it contains an SSOT source hash line: does the declared source file exist, and does the current content hash match what is declared (mismatch hints possible stale)?

**L2 semantic checks** (need agent judgment):

- Is the core-invariant summary in the adapter consistent with the current SSOT architecture content?
- Does the SSOT-generated thin adapter contain independent facts not in SSOT? If yes, output a `[CORE-REF]` suggestion rather than reporting only `[ADAPTER]`.

Output tags:

- `[ADAPTER]`: SSOT-generated thin-adapter file-form issue.
- `[CONSUMPTION]`: SSOT trigger-chain issue of a startup/reference file.
- `[CORE-REF]`: fact correctness, long-lived content absorption, startup-file update suggestions.

---

## 5. Anti-patterns

| Anti-pattern | Why dangerous |
|---|---|
| Maintaining independent long-lived facts in AGENTS.md/CLAUDE.md | Authoritative location splits; future agents cannot tell which is authoritative |
| Copying full SSOT protocol into the adapter | The adapter bloats; maintaining the same rule in two places drifts |
| Auto-updating the adapter without reminding the user | The user may have added non-SSOT harness-specific configuration in the adapter |
| Putting hypothesis/candidate knowledge into the adapter | Uncertain knowledge leaks into files not governed by SSOT |
| Putting summaries of all gotchas/decisions/architecture into the adapter | The adapter should only hold the highest-priority core invariants; detailed info should be read from SSOT |
| Reporting handwritten startup files only as `[ADAPTER]` for marker/size issues | Misses outdated commands, workflow state, architectural boundaries or test strategy; must also run `[CORE-REF]` |
| Defaulting all startup files to `thin-adapterize` | Will lose harness-required local commands, workflows or operational constraints; `thin-adapterize` may only be a conditional suggestion |
