---
manifest_archetype: architecture-views
intent_recovery: gap
---
# Architecture views recovery manifest

<!-- Writing style: implementation-delegator. Route from a recognisable
     cross-owner question to its plain-language narrative and current proof. -->

<!-- Render this template as 02-architecture/views/_manifest.md. Keep one row
     for each applicable cross-owner question. A merged or inapplicable view
     needs a reason and a narrative owner. -->

## Cross-owner question coverage

| Question class | Narrative owner | Coverage | Evidence or closure |
|---|---|---|---|
| Pressures, priorities, trade-offs, and technical non-goals | [Operating model](./operating-model.md) | gap | Verify against product constraints, decisions, and domains |
| Current request-to-result paths and visible outcomes | [Critical journeys](./critical-journeys.md) | gap | Trace load-bearing current journeys across owners |
| State ownership, transitions, retention, rebuild, and recovery | [State and data lifecycle](./state-and-data-lifecycle.md) | gap | Verify schema, storage, projections, and recovery |
| Contracts, authentication, permissions, secrets, and redaction | [Contracts and trust boundaries](./contracts-and-trust-boundaries.md) | gap | Verify public and internal trust boundaries |
| Detection, retry, cancellation, restart, degradation, and diagnosis | [Failure and recovery](./failure-and-recovery.md) | gap | Exercise representative cross-owner failures |
| Runtime topology, change delivery, configuration, health, telemetry, and rollback | [Deployment and observability](./deployment-and-observability.md) | gap | Verify the running topology and exercise representative diagnosis and recovery |
| Current implementation, intended design, and named gaps | [Current, target, and gap](./current-target-gap.md) | gap | Link current evidence, decisions, and closure owners |
| Applicable Q01-Q21 behaviour across owners | Owner links from [STATUS](../../STATUS.md#quality-risk-and-governance) | gap | Synthesize only where no single domain can explain the current behaviour |

## View-to-domain consistency

| Sampled view claim | Unique domain owners | Consistency result | Evidence |
|---|---|---|---|
| No claim sampled yet | unresolved | needs-review | Sample each view before claiming covered |

## Cold-reader evidence

<!-- Render `reader-review.md` under `SSOT/.bootstrap/` after every applicable
     question class has a narrative owner. -->

| Review scope | Artifact | Score | Critical truth errors | Unresolved required changes | Verdict |
|---|---|---|---|---|---|
| Cross-owner view teach-back with tables hidden | `SSOT/.bootstrap/<review-file>.md` | not-scored /32 | not-counted | not-counted | needs-review |
