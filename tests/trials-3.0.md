# Behavior trials for 3.0 (2026-10-26)

This records how the 3.0 candidate was tested against v2 and against no SSOT
at all, so the claims in `CHANGELOG.md` can be checked. The trials used copies
of real repositories. No real repository was changed.

## Set-up

The consumer was a desktop application (Electron, about 2,300 tracked files)
whose SSOT was written under v2.64. We made three copies of the same commit:

- **v2**: the original SSOT, with the last v2 skills (2.86) installed.
- **v3**: the same SSOT after a fresh agent migrated it with an early draft
  of `ssot-bootstrap` section 7. SSOT shrank from 829 KB to 518 KB. The
  final procedure added steps, including keeping `GAP-` IDs (the trial
  migration dropped them), handling `apex-maxim` rows, sorting before
  deletion, and repointing tooling. Only the tooling step was later applied
  to this copy.
- **none**: `SSOT/` and the SSOT skills removed. The repository's own
  `AGENTS.md`, code, and other documents stayed.

Six questions came from real maintenance work: changing a target-window
check, a paste failure in a console, an integration's send behaviour (the
asked-about mode does not exist in the snapshot, so a good answer says so),
claiming macOS done from Windows evidence, finishing a UI change, and what an
agent may do alone when releasing. For each question and each copy, a fresh
agent started the task as the repository's instructions direct and answered
without changing files. That made 18 answers.

An agent with full read access built an answer key from the code, the
decision records, and the user's recorded instructions. The key marked
must-have points and listed eight stale statements that exist in the
documents. Judges saw the three answers to one question under random labels,
with paths and reading logs removed. They scored each must-have point 0–2,
listed errors, counted noise (burdens unrelated to the task), and gave a
usefulness score from 1 to 10. Full blinding was not possible, because the
answers' wording reveals the documentation they read.

## Results

Must-have score (fraction of the maximum) and usefulness:

| Question | v3 | v2 | none |
|---|---|---|---|
| Q1 target check | 27/28 · 8 | 28/28 · 8 | 22/28 · 7 |
| Q2 console paste | 12/12 · 8 | 12/12 · 9 | 10/12 · 8 |
| Q3 send mode | 11/12 · 8 | 10/12 · 7 | 9/12 · 6 |
| Q4 macOS claim | 7/8 · 8 | 8/8 · 7 | 7/8 · 8 |
| Q5 UI change | 9/10 · 6 | 10/10 · 8 | 9/10 · 7 |
| Q6 release | 12/12 · 6 | 12/12 · 8 | 11/12 · 7 |
| Mean of fractions | 94% | 97% | 84% |
| Noise items, total | 6 | 14 | 0 |
| Tokens, six answers | 0.74 M | 0.74 M | 0.72 M |

Where the noise came from:

- **v2:** every answer reported protocol lag and asked the user to run an
  audit before SSOT could be written. Several also asked the user to decide
  on stale coverage labels.
- **v3:** all six items were one claim, "the commit gate is broken", which
  was true in that copy. The migration had left the repository's scripts
  calling v2's `ssot-lint.sh`.

That migration gap was fixed in the procedure (`ssot-bootstrap` §7, step 9).
A fresh agent then applied the new step to the v3 copy, and Q5 and Q6 were
re-run there and judged blind again:

| Question | v3 after fix | v2 | none |
|---|---|---|---|
| Q5 UI change | 10/10 · 9 · 0 noise | 10/10 · 7 · 3 noise | 9/10 · 7 · 0 noise |
| Q6 release | 12/12 · 9 · 0 noise | 12/12 · 8 · 2 noise | 10/12 · 7 · 0 noise |

Q1–Q4 were not re-run after the fix.

## Other trials

- **Closeout, nothing durable:** an internal refactor. The agent compared
  the owners and wrote nothing to `SSOT/`, which `git status` confirmed.
- **Closeout, durable change:** the user shortened a retention period. The
  agent updated the behaviour owner, added a decision record, and kept the
  old decision as history with a pointer. No current statement of the old
  value remained.
- **Conflict:** the user asked for a pop-up that a confirmed rule forbids.
  The v2 and v3 agents both stopped and offered options. v3 used 69k tokens
  and 11 tool calls; v2 used 105k and 20.
- **Setup from scratch:** on a smaller web application with a 307-line
  `AGENTS.md`. The result was 7 documents of about 50 KB, plus 6 registered
  rules. An independent newcomer test answered 5 real tasks correctly. The
  run also found two real bugs in that application.

## What these results do not show

- Only one consumer was migrated, and it was a single snapshot.
- There was one run per cell, so the numbers carry no statistical weight.
- Every agent was the same model, in the same harness.
- Long-term maintenance over many batches was not observed.
- Judges graded against the original repository, which disadvantaged
  answers that cited rules numbered only in the migrated copy. The re-judge
  corrected for this.
- 3.0 did not reduce reading cost.
