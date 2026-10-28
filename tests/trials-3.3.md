# Evidence for 3.3 (2026-10-28): large repositories

This records how 3.2 was tested on two large repositories, what broke, and how the 3.3 changes were checked, so the claims in `CHANGELOG.md` can be checked. Every run used a copy of a public repository; nothing was published. The agent in every run was `deepseek-v4.1-flash` through dsh headless, a cheap model; the maintainer only prepared copies and judged results. Most cells ran once or twice, so the results show what can happen, not how often.

## The question

Version 3 dropped v2's size tiers and fixed folder skeleton. `SSOT/` starts as one README and splits a file into a folder when it grows. Does that still work when the repository has millions of lines and tens of thousands of commits: can an agent set SSOT up, use it without reading the whole tree, keep it current, and catch it up after a long gap?

## The repositories

- **n8n**, a workflow automation platform: a TypeScript monorepo with about 2.5 million lines of non-test source, 32,000 files, 26,000 commits, 37 agent instruction files, and nine ADRs. SSOT was set up at the commit of 2026-10-20, and 400 later commits were held back for the catch-up.
- **zed**, a code editor: about 1.8 million lines of Rust in 249 crates, 40,000 commits. SSOT was set up at the commit of 2026-10-13, and 200 later commits were held back.

Each copy was a clone that contained only the history up to its start commit, with no remotes and no tags, so an agent could not read the later fixes. An early version of the harness leaked later commits through a shared object store and a remote branch; one setup session ran `git log origin/master`, and one task answer cited the real upstream fix. Those runs were thrown away and repeated on clean clones.

## 1. Setup

| | n8n | zed |
|---|---|---|
| Sessions until `BOOTSTRAP.md` was deleted | 1 (twice), or never (once; see section 5) | 3 |
| Time per session | 8 to 19 minutes | 7 to 16 minutes |
| Result | 16 to 22 files, 82 to 156 KB | 13 files, 104 KB |
| README | 11 to 19 KB, 19 to 44 invariant rows | 14 KB, 20 invariant rows |

Every setup split `architecture.md` and `process.md` into folders when they passed the reading budget, as the memory model prescribes, and every setup ended with the checker reporting no errors. Spot checks against the code found the documents mostly right; the later catch-ups found the errors that remained (section 3).

## 2. Using SSOT on tasks (preflight)

Six real fixes from the held-back commits per repository became tasks: the agent got the bug report or feature request and had to give a plan without changing files. Each task ran with SSOT and without it (`SSOT/` and the skills removed).

- **Reading stayed bounded.** With SSOT, a task read 3 to 9 SSOT files, 29 to 101 KB, out of 104 to 156 KB in total. No run read the whole tree. The README with its register was read every time; the n8n register is 44 rows and 12 KB, and across 20 task runs the plans cited 18 of its 44 rows.
- **Cost did not go down.** Total input tokens for five n8n tasks were 6.2 and 9.0 million without SSOT (two runs) and 12.6 and 11.8 million with it; for zed, 18.4 without and 19.4 with. These are code-local bug fixes, and searching the code dominated both arms.
- **Quality was similar.** Both arms usually found the same root cause, and many matched the real upstream fix. With SSOT the plans cited the repository's rules by ID and sometimes added a relevant constraint (the private security-fix flow for a webhook signature change; the decision that owns binary-file deletion). Both repositories already ship long agent instruction files, so the arm without SSOT also found most rules. No blind grading was done, so this is the maintainer's reading, not a measurement.

**A change that was tried and dropped.** For large repositories we added a "this part is not described in SSOT, look here instead" route row to the README template, and a preflight rule to stop searching SSOT for an undescribed part. A fresh n8n setup with the change wrote no such rows, and in two repeated task runs the SSOT reading was unchanged (68 and 65 KB against 66 and 59 KB without the change). It is not in 3.3.

## 3. Catch-up after a gap

The held-back commits were merged and a fresh agent was asked to catch SSOT up with `$ssot-doctor`.

- **zed, 200 commits:** one session, 17 minutes. It corrected eleven files (for example the new macOS minimum, crash-report templates that were removed while the instruction file still pointed at them, and the new ban on legacy Objective-C crates) and moved `reviewed_through` to the merge.
- **n8n, 400 commits:** one session, 23 minutes, about 31 million input tokens. It found statements the code had made wrong (a removed planning layer, a deleted feature flag, an engine resume path described as working that is not wired), added owners for new areas, and moved `reviewed_through`. It said it had read every commit subject but not every diff line.
- **n8n, 2,007 commits** (SSOT set up again at the commit of 2026-09-16): with 3.2, one session ran for 60 minutes and made 19 substantive corrections, then stopped with large areas unreviewed. It correctly left `reviewed_through` at the start, because 3.2 moved it only after the whole range. But it also left no record of where it got to, so a second session would have had to start from the beginning. With a gap this long, a catch-up could never finish.

3.3 changes catch-up in three ways, each found in a run of this trial:

