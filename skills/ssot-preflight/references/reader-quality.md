# Reader Quality and Completeness

This file is the unique schema owner for reader-facing SSOT quality. Its shared
writing floor applies to every body under `SSOT/`: the root reader map; product;
architecture; the process root plus development, testing, benchmark,
deployment, release, and applicable operations and security/compliance owners;
the records root plus decisions, research, gotchas, bugs, and technical debt;
and glossary. Product and architecture use the full v2.60 task-based cold-review
gate because they carry the broadest promise-to-runtime truth. Process, records,
glossary, the SSOT root, and STATUS use the lighter exact-scope review in §7.7.
No area may turn an exact profile into a future promise and still claim
`covered` or `converged`.

## 1. The outcome

KISS means the shortest reliable path to understanding, not the fewest words.
Remove duplication and machinery from the reader path, then write enough prose
for a newcomer to explain the product or system back in their own words.

Reader-facing documents use progressive disclosure:

1. **Orientation** — who or what this owner serves, why it exists, and one
   concrete scene.
2. **Explanation** — the causal story: normal path, state changes, boundaries,
   important variants, and failure/recovery.
3. **Reference** — compact comparisons, status, owner links, and evidence.
4. **Machine recovery** — manifests and audit metadata, outside the prose body.

Do not shorten layer 2 to make layer 3 denser. A long document can still be
unreadable when tables and identifiers carry the story; a shorter document can
still be incomplete when it omits a user surface, state owner, trust boundary,
or failure path.

The area entry point and its primary spine must teach the core story locally.
A cold reader must not have to open a large collection merely to learn the
audience, current path, visible result, failure/recovery posture, and important
gaps. Links add detail; they do not assemble a missing explanation. During
review, record the bounded reading set and the navigation hops used for the
teach-back. Unexpected detours are a reader-surface defect even when every fact
exists somewhere.

## 2. Shared writing contract

`partial` is the pre-gate honest Area Status state: the owner README exists, the
shared writing floor in this section is met, Doctor L1 is clean for the scope,
and a scoped self-review is recorded in the Stop Review Gate with
`authorises=area:<scope>:partial`. It requires none of the §7 cold-reader review
machinery. Only `covered` and `converged` require the §7 review.

The default reader profile is `implementation-delegator`: a person who
delegates coding and evaluates observable outcomes, acceptance, and risk. This
reader need not read source code to understand the current story or decide the
next action. `reader_profile` describes who must understand the material;
`reviewer_role` describes who performed a review. They are independent fields.

**Plain language** means a cold implementation delegator can recover the
reader, decision, causal story, visible result, boundary, failure/recovery, and
next action before encountering repository vocabulary or implementation pins.
It does not mean deleting precision. Lead with the ordinary-language model,
then add exact identifiers, state names, paths, and evidence.

Every core conclusion follows this order when the material applies:

1. context and pressure;
2. current truth in ordinary language;
3. one concrete example or end-to-end path;
4. boundary, variation, or failure/recovery;
5. owner and evidence direction.

The prose must stand on its own if tables are hidden. Tables may route,
compare, register state, or index evidence only after the prose has explained
the conclusion. Do not make a reader reconstruct causality from cells.

Define repository-specific terms positively on first use. Prefer product words
in product owners and system concepts in architecture owners. Function names,
test names, paths, state tags, protocol codes, and Doctor labels belong in a
short reference appendix or the matching manifest unless the identifier is
essential to the explanation.

Reader-facing prose must not teach the SSOT protocol. Visible references to
`ssot-bootstrap`, Doctor check numbers, adoption versions, pillar vocabulary,
or authoring instructions are meta leakage. Template authoring notes use HTML
comments and must be removed before an owner is marked `covered`.

Single ownership does not forbid orientation. A non-owner may give a short
contextual summary that says why the linked fact matters here, but it must not
redefine the contract, state, or acceptance rule. Link to the owner for the
authoritative body.

Summaries are derived from unique owners. When a maturity, current behaviour,
boundary, or closure condition appears in more than one reader surface, audit
all copies together and resolve any conflict before claiming coverage. The
product-maturity and evidence-fidelity vocabularies in this file are the unique
protocol authority for product reader surfaces; adapters and manifests may
reference them but must not introduce parallel state meanings.

### Shared body scope and navigation

The shared floor covers `SSOT/README.md`, all reader bodies under
`01-product/` and `02-architecture/`, `03-process/README.md` and every applicable
process owner, `04-records/README.md` and every record index or entry, and
`glossary/`. In a covered area, an H1, headings, tables, lists, comments, or
code blocks without explanatory prose are not a reader body. At minimum, each
covered body contains two real prose paragraphs totalling 80 non-space
characters; semantic review still decides whether those paragraphs actually
teach the required story. The root process or records router becomes part of
the covered reader path when any child area is covered.

Register-only files are different. `STATUS.md`, `_manifest.md` and future
`_*.md` files, artifacts under `.bootstrap/`, promotion/protocol ledgers, and
thin startup adapters may keep fixed tables or compact fields. Their cells stay
pointer-sized and route narrative to its owner. They are not prose bodies and
must not be padded merely to satisfy the body floor.

Apply these reader rules to every body in scope:

1. Open each section with its ordinary-language conclusion before a table.
2. Define a repository term positively on first use, then give exact labels,
   paths, tokens, or commands only where they help the decision.
3. Move paragraph-sized reasoning out of table cells; keep cells for routing,
   comparison, state, and evidence pointers.
4. Use the locked documentation language for the H1 and surrounding prose,
   except for unavoidable identifiers or product names.
5. Never mark a body `covered` while template tokens such as `<term>`,
   `<owner-path>`, or their locked-language equivalents remain in reader prose.
6. Source references must resolve in the current tree. A body that pins
   `` `engine/foo.py` `` or `` `engine/foo.py::dispatch` `` teaches a runtime
   the reader will try to open. When the pinned file or symbol is deleted, the
   page keeps teaching a dead system — worse than an honest `gap`. Prefer
   `path::symbol` over `path:NN` line pins (line numbers drift on every edit);
   when a reference is intentionally historical, mark it inline
   (`historical: engine/old.py`, `retired:`, `deleted:`) so a reader — and
   lint `[REF-RESOLVE]` — knows it describes a past state, not the current one.

Information architecture is part of the writing floor. A directory with at
least two reader children opens its README with an ASCII tree of immediate
children and a one-sentence plain-language annotation per row. Put read-ordered
children behind the stable `NN-` prefix; when peers have no canonical order,
name the first two or three recommended entries below the map. Translate jargon
in the annotation rather than forcing the reader to infer it from a filename.
Label every `_*.md` row as machine-only and safe to skip.

Every owner also provides one concrete walkthrough, distinguishes its nearest
confusing sibling, states which question it does not answer and where that
question goes, and gives the next evidence or reading path. These are semantic
roles, not mandatory headings. Architecture domains additionally put a small
typed boundary diagram before dense reference tables when the boundary is not
obvious. Bootstrap §3.7 is only the entry and routing adapter to this contract;
it does not own or restate the writing floor.

### 2.1 Common completeness profile

Every reader-facing owner disposes these questions. `covered` means answered;
`not_applicable` requires a named reason and evidence or owner direction.

