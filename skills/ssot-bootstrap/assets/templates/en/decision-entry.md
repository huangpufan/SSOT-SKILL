---
id: DEC-NNNN
record_status: accepted
status: accepted
implementation_state: pending
created_on: YYYY-MM-DD
updated_on: YYYY-MM-DD
introduced_in: abcdef1
updated_in:
  - abcdef1
superseded_by:
supersedes:
---

# <NNNN> <Title>

<!-- Writing style: implementation-delegator. Start with the decision pressure
     and current consequence; explain labels before evidence and paths. -->

<!-- Completeness authority: reader-quality.md C01-C09, R01-R16, and applicable
     Q01-Q21. Covered records use the exact lightweight entry/index contract;
     keep facts, judgment, evidence, both state axes, owner, and closure explicit. -->

> Use one file per major decision. Explain why this option was chosen over the
> closest alternatives, what changed because of it, and what a future reader
> must verify before keeping, changing, or replacing it.

## Record orientation

<State the record's purpose and scope, trigger and date/context, current
lifecycle and implementation status, verified facts versus rationale or
inference, and the evidence/provenance freshness limit.>

`record_status` says whether this decision is accepted, deprecated, or
superseded. `implementation_state` separately says whether the decided change
is pending, partial, implemented, diverged, or superseded. The compatibility
field `status` mirrors `record_status`; never use it for implementation
progress.

## Background

What problem prompted this decision? What context, constraints, or prior decisions shaped the space of possible options?

## Decision

What was decided, and which option was chosen. State the decision as a positive, concrete choice — "We will use X for Y" — rather than a negation of what was rejected.

### Options considered

| Option | Brief description | Key trade-off |
|--------|-------------------|---------------|
| Option A (chosen) | | |
| Option B | | |
| Option C | | |

## Consequences

What does this decision change? Both intended effects and side effects. Record things a future agent must know before reversing or modifying this decision: invariants created, constraints introduced, compatibility commitments.

## Scope of Impact

- **Cross-domain impact**:
- **Product acceptance boundaries**:
- **Testing / verification implications**:
- **Migration or compatibility surface**:
- **Affected versions / platforms / environments / tenants-workspaces / data classes / compatibility window**:
- **Security / privacy / compliance / customer exposure and notification duty**:
- **Owner / reviewer**:

## Validation and follow-up

<Explain how the decision or implementation is validated, who owns remaining
work, the next follow-up trigger, and any reproducible symptom or prevention
rule that matters.>

## Closure, supersession, and invalidation

<State the falsifiable closure condition, what evidence closes the record,
what decision supersedes it, and which changed assumption makes it stale.>
