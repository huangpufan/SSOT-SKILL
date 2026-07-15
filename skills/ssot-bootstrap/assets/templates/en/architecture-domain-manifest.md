---
manifest_archetype: architecture-domain
owner_id: "owner:<slug>"
intent_recovery: gap
---
# Runtime-owner recovery manifest

<!-- Writing style: implementation-delegator. Keep cells pointer-sized and link
     to the ordinary-language current-flow explanation before technical labels. -->

<!-- Render this template beside a domain README. It stores local recovery pins
     and technical-surface rows; the mental model and causal story stay in
     README.md. owner_id must match the architecture-root registry. -->

## Boundary and runtime coverage

| Required owner question | Unique narrative owner | Coverage | Stable evidence or closure |
|---|---|---|---|
| Boundary, callers, responsibility, and exclusions | [Domain README](./README.md) | gap | Verify against the current runtime path |
| Owned state, resources, and lifecycle | [Domain README](./README.md) | gap | Link stable schema, storage, or resource anchors |
| Load-bearing contracts and trust boundaries | [Domain README](./README.md) | gap | Link stable route, protocol, schema, or selector anchors |
| Canonical current flow and visible outcome | [Domain README](./README.md) | gap | Link stable symbols plus runtime or integration evidence |
| Representative failure and recovery | [Domain README](./README.md) | gap | Link correlation evidence and a regression check |
| Invariants, deployment, observation, and local evolution | [Domain README](./README.md) | gap | Link enforcement, runtime topology, telemetry, decisions, and named gaps |
| Applicable Q01-Q21 enforcement, limits, and recovery | Product/architecture routes from [STATUS](../../STATUS.md#quality-risk-and-governance) | gap | Link local enforcement and evidence, or a resolving gap owner |

## Owned technical surfaces

<!-- Copy only the surfaces uniquely owned by this domain from the root unique
     architecture surface registry. Allowed kinds are exactly `entry`,
     `write-store`, `contract`, `operator-surface`, and `external-integration`.
     IDs and facts must match; shared callers/readers belong in prose, not as
     duplicate owners. -->

| Technical surface ID | Surface kind | Narrative owner | Current state | Stable anchor | Evidence or closure |
|---|---|---|---|---|---|
| `tech:<slug>` | entry / write-store / contract / operator-surface / external-integration | [Domain README](./README.md) | gap | | Reconcile with the root unique registry |

## Stable evidence pins

| Claim | Stable anchor | Evidence kind | Verification status |
|---|---|---|---|
| Domain evidence not yet recorded | README.md | static | missing |

## Document invalidation and retirement

| Condition | Detection | Recovery or retirement action | Owner |
|---|---|---|---|
| Runtime boundary, write owner, public contract, deployable unit, or operational surface changes | Review changed symbols and current traces | Update the domain, root surface registry, and affected cross-owner views in the same change | Domain maintainer |
| Domain no longer has an independent state, contract, lifecycle, or failure boundary | Architecture owner review | Merge facts and surface rows into the surviving owner and replace links atomically | Architecture maintainer |

## Cold-reader evidence

| Review scope | Artifact | Score | Critical truth errors | Unresolved required changes | Verdict |
|---|---|---|---|---|---|
| Domain normal/failure/boundary teach-back with tables hidden | `SSOT/.bootstrap/<review-file>.md` | not-scored /32 | not-counted | not-counted | needs-review |
