---
name: ssot-doctor
description: Check the health of a repository's SSOT, review it against the code, or catch it up on past commits. Use when the user asks for an SSOT health check, review, or catch-up (for example "sync SSOT with the recent commits"), or when another SSOT skill routes here. Runs the mechanical checker plus an agent review of the requested scope, and reports exactly what was checked.
---

# SSOT Doctor

Find where `SSOT/` is wrong, missing, contradictory, or hard to use, and say exactly how far your check went. The model you check against is [`memory-model.md`](../ssot-preflight/references/memory-model.md).

## 1. Agree on the scope

If `SSOT/README.md` has no `ssot_format: 3` (usually a v2 layout), review read-only and offer migration with `$ssot-bootstrap`. Do not write to it.

The scope is the whole SSOT, one area or file, or a catch-up from a given commit. State it in your report. Findings, and any statement that something is healthy, cover only that scope.

## 2. Run the mechanical check

From the repository root, run `python3 <this skill's directory>/assets/scripts/ssot-check.py SSOT`. It reports errors (a missing entry point, broken links or heading anchors, a malformed invariants register) and warnings (oversized files, v2 leftovers, and mentioned files that git says were removed or moved). It cannot tell whether a statement is true or readable. That part is your review; the removal warnings are a good place to start. Exit code 3 means the run was incomplete: the checker crashed or could not examine part of the tree. That is never a pass, and any errors it did list are still real. Errors in files outside your scope do not stop the review of your scope. Report them separately.

## 3. Review the scope

- **Truth.** Pick the statements a future task would act on, such as contracts, state ownership, commands, and "planned" labels, and check them against the code, configuration, and tests. Start with areas that changed recently in `git log`.
- **Consistency.** Look for one fact stated two different ways, and for superseded decisions still presented as current.
- **Invariants.** Every row links to an explanation inside `SSOT/`. No rule changed meaning or status without a recorded user decision. List the candidates that are still waiting for the user to confirm them.
- **What does not belong.** Flag restated code, proof of a single task, edit history, and status about the documents themselves.
- **Usefulness to a newcomer.** If you can start a helper with a fresh context, give it three to five real tasks for this repository. Include at least one normal path, one failure or recovery case, and one boundary judgment ("may I change X?"). The helper starts from `SSOT/README.md` and reads only `SSOT/`. Then check its key answers against the code, configuration, and confirmed decisions: an answer that matches a wrong document is a finding about the document. Report which tasks you used. If no helper is available, say that this check was your own reading.

## 4. Catch up on past commits

Use this when commits landed without SSOT updates, or when the user asks for a catch-up.

1. **Fix the range before you start.** The start is `reviewed_through` in the README's front matter, or a commit the user names. If the user asks for earlier history, the field does not limit you. If there is no start, ask the user, and suggest the commit that created `SSOT/`. Resolve the start and `HEAD` to full commit SHAs and use those two SHAs throughout, even if `HEAD` moves while you work. If the start is missing from the history or is not an ancestor of the end, the range is not empty. Stop and ask the user.
2. Work through the range oldest first, along the main line of history (`git log --first-parent --reverse <start>..<end>`), in segments of a few dozen commits; a long range may take several sessions. For each commit, read its message, and read its diff when the message or the files it touches suggest a durable fact. List the durable facts the segment introduced that SSOT does not hold yet. The categories are the same as in `$ssot-closeout` step 1. Keep working files, such as commit lists, outside the repository, so an interrupted session leaves nothing behind.
3. Write them by the closeout rules: single owner, remove superseded statements, protect invariants.
4. Move `reviewed_through` last. Only when every fact a segment introduced is written, set it to the segment's last commit; a session interrupted after an earlier move would skip the facts not yet written. The next catch-up resumes there instead of starting over. A segment is not done if you skipped some of its commits, sampled them by kind, or found facts you did not write: leave the field before it. A review limited to some paths or owners moves nothing. Report how far the field moved and what remains.

## 5. Report

Report the scope, the checker result, and the findings ordered by impact, each with its file and evidence. Separate what you fixed from what remains, and list what you did not check. Fix things only when the user asked for fixes or another SSOT skill sent you here to fix them. Otherwise report and let the user decide.
