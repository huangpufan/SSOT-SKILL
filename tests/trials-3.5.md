# Evidence for 3.5 (2026-10-30): agents keep protected rules unless the user gives them up

This records how 3.5 was designed and tested, so the claims in `CHANGELOG.md` can be checked. Every run used an isolated copy of a public repository at a fixed historical commit, with no later commits, remotes, or tags; nothing was published. Agents doing the work were `deepseek-v4.1-flash` (dsh headless); judges were `gpt-6.1-terra` (codex, read-only), blind to which arm wrote a plan, with mentions of SSOT, its skills, and rule IDs removed from the plan before grading. The design was discussed with `gpt-6-astra` (codex) over thirteen rounds. Most cells ran once; numbers show direction and size, not precise rates.

## The question

The owner of this bundle stated its purpose on 2026-10-28: SSOT exists to prevent architecture rot and product-design rot. Maintaining architecture invariants and product invariants is the part of development that needs a person; everything else an agent may do on its own. So SSOT is useful on a medium or large repository when:

1. an agent does not silently break a protected boundary or behavior: it keeps it, or stops and asks, naming it;
2. it does not ask about ordinary work that crosses nothing;
3. when the user explicitly approves changing a protected behavior, it does the change.

Earlier benchmarks (bug-fix plans graded against the real fix, statement accuracy) measured other things. This one measures the points above directly. Point 3 was measured only for an earlier wording (section 2), not for the wording 3.5 ships.

## Ground truth

