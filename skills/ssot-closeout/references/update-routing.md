# Update Routing Reference

This file owns closeout/update routing: impact tiering, file-type signals,
conversation signals, cascade checks, testing-ledger boundaries, agent
actionability, and decision-overturn checks.

The default path is a decision tree. The tables are fallback reference, not the
normal execution path.

## 1. Routing In Five Questions

1. **What changed?** Identify whether the source is code/config/schema, tests,
   docs/source material, SSOT/protocol/template text, conversation signal,
   decision overturn, bug fix, or generated artifact.
2. **Did a durable fact change?** If the change only proves this batch ran,
   keep it in final response, commit note, CI artifact, release note, bug entry,
   or stop-review evidence. Do not create a shadow ledger.
3. **Is the problem a protocol gap?** When a consumer SSOT/docs problem exposes
   a repeatable gap in SSOT-SKILL protocol, templates, or lint, and this
   repository owns the bundle, fix SSOT-SKILL first. Then migrate the consumer.
4. **Who owns the fact?** Product promises go to `product/`; technical runtime,
   state, contract, failure, trust, and current/target/gap facts go to
   `architecture/`; testing policy goes to `testing/`; recurring procedural
   rules go to `development/`; file/module traps go to `gotchas/`; root causes
   go to `bugs/`; deferred work goes to `tech-debt/`; adjudicated trade-offs go
   to `decisions/`.
5. **What is the impact tier?** Trivial changes usually need no SSOT update;
   localized changes check the direct owner; cross-cutting changes also run the
   cascade path.
6. **Does it cascade?** Check only areas actually linked to the changed owner,
   decision, flow, product promise, schema, security boundary, or failure mode.

If routing remains unclear, use the fallback classifier in
`ssot-preflight/references/area-model.md §4.1`: imperative rule ->
`development/`, file-scoped trap -> `gotchas/`, trade-off -> `decisions/`,
bug-instance takeaway -> `bugs/<entry>.md`. Never create a new top-level area
just because a fact is hard to route.

## 2. Frequent Routes

**Code changes** usually update architecture only when they change a public
contract, state/resource ownership, runtime order, persistence, failure or retry
semantics, trust/config boundary, observability contract, or a domain split. A
routine internal helper edit usually records no SSOT change.

**Tests and test results** update `testing/` only when future test selection,
quality gates, fixtures/test data, current baselines, known gaps, or defensive
test maps change. A one-time pass/fail result is evidence for this batch.

**README/docs/ADR/runbook/PRD/source material** first goes through source
material lifecycle and absorption. Product facts enter `product/`; technical
facts enter the right architecture view/domain, decision, debt, gotcha, bug,
testing, release, or deployment owner. `STATUS.md` records classification,
lifecycle, downgrade fields, and pointers only. Working/historical docs may stay
outside SSOT, but they must not masquerade as current authority.

**SSOT readability/actionability gaps** should fix SSOT-SKILL first when the
repository owns the bundle and the weakness is repeatable across projects. Then
repair consumer SSOT using the improved rule.

**Temporary surfaces** -- fallback, compat shim, later-remove path,
TODO/FIXME/HACK/WORKAROUND, temporary waiver, or deferred cleanup -- route to a
real owner before closeout. Prefer an existing `tech-debt/`, `bugs/`,
`decisions/`, or owner-specific gap entry; create one when the current wording
only says "TODO debt" or "follow up later". A registered temporary surface must
name owner, reason, closure condition, revisit signal, and verification guard.
If those fields cannot be written, do not call the area `covered`; leave an
open gap instead.

**Conversation directives** route by their durable meaning: product promises to
`product/`, decisions to `decisions/`, recurring agent discipline to
`development/`, pitfalls to `gotchas/`, root causes to `bugs/`, and future work
to `tech-debt/`.

## 3. Impact Tiering

| Impact | Characteristics | Check depth |
|---|---|---|
| trivial | Formatting, comments, typo fixes, pure refactors with no behavior or authority change | Usually no SSOT update. If recording `no-op`, use stop review. |
| localized | Implementation or documentation change within one owner/domain | Check the corresponding owner and matching gotcha/bug/debt triggers. |
| cross-cutting | Cross-domain, cross-tier, protocol, product, schema, trust, or architectural change | Check direct owners and run targeted cascade checks. |

