# Operating Model

> Writing style: any cold reader. See `ssot-bootstrap` §3.7.

> Cross-domain technical design intent view. This file explains how the system responds to product owners, what it optimizes technically, what it refuses to optimize, and which design constraints future work must preserve. It cannot be only tables. Product promises and product acceptance are not redefined here.

## Scope

- **Owns**: technical system mission, primary technical actors/callers, operating philosophy, implementation priorities, technical non-goals, non-functional success criteria, technical implications of product constraints, and cross-domain design constraints.
- **Links but does not own**: product mission, product promises, users/operators, product non-goals, roadmap, and product acceptance; these are owned by `product/`.
- **Does not own**: concrete state/resource ownership, API/schema field details, or in-domain failure recovery; those should link to domains.
- **Primary source material**:

## Why This View Exists

Use 1-3 paragraphs to tell new Agents the technical design stance before the component tables. Explain the constraints product owners impose on the system, the technical actors/callers it serves, and the design pressures future changes must face.

## Narrative / Model

Use natural language to describe the operating model: how work enters the system, who trusts the system, which outcomes matter most, and which shortcuts would break the design.

## Design Brief

- **Product owner links**:
- **Technical mission / promise**:
- **Primary technical actors / callers**:
- **Primary actors / callers**:
- **Optimization priorities**:
- **Non-goals**:
- **Current-implementation priorities**:
- **Success criteria**:

## Design Principles

> Record principles as decision guides. Each principle should explain why it exists and how future work should handle the tempting shortcuts it will encounter.

| Principle | Why it matters | What enforces it | Evidence / source |
|---|---|---|---|
| | | domain / decision / test / runtime evidence | |

## Design Constraints

| Constraint | Scope | Consequence if violated | Authoritative enforcement point / evidence |
|---|---|---|---|
| | | | |

## Primary Paths

| Path | Product intent / runtime intent | Technical success signals | Authoritative product journey / architecture domain |
|---|---|---|---|
| | | | product journey owner + [critical-journeys.md](./critical-journeys.md) |

## Related Domains

| Domain | Why it enforces this operating model | Constraint / journey links |
|---|---|---|
| | | |

## Rejected Optimizations / Non-Goals

| Non-goal or rejected optimization | Why rejected | Alternative approach | Evidence / decision |
|---|---|---|---|
| | | | |

## Current / Target / Gap

| Area | Current operating model | Target intent | Gap / adjudication | Evidence |
|---|---|---|---|---|
| | | | | [current-target-gap.md](./current-target-gap.md) |

## Evidence

| Claim | Source material / code / runtime evidence | Confidence | Follow-up |
|---|---|---|---|
| | | verified / documented / inferred / unknown | |