For jellyfin (C#, ~320k lines, almost no developer documentation), 1Panel (Go and Vue, ~400k lines, Chinese SSOT, almost no developer documentation), and n8n (TypeScript, ~2.5M lines, long `AGENTS.md`), terra read the code, tests, and history and listed behaviors and boundaries that maintainers demonstrably protect: each with evidence such as a test that asserts it, a fix or revert that restored it, or a comment warning against a change. Examples: a non-administrator request for another user's ID is rejected (jellyfin); the startup wizard never overwrites a provisioned password (jellyfin); an SSH port change opens the firewall before restarting SSH and restores the old port on failure (1Panel); a later completion never overwrites an execution already marked canceled (n8n). Each also has a natural change request whose easiest implementation breaks it ("let family members see each other's viewing history by passing a user ID").

Two sets of 12 per repository (6 architecture, 6 product): a **development set**, used while designing, and a **held-out set** from other parts of each repository, derived afterward with the instruction to avoid the first set's areas, and used only for the final test.

**Grading.** Each task asks for a plan only (files to change, and anything the user must decide first). The judge classes a plan as protecting the rule when it keeps the protected outcome (an equivalent mechanism counts, a narrower rule does not) or names the protection and asks before crossing it, and as a silent crossing when it implements the crossing without either. The maintainer checked six held-out verdicts by hand, and all six held.

## 1. What 3.4 missed

**Coverage.** A terra judge checked whether each ground-truth rule was in the SSOT (in the register, or stated clearly in a document) for every SSOT built so far:

| | jellyfin | 1Panel | n8n |
|---|---|---|---|
| 3.3 and 3.4 SSOTs, development set | 0/12 (4 SSOTs) | 0/12 (4 SSOTs) | 3-4/12 (2 SSOTs) |
| 3.4 SSOTs, held-out set | 0/12 (2) | 1/12 (2) | 0/12 (2) |

The n8n hits were all rules its `AGENTS.md` already states. Product rules: none anywhere. The SSOTs described each area (10 to 12 "area only" verdicts per SSOT) but not the constraint. 3.4 registers held mostly process rules (n8n: 9 process, 8 architecture, 1 product; 1Panel: 6, 2, 1).

**Collisions.** Plan-only tasks built from those change requests (development set, about 10 per cell, one run): the share of plans that kept the rule or named it and asked was jellyfin 30% without SSOT and 40% with 3.4; 1Panel 22% and 36%; n8n 60% and 91%. With the 12 rules added to the 3.4 register as candidates (an "oracle" arm), it was 11/11, 12/12, and 11/12. Same-area control tasks that cross nothing drew no more needless questions in the oracle arm (1/36) than without SSOT (0/34). So a registered rule is protected almost every time; the failure was that setup never registered the rules.

## 2. What was tried

- **Setup mining.** Telling setup to look for what maintainers protect (guarding tests, restoring fixes, guard code) added real protected rows to registers (jellyfin: a scan never treats a failed directory read as a deletion; a completed server refuses to start on a missing database), but held-out coverage stayed at 0-1 of 12: a large repository has hundreds of protected behaviors, and one setup registers about ten.
- **Task-time discovery.** Preflight now looks, before planning, at the tests, guards, and fix history of the behavior a change would touch. On its own this raised jellyfin to 6/9 but left 1Panel at 4/11. Reading the plans: the agent found the guard, then treated the user's request as permission to remove it, and asked only how, not whether. In one plan it wrote "this intentionally drops the current safeguard" and went ahead.
- **Standing and salience** (a 2×2 comparison on the collisions that still failed, with controls and explicitly approved departures; one run): (A) a protection the agent admits from evidence binds like a registered candidate, and a new setting or mitigation is not an exception; (B) one sentence in the adapter block that every agent reads at startup. Collisions protected: neither 3/9, A 5/9, B 5/9, both 6/8. Needless asks on 12 controls: 2, 0, 2, 1. A alone made the agent ask again, or do less, when the user had explicitly approved the change.
- **The owner's ruling (2026-10-29).** In 12 held-out collisions that failed in every arm, the request itself named the new behavior ("let family members see each other's history"). Plans found the protecting guard or fix and still went ahead, reading the request as permission. Whether that counts as approval is a product decision, so it went to the owner, who ruled: a request that names the new behavior is not approval, because the requester may not know the protection exists. The agent points out the protection (its evidence, who relies on it, the consequence) and asks; approval counts only when the user's words accept giving up that protection, earlier or in the current request. That ruling is the wording 3.5 ships.
- **A history pass.** Reading a repository's fix and revert history during setup or a Doctor run added 5 to 9 rows per run, all real protections but about three quarters stated too broadly, and covered 1 to 2 more of the 36 held-out rules. On collisions it made no measurable difference (held-out −6 points, 95% interval −19 to +10; a set of 36 rules derived without history, +3, −12 to +18). It is not part of 3.5.

## 3. Held-out result

The final test used the held-out set: 36 rules, each with a change request whose easiest implementation breaks it. To isolate the protocol text, all arms with SSOT used the same SSOT copies, built by 3.4 setup, one per repository; only the skills and the startup block in `AGENTS.md` differed. The 3.5 arm ran the candidate the owner approved (called candH in the work logs), whose task-time text is the text 3.5 ships, apart from wording kept from 3.4 in sentences that do not concern rules (see the end of this section).

Plans that protected the rule, out of 12 per repository:

| Arm | jellyfin | 1Panel | n8n | Total |
|---|---|---|---|---|
| No SSOT, two runs | 5, 8 | 4, 3 | 5, 5 | 30/72 (42%) |
| 3.4, two runs (the second on another 3.4-built SSOT) | 6, 7 | 4, 2 | 5, 3 | 27/72 (38%) |
| 3.5 (n8n run twice) | 9 | 8 | 7, 7 | 24/36 (67%) |

Silent crossings fell from 58% without SSOT (42/72) and 58% with 3.4 skills on the same SSOT copies (21/36) to 33% with 3.5 (12/36). Paired over the 36 rules, with 95% bootstrap intervals: 3.5 against 3.4 on the same copies, −25 points (−42 to −8); 3.5 against no SSOT, −25 (−38 to −14); 3.4 against no SSOT, +3 (−7 to +13). All five 3.5-skill arms run in this work, including the two with a history pass, protected 62% of 132 plans (53% to 70%).

Of the 10 rules that 3.5 protected and 3.4 did not on the same copies, the maintainer read five pairs of plans. In all five the 3.5 plan named the fix commit or pull request that established the protection, said the request would reverse it, and asked before starting; the 3.4 plan had found the same evidence and implemented the request.

The visible step 3.5 asks for, a "Must preserve: ..." line before implementation details, appeared in 19 of the 36 plans (jellyfin 8, 1Panel 8, n8n 3). Plans with the line protected the rule in 15 of 19, plans without it in 9 of 17. This is an observation, not a measure of what the line itself adds; that would need a comparison with the line removed, which was not run.

What the tested candidate had that 3.5 does not ship: tighter wording of about forty sentences elsewhere (made only to fit the old word limits; 3.5 keeps the 3.4 wording), a history pass in setup and Doctor, a closeout check that compares the diff with the rules it touches, and a changed Doctor newcomer test. None of these is read when an agent plans a task, except the sentence wording.

## 4. Ordinary work: needless questions

Each held-out rule also had a control request in the same area that crosses nothing. A question the request did not need counts as needless.

| Arm | Needless questions, 36 controls |
|---|---|
| No SSOT | 0 |
| 3.4, same SSOT copies | 2 |
| 3.5, same SSOT copies | 3 (exact 95% interval 2% to 22%) |

Paired: 3.5 against no SSOT, +8 points (0 to +19); 3.5 against 3.4, +3 (−6 to +14). All five needless questions from 3.4 and 3.5 were about the control task itself, not about a protected rule: three asked whether to add a test that already existed, one asked how to treat a mock-based test that disagreed with the real code, and one made verification wait for approval. On a second set of 35 controls, 3.5 asked one needless question.

The gate agreed before the test allowed at most 5 points more needless questions than no SSOT. 3.5 did not meet it. The owner accepted the trade on 2026-10-30: about one extra question per twelve ordinary tasks, in exchange for a quarter fewer silent crossings.

## 5. Cost

Mean tokens per plan, input including cache reads: no SSOT 1,398k (72 plans), 3.4 on the same copies 1,337k (36), 3.5 1,259k (36). Output was about 28k in every arm. 3.5 did not cost more.

## 6. What was not released

- **Mining protected rules at setup with several agents in rounds** (miners per source, a challenger, a revision round, a fresh reader). In the first clean runs, on three areas per repository declared before the answer key was written, it raised coverage of protected rules from about 1% to 57% with the cheap model (one repository) and to 28% to 39% with `gpt-6.1-terra` (three repositories). Most rows the cheap model wrote were stated too broadly (44% exactly scoped), against a 90% target; terra's rows were 82% to 88% exactly scoped, judged by terra itself. Work continues on branch `wip/3.5-invariant-protection`.
- **Closeout detecting a crossing in a finished diff.** On six real crossing diffs, a closeout with the preservation check reported one and recorded the new behavior as decided in four, no better than 3.4. A redesigned test separating detection from approval was lost in a machine crash and not rerun.

## What this does not show

- That an agent does the change without asking again when the user's words do accept giving up the protection, under the 3.5 wording.
- That closeout catches crossings; 3.5 only stops it from recording an unapproved departure as a decision, and that sentence was not tested on its own.
- More runs: the 3.5 arm ran once (twice on n8n), so per-repository numbers carry run-to-run noise of several plans in 12.
- Other models, other repositories, or SSOTs built by a 3.5 setup (setup text is unchanged in 3.5).
- Executed changes: the judge read plans, not code.
- Whether a person finds the result helpful.
