---
id: DEBT-NNNN
record_status: current
repayment_state: active
status: active
priority: medium
owner: <role-or-owner-path>
created_on: YYYY-MM-DD
updated_on: YYYY-MM-DD
closure_condition: <falsifiable-predicate>
revisit_signal: <path-event-test-or-decision-trigger>
verification_guard: <command-test-or-observable-proof>
temporary_surface: false
---

# <Debt title>

<!-- Writing style: implementation-delegator. First screen: overlap trigger,
     decision, next action, guard, and current lifecycle. -->

<!-- Completeness authority: reader-quality.md C01-C09, R01-R16, and applicable Q01-Q21. -->

## Quick entry

- **Read when** — <task, path, owner, failure mode, or decision overlap>.
- **Decision for the current task** — fix now / recommend now / defer visibly /
  outside scope; <one-sentence reason>.
- **Do not** — <action that deepens or hides the debt>.
- **Next concrete action** — <one bounded repayment step and owner>.
- **Verification guard** — `<command, predicate, or observable proof>`.
- **Current status** — `active` / `resolved` / `obsolete`; <pointer to the
  lifecycle evidence below>.

`record_status` says whether this entry is current routing knowledge, archived,
or superseded. `repayment_state` separately says whether the debt is active,
repaid (`resolved`), or no longer relevant (`obsolete`). The compatibility
field `status` mirrors `repayment_state`.

## Context, facts, and judgment

State when and why the debt was incurred, the current source or environment
state, and what is directly verified. Separate those facts from the judgment
that the compromise is acceptable for now or worth repaying in a particular
way.

## Impact and priority

Explain what becomes harder, riskier, slower, less reliable, or more expensive
while the debt remains. Name affected users, runtime owners, processes, data,
security boundaries, or future changes and why the selected priority fits.
For R15/R16, state affected versions, platforms, environments, tenants/
workspaces, data classes, compatibility window, and any security, privacy,
compliance, customer exposure, disclosure, or notification duty.

## Cause, alternatives, and trade-offs

Explain the pressure that created the debt and why the temporary or incomplete
path was chosen. Record meaningful alternatives, their costs, and any rejected
shortcut that would deepen the problem.

## Repayment plan and next action

Describe the bounded sequence that removes the debt. The first action must be
specific enough for another agent to start without re-litigating intent. Name
prerequisites, permissions, migrations, compatibility steps, side effects, and
the owner of each handoff when they matter.

## Validation and evidence freshness

List evidence for the debt's existence, impact, and repayment state. State the
source state, observation date or version, fidelity, and limitations. Explain
which path, architecture decision, dependency, schema, test, environment, or
temporary-surface change invalidates the evidence.

| Claim | Evidence | Source state / observed on | Limit |
|---|---|---|---|
| | | | |

## Owner, follow-up, and visible deferral

Name the record owner, implementation owner, next review trigger, and linked
issue or decision when scheduling lives elsewhere. If repayment is deferred,
preserve the reason, owner, closure condition, revisit signal, verification
guard, and next action here; “later” alone is not a disposition.

## Closure, resolution, or obsolescence

For `active`, explain how the frontmatter closure condition is observed without
re-debating the design. For `resolved`, identify the repayment change and
verification. For `obsolete`, identify the architecture or decision change
that removed the need and why no hidden temporary surface remains.

## Prevention or recurrence

When applicable, state the test, invariant, review step, or registration rule
that prevents the same debt from returning unnoticed. If no prevention is
reasonable, explain the recheck trigger and owner instead.
