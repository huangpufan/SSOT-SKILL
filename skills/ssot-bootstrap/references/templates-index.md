# Templates Index

Single index of every file under `assets/templates/{en,zh}/`. Every row has a parallel `en/` and `zh/` version (enforced by `tests/test-bundle-shape.sh`). When adding or removing a template, update this index *and* both language directories in the same change.

The "Default destination" column is where Phase 1 Skeleton creation (see [`bootstrap.md`](./bootstrap.md) §2) writes the rendered file. The "Section in `bootstrap.md`" column points at the protocol paragraph that owns when/why each template is used.

| Template | Purpose | Default destination | Section in bootstrap.md |
|---|---|---|---|
| `recon-report.md` | Phase 0 recon output: documentation-language lock evidence, repo inventory, hypotheses for later phases. | `SSOT/.bootstrap/recon.md` | [Phase 0 recon §1](./bootstrap.md#1-phase-0-recon) |
| `bootstrap-manifest.md` | Coordination layer: global state, area assignment, convergence-check ledger. | `SSOT/.bootstrap/manifest.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `bootstrap-session.md` | One log per exploration unit (one sub-Agent run); reviewed at stop. | `SSOT/.bootstrap/sessions/NNN-<scope>.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `ssot-readme.md` | SSOT trunk index: satellite area map, optional task-entry map. | `SSOT/README.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `status.md` | State-tracking file: tracked_commit, tracked_skill_version, documentation_language lock, area states. | `SSOT/STATUS.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `product-readme.md` | Product trunk README: routes to PRD, product-model, capabilities, journeys, roadmap. | `SSOT/01-product/README.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `product-prd.md` | Concise PRD spine: long-term product facts, owner links, current/target product posture. | `SSOT/01-product/prd.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `product-model.md` | Users, problems, product promises, product boundary, product language, long-term product tradeoffs. | `SSOT/01-product/product-model.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `product-roadmap-and-acceptance.md` | Product phases, roadmap intent, product acceptance gates, product-level gaps. | `SSOT/01-product/roadmap-and-acceptance.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `product-capabilities-readme.md` | Capability owner index (no duplicated capability fact content). | `SSOT/01-product/capabilities/README.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `product-capability-entry.md` | Per-capability entry. | `SSOT/01-product/capabilities/<capability>.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `product-journeys-readme.md` | Product journey owner index. | `SSOT/01-product/journeys/README.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `product-journey-entry.md` | Per-product-journey entry. | `SSOT/01-product/journeys/<journey>.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `architecture-readme.md` | Architecture entry point: technical system mental model, routes to views/domains. | `SSOT/02-architecture/README.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `architecture-views-readme.md` | Cross-domain architecture views index. | `SSOT/02-architecture/views/README.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `architecture-view-operating-model.md` | Cross-domain technical design intent view. | `SSOT/02-architecture/views/operating-model.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `architecture-view-critical-journeys.md` | Cross-domain runtime journey view (end-to-end paths, lifecycle, failure/recovery, observability). | `SSOT/02-architecture/views/critical-journeys.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `architecture-view-current-target-gap.md` | Cross-domain implementation evolution view: implemented facts vs target design vs migration stance. | `SSOT/02-architecture/views/current-target-gap.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `architecture-domain-readme.md` | Per-architecture-domain README: state/resources, contracts, invariants, failure/recovery, evidence. | `SSOT/02-architecture/domains/<domain>/README.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `glossary-entry.md` | Per-term glossary entry: one positive sentence, used-in inverse index, not-to-be-confused-with disambiguation, source pin. (v2.51) | `SSOT/glossary/<term>.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `_manifest.md` | Per-area SSOT self-maintenance machinery (Core recovery manifest, Apex / Maxim → Owner mirror, Capability surface registry, intent_recovery evidence, README-self failure modes, adoption-cycle log). One per covered product / architecture area; carries only doctor / cold-agent-sim / audit material so the prose owner stays product / design narrative. (v2.48) | `SSOT/01-product/_manifest.md`, `SSOT/01-product/{capabilities,journeys}/_manifest.md`, `SSOT/02-architecture/_manifest.md`, `SSOT/02-architecture/views/_manifest.md`, `SSOT/02-architecture/<domain>/_manifest.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `development-readme.md` | How to run the project and development conventions for new Agents. | `SSOT/03-process/development/README.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `testing-readme.md` | Test strategy, commands, fixture constraints, high-risk regression protection. | `SSOT/03-process/testing/README.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `release-readme.md` | Versioning, release, delivery consistency invariants. | `SSOT/03-process/release/README.md` | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
| `adapter-thin.md` | Thin agent-instruction adapter (AGENTS.md / CLAUDE.md / GEMINI.md). Keep `Key Reminders` for proactively-read files; drop for read-on-demand files. | `AGENTS.md` / `CLAUDE.md` / `GEMINI.md` (repo root) | [Phase 1 outputs §2](./bootstrap.md#2-phase-1-skeleton-creation) |
