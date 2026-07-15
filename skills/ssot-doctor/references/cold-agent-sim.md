# Task-Based Cold-Reader Review (v2.60)

This file owns execution of the cold-reader gate. It does not own or fork the
artifact schema. [`reader-quality.md §7`](../../ssot-preflight/references/reader-quality.md#7-cold-reader-acceptance)
owns the fields, exact task classes, 16 scored leaves, completeness IDs, cold
proofs, thresholds, and six H2 sections. Lint proves deterministic structure;
this review proves that an implementation delegator can route, understand,
check, decide, and act without reading code or receiving the author's private
context. The delegator must be able to tell an implementation Agent what to
change, name the visible result and evidence they expect back, and know when to
stop or escalate.

The review is task-based. It no longer treats recent commits or abstract
intent/truth pillars as the reader's job.

Before execution, load the unique definitions this harness applies rather than
guessing from template placeholders: `reader-quality.md` §§2.1-2.4, 3, 4, and 7
for the common/scope/Q IDs, six exact task classes, cold proofs, fingerprints,
scores, and artifact schema; then load `status-protocol.md` §6 for reviewer and
Stop Review authority. If either owner is unavailable, the review is blocked;
this harness deliberately does not copy their vocabularies.

## 0. When to run

Run the gate:

- during the reader-surface regeneration loop in bootstrap;
- after a large product or architecture rewrite, split, merge, or protocol
  upgrade that changes the generated reader surface;
- before a covered/converged claim whose scope has no current v2.60 artifact;
- when the user asks whether SSOT is useful to a cold reader.

Do not run it on every commit. A focused task review may cover one changed
owner; a bootstrap or high-impact protocol review covers both trunks and uses
the reviewer role required by `status-protocol.md §6`.

## 1. Freeze the review inputs

Record before prompting the reviewer:

- `tracked_commit`, `tracked_skill_version`, and documentation language;
- the product surface inventory and its source pins;
- the architecture owner inventory, including `runtime`, `support`, and
  `target` classifications, applicable cross-owner views, and the unique
  technical-surface registry;
- the `STATUS.md` `Q01`-`Q21` quality, risk, and governance dispositions and
  every linked product, architecture, process/evidence, or gap owner used by
  the mandatory tasks or finite target population;
- the shared reader-surface content fingerprint and normalized STATUS-Q
  disposition fingerprint defined by `reader-quality.md`;
- a resolvable repository commit that is ancestor-or-equal to `HEAD`;
- the review id, review type, deterministic sample seed, rotation id, stable
  reviewer identity, reviewer role, and the exact proposed authorisation:
  `area:product:covered` or `area:architecture:covered`;
- the one current `STATUS.md` Stop Review Gate row that will close the covered
  claim, or the explicit fact that no such row exists yet.

If either inventory is missing, do not invent tasks from memory. Report the
matching inventory failure, build the inventory from real evidence, and restart
the review from the frozen inputs.

### 1.1 Task set

A product review runs the six exact `product-*` classes in
`reader-quality.md §7.2`; an architecture review runs the six exact
`architecture-*` classes there. Do not merge, rename, omit, or pad the set.
Each prompt names a real reader decision and uses a deterministic inventory row
from the complete target register. The orientation task tests first-day comprehension; the
journey/request tasks test observable outcomes; control/failure tasks test
side effects and recovery; inventory tasks test finite disposition and evidence;
boundary/owner tasks test authority and trust; trace tasks cross product and
architecture in both directions without redefining either owner.

The exact product profile is `C01-C09 + P01-P23 + Q01-Q21`; the exact
architecture profile is `C01-C09 + A01-A18 + Q01-Q21`. The shared Q rows are
dispositions, not twenty-one mandatory prose headings. For each applicable Q
item, the reviewer follows the layer owner or named gap and checks that missing
implementation was not relabelled `not_applicable`.

Before selecting deeper evidence, build one finite target population from the
frozen consumer SSOT:

- product: every product-spine, capability, and journey reader owner; every
  product-surface inventory row; and every product-to-architecture bridge row;
- architecture: every root, view, and domain reader owner; every direct owner
  classification; every applicable cross-owner view or reasoned merge/exception;
  every technical-surface row; and every bridge row;
- both scopes: every reasoned `not_applicable`, merged, target, support, or gap
  disposition that participates in the covered claim.

Give every target a stable ID and one target kind: `reader-owner`,
`product-surface`, `technical-surface`, `cross-owner-view`, or `bridge`. The same
file may own several distinct targets, but every target ID appears exactly once.
Use the inventory's exact `surface:<slug>` and `tech:<slug>` IDs. Give the other
classes deterministic IDs: `owner:<SSOT-relative-path#anchor>`, `view:<slug>`,
and `bridge:<surface-id>`. Do not combine IDs, ranges, globs, or comma-separated
name lists in one target row.

Target kind says what is being reviewed; it is not lifecycle or applicability.
Record the exact frozen disposition in its own column—for example product
`current|limited|target|out`, architecture `runtime|support|target`, view
`applicable|merged|not_applicable`, or a named `gap`. Do not encode `target`,
`support`, `gap`, or `not_applicable` as a new target kind, and do not silently
translate one scope's disposition into another scope's vocabulary.

Before the target rows, reconcile these source populations separately:
`product-reader-owner`, `product-surface`, and `product-bridge` for product;
`architecture-reader-owner`, `architecture-direct-owner`,
`architecture-view`, `technical-surface`, and `architecture-bridge` for
architecture. Link the frozen source inventory, count its applicable and
reasoned-disposition rows, count the matching target rows, and require equality
with `pass`. This count does not prove meaning; it prevents a polished subset
from masquerading as the finite population.

Assign every target to at least one of the six mandatory tasks and record, in
ordinary language, the decision it informs, what an implementation Agent would
be asked to do, and the visible result used for acceptance. A passing review has
no missing, duplicated, unassigned, deferred, or failed target.

This is complete owner/target coverage, not complete low-level evidence
inspection. Deeper code, configuration, test, or runtime checks may rotate when
the population is large, provided all high-consequence targets are selected and
the saved evidence rows state what was not checked. Rotation may change evidence
depth; it must never make an owner, surface, view, bridge, or reasoned boundary
disappear from the review.

### 1.2 Bounded reading set and hops

Each task declares its reading boundary before the reviewer starts:

| Boundary | Rule |
|---|---|
| Entrypoint | One reader-facing file named by the normal first-day or task route |
| Reader files | At most five reader-facing Markdown files per task: the entrypoint plus up to four linked owners |
| Route hops | At most four followed owner links; exceeding the budget is a task failure even when the answer is eventually found |
| Locality | The core answer appears in the expected owner within two hops; a remote grep hit or protocol/meta detour does not satisfy locality |
| Machine files | `_manifest.md`, `STATUS.md`, and `.bootstrap/` do not enter the first teach-back; they are checked after prose comprehension |
| Source evidence | Code/config/schema/test or the real product surface is opened only during the later evidence sample and only through cited anchors |

Searching inside the declared files is allowed. Repository-wide grep may help
diagnose a failure after the trial, but it cannot turn the trial into a pass.
The artifact records the exact files opened and hops used, not only the cap.

The finite target sweep runs only after the first tables-hidden teach-back. It
is separate from the six cold-route hop budgets: record its owner reads in the
finite target table, but never use the later sweep to repair a failed route or
rewrite the teach-back. Assigning a target to a mandatory task states which
reader decision it supports; it does not silently enlarge that task's bounded
read set.

### 1.3 Reviewer setup

For `high-impact-adoption`, use an independent cold reader who has not authored
the reviewed slice. A `routine` review may use `scoped-self-review` only when
`status-protocol.md §6` permits it. Keep this reviewer role separate from the
mandatory `implementation-delegator` reader profile. Give the reviewer only:

- the realistic task prompt;
- the declared entrypoint and reading boundary;
- access to the frozen consumer SSOT;
- the output schema below.

Do not give the author plan, a summary of the intended answer, the expected
score, or source evidence before the first teach-back. Pin and record the model
or reviewer identity when the environment supports it. The artifact always
records a stable reviewer ID. A high-impact adoption records
`reviewer_role: independent-cold-reader`; a display name or generic word such as
“reviewer” is not a stable identity.

### 1.4 Artifact link and visible-content boundary

A durable review must remain understandable and checkable after it moves to
another machine. A link that works only because it names the reviewer's absolute
workspace path proves nothing about the consumer SSOT.

Every owner or evidence link saved in the review artifact therefore:

1. uses a relative Markdown link from the artifact;
2. resolves, after normalising the path, to a regular Markdown file inside the
   current consumer `SSOT/` tree;
3. does not traverse a symbolic link and does not land in `SSOT/.bootstrap/`,
   another review artifact, the current artifact itself, or a path outside the
   consumer SSOT;
4. resolves its fragment to a real heading or explicit anchor when a fragment is
   present.

Reject absolute paths, `file://` or web URLs, bare paths presented as evidence,
and links whose visible label hides an out-of-scope target. The reviewer may
inspect source, configuration, tests, or runtime evidence named by a consumer
SSOT owner, but the artifact's durable evidence link points to that SSOT owner
or exact owner anchor; record the lower-level check and its result in plain text.

Only visible Markdown satisfies the artifact contract. Ignore headings, tables,
links, verdicts, and field-like text inside HTML comments or fenced code. A
passing artifact contains no authoring comment, placeholder, TODO/TBD marker, or
unreplaced angle-bracket token. A code fence may preserve supporting output, but
it cannot supply a required H2, table row, evidence link, or verdict.

## 2. Review probes

Run the probes in this order so later evidence cannot mask a weak reader path.

### 2.1 Route probe

From the declared entrypoint, ask the reviewer to name the next owner and why.
The route passes when the owner is authoritative, is reached within budget,
and does not require opening a machine-only file. For directory routing, the
reviewer may see the tree and the first screen of the immediate README; opening
one child README is the second and final routing hop.

The full review includes generic route questions for product promise, current
surface, architecture response, known bugs, development workflow, and whether
to open `_manifest.md`, plus questions generated from the consumer's actual
owner names. At least 80% must pass and no mandatory route may fail.

### 2.2 Tables-hidden teach-back

Hide tables, manifests, code fences, HTML author comments, Doctor labels, and
protocol metadata. Using only narrative prose in the bounded reader files, the
reviewer teaches back:

- the product audience, problem, current entry choices, normal and recovery
  experience, boundaries, acceptance, and future gap;
- the architecture context, request-to-result path, runtime owners, state/write
  ownership, trust/contracts, failure/recovery, deployment/diagnosis when
  applicable, and evolution gap;
- the product and technical owners reached by the six bounded tasks, including
  their boundary and evidence direction;
- the product-to-architecture traces reached by those tasks in both directions.

The teach-back also names the applicable quality/risk constraints that change
the reader's decision. It explains them in the natural product or system story;
it does not recite `Q01`-`Q21` or depend on the STATUS register as prose.

Restore tables only after this answer is recorded. A table may improve lookup,
but it cannot repair a missing causal story. If hiding tables changes a central
conclusion, record `table-dependence` and fail the task.

### 2.3 Cross-owner truth consistency

Compare every statement used in the teach-back across its unique prose owner,
root synthesis, linked view/domain or capability/journey, and manifest row.
Check that:

- product maturity/evidence follows the product contract in
  `reader-quality.md`, while architecture lifecycle state stays in
  architecture;
- product and architecture link across the constraint/technical-response
  boundary without copying or changing each other's facts;
- root and views synthesize rather than strengthen a child owner's posture;
- inventory rows, owner bodies, and evidence/closure pointers agree;
- deployment, observability, and failure claims name the same runtime owner.

A contradiction about current user behaviour, ownership, trust, persistence,
failure handling, or deployment is a critical truth error. Do not average it
away with strong prose scores.

### 2.4 Evidence sampling

After the teach-back, sample the cited evidence most likely to falsify it. A
full review records one evidence row per mandatory task. Across those six rows,
cover a real user-visible surface, a product boundary or recovery claim, a
state/contract/flow claim, a failure/deployment/diagnosis claim, and both ends
of the product-to-architecture trace. Across the same rows, sample the
highest-consequence applicable Q dispositions and their named gaps. Do not
replace task coverage with an arbitrary maximum number of convenient links.
The evidence sample adds depth to the finite target table; it does not decide
which owners or targets exist.

Open only the cited route/handler, selector/component, schema/symbol, test,
config, or runtime surface needed for the sample. In the durable table, link the
consumer SSOT owner or exact owner anchor that states the claim and pins that
evidence; describe the lower-level item actually checked, observed result, and
limit in the surrounding cells. Record claim, evidence,
fitness/fidelity/freshness, result, and limit. Path existence alone does not
prove path semantics or a visible label. Record whether browser proof used a
real backend/runtime or a rendered mock, and whether identity/audit evidence
identifies a human, service, session, or actor token. Evidence weakness does
not silently change product maturity; it creates the evidence or closure gap
defined by the product owner contract.

### 2.5 Finite owner and inventory probes

Reconcile the finite target table against the frozen inventories before grading
individual prose. The product side passes only when every real or reasoned
non-applicable surface, reader owner, and bridge row appears once, routes to its
unique product owner, and states current user-visible behaviour or an honest
boundary. The architecture side passes only when every reader owner, direct
owner classification, applicable view or reasoned exception, technical surface,
and bridge row appears once; each technical surface routes to exactly one
classified owner; and support/target rows cannot masquerade as current runtime
owners.

Then read every linked owner body far enough to verify the target's decision,
delegated action, visible result, and boundary. This is a semantic check, not a
row-count or long-string check. A table cell containing many owner names does
not prove that any linked page teaches the target. Inventory completeness is
structural; truth and explanation remain semantic. One strong owner or one deep
evidence sample cannot rescue an omitted, duplicated, unassigned, or unread
target.

## 3. Scoring and verdict

Map every mandatory task to its applicable leaves, score the task/leaf pairs,
then derive each of the 16 leaf scores as the minimum applicable task score.
Keep family, leaf ID, dimension name, `/32` threshold, family floors, and the
implementation-delegator hard floor verbatim from `reader-quality.md §7`; this
harness does not redefine them.

A task passes only when it stays within its bounded read set/hops, gives the
tables-hidden teach-back, has no unresolved route/truth/evidence failure, and
does not depend on a non-owner copy. The whole review passes only when all are
true:

1. all score, family, leaf, and persona floors in `reader-quality.md §7.3` pass;
2. every leaf is non-zero and every applicable task score is recorded;
3. cold proofs `CP-D`, `CP-R`, `CP-T`, `CP-E`, and `CP-C` pass; `CP-D`
   explicitly proves the implementation request, visible result/evidence, and
   stop/escalation decision without source reading;
4. `critical_truth_errors = 0` and `unresolved_required_changes = 0`;
5. all six mandatory tasks and the exact `C + scope + Q` completeness profile pass;
6. every finite owner/target row is present once, assigned, read, and passing;
7. exactly one current STATUS stop row matches the artifact's reviewer, role,
   review date, verdict, artifact pointer, and authorisation;
8. `verdict = no-more-required-changes`.

Any other result is `needs-fix`. Lint, an author-assigned score, or a high
aggregate cannot override a failed mandatory task, truth conflict, or zero
dimension.

### 3.1 Miss classes

Every failed task records one primary miss class and may list secondary ones:

| Miss class | Meaning | Usual fix owner |
|---|---|---|
| `missing-owner` | No authoritative prose owner answers the task | Consumer SSOT owner/inventory |
| `surface-inventory-gap` | A real user surface is absent, duplicated, or has no product disposition | Product root manifest/inventory |
| `owner-inventory-gap` | A technical surface, owner classification, or cross-owner view is absent or ambiguous | Architecture root manifest/inventory |
| `quality-disposition-gap` | An applicable Q dimension, layer owner, evidence process, or named gap is silent or mislabeled non-applicable | STATUS register plus the missing layer owner |
| `broken-ref` | The owner exists but a link or evidence anchor is stale | Linked consumer owner |
| `prose-fork` | The reviewer lands on a non-owner copy or two owners maintain the fact | Unique prose owner |
| `truth-conflict` | Linked owners disagree about a current or target fact | Owners in conflict plus adjudication if needed |
| `table-dependence` | Narrative prose cannot carry the teach-back without tables | Reader-facing prose owner |
| `reader-locality-gap` | The answer exists only outside the bounded local owner path | Reader Map or expected owner |
| `evidence-sample-gap` | A sampled claim lacks, contradicts, or overstates its cited evidence | Claim owner and closure record |
| `glossary-gap` | A repository-specific term cannot be understood or has conflicting definitions | Glossary owner |
| `comprehension-gap` | The route is correct but the reader cannot explain the causal story or boundary | Reader-facing prose owner |

## 4. Failure partition

Keep consumer-document failure separate from bundle-protocol failure:

| Partition | Definition |
|---|---|
| `doc-fail` | The current bundle requires the missing inventory, owner, prose, route, or evidence shape, but this consumer does not provide it. Route to `STATUS.md ## Pending Captures`. |
| `skill-fail` | Doctor and the bundle contract are clean, yet the realistic task still fails because the protocol never required the needed shape. Route to the bundle's protocol capture owner. |
| Tie-breaker | When Doctor is dirty on the same row, repair the consumer first. If the same miss survives the next rotated review, reclassify it as `skill-fail`. |

Each fail row names `task_id`, `miss_class`, `hop_died_at`, expected owner or
evidence kind, actual result, partition, and proposed fix owner.

## 5. Durable review evidence

Write a durable Markdown artifact under `SSOT/.bootstrap/` for each full review.
Use the exact frontmatter schema and result values owned by
[`reader-quality.md §7`](../../ssot-preflight/references/reader-quality.md#7-cold-reader-acceptance),
using the paired `reader-review.md` template. The rendered artifact contains
exactly the 29 scalar fields shown there, once each, with no aliases or extra
keys. In addition to the existing review fields, it records `reviewer` as a
stable identity and `authorises` as exactly `area:product:covered` or
`area:architecture:covered`, matching scope and profile. L1 rejects
missing/duplicate/extra fields, scope or tracking baseline mismatch, template
placeholders, an unbounded route, a stale shared-surface fingerprint, a
non-resolvable or non-ancestor commit, a missing per-task evidence sample, an
incomplete finite target/profile set, or a dimension table whose 16 canonical
leaf minima do not sum to the declared score and meet every family/persona
floor.

The artifact also records the frozen inventory/content identifiers, sample
seed, exact task prompts, opened files and hops, teach-backs, per-task verdicts,
miss classes/partitions, the complete finite target table, deeper-evidence
rotation, and next rotation. A passing artifact has no deferred target; only
deeper evidence may be deferred with a named limit. A link to chat or a bare
"reviewed" sentence is not durable evidence. Apply the relative, in-SSOT,
regular-Markdown, non-symlink, non-review, non-self link boundary in §1.4 to
every owner/evidence link.

The six machine-checked H2 sections are:

```markdown
# Reader Review <id>

## Bounded reading set
## Teach-back
## Consistency and evidence sample
## Dimension scores
## Completeness profile
## Required changes and verdict
```

Use the corresponding locked-language headings from the paired template. Put
the route probe inside `Bounded reading set`. Put frozen inventories, task
prompts, route/locality results, truth samples, failure partitions, and the
verdict inside those sections as prose or H3 subsections; adding a seventh H2
such as `Route probe` would fork the artifact protocol.

Keep trial transcripts beside the artifact only when needed to reproduce a
failure. The artifact itself must be sufficient for Doctor to locate every
claim that supports the verdict.

### 5.1 Product/architecture covered-claim closure

A product or architecture artifact proposes one covered claim through its exact
`authorises` value. A `no-more-required-changes` artifact closes that claim only
when `STATUS.md` has exactly one current Stop Review Gate row for the same scope
and authorisation. Compare all of these values, not merely the artifact link:

- stable reviewer identity;
- reviewer role;
- reviewed date (the date portion of STATUS reviewed time);
- `no-more-required-changes` or `needs-fix` result;
- STATUS Evidence resolving to this exact artifact;
- `area:product:covered` or `area:architecture:covered` authorisation.

Record the comparison in the template's visible STATUS closure table. Do not
self-link the artifact from that table; link the consumer STATUS section and
state whether its evidence resolves back to the current artifact. Multiple
current rows, an older competing row, any field mismatch, or a missing row makes
the proposed covered claim `needs-fix`.

A `needs-fix` artifact remains valid evidence of failure even when no STATUS row
exists—that missing row may be the failure. Record the exact visible sentinel
`none: needs-fix does not authorise covered` and closure result
`not-authorised`. It may instead link one diagnostic `needs-fix` stop row when
the project records failed reviews, but every populated field must match. It
must never leave a passing current row that still authorises the failed covered
claim.

For `high-impact-adoption`, both the artifact and STATUS row use the same stable
reviewer and `reviewer_role: independent-cold-reader`. Routine review may use
`scoped-self-review` only where `status-protocol.md §6` allows it.

The final H2 ends with exactly one visible `Final verdict:` line (localized by
the template). That value always equals frontmatter `verdict` and the
required-changes calculation. For `no-more-required-changes`, it also equals the
required STATUS row result. For `needs-fix`, it equals a linked diagnostic stop
row when one exists; otherwise the closure table uses the `not-authorised`
sentinel above. `no-more-required-changes` requires zero unresolved rows and the
single `none` sentinel or resolved rows only. `needs-fix` requires the unresolved
count to equal all `pending`, `required`, and `open` rows. A verdict hidden in a
comment or code fence is not a verdict.

### 5.2 Lightweight exact-scope evidence

Process, records, glossary, root, and STATUS use `scope-review.md`, not the six
task rows or sixteen-leaf score above. Follow the exact artifact schema in
`reader-quality.md §7.7`. A passing artifact proves both completeness and a
bounded check against repository truth:

1. disposition every exact profile ID once and link one reachable owner or
   evidence route;
2. pass the three review-basis checks for current fingerprint, route
   resolution, and STATUS authority;
3. save one semantic-truth sample from every profile family, and—when both
   appear—at least one `covered` and one `not_applicable` sample;
4. for each sample, record `Item ID`, the exact owner/body claim checked, one
   resolving non-review repository/evidence link, `Truth result`, and the
   limit of what the sample does not prove;
5. leave no unresolved required change and make frontmatter, final verdict,
   Area Status, and Stop Review Gate agree.

Open the linked body and the smallest fitting code, schema, configuration,
test, runtime, or source-material evidence. Confirm the disposition, boundary,
ordinary-language narrative, and claimed evidence depth; path existence is not
truth. Every truth result in a passing artifact is `pass`. A 46/46, 38/38, or
similar row count with no saved semantic sample is a false green.

## 6. Regeneration and termination

On `needs-fix`, classify the miss, update the evidence inventory when needed,
repair unique owners bottom-up, regenerate indexes/views/root synthesis, and
rerun the affected full or lightweight review with a reviewer chosen under
`status-protocol.md §6`. For process also recheck its method and stable assets;
for records, both state axes and exact indexes; for glossary, all six families;
for root, task routes; and for STATUS, every exact register. Do not patch only
the score or disposition table.

One passing artifact can support its scoped covered claim. A protocol-upgrade
or SSOT-SKILL × consumer optimization campaign terminates only after two
consecutive review rounds pass across every affected scope, with different
deterministic owner/surface or semantic-sample rotations and zero `skill-fail`
rows. Product and architecture use their full reviews; the other five scopes
use exact-scope reviews. This shows the protocol generalises beyond one
memorised sample. In each product/architecture round, the complete finite
owner/target population still appears and passes; rotation changes only the
deeper evidence selected from that population.

## 7. Historical compatibility

Protocols v2.43–v2.58 used commit-derived intent/truth pillars and per-pillar
floors. v2.59 added an eight-dimension `/16` comprehension probe. Those reports
remain valid historical evidence at their recorded tracking baseline; do not rewrite
them or claim they used v2.60.

For a consumer tracked below v2.60, Doctor interprets the existing artifact
under the recorded protocol. Advancing to v2.60 requires the inventories and a
new task-based `/32` artifact; legacy pillar declarations, scores, or production
evidence labels cannot satisfy the new gate.

For `2.45 <= tracked_skill_version < 2.48`, the historical compatibility sweep
reads the inline manifests only in `product/README.md` and
`architecture/README.md`. Do not require sibling `_manifest.md` files.
