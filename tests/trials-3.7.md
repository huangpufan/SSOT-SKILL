# Evidence for 3.7 (2026-10-30): mining finds most of a medium repository's protected rules

This records how the mining changes in 3.7 were tested, so the claims in `CHANGELOG.md` can be checked. 3.6 added a multi-agent procedure that finds the rules a repository protects (`tests/trials-3.6.md`); on large repositories it found about half of each sampled area's rules. The owner's goal for this round was coverage and precision near complete on small and medium repositories, measured on one or two of them so that each change could be tried quickly. Every run used an isolated copy of a public repository at a fixed commit, with no later commits, remotes, or tags. Builds were done by `gpt-6.1-terra` (codex) and `deepseek-v4.1-flash` (dsh headless); the answer keys and all judging were done by `gpt-6.1-terra`.

## The repositories and the answer keys

- **fd** (`sharkdp/fd` at `434d80e`): a Rust command-line search tool, about 12,000 lines with 220 integration tests and 2,000 commits. Used to develop the changes.
- **click** (`pallets/click` at `2247b35`): a Python command-line library, about 29,000 lines with 600 tests and 3,400 commits. Held out: the maintainer did not read its answer key while changing the skill, and the skill was not changed for it.

Five areas per repository were declared before any answer key existed, together covering the whole repository. For each area terra listed protected rules twice, once from the code at that commit and once mainly from its history, with evidence that people protect each one; an independent terra pass checked every claim against the code (none dropped, about a fifth narrowed), and a final pass merged duplicates. That left 53 rules for fd and 61 for click. The maintainer checked two fd rules against the code; both hold.

Each rule usually bundles several behaviors ("hidden entries are skipped by default, hidden directories are not entered, `--hidden` includes them without disabling ignore rules, and a hidden directory given as a search root is still searched"). Judging whole rules turned out to be all-or-nothing: a rule written as two rows, or missing one of four parts, counted as absent. So terra split every rule into single checkable claims without changing their meaning: 202 for fd, 169 for click. **Coverage** is the share of claims that `SSOT/` states, in the register or in a document, alone or together. **Precision** is the share of register rows a run added that a terra audit judged correct: true at that commit, protected on purpose, with the right conditions and exceptions. The judges read a copy of the repository without the working files, because one early run kept its working notes inside `SSOT/` and the judge counted them.

## 1. What changed, and what each change did

Mining was run on its own, as a Doctor scope over the whole repository, on copies of the same starting SSOT: the one 3.6 setup produced for fd with terra. Each version ran two or three times with terra.

| Version | What it changed | Coverage of fd claims | Precision of added rows |
|---|---|---|---|
| 3.6 | | 36%, 30%, 32% (mean 33%) | 23/25, 15/17, 18/18 |
| A | Helpers write: one helper per area writes every outcome the challenge left standing into `SSOT/`; the lead decides only disputes, instead of deciding every proposal itself | 53%, 55%, 53% (54%) | 54/57, 54/59, 115/123 |
| B | A, plus the user documentation as a source and as evidence | 65%, 64%, 55% (61%) | 64/71, 49/54, 44/46 |
| C | B, plus what each explanation must name: triggers with aliases, the default, the exact outcome, precedence, exclusions | 65%, 64%, 66% (65%) | 65/69, 60/62, 59/62 |
| Shipped | C, plus the review fixes in section 3 | 55%, 70% | 64/64, 60/67 |

Rows added per run rose from 17 to 25 under 3.6 to between 46 and 123. Precision stayed between 90% and 100% throughout. Across the five runs of C and the shipped text, coverage averaged 64%, against 33% for 3.6.

The first two drafts did not help, and why they failed shaped the rest:

- **Sampling until complete.** A draft that sampled the checklist and mined again whenever the sample found a miss spent a whole setup on one area, sampling four times, and wrote rows that restated test fixtures ("in the tested fixture, `.hidden.foo` is excluded"). It stated 8% of fd's claims. The shipped text samples once, after every area's first pass, mines the misses once, and then reports.
- **The lead as bottleneck.** In 3.6 the lead agent decides every proposal itself and re-checks it. In one terra run the miners' proposals covered most of the answer key, but the lead had decided only 18 when it stopped and left the rest "deferred"; another run admitted 7 rows and reported 52 drafts still waiting. Change A removed that bottleneck, and it gave the largest single gain.
- **A second round adds little.** Running the same mining again on two finished A copies moved coverage from 53% to 53% and from 55% to 57%. What was missing was detail, not breadth: SSOT said "matches the full path" where the rule is "the absolute path", named `--quiet` but not `-q`, and never said which of two case options wins. Change C names those details.

