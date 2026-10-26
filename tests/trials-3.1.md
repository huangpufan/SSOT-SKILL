# Evidence for 3.1 (2026-10-27)

This records what 3.1 was tested on, so the claims in `CHANGELOG.md` can be
checked. Every run used a copy of a real repository; no real repository was
changed. Each cell ran once, with one model (Claude Code, headless) acting as
the agent, so the results show what can happen, not how often.

## 1. Mentions of files that no longer exist

**The question.** SSOT documents name the file that holds a detail instead of
copying it. When a later change deletes or moves that file, does the
sentence around it get fixed?

**Real repositories.** The new checker ran, read-only, on clones of three
repositories that have used SSOT (v2 layout) for three to five months:

| Repository | Warnings | Run time |
|---|---|---|
| a desktop app | 0 | under 2 s |
| a web service | 158 | under 1 s |
| an agent platform | 36 | under 1 s |

A separate agent (codex) labeled 72 warnings blind: all of the agent
platform's warnings from an earlier build of the check (27), and 45 random
ones from the web service. It read each sentence in its document and the git
history:

- 32 were **stale**: the sentence still presented the file as current. For
  example, a testing guide called a deleted test "the regular deterministic
  gate", and an architecture page still described a module under its old
  name after a move.
- 33 were deliberate **history** ("was deleted", "do not revive", "see git
  history").
- 6 were point-in-time **records**: a bug report's list of files from its
  fix.
- 1 was a **checker mistake**: inline code used as a link label whose
  target was correct. Link labels are skipped since then.

So "this path is gone" was right in 71 of 72, and about 44% of the warnings
pointed at a sentence that needed fixing. We also tried filtering by
`git blame`, warning only where a line was older than the removal. That would
have hidden 5 of the 32 stale sentences: people had edited those lines
without fixing the path. Instead, a line that names the removing commit
counts as deliberate history and is not reported.

**Recall and speed on large histories.** Each of two larger clones got a
README listing 40 random deleted paths and 40 random live ones. One clone
has 20,734 commits; the other has 2,242 commits and long non-ASCII file
names. In both, every listed path that is absent today was reported (38 and
40; two of the deleted paths had been added back later), and no live path
was. The run on the 20,734-commit history took under 7 seconds, most of it
reading 8,266 merges; the other took about 2 seconds.

**Behaviour in closeout (the trial in section 2).** Two tasks deleted or moved
files that SSOT mentioned: renaming a module (T1), and folding two files into
others (T7). In both arms (3.0 and 3.1), the agent found and fixed every
mention itself, before or without the checker. In this repository the
checker only confirmed the result. So far its demonstrated value is finding
the backlog that earlier work left behind, not changing closeout behaviour.

## 2. Closeout and preflight changes

**Set-up.** A clone of a small repository was bootstrapped with SSOT 3.0: a
Rust terminal memory monitor with an optional process-killing guard, about
4,500 lines and 44 commits. A fresh headless agent
did the setup with no user answers: 9 documents, 13 invariants (3 confirmed
from `AGENTS.md`, 10 candidates), and 3 open questions. Each task then ran
twice from that state, once with the 3.0 skills (baseline) and once with the
3.1 candidate.

| Task | 3.0 | 3.1 |
|---|---|---|
| T3: "From now on, never kill without SIGTERM first", interrupted at the agent's first edit under `src/` | 2 of 2 runs lost the rule: no SSOT write before the first code edit | 4 of 4 runs with "before you change anything else" wrote the rule first; an earlier draft lost it in 1 of 1 |
| T4: a musing ("maybe drop macOS some day, don't act on it") plus a small feature | musing not recorded | musing not recorded |
| T5: the user asks for something a candidate rule forbids (guard kills other users' processes as root) | implemented; recorded as the user's decision; rule updated | same |
| T1: rename a module file | all 3 SSOT mentions fixed | same |
| T7: fold two files into others | all mentions fixed | same |
| T2: internal refactor | wrote nothing; ran the checker | wrote nothing; skipped the checker |

T3 is the change that matters. The 3.1 wording changed twice during the
trial, and each change came from a run:

1. The first draft said to write such a rule "once it is settled". The agent
   read that as "later", edited code first, and the interruption lost the
   rule (1 of 1).
2. The wording became "before you change anything else". Both runs wrote the
   rule first. One of them also wrote "the emergency path was removed"
   before changing any code, so the interrupted copy claimed work that had
   not happened.
3. The wording gained "label what the code does not do yet as planned". In
   both runs, the agent recorded the rule as a confirmed invariant with a
   decision record and marked the code change "planned, not built yet".

This shows that the rule was written down before the interruption. It does
not show that the rule is enforced afterwards.

T1 and T2 ran with the first draft; the closeout and checker behaviour they
test did not change afterwards. T4 and T5 showed no false capture and no
extra questions. Cost per task was similar between arms. The two most costly
3.1 runs were also the ones where the agent found and fixed real defects in
the tool (for example, clock drift on WSL2 that blocked every signal). So
these runs do not show whether 3.1 changes cost.

## What this does not show

- Migration of a v2 SSOT with the 3.1 procedure (persistent `BOOTSTRAP.md`,
  absorbing other documents, the newcomer test) has not been run end to end.
- One run per cell, one model, one harness, one small repository for the
  behaviour trial.
- Whether people find the generated documents readable.
- Native Windows, submodules, and grafted or replaced histories in the
  checker. These are untested.
