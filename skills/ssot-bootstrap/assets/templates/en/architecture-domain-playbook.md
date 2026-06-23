# <runtime owner> Playbook (maintenance / onboarding / verification)

> Architecture-domain operational playbook. Use when the domain owns ≥3 mechanical task branches (e.g. "add a new SDK adapter", "migrate a schema column"). The README owns contract truth; this file owns *procedure*. See sample: `SSOT/02-architecture/sdk-agent-runtime/playbook.md`.

## 0. Startup check (run every time)

- `$ssot-preflight` and confirm `documentation_language`.
- `git status -s` — record unrelated dirty paths you must NOT stage.
- Read [`README.md`](./README.md) "Owned State And Resources" + "Contract Surfaces" before acting; this playbook assumes you understand the contract.

## 1. Task branch A: <name the most common mechanical task>

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
- Commit message names: branch chosen, gates run + result, SSOT files updated.

## 6. Prohibitions

- ❌ ...
- ❌ ...
- ❌ Skipping a §3 gate and calling skip a pass.
