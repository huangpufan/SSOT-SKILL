# <runtime owner> Playbook (maintenance / onboarding / verification)

<!-- Writing style: implementation-delegator. State the task decision and safe
     visible outcome before commands; include failure, recovery, and evidence. -->

<!-- Render at SSOT/02-architecture/NN-<domain>/playbook.md only when the domain
     has at least three repeatable implementation task branches. -->

> Use this playbook for repeatable implementation tasks in this runtime area,
> such as adding an adapter or migrating a data field. The local README explains
> what the area promises and owns; this file explains how to change it safely.

## 0. Startup check (run every time)

- Read [SSOT status](../../STATUS.md) and the [SSOT entry](../../README.md).
  Confirm the current tracking baseline, open gaps, document language, and the
  owners routed for this task.
- `git status -s` — record unrelated dirty paths you must NOT stage.
- Read [`README.md`](./README.md) "Owned state and lifecycle" and "Contracts and trust boundaries" before acting; this playbook assumes you understand the current contract and applicable Q01-Q21 risks.

## 1. Task branch A: <name the most common mechanical task>

State what to delegate, the expected visible result, and when to stop or
escalate before listing implementation steps.

Pre-conditions:
- ...

Implementation order (each step must complete before the next):

1. ...
2. ...

## 2. Task branch B: <next most common task>

(Mirror §1 shape; add §3, §4 as the domain accrues mechanical task branches.)

## 3. Pre-commit gates

Run in order; any failure blocks the commit:

1. Targeted test selection: ...
2. Suite-level fast suite: ...
3. SSOT lint: ...

## 4. Debug ladder

Walk top-to-bottom; each step proves the previous step was clean:

1. ...
2. ...

## 5. Definition of Done

- All steps in the active task branch complete.
- Section §3 gates green; any skip names the missing prerequisite.
- SSOT updated in the same commit (README contract truth, gotchas / bugs as needed).
- Applicable Q01-Q21 owner routes and evidence remain correct; a missing control is a named gap.
- Commit message names: branch chosen, gates run + result, SSOT files updated.

## 6. Prohibitions

- ❌ ...
- ❌ ...
- ❌ Skipping a §3 gate and calling skip a pass.
