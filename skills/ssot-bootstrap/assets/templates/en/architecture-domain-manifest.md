---
manifest_archetype: architecture-domain
intent_recovery: gap
---
# Runtime-owner recovery manifest

<!-- Render this template beside a domain README. It stores stable recovery pins
     and document lifecycle conditions; the runtime mental model and causal
     story stay in README.md. Replace gap rows before claiming covered. -->

## Boundary and runtime coverage

| Required owner question | Narrative owner | Coverage | Stable evidence or closure |
|---|---|---|---|
| Boundary, callers, responsibility, and exclusions | [Domain README](./README.md) | gap | Verify against the current runtime path |
| Owned state, resources, and lifecycle | [Domain README](./README.md) | gap | Link stable schema, storage, or resource anchors |
| Load-bearing contracts and trust boundaries | [Domain README](./README.md) | gap | Link stable route, protocol, schema, or selector anchors |
| Canonical current flow and visible outcome | [Domain README](./README.md) | gap | Link stable symbols plus runtime or integration evidence |
| Representative failure and recovery | [Domain README](./README.md) | gap | Link correlation evidence and a regression check |
| Invariants, operations, and local evolution | [Domain README](./README.md) | gap | Link enforcement, decisions, and named gaps |

## Stable evidence pins

| Claim | Stable anchor | Evidence kind | Verification status |
|---|---|---|---|
| Domain evidence not yet recorded | README.md | static | missing |

## Document invalidation and retirement

| Condition | Detection | Recovery or retirement action | Owner |
|---|---|---|---|
| Runtime boundary, write owner, or public contract changes | Review changed symbols and current traces | Update the domain and affected cross-owner views in the same change | Domain maintainer |
| Domain no longer has an independent state, contract, lifecycle, or failure boundary | Architecture owner review | Merge facts into the surviving owner and replace links atomically | Architecture maintainer |

## Cold-reader evidence

| Review | Status | Score | Evidence |
|---|---|---|---|
| Domain normal/failure/boundary teach-back with tables hidden | needs-review | not-scored | Record review before claiming covered |
