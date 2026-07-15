---
intent_recovery: gap
---
# Contracts and trust boundaries

<!-- Writing style: implementation-delegator. Start with who is trying to do
     what, then the allow/deny result, failure/recovery, and enforcement proof. -->

<!-- Explain who calls the system, which boundaries change the level of trust,
     and what compatibility promise each caller relies on. Start from one real
     request crossing those boundaries. -->

## A request crossing trust boundaries

<!-- Follow authentication or identity, authorisation, validation, internal
     handoff, external integration, and response shaping. Explain where secrets
     and sensitive data appear and where they must be redacted. -->

```mermaid
<!-- diagram_type: component -->
flowchart LR
  caller["External caller"] --> edge["Authenticated boundary"]
  edge --> service["Authorised service"]
  service --> internal["Internal owner"]
  service --> provider["External provider"]
  internal --> audit[("Audit evidence")]
```

## Contract landscape

| Contract | Callers and consumers | Compatibility promise | Trust level | Owning domain | Verification |
|---|---|---|---|---|---|
| | | | public / authenticated / internal / privileged | | |

## Identity, authentication, and permissions

<!-- Explain identity sources, workspace or tenant isolation, role or ownership
     checks, service identities, and the user-visible result of denied access.
     Distinguish present enforcement from intended policy. -->

## Validation and compatibility

<!-- Describe versioning, schema evolution, idempotency, error shape, timeout,
     and backward-compatibility rules that cross owners. Link field-level detail
     to the contract owner. Cover deprecation, migration, mixed-version
     operation, and rollback for applicable Q07. -->

## Secrets, privacy, and redaction

<!-- Explain configuration sources, secret handling, sensitive payloads, logs,
     traces, exports, and external transmission. Name what must never be
     exposed and how an operator verifies redaction. Route applicable Q09-Q17
     threat/abuse, dependency, notification, policy, privacy, harm prevention,
     human authority/appeal, fairness, transparency, and explanation enforcement
     here. Also route Q20 validity/calibration contracts and Q21 price, charge,
     quota, plan, and entitlement boundaries when they cross an interface. -->

This trust view owns who may read or change sensitive configuration, where a
secret or protected value crosses a trust boundary, what must be redacted, and
how denied access appears. The [deployment and observability
view](./deployment-and-observability.md#configuration-secrets-and-environment-differences)
separately owns where configuration comes from in each environment, when the
running system loads it, how drift is detected, and what operational recovery
follows a bad value. Link the other view; do not maintain both stories here.

## Environment and external integrations

<!-- Cover development/production differences, proxy or origin boundaries,
     callback verification, provider credentials, and degraded operation when
     an external contract is unavailable. -->

## Current direction and gaps

| Boundary or contract | Current enforcement | Intended state | Exposure or gap | Completion owner |
|---|---|---|---|---|
| | | | | |

## Evidence links

| Claim | Contract, policy, or domain owner | Configuration, test, or runtime evidence |
|---|---|---|
| | | |