| ID | Required question |
|---|---|
| `C01` | Who is the reader, what decision must they make, and what action follows? |
| `C02` | What is the current conclusion or observable outcome? |
| `C03` | What is outside this owner's boundary or deliberately not a goal? |
| `C04` | Where is the unique owner and how does a handoff reach it? |
| `C05` | What evidence fits the claim, how fresh is it, and what invalidates it? |
| `C06` | What can fail or become irreversible, and how does recovery work? |
| `C07` | What next step, acceptance check, or closure condition is actionable? |
| `C08` | Are unavoidable terms, assumptions, states, commands, and evidence labels explained in ordinary language before use? |
| `C09` | Does one concrete scene let the reader recognise the decision, delegated action, visible result, and fitting evidence without reading source code? |

### 2.2 Process, record, and glossary profiles

These IDs are exact v2.60 profiles, not optional prompts. A covered process
disposes `C01`-`C09`, `PR01`-`PR16`, and `Q01`-`Q21` exactly once (46 rows). A
covered records scope disposes `C01`-`C09`, `R01`-`R16`, and `Q01`-`Q21`
exactly once (46 rows). A covered glossary disposes `C01`-`C09`, `G01`-`G08`,
and `Q01`-`Q21` exactly once (38 rows). Use the lightweight artifact in §7.7;
do not invent parallel IDs or copy the product/architecture scoring machinery.

| Process ID | Required question |
|---|---|
| `PR01` | Audience, applicability, and trigger |
| `PR02` | Prerequisites, inputs, and environment |
| `PR03` | Roles and permissions |
| `PR04` | Ordered canonical path |
| `PR05` | Decisions, branches, and exceptions |
| `PR06` | Side effects and irreversibility |
| `PR07` | Observable output or artifact |
| `PR08` | Verification and acceptance gate |
| `PR09` | Failure detection and stop condition |
| `PR10` | Retry, rollback, and recovery |
| `PR11` | Escalation and handoff |
| `PR12` | Reproducible commands |
| `PR13` | Freshness, current/target posture, and change trigger |
| `PR14` | Repeat, concurrent, and partial-completion behaviour |
| `PR15` | Strategy and method, including the conventions, invariants, rationale, and trade-offs that make the path coherent rather than a list of commands |
| `PR16` | Finite inventory of stable assets the process creates, reads, changes, verifies, hands off, or retires, with a unique owner for each class |

| Record ID | Required question |
|---|---|
| `R01` | Record type, purpose, and scope |
| `R02` | Trigger, context, and time |
| `R03` | Both status axes: the record's own lifecycle and the implementation or real-world state it describes; never collapse one into the other |
| `R04` | Fact versus inference or judgment, with confidence, named uncertainty, and what evidence would change the conclusion |
| `R05` | Evidence, provenance, and freshness |
| `R06` | Impact and severity |
| `R07` | Cause or rationale |
| `R08` | Alternatives and trade-offs |
| `R09` | Decision, action, fix, or workaround |
| `R10` | Validation |
| `R11` | Owner and follow-up |
| `R12` | Closure, supersession, or invalidation |
| `R13` | Reproduction or prevention when applicable |
| `R14` | Exact index-to-entry routing: every real entry appears exactly once in its collection index, every index row resolves, and the entry remains the unique narrative owner |
| `R15` | Affected versions, platforms, environments, tenants or workspaces, data classes, and compatibility window |
| `R16` | Security, privacy, compliance, and customer exposure, including notification duties |

The two states in `R03` answer different plain-language questions. The record
state asks, “Should I still trust and maintain this document?” The real-world
state asks, “Has the decision been implemented, has the research been adopted,
is the bug open, fixed, or recurring, is the pitfall still dangerous, or is the
debt still being repaid?” A record can remain current while the problem it describes
is resolved, and an accepted decision can still be only partly implemented.
Showing only one state hides one of those truths.

The collection-root README is the one complete state index for its record type.
Entries may live in nested topic, domain, or time directories, but the root
index still lists every stable ID exactly once and links the real leaf owner.
A nested README may help a reader navigate its group; it must not copy the
state rows or become a competing index. Standard `DEC`, `RES`, `BUG`, and
`DEBT` entries use exactly four digits and a matching `NNNN-slug.md` filename.
A gotcha topic may aggregate several entries only when every entry starts at an
ID-only `## GOT-NNNN` heading, so the stable `#got-nnnn` anchor does not change
when its explanatory title is edited.

`R14` does not force a fake entry into a legitimately empty collection. When a
covered decisions, research, gotchas, bugs, or technical-debt index has no real
entry, it has no data row and states one visible disposition:
`Empty collection: reason=<named reason>; owner=[responsible owner](<resolving
path>); review when=<observable event>.` Chinese uses
the equivalent localized sentence from the Chinese collection-index template.
The reason and trigger are concrete, and the owner is one resolving Markdown
link or an explicit `$ssot-*` route. This sentence is visible prose, not a
commented or fenced example. Once an entry exists, remove it; an index cannot
be both empty and populated.

| Glossary ID | Required question |
|---|---|
| `G01` | Positive plain definition |
| `G02` | Why it matters or changes a decision |
| `G03` | Example |
| `G04` | Non-example or common confusion |
| `G05` | Unique owner and evidence |
| `G06` | Related terms, scope, invalidation, and term lifecycle: `active`, `deprecated`, or `retired`, plus replacement and migration direction when the term is no longer active |
| `G07` | Canonical spelling, aliases or acronyms, user label, machine token, and translation constraint when they differ |
| `G08` | Finite glossary inventory across the mandatory term families, with every real entry indexed exactly once and an explicit reason when a family is genuinely empty |

The glossary inventory always disposes six families: product and user concepts;
architecture and runtime concepts; state, lifecycle, and workflow terms; trust,
identity, access, and data-governance terms; evidence, verification, and
operating terms; and concurrency-control terms such as ordering, atomicity,
idempotency, deduplication, replay, reconciliation, or locking. A repository
does not need to invent entries, but it must state why an empty family has no
repository-specific vocabulary. Ordinary dictionary words do not need entries.

### 2.3 Root and STATUS profiles

| Root ID | Required question |
|---|---|
| `RT01` | Repository, audience, and outcome orientation |
| `RT02` | Area map |
| `RT03` | First-day bounded route |
| `RT04` | Task-to-owner map |
| `RT05` | Current tracking baseline and gap handoff |
| `RT06` | No duplicated truth or visible protocol/meta leakage |
| `RT07` | Delegation and acceptance route: what to ask an agent to do, what visible evidence to expect, and when to stop or escalate |

