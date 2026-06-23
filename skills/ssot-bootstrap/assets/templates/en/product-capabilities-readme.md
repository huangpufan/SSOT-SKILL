# Product capability index

> Writing style: any cold reader. See `ssot-bootstrap` §3.7.

> Capability owner index. Do not duplicate capability fact content in this file.

## Split criteria

Before creating `capabilities/<capability>.md`, at least one stable product-boundary signal must hold:

- Durable user value and independent product boundary.
- Independent non-goals, acceptance meaning, or roadmap state.
- Keeping it in `prd.md` or `product-model.md` would make the spine hard to read.

Do not create a capability file for a one-off feature, ticket, UI script, test case, or implementation flow.

## Capability owner index

| Capability | Owner | Why separate | Product status | Acceptance link | Architecture link |
|---|---|---|---|---|---|
| | `<capability>.md` | | current / target / gap / obsolete | [../roadmap-and-acceptance.md](../roadmap-and-acceptance.md) | [../../architecture/README.md](../../architecture/README.md) |

## Rejected splits

| Candidate | Why not separate | Current owner |
|---|---|---|
| | | [../prd.md](../prd.md) / [../product-model.md](../product-model.md) |
