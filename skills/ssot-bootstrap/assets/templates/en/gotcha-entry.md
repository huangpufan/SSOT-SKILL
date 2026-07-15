---
id: GOT-NNNN
record_status: current
hazard_state: active
status: active
created_on: YYYY-MM-DD
updated_on: YYYY-MM-DD
owner: <role-or-owner-path>
trigger: <task-pattern-or-path-glob>
---

# <Pitfall title>

<!-- Single-entry file form: frontmatter `id` is the entry ID. In an existing
     topic file, use the exact stable H2 `## GOT-NNNN`, then put the readable
     pitfall title on the next line as an H3 or bold sentence. Link `#got-nnnn`
     from the collection index. Before the next H2, include this state line:
     - **Record status / hazard state**: `current` / `active`. Topic grouping
     is compatible. -->

<!-- Writing style: implementation-delegator. First screen: trigger, decision,
     safe action, and current status. Define repository terms on first use. -->

<!-- Completeness authority: reader-quality.md C01-C09, R01-R16, and applicable Q01-Q21. -->

## Quick entry

- **When this appears** — <concrete operation, path, or symptom>.
- **Decision** — do not <dangerous intuitive action>; instead <safe action>.
- **First evidence to inspect** — <stable path, symbol, test, log, or decision>.
- **Minimal prevention check** — `<command-or-test>`.
- **Current status** — `active` / `resolved`; <one sentence pointing to the
  entry section that owns the reason>.

`record_status` says whether this entry is current routing knowledge, archived,
or superseded. `hazard_state` separately says whether the trap is active or
resolved. The compatibility field `status` mirrors `hazard_state`.

## Context and observed facts

<!-- State when the pitfall was found, what was directly observed, the source
     snapshot or environment, and what remains inference or judgment. -->

Describe the concrete scene in which a reasonable action leads to the wrong
result. Separate observed facts from the explanation inferred from them.

## Why the obvious move is dangerous

<!-- Explain cause, impact, severity, affected scope, and any irreversible or
     silent side effect. For R15/R16, name affected versions, platforms,
     environments, tenants/workspaces, data classes, compatibility window, and
     any security/privacy/compliance/customer exposure or notification duty. -->

Explain the causal chain from the tempting action to the visible or latent
failure. Name who or what is affected and why ordinary checks may miss it.

## Safer alternative

**Do not**: <unsafe action>.

**Do instead**: <safe path and why it preserves the required boundary>.

<!-- Record considered alternatives and trade-offs when more than one safe
     response exists. -->

## Reproduction and prevention

Describe the smallest reliable reproduction when it is safe to run. Then state
the code guard, process step, test, or review rule that prevents recurrence.
If reproduction is destructive or paid, explain the substitute evidence and
required authority.

## Validation and evidence freshness

List the evidence that proves the trap, the alternative, and the current
status. State when it was observed, its fidelity and limitation, and the path,
API, configuration, architecture, or test change that requires rechecking it.

| Claim | Evidence | Observed on / source state | Limit |
|---|---|---|---|
| | | | |

## Owner and follow-up

Name the entry owner, the implementation or process owner that can remove the
trap, the next concrete action, and the trigger that makes follow-up necessary.

## Resolution or invalidation

For `active`, state the falsifiable condition that would make the pitfall no
longer apply. For `resolved`, name the change or decision that removed it and
the check that confirms the old trigger is gone. Preserve the historical
lesson; do not rewrite the entry as if the trap never existed.
