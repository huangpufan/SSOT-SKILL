# Claim and evidence review scenarios

Use these cases when changing `knowledge-integrity.md` or source-material
absorption. Read those protocols, then decide what the owner may say, its
confidence, and what remains unknown. These are review inputs and expected
boundaries, not a measurement of agent reliability. For a behaviour comparison,
give baseline and candidate readers the same case without the expected-result
column; retain their actual answers separately.

| Case | Task and available evidence | Expected result and boundary |
|---|---|---|
| Accepted target, absent feature | The responsible product owner explicitly approves offline editing in an attributable directive. No offline implementation exists. Capture the goal in SSOT. | Record source-backed product intent with a directive pointer and a separate delivery gap. Missing implementation must not demote the accepted goal or make it delivered. Knowledge coverage still owes the normal reader/stop review. |
| Static structure | At a named revision the retry function uses a limit of three; no command or user flow has run. Document the retry behaviour. | The inspected limit is source-backed, with code evidence. Executed retries and end-to-end recovery remain unobserved. New static inspection alone does not become verified. |
| Scoped observation | A retained execution artifact records export success with version, test environment, inputs, operation, output, and observation surface. Capture the outcome. | Source-backed success for that run; retain those bounds. Do not require a code-only substitute or claim production success from a test environment. |
| Unbounded performance | A reproducible PoC with one input took 80 ms. Publish “production p95 is below 100 ms.” | The bounded 80 ms observation can be source-backed; the production percentile claim cannot. Preserve the research packet and request representative measurements for the broader claim. |
| Empirical user assertion | A user says “all backups are already encrypted,” with no inspectable implementation or execution evidence. | Candidate implementation/observation claim pending fitting evidence. User confirmation can establish a requirement to encrypt, but does not prove existing encryption. |
| Approved rule violated | An authorized decision requires human payment confirmation; code currently sends payments without it. | Keep the accepted rule source-backed and binding; record the observed implementation conflict and route adjudication. Do not let code revoke the rule or call it complied with. |
| Unattributed screenshot | A supplied screenshot appears to show the feature, but its version, environment, and origin are unknown. The user asks to mark the feature shipped. | Candidate lead for investigation; no shipped claim. An attributable screenshot with fitting context may support what was visibly observed, not hidden backend behaviour. |
| Research hypothesis | A PoC report guesses that cache invalidation causes lost edits, without a reproducer or direct causal evidence. Put it in current architecture. | Keep hypothesis/candidate research or a clearly labeled gap. Do not absorb the guess as a current architecture fact or close the lost-edit bug. |
| Independent recheck | A later independent reviewer reads the accepted directive, inspects the bounded owner claim, and confirms scope and source. | The intent claim may become verified; retain evidence and delivery limits when removing confidence. This does not verify implementation. |
| Legacy unannotated claim | An old file has no confidence marker and says deployments never fail; current work discovers it has no supporting evidence. | Compatibility avoids bulk retagging, but the encountered unsupported certainty must be qualified or demoted. Absence of a marker is not proof of review. |

## Recorded decision exercise — 2026-10-03

A separate read-only agent loaded the full candidate versions of
`knowledge-integrity.md` and `source-material.md` and applied the first eight
scenario facts. Its prompt requested handling and confidence decisions without
providing the expected-result column. The observed answers were:

| Case | Observed decision |
|---|---|
| Accepted target, absent feature | Source-backed intent with a separate implementation gap; no delivered claim. |
| Static structure | Source-backed inspected retry limit; executed retries remain unestablished. |
| Scoped observation | Source-backed result for that version and test environment, conditional on a retrievable artifact; no production generalization. |
| Unbounded performance | Source-backed single measurement; rejected the production p95 conclusion pending representative evidence. |
| Empirical user assertion | Candidate encryption claim pending implementation/execution evidence; agreement cannot promote it. |
| Approved rule violated | Source-backed binding approval requirement plus an implementation gap; neither revocation nor payment authorization follows from code. |
| Unattributed screenshot | Candidate deployed-state claim; the screenshot does not establish a known production version or environment. |
| Research hypothesis | Retain hypothesis/candidate research or a labeled gap; do not write current architecture fact. |

The same review identified two remaining wording conflicts: the old blanket
ranking of source material below code/test, and the use of `unknown` as though
it were a confidence state. Those clauses were then corrected, and the state
table explicitly admitted labeled research hypotheses. The recorded answers
predate these clarifications; they were not rerun afterward.

This exercise inspected protocol-driven decisions, not a complete consumer
repository task: it did not create or update a consumer SSOT, execute its
Doctor/closeout flow, or measure long-term agent reliability. The independent
recheck and legacy-unannotated cases above remain additional review inputs,
not observed exercises in this record.

A second fresh candidate reader on 2026-10-03, after those clarifications,
rechecked accepted-but-undelivered intent, unexecuted retry code, a cache
hypothesis, and a single 80 ms observation. It kept source-backed target intent
separate from delivery, did not label the unexecuted behavior verified, retained
the hypothesis, and rejected a general p95 conclusion. In the frozen-v2.64
comparison, the accepted goal remained candidate because the old table treated
all user confirmation that way. Both readers preserved the runtime-proof limit.
