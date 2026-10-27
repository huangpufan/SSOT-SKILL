# Bootstrap: creating and migrating an SSOT

Templates for every file live in `../assets/templates/`. They are starting shapes, not forms to fill: delete any section that has nothing true to say.

## 1. Explore before writing

Read enough to answer, from evidence:

- what the project is for and who uses it: READMEs, docs, product notes, issue templates;
- how it is built, tested, released, and deployed: build files, CI configuration, scripts, Dockerfiles, release notes;
- its main parts, where state lives, and how a typical request or command flows: entry points, directory structure, data stores, external services;
- the rules people already set: `AGENTS.md`, `CLAUDE.md`, contributing guides, ADRs, code review conventions;
- what history says: `git log` themes, large refactors, reverted changes, bug-fix commits that reveal traps.

Note where the evidence is thin. That becomes an open question, not a guess. For a large repository, explore one part at a time and write as you go, so nothing depends on holding the whole repository in mind.

## 2. Write the README first

Start from `ssot-readme.md`. Set `ssot_format: 3` and the documentation language: the language the user asked for, or else the language of the repository's existing documentation. Write the project summary, the map, and task routes for the main kinds of work you saw in the history. Seed the invariants register like this:

- A rule a person wrote down, such as an `AGENTS.md` requirement or an accepted ADR, is `confirmed`. Its source is that document, and its explanation moves into `SSOT/` (section 4).
- A rule you inferred from the code or the history is `candidate`.

## 3. Fill only what has real content

Then write `product.md`, `architecture.md`, and `process.md`. After those, write decision records and gotchas for which you found evidence. Follow the memory model throughout: explain the system rather than restate the code, label anything planned as planned, and say what is unknown. Skip any file you cannot fill truthfully, and list it as an open question instead.

## 4. Absorb existing documents

Every durable fact must end up inside `SSOT/`. For each existing document that holds durable facts:

1. Move those facts into their SSOT owner, rewritten to the memory model. Do not paste the document whole.
2. Turn the original into a short pointer to its new owner, or mark it as historical at the top. A public README may keep its summary for outside readers and link to `SSOT/` for the maintained version.
3. Leave generated files and vendored third-party documents alone.

The agent instruction file (`AGENTS.md`, `CLAUDE.md`) often mixes two things. Short rules for how agents must work there (commit discipline, required checks, forbidden actions) stay in it, because agents read it at startup. Project facts in it (how the system works, how to deploy, history) move into `SSOT/` like any other document. Show the user the planned split first. A rule's Source names where it was written and when (file, section, commit), so it stays traceable after the text moves.

Before you edit or remove an existing file, list the planned changes for the user. Never delete a file without the user's agreement.

## 5. Work across sessions

If setup will not finish in one session, keep `SSOT/BOOTSTRAP.md` from the `bootstrap-progress.md` template. Record what is done, what comes next, and the questions waiting for the user. Each session starts by reading it. Delete it when setup is complete.

## 6. Wire the instructions and finish

1. Add the block from `adapter-thin.md`, everything between `<!-- SSOT-SKILL:BEGIN -->` and `<!-- SSOT-SKILL:END -->`, to the repository's agent instruction file (`AGENTS.md`, `CLAUDE.md`, or the repository's equivalent). If the markers already exist, replace only the text between them. This wiring step never edits outside the markers; moving project facts out of that file is section 4's job, done with the user's agreement.
2. Run `python3 ../ssot-doctor/assets/scripts/ssot-check.py SSOT`, with the path taken relative to this skill's directory. Fix every error. Where it warns that a mentioned file was removed or moved, correct each sentence that still describes current code.
3. Run the newcomer test from `ssot-doctor` section 3 and fix the gaps and errors it exposes. If no helper is available, do it yourself and tell the user it was not independent.
4. Show the user every invariant you registered, the confirmed ones with their sources too (a rule found in an instruction file may have been written by an agent), plus the candidates and the open questions, and invite corrections. Do the same with the planned changes to documents outside `SSOT/` (section 4). Setup is complete once all of these have been put to the user; it does not stay open waiting for the answers. If some documents still repeat facts that SSOT now owns, add one open question to the README that names them; that question, not `BOOTSTRAP.md`, carries the pending work, and the exact edits are worked out once the user agrees. Answers that come later are recorded through `$ssot-closeout`. A candidate nobody answers stays a candidate; preflight asks about it when a task needs to depart from it.
5. Set `reviewed_through` in the README front matter to the commit whose code you explored. It marks where the next catch-up starts; it does not claim that you read every earlier commit. Then delete `BOOTSTRAP.md`.

