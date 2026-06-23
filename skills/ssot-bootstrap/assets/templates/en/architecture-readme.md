# Architecture

> Writing style: any cold reader. See `ssot-bootstrap` §3.7.

> Architecture root is a Runtime Owner Map. It gives the technical mental model,
> core invariants, cross-owner view routes, runtime-owner domain routes, and
> evidence direction. Product promises, users, roadmap, non-goals, and
> acceptance meaning live in `product/`; architecture only links those owners
> and records implementation response or implementation gap.

## Design Brief

Use 1-3 paragraphs to explain what this system is, which runtime path matters
most, which constraints make the architecture safe, and what future agents must
preserve. Name the primary product owner links, but do not redefine product
promises here.

## Design Intent And Truth

Before any dense owner map or recovery manifest, write 2-5 short paragraphs that
explain the design from first principles: why the chosen runtime-owner axis is
the right split, what is enforced today, what remains design/debt/Out, which
near-miss implementation inventories are deliberately excluded from the design
core, and which view/domain to inspect first for detail.

This section synthesizes owners; it does not replace view/domain bodies.

## Runtime Owner Map

Each row routes a reader to the owner of runtime state, resources, contracts,
lifecycle, failure/recovery, or verification. Rows are routes, not body facts.

| Reader question | Runtime owner | First stop | Evidence direction | Stop condition / risk |
|---|---|---|---|---|
| Which process owns writes and lifecycle? | `<owner>` | [domains/<owner>/README.md](./domains/<owner>/README.md) | code / config / schema / tests | Reader can locate the write owner and lifecycle boundary |
| Which contract handles `<surface>`? | `<owner>` | [domains/<owner>/README.md](./domains/<owner>/README.md) | API / SDK / protocol / schema / tests | Reader can locate compatibility semantics |

## Core Invariants

Only list invariants that apply across runtime owners. Domain-local invariants
belong in the domain README.

| Invariant | Owner | Why it exists | Evidence |
|---|---|---|---|
| | [domains/<owner>/README.md](./domains/<owner>/README.md) | | |

## Views

Views stay only when the question crosses runtime owners. Common valid views:
critical runtime flows, contract map, failure/recovery map, and global
current/target/gap index.

| View | Path | Cross-owner question | Status | Evidence |
|---|---|---|---|---|
| Operating model | [views/operating-model.md](./views/operating-model.md) | Technical operating constraints across owners | gap / covered / stale / unknown | |
| Critical runtime flows | [views/critical-journeys.md](./views/critical-journeys.md) | How load-bearing flows cross owners | gap / covered / stale / unknown | |
| Contract map | `views/contract-map.md` when needed | Which owners expose which contracts | gap / covered / stale / unknown | |
| Failure / recovery map | `views/failure-recovery-map.md` when needed | How failures cross owners and recover | gap / covered / stale / unknown | |
| Current / Target / Gap | [views/current-target-gap.md](./views/current-target-gap.md) | Global migration posture and gap index | gap / covered / stale / unknown | |

## Domains

Domains own detailed runtime facts. Keep domain names aligned to runtime owner
boundaries, not source directories.

| Domain | Path | Why separate | Owned facts | Owns surfaces | Status | Evidence |
|---|---|---|---|---|---|---|
| `<owner>` | [domains/<owner>/README.md](./domains/<owner>/README.md) | | state / resource / contract / lifecycle / failure / verification | routes / SQL identifiers / DOM selectors / CLI commands handled by this owner | gap / covered / stale / unknown | |

The `Owns surfaces` column lists the route prefixes, SQL identifiers, DOM selector roots, or CLI commands this domain owns; doctor `[FORK]` (14W) treats overlap across rows as a fork signal.

## Architecture Diagrams

Mermaid fenced blocks are authoritative. Exported images are derivatives.
Root diagrams stay at owner-map level; detailed flow/state/failure diagrams
belong in views or domains.

### Diagram Index

| Diagram ID | Status | Coverage | Authoritative location | Evidence |
|---|---|---|---|---|
| `<ARCH-OWNER-MAP-CURRENT>` | current / target / stale | runtime owners and cross-owner edges | this file | |

### Current Runtime Owner Map

- **Diagram ID**: `<ARCH-OWNER-MAP-CURRENT>`
- **Status**: `current`
- **Coverage**: runtime owners and cross-owner edges.
- **Evidence**:

```mermaid
flowchart LR
  caller["<caller>"] --> ownerA["<runtime owner A>"]
  ownerA --> ownerB["<runtime owner B>"]
```

## Current / Target / Gap

Root keeps only global migration posture and the gap index link. Detailed CTG
belongs in the relevant view or domain.

| Gap | Owner | Current | Target | Next evidence |
|---|---|---|---|---|
| | [views/current-target-gap.md](./views/current-target-gap.md) | | | |

## decomposition_basis

- **Chosen split axis**: `runtime-owner-map` / `single-level`
- **Why this axis**:
- **Runtime owners**:
- **Rejected axes**:
- **Owner anchor**: root routes; domains own runtime facts; views own cross-owner synthesis.
- **Coverage depth**: `deep` / `sampled` / `inferred` / `unknown`
- **Coverage scope**:
- **Stop review**: `<reviewer>` returned `no-more-required-changes` / `needs-fix`.

## Source Material Pointers

The full inventory lives in `SSOT/STATUS.md`. This root links only
architecture-related sources whose durable technical facts have an owner.

| Source material | Lifecycle / classification | Authoritative owner | Status / conflict |
|---|---|---|---|
| | working/* / historical/* / external/source-material / public/thin-entry; absorb / link-only / stale/conflict / obsolete | | |
