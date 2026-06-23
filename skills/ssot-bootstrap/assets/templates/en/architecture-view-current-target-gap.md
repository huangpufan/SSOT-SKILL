# Current / Target / Gap

> Writing style: any cold reader. See `ssot-bootstrap` §3.7.

> Cross-domain implementation evolution view. This file separates implemented facts from target technical design and explains the migration stance. It synthesizes implementation gaps from domain evidence, decisions, and product owners; it does not own concrete state/contract/failure detail, nor does it redefine the product roadmap or product acceptance. It must not flatten design intent into only a state table.

## Scope

- **Owns**: global implementation current/target/gap, migration priorities, partially landed technical design intent, implementation gaps against product acceptance, stale/conflicting technical design source material, and open design adjudications.
- **Links but does not own**: product roadmap, phase intent, product-level gaps, and product acceptance gates; these are owned by `product/roadmap-and-acceptance.md` or the relevant product owner.
- **Does not own**: in-domain implementation details. Each concrete gap should link to a domain, decision, bug, gotcha, test, or tech-debt entry.
- **Primary source material**:

## Why This View Exists

Use 1-3 paragraphs to explain the system's current implementation posture: what already holds, what the target technical state is, which product acceptance items still have implementation gaps, and how future Agents should trade off implementation convenience, product constraints, and design direction.

## Narrative / Model

Use natural language to explain the migration model: which current implementations are intentionally preserved, which are transitional, and what future work should prioritize or avoid.

## Design Intent / Constraints

| Intent or constraint | Current relationship | Why it matters | Evidence / decision |
|---|---|---|---|
| | implemented / partial / diverged / pending | | |

## Migration Stance

- **Current baseline**:
- **Product owner links**:
- **Target technical design**:
- **Highest-priority gaps**:
- **Current-stage non-goals**:
- **Risk tolerance / rollback stance**:

## Current / Target / Gap Matrix

| Area | Current implementation fact | Target technical intent / product constraint | Implementation gap / blocker | Authoritative owner | Evidence |
|---|---|---|---|---|---|
| | | | | product / domain / decision / debt / adjudication | |

## Partially Landed Design Intent

| Intent | Landing status | Missing parts | Decision / source | Required adjudication |
|---|---|---|---|---|
| | pending / partial / diverged / implemented | | | |

## Rejected Alternatives / Do Not Revive

| Old form or rejected alternative | Why rejected | Alternative direction | Enforcement location |
|---|---|---|---|
| | | | decision / domain / gotcha / test |

## Open Design Questions

| Question | Why it matters | When it is needed | Current default | Links |
|---|---|---|---|---|
| | | | | |

## Related Domains

| Domain owner | Current / target responsibilities | Gap / decision / debt links |
|---|---|---|
| | | |

## Evidence

| Claim | Source material / code / runtime evidence | Confidence | Follow-up |
|---|---|---|---|
| | | verified / documented / inferred / unknown | |