This tiering is coarse. Judge by actual behavior and authority impact.

## 4. Cascade Checks

Run cascade only when the changed fact has linked owners. Do not traverse every
area by default.

```text
1. Identify the changed owner/fact.
2. Ask whether another owner links to or depends on it.
3. Check only those linked areas.
4. Update stale linked facts, or record no-op with stop review.
```

High-impact scenarios that commonly cascade:

- decision overturn;
- architecture-domain reorganization;
- runtime flow, lifecycle, state, schema, config, trust, or failure model
  change;
- product promise/capability/journey/acceptance change;
- security or error-handling strategy change;
- discovery of long-term agent-operation discipline;
- SSOT readability/actionability gap that is systemic.

Appendix C keeps the detailed cascade lookup matrix.

## 5. Testing Ledger Boundary

`testing/` records stable testing policy and protective maps, not chronological
proof that a particular batch ran. Before writing there, ask whether the
sentence would still be useful after the next test run. If not, keep it out of
SSOT or place it in an authorized evidence owner.

Write to `testing/` when the result changes strategy, selection matrix, quality
gate, fixture/test-data contract, current baseline, known gap, or defensive-test
mapping. Do not write one batch's transcript, date, duration, or latest green
state.

## 6. Agent-Actionability Boundary

Agent actionability is an orientation layer inside an existing owner, not a new
playbook area. Add it only when it tells a future agent when to read the owner,
where to inspect first, what not to do, or how to verify closure. If the issue
is repeatable across projects and this repository owns SSOT-SKILL, fix the
bundle first.

## 7. Appendix A: File-Type Routing Table

| Changed file type | Possibly affected areas |
|---|---|
| Source code add/delete/move files or directories | `architecture/` design units, boundaries, dependencies, decomposition/domain diagram |
| Source code public/exported signature changes | `architecture/` contracts and affected flow/trust diagrams |
| Source code internal logic | Usually no SSOT update unless dedicated phase, state, lock, rollback, persistence, contract, failure, or gotcha semantics changed |
| Error handling / retry / circuit breaker | `architecture/` failure-recovery model and diagrams |
| Auth / authorization / permissions | `architecture/` trust boundary and invariants |
| Logs / metrics / traces | `architecture/` observability or verification evidence |
| Package manifest / lockfile | `development/`, `architecture/`, `release/` when dependency/runtime/release facts change |
| Test files / test configuration | `testing/` only for durable testing policy/baseline/gap/fixture/map changes |
| SSOT Skill protocol, templates, or maintenance scripts | Update SSOT-SKILL first if present; then repair consumer SSOT |
| SSOT Markdown body or indexes | Update the unique owner; for systemic readability/actionability issues check protocol/template/lint first |
| CI/CD | `deployment/`, `release/` |
| Dockerfile / k8s / Terraform / infrastructure | `deployment/`, `architecture/` runtime/config model |
| schema / migration / protobuf / OpenAPI | `architecture/` data/state/contracts |
| Config / env / feature flags | `architecture/` config/trust model; deployment for environment differences |
| Monitoring / alerting | `architecture/` observability/verification evidence |
| README / docs / ADR / runbook / PRD / planning | Source-material absorption; product facts to `product/`; technical facts to owner |
| Working docs / PoC / closure / report / historical docs | Source-material lifecycle inventory; downgrade fields; absorb durable product/architecture facts only |
| Generated diagrams / screenshots / dependency graphs / auto-summaries | Source-material/diagram candidates only; facts must be verified and rewritten as maintainable owner content |
| Deleting legacy surface / retiring compatible paths | `architecture/` evolution/current-target-gap plus gotchas/decisions/testing as linked |
| Bug fix / hotfix / revert-fix loop | `bugs/`, split by failure mode when critical/major/recurred |
| External SDK / third-party API integration | `architecture/`, `development/` discipline, and `bugs/` when a prior recurrence drove the rule |

## 8. Appendix B: Conversation Signal Routing Table

