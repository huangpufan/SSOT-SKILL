---
review_id: "review:<product|architecture>:<YYYYMMDD>:<slug>"
review_scope: "<SSOT/01-product | SSOT/02-architecture>"
review_type: "<high-impact-adoption | routine>"
reader_profile: implementation-delegator
completeness_profile: "<product | architecture>"
protocol_version: "<tracked_skill_version>"
reviewed_on: "<YYYY-MM-DD>"
reviewer: "<stable-human-or-agent-id>"
reviewer_role: "<independent-cold-reader | scoped-self-review>"
repository_commit: "<resolvable ancestor-or-equal commit>"
content_fingerprint: "<shared-reader-surface lowercase sha256>"
quality_disposition_fingerprint: "<lowercase-sha256>"
sample_seed: "<stable-seed>"
rotation_id: "<stable-rotation-id>"
task_count: 6
passed_task_count: "<count>"
failed_task_count: "<count>"
entrypoint: SSOT/README.md
tables_hidden: true
bounded_read_set: true
route_probe: "<passed | failed>"
truth_consistency: "<passed | failed>"
evidence_sample: "<passed | failed>"
scored_dimensions: 16
score: "<score>/32"
critical_truth_errors: "<count>"
unresolved_required_changes: "<count>"
authorises: "<area:product:covered | area:architecture:covered>"
verdict: "<needs-fix | no-more-required-changes>"
---
# Cold-reader review

<!-- The rendered artifact has exactly the 29 scalar frontmatter fields shown
     above, once each, with no aliases or extra keys. `reviewer` is a stable
     identity, not a display label that changes between runs. `authorises`
     matches review_scope and completeness_profile exactly. -->

<!-- Store the rendered review under SSOT/.bootstrap/ and replace every
     placeholder. `high-impact-adoption` requires an independent cold reader;
     a `routine` review follows the reviewer-role rule in status-protocol §6.
     Reviewer role is separate from the implementation-delegator reader profile. -->

<!-- Write for an implementation delegator: begin each task with a concrete
     situation and decision; record the delegated action, visible success,
     failure/recovery, and fitting evidence before paths or internal labels. -->

<!-- Every owner or evidence link in the rendered artifact is relative and
     resolves to a real, regular, non-symlink Markdown file inside this
     consumer's SSOT/. It never uses an absolute path, URL, workspace-external
     path, SSOT/.bootstrap/ review artifact, or this artifact itself. A linked
     fragment exists in the target file. Headings, tables, evidence, and the
     verdict count only in visible Markdown: content hidden in HTML comments or
     code fences cannot satisfy the protocol. Remove all authoring comments and
     placeholders before recording a passing verdict. -->

## Bounded reading set

<!-- Start every task at SSOT/README.md. Record actual files and at most four
     owner-link hops. Do not use source, manifests, prior reviews, or the
     expected answer before the first teach-back. Put the route probe here; do
     not create a seventh H2 section. -->

| Step | Page | Reason | Hops | Friction |
|---|---|---|---:|---|
| 1 | SSOT/README.md | Initial reader route | 0 | |

### Mandatory task matrix

<!-- Product uses each exact product-* class in reader-quality §7.2 once;
     architecture uses each exact architecture-* class there once. `Files
     opened` records the actual consumer-SSOT Markdown files. `Evidence and
     limit` begins with one relative consumer-SSOT Markdown owner/anchor link;
     a bare path or a link outside SSOT is not evidence. -->

| Task class | Reader and decision | Delegated action | Expected visible result | Stop or escalate when | Entrypoint | Files opened | Actual hops | Observed outcome | Table-hidden result | Evidence and limit | Verdict |
|---|---|---|---|---|---|---|---:|---|---|---|---|
| <exact-task-class> | | | | | SSOT/README.md | | | | pass / fail | | pass / fail |

### Task-to-leaf applicability

<!-- Map every RF1-RF2, LA1-LA3, CT1-CT4, BC1-BC4, and RP1-RP3 leaf to one
     or more mandatory tasks before scoring. -->

| Task class | Applicable leaf IDs | Why applicable |
|---|---|---|
| <exact-task-class> | <comma-separated leaf IDs> | |

### Finite owner and target coverage