## 2. Held-out repository

On click, with the same starting arrangement (the SSOT 3.6 setup produced with terra), mining ran without any change to the skill:

| Version | Coverage of click claims | Precision |
|---|---|---|
| 3.6 | 34%, 36% | 27/28, 33/35 |
| C | 49%, 58% | 91/93, 256/273 |
| Shipped | 44% (finished after release) | 85/98 |

## 3. Review, and a finding from the cheap model

A fresh terra review of the change, given only the diff and the goal, raised twelve points. Six were applied: rules taken from user documentation are candidates, also when setup seeds the register; an architecture rule states the property and boundary it keeps rather than a user-visible outcome; a protected rule the code now breaks stays and the violation is reported; a disputed row is rechecked once and then stays out of the register and goes in the report; each writing helper owns its own files; misses the completeness sample finds go through the same challenge and check. The others were not applied, with reasons in the work log: treating documentation as a lead only (the owner's definition of a product invariant covers behavior users rely on), the existing Doctor rule about writes, and the size of the checklist on long histories (not observed on these two repositories).

The cheap model shows the documentation risk the review pointed at. With version A, a flash setup of fd reached 94% coverage, but it registered 21 documented behaviors as `confirmed`, citing the manual as a rule a person wrote down; precision of its candidate rows was 3 of 14. 3.7 says a behavior taken from documentation is a candidate. With that sentence, a second flash setup registered 10 confirmed rows, all from the contributing guide, the security policy, and the release checklist, and 50 candidates.

## 4. Setup with the cheap model

Full setups of fd with flash under 3.6 reached 85% and 73% coverage, with precision 33/41 and 12/18: the cheap model writes long architecture documents (15,000 to 19,000 words for fd) that state most behaviors, and states a fifth to a third of its rows too broadly. With the 3.7 text, one flash setup reached 87% coverage with 15,400 words, but only 29 of its 50 candidate rows were judged correct (58%); most of the rest miss a condition or exception. The flash row checker accepts rows the terra judge rejects, so precision with the cheap model is still the main open problem.

## 5. A question 3.6 left open

3.6 shipped before it was known whether mined, partly overbroad rules make agents ask about ordinary work. The jellyfin near-boundary requests have since finished (12 per SSOT, terra judge, rubric of `tests/trials-3.5.md`): the unmined SSOT drew 1 needless question, the flash-mined one 0, the terra-mined one 2, and no plan broke anything. Mined SSOTs together asked needlessly 2 times in 24, the unmined one 1 in 12.

## 6. Found after release: the trial environment

After release the maintainer found that every terra run in this trial, the builders and the judges alike, ran with the maintainer's personal codex configuration: a global instruction file about work discipline, 32 personal skills (one of them is applied before any completion claim and asks for evidence that the work is done), and codex memories. Several setups read that skill just before stopping and reported setup as unfinished. The setup prompt also said "This session may end before setup is finished", which invites an early stop. Some runs met network interruptions with reconnects lasting minutes. The flash runs loaded no global instruction file; they saw only a list of personal skill names.

Both arms of every comparison ran under the same configuration, so sections 1 and 2 compare versions under equal conditions. The absolute numbers, and above all the full setups with terra (2% to 64% on fd and click), may not hold in a clean environment. The harness now runs codex with an isolated home, and a check confirmed that such a run sees none of the personal skills or instructions. Repeating the trial in the clean environment was blocked by the terra account's usage limit.

## What this does not show

- Coverage near complete. The best terra mining reached two thirds of fd's claims and about half of click's; most of what remains is detail of documented options. The one click run of the shipped text (44%, finished after release) was the lowest of the three 3.7 click runs, mostly in completion and testing (9 of 35 claims, against 24 and 26); one run cannot separate the review fixes from run-to-run spread.
- Precision near complete with the cheap model.
- Large repositories, other models, and repeated full setups with terra, which often ended a session with setup still unfinished.
- Whether more rows change what agents do. The 3.6 end-to-end check on jellyfin (agents kept 9 of 12 sampled rules against a mined SSOT, 2 of 12 against an unmined one) was not repeated, and the size of the SSOT agents must read grows with coverage.
- That the answer key is complete: it is terra's selection of each area's most important rules, about ten per area.
