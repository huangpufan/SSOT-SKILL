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
