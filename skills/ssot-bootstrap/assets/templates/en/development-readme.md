# Development Workflow

<!-- Writing style: implementation-delegator. Start with the change situation
     and decision, then path, outcome/recovery, commands, and evidence. -->

<!-- Completeness authority: reader-quality.md C01-C09, PR01-PR16, and applicable
     Q01-Q21. Covered process owners use the exact strategy and finite-asset
     contract; give a reason/evidence pointer for every not_applicable item. -->

> This area records how to run the project and the development conventions new Agents must follow when writing code. Only long-lived semantics, prerequisites, and risks are recorded here; the full script source remains in the repository.

## When and for whom

<Explain in plain language which contributor uses this process, what change or
symptom triggers it, the required repository/runtime environment, and which
role or permission is needed. Give one concrete first-day scenario.>

## Why this development method

<Explain the strategy before the steps: which conventions and invariants keep
changes coherent, why this repository uses this sequence, what constraint or
past failure rules out the nearest alternative, which trade-off is accepted,
and what evidence would justify changing the method.>

## Canonical path and branches

<Tell the ordered development path as a short story: prepare inputs, start the
right services, make the change, choose between important branches or
exceptions, and name any state-changing or irreversible side effect. Explain
repeat, concurrent, and partial-completion behaviour when it changes safety
(PR14), and route applicable Q01-Q21 checks through STATUS.>

## Output and acceptance

<Name the observable artifact or result and the checks that make it acceptable.
A command existing is not acceptance; say what a successful result looks like.>

## Failure, recovery, and handoff

<Explain how failure is detected, when to stop, what may be retried or rolled
back, what cannot be reversed, and which owner receives an escalation.>

## Reproduce and keep current

<Give the canonical reproducible command path, its evidence source, current
versus target posture, and the file/event that invalidates this process.>

## Development at a Glance / Reader Map

| Reader question | First stop | Authoritative owner | Evidence direction | Stop condition / risk |
|---|---|---|---|---|
| How do I start local development? | [Local run](#local-run) | this file | package.json / Makefile / Dockerfile / docs | |
| Which scripts/tools are commonly used and have prerequisites? | [Scripts / tool inventory](#scripts--tool-inventory) | scripts directory | scripts directory / CI / Makefile | |
| Which code patterns must I follow when adding features? | [Pattern language](#pattern-language) | this file | code review / lint config / examples | |

## Local Run

Use a short narrative to describe this repository's development path: how dependencies are installed, how services are started, which steps must occur in order.

| Scenario | Command | Purpose | Required setup | Evidence | Known risk |
|---|---|---|---|---|---|
| | | | | package.json / Makefile / Dockerfile / docs | |

## Scripts / Tool Inventory

> This is the finite inventory of stable scripts and tools the development
> process creates, reads, changes, verifies, hands off, or retires. Do not copy
> source. List every real asset once. If none exists, delete the sample row and
> write: `No stable assets: reason=<specific reason>; owner=[responsible owner](<resolving-path>); review when=<observable event>.`

| Asset | Class | Purpose | Selection rule | Owner | Evidence | Risk | Retirement or replacement trigger |
|---|---|---|---|---|---|---|---|
| | script / tool / build / dev-server / codegen / lint-format / diagnostics / other | | | | | | |

## Pattern Language

> Only record coding conventions that linters/formatters cannot automatically enforce and that new Agents are likely to violate.

| Pattern | When to use | Why it matters | Evidence | Risk |
|---|---|---|---|---|
| | | | | |

## End-to-End Skeleton Flow

| Feature type | Authoritative locations to touch | Representative example | Verification | Risk |
|---|---|---|---|---|
| | | | | |

## Open Gaps

| Gap / unknown | Required evidence | Blocking level |
|---|---|---|
| | | blocking / non-blocking |