1. **Say what reviewing a commit means, and let the marker move per segment.** Work oldest first along the main line, a few dozen commits at a time; read every commit message, and read the diff where the message or the files it touches suggest a durable fact. When a segment's facts are written, move `reviewed_through` to its last commit, so the next session resumes there. A segment that was skipped, sampled by kind, or left with facts unwritten does not count. An earlier wording of this rule, without the definition, let one agent move the marker over the whole range in 9 minutes while calling two of its segments "approximate". With the definition, the same range (2,001 commits on the main line) took one 13-minute session that changed 18 files, and the agent said it had read every subject and the diffs that mattered.
2. **Move the marker last.** Both 3.2 catch-ups that moved `reviewed_through` moved it before writing anything: before all 93 edits on n8n, and before all 32 on zed. The candidate with only the definition moved it halfway, after 21 of 40 edits. A session interrupted at that point would make the next one skip facts that were never written. With "move it last, because an interrupted session would skip what is not yet written", the n8n run moved it after all 55 of its edits, and the zed run after its first pass; zed then added two facts it noticed on rereading.
3. **Keep working files outside the repository.** An interrupted session left 3.3 MB of commit lists and helper scripts in a hidden folder at the repository root, where a person could commit them by accident. With the rule, two more sessions cut off at 8 minutes kept their lists in the system temp directory and left nothing outside `SSOT/`; both also left the marker at the start, because they were cut off mid-write.

**Resuming.** To force interruptions, the 2,001-commit catch-up ran in sessions capped at 8 minutes. The first was cut off mid-write and left the marker at the start, which is the safe outcome. The next three each continued from the marker and moved it 9, 3, and 6 times, in step with their edits: to commit 500, 843, and 1,300 of 2,001. Each one ended by naming the first commit it had not reviewed.

## 4. Closeout

Four finished changes were put in the working tree of the task copies, and a fresh agent ran closeout.

- Two changes with nothing durable (a missing period in a banner; a silenced warning when `gpg` is absent): both agents compared the owners, wrote nothing, and said why.
- The binary-file deletion change in n8n: the agent updated the execution architecture page and the decision about deletion. The real upstream commit edited its ADR the same way.
- Raising zed's minimum macOS version: the agent updated the product, process, and release pages and wrote a new decision record.

## 5. Setup that never finished

In the first n8n setup, sessions 2, 3, and 4 each kept `SSOT/BOOTSTRAP.md`: the user had not yet agreed to turn the outside documents into pointers to SSOT, and the agents read that pending plan as unfinished setup. In a repository with dozens of instruction files and ADRs, that agreement is easy to defer, and as long as `BOOTSTRAP.md` exists every later agent treats SSOT as unfinished.

Part of the cause was the harness: the first prompt told the agent to park questions in `BOOTSTRAP.md`. Later prompts told it to put questions in its final answer, and the 3.2 rules still kept the file: two continuation runs from the same state, on clean copies, both kept it.

3.3 says setup is complete once the invariants, the open questions, and the planned outside changes have been put to the user; documents that still repeat SSOT's facts become one open question in the README, which carries the pending work. Five continuation runs from the same state with the 3.3 rule (two of them with an earlier draft of its wording): three finished setup and deleted the file, one kept it and said the user's answers were still outstanding, and one was cut off by the provider's rate limit after deciding to finish.

## What this does not show

- One model, one harness, one or two runs per cell.
- Whether a person finds the generated documents readable; nobody read them for that.
- Migration of a large v2 SSOT: none of these repositories had one.
- Repositories without long agent instruction files, where SSOT might matter more to task quality than it did here.
- Multiple people or agents writing SSOT at the same time.

## 6. Fact-checking what setup writes (added after 3.3 shipped; part of 3.4)

**The question.** Is the SSOT that setup and catch-up leave behind true? A different cheap model (`gpt-6.1-terra` through codex, read-only) audited each finished document: it picked eight statements a task would act on, checked each against the code and history, and graded it correct, partly right (a detail wrong or missing in a way that would mislead a task), or wrong. Two of its verdicts were checked by hand and held.

**Before the change.** Across the three SSOTs that had been set up and then caught up (n8n after 400 and after 2,001 commits, zed after 200), 58% of 320 statements were correct, 37% partly right, and 5% wrong. The usual fault was a statement made too broad ("every node runs once", "all host operations live in the agent") or an intention taken from a design document and presented as built ("the stored body is redacted, then encrypted"). Catch-ups fixed stale statements but did not raise these rates. Setup itself never checked its statements against the code: the newcomer test asks whether a reader can find an answer, not whether the answer is true.

**The change.** Setup and catch-up now check what they wrote against the code, using Doctor's Truth review, which names the two kinds to look at hardest: statements with "all", "only", "every", "never", or "always", and statements taken from a design document, an ADR, or a code comment. The memory model adds the matching writing rule: use those words only when the code enforces them.

**The trial.** Two repositories with almost no developer documentation, so setup had to read code: jellyfin (about 320,000 lines of C#) and 1Panel (about 400,000 lines of Go and Vue, SSOT written in Chinese). Each was set up four times from the same commit, twice with 3.3 and twice with the change, one session each; every run finished setup.

| | 3.3 | with the change |
|---|---|---|
| Statements audited | 272 | 272 |
| Correct | 51% | 56% |
| Partly right | 40% | 42% |
| Wrong | 7% (20) | 2% (6) |
| Statements with "all/only/every/never/always" that were not correct | 60% of 53 | 44% of 43 |

Re-auditing two of the SSOTs with the same judge moved their correct share by 5 and 7 points, so the judge's own noise is about as large as the difference in correct statements; that difference is not shown. The drop in wrong statements is larger than the noise and appeared in all four comparisons; resampling the 68 documents never removed it. Reading cost and setup time did not change noticeably (one session of 12 to 20 minutes in every run).

**What this does not show.** Two repositories, two runs per arm, one model doing the work and one judging. Partly-right statements stayed at about 40% in both arms: the change mostly turns wrong statements into qualified ones, and does not make the documents complete.
