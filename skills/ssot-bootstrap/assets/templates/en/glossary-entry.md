---
intent_recovery: covered
---

# <Term>

> Writing style: any cold reader. Every section opens with prose before tables;
> tables are indexes, not paragraphs. See `ssot-bootstrap` §3.7.

**One-sentence definition**: <≤ 25 words, positively defined; do not introduce the term with "X is not Y" first>.

## Extended definition

<one paragraph; required when one sentence is insufficient to convey the term's full scope, lifecycle, or constraints>

## Used in

- `<area>/<file>` § <section> — <one line: why this term matters in that location>
- `<area>/<file>` § <section> — <one line>

## Not to be confused with

- **<Sibling term>** — <one-line distinction; positive definition of the boundary>
- **<Sibling term>** — <one-line distinction>

## Source pin

- `[CORE-REF: <area>/<file>.md#anchor]` — <which authoritative owner originally defines this>
- `path:src/myapp/...:LNN` or `tests/...::test_*` — <code/test pin if the term is implemented in code>

<!--
Template notes (v2.51):

1. One file per term; one term per file. Multi-term glossary stays in
   `glossary/README.md` as the directory map index.
2. Positive definition is enforced by Doctor 14I (a cell is not a paragraph)
   and 15F (`[VOCAB-PROSE-FORK]`). Negative definition belongs in
   `## Not to be confused with`, not in the headline.
3. `## Used in` is the inverse index: readers who land here jump to the
   non-glossary owners that consume this term.
4. KISS mini-card permitted form (v2.51, see `SKILL_STYLE.md`): inside the
   consuming owner's prose, the term may appear as
   `**Term** (def: <≤ 15-word clause> → [CORE-REF: glossary/<term>.md])`
   without violating 15F.
-->
