---
intent_recovery: gap
---
# Contracts and trust boundaries

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
     to the contract owner. -->

## Secrets, privacy, and redaction

<!-- Explain configuration sources, secret handling, sensitive payloads, logs,
     traces, exports, and external transmission. Name what must never be
     exposed and how an operator verifies redaction. -->

## Environment and external integrations

<!-- Cover development/production differences, proxy or origin boundaries,
     callback verification, provider credentials, and degraded operation when
     an external contract is unavailable. -->

## Current direction and gaps

| Boundary or contract | Current enforcement | Intended posture | Exposure or gap | Closure owner |
|---|---|---|---|---|
| | | | | |

## Evidence links

| Claim | Contract, policy, or domain owner | Configuration, test, or runtime evidence |
|---|---|---|
| | | |