| STATUS ID | Required question |
|---|---|
| `S01` | Tracking-baseline consistency |
| `S02` | Area pointers |
| `S03` | Source absorption inventory with lifecycle, source classification, authority/disposition, durable owner, explicit do-not-use direction, review freshness, and conflict route |
| `S04` | Core-reference inventory with startup-file path, status, role, reviewed commit/session, durable owner or absorbed scope, and gap/conflict route |
| `S05` | Stop-review register with scope, proposed claim, reviewer and role, reviewed time, result, evidence pointer, remaining changes, and the tracking baseline or area it authorises |
| `S06` | Open adjudication and gap lifecycle: stable ID, state, affected scope/task, question or missing evidence, owner, blocking or retrigger condition, resolving route, and closure/supersession evidence |
| `S07` | Register-only, pointer-sized cells |
| `S08` | Open-gap actionability: task impact, concrete blocking or retrigger condition, and a clickable owner or explicit `$ssot-*` route |
| `S09` | Complete `Q01`-`Q21` disposition register: every applicable layer links its owner or gap, and every cell remains pointer-sized |
| `S10` | Pending Captures inventory: each not-yet-absorbed durable fact names its source, proposed owner, reason, priority or trigger, responsible owner, and capture/closure state |
| `S11` | Source Inventory Exclusions: each excluded pattern or artifact class names the reason, decision owner, `last_checked` evidence, and the trigger that requires another review |

An open gap is useful only when a reader can decide three things without
reconstructing the whole project: whether the gap affects the task in front of
them, which observable condition makes the gap blocking or requires another
review, and which owner to open next. A bare record ID is not a route: link the
owner file, or use an explicit `$ssot-*` runtime route. Keep those answers
pointer-sized; the owner holds the explanation and evidence.

The root exact profile is `C01`-`C09` + `RT01`-`RT07` + `Q01`-`Q21` (37 rows).
The STATUS exact profile is `S01`-`S11` + `Q01`-`Q21` (32 rows); STATUS is a
register, so it does not add the narrative `C` questions. At v2.60, a covered
process, records, or glossary row requires its passing lightweight artifact.
`coverage_result: converged` additionally requires passing root and STATUS
artifacts. §7.7 owns their common schema and STATUS link contract.

### 2.4 Shared quality, risk, and governance profile

The `Q` profile is the unique shared inventory of concerns that are otherwise
easy to omit because they cross product, architecture, process, and evidence
boundaries. It is a disposition and routing profile, not twenty-one mandatory
body sections and not a claim that every concern has been implemented.

Before using the inventory, an implementation delegator should be able to ask
four ordinary questions and get an ordinary-language answer from the owners:

1. Who could find this hard to use, be treated unfairly, or be harmed?
2. What happens under load, failure, repetition, concurrency, offline use, or
   an upgrade?
3. Who is responsible for the data, permissions, money, and external rules?
4. What evidence shows that the output is valid, cost stays controlled, and a
   problem can be detected and recovered?

The table below is a completeness and routing check: it makes omissions and
ownership gaps visible. It cannot replace the causal story, and a normal reader
must not have to infer the system's behaviour by stitching its rows together.

| ID | Required quality, risk, or governance concern |
|---|---|
| `Q01` | Accessibility and inclusive interaction |
| `Q02` | Language, locale, time zone, formats, translation, and fallback |
| `Q03` | Usability, discoverability, learnability, operability, user assistance, self-descriptiveness, engagement, onboarding, feedback states, and error prevention |
| `Q04` | Performance, latency, throughput, capacity, scalability, elasticity, backpressure, quotas, resource use, and cost budgets |
| `Q05` | Concurrency, ordering, atomicity, consistency, idempotency, deduplication, replay, and reconciliation |
| `Q06` | Availability, durability, continuity, maintenance, degradation, resilience, system or service recoverability, fault tolerance, fault prevention, service indicators or objectives, and failover |
| `Q07` | Versioning, interoperability, coexistence, adaptability, installability, replaceability, portability, compatibility, deprecation, migration, mixed-version operation, and rollback |
| `Q08` | Retention, deletion, export, backup, restore, corruption recovery, disaster recovery, and recovery-point or recovery-time objectives |
| `Q09` | Tenant or workspace isolation, shared quotas, noisy-neighbour control, and blast radius |
| `Q10` | Threats, abuse, untrusted input, privilege escalation, confidentiality, integrity, authenticity, non-repudiation, security accountability, rate limiting, and security detection and response |
| `Q11` | Dependencies, platforms, supply chain, provenance, signing, software bills of materials, vulnerabilities, and updates |
| `Q12` | Notifications, asynchronous delivery, duplication, offline use, reconnect, resume, and conflict reconciliation |
| `Q13` | Policy, consent, compliance, data residency, licensing, audit evidence, and disclosure |
| `Q14` | Privacy and data governance: classification, purpose limitation, minimisation, collection and access, data quality (accuracy, completeness, consistency, timeliness, currentness, validity, credibility, precision, uniqueness, traceability, and understandability), lineage, provenance, and stewardship |
| `Q15` | Safety and harm: hazard and risk identification; physical, psychological, financial, legal, or reputational harm; operating constraints, warnings, safe integration, prevention and recovery; unsafe autonomous action; safe failure; and fail-safe behaviour |
| `Q16` | Human oversight, authority, accountability, approval, override, appeal, contestability, and redress |
| `Q17` | Fairness, transparency, explainability, interpretability, bias, limitations, and user or operator notices |
| `Q18` | Maintainability and evolvability: modularity, analysability, modifiability, testability, reusability, ownership, and decommissioning |
| `Q19` | Environmental lifecycle impact: energy, carbon, water, hardware, data or model footprint, and end-of-life handling |
| `Q20` | Functional and output validity: functional completeness, functional correctness, functional appropriateness, output or decision accuracy, robustness, calibration and uncertainty, generalisation, model or data drift, and evaluation limits |
| `Q21` | Commercial, financial, and entitlement integrity: pricing, billing, metering, quotas, credits, entitlements, purchase, refund, cancellation, tax, invoice, accounting reconciliation, and monetary or paid-action authority |

Use these boundaries when two rows appear to overlap:

- `Q08` owns data lifecycle and recoverability; `Q14` owns why data is
  collected, how it is classified and governed, and whether its quality and
  provenance are fit for use. `Q10` owns hostile or unauthorised action, while
  `Q13` owns external policy, legal, regulatory, residency, licensing, and
  disclosure obligations.
- `Q06` owns resilience and recovery of the system or service. `Q08` owns the
  recoverability of data, including backup, restore, corruption recovery, and
  disaster-recovery point/time objectives. A service restart that leaves data
  unusable therefore routes to both, with one owner for each claim.
- `Q15` owns the harm that an action or failure can cause and the safe-failure
  posture. `Q16` owns who may approve, stop, override, challenge, or remedy
  that action. `Q20` owns whether the output or decision is valid and how its
  uncertainty and drift are evaluated.
- `Q17` owns fairness and whether people can understand the system's basis,
  limitations, and notices. Mandatory policy or legal disclosures remain in
  `Q13`; measured validity, accuracy, calibration, and evaluation limits remain
  in `Q20`.
- `Q14` data accuracy means that collected, stored, moved, and governed data is
  fit for its declared purpose. `Q20` output accuracy means that a produced
  answer, score, recommendation, or decision matches its evaluation target.
  Input or reference-data defects route through `Q14`; how those defects affect
  output validity, uncertainty, robustness, or drift also routes through `Q20`.
- `Q18` owns the system's ability to be understood, changed, tested, reused,
  owned, and retired. Version compatibility and migration remain in `Q07`;
  adaptability, installability, replaceability, and portability across
  environments remain in `Q07`; dependency and supply-chain integrity remain
  in `Q11`.
