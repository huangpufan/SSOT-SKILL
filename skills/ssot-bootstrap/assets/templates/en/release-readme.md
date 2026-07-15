# Release Process

<!-- Writing style: implementation-delegator. Start with the release decision
     and audience, then path, outcome/recovery, commands, and evidence. -->

<!-- Completeness authority: reader-quality.md C01-C09, PR01-PR16, and applicable
     Q01-Q21. Covered process owners use the exact strategy and finite-asset
     contract; give a reason/evidence pointer for every not_applicable item. -->

> This area records versioning, release, and delivery consistency. Only long-lived invariants, failure modes, and evidence pointers are recorded; the full content of CI, scripts, and changelog remains in the repository.

## When and for whom

<Explain who can request and approve a release, what trigger starts it, the
required branch/version/environment state, credentials, and irreversible or
paid permissions.>

## Why this release method

<Explain why versioning, build, verification, signing/publishing, delivery, and
announcement occur in this order. Name the conventions and invariants that
keep destinations consistent, the constraint or past failure behind them, the
accepted trade-off, the nearest rejected path, and evidence that would justify
changing the method.>

## Canonical path and branches

<Tell the ordered path from version decision through build, verification,
signing/publishing, deployment or delivery, and announcement. Explain manual,
CI, hotfix, prerelease, repeated/concurrent invocation, mixed-version,
partial-completion, and partial-failure branches. Route applicable Q07/Q11-Q21
compatibility, provenance, notification, policy, licensing, disclosure,
privacy, safety, human oversight, fairness, retirement, environmental impact,
output validity, and commercial-entitlement integrity.>

## Output and acceptance

<Name the observable artifacts and destinations, how versions remain
consistent, and the exact gate that means a release is accepted rather than
merely attempted.>

## Failure, recovery, and handoff

<Explain detection, stop points, safe retry, rollback/yank/rebuild options,
irreversible publication boundaries, and the owner/escalation path.>

## Reproduce and keep current

<Give canonical commands or workflow entrypoints, evidence owners, current
versus target posture, and the script/config/registry change that invalidates
this process.>

## Release at a Glance / Reader Map

| Reader question | First stop | Authoritative owner | Evidence direction | Stop condition / risk |
|---|---|---|---|---|
| How do I release or cut a version? | [Release path](#release-path) | this file | CI / release script / version file | |
| Which scripts maintain release invariants? | [Release scripts / tool inventory](#release-scripts--tool-inventory) | scripts directory | scripts directory / CI / signing config | |
| What consistency would a failure break? | [Release invariants and failure modes](#release-invariants-and-failure-modes) | this file | CI logs / past incidents / detection signals | |

## Release Path

Use a short narrative to describe how releases are triggered, the versioning strategy, the relationship between artifact / package / deployment, and who is responsible for final sign-off.

| Release path | Trigger | Artifact / target | Required setup | Evidence | Known risk |
|---|---|---|---|---|---|
| | tag / CI / manual / package publish | | | CI / release script / version file | |

## Release Scripts / Tool Inventory

> This is the finite inventory of stable release assets. Include every real
> version-sync, changelog, build, publish, signing, import-rewrite, delivery,
> or announcement tool once. If an asset affects architecture current/target/
> gap, link its unique owner rather than duplicating that fact.
> If none exists, delete the sample row and write: `No stable assets: reason=<specific reason>; owner=[responsible owner](<resolving-path>); review when=<observable event>.`

| Asset | Class | Purpose | Selection rule | Owner | Evidence | Risk | Retirement or replacement trigger |
|---|---|---|---|---|---|---|---|
| | script / tool / artifact / target / runbook / control / version-sync / changelog / publish / signing / import-rewrite / other | | | | | | |

## Release Invariants and Failure Modes

| Invariant | Why it matters | Failure mode | Detection | Evidence |
|---|---|---|---|---|
| | | | | |

## Current / Target / Gap

| Area | Current | Target | Gap / next verification | Evidence |
|---|---|---|---|---|
| | | | | |

## Open Gaps

| Gap / unknown | Required evidence | Blocking level |
|---|---|---|
| | | blocking / non-blocking |
