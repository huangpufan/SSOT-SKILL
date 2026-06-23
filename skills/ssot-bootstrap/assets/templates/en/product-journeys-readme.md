# Product journey index

> Writing style: any cold reader. See `ssot-bootstrap` §3.7.

> Product journey owner index. Do not duplicate journey fact content in this file. Architecture critical journeys own runtime execution, lifecycle, failure/recovery, observability and diagrams.

## Split criteria

Before creating `journeys/<journey>.md`, at least one stable product-boundary signal must hold:

- The journey crosses multiple capabilities.
- The journey affects roadmap/release decisions.
- The journey has independent product acceptance.
- The journey repeatedly drives priority tradeoffs.

Do not create a journey file for an implementation flow, test script, single UI path, or one-off ticket.

## Journey owner index

| Journey | Owner | Why separate | Product acceptance | Capability links | Architecture runtime link |
|---|---|---|---|---|---|
| | `<journey>.md` | | [../roadmap-and-acceptance.md](../roadmap-and-acceptance.md) | | [../../architecture/views/critical-journeys.md](../../architecture/views/critical-journeys.md) |

## Rejected splits

| Candidate | Why not separate | Current owner |
|---|---|---|
| | | [../prd.md](../prd.md) / [../product-model.md](../product-model.md) |
