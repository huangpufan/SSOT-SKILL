---
intent_recovery: gap
---
# Runtime owner: Example boundary

<!-- Writing style: implementation-delegator. Begin with why this owner matters
     in a concrete current flow; explain labels before paths and evidence. -->

<!-- Replace the title. Explain this owner as a runtime boundary, not a source
     directory: what responsibility it owns, who calls it, and which state,
     resource, contract, lifecycle, or failure would become ambiguous without it. -->

## Mental model and boundary

<!-- Begin with two or three paragraphs and one concrete scene. Name what enters,
     what this owner decides or changes, what leaves, what it delegates, and the
     nearest owner a newcomer might confuse with it. Define terms before IDs. -->

```mermaid
<!-- diagram_type: component -->
flowchart LR
  caller["Caller"] --> owner["This runtime owner"]
  owner --> state[("Owned state or resource")]
  owner --> dependency["Delegated dependency"]
  owner --> observer["Result or observable signal"]
```

## A canonical current flow

<!-- Narrate one load-bearing flow from trigger to user/operator outcome. Mark
     each cross-boundary hand-off, important state transition, and correlation
     handle. Keep target behaviour separate and link rather than restating the
     cross-owner critical-journey view. -->

## Owned state and lifecycle

<!-- Give each owned state or resource a short subsection. Explain creation,
     sole write authority, readers/projections, transitions, persistence,
     retention, concurrency, rebuild, and deletion where applicable. If this
     owner is stateless, say whose state it depends on and why the boundary remains. -->

## Contracts and trust boundaries

<!-- Describe the three to five load-bearing contracts in prose. For each, name
     callers, the promise, validation and permission, compatibility, timeout and
     idempotency behaviour, secrets/redaction when relevant, and one stable
     surface anchor. The local `tech:<slug>` list lives in
     [the domain manifest](./_manifest.md#owned-technical-surfaces). -->

<!-- Apply the Q01-Q21 routes assigned to this owner in STATUS. Explain only the
     applicable behaviours in the nearest existing section: current limits,
     enforcement, repeated/concurrent/partial completion, observable failure,
     recovery, proof, and a resolving gap owner. -->

## Failure and recovery

<!-- Tell one representative failure from detection to recovery: correlation,
     committed state, visible effect, retry/cancel/restart or degradation,
     operator diagnosis, and proof that recovery completed. Add another scene
     only when it has a genuinely different safety or recovery boundary. -->

## Invariants, deployment, and operation

<!-- Explain the pressure behind every local invariant. Then describe the
     domain's deployment unit, configuration/secrets, scaling or concurrency,
     health signal, logs/metrics/traces, maintenance, and rollback only where
     they change its behaviour. Link the cross-owner deployment view for the
     whole-system path; do not restate that topology here. -->

## Current direction and gaps

<!-- Separate current behaviour from intended posture. Explain the operational
     or user harm of each gap and name one closure owner or next evidence. -->

## Verification and evidence

<!-- Describe the smallest check at the same observable boundary as each major
     claim, then link stable symbols, tests, traces, logs, metrics, and audit
     evidence. Line numbers may be hints but never the only anchor. Keep the
     exhaustive evidence pins in `_manifest.md` rather than duplicating them. -->

## Related owners and explicit exclusions

<!-- Route every easily-confused responsibility to its unique owner and explain
     the hand-off in one sentence. Link an optional playbook only when it owns a
     real multi-step operational branch. -->