- `Q19` owns environmental impact across the full lifecycle. Runtime capacity,
  resource use, and the operator's internal cost budget remain in `Q04`.
- `Q21` owns correctness and authority at the commercial transaction and
  entitlement boundary. Internal compute/resource cost remains in `Q04`,
  policy or legal obligations remain in `Q13`, general human approval and
  appeal remain in `Q16`, and resulting financial harm remains in `Q15`.
- `Q04` owns total resource demand and capacity of the service. `Q09` owns how
  shared capacity is isolated between tenants or workspaces and whether one
  neighbour can consume another's share. `Q21` owns the commercial promise or
  purchased entitlement to a quota; it does not own the runtime capacity or
  neighbour-isolation mechanism that fulfils that promise.
- `Q05` owns state correctness when work overlaps: ordering, atomicity,
  idempotency, deduplication, replay, and reconciliation. `Q12` owns delivery
  behaviour across asynchronous, duplicate, offline, reconnect, and resume
  situations. `Q14` owns whether the underlying data remains accurate,
  complete, consistent, timely, and traceable. One offline replay can therefore
  route to all three, but each claim keeps its own owner.
- `Q07` owns migration or portability of the system, software, protocol, or
  deployment across versions and environments. `Q08` owns export and movement
  of the repository's or product's data, including retention and recovery
  implications. A platform migration that exports customer data routes to both.
- `Q10` owns accountability for a security event: attribution, auditability,
  non-repudiation, detection, and response to hostile or unauthorised action.
  `Q16` owns responsibility for a human decision: who may approve, override,
  contest, appeal, or provide redress. A security incident with a manual
  approval step uses both without merging those responsibilities.
- `Q11` provenance means the origin and integrity of software, dependencies,
  packages, build inputs, models, or other supply-chain components. `Q14`
  provenance and lineage mean where governed data came from, how it changed,
  and who stewards it. Do not use one generic “source” claim for both.

For each applicable row, product owns the user-visible promise, limit, or
acceptance meaning; architecture owns the mechanism, boundary, and failure
posture; process/evidence owns the operating or verification route. A layer
that genuinely does not apply says why. A missing implementation, proof, or
owner is a named gap with a resolving owner, not a silent omission and not a
reason to invent a section.

`STATUS.md` carries only the cross-area disposition register under the exact H2
`## Quality, Risk, and Governance` in English or the localized heading from the
Chinese STATUS template. Its exact columns are `Q ID`,
`Applicability`, `Product owner`, `Architecture owner`,
`Process/evidence owner`, and `Gap owner` (translated under a Chinese language
lock). It contains exactly `Q01`-`Q21` once each. `Applicability` is
`applicable` or
`not_applicable: <named reason>; [boundary evidence or owner](<resolving path>)`.
In an applicable row, each of the first three owner cells is a resolving
Markdown link or
`not_applicable: <layer reason>; [boundary evidence or owner](<resolving path>)`;
`Gap owner` is a resolving Markdown link or
`none: <evidence or reason no gap remains>`. A
globally non-applicable row may use `—` in the remaining cells. Neither global
nor layer-level `not_applicable` is valid as an unsupported assertion: the same
pointer-sized cell carries its resolving evidence or owner link. Keep narrative,
commands, proof, and trade-offs in the linked owner.

## 3. Product completeness

The product trunk collectively answers every applicable question below. A
missing class is written as a named gap or reasoned `not_applicable`; silence
cannot support `covered`.

The v2.60 product completeness profile is exact. Its 53 rows are all common
items `C01`-`C09`, all product items `P01`-`P23`, and all shared quality items
`Q01`-`Q21`, each exactly once.

| ID | Required product question |
|---|---|
| `P01` | Users, persona prerequisites, deployment/organisation setting, and scenario |
| `P02` | Current pages |
| `P03` | Persistent navigation and tabs |
| `P04` | Openers, entry modes, and creation modes |
| `P05` | State-changing controls and their side effects |
| `P06` | Settings groups |
| `P07` | Diagnostics, evidence, and review affordances |
| `P08` | External channels and integrations visible to the user |
| `P09` | Main journey and observable outcome |
| `P10` | Important choice or branch |
| `P11` | Control semantics, including stop, cancel, and retry |
| `P12` | Failure recovery and irreversible boundaries |
| `P13` | Diagnosis path and visible signals |
| `P14` | Product objects, lifecycle, and source of visible truth |
| `P15` | Current maturity, limitation, target, and gap |
| `P16` | Acceptance, rejection, handoff, and follow-up |
| `P17` | Identity, access, multi-user, and actor semantics |
| `P18` | Privacy, retention, and audit semantics |
| `P19` | Product non-goals |
| `P20` | Product-to-architecture bridge |
| `P21` | Non-page product surfaces: commands, public API/SDK/library interfaces, output artifacts or reports, notifications, and help/onboarding |
| `P22` | User problem, current pain, value proposition, and the current product promise that answers them |
| `P23` | Sustained user value across repeated real tasks: exact outcome-metric and counter-metric definitions, applicable audience, observation window, source and privacy boundary, current baseline (write `unknown` when it is not yet measured), feedback entry and feedback-to-roadmap loop, and the owner plus threshold or event that triggers a product decision |

`P22` is the plain answer to why this product exists now; a feature list or
future vision cannot substitute for the current problem, pain, value, and
promise. `P23` asks whether that value survives repeated real work and how the
team learns when it does not. It never requires invented adoption numbers or a
measurement system the repository does not have: define what each metric means,
who it applies to, the observation window, and where the data comes from; name
the privacy boundary; write the current baseline as `unknown` when it has not
been measured; and state which threshold or event makes which owner take a
product decision. Also preserve the feedback route and feedback-to-roadmap
loop. `Q03` owns whether one interaction is learnable, operable,
self-explanatory, assisted, feedback-rich, and resistant to user error. `P23`
consumes results across repeated tasks, including abandonment and user
feedback, to change outcome measures and the roadmap. `Q20` remains about the
functional completeness/correctness/appropriateness and validity of an
individual function, output, or decision; neither Q row substitutes for the
product-value learning loop.

### Product brief and model

- Who are the primary and secondary users or operators, and in what deployment
  or organisational setting do they work?
- What job are they trying to complete, what frustrates them today, and what
  user-visible result counts as success?
- What pages, entry modes, controls, settings, integrations, diagnostics,
  commands, public interfaces, output artifacts, notifications, and
  help/onboarding surfaces can they actually use today?
- What are the core product objects, how does a user understand their
  lifecycle, and which object is the source of visible truth?
- What does the product promise, limit, target, or explicitly keep out?
- What identity, access, multi-user, data-retention, privacy, and audit
  expectations affect the product experience?

### Capabilities

Each stable capability explains:

- why the user needs it;
- one current end-to-end scene;
- what the user can do today and what they see when it fails;
- important state, permission, and recovery boundaries in user language;
- current maturity and target posture;
- an example of product acceptance;
- architecture and test owners in a short evidence appendix.

Do not put implementation flow, SQL, line-number pins, or test inventories in
the product narrative. A capability may link a compact evidence row, but the
reader should not need it to understand the promise.

