# Evidence for 3.6 (2026-10-30): finding the protected rules at setup, with several agents in rounds

This records how the rule-mining procedure in 3.6 was tested, so the claims in `CHANGELOG.md` can be checked. 3.5 made agents keep the protected rules SSOT knows about; its own trial showed why that is not enough: a registered rule is protected almost every time, but setup registered almost none of the rules a repository actually protects (`tests/trials-3.5.md` section 1). 3.6 adds a procedure that finds them. Every run used an isolated copy of a public repository at a fixed historical commit, with no later commits, remotes, or tags. Builds were done by `deepseek-v4.1-flash` (dsh headless) and, in a second arm, `gpt-6.1-terra` (codex); the answer key and all judging were done by `gpt-6.1-terra`. Most cells ran once or twice; numbers show direction and size, not precise rates.

## The procedure

`references/mining.md`, used by setup and by a Doctor area scope: declare the areas, sources, and budget first; start at least two helper agents per area, each with a fresh context and a different source (tests and contracts; history; guards and comments); give each area's proposals to a fresh challenger that looks for exceptions, bypasses, and later decisions, and reads sources the miners did not cite; send the findings back to the miners for one revision round; admit each proposal by the rule in memory-model §5; have a fresh reader that sees only `SSOT/` answer crossing, nearby, and explicitly approved requests; report per area. Working files live in `.ssot-work/` inside the repository, ignored by git.

## The answer key

Three areas per repository were declared before any answer key existed, chosen to mix test-rich and test-poor code: jellyfin file-name parsing, Live TV, and users and sessions; 1Panel backup, websites and nginx, and the file manager; n8n webhooks, queue mode, and credentials. For each area terra listed protected rules twice, once from the code at that commit only and once mainly from the history, each rule with evidence that people protect it (a test that asserts it, a fix that restored it, a comment that explains a guard). A third, independent terra pass checked every claim against the code: of 152, it kept 105, narrowed 47 to what the code supports, dropped none, and removed 18 duplicates, leaving 134 rules (jellyfin 44, 1Panel 43, n8n 47). The maintainer checked three against the code; all three hold. The rules are fine-grained, about the level of one tested behavior: for example, a worker never runs a queued execution already marked crashed (n8n), and creating a series recording rule does not cancel timers already set by hand for the same programs (jellyfin).

Coverage means the share of these rules that SSOT records, either as a register row or stated clearly enough in a document that an agent would not break it. Precision means the share of rows a build added that a terra audit judged correct in scope: true at that commit, protected on purpose, and with the right conditions and exceptions. "Overbroad" rows are right in substance but miss a condition or exception.

## 1. Coverage and precision

| SSOT | jellyfin | 1Panel | n8n | Precision of added rows |
|---|---|---|---|---|
| Built by 3.4 setup | 1/44 | 0/43 | 0/47 | |
| 3.4 setup plus a history pass | 2/44 | 2/43 | 0/47 | |
| Mined, cheap model, build 1 | 25/44 (57%) | not clean, see section 4 | 20/47 (43%) | 44% (jellyfin), 60% (n8n) |
| Mined, cheap model, build 2 | 19/44 (43%) | pending | pending | 67% (jellyfin) |
| Mined, terra | 17/44 (39%) | 13/43 (30%) | 13/47 (28%) | 88%, 85%, 82% |

Each mined build added 17 to 33 register rows plus area documents. The cheap model found more rules and stated many too broadly; terra found fewer and stated them more exactly. The terra arm is graded by the same model that wrote the answer key, which may flatter it.

## 2. Was the procedure followed

All three clean cheap-model builds started six miners (two per area, tests and history), three challengers (one per area), and a fresh reader, and wrote a per-area report; two of them left revision files from the miners, the third reported the revision round without files. A build took 22 to 42 minutes; the lead session read 18 to 35 million input tokens, mostly cache reads, and helper tokens were not counted. The terra builds took 7 to 8 minutes and showed the same stages in their working files.

## 3. Does it change what agents do

For jellyfin, 12 of the answer-key rules were sampled at random (a fixed seed, four per area), each with a change request whose easiest implementation breaks it. On the same skills, agents planned against the unmined 3.4 SSOT and against the first cheap-model build. Plans that protected the rule: 2 of 12 unmined, 9 of 12 mined; silent crossings 10 and 3. Same-area requests that cross nothing, which show whether overbroad rules make agents ask needlessly, were still running when 3.6 was released, as were the same tests for 1Panel and n8n.

## 4. What went wrong in the trial, and what it changed

- **Rate limits.** With several builds at once, and even with one build starting six helpers together, the provider refused requests and helpers died. The lead agent read this as a time limit and replaced the miners with narrower tasks, which shrank the round (13% coverage in that n8n run). The harness now retries patiently, and `mining.md` says to read a helper's error, retry after a rate limit with fewer at a time, and not substitute a narrower task.
- **Working files outside the repository.** The first draft put them outside the repository; in the sandbox an agent can write only inside it, and the temporary directory is private to each command. `mining.md` and Doctor's catch-up now use `.ssot-work/` with its own `.gitignore`.
- **A resumed session.** One stopped build session was resumed by another dsh host on the same machine and kept working in its copy; the 1Panel cheap-model build that followed is excluded. The harness now closes any session it stops.

## What this does not show

- Whether mined, partly overbroad rules make agents ask about ordinary work; that test was still running.
- Precision near the 90% target with the cheap model, or coverage near complete: the best builds reached about half of each area's rules.
- 1Panel with the cheap model, more builds per repository, other models, and areas not declared in advance.
- That the history source is used well: rules the answer key found mainly in the history were covered less often (jellyfin build 1: 5 of 14, against 20 of 30 found in the code; n8n: 5 of 17 against 15 of 30).
- Executed changes: the judge read plans, not code.
