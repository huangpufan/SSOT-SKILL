# Release Process

> Writing style: any cold reader. See `ssot-bootstrap` §3.7.

> This area records versioning, release, and delivery consistency. Only long-lived invariants, failure modes, and evidence pointers are recorded; the full content of CI, scripts, and changelog remains in the repository.

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

> If there are tools for version sync, changelog generation, publishing, artifact signing, or import rewriting, record them here. If a script affects architecture current/target/gap, link to the corresponding architecture domain or decision.

| Filename | Purpose | Category | Release invariant | Evidence | Failure mode | Architecture link if any |
|---|---|---|---|---|---|---|
| | | version-sync / changelog / publish / signing / import-rewrite / other | | | | |

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
