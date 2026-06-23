# Skill Protocol Upgrade Router

This file is the default entry point for SSOT Skill protocol-version drift.
It is intentionally small. Do not put the whole historical ledger here.

A protocol upgrade review only does impact review: read
`tracked_skill_version` from the current project's `SSOT/STATUS.md`, compare it
with the loaded `ssot-preflight/SKILL.md` `metadata.protocol_version`, then read
only the upgrade entries needed for the unapplied range. Do not mechanically
rewrite the entire project SSOT into the latest template.

## Default Reading Path

1. Read the current protocol version from `ssot-preflight/SKILL.md`.
2. Read the consumer project's `tracked_skill_version`.
3. If `tracked_skill_version` is current, stop.
4. If `tracked_skill_version` is `2.35` or newer, read
   [`current-upgrade.md`](current-upgrade.md) only.
5. If `tracked_skill_version` is older than `2.35`, read
   [`archive/index.md`](archive/index.md) and then only the archive range files
   that cover the unapplied versions.
6. For each applicable version, record no-op or update only the affected
   authoritative owners.

Unknown or missing `tracked_skill_version` means the project needs a baseline
audit. Use the archive index to load every range from the first supported
version through the current upgrade file.

## Ledger Files

| File | Read when | Contents |
|---|---|---|
| [`current-upgrade.md`](current-upgrade.md) | Current or recent project waterline | Current protocol entry and the most recent standalone entries |
| [`archive/index.md`](archive/index.md) | Waterline is older than the current file floor, or missing | Range map and complete-version coverage index |
| [`archive/v2.22-v2.34.md`](archive/v2.22-v2.34.md) | Project has unapplied versions in `2.22` through `2.34` | Older medium entries plus explicit low/no-op entries that were previously CHANGELOG-only |
| [`archive/v2.6-v2.21.md`](archive/v2.6-v2.21.md) | Project has unapplied versions in `2.6` through `2.21`, or no waterline | Original baseline protocol entries plus v2.20 installer-only coverage |

## Execution Rules

1. The current protocol version comes from `metadata.protocol_version` in the
   top-of-file YAML of the loaded/installed `ssot-preflight/SKILL.md`.
2. The applied protocol version of the project comes from
   `tracked_skill_version` in `SSOT/STATUS.md`.
3. Version comparison uses semantic-version numeric segments; when parsing
   fails, audit conservatively.
4. When `tracked_skill_version` is missing, treat it as `unknown/legacy` and
   run the baseline audit through the archive index.
5. For each unapplied version, audit per that entry's impact checklist.
6. For no-impact items, explicitly record no-op; for impact items, update only
   affected authoritative locations.
7. Review scope: `semantic_impact=high` upgrades require an independent
   reviewer before the waterline can advance. `none`, `low`, and `medium`
   upgrades use self-review per `status-protocol.md §7.1`; `medium` entries
   still require a standalone impact checklist.

## Bundle Captures

Provisional agent-method rule captures destined for SSOT-SKILL bundle apex
(`AGENTS.md` or a specific `SKILL.md`). Sourced from consumer repos'
`deferred-export` rows during the audit protocol-upgrades cadence; `$ssot-audit`
emits the move block that promotes a row into its apex destination.

| id | captured_at | about | altitude_guess | rule | evidence | signal_source | status |
|---|---|---|---|---|---|---|---|
| CAP-20260618-01 | 2026-06-18 | agent-method | bundle | `[SURFACE-PIN]` (14T) currently passes when the Capability → Surface registry row names a parent component, even when the user-observable behavior is implemented across ≥2 leaf modules with independent failure modes. A cold agent reading the registry then cannot hop to the actual changed leaf when that capability gets a sub-component fix. Tighten the rule: a registry row whose Component cell points at a parent component which imports ≥3 sibling leaves (each with its own test) must enumerate each leaf as its own row, OR the row's `state` must downgrade to `design` until each leaf is enumerated. | path:projects/SSOT-SKILL/skills/ssot-doctor/assets/cold-agent-sim/cycle-example.md (trial 3, commit `<commit>`); the origin project's capability registry (registry row "Live cursor + whole-line Markdown-safe reveal" pointed at a parent component but the diff was in two sibling leaf modules) | repo-signal | routed (cycle-2 tightened 14T per this rule; doctor.md §2.2 row 14T v2.40 leaf-enumeration clause now enforces it) |
| CAP-20260619-01 | 2026-06-19 | agent-method | bundle | Two-step rename phase 2 (cycle-4): promote `[FORK]` (14W) from WARN-only to slice-scoped hard blocker. Cycle-3 phase 1 extracted `architecture/control-plane/` as the unique runtime owner; `backend-runtime/README.md` kept the control-plane shell + Symbols/Failure-trace table rows as a redirect layer. Without a hard-blocker step, non-owner READMEs can drift back into copying control-plane facts. Promotion rule: inside the active cycle's slice scope, `[FORK]` blocks the affected area's `covered` mark until the fact is migrated to its unique runtime owner and non-owner locations are reduced to a single-line link. WARN-only outside the active slice. | path:projects/SSOT-SKILL/skills/ssot-doctor/references/doctor.md (rows 14W + Coverage hard blockers list); the origin project's backend-runtime README (cycle-3 redirect shell §"Control plane (moved)" with explicit cycle-4 promotion note); the origin project's control-plane README (new unique runtime owner extracted in cycle-3 commit `<commit>`) | repo-signal | routed (cycle-4 doctor.md row 14W v2.41 hard-blocker clause now enforces it; preflight protocol_version 2.40 → 2.41) |
| CAP-20260619-02 | 2026-06-19 | agent-method | bundle | Tighten cold-agent-sim §2 prompt template: schema expanded from 3-field `{intent, hop1_path, hop2_anchor}` to 6-field `{intent, hop1_path, hop2_anchor, hops_used, verdict, reasoning}`; new "Routing-only mandate" subsection (v2.42) explicitly disambiguates `verdict=FAIL` as "cannot route to SSOT anchor" (NOT "commit appears unaligned with SSOT consensus"). Cycle-3 + cycle-4 surfaced ~25-30% of trials drifting from "route to owner" mode into "validate commit text vs SSOT consensus" mode under ambiguous prompts (cycle-3 trials `<commit>` + `<commit>`; cycle-4 trials `<commit>`/T1+T3 + `<commit>` ×3 + `<commit>`/T1+T3 + `<commit>`/T2). The prompt template shape was the suspected cause. Cycle-5 regression with the tightened prompt tests whether schema-deviation drops below 10%. | path:projects/SSOT-SKILL/skills/ssot-doctor/references/cold-agent-sim.md §2 (Output schema row + new "Routing-only mandate" subsection, v2.42); path:projects/SSOT-SKILL/skills/ssot-doctor/assets/cold-agent-sim/cycle-example.md (§6 deviation 2); path:projects/SSOT-SKILL/skills/ssot-doctor/assets/cold-agent-sim/cycle-example.md (results table — `<commit>` + `<commit>` + `<commit>` fails all schema-deviation); path:projects/SSOT-SKILL/skills/ssot-doctor/assets/cold-agent-sim/cycle-example.md (regression results under v2.42 prompt; preflight protocol_version 2.41 → 2.42; VERSION 2.38 → 2.42 catch-up) | repo-signal | routed (cycle-5 phase 1; cold-agent-sim.md §2 v2.42 prompt-template clause now in force) |

> CAP- row enums and the move-block mechanism: see
> `$ssot-closeout references/promotion-rationale.md`.
