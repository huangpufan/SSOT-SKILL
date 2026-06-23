# Recon Report

> Bootstrap temporary file. Phase 0 records observations for later phases. Clean
> it up with `.bootstrap/` after bootstrap completes and stop reviews pass.

## Documentation Language

| Field | Value |
|---|---|
| Detection result | `<documentation_language>` / `unknown` / `mixed` |
| Evidence | README / docs / ADR / runbook / subsystem README / user material |
| Ask user? | yes / no |
| STATUS fields | `documentation_language`, `documentation_language_evidence` |

> If evidence is mixed, insufficient, or absent, ask the user. Do not fall back
> to the current conversation language.

## Repository Shape

| Field | Value |
|---|---|
| Size tier | `S` / `M` / `L` / `XL` |
| Topology | monolith / monorepo-workspaces / monorepo-services / library/tooling / kernel or infrastructure |
| Entrypoints | |
| Workspaces/deployable units | |

## Observations

Record only what later phases need to route work. Each row should be an
observation, an evidence pointer, likely owner route, confidence/gap, and next
check.

| Observation | Evidence | Likely route | Confidence/gap | Next check |
|---|---|---|---|---|
| | | product / architecture / development / testing / release / deployment / decisions / gotchas / bugs / tech-debt / link-only | verified / documented / inferred / unknown | |

## Architecture Hypothesis

| Field | Value |
|---|---|
| Likely split axis | |
| Why | |
| Candidate owners | |
| Open risks/gaps | |
| Next architecture check | |

> This is not the formal `decomposition_basis`. Write the full signal matrix
> only in an appendix when it is needed.

## Product Hypothesis

| Field | Value |
|---|---|
| Product posture / PRD spine | |
| Users/operators | |
| Promise / boundary | |
| Capability or journey splits that may be stable | |
| Open product gaps | |

## Recommended Strategy

- **Area order adjustment**:
- **Architecture owners needing special attention**:
- **Areas that can be completed quickly**:
- **Estimated sessions**:
- **Other notes**:

## Optional Appendices

Create these only when the recon actually needs them:

- `## Appendix: architecture candidates` for candidate axes, signal matrix,
  predicted diagrams, stop/recursion challenge.
- `## Appendix: product candidates` for product-dimension matrix.
- `## Appendix: design-intent candidates` for technical mission, priorities,
  runtime journeys, migration stance, and rejected alternatives.
- `## Appendix: source inventory` for detailed source-material lifecycle,
  downgrade fields, audited exclusions, and classification.
- `## Appendix: readability/evidence candidates` for Reader Map, script/tool,
  diagram, or claim-to-evidence candidates.