### Journeys

The journey set covers the primary happy path plus the important choice,
control, recovery, diagnosis, and target-only paths. Each journey names its
trigger, user goal, touchpoints, decision points, failure/recovery experience,
completion meaning, and capability links. Do not splice target-only steps into
a current journey.

### Product truth has two axes

Never use verification fidelity as product maturity. Record them separately:

| Axis | Vocabulary | Question answered |
|---|---|---|
| Product maturity | `current`, `limited`, `target`, `out` | What can the user rely on today? |
| Evidence fidelity | `browser`, `integration`, `unit`, `static`, `missing` | At what user-observable or internal layer has that claim been verified? |

`browser` means a rendered interaction surface, but its evidence note must say
whether it used a real backend/runtime (`browser:real-runtime`) or a rendered
mock/stub (`browser:rendered-mocked`). The latter proves layout and interaction,
not end-to-end runtime truth. `integration` means a real API/SDK/runtime path
without claiming the browser experience. `current`
with lower-fidelity evidence is a verification gap, not automatically a target
feature. `target` with a unit test is still not current. Every
`limited` or `target` product surface names current behaviour and a falsifiable
closure owner.

### Surface coverage

During bootstrap or product audit, inventory the finite visible surface from
the implementation, not from marketing labels or link existence. Inclusion is
mandatory for routes/pages, persistent navigation/tabs, openers and entry or
creation modes, state-changing controls, settings groups, diagnostics,
evidence/review affordances, external channels, commands, public API/SDK or
library interfaces, output artifacts or reports, notifications, and
help/onboarding. A product may aggregate
repetitive micro-controls only when the row names the aggregation rule and all
members share one owner, maturity, side-effect boundary, and recovery posture;
a control with a distinct write, permission, irreversible effect, or failure
path gets its own row. Source PRDs alone cannot establish a current surface;
verify path semantics and visible labels against the mounted route, handler,
default DOM, CLI surface, or other real entry point.

A planned visible surface with no implementation must not invent a source
anchor and must not be mislabeled `out`. Its source cell is
`planned_in: [resolving product roadmap or acceptance owner](...)`, maturity is
`target`, fidelity is `missing`, and closure is falsifiable. A genuinely absent
class uses `not_applicable: <reason>`, `out`, `static`, and a disposition reason.

The product-root manifest owns the finite surface inventory. Give every item a
stable `surface:<slug>` identifier and one of these classes: `page`,
`navigation`, `entry-mode`, `control`, `settings`, `diagnostic`,
`external-channel`, `command`, `public-interface`, `output-artifact`,
`notification`, or `help-onboarding`. Record its unique product owner, product
maturity, evidence
fidelity, and a stable evidence pointer or falsifiable closure condition. Each
class is either represented by a real item or has a reasoned `not_applicable`
row. A generic capability list, a count, or a source-tree guess is not a surface
inventory.

Identity and audit claims state their semantic granularity. A stable actor
token, service principal, session, or machine identity is not evidence of a
human identity or accountable human audit trail. Persona prerequisites,
handoff, acceptance/rejection, and follow-up must match what the outcome
reviewer can actually observe. Explain every repository-specific acronym,
role, mode, state label, and call-to-action on first use when it appears in a
reader path; examples from one consumer must not become required vocabulary in
another.

## 4. Architecture completeness

