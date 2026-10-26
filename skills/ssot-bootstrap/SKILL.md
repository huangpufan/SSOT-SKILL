---
name: ssot-bootstrap
description: Create, continue, or migrate a repository's SSOT. Use when the user agrees to create SSOT for a repository that has none, when SSOT/BOOTSTRAP.md shows setup is unfinished, or when the user agrees to migrate an SSOT whose README lacks ssot_format 3 (usually the v2 layout with SSOT/STATUS.md). Builds the memory from repository evidence and absorbs existing documentation into SSOT/. Do not use for normal task preflight or closeout.
---

# SSOT Bootstrap

Build the repository's memory from what the repository shows: its code,
configuration, tests, history, and existing documents. A filled template is
not knowledge. What to store and how to write it is defined in
[`memory-model.md`](../ssot-preflight/references/memory-model.md).

Setup writes a documentation tree and may edit existing documents, so it
needs the user's agreement first. Tell them what you will create and which
existing files you expect to change.

Follow [`references/bootstrap.md`](references/bootstrap.md):

- Sections 1–6 cover a new SSOT, or continuing an unfinished one.
- Section 7 covers migrating a v2 layout, including resuming a migration
  that `SSOT/BOOTSTRAP.md` says is under way.

You are done when all of these hold:

- the README routes the repository's main kinds of task;
- every document you wrote matches the code it describes;
- the existing documents' durable facts live in `SSOT/`;
- the candidate invariants and open questions have been put to the user;
- the checker reports no errors;
- `SSOT/BOOTSTRAP.md` has been removed.

If you have to stop earlier, `BOOTSTRAP.md` must say what is done and what
comes next.
