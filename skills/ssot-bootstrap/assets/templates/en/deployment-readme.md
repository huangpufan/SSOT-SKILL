# Deployment

<!-- Writing style: implementation-delegator. Explain the concrete rollout
     decision and observable outcome before commands or inventories. -->

<!-- Completeness authority: reader-quality.md C01-C09, PR01-PR16, and applicable Q01-Q21. -->

Use this page when a built version must enter an environment that another
person or system depends on. Before running anything, decide the target
environment, exact artifact or revision, expected visible result, rollback
owner, and the signal that will stop the rollout. The safe action is to follow
one canonical path, verify the result where it is consumed, and either complete
the handoff or recover to a known state.

A typical scene is a service update: an operator confirms the target and
permissions, deploys one pinned image, checks readiness and a representative
user path, then records the observed version. If readiness or the user path
fails, the operator stops expansion and follows the documented rollback or
recovery branch.

## Why this method and these constraints

<!-- Explain why this repository uses this rollout shape instead of the nearest
     plausible alternative. Name the conventions and invariants that keep it
     coherent, the constraint behind each major step, the accepted trade-off,
     and the evidence that would justify changing the method. Do not turn this
     into another command list. -->

## Before deployment starts

The deployer and approver must know what is changing, why now, who may change
the target, and which environment and data are in scope. Required inputs include
the pinned artifact, configuration source, secrets access, migration posture,
current health, and a recovery destination. Missing authority, an unpinned
artifact, or an unknown rollback path is a stop condition.

<!-- Describe actual roles, permissions, environment prerequisites, inputs,
     maintenance windows, cost approval, and data safeguards here. -->

## Canonical path

1. Confirm the target, artifact identity, current state, owner, and change
   window.
2. Check prerequisites and produce any backup, snapshot, drain, or approval
   required before mutation.
3. Apply the repository's deployment command or workflow to the smallest safe
   scope.
4. Observe rollout progress and stop on the named health, migration, capacity,
   or user-path failure signal.
5. Verify the deployed version, readiness, representative behaviour, and any
   state transition at the real destination.
6. Expand, complete the handoff, or execute rollback/recovery. Record only the
   durable resulting state in its owner; raw run output stays with the run or
   delivery artifact.

<!-- Replace the generic sequence with the repository's actual ordered path.
     Preserve the decision, stop, verification, and recovery semantics. -->

## Branches and exceptions

<!-- Cover repeated/concurrent invocation and partial completion (PR14), plus
     applicable Q04-Q21 capacity, continuity, migration, restore, isolation,
     threat, supply-chain, notification, policy, privacy, harm prevention,
     human oversight, fairness, retirement, environmental impact, output
     validity, and commercial-entitlement branches. Link the unique product and
     architecture owner plus process evidence; do not duplicate Q rows. -->

Different environments, deployment units, migrations, feature flags, canaries,
or manual approvals may branch from the canonical path. Explain what selects a
branch and where it rejoins. An emergency path must still pin the artifact,
name the approver, preserve evidence, and define recovery; “hotfix” is not
permission to skip those boundaries.

| Branch | Selection condition | Extra prerequisite | Rejoin or completion point |
|---|---|---|---|
| | | | |

## Side effects and irreversible boundaries

Deployment may replace running processes, mutate infrastructure, migrate data,
invalidate caches, rotate credentials, notify external systems, consume paid
capacity, or interrupt users. State which effects are reversible, which require
a backup or compensating action, and which cannot be undone after expansion.
Stop before an irreversible step if its owner, backup, or acceptance signal is
missing.

## Observable result and acceptance

A successful command is only an attempt. Acceptance means the intended
artifact is present at the intended target, health/readiness is meaningful,
the representative user or operator path works, and state or migration checks
match the expected posture. Name the exact observation and who accepts it.

| Result to observe | Where to observe it | Acceptance rule | Evidence owner |
|---|---|---|---|
| | | | |

## Failure detection and stop conditions

Describe the earliest trustworthy signals for failed rollout, unhealthy
instances, schema incompatibility, partial expansion, data corruption,
capacity exhaustion, or silent version mismatch. State which signal pauses the
rollout, which forces rollback, and which requires escalation rather than
repeated retries.

## Retry, rollback, and recovery

Retry only after identifying whether the failed step is idempotent and whether
partial side effects remain. Rollback restores the previous deployable state;
recovery may instead require forward repair, data restore, traffic isolation,
or a new artifact. Explain how to verify recovery and how to avoid overwriting
the evidence needed for diagnosis.

## Escalation and handoff

Name the deployment owner, environment or infrastructure owner, data owner,
security approver, and product or release recipient when applicable. The
handoff includes target, artifact identity, observed state, unresolved risk,
and the next decision—not just a link to logs.

## Reproducible commands

Commands are exact entry points, not the explanation of the process. Include
the required working directory, environment, safe preview or dry-run when
available, deployment action, observation command, and rollback/recovery
entrypoint.

```bash
# <preview or plan>
# <deploy the pinned artifact>
# <observe and verify>
# <rollback or recover>
```

## Stable asset inventory

This is the finite list of stable things this deployment process creates,
reads, changes, verifies, hands off, or retires. “Asset” means a reusable
script, tool, target, artifact, runbook, control, or other named process input
or output—not a run transcript. List each real asset once; if a class truly has
none, state the reason rather than inventing one.

If no stable asset exists at all, delete the sample row and write: `No stable assets: reason=<specific reason>; owner=[responsible owner](<resolving-path>); review when=<observable event>.`

| Asset | Class | Purpose | Selection rule | Owner | Evidence | Risk | Retirement or replacement trigger |
|---|---|---|---|---|---|---|---|
| | script / tool / target / artifact / runbook / control / other | | | | | | |

## Current or intended state and freshness

State which targets and branches are current, limited, intended-only, or not
applicable, and name any known gap with its owner. Recheck this page when
deployment workflows, infrastructure definitions, environment topology,
configuration/secrets, migration behaviour, health signals, artifact format,
or rollback ownership changes.

## Boundaries

Build and coding steps belong in [development](../development/README.md),
correctness gates in [testing](../testing/README.md), measured floors in
[benchmark](../benchmark/README.md), and version publication in
[release](../release/README.md). Runtime topology and state ownership belong in
[architecture](../../02-architecture/README.md); this page links those facts
and owns the deployment procedure.
