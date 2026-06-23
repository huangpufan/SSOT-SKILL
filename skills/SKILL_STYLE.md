# SKILL.md Style — the grill-me distillation

This file is the acceptance standard for the *prose body* of every `SKILL.md`
in this bundle. It does **not** govern frontmatter (`name`, `description`,
`metadata.protocol_version`), `references/*.md`, `assets/`, or installer
behaviour — those are mechanical contracts owned elsewhere.

The standard is reverse-engineered from Anthropic's `grill-me` skill, whose
body is ~60 words and outperforms multi-page playbooks. Read it first:

```
Interview me relentlessly about every aspect of this plan until we reach
a shared understanding. Walk down each branch of the design tree,
resolving dependencies between decisions one-by-one. For each question,
provide your recommended answer.

Ask the questions one at a time.

If a question can be answered by exploring the codebase, explore the
codebase instead.
```

That body works for five reasons. They are the five criteria below.

---

## The five criteria

A SKILL.md body passes review only if every retained sentence answers
**yes** to at least one of these — and every cut sentence answered **no**
to all of them.

### 1. Mode-switch, not manual

Does this sentence put the model into a posture it isn't in by default?

- **Keep**: "Treat any substantive edit as blocked until you've reconciled
  with STATUS.md."
- **Cut**: "1. Read SSOT/STATUS.md. 2. Check open adjudications. 3. Check
  documentation_language…" — the model already knows how to read files in
  order. The numbered list teaches nothing it doesn't already do; it just
  drowns the posture sentence.

The model has skills in its weights. SKILL.md activates one, it does not
re-teach it.

### 2. Outcome condition, not step count

Does this sentence give the model a state it can self-evaluate against?

- **Keep**: "until we reach a shared understanding", "until the routed
  reads cover this task's evidence needs"
- **Cut**: "Run steps 1–8 of the preflight checklist" — checklists are
  mechanical, the model stops when the list ends regardless of whether
  the actual goal was met.

When the model knows *what done looks like*, it self-corrects. When it
only knows *what to do next*, it walks off the end.

### 3. Structural metaphor over enumerated rules

Is there a single phrase that imports a whole semantic structure?

- **Keep**: "Walk down each branch of the design tree, resolving
  dependencies between decisions one-by-one." — one sentence loads tree
  traversal, dependency ordering, and exhaustiveness.
- **Cut**: A 14-row table that spells out which task signals map to which
  files, when the routing is just "use the project's task-entry map and
  fall back to the nearest topical area."

Use the structure-loading phrase. Move the enumeration to `references/`
for the cases that genuinely need it.

### 4. One anti-pattern guardrail per high-frequency failure

Does this rule prevent a failure mode the model actually has?

- **Keep** (grill-me): "Ask the questions one at a time." — prevents the
  model's strong default to dump a 15-question batch.
- **Keep** (grill-me): "If a question can be answered by exploring the
  codebase, explore the codebase instead." — counter-corrects the
  *interview* posture itself, which would otherwise bias toward asking
  over investigating.
- **Cut**: "Be thorough", "summarise findings", "use markdown" — the
  model defaults are already good enough; these dilute the rules that
  matter.

Every rule has activation cost and dilutes its neighbours. Spend rule
budget only where the model's default behaviour fails.

### 5. Second-person imperative, not third-person documentation

Is the body written as the prompt the user would have typed, or as a
spec describing what the skill does?

- **Keep**: "You are on preflight. Decide what to read, what to defer,
  and what durable facts to capture."
- **Cut**: "This skill is the mandatory entry point for the bundle. It
  decides whether work may proceed…" — that's documentation about the
  skill. The model reads it as *understanding a spec*, not as *acting on
  an instruction right now*.

If you can paste the body into a chat and it reads as a sensible
prompt, it's a SKILL.md body. If it only reads sensibly as README prose
about the skill, it's the wrong register.

---

## Anti-patterns specific to this bundle

These have shown up in our own SKILL.md files and are the first things
to cut on the next pass:

- **Re-declaring what `description:` already says.** The frontmatter
  description is loaded into the routing context. Repeating "Use this
  skill for X. Do not use for Y." in the body wastes the body's budget.
- **Inlining what `references/*.md` already expands.** If the detail is
  in a reference file, the body should name *when to load* the
  reference, not what it contains.
- **Step-by-step workflows that re-derive the bundle's lifecycle.** The
  bundle order (preflight → work → closeout, with bootstrap/audit/doctor
  branches) is fixed and already known after the first preflight. Each
  skill body should assume the lifecycle, not re-explain it.
- **Cross-skill routing tables longer than three rows.** Three rows is
  the threshold above which a metaphor or a single "route to the
  matching lifecycle skill" sentence beats the table.
