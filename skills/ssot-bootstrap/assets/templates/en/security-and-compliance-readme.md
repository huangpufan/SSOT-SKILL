# Security and Compliance

<!-- Writing style: implementation-delegator. Begin with the risk or decision
     a reader can recognise, then the safe path, success/failure/recovery, and
     finally commands and evidence. Explain policy and security terms in
     ordinary language before using repository labels or acronyms. -->

<!-- Completeness authority: reader-quality.md C01-C09, PR01-PR16, and every
     applicable Q01-Q21 item routed here from STATUS. This process owner says
     how to assess and prove controls; product and architecture own the promise
     and enforcement truth. Never copy secrets or sensitive evidence here. -->

Use this page before a change affects identity, authorization, untrusted input,
sensitive data, tenant/workspace boundaries, dependencies, policy, consent,
licensing, audit, disclosure, or customer notification. First decide what may
be exposed and who is allowed to accept the risk. Then follow the assessment,
verification, and escalation path without treating a passed scanner as proof
that the whole boundary is safe.

## Why this assessment method

<!-- Explain why this repository classifies exposure before choosing a check,
     and why approval, negative cases, deployed-result verification, redaction,
     and escalation occur in this order. Name the policy or system constraints,
     invariants, accepted trade-offs, rejected shortcuts, and evidence that
     would justify changing the method. -->

## Recognise the decision and exposure

<!-- Start with a concrete misuse, data, dependency, or policy scenario. State
     the affected people, versions, platforms, environments, tenants/workspaces,
     data classes, compatibility window, and possible customer exposure. -->

| Scenario | Asset or obligation | Exposure boundary | Decision authority | Read first |
|---|---|---|---|---|
| | | | | |

## Follow the assessment and change path

<!-- Explain the ordinary safe path before a checklist: classify the change,
     identify trust and data boundaries, find current controls, choose fitting
     verification, obtain required approval, roll out safely, and retain only
     the evidence allowed by policy. Name paid, external, or irreversible steps. -->

1. Classify the affected identity, privilege, input, data, dependency, policy,
   tenant/workspace, and external recipient.
2. Trace the current product promise to its architecture enforcement point.
3. Choose checks that exercise the actual threat or obligation, including a
   negative or abuse case when applicable.
4. Obtain the named approval before an external, paid, privileged, destructive,
   disclosure, or customer-notification action.
5. Verify the deployed result, preserve redacted evidence, and route remaining
   exposure to a resolving owner.

## Define safe success, failure, and response

<!-- State the expected allowed and denied outcomes, audit signal, and retained
     evidence. Cover partial rollout, mixed versions, repeated/concurrent calls,
     compromised credentials or dependencies, data exposure, containment,
     rollback, disclosure, customer notification, and recheck duties when they
     apply. Do not claim zero risk. -->

| Outcome | Observable signal | Containment or recovery | Notification / disclosure duty | Owner |
|---|---|---|---|---|
| expected allowed use | | | | |
| expected rejection or prevention | | | | |
| suspected or confirmed exposure | | | | |

## Route quality, risk, and governance conditions

<!-- Start from STATUS Q01-Q21 and expand only applicable conditions. Security
     and compliance commonly own process/evidence for Q07-Q17 and Q20-Q21 and
     may constrain Q01-Q06, Q18, and Q19. Include privacy and data governance,
     harmful outcomes, human oversight and appeal, fairness and explanation,
     output validity, and commercial or entitlement integrity when applicable.
     Link the unique product promise, architecture enforcement, process evidence,
     and gap owner; do not create twenty-one fixed subsections. -->

| Q ID | Decision or obligation | Product / architecture owner | Process evidence | Gap owner |
|---|---|---|---|---|
| | | | | |

## Stable asset inventory

List the finite stable scripts, tools, suites, fixtures, targets, artifacts,
runbooks, controls, and other named things this process creates, reads, changes,
verifies, hands off, or retires. One-off scan output is evidence, not a stable
asset. Never put secret values or sensitive samples in this inventory.

If none exists, delete the sample row and write: `No stable assets: reason=<specific reason>; owner=[responsible owner](<resolving-path>); review when=<observable event>.`

| Asset | Class | Purpose | Selection rule | Owner | Evidence | Risk | Retirement or replacement trigger |
|---|---|---|---|---|---|---|---|
| | script / tool / suite / fixture / target / artifact / runbook / control / other | | | | | | |

## Verify without leaking sensitive material

<!-- Commands come after the decision path. Use redacted fixtures and least
     privilege. State environment, identity, setup, expected allowed/denied
     result, evidence destination, cleanup, and what must never enter Markdown,
     logs, shell history, screenshots, commits, or tickets. -->

```bash
# <run a safe static, dependency, policy, or configuration check>
# <exercise one authorized positive case and one denied/abuse case>
# <verify audit/detection evidence without printing secrets or personal data>
```

| Claim or control | Fitting evidence | Expected result | Freshness / invalidation | Evidence owner |
|---|---|---|---|---|
| | | | | |

## Escalation, boundaries, and freshness

<!-- Name the security, privacy, legal, compliance, licensing, or customer
     authority required for unresolved decisions. This page is not legal advice
     and does not grant permission. Recheck when threats, data classes, policy,
     jurisdictions, dependencies, trust boundaries, controls, versions, or
     notification duties change. -->