<!-- Reconcile the complete frozen target population, not a convenient sample.
     Product includes every product-spine, capability, and journey owner, every
     product-surface inventory row, and every product-to-architecture bridge
     row. Architecture includes every root/view/domain reader owner, direct
     owner classification, applicable or reasoned-exception cross-owner view,
     technical-surface row, and bridge row. Include reasoned not_applicable or
     merged dispositions. Each stable target ID appears exactly once, is
     assigned to at least one mandatory task, and has a plain-language decision,
     delegated action, and visible result. A passing artifact has no missing,
     duplicated, unassigned, deferred, or failed target. Deep source/runtime
     evidence may rotate, but owner/target coverage may not. Run this complete
     sweep after the first table-hidden teach-back; it cannot repair a failed
     bounded route or change that teach-back. Use one reconciliation row per
     applicable frozen-population token shown below; remove the option list and
     do not combine several populations into one count. -->

| Frozen population | Source inventory | Expected targets | Listed targets | Reconciliation result |
|---|---|---:|---:|---|
| product-reader-owner / product-surface / product-bridge / architecture-reader-owner / architecture-direct-owner / architecture-view / technical-surface / architecture-bridge | [frozen inventory](<relative-SSOT-markdown-path-or-anchor>) | <count> | <count> | pass / fail |

| Target ID | Target kind | Frozen disposition | Owner/body | Assigned mandatory task | Decision, delegated action, and visible result | Result | Evidence and limit |
|---|---|---|---|---|---|---|---|
| <stable-target-id> | reader-owner / product-surface / technical-surface / cross-owner-view / bridge | <exact inventory disposition> | [owner/body](<relative-SSOT-markdown-path-or-anchor>) | <exact-task-class> | | pass / fail | [fitting owner/evidence](<relative-SSOT-markdown-path-or-anchor>); <what it does not prove> |

### Route probe

<Record wrong turns, missing owners, and over-budget tasks.>

## Teach-back

<!-- Hide Markdown tables. The implementation delegator must explain the
     current causal story, visible outcome, boundary, failure/recovery, and
     next decision without reading code. They must also recognise what to
     delegate and how to accept the result. -->

### Table-hidden teach-back

<Write the cold reader's account.>

### Unclear or unrecoverable points

<Name the point and the nearest owner that must teach it.>

## Consistency and evidence sample

### Cross-owner truth consistency

<!-- Owner and compared-owner cells use relative consumer-SSOT Markdown links
     to the exact bodies or anchors being compared. -->

| Claim | Owner | Compared owner | Result | Note |
|---|---|---|---|---|
| | | | pass / fail | |

### STATUS covered-claim closure

<!-- A no-more-required-changes product or architecture claim has exactly one
     current Stop Review Gate row. Its reviewer, reviewer role, reviewed date,
     result, evidence artifact, and authorises value match this artifact. The
     STATUS Evidence cell resolves to this exact artifact; do not add a
     self-link here. A high-impact adoption uses independent-cold-reader in both
     places. A needs-fix artifact may have no STATUS row—the missing row may be
     the failure. In that case use the exact sentinel `none: needs-fix does not
     authorise covered`, Evidence=no, and Match=not-authorised. Never retain a
     passing current row that authorises the failed claim. -->

