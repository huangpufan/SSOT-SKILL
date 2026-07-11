# SSOT

> The repository's durable memory. Start with the product need, follow the
> system response, and check the current waterline before changing the repo.

<!-- Replace the next line with one sentence: what this repository is, who it
     serves, and the result it creates. Do not copy the product or architecture
     owner bodies into this routing page. -->

<one-sentence repository positioning>

## Repository map

```text
SSOT/
├── 01-product/          User needs, current surfaces, journeys, and acceptance
├── 02-architecture/     System response, runtime owners, flows, state, and trust
├── 03-process/          Development, testing, benchmark, release, and deployment
├── 04-records/          Decisions, bugs, debts, gotchas, and research packets
├── glossary/            Repository-specific terms
├── STATUS.md            Waterlines, coverage, adjudications, and visible gaps
└── README.md            This reader route
```

The map answers where to begin, not the question itself. Each child README
explains its boundary and routes to the unique owner of the detailed fact.

## First-day reading order

1. **Positioning** — read this page's positioning and map so you know which
   kind of owner can answer your question.
2. **Product** — read [01-product/README.md](./01-product/README.md) to learn
   who the product serves, what people can use today, and what success means.
3. **Architecture** — read
   [02-architecture/README.md](./02-architecture/README.md) to follow the
   current request-to-result story and locate runtime owners.
4. **Task owner** — follow the relevant architecture view/domain, process
   owner, or durable record; read only the branch your task needs.
5. **Waterline** — read [STATUS.md](./STATUS.md) immediately before acting to
   check protocol/coverage waterlines, open adjudications, and visible gaps.

## Question-to-owner map

| Reader question | First owner | Evidence direction |
|---|---|---|
| What does the product promise, limit, and accept? | [Product](./01-product/README.md) | Current product surfaces, acceptance evidence, and user source material |
| How does the current system deliver that promise? | [Architecture](./02-architecture/README.md) | Runtime traces, code, schema, config, and tests |
| How should I develop or verify a change? | [Process](./03-process/README.md) | Commands, CI, test strategy, benchmark policy, and release/deployment rules |
| What prior decision, bug, debt, or trap affects this work? | [Records](./04-records/README.md) | Lifecycle entries and their evidence/closure owners |
| What does a repository-specific term mean? | [Glossary](./glossary/README.md) | Canonical definition and unique owner pointer |

Product explains the user-facing intent; architecture explains the technical
response. Process files tell contributors how to work, while records preserve
why a durable exception or decision exists. Do not maintain the same fact in
two of these areas.

## Task-entry shortcuts

<!-- Keep this section only when repeated task clusters justify shortcuts.
     Every row is a pointer; the destination remains the fact owner. -->

| Task cluster | Trigger | Read first | Final check |
|---|---|---|---|
| <repeated task class> | <path, capability, or failure signal> | <owner link> | <gate or evidence owner> |
