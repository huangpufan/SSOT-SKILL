---
name: ssot-preflight
description: Read the repository's SSOT before substantive work. Use this before code, config, documentation, review, debugging, refactoring, or planning work in a repository, to find the invariants and documents that bear on the task and to surface open questions that affect it. Skip it for non-repository chat, pure command runs, and typo or formatting edits that cannot change meaning.
metadata:
  protocol_version: "3.0"
  bundle: "SSOT Skill"
---

# SSOT Preflight

Before substantive work, find out what the repository's memory says about the
task. [`references/memory-model.md`](references/memory-model.md) explains what
`SSOT/` holds and what the invariants register means. Read it the first time
you use SSOT in a session.

## 1. Find the entry point

- **No `SSOT/` directory.** Tell the user the repository has no SSOT and offer
  to create one with `$ssot-bootstrap`. Setup writes a documentation tree and
  can take more than one session, so it needs the user's yes. If they decline
  or defer, do the task without the SSOT steps, and do not offer again this
  session.
- **`SSOT/BOOTSTRAP.md` exists.** Setup is unfinished. Offer to continue it,
  and meanwhile use what is already written.
- **`SSOT/README.md` has no `ssot_format: 3`.** This SSOT predates v3:
  usually the v2 layout with `SSOT/STATUS.md`, sometimes a hand-written one.
  Read it as knowledge. Its coverage labels and review
  records are historical, but its adjudications, user constraints, limits,
  and open questions that bear on the task still bind you. Do not write to
  it. Tell the user once that `$ssot-bootstrap` can migrate it or set it up
  in the v3 format.

## 2. Read what this task needs

Read `SSOT/README.md`, then:

1. **Invariants.** Find the rows whose rule this task could affect, and read
   the explanation each one links to. If the task would break a confirmed
   invariant, stop and ask the user before acting. Follow candidate rows as
   strong defaults, and mention them when the task bears on them.
2. **Open questions.** If one blocks the path this task needs, say so. Only
   the work that depends on the answer waits; unrelated work goes ahead.
3. **Known traps and limits.** Read the gotchas and the known gaps that
   touch the parts you will change, and handle each one: fix it, work around
   it deliberately, or say why it does not apply.
4. **Routes.** Read the files the task routes point to. If no route fits, read
   the product and architecture entry documents. Do not read the whole tree.
5. **What you rely on.** When an SSOT statement decides how you will implement
   something, check it against the code first. If they disagree, the code is
   the current behavior. Note the mismatch so closeout fixes the document, or
   so you can report the violation.

## 3. While you work

Watch for facts that will outlive the task: decisions, changed contracts or
behavior that users rely on, traps you hit, changed commands, temporary
workarounds, and lasting directives from the user ("never", "always", "from
now on"). Note them as they come up. `$ssot-closeout` records them before you
finish. If a fact is clear and its owner is obvious, you may update the owner
right away.

## Where to go next

| Situation | Skill |
|---|---|
| No SSOT yet, setup unfinished, or a v2 layout to migrate | `$ssot-bootstrap` |
| Finishing a substantive batch, before the final response or commit | `$ssot-closeout` |
| Health check, a review, or catching up on past commits | `$ssot-doctor` |
