# Critical Journeys

> Writing style: any cold reader. See `ssot-bootstrap` §3.7.

> Cross-domain runtime journey view. This file explains the end-to-end runtime paths, lifecycle, failure/recovery, and observability signals that should guide technical design decisions. It synthesizes journeys from domain evidence; it does not own concrete state/contract/failure detail, nor does it redefine product journeys or product acceptance. It must contain narrative technical intent and recovery/observability signals, not just a flow table.

## Scope

- **Owns**: system/runtime execution, phase lifecycles, cross-domain overview diagrams, failure/recovery, observability signals, and technical acceptance signals.
- **Links but does not own**: user/operator journeys, touchpoints, experience constraints, and product acceptance; these are owned by `product/journeys/` or the product spine.
- **Does not own**: concrete state/resource details or in-domain contracts; those should link to domains.
- **Primary source material**:

## Why This View Exists

Use 1-3 paragraphs to explain which runtime journeys determine whether the system reliably delivers the product promise. When user/operator perspective and system perspective diverge, link to the product journey owner and describe only the system execution path here.

## Narrative / Model

Before listing flows, use natural language to explain the journey model. Identify which journey is the design anchor and how future changes should be judged against it.

## Design Intent / Constraints

| Intent or constraint | Applicable journey | Why it matters | Evidence / source |
|---|---|---|---|
| | | | |

## Journey Overview

- **Product journey owner links**:
- **Primary runtime journeys**:
- **Secondary runtime journeys**:
- **Critical failure/recovery journeys**:
- **Product journeys explicitly out of architecture scope**:

## Journey Diagrams

> Mermaid code blocks are authoritative. Use overview diagrams here; domain-specific subflows go to the domain README.

### External Journey Diagram Candidates

> Externally generated diagrams, screenshots, IDE dependency graphs, and auto dependency graphs are candidates only. When absorbed, they must be rewritten as current or target Mermaid journey diagrams and linked to the domains responsible for each phase.

| Candidate source | Suggested authoritative Diagram ID | Journey / phase | What to verify | Candidate status |
|---|---|---|---|---|
| | | | | pending / converted / rejected / obsolete |

### `<JOURNEY-...-CURRENT>`

- **Status**: `current`
- **Coverage**:
- **Evidence**:

```mermaid
sequenceDiagram
  participant Actor
  participant System
  participant Domain
  Actor->>System: <intent>
  System->>Domain: <cross-domain step>
  Domain-->>System: <state/result>
  System-->>Actor: <visible outcome>
```

## Primary Journeys

| Journey | Product intent / runtime intent | Triggered design constraints | Technical acceptance / recovery / observability signals | Product owner / Domain owners |
|---|---|---|---|---|
| | | | | |

## Failure / Recovery Journeys

| Failure journey | Detection signals | Expected recovery / degradation | What must be observable | Domain recovery owner / tests |
|---|---|---|---|---|
| | | | | |

## Acceptance Criteria

| Criterion | Applies to | Required evidence | Frequency / trigger |
|---|---|---|---|
| | | | |

## Related Domains

| Domain owner | Journey phases owned | State / contract / recovery owned |
|---|---|---|
| | | |

## Current / Target / Gap

| Journey | Current behavior | Target journey | Gap / next verification | Evidence |
|---|---|---|---|---|
| | | | | |

## Evidence

| Claim | Source material / code / runtime evidence | Confidence | Follow-up |
|---|---|---|---|
| | | verified / documented / inferred / unknown | |
