# Architecture Views

> Writing style: any cold reader. See `ssot-bootstrap` §3.7.

> Cross-domain architecture views. Views synthesize across domains and absorb technical system goals, operating philosophy, runtime journeys, and implementation current/target/gap from source material; concrete ownership, contracts, state, and recovery details must be routed to domains. Product promises, capabilities, journeys, and product acceptance are owned by `product/`; views only link to the product owner and record implementation design or gaps.
>
> Views are the SSOT design intent layer and must contain narrative design thinking, not just tables.

## View Index

| View | Path | Authoritative responsibility | Source material input | Evidence / status |
|---|---|---|---|---|
| Operating model | [operating-model.md](./operating-model.md) | Technical mission, operating philosophy, principles, implementation priorities, technical non-goals, technical actors, primary operating paths | product owner links, design docs, root README, high-level architecture docs | |
| Critical journeys | [critical-journeys.md](./critical-journeys.md) | Runtime journeys, phase lifecycle, failure/recovery, observability signals | product journey links, design walkthroughs, runbooks, source-code traces | |
| Current / Target / Gap | [current-target-gap.md](./current-target-gap.md) | Implemented state vs. target design, migration stance, implementation gaps, implementation gaps against product acceptance, adjudication pointers | product roadmap/acceptance links, ADR, design docs, source material, code evidence | |

## Cross-Domain At-a-Glance Map / Reader Map

> The entry map of Views does only routing; it does not carry independent long-lived facts. Concrete design intent, journeys, and gaps must go into the corresponding view body; state/resource/contract/recovery details continue down to domains.

| Reader question | First stop | Authoritative owner | Evidence direction | Stop condition / risk |
|---|---|---|---|---|
| Understand how product constraints shape technical design and what is prioritized technically | [operating-model.md](./operating-model.md) | operating-model view + product owner | domains / decisions / product | Principles link to domain owners that enforce them; product facts remain in product |
| Understand which end-to-end paths decide whether the system is usable | [critical-journeys.md](./critical-journeys.md) | critical-journeys view | domains / tests | Every phase has a domain owner responsible for state/contract/recovery |
| Distinguish current implementation, target design, and migration gap | [current-target-gap.md](./current-target-gap.md) | current-target-gap view | domains / decisions / tech-debt | Each concrete gap links to a domain/decision/debt/adjudication owner |

## View Rules

- A view cannot be only tables. It must have a `Why this view exists` / narrative section explaining design intent.
- Views answer cross-domain questions and synthesize system intent, journeys, and gaps from domain evidence; domains own detailed state/resource, contracts, invariants, failure recovery, and verification.
- A view may contain overview Mermaid diagrams when they clarify whole-system journeys.
- Views must link to the domain owners responsible for concrete state/resource/contract/failure details.
- Views must separate current facts from target design. Current claims require code/config/schema/test/runtime evidence; target claims require decision, ADR, issue, or conversation evidence.
- When PRD/product material contains current product priorities, product non-goals, and product acceptance, product must absorb them first; operating-model only records the technical response.
- Critical-journeys must absorb runtime execution, failure/recovery, and observability signals, not just list happy-path flow names; user touchpoints and product acceptance link to the product journey owner.
- Current-target-gap must explain the migration stance and partially landed intent, not just list gap rows.
- Reader Map, topic candidates, and evidence links must come from architecture decomposition, reader questions, and repository evidence; each view must add design intent, why, constraints, risks, and authoritative owner; Reader Maps do not carry independent long-lived facts and external topic trees must not be treated as the view structure itself.

## Source Material Routing

| Source-material content | Target view | Domain / satellite area follow-up |
|---|---|---|
| Product positioning, product goals, product priorities, product non-goals, product acceptance | `../product/` owner | Architecture views link to the product owner without duplicating facts |
| Technical system positioning, implementation priorities, technical non-goals, operating philosophy, primary technical actors, non-functional success criteria | [operating-model.md](./operating-model.md) | Link to domains enforcing these principles and to the relevant product owner |
| Runtime primary paths, phase lifecycles, failure/recovery, observability signals | [critical-journeys.md](./critical-journeys.md) | Link to domains owning each phase/state/resource/recovery |
| Implementation current/target/gap, migration goals, design gaps, implementation gaps against product acceptance | [current-target-gap.md](./current-target-gap.md) | Link to product owner, decisions, domains, open adjudication items |
| Candidate leads from externally generated diagrams, screenshots, dependency graphs, or auto summaries | After cross-verification only, route semantically into operating-model / critical-journeys / current-target-gap | Script inventories default to repository scripts, manifests, CI, and config; architecture behavior then links to domains |

## Open View Gaps

| View | Gap / unknown | Required evidence | Blocking level |
|---|---|---|---|
| | | | blocking / non-blocking |