- **Defensive prose ("Do not advance waterlines without review", "Do not
  copy source documents") repeated in every skill.** Hoist these
  invariants to a single place (`references/` or a shared invariants
  file) and let each skill link, not restate.

**Exception**: `ssot-preflight` plays a gate-and-router role for the whole
bundle, so its body legitimately keeps the routing table and a short routing
defense; other skills still target the ≤60-word ceiling.

## KISS bridge for references and templates

This file does not sentence-review `references/` or `assets/templates/`, but
they must not reverse the bundle's KISS rule. A reference table is acceptable
only when it is a lookup surface; a template table is acceptable only when it
will stay an index after instantiation. If following a reference or template
would make the consumer write paragraph-length reasoning inside cells, copy a
checklist into `STATUS.md`, or produce a document that is easier for grep than
for a cold reader, fix the reference or template first.

## Reader scaffolds (v2.51)

KISS is a *subtractive* discipline — it cuts what adds noise. The cold-reader
problem has a second axis: any reader who lands on a page also needs scaffolds
that *add* orientation — what concrete thing this owner does, which sibling
owners it gets confused with, where the boundary stops, where to go next.
"Reader scaffolds" is the additive complement. Both serve the same cold reader.

Every owner-archetype template in `assets/templates/{en,zh}/` carries six
reader-facing structural slots. Five are pre-existing (`Lead` opening, runtime
diagram, owned facts, evidence pointer, source material). Four are new in v2.51
and required on every owner README:

- **Walkthrough** — one end-to-end concrete prose example of this owner doing
  its job, not a table. Skipped with explicit `not_applicable: <reason>` only
  for purely indexical owners (e.g. `SSOT/README.md`).
- **Easily confused with** — one to three sibling owners that get confused
  with this one, each with a one-line disambiguating boundary.
- **Out of scope** — one-line statement of what this owner does NOT answer,
  plus a pointer to the owner that does. Required even when "none" (write
  `none — covers complete intent`).
- **See also** — forward-link bouquet (three to seven outbound links), each
  with a one-line hook. Once present, inline body must avoid navigation-only
  links; this section owns them.

These slots are *structural*. Doctor checks they exist (15R–15V). The
prose-before-tables, positive-definition, and cell-is-not-a-paragraph
guardrails still bind whatever fills them. A scaffold cannot smuggle in a
shadow ledger.

**Why not introduce an `archetype:` frontmatter field.** A consumer's SSOT is
already partitioned by area (product, architecture, development, testing) and
by owner role (trunk README, subsystem README, glossary entry, decision
record). Adding a Diátaxis-style `archetype:` field would force the agent to
make a third classification decision per file and would conflict with the
area model (`ssot-preflight/references/area-model.md`). The same goal is
reached by embedding scaffold slots into the existing per-archetype
templates: when `bootstrap-readme.md` is rendered from `architecture-domain-
readme.md`, the four slots are already there.

**Diagram typing.** Each Mermaid block in an architecture template carries a
`<!-- diagram_type: component | sequence | state | flow -->` HTML comment as
its first fenced-block line. One type per block — do not mix component edges
with sequence arrows in one diagram. Subsystem pages should ship a component
diagram in the first screen, before any table. Doctor `15U [DIAGRAM-TYPE-TAG]`
and `15V [DIAGRAM-FIRST]` track this.

**KISS bridge update — mini-card permitted form for first-mention canonical
vocabulary.** Doctor `15F [VOCAB-PROSE-FORK]` keeps the single-prose-owner
rule for canonical vocabulary (each term has exactly one prose owner —
`glossary/<term>.md`). v2.51 carves out one explicit inline aid for
first-mention readability without violating that rule:

```
**Term** (def: <one clause ≤ 15 words> → [CORE-REF: glossary/<term>.md])
```

This mini-card is **permitted**, not required. The glossary entry is still
the owner. The mini-card is bounded to one clause and one anchor; a second
prose sentence, a state-transition clause, or any further explanation falls
back under 15F and must move to the glossary owner. Use the mini-card only
on first mention in a consuming owner; later mentions in the same file use
the bare term plus optional link.

---

## Review procedure

When opening a PR that rewrites a `SKILL.md` body:

1. Paste the **before** body and **after** body side by side in the PR
   description.
2. For every sentence in **after**, annotate which of criteria 1–5 it
   passes.
3. For every sentence cut from **before**, annotate which criterion it
   failed (or which `references/*.md` now owns the detail).
4. Reviewer rejects any retained sentence that fails all five criteria,
   and any cut sentence whose detail was lost rather than relocated.

The goal is not minimum word count. The goal is that every retained
sentence earns its activation cost.

---

## Out of scope

This file does not change:

- `description:` frontmatter (routing-critical, follow Anthropic's
  description guidance separately).
- `metadata.protocol_version` and the VERSION/CHANGELOG bump rules in
  `CONTRIBUTING.md`.
- `references/*.md` length or structure — references are *loaded on
  demand* and may stay as long as they need to be.
- `assets/`, `agents/`, scripts, templates, tests.

It only standardises the prose body the model reads every time the
skill activates.