## 7. Migrating a v2 layout

A v2 SSOT has `STATUS.md` and often `HISTORY.md`, a `.bootstrap/` folder, and `_manifest.md` files. Its documents hold real knowledge, mixed with bookkeeping that v3 no longer keeps. The migration keeps the knowledge and removes the bookkeeping. The old files stay in git history.

Get the user's agreement first, and make the whole migration one commit with no unrelated changes. Moving to v3 is a decision for the whole repository: every installation that works on it (other agents, global installs, teammates, CI hooks) must be on 3.x first, or a v2 agent will try to rebuild the v2 ledgers. Before you start, check the working tree: if `SSOT/` or the agent instruction files have uncommitted changes, ask the user to commit them or set them aside first, so that nothing unrecorded is lost.

Before the first write, create `SSOT/BOOTSTRAP.md` (section 5), say that it is a migration, and note the commit you started from. Keep it until step 10 passes, so that an interrupted migration reads as unfinished instead of as a finished v3 SSOT. A session that resumes it checks the uncommitted changes against what the file says was done, and asks the user about any it cannot account for.

Judge every item by what it says, not by the section it sits in. v2 ledgers sometimes hold a user's instruction, a deployment limit, or an environment difference that appears nowhere else.

1. **Extract from `STATUS.md` before removing it.**
   - Adjudication-boundary rows (in the README) become invariant rows. The v2 columns map one to one: `ID | Kind | Rule | Owner | Established by | State` becomes `ID | Kind | Rule | Explained in | Status | Source`, with Owner → Explained in, State → Status, and Established by → Source. Keep the IDs. A `confirmed` row stays confirmed and a `candidate` row stays candidate. Never promote a row. Rows of kind `apex-maxim` (IDs such as `CLAUDE-MAXIM-1` or `CORE-RULE-1`) are different: their State column (`core-ref-thin`, `inline-body`, `not_yet_owned`) records where the rule text lived, not whether it was approved. These are rules the user wrote into the root instruction file, so migrate them as `confirmed` with kind `process rule`, and give their original location as the Source. List them separately in your report so the user can confirm or correct them. Not every v2 repository has this table: rules people set may also sit in pending captures, in decision records, or in the agent instruction files. Register the lasting rules (memory model §5); a one-time choice stays a decision record.
   - Open adjudications and open gaps that still affect work become open questions. Keep their IDs (`GAP-…`, `ADJ-…`) in the new entry, because code comments, instruction files, and people still use them. Limits that still hold, such as "not verified on macOS", move into the owner document they concern.
   - Pending captures: first check each one's state, scope, and whether a later capture or decision replaced it. A user's directive that still applies becomes a confirmed invariant with the user and date as its source, or a decision record if it was a one-time choice. A replaced or rejected one stays history: do not turn it into a rule. One that is already absorbed into an owner needs nothing new. The rest become candidates or open questions.
   - Coverage tables, tracking baselines, quality matrices, and review gate rows: v3 keeps none of their status. The facts inside them still need extracting, or confirming that a document already carries them.