What a domain *owns* is defined solely by
[`architecture.md §3`](architecture.md#3-thin-defaults); this section defines
only what a domain reader surface must *teach* — the acceptance rubric below
derives from that single ownership definition and does not restate it.

The architecture trunk collectively answers every applicable question below.
The root teaches the system; views explain cross-owner relationships; domains
own detailed runtime truth.

The v2.60 architecture completeness profile is exact. Its 48 rows are all
common items `C01`-`C09`, all architecture items `A01`-`A18`, and all shared
quality items `Q01`-`Q21`, each exactly once.
Missing metrics or traces are normally a documented gap with an owner, not a
casual `not_applicable` claim.

| ID | Required architecture question |
|---|---|
| `A01` | Current request-to-result story |
| `A02` | Actors and system context |
| `A03` | Runtime, support, and target owners |
| `A04` | State and write ownership |
| `A05` | Contracts, trust, and permissions |
| `A06` | Failure, recovery, and degradation |
| `A07` | Deployment topology and variants |
| `A08` | Configuration, secrets, and environments |
| `A09` | Health and readiness |
| `A10` | Logs and their diagnostic meaning |
| `A11` | Metrics and their diagnostic meaning |
| `A12` | Traces and their diagnostic meaning |
| `A13` | Alert or symptom to diagnosis route |
| `A14` | Restart, rollback, and data irreversibility |
| `A15` | Product-to-architecture bridge |
| `A16` | Finite technical-surface registry |
| `A17` | Current, target, gap, and unknown posture |
| `A18` | Design drivers and constraints, global invariants, key trade-offs, technical non-goals, and why the chosen decomposition fits them |

### Architecture root

The root explains, in this order:

- a current request-to-result story visible to the user or operator;
- the system context and external actors;
- the runtime-owner decomposition and why it matches state/failure boundaries;
- the few global invariants and the pressure each one addresses;
- the first reading path for flow, state/data, trust/contracts,
  failure/recovery, and current/target/gap;
- a short current/target/gap posture.

One useful context diagram is better than several overlapping inventories.
Root detail stops where a view or domain becomes the owner.

### Cross-owner views

For non-trivial services, the default cross-owner set is:

- `operating-model.md` — design pressures, priorities, trade-offs, and
  technical non-goals;
- `critical-journeys.md` — end-to-end current paths and their visible result;
- `state-and-data-lifecycle.md` — durable and ephemeral state, write owners,
  transitions, retention, rebuild, and recovery;
- `contracts-and-trust-boundaries.md` — public/internal contracts,
  authentication, permissions, secrets, redaction, environment, and external
  integration boundaries;
- `failure-and-recovery.md` — detection, retry, cancellation, rollback,
  restart, degradation, and operator diagnosis across owners;
- `deployment-and-observability.md` — runtime topology, deployment variants,
  health signals, logs/metrics/traces, alert-to-diagnosis paths, and operator
  surfaces across owners;
- `current-target-gap.md` — implementation evolution only.

Small repositories may merge a view with a reason. Large repositories may add
a view only for a recurring cross-owner question. Views synthesize owner facts;
they do not mirror domain tables.

The architecture root also gives a compact product-to-architecture bridge: for
each stable product capability or current user surface class, name the runtime
owner(s), contract or state boundary that carries it, and the cross-owner view
that explains failure or operations. This is routing, not a duplicate product
specification.

### Runtime-owner domains

A domain reader surface explains:

1. a mental model and why this boundary is separate;
2. a first-screen component diagram for every covered domain, because a
   separately named runtime owner must display the boundary that justifies it;
3. one canonical current flow and its user/operator outcome;
4. owned state/resources and lifecycle;
5. three to five load-bearing contracts;
6. a representative runtime failure and recovery path;
7. concurrency, configuration, trust, deployment, or operations when they
   change this owner's behaviour;
8. local current/target/gap and verification direction.

These are questions, not a mandatory heading checklist. Combine related
answers and remove non-applicable sections. Machine pins and exhaustive rows
belong in the domain manifest or a dedicated reference appendix.

Document-self drift and retirement conditions belong in the domain manifest.
They do not appear as `Failure Modes` or `Closing Conditions` before the
runtime mental model. The prose body owns runtime failure/recovery only.

Prefer `path::symbol`, route names, SQL identifiers, selectors, or test names
over volatile line-number pins. A line number may be an auxiliary hint, never
the only stable anchor.

## 5. Source-to-owner coverage

File-level `absorbed` is not enough for a major product or architecture audit.
Build a topic disposition for the audited corpus. Each material topic is one
of:

- `absorbed` — current durable fact has an owner;
- `linked` — the source remains the appropriate evidence surface;
- `rejected-stale` — contradicted or superseded, with current owner named;
- `gap` — important but not yet proven or owned, with closure owner.

Sample the real routes, state transitions, persistence, failures, auth,
deployment, operations, and user-visible surfaces most likely to invalidate
source material. Do not promote uncommitted worktree candidates into current
authority.

## 6. Manifest archetypes

Bootstrap chooses a manifest by owner type instead of copying one universal
table everywhere:

| Archetype | Required recovery content | Forbidden cargo |
|---|---|---|
| `product-root` | core product spine/capability/journey rows plus finite user-surface inventory across all twelve classes, maturity, evidence/closure | apex registry, runtime implementation mirror |
| `product-collection` | one row per child owner, maturity, evidence/closure | root completeness rows, apex registry |
| `architecture-root` | every direct runtime/support/target owner, views, global invariants, CTG, product bridge, unique technical surface registry | child symbol inventories |
| `architecture-views` | one row per cross-owner view, including deployment/observability, and required question class | apex registry, domain symbols |
| `architecture-domain` | boundary, core state/contracts/flows, stable evidence pins, document invalidation/retirement conditions | global apex or capability mirrors |

Every manifest starts with `manifest_archetype: <value>`. A `covered` manifest
contains no TODO, author handoff, placeholder path, empty required cell, or
section forbidden for its archetype. Optional machinery is omitted rather than
left as an empty table.

Bootstrap `gap` is recovery coverage, never product maturity. Until evidence is
reviewed, a product manifest keeps maturity `not_assessed` beside a separate
`gap` coverage cell; before `covered`, replace it with
`current|limited|target|out`. Architecture rows analogously use
`contract|design|poc|debt|mixed` only after verification.

For protocol v2.60 and later, the architecture-root manifest enumerates every
direct numbered owner directory and classifies it as `runtime`, `support`, or
`target`; silence is not classification. It also owns a finite unique technical
surface registry. Give each surface a stable `tech:<slug>` identifier, one kind
(`entry`, `write-store`, `contract`, `operator-surface`, or
`external-integration`), exactly one narrative owner, its current state, and a
stable anchor plus evidence or closure direction. A row may route to multiple
participants, but one owner remains authoritative. The architecture-views
manifest enumerates every default cross-owner view or a reasoned
`not_applicable` disposition.

The direct numbered directory set and owner-registry rows are one-to-one. Each
owner row uses a stable `owner:<slug>` ID and one resolving Markdown link to its
reader body. Every technical surface references one registered owner ID, uses a
globally unique stable anchor whose repository path resolves, and has fitting
evidence or an explicit closure. The architecture root carries an exact kind
disposition table for `entry`, `write-store`, `contract`, `operator-surface`,
and `external-integration`: `applicable` names at least one registry row of that
kind; `not_applicable` gives a named reason and has no such row. Small systems
must not invent five fake surfaces merely to fill the vocabulary.

The product bridge header uses `Product surface ID` and `Runtime owner ID`.
Its surface-ID multiset equals the product inventory exactly: every current,
limited, target, and out surface appears once, with no extra or duplicate row.
Current/limited/target rows reference a registered owner ID, state the contract
or planned state boundary, and link to a resolving Markdown view under
`02-architecture/views/`; target may route to an owner classified `target`.
An `out` surface uses a named `not_applicable` disposition in the runtime-owner,
boundary, and view cells rather than inventing a runtime implementation.

## 7. Cold-reader acceptance

`covered` and `converged` are the only Area Status states that require this §7
review. `partial` — the pre-gate honest state of an owner README, the shared
writing floor, a clean Doctor L1 for the scope, and a scoped self-review
recorded with `authorises=area:<scope>:partial` — does not.

Product and architecture `covered` claims use a task-based review of the actual
Markdown. Routing, comprehension, completeness, truth, and evidence are
separate gates. Start every task at `SSOT/README.md`; do not give the reviewer
source code, manifests, prior reviews, author plans, or the expected answer
before the first teach-back.

### 7.1 Frozen review identity and freshness

Every artifact records a `review_id`, `review_type`, repository commit, content
fingerprint, sample seed, rotation ID, and task counts. The commit must resolve
and be an ancestor of or equal to current `HEAD`. Equality is valid for a
pre-commit review; exact content freshness comes from the fingerprint.

Both product and architecture reviews carry two fingerprints. The first is the
same shared reader-surface `content_fingerprint`, so a root or cross-scope trace
change expires both: `SSOT/README.md` plus every Markdown file under
`SSOT/01-product/` and `SSOT/02-architecture/`, excluding `.bootstrap/`. Sort
paths in byte order; for each file emit
`<path-relative-to-SSOT>\0<lowercase-file-sha256>\n`; hash the concatenated
stream with SHA-256.

The second is `quality_disposition_fingerprint`. It expires both reviews when
the semantics of any STATUS Q disposition change, without expiring them for an
unrelated STATUS tracking-baseline edit. Parse the exact Quality, Risk, and Governance
table by its named columns; trim leading and trailing cell whitespace, collapse
internal whitespace runs to one space, remove optional outer backticks from the
`Q ID` only, sort rows by `Q ID` in byte order, and
emit
`<Q-ID>\0<Applicability>\0<Product-owner>\0<Architecture-owner>\0<Process/evidence-owner>\0<Gap-owner>\n`
for `Q01`-`Q21`. Hash that stream with SHA-256. Markdown link labels and targets
remain part of the normalized cells because changing either can change the
reader's meaning or route. Heading wording, table alignment whitespace, and
other STATUS sections do not enter this fingerprint. Chat links, timestamps,
and commit ancestry alone do not establish freshness.

`review_type: high-impact-adoption` requires
`reviewer_role: independent-cold-reader`. `review_type: routine` may use
`scoped-self-review` when `status-protocol.md §6` allows it. Template comments
must state this conditionally; independence is not a universal claim.

### 7.2 Exact mandatory task matrix

Product reviews contain each of these task classes exactly once:

1. `product-orientation-decision`;
2. `product-main-journey-acceptance`;
3. `product-control-failure-recovery`;
4. `product-surface-inventory`;
5. `product-boundary-trust-data`;
6. `product-architecture-trace`.

Architecture reviews contain each of these task classes exactly once:

1. `architecture-orientation-request-result`;
2. `architecture-owner-state-contract`;
3. `architecture-failure-recovery`;
4. `architecture-deployment-diagnosis`;
5. `architecture-product-trace`;
6. `architecture-inventory-evidence`.

Every task row records the reader and decision, delegated action, expected
visible result, stop/escalation boundary, `SSOT/README.md` entrypoint, files
opened, actual hops, observed outcome, table-hidden result, evidence and limit,
and verdict. Passing requires at most four hops, a complete observed outcome,
`table-hidden result = pass`, fitting evidence with its limitation, and
`verdict = pass`. The evidence sample contains one row for every mandatory
task; there is no two-link sampling cap.

### 7.3 Five scored families and sixteen leaves

Score each applicable task from 0 to 2 for each leaf. `0` means absent,
misleading, or unusable; `1` means recoverable only with material friction or
an important gap; `2` means clear, local, concrete, and consistent enough to
decide and act. The artifact maps tasks to applicable leaves before scoring.
Each leaf score is the **minimum** of its applicable mandatory-task scores,
never an average.

| Family | Leaf | Dimension |
|---|---|---|
| Reader fit (`RF`) | `RF1` | Reader, decision, and action fit |
| Reader fit (`RF`) | `RF2` | Orientation and visible outcome |
| Plain-language clarity (`LA`) | `LA1` | First-use terminology |
| Plain-language clarity (`LA`) | `LA2` | Plain-language cognitive load |
| Plain-language clarity (`LA`) | `LA3` | Concrete grounding |
| Causal and truth story (`CT`) | `CT1` | Causal chain |
| Causal and truth story (`CT`) | `CT2` | Current truth and cross-owner consistency |
| Causal and truth story (`CT`) | `CT3` | Posture, uncertainty, and change |
| Causal and truth story (`CT`) | `CT4` | Success, failure, and recovery |
| Boundary and coverage (`BC`) | `BC1` | Boundaries and non-goals |
| Boundary and coverage (`BC`) | `BC2` | Unique owner and handoff reachability |
| Boundary and coverage (`BC`) | `BC3` | Evidence fitness, fidelity, freshness, and invalidation |
| Boundary and coverage (`BC`) | `BC4` | Scope completeness |
| Reading path (`RP`) | `RP1` | Scannability and progressive disclosure |
| Reading path (`RP`) | `RP2` | Bounded route and locality |
| Reading path (`RP`) | `RP3` | Table-independent narrative |

Passing requires all of the following:

- total at least `29/32`, with no zero leaf;
- family floors `RF >= 3/4`, `LA >= 5/6`, `CT >= 7/8`,
  `BC >= 7/8`, and `RP >= 5/6`;
- for `reader_profile: implementation-delegator`, `RF1 = 2`, `LA2 = 2`,
  `CP-D = pass`, and `CP-T = pass`—this is the reader who delegates coding,
  evaluates outcomes, and need not read code;
- zero critical truth errors and unresolved required changes;
- every mandatory task, truth/evidence sample, inventory gate, and manifest
  gate passes.

### 7.4 Unscored cold-proof hard probes

These probes cannot be averaged away:

| Probe | Required proof |
|---|---|
| `CP-D` | Without reading source code, the reader can make the named decision, state what to delegate, name the expected visible result and fitting evidence with its limit, and know when to stop or escalate. |
| `CP-R` | The authoritative owner is reached within the bounded route. |
| `CP-T` | The table-hidden teach-back preserves the causal conclusion. |
| `CP-E` | Consequential claims have fitting, faithful, fresh evidence and a stated limit. |
| `CP-C` | Every exact completeness-profile item has a disposition. |

Each appears exactly once with evidence from mandatory tasks, `pass`, and a
limit. A path that only resolves is not semantic proof: verify that the path,
visible label, identity/audit meaning, and product-to-architecture mapping say
what the prose claims.

### 7.5 Exact completeness disposition

The artifact contains one `covered|not_applicable` row with reason and evidence
for every common ID, scope ID, and shared quality ID. Product uses `C01`-`C09`,
`P01`-`P23`, and `Q01`-`Q21`; architecture uses `C01`-`C09`, `A01`-`A18`, and
`Q01`-`Q21`. No extra, missing, or duplicated ID is allowed.
`not_applicable` is a reasoned boundary decision, not a substitute for missing
evidence. A `covered` Q row proves the concern was explicitly disposed and
routed; it does not imply the product or mechanism is complete. Missing
implementation or proof is recorded as a named current gap and closure owner.

### 7.6 Durable artifact schema

The frontmatter contains exactly one of every field below (values shown are a
passing product example):

```yaml
review_id: review:product:YYYYMMDD:<slug>
review_scope: SSOT/01-product
review_type: routine
reader_profile: implementation-delegator
completeness_profile: product
protocol_version: "2.60"
reviewed_on: YYYY-MM-DD
reviewer: <stable-human-or-agent-id>
reviewer_role: scoped-self-review
repository_commit: <resolvable-full-or-short-commit>
content_fingerprint: <lowercase-sha256>
quality_disposition_fingerprint: <lowercase-sha256>
sample_seed: <stable-seed>
rotation_id: <stable-rotation-id>
task_count: 6
passed_task_count: 6
failed_task_count: 0
entrypoint: SSOT/README.md
tables_hidden: true
bounded_read_set: true
route_probe: passed
truth_consistency: passed
evidence_sample: passed
scored_dimensions: 16
score: "29/32"
critical_truth_errors: 0
unresolved_required_changes: 0
authorises: area:product:covered
verdict: no-more-required-changes
```

Architecture changes `review_id`, `review_scope`, and
`completeness_profile: architecture`. The body has exactly these six protocol
H2 sections; the route probe belongs inside the bounded-reading section:

```markdown
## Bounded reading set
## Teach-back
## Consistency and evidence sample
## Dimension scores
## Completeness profile
## Required changes and verdict
```

The body also includes the mandatory task matrix, task-to-leaf applicability,
per-task evidence sample, five cold-proof rows, sixteen leaf scores with
applicable task scores and reasons, exact completeness rows, required changes,
and final verdict. A file that merely contains the verdict string is not review
evidence. The only verdicts are `needs-fix` and
`no-more-required-changes`; do not soften or rename them.

The final H2 contains exactly one required-changes table with this deterministic
schema:

```markdown
| Change ID | Status | Required change | Owner | Closure evidence |
|---|---|---|---|---|
| none | none | No required change remains after this review. | — | The unresolved count is zero and the final verdict is no-more-required-changes. |
```

Real change rows use unique `RC-NN` IDs and one of `resolved`, `pending`,
`required`, or `open`. A passing review may retain resolved rows with their
owner and closure evidence, or use the single `none` sentinel above. The
sentinel never coexists with a real change row. The count of `pending`,
`required`, and `open` rows equals `unresolved_required_changes`; any such row
contradicts a zero count or `no-more-required-changes` verdict. Prose below the
table may explain the result, but it cannot override the table.

### 7.7 Lightweight exact-scope review

Process, records, glossary, root, and STATUS do not repeat the six mandatory
product/architecture tasks or the sixteen-leaf score. Their smaller artifact
proves two things together: every exact profile item has a reachable owner or
evidence disposition, and a bounded semantic sample agrees with current
repository or evidence truth. A link that merely resolves cannot support a
passing claim, and no required change may hide behind a green area state.

Use `scope-review.md`. Every lightweight artifact has exactly these frontmatter
fields:

```yaml
review_id: scope-review:<process|records|glossary|root|status>:YYYYMMDD:<slug>
review_scope: <process|records|glossary|root|status>
completeness_profile: <same-scope-token>
protocol_version: "2.60"
reviewed_on: YYYY-MM-DD
reviewer: <stable-human-or-agent-id>
reviewer_role: scoped-self-review
repository_commit: <resolvable-full-or-short-commit>
entrypoint: <canonical-scope-entrypoint>
scope_fingerprint: <lowercase-sha256>
area_disposition_fingerprint: <lowercase-sha256>
quality_disposition_fingerprint: <lowercase-sha256>
profile_item_count: <46|46|38|37|32>
covered_item_count: <integer>
not_applicable_item_count: <integer>
unresolved_required_changes: 0
authorises: <area:<scope>:covered|scope:<root|status>:covered|coverage_result:converged>
verdict: no-more-required-changes
```

`reviewer_role` is `scoped-self-review` or `independent-reviewer`; apply the
independence exceptions in `status-protocol.md §6`. `repository_commit` resolves
to an ancestor of current `HEAD`. The date segment in `review_id` equals
`reviewed_on`, and every linked passing artifact has a unique `review_id`.

The exact entrypoints are `SSOT/03-process/README.md`,
`SSOT/04-records/README.md`, `SSOT/glossary/README.md`, `SSOT/README.md`, and
`SSOT/STATUS.md`. The scope fingerprint hashes the current Markdown files under
the corresponding process, records, or glossary directory; root hashes only
`SSOT/README.md`; STATUS hashes only `SSOT/STATUS.md`. Sort paths in byte order,
then emit `<path-relative-to-SSOT>\0<lowercase-file-sha256>\n` and hash the
stream with SHA-256. All five artifacts also carry the Q fingerprint defined in
§7.1 because every lightweight profile includes `Q01`-`Q21`.

The area-disposition fingerprint prevents a parent review from staying green
after a child row changes. Process hashes the normalized Area Status rows for
`process`, `development`, `testing`, `benchmark`, `deployment`, `release`,
`operations`, and `security-and-compliance`; records hashes `records`,
`decisions`, `research records`, `gotchas`, `bugs`, and `tech-debt`; glossary
hashes its own row. Root and STATUS hash all seventeen baseline rows. In the
listed order, emit `<Area>\0<Status>\0<normalized Notes>\n` and hash the stream
with SHA-256. A missing or duplicate row cannot produce a passing fingerprint.

The body has exactly three H2 sections:

```markdown
## Review basis
## Exact profile
## Required changes and verdict
```

Chinese artifacts use the three localized H2 headings from the Chinese
`scope-review.md` template.
The `Review basis` section first contains the exact three-row route/fingerprint
check shown by `scope-review.md`; every result is `pass` with a non-empty
evidence/limit cell. It then contains one semantic-truth sample table with exact
columns `Item ID`, `Owner/body claim`, `Repository/evidence sample`, `Truth
result`, and `Limit` (using the corresponding localized columns under a Chinese
language lock). Sample IDs are unique members of the exact profile. At
least one sample comes from each profile family: process=`C`,`PR`,`Q`;
records=`C`,`R`,`Q`; glossary=`C`,`G`,`Q`; root=`C`,`RT`,`Q`; status=`S`,`Q`.
If the exact profile contains both `covered` and `not_applicable` dispositions,
at least one sampled ID comes from each. Every row in a passing artifact has
`Truth result=pass`, a specific owner/body claim, one resolving non-review
Markdown evidence link, and a limit that says what the sample does not prove.

Family sampling does not prove the whole scope. The same section therefore has
an exact target-coverage table with columns `Target ID`, `Target owner`,
`Profile IDs exercised`, `Repository/evidence sample`, `Truth result`, and
`Limit` (using the corresponding localized columns under a Chinese language
lock). Process targets its root and every actual child README.
Records targets its root, all five collection indexes, and every real entry or
gotcha anchor. Glossary targets its root and every real term owner or anchor.
Root and STATUS each target themselves. Every real target appears exactly once,
all evidence links resolve to that exact non-review target, all passing rows say
`pass`, and the union of exercised IDs is the complete exact profile. An empty
target table, three convenient files, or repeated links to one root cannot
authorise coverage.

The exact-profile table has `Item ID`, `Disposition`, `Plain answer`, and
`Owner / evidence` columns (using the corresponding localized columns under a
Chinese language lock). It contains the profile's exact ID set once each, with
no extra row.
Disposition is `covered` or `not_applicable`. Every owner/evidence cell contains
exactly one resolving Markdown link; `not_applicable` also gives a named reason.
Every plain answer states the current conclusion in ordinary language. It may
use an exact state name where needed, but it cannot merely repeat the profile
question, cite the protocol ID, or say that a link exists.
The final section uses the same deterministic required-changes table and
verdict consistency rules as §7.6.

STATUS supplies both authority and reachability:

- a covered `process`, `records`, or `glossary` Area Status Notes cell keeps one
  direct canonical-owner link and exactly one matching lightweight artifact
  link; other links must not masquerade as a second current review;
- the Stop Review Gate contains exactly one matching `covered` row whose
  evidence resolves to that same artifact and whose `authorises` value is
  `area:<scope>:covered`;
- when `coverage_result` is `converged`, the Stop Review Gate contains matching
  `root` and `status` rows, each with stop claim `converged`, evidence pointing
  to its artifact, and `authorises: coverage_result:converged`.

Root and STATUS may also be reviewed before whole-SSOT convergence. In that
case use stop claim `covered` and `authorises: scope:root:covered` or
`scope:status:covered`. This proves the document scope only; it does not imply
or authorise `coverage_result: converged`.

The stop row and artifact agree on reviewer, reviewer role, review date,
authorised claim, and verdict. Below v2.60, or while the relevant area is not
`covered` and the whole SSOT is not `converged`, this gate does not invent a
review obligation.

## 8. Reader-surface regeneration loop

When generated SSOT content in any affected scope fails its review gate, do not
patch the review wording or add another summary layer. Product and architecture
use the task-based cold-reader review; process, records, glossary, root, and
STATUS use the lightweight exact-scope review. Run the same repair loop against
the files and review type that own the failed claim:

1. freeze the failing consumer files and review evidence as the baseline;
2. map each reader symptom to the protocol or template that allowed it;
3. inventory every applicable profile item, surface, owner, view, record, term,
   and register route as owned, gap, or reasoned `not_applicable`;
4. rewrite bottom-up: unique owners first, then collections, journeys or views,
   then roots and derived registers; delete duplicated state definitions;
5. run deterministic lint, then the scope's task-based or lightweight review
   against the rendered Markdown;
6. if the verdict is `needs-fix`, regenerate the affected SSOT from the repaired
   protocol/templates and repeat from the earliest false assumption. Do not
   hand-edit a green artifact over unchanged weak content.

Stop only when source protocol, installed skill, consumer `STATUS.md`, manifests,
reader bodies, and review artifacts agree at one protocol baseline, and both
the deterministic gate and the cold-reader gate pass. Passing lint alone never
ends this loop.
