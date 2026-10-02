# Bootstrap completion and evidence retention scenarios

Apply `ssot-bootstrap/references/bootstrap.md` to these cases, including the
entry route in both bootstrap and preflight. Decide whether setup is active,
what may be removed, and which evidence must still resolve afterward. These
are review cases, not executed consumer tasks or reliability measurements.

| Case | Repository state or action | Required result |
|---|---|---|
| Reviews after completion | STATUS has supported `converged`; `.bootstrap/` contains current reader-review and scope-review artifacts only. An ordinary code task starts. | Route through normal preflight; retained evidence alone must not restart bootstrap or be deleted. |
| Interrupted setup | STATUS says `bootstrap`; manifest has an active fill phase and a blocked convergence phase. | Resume the recorded phase and prerequisites; preserve completed work and session evidence. |
| Explicit unfinished coordination | An active manifest has a pending cleanup phase, even though review preparation is finished. | Continue the unfinished phase; proposed cleanup and an earlier passing review are not completion. |
| Historical manifest | STATUS has supported completion; the retained manifest has a historical note linked to completion evidence. | Treat it as evidence, not current assignments. No automatic restart because its directory or historical rows remain. |
| Conflicting status | STATUS says `converged`, but an apparently current manifest has blocked phases and no final completion evidence can be recovered. | Investigate the conflict, preserve records, resume missing work and correct unsupported claims. Do not assume either deletion or restarting every phase is warranted. |
| Directory absent | `.bootstrap/` has been deleted, but STATUS still says `bootstrap`. | Missing files do not prove success; reconstruct the missing progress/evidence or report the specific recovery gap. |
| Referenced session | A covered owner's evidence or a frozen review links to `sessions/003-storage.md`. | Retain the resolving target and its evidence. A STATUS summary cannot replace that artifact. |
| Unique unabsorbed finding | A session contains the only rejected-design rationale and a new unresolved failure lead. | Absorb or route the long-lived facts, preserve the supporting record, and keep remaining work visible before closing cleanup. |
| Redundant coordination | An unreferenced assignment scratch file duplicates retained records, has no unique findings, and no worker writes it. | Removal is permitted after review of the concrete cleanup plan; retaining it is also valid. Do not remove other files by directory-wide deletion. |
| Frozen recon | The original recon is frozen or its content/path is used by existing review evidence. | Keep original bytes and path; let the archival decision entry point to it. Do not silently rewrite frozen evidence for convenient relocation. |
| Movable recon | An unfrozen recon can be relocated safely. | Archive it, preserve its body evidence, and check both incoming anchors and its own relative links. Preserve old routes required by historical references. |
| Review invalidation | Absorption or archival changes an owner covered by a fingerprinted review. | Check the applicable fingerprint and refresh the affected review before claiming completion. A link that still opens is insufficient. |
| Worker still active | A session file appears redundant, but its assigned worker still runs. | Keep the file and coordinate completion first; cleanup must not erase an active writer's output. |
| Repeated cleanup | Cleanup already finished and a later task reviews retention. | Recognize the completion evidence, preserve historical artifacts, and perform only any newly justified maintenance; do not rerun initialization or invent a fresh completion. |

Template inspection must cover both languages: neither manifest template may
instruct recursive removal of `.bootstrap/`, and both session templates must
retain unique findings and referenced evidence. An end-to-end verification
would exercise actual consumer routing, cleanup, retained links and review
freshness; the presence of this scenario table does not establish that result.

## Recorded execution comparison — 2026-10-03

Separate agents actually created and edited the same seven-file synthetic
consumer for Phase 4. Prior-phase passes, existing reviews, and tracking
baselines were supplied assumptions, not newly verified results. The execution
reports are `cleanup-baseline-result.md`, `cleanup-candidate-result.md`, and
`cleanup-candidate-fixed-result.md` from this review run.

| Run | Observed actions and result |
|---|---|
| Frozen baseline | The independent cleanup reviewer first rejected deletion because it would lose unique sampling limits and a rejected experiment. The agent moved both passages into the retained reader review, rewrote their links, obtained a passing cleanup review, then deleted the manifest and both sessions. All six final Markdown references resolved and both passages remained. STATUS stayed `in_progress`. This run did **not** lose the evidence; its reviewer prevented that outcome. |
| First candidate, changing protocol | The agent retained the referenced manifest/session and removed only redundant session 002. File/link checks passed, but the protocol changed from 2.71 to 2.73 during execution. The final version check failed; the agent withdrew completion and left cleanup `blocked`. The earlier no-bootstrap-route prediction was not established in this run. |
| Candidate frozen at 2.74 | On a fresh fixture, only session 002 was deleted; six initial files remained. README, both existing reviews, and session 001 retained their original hashes. The unique passages and original evidence anchors remained in place; all 17 final local references resolved. Independent plan and execution reviews passed. The final checks confirmed unchanged protocol hashes, synthetic STATUS `converged`, and manifest historical/cleanup done. The state-based route check required bootstrap while cleanup was active, then returned false after completion. |

The fixed run also retained an intermediate failed check caused by linking a
JSON artifact before generating it. The agent corrected the generation/link
order and reran the checks successfully; this failure was not hidden.

The observed difference is preservation of original evidence paths and review
bytes instead of mandatory process-file migration/deletion. These runs do not
establish a baseline data-loss rate or general reliability gain. No fixture
included recon, so recon archival was not exercised. Neither the complete
bootstrap/Doctor flow nor a subsequent ordinary development task was run;
the final routing result is a check against the actual fixture state and
frozen entry rules, not a completed next task.