2. **Scan `HISTORY.md`, `.bootstrap/`, and `_manifest.md` files** for anything that appears nowhere else and still matters: decisions, limits, the cause of a failure, the reason an option was rejected, unfinished work, and evidence that a current conclusion relies on. Move it to its owner; evidence goes to `research/` or another fitting owner, and links that pointed at it are updated. Do not drop unique content just because it sits in a ledger. Before deleting, sort every part of each file into one of three groups: already carried by a document, clearly obsolete, or undecided. Undecided parts are kept, or put to the user.
3. **Make sure removal is recoverable, then remove the ledgers.** Git history keeps committed files only. If a file you are about to remove has uncommitted changes or is untracked, ask the user how to keep it before you remove it. Check that nothing still links to what you remove.
4. **Bring every invariant's explanation inside `SSOT/`.** If a row's explanation lives elsewhere, for example in `AGENTS.md`, copy it into the right SSOT owner and repoint the row. Ask the user before changing text outside a managed block. Documents outside `SSOT/` that still hold durable facts SSOT lacks are absorbed as section 4 describes.
5. **Remove bookkeeping from the documents.** That means front matter that tracks the document's own v2 review state (such as `intent_recovery`, `scope`, `promotion_targets`); coverage and baseline notes; review-certificate language; quality-matrix IDs; `<!-- -->` comments inside Mermaid fences (use `%%`); and lines about writing style. Fields that record the subject's state carry knowledge: a record that was superseded, rejected, deprecated, or never adopted (`record_status`, `adoption_state`), or work that is pending, partial, or diverged (`implementation_state`, `failure_state`, `hazard_state`, `repayment_state`). Write that state into the body first (for a decision, its Status line: `deprecated` becomes `retired`; add a successor link where one exists), then drop the field. Drop date stamps such as `updated_on`, because git keeps them. Keep every sentence of real knowledge.
6. **Keep the existing paths.** Rewrite the README into the v3 sections: front matter, summary, map, routes, invariants, open questions. Keep its existing routes. If v2 had a `tracked_commit`, resolve it to a full SHA and check that it exists and is an ancestor of `HEAD`. If it passes, set `reviewed_through` to it, because the commits after it have not been reviewed. If it fails, leave the field out and tell the user.
7. **Replace the old instructions.** Search every agent instruction file (`AGENTS.md`, `CLAUDE.md`, and similar) for SSOT instructions, both inside and outside `SSOT-SKILL` markers. Look for mentions of `$ssot-audit`, `tracked_commit` or other `tracked_*` fields, reading `STATUS.md` first, `HISTORY.md` rows, coverage, or protocol versions. These conflict with v3 and must go. The v3 block from `adapter-thin.md` replaces them. Keep project rules that are not about the SSOT workflow. Text inside markers can be replaced directly; for text outside them, show the user the old text and the replacement before you change it.
8. **Fix inbound links.** Search the repository for links to files or headings you renamed or removed, for example `SSOT/README.md#adjudication-boundary`, and point them at the new location.
9. **Repoint tooling that used v2 scripts.** Search `package.json`, Makefiles, CI workflows, hooks, scripts, and tests for v2 bundle files such as `ssot-lint.sh`, `ssot-migrate.py`, or `run-tests.sh`. v3 ships none of them, so those commands now fail. With the user's agreement, point them at `ssot-check.py`. Its exit codes are 0 pass, 1 errors, 2 usage error, and 3 incomplete, which is never a pass; its last line always starts with `ssot-check: PASS`, `FAIL`, or `INCOMPLETE`. It needs `python3`. If the skills are installed outside the repository, ask the user which path the scripts should use. Keep the old semantics: a check that did not block commits still does not block them. Tests that parsed v2 output or read v2 script source are rewritten against the new checker, or removed if the user prefers. Run the repointed commands once, and update any SSOT text that describes them. Never bypass a failing hook to get the migration committed.
10. **Verify and finish.**
   - The checker reports no errors, and the sentences its removal warnings point to no longer describe missing code as current.
   - Every invariant ID from v2 is still present with the same status, apart from `apex-maxim` rows, which are now `confirmed`.
   - Every item extracted in steps 1, 2, and 4 can be found in its new owner.
   - A fresh look finds nothing left to migrate: no ledgers, no v2 front matter or bookkeeping, and no old SSOT instructions.
   - The newcomer test from section 6, step 3, passes.

   Then put the candidates, the `apex-maxim` rows, and the open questions to the user (section 6, step 4), give them a short list of where each extracted item went, and delete `BOOTSTRAP.md`. `reviewed_through` stays as step 6 set it.
