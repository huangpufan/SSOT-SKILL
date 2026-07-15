# <Term>

<!-- Writing style: implementation-delegator. Every section opens with plain
     prose before
     tables; tables are indexes, not paragraphs. Follow reader-quality.md. -->

<!-- Completeness authority: reader-quality.md C01-C09, G01-G08, and applicable
     Q01-Q21 vocabulary. Include a positive definition, consequence,
     example/non-example, owner, related scope, and
     invalidation direction. Glossary coverage is governed by Area Status and
     a semantic stop review; per-file intent_recovery is product/architecture-only. -->

**One-sentence definition**: <≤ 25 words, positively defined; do not introduce the term with "X is not Y" first>.

## Extended definition

<one paragraph; required when one sentence is insufficient to convey the term's full scope, lifecycle, or constraints>

## Why it matters

<Explain which reader decision, product promise, runtime boundary, process
gate, or record interpretation changes when this term is understood correctly.>

## Example and non-example

- **Example** — <one concrete repository scene where the term applies>.
- **Non-example** — <the nearest plausible case that does not qualify, and why>.

## Used in

- `<area>/<file>` § <section> — <one line: why this term matters in that location>
- `<area>/<file>` § <section> — <one line>

## Not to be confused with

- **<Sibling term>** — <one-line distinction; positive definition of the boundary>
- **<Sibling term>** — <one-line distinction>

<!-- G07: record the canonical spelling and, when they differ, aliases or
     acronyms, user-visible label, machine token, and translation constraint.
     Explain which form a person should use before listing machine forms. -->

## Source pin

- `[CORE-REF: <area>/<file>.md#anchor]` — <where the underlying product,
  architecture, process, record, schema, or contract fact named by this term is
  maintained; this is not a second term definition>
- `path:src/myapp/...:LNN` or `tests/...::test_*` — <code/test pin if the term is implemented in code>

## Scope and invalidation

<Name related terms; confirm that this glossary entry is the only prose
definition; and name the code/schema/decision change that requires this
definition and the documents or features that use it to be reviewed.>

## Term lifecycle

<State `active`, `deprecated`, or `retired`. For a deprecated or retired term,
name its replacement, the migration direction, and the event that completes
retirement.>

<!--
Template notes (v2.51):

1. This is the dedicated-file form. Existing README/topic aggregation may use
   one unique H2 anchor per term; the family inventory links that exact anchor.
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
