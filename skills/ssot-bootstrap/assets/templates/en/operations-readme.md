# Operations

<!-- Writing style: implementation-delegator. Start with an operator's
     situation and decision, then give the concrete path, visible success,
     failure and recovery, and only then commands and evidence. Explain every
     unavoidable repository term in ordinary language before using its label. -->

<!-- Completeness authority: reader-quality.md C01-C09, PR01-PR16, and every
     applicable Q01-Q21 item routed here from STATUS. This page owns repeatable
     operation; architecture owns runtime truth and records own incidents. -->

Use this page when a running environment needs attention: checking health,
handling a background job, changing capacity, restoring service, or deciding
whether an operator may proceed. Begin with the symptom and the decision it
requires. Follow the smallest safe branch below, verify the result from the
outside, and stop at the named boundary when authority or evidence is missing.

## Why this operating method

<!-- Explain why operators use this order and why the smallest authorized
     action comes before broader mitigation. Name the conventions, invariants,
     constraints, and trade-offs behind observation, mutation, independent
     verification, recovery, and escalation. Name the nearest viable alternative
     and the concrete reason it is rejected or deferred. State what evidence
     would justify changing the method. -->

## Decide what is happening

<!-- Describe ordinary operating situations in words a non-author can
     recognise. For each, state who may act, what must remain true, and which
     architecture or product owner explains the underlying promise. -->

| Situation and visible signal | Decision | Read first | Authority | Stop condition |
|---|---|---|---|---|
| | observe / mitigate / recover / escalate | | | |

## Follow the current operating path

<!-- Explain the safe sequence in connected prose before presenting a compact
     checklist. Name prerequisites, environment and tenant/workspace scope,
     configuration source, durable side effects, dependencies, and the point
     after which reversal is not automatic. -->

1. Confirm the environment, affected scope, operator identity, and current
   symptom from a trusted signal.
2. Check the linked runtime owner and active incident, maintenance, or release
   context before changing state.
3. Apply the smallest authorized action and retain its correlation or evidence
   pointer.
4. Verify the user-visible result and the system signal independently.
5. Recover, roll back, or escalate when the acceptance condition is not met.

## Know success, failure, and recovery

<!-- Teach the full outcome. Cover partial completion, repeated or concurrent
     actions, timeout, duplicate delivery, stale reads, degraded mode, and lost
     operator connection when applicable. Say what remains safe, what may be
     retried, what requires rollback/repair, and who owns the next decision. -->

| Outcome | What people or operators observe | Safe state | Next action | Owner |
|---|---|---|---|---|
| success | | | | |
| partial or uncertain | | | | |
| failed or degraded | | | | |

## Route quality, risk, and governance conditions

<!-- Start from STATUS Q01-Q21. Discuss only applicable conditions, but do not
     silently omit one: each is either handled here, linked to its unique
     product, architecture, or process owner, or exposed through a named gap.
     Operations commonly owns evidence for Q04-Q12 and Q18, plus the operating
     consequences of applicable Q14-Q17 and Q19-Q21: privacy handling, harmful
     outcomes, human intervention, fairness signals, retirement, environmental
     impact, output drift, and billing or entitlement failures. Applicability
     remains repository specific. Do not create twenty-one fixed subsections. -->

| Q ID | Operating decision or signal | Unique fact owner | Evidence or gap owner |
|---|---|---|---|
| | | | |

## Stable asset inventory

List the finite stable scripts, tools, suites, targets, artifacts, runbooks,
controls, or other named things this process creates, reads, changes, verifies,
hands off, or retires. Keep one row per real asset; raw incident/run output is
evidence, not a stable asset.

If none exists, delete the sample row and write: `No stable assets: reason=<specific reason>; owner=[responsible owner](<resolving-path>); review when=<observable event>.`

| Asset | Class | Purpose | Selection rule | Owner | Evidence | Risk | Retirement or replacement trigger |
|---|---|---|---|---|---|---|---|
| | script / tool / suite / target / artifact / runbook / control / other | | | | | | |

## Run and verify

<!-- Put commands only after the reader understands the decision and risk.
     Provide copyable commands with explicit working directory, prerequisites,
     safe parameters, expected output, side effects, timeout, and redaction.
     Never put a live secret on a command line. -->

```bash
# <observe without changing state>
# <perform the smallest authorized action>
# <verify the visible and system result>
# <recover or roll back>
```

| Check | Expected observable result | Evidence owner | Freshness / invalidation |
|---|---|---|---|
| | | | |

## Escalation, boundaries, and freshness

<!-- Name actions this runbook does not authorize, the team or owner that can
     decide them, and the evidence to carry into escalation. Recheck this page
     when runtime topology, permissions, dependencies, signals, SLOs, quotas,
     recovery steps, or user-visible operating promises change. -->