| Pattern in conversation | Possibly affected areas |
|---|---|
| Option selection or "we decided..." | `decisions/` |
| "Do not touch..." / trap | `gotchas/` |
| Root cause analysis | `bugs/` |
| Recurring bug / hotfix loop | `bugs/`, split by failure mode; recurrence timeline for same root cause |
| Temporary fix / later refactor | `tech-debt/` |
| Fallback / compat shim / later-remove / temporary waiver / TODO left in current code | `tech-debt/` or the owning `bugs/` / `decisions/` entry, with owner + reason + closure condition + revisit signal + verification guard |
| Technical priorities / non-goals / NFRs | `architecture/views/operating-model.md`, CTG, or `decisions/`; product promises first enter `product/` |
| Product promises / users / capability / journey / acceptance / roadmap | `product/` |
| Constraints | architecture operating model/domain constraints; decisions if long-lived trade-off |
| Design intent / do not revive old approach | architecture CTG/domain trade-offs and `decisions/` |
| New or corrected terms | `glossary/` |
| Boundaries, dependencies, runtime flows, state ownership | `architecture/` |
| Test strategy / coverage goals | `testing/` only if durable policy/baseline/gap/map changes |
| Deployment or environment differences | `deployment/`, architecture config/trust model |
| Security / permission / secret model | architecture trust boundary |
| Error handling / retry / degradation | architecture failure-recovery |
| Release/versioning strategy | `release/` |
| Data model / migration strategy | architecture data/state |
| Current/target diagrams or architecture diagrams | architecture diagrams with current/target separation |
| High-frequency/high-risk task entry | `SSOT/README.md` task-entry thin index |
| External material/spec/PRD/design doc | Source-material absorption |
| "From now on always..." / "never..." | `development/` discipline |
| Mock-only test passed but real service differed | `development/` discipline plus originating `bugs/` |
| Test run output | Usually no SSOT write unless durable testing facts change |
| Previous fix was wrong because verification was missing | `development/` discipline plus originating `bugs/` recurrence |
| "Where should this lesson live?" | area-model fallback classifier |
| "SSOT is unclear / too complex" | SSOT-SKILL first if owned; then consumer SSOT |

## 9. Appendix C: Cascade Matrix

| High-impact change | Associated area set | Check focus |
|---|---|---|
| Decision overturn | architecture views/domains and areas in old decision scope | Boundaries, contracts, state, deployment, recovery strategy |
| Architecture-domain reorganization | architecture, gotchas, tech-debt | decomposition basis, diagrams, contracts, stale gotchas |
| Runtime flow/lifecycle/state change | architecture, testing | flow diagrams, state diagrams, fixtures |
| Constraint change | architecture, decisions | new/overturned decisions, current/target separation |
| Config structure change | architecture, deployment | config model, trust/config diagram, deployment process |
| Data-model migration | architecture, testing | state ownership, contracts, fixtures |
| Architecture migration / legacy removal | architecture, gotchas, decisions, testing | evolution ledger, do-not-revive concepts, CTG, tests |
| Product promise/capability/journey/acceptance | product, architecture, testing, decisions | product owner, implementation gap, acceptance tests, trade-offs |
| Product / architecture information architecture drift | product, architecture, SSOT-SKILL if systemic | product intent layer vs architecture implementation response; Runtime Owner Map |
| SSOT readability/actionability gap | SSOT-SKILL if present, affected owners, STATUS pointers | systemic protocol/template/lint gap before local repair |
| Security model change | architecture, gotchas | trust boundaries, auth requirements, old gotchas |
| Error-handling strategy | architecture, deployment | failure/recovery diagrams, health checks, alerts |
| Agent-operation discipline | development, originating bugs/decisions, testing when enforcement test added | discipline rule, back-links, enforcement evidence |

## 10. Appendix D: Decision-Overturn Checklist

When a decision is overturned, check only areas referenced by the old decision's
`scope`:

| The old decision affected... | Need to check... |
|---|---|
| Architectural boundary / design unit | corresponding architecture domain and diagrams |
| Public API / protocol / SDK | cross-boundary contracts and flow/trust diagrams |
| Deployment / config model | deployment and architecture config/trust docs |
| Error-handling strategy | failure-recovery owner and diagrams |
| Security model | trust boundary and diagrams |
| gotchas / bugs / tech-debt | related entry state/root cause/resolution |
| Architectural constraints | operating model/domain constraints and CTG |
| Legacy surface / deprecated concept | evolution ledger and do-not-revive wording |
| Runtime flow or high-risk internal flow | runtime flow row, diagram, evidence |
