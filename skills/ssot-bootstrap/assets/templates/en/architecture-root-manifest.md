---
manifest_archetype: architecture-root
intent_recovery: gap
---
# Architecture recovery manifest

<!-- Render this template as 02-architecture/_manifest.md. It recovers the
     architecture shape and evidence; the system explanation stays in the root,
     views, and domains. Replace gap rows before claiming covered. -->

## Architecture trunk coverage

| Required architecture question | Narrative owner | Coverage | Evidence | Closure action |
|---|---|---|---|---|
| Current request-to-result story and system context | [Architecture root](./README.md) | gap | missing | Trace one real current path from entry to visible result |
| Runtime owners and boundary rationale | [Architecture root](./README.md) | gap | missing | Verify state, lifecycle, contract, and failure ownership |
| Cross-owner flow, state, trust, recovery, and evolution | [Architecture views](./views/README.md) | gap | missing | Complete every applicable view question class |
| Detailed runtime truth | Domain READMEs | gap | missing | Link every runtime owner to one domain |
| Global invariants and their pressure | [Architecture root](./README.md) | gap | missing | Verify enforcement across all affected owners |

## Unique surface ownership

| Surface class | Owning domain | Overlap check | Stable evidence |
|---|---|---|---|
| Public routes and protocols | unresolved | not-run | Map each surface to one runtime owner |
| Durable stores and write operations | unresolved | not-run | Map each write to one authoritative owner |
| User-visible runtime components and commands | unresolved | not-run | Map each applicable surface to one owner |

## Current, target, and gap coverage

| Scope | Current owner | Target owner | Open-gap owner | Evidence |
|---|---|---|---|---|
| Global implementation evolution | [Current, target, and gap](./views/current-target-gap.md) | [Current, target, and gap](./views/current-target-gap.md) | unresolved | Verify current claims before adopting target design |

## Cold-reader evidence

| Review | Status | Score | Evidence |
|---|---|---|---|
| Architecture teach-back with tables hidden | needs-review | not-scored | Record an independent review before claiming covered |
