# Development Workflow

> Writing style: any cold reader. See `ssot-bootstrap` §3.7.

> This area records how to run the project and the development conventions new Agents must follow when writing code. Only long-lived semantics, prerequisites, and risks are recorded here; the full script source remains in the repository.

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

> If a scripts directory, package manifest, CI, Makefile, or tool entry in config exists, absorb it semantically. Do not copy script source; only record purpose, when to use, evidence, and risk. If no such scripts exist, write `not_applicable` and the reason.

| Filename | Purpose | Category | When to use | Evidence | Risk or prerequisite | Architecture link if any |
|---|---|---|---|---|---|---|
| | | build / dev-server / codegen / lint-format / diagnostics / other | | | | |

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
