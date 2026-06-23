# Capability: <Capability Name>

<!-- Optional template. Instantiate only when a capability has durable product value, boundaries, non-goals, acceptance meaning, or roadmap state that would bloat the product spine. -->

> Writing style: any cold reader. See `ssot-bootstrap` §3.7.

## Tell this capability in one breath [MUST]

Write three layers in order:

1. **One-sentence summary**: in plain language, what this capability means to the user ("X lets a certain kind of user, in situation Y, do Z").
2. **One concrete scene**: in 2–4 sentences, describe a concrete usage scene ("imagine a user at the moment they …") so a reader who has never seen the product immediately gets a picture.
3. **Why an independent owner**: in 1–2 paragraphs, explain why its product boundary deserves to be split out of the spine and maintained independently (durable user value / independent non-goals / independent acceptance / independent roadmap state). If the reason is only "we wanted to write it up at length", merge it back into the spine.

## Product boundary

| In scope | Out of scope | Why |
|---|---|---|
| | | |

## User value

| User / operator | Value | Evidence |
|---|---|---|
| | | |

## Acceptance meaning

| Acceptance | Product meaning | Evidence / testing link |
|---|---|---|
| | | |

## Roadmap state

| Phase | Status | Notes |
|---|---|---|
| | planned / active / deferred / shipped / obsolete | |

## Architecture owner links

| Product constraint | Architecture owner | Implementation gap |
|---|---|---|
| | | |

## Capability → Surface registry

Mirrors `ssot-preflight/references/architecture.md` §16 on the product side; pins each surface this capability lands on. A `contract`-state row that does not name a Playwright test is doctor-blocked (CLAUDE-MAXIM-2: jsdom is not browser evidence).

| Surface | Route or module | Component | Test | state |
|---|---|---|---|---|
