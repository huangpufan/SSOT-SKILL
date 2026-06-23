# <runtime owner>

> Writing style: any cold reader. See `ssot-bootstrap` §3.7.

> Architecture domain README. Use this for a runtime owner: a boundary with its
> own state/resources, contracts, lifecycle, failure/recovery, verification, or
> implementation gap. Do not use this as a universal checklist. Delete optional
> sections that do not apply.

## Why This Owner Is Separate

Use 1-3 paragraphs to explain the boundary, the owned runtime responsibility,
and what would become unsafe or unclear if it merged with another owner.

- **Includes**:
- **Excludes**:
- **Primary evidence**:

## Owned State And Resources

Name the state/resources this owner writes, persists, derives, or protects.
If the owner has no state/resource responsibility, say why in prose rather than
leaving empty tables.

| State / resource | Write owner | Readers / derived users | Lifecycle / persistence | Evidence |
|---|---|---|---|---|
| | this owner | | | |

## Contract Surfaces

List only contracts whose compatibility semantics this owner maintains: API, SDK, protocol, event, schema, file format, CLI, or external integration. Each row carries `state: contract | design | poc | debt` inline (`ssot-bootstrap` §3.7) and a surface anchor (`ssot-preflight/references/architecture.md` §16). Doctor `[SURFACE-PIN]` (14T) and `[STATE-TAG]` (14V) gate this.

| Contract | Compatibility promise | Callers / consumers | Surface anchor | state | Evidence / tests |
|---|---|---|---|---|---|
| | | | GET /api/foo (`src/.../routes.py:42`) / `frontend/.../Component.tsx` / Playwright `frontend/e2e/foo.spec.ts::name` | contract / design / poc / debt | |

## Lifecycle And Failure Boundary

Explain startup/shutdown, concurrency, retry, rollback, demotion, or recovery
only when this owner has an independent boundary.

| Boundary | Normal lifecycle | Failure / recovery | Evidence |
|---|---|---|---|
| | | | |

## Failure trace

Doctor `[FAILURE-TRACE]` (14U) gates regression coverage of observed failure modes; one row per mode that has bitten this owner.

| Failure mode | Detection | Recovery | Regression test or bug | state |
|---|---|---|---|---|

## Runtime Flows

Keep only load-bearing flows: cross-boundary calls, persistent writes, resource
lifecycle, user/ops/API behavior, locks/transactions/retries, trust boundaries,
or dense algorithms.

| Flow | Diagram ID | Why included | State / contract touched | Evidence |
|---|---|---|---|---|
| | `<DOMAIN-FLOW-...-CURRENT>` | | | |

## Invariants

List invariants that make this owner safe to change. Do not duplicate product
acceptance or root-level invariants.

| Invariant | Why it exists | Consequence if violated | Evidence |
|---|---|---|---|
| | | | |

## Symbols

Each invariant / contract row anchors at least one `path:src/...:LNN` or `tests/...::test_*` a cold agent can resolve in one hop (doctor `[SYMBOL-PIN]` / 14S).

| Symbol | Kind | Owner anchor | state | Evidence |
|---|---|---|---|---|
| `<symbol name>` | function / class / route / SQL identifier / DOM selector | `path:src/...:LNN` or `tests/...::test_*` | contract / design / poc / debt | |

## Verification And Evidence

Give the minimal checks or runtime evidence that validate changes to this
owner.

| Change family | Minimal sufficient verification | Evidence owner |
|---|---|---|
| | | |

## Capability → Surface registry

Mirrors `ssot-preflight/references/architecture.md` §16; `product/capabilities/<name>.md` carries the product-side mirror.

| Capability link | Route or module | Component | Test |
|---|---|---|---|

## Playbook

Mechanical task branches (≥3 ordered operations) live in [`./playbook.md`](./playbook.md) modeled on `ssot-bootstrap/assets/templates/{en,zh}/architecture-domain-playbook.md`. If this domain has no such task branches, write `not_applicable` and the reason here.

## Local Current / Target / Gap

This owner owns detailed implementation posture for its boundary. Global CTG
indexes this row; it does not duplicate the details.

| Topic | Current | Target | Gap / next evidence |
|---|---|---|---|
| | | | |

## Diagrams

Mermaid fenced blocks are authoritative. Current and target diagrams are
separate. Add diagrams only for non-obvious boundaries, flows, state/resource
lifecycle, lifecycle/concurrency, failure/recovery, or trust/config.

### Diagram Index

| Diagram ID | Status | Coverage | Evidence |
|---|---|---|---|
| `<DOMAIN-CTX-CURRENT>` | current / target / stale | boundary/context | |
| `<DOMAIN-FLOW-...-CURRENT>` | current / target / stale | runtime flow | |

### Current Boundary / Context

- **Diagram ID**: `<DOMAIN-CTX-CURRENT>`
- **Status**: `current`
- **Coverage**: boundary and external dependencies.
- **Evidence**:

```mermaid
flowchart LR
  caller["<caller>"] --> owner["<runtime owner>"]
  owner --> dependency["<dependency>"]
```

## decomposition_basis

- **Chosen split axis**: `runtime owner` / `single-level`
- **Why this owner is separate**:
- **Independence signals**: state / resource / contract / lifecycle / failure / invariant / verification / current-target-gap
- **Rejected false friends**: source directory / package name / team / external topic tree
- **Owner anchor**: this file owns runtime facts for `<runtime owner>`; non-owner facts link out.
- **Coverage depth**: `deep` / `sampled` / `inferred` / `unknown`
- **Coverage scope**:
- **Stop review**: `<reviewer>` returned `no-more-required-changes` / `needs-fix`.

## Source Material Pointers

| Source material | Lifecycle / classification | Absorbed fact | Status / conflict |
|---|---|---|---|
| | working/* / historical/* / external/source-material / public/thin-entry; absorb / link-only / stale/conflict / obsolete | | |
