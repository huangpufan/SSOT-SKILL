---
id: BUG-NNNN
record_status: current
failure_state: open
status: open
severity: major
created_on: YYYY-MM-DD
updated_on: YYYY-MM-DD
owner: <role-or-owner-path>
fixed_in: none
---

# <Failure-mode title>

<!-- Writing style: implementation-delegator. First screen: observable
     signature, first inspection, do-not-do boundary, minimal check, status. -->

<!-- Completeness authority: reader-quality.md C01-C09, R01-R16, and applicable Q01-Q21. -->

## Quick entry

- **Trigger and symptom** — <what the user, operator, or test observes and
  under which condition>.
- **Inspect first** — <stable owner path, state, log, test, or runtime surface>.
- **Do not** — <plausible action that masks the cause or creates false proof>.
- **Minimal verification** — `<targeted regression command or observable check>`.
- **Current status** — `open` / `fixed` / `recurred`; <one sentence pointing to the
  lifecycle evidence below>.

`record_status` says whether this entry is current routing knowledge, archived,
or superseded. `failure_state` separately says whether this is a newly known
failure without a verified fix, a fixed failure, or a previously fixed failure
that has happened again. The compatibility field `status` mirrors
`failure_state`.

Keep `fixed_in: none` while the failure is `open`, or while a `recurred` failure
has no new verified fix. Replace it with a concrete commit, PR, release, or
change reference only after the fitting closure evidence exists. Put an older
invalidated fix in the timeline instead of presenting it as the current fix.

## Incident context and reproduction

State when and where the failure occurred, the affected version or source
state, prerequisites, and the smallest safe reproduction. Describe the visible
result before implementation details. If reproduction is destructive, paid,
or depends on an external system, name the safer evidence path and authority.

## Facts, analysis, and timeline

Separate direct observations from the root-cause judgment. Record the first
confirmed failure, any fix, and any recurrence in time order, but keep only
events that change the failure model, fix, evidence, or lifecycle.

| Date / source state | Observed fact | Interpretation | Evidence |
|---|---|---|---|
| | | | |

## Root cause

Explain the causal chain from trigger to failure when it is known, and why the
previous guard or ordinary check did not stop it. While the cause is unknown,
name the leading hypotheses, their confidence, and the evidence that would
distinguish them. Split the record if the same symptom has more than one
independent root cause.

## Impact and severity

Name the affected users, data, runtime owners, workflows, or guarantees; state
whether the failure is silent, irreversible, security-sensitive, or limited to
a recoverable surface. Record affected versions, platforms, environments,
tenants/workspaces, data classes, and compatibility window (R15). Record any
security, privacy, compliance, customer exposure, disclosure, or notification
duty and its owner (R16). Explain why the selected severity fits.

## Options and fix

Describe the proposed or chosen fix in terms of the root cause it would close.
If no fix has been chosen, state the current containment and next investigation
step. Record meaningful alternatives and trade-offs, especially when a
workaround was rejected or retained as debt. Link any resulting decision,
gotcha, architecture change, or technical debt owner.

## Validation and evidence freshness

Use evidence at the fidelity of the failure: a real user/runtime path for a
user/runtime claim, plus a targeted regression that protects the root cause.
State source state, environment, observed result, and limits. Name the code,
configuration, dependency, schema, test, or product-surface change that makes
the evidence stale.

| Claim | Evidence / command | Result and source state | Limit |
|---|---|---|---|
| | | | |

## Prevention and recovery

Explain the regression guard and how a future agent distinguishes this bug from
nearby failures. Include safe recovery or workaround steps for affected users
or operators when the failure can happen before a fix is deployed.

## Owner and follow-up

Name the bug-record owner, implementation owner, next action, and trigger for
rechecking. If scheduling remains open, link the issue owner without moving the
root-cause knowledge out of this entry.

## Current resolution or recurrence

For `open`, state the evidence that confirms the failure, the current
containment or investigation, and the falsifiable checks required to reach
`fixed`. For `fixed`, state the evidence that closes the failure mode and the
condition that would reopen it. For `recurred`, state the new evidence that
invalidated the earlier closure, why the problem remains open, and the
falsifiable checks required to return to `fixed`.
