# Design: why SSOT Skill is shaped this way

This file records why version 3 looks the way it does, so that later changes do not quietly rebuild what it removed. How to change the protocol is in [CONTRIBUTING.md](./CONTRIBUTING.md#changing-the-protocol). What a consumer's `SSOT/` contains is in [memory-model.md](./skills/ssot-preflight/references/memory-model.md).

## The job

A coding agent starts every session without the history of the project. SSOT Skill gives each repository a small, maintained memory: what the project is for, how it works, which rules people decided, why things are the way they are, and where the traps are. The next agent reads it before working and updates it when something durable changes. The bundle's value is that this reading and updating cost less than the mistakes they prevent.

## What happened in v2

Version 2 grew from 0.8 MB of skills (2.50, June 2026) to 1.9 MB (2.86, October 2026), and its lint script grew from 50 KB to 400 KB of Bash. There were 36 protocol versions in four months. Most later commits reconciled clauses that earlier fixes had made inconsistent.

The repositories that used it showed the cost:

- None of the five repositories ever reached the protocol's own finish line (`converged`). One had 406 SSOT commits, and all 17 of its areas were still marked `gap` or `stale`.
- Status ledgers, histories, review records, and manifests made up 15–38% of the SSOT bytes. One `STATUS.md`, which agents had to read before every task, had grown to 213 KB.
- About a third of all commits in the heavy users changed only SSOT files.
- The governance did not keep the facts fresh. One product document still gave a schema version that the code had passed several migrations earlier.
- Documents meant for people filled up with the protocol's bookkeeping vocabulary, and readers said they could not follow them.

The cause was in how the protocol changed, not in any one rule. Each observed agent mistake became a new clause, a lint check, a template field, a version bump, and a catch-up task for every consumer. Each fix was tested on its own case. Nothing asked whether the duty belonged in a general protocol at all, or whether the whole still paid for itself.

## Principles of v3

1. **Memory, not verification.** SSOT keeps what helps the next task. Proof that one task works stays in its commit, pull request, or test run.
2. **Store only what the code cannot tell you.** Don't restate fields, versions, or configuration values. Explain intent, system relationships, decisions, rejected options, and traps.
3. **One required file.** `SSOT/README.md` is the entry point; every other file exists only when it has real content.
4. **People's rules are the one strongly governed thing.** Confirmed invariants cannot be changed by an agent, and every invariant is explained inside `SSOT/`.
5. **Releases never create work for consumers.** The data format (`ssot_format`) changes only when old SSOTs would be misread. A new bundle version alone never asks a repository to catch up.
6. **Machines check only what machines can decide.** Links, anchors, the register's shape, sizes, and file paths that git says were deleted or moved. Truth and readability are reviewed by an agent, and the review says how far it went.

## What was removed, and what it would take to bring it back

The following left the bundle in 3.0. The full v2 implementation is frozen at the `v2-final` tag and installable with `install.sh --ref v2-final`:

- per-area coverage states, completeness checklists, the Q01–Q21 matrix, and `converged` certification;
- the `STATUS.md` and `HISTORY.md` ledgers, review archives under `.bootstrap/`, and `_manifest.md` inventories;
- tracking baselines advanced after review, and the obligation to audit after every protocol release;
- the 400 KB lint script and its prose-pattern checks.

Bringing any of these back needs what v2 never had: a failure seen in real use that v3 cannot handle, a trial that shows the addition helps on whole tasks, and a place in the [budget](./CONTRIBUTING.md#protocol-budgets).
