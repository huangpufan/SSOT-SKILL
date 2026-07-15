# How Work Gets Done

<!-- Writing style: implementation-delegator. Lead with the decision and next
     action in ordinary language; define repository terms on first use. -->

<!-- Completeness authority: reader-quality.md C01-C09, PR01-PR16, and every
     applicable Q01-Q21 process/evidence route from STATUS. This
     root is a bounded router; child pages own commands, gates, and recovery. -->

Use this page after deciding that the repository must change and before choosing
a command or workflow. First decide what kind of outcome you need: make a code
change, prove correctness, compare measured behaviour, operate a running
environment, assess security or compliance, deploy an artifact, or publish a
release. Then open the one child page that owns that work and follow its current
path.

For example, a change to an API normally starts in
[development](./development/README.md), moves to
[testing](./testing/README.md), and reaches
[deployment](./deployment/README.md) only when an environment must change.
This root explains that route; it does not copy the commands or acceptance
rules from those owners.

## Choose the next owner

- Open [development](./development/README.md) when you need to set up the
  repository, change code, or follow its engineering conventions.
- Open [testing](./testing/README.md) when you must decide which correctness
  checks fit a change and what blocks acceptance.
- Open [benchmark](./benchmark/README.md) when the decision depends on measured
  latency, throughput, capacity, cost, or another comparable workload.
- Open [deployment](./deployment/README.md) when an artifact must enter an
  environment and you need rollout, verification, rollback, or operator steps.
- Open [release](./release/README.md) when a version, package, tag, changelog, or
  public delivery must be produced and kept consistent.
- For live-operation or security/compliance work, first read the matching row in
  [Area Status](../STATUS.md#area-status). These are conditional owners: follow
  the row's owner when it exists, or its reasoned boundary when the lifecycle
  genuinely does not apply. A missing directory is a gap, not proof that the
  work is irrelevant.

<!-- If operations/ or security-and-compliance/ is created, replace the
     conditional STATUS route above and the matching table row below with one
     direct owner link. Remove this comment before marking the page covered. -->

If one task crosses several owners, keep the order explicit. Do not infer that
a green test means a deployment happened, that a benchmark proves correctness,
or that a deployment automatically creates a release.

## Route map

The table is a quick index after the route above is understood. Each linked
page remains the only owner of its detailed facts.

| Reader decision | First stop | Continue when |
|---|---|---|
| How do I make this change safely? | [development](./development/README.md) | The change is ready for its required checks. |
| What proves the change is correct? | [testing](./testing/README.md) | A stable performance or cost comparison is also needed. |
| What measured result can be compared? | [benchmark](./benchmark/README.md) | The result changes a decision, gate, or known gap. |
| How does this version reach an environment? | [deployment](./deployment/README.md) | The deployed result is verified or rolled back. |
| How is a version published and announced? | [release](./release/README.md) | The release artifacts and destinations agree. |
| How is a running environment observed, mitigated, and restored? | [Area Status operations row](../STATUS.md#area-status) | Follow the conditional owner or its reasoned boundary. |
| What security, privacy, or compliance proof is required? | [Area Status security row](../STATUS.md#area-status) | Follow the conditional owner or its reasoned boundary. |

Use the [STATUS quality, risk, and governance register](../STATUS.md#quality-risk-and-governance)
when a task touches Q01-Q21. It points to the unique product promise,
architecture enforcement, process/evidence owner, and any unresolved gap; this
router does not repeat those facts.

## Boundaries and handoff

This directory owns repeatable engineering procedures. Product promises belong
in [product](../01-product/README.md), runtime design belongs in
[architecture](../02-architecture/README.md), and incident knowledge or
open tracked work belongs in [records](../04-records/README.md). A child
process may link those owners, but it must not redefine their facts.

When a route is missing or contradictory, stop before the irreversible step.
Record the uncertainty with an owner and evidence direction, then hand it to
the child process whose output or recovery decision is blocked.

## Freshness

Recheck this map when a process directory is added, removed, renamed, or given
a new responsibility. Recheck the child page—not this root—when commands,
permissions, environments, gates, rollback, acceptance rules, or a Q01-Q21
owner route changes.