| STATUS row | Scope | Stop claim | Reviewer | Reviewer role | Reviewed date | Result | STATUS evidence resolves to this artifact | Authorises | Match |
|---|---|---|---|---|---|---|---|---|---|
| <[current Stop Review Gate](../STATUS.md#stop-review-gate) OR none: needs-fix does not authorise covered> | product / architecture | covered | <same-stable-reviewer> | independent-cold-reader / scoped-self-review | <same-YYYY-MM-DD> | needs-fix / no-more-required-changes | yes / no | area:product:covered / area:architecture:covered | pass / not-authorised / fail |

### Evidence sample

<!-- One row per mandatory task. Path existence is insufficient: record claim,
     semantic fitness, browser real-runtime versus rendered-mocked fidelity,
     freshness, observed result, and the sample limit. Each Evidence cell has
     exactly one relative consumer-SSOT Markdown owner/anchor link; describe the
     lower-level source/runtime item checked in the fitness cell. -->

| Task class | Claim | Evidence | Fitness, fidelity, and freshness | Result | Limit |
|---|---|---|---|---|---|
| <exact-task-class> | | | | pass / fail | |

### Cold proof gates

| Probe ID | Evidence from mandatory tasks | Result | Limit |
|---|---|---|---|
| CP-D | | pass / fail | |
| CP-R | | pass / fail | |
| CP-T | | pass / fail | |
| CP-E | | pass / fail | |
| CP-C | | pass / fail | |

## Dimension scores

<!-- Score each task/leaf pair 0, 1, or 2. A leaf is the minimum of its
     applicable task scores. Passing is >=29/32, no zero, family floors
     RF>=3, LA>=5, CT>=7, BC>=7, RP>=5; implementation-delegator also requires
     RF1=2 and LA2=2. Each Reason and page cell contains one relative link to
     the consumer-SSOT body or anchor whose visible prose supports the score. -->

| Family | Leaf ID | Dimension | Applicable task scores | Score /2 | Reason and page |
|---|---|---|---|---:|---|
| Reader fit | RF1 | Reader, decision, and action fit | <task=score;...> | | |
| Reader fit | RF2 | Orientation and visible outcome | <task=score;...> | | |
| Plain-language clarity | LA1 | First-use terminology | <task=score;...> | | |
| Plain-language clarity | LA2 | Plain-language cognitive load | <task=score;...> | | |
| Plain-language clarity | LA3 | Concrete grounding | <task=score;...> | | |
| Causal and truth story | CT1 | Causal chain | <task=score;...> | | |
| Causal and truth story | CT2 | Current truth and cross-owner consistency | <task=score;...> | | |
| Causal and truth story | CT3 | Posture, uncertainty, and change | <task=score;...> | | |
| Causal and truth story | CT4 | Success, failure, and recovery | <task=score;...> | | |
| Boundary and coverage | BC1 | Boundaries and non-goals | <task=score;...> | | |
| Boundary and coverage | BC2 | Unique owner and handoff reachability | <task=score;...> | | |
| Boundary and coverage | BC3 | Evidence fitness, fidelity, freshness, and invalidation | <task=score;...> | | |
| Boundary and coverage | BC4 | Scope completeness | <task=score;...> | | |
| Reading path | RP1 | Scannability and progressive disclosure | <task=score;...> | | |
| Reading path | RP2 | Bounded route and locality | <task=score;...> | | |
| Reading path | RP3 | Table-independent narrative | <task=score;...> | | |
| **Total** | | | | **/32** | |

## Completeness profile

<!-- Product records exactly 53 rows: C01-C09, P01-P23, and Q01-Q21 once each.
     Architecture records exactly 48 rows: C01-C09, A01-A18, and Q01-Q21 once
     each. Use covered or
     not_applicable; every row needs a reason and evidence/owner direction.
     C08 checks ordinary-language explanation before unavoidable terms,
     assumptions, states, commands, or evidence labels. C09 requires a concrete
     scene with the decision, delegated action, visible result, and fitting
     evidence. P21 includes command, public-interface, output-artifact,
     notification, and help-onboarding surfaces. Missing metrics/traces are a
     named gap when the runtime needs them, not a casual N/A. P22 explains the
     current problem/value/promise; P23 owns sustained value and the honest
     feedback-to-roadmap learning loop. A18 owns design drivers, invariants,
     trade-offs, technical non-goals, and decomposition rationale. Every Reason
     and evidence cell includes one relative link to its consumer-SSOT owner or
     exact boundary anchor; owner-name strings and bare paths do not count. -->

| Item ID | Disposition | Reason and evidence |
|---|---|---|
| <exact-item-id> | covered / not_applicable | |

## Required changes and verdict

<!-- Use one row per real change with a unique RC-NN ID and status resolved,
     pending, required, or open. pending/required/open rows must equal
     unresolved_required_changes. For a passing review with no historical
     resolved row, use exactly the `none` sentinel shown below. Never mix the
     sentinel with real rows. A real row's Owner and Closure evidence links obey
     the same relative, in-consumer-SSOT boundary as the rest of the artifact. -->

| Change ID | Status | Required change | Owner | Closure evidence |
|---|---|---|---|---|
| none | none | No required change remains after this review. | — | The unresolved count is zero and the final verdict is no-more-required-changes. |

<!-- no-more-required-changes requires all six tasks, five cold proofs, exact
     completeness rows including Q01-Q21, the matching quality-disposition
     fingerprint, score/family/persona floors,
     truth/evidence checks,
     complete finite owner/target coverage, one matching STATUS stop row, and
     zero critical errors or unresolved changes. Otherwise use needs-fix.
     The visible verdict below, frontmatter verdict, unresolved count,
     and required-changes rows always agree. A passing verdict also agrees with
     the required STATUS result; a needs-fix verdict may use the
     not-authorised sentinel when no stop row exists. -->

Final verdict: `<needs-fix|no-more-required-changes>`.
