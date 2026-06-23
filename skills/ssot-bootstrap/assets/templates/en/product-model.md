# Product model

> Writing style: any cold reader. See `ssot-bootstrap` §3.7.

> This file owns users, problems, product promises, product boundary, product language, and long-term product tradeoffs.

## Users and the world they live in [MUST]

Use 1–3 paragraphs of prose to describe the real users/operators: the work they do, what a typical day looks like, the two or three pains they feel most sharply today. You may include 2–3 sentences of a concrete dialogue or scene ("the on-call engineer woken up at 3 a.m. by a pager …").

## What we promise and what we do not [MUST]

Use 1–2 paragraphs of prose to walk through the core promise in plain language: "for the users in the section above, here is what we commit to keep stable, and here is what we explicitly refuse to commit to".

Define each new term positively the first time it appears: "X, in this product, means …". Then let the promise / boundary tables below act as precise comparison; the tables are an index to this prose, not a replacement for it.

## Users and operators

| User / operator | Goal | Pain points / risk | Evidence |
|---|---|---|---|
| | | | |

## Problems

| Problem | Why it matters | Current handling | Evidence |
|---|---|---|---|
| | | | |

## Product promise

| Promise | User-visible meaning | What is not promised | Owner / evidence |
|---|---|---|---|
| | | | |

## Product boundary

| Boundary | In scope | Out of scope | Why / tradeoff |
|---|---|---|---|
| | | | |

## Product language

| Term | Product meaning | Avoid saying | Evidence |
|---|---|---|---|
| | | | |

## Long-term product tradeoffs

| Tradeoff | Chosen side | Rejected side | Why / revisit condition |
|---|---|---|---|
| | | | |

## Architecture owner links

| Product constraint | Architecture owner | Implementation gap |
|---|---|---|
| | [../architecture/README.md](../architecture/README.md) | |
