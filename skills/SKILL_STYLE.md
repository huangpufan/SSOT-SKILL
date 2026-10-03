<!-- SSOT-SKILL bundle companion; owned by install.sh -->

# SKILL.md Style — task-complete entrypoints

This file governs the prose body of this bundle's `SKILL.md` files.
Frontmatter, references, templates, scripts, and installer contracts retain
their own owners. The goal is the shortest reliable path through the task,
not a fixed word count or a single prompting style.

## Keep the decisions the skill must make

A useful entrypoint lets an agent select the applicable branch, find its
instructions, respect its boundaries, and recognise when the work is done.
Evaluate each sentence against these five purposes:

1. **Purpose and outcome.** State the useful result and its completion
   condition. A posture such as "reconcile the whole batch" can help, but
   cannot replace the evidence needed to decide that reconciliation holds.
2. **Routing.** Keep the branch choice and a resolving reference with a clear
   loading condition. A skill may be invoked directly without a prior
   preflight; do not assume another skill's contents are already in context.
3. **Essential procedure.** Keep an ordered step where order affects safety
   or correctness, or where the operation is specific to this protocol.
   Generic file-reading instructions can go; a required baseline check or
   write-before-advance dependency cannot disappear merely because it is a
   checklist.
4. **Boundaries and recovery.** Preserve non-obvious permission, ownership,
   evidence, and failure rules. Explain the allowed next action when a gate
   cannot clear. Route shared detail to its unique owner without hiding a
   boundary that the agent needs before selecting the route.
5. **Useful knowledge.** Preserve distinctions, examples, and caveats that
   change decisions. Move branch-specific detail to references when doing so
   reduces unrelated reading; keep the reference reachable at its use site.

Use direct instructions where action is needed and explanatory prose where
it makes a distinction understandable. Structural metaphors, tables, and
numbered steps are tools, not mandatory or forbidden forms. A small routing
table can be clearer than a compressed metaphor even when it has more than
three rows.

## Compression without loss

Remove duplicate authority, generic advice, and material unrelated to the
skill's task. Before cutting a rule or reference, inspect its callers and
identify where its useful meaning will remain. Do not assume protocol
knowledge is present in model training or that a short unrelated skill's
length proves the right budget for this workflow.

There is no 60-word ceiling. Keep every entrypoint as short as its actual
branches permit; longer text must earn its place through a decision, useful
context, or necessary recovery path. `ssot-preflight` carries the shared gate
and router; other skills still need enough context to work when selected
independently. Detailed manuals belong in references with explicit read
conditions, not behind vague instructions to "follow the protocol".

## KISS bridge for references and templates

This file does not sentence-review `references/` or `assets/templates/`, but
they must not reverse the bundle's KISS rule. A reference table is acceptable
only when it is a lookup surface; a template table is acceptable only when it
will stay an index after instantiation. If following a reference or template
would make the consumer write paragraph-length reasoning inside cells, copy a
checklist into `STATUS.md`, or produce a document that is easier for grep than
for a cold reader, fix the reference or template first.

### Authority-alignment rule (v2.60)

Shared semantic vocabularies and scoring rubrics have one protocol owner.
Consumer references state the question they need answered and link that owner;
they do not copy an enum or create a near-synonym set for convenience. In
particular, `ssot-preflight/references/reader-quality.md` alone owns product
maturity, product evidence fidelity, the cold-reader dimensions, and the
`Q01`-`Q21` quality/risk/governance profile. Product templates never borrow
architecture lifecycle states, and individual areas do not invent a smaller
quality checklist. The task harness in
`ssot-doctor/references/cold-agent-sim.md` owns review execution and artifact
shape, not the meaning of the dimensions.

When a reference or template changes a reader-facing contract, inspect a
rendered consumer surface through the task-based cold review. A compact source
diff is not evidence that the generated prose remains understandable,
locally-routed, or consistent across owners.

The default consumer is an implementation delegator, not a source-code reader.
Lead with the scene, decision, delegated action, observable result and evidence,
then the stop or escalation boundary. Define unavoidable repository terms
before using them as explanation. Exact symbols and commands preserve
precision after that ordinary-language model; they do not replace it.

## Reader scaffolds (v2.51; de-checklisted v2.59)

KISS is a *subtractive* discipline — it cuts what adds noise. The cold-reader
problem has a second axis: any reader who lands on a page also needs scaffolds
that *add* orientation — what concrete thing this owner does, which sibling
owners it gets confused with, where the boundary stops, where to go next.
"Reader scaffolds" is the additive complement. Both serve the same cold reader.

Every owner must carry four **semantic roles** in its reader path. They may be
combined under natural headings; they are not a universal heading checklist:

- **Walkthrough** — one end-to-end concrete prose example of this owner doing
  its job, not a table. Skipped with explicit `not_applicable: <reason>` only
  for purely indexical owners (e.g. `SSOT/README.md`).
- **Boundary disambiguation** — one to three sibling owners that get confused
  with this one, each with a one-line disambiguating boundary.
- **Out-of-scope routing** — what this owner does not answer,
  plus a pointer to the owner that does. Required even when "none" (write
  `none — covers complete intent`).
- **Next-owner routing** — a small set of outbound owner links with a reason
  to follow each one.

Doctor checks whether the reader can recover these meanings (15R–15T), not
whether exact English H2 headings exist. The prose-before-tables,
positive-definition, and cell-is-not-a-paragraph guardrails still bind the
result. A scaffold cannot smuggle in a shadow ledger.

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
`%% diagram_type: component | sequence | state | flow` Mermaid comment as
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

When changing a `SKILL.md` body:

1. Identify the requests and failure paths affected by the change.
2. Compare before and after: every required branch, boundary, and useful
   distinction must remain inline or have a resolving, timely read route.
3. Check an applicable scenario and a nearby non-applicable scenario. For
   changes that broadly alter decisions, use independent baseline/candidate
   trials and preserve misses, false triggers, and execution cost.
4. Run structural checks for bodies, metadata, references, and packaging.
   These checks do not establish decision quality. Report what was actually
   exercised and any untested behavior.

Scale this review to semantic impact. An editorial correction does not need
sentence-by-sentence annotations or a full behavioral trial. A shorter body
that loses necessary knowledge does not pass.

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
