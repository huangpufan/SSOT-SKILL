# SSOT Status

> KISS register rule: this file is a state register, not the narrative owner.
> Cells carry state, owner, date, result, and evidence pointers. Move paragraph
> reasoning, command output, checklists, and review transcripts to the
> authoritative owner or evidence artifact.

## Event-Source Coverage

| Field | Value |
|---|---|
| tracked_commit | `<commit-sha>` |
| tracked_session | `<ISO-timestamp-or-session-id>` |
| tracked_skill_version | `<ssot-preflight-protocol-version>` |
| documentation_language | `<locked-natural-language-or-BCP47-tag>` |
| documentation_language_evidence | `<source-path-or-user-decision>` |
| coverage_result | `bootstrap` / `catching_up` / `in_progress` / `converged` |
| last_stop_review | `<review-pointer>` |

## Area Status

| Area | Status | Notes |
|---|---|---|
| product | | |
| architecture | | |
| glossary | | |
| development | | |
| testing | | |
| deployment | | |
| release | | |
| decisions | | |
| research records | | `04-records/research/` |
| gotchas | | |
| bugs | | |
| tech-debt | | |

> Status values and covered preconditions: see
> `$ssot-preflight references/status-protocol.md`. Notes are one short pointer,
> not a child-state ledger.

## Source Material Absorption

| Source material | Path/source | Lifecycle | Classification | Authority | Owner / absorbed_to | Do not use for | Review |
|---|---|---|---|---|---|---|---|
| | path or `pattern=docs/*` | working/research / working/draft / working/proposal / working/experiment / working/poc / working/prototype / working/execution-log / working/closure / working/report / working/handoff / historical/superseded / historical/deprecated / external/source-material / public/thin-entry | absorb / link-only / stale/conflict / obsolete | current / downgraded / external / historical | owner=SSOT/...; absorbed_to=SSOT/... | do_not_use_for=... | review_on=YYYY-MM-DD; status=pending / absorbed / linked / conflict-recorded / obsolete; conflict=none |

## Source Inventory Exclusions

| pattern | reason | owner | last_checked | review_trigger |
|---|---|---|---|---|
| | | | YYYY-MM-DD | |

## Core Reference Document Review

| Document | Role | Relation | Status | Evidence/action |
|---|---|---|---|---|
| AGENTS.md / CLAUDE.md / Cursor rules | startup / agent-rules / reference / none | thin-adapter / source-material / mixed | covered / stale / conflict / missing / not_applicable | |

> Add an appendix only when a startup/reference file needs wider fields such as
> check scope, last check, detailed action, or conflict links.

## Stop Review Gate

| scope | stop_claim | reviewer | reviewed_at | result | evidence | remaining_changes |
|---|---|---|---|---|---|---|
| | converged / covered / no-op / tracked_commit / tracked_session / tracked_skill_version / protocol-upgrade / documentation_language | | | no-more-required-changes / needs-fix | | |

## Open Adjudications

| id | status | scope | question | next trigger |
|---|---|---|---|---|
| | pending / deferred / resolved / superseded | | | |

## Pending Captures

| id | captured_at | about | altitude_guess | rule | evidence | signal_source | status |
|---|---|---|---|---|---|---|---|
| CAP-YYYYMMDD-NN | | agent-method / product | apex / authority / inbox | | | user-directive / repo-signal / transcript / tier4-rollup | open / routed / deferred / deferred-export / expired |

## Open Gaps

| Area | Status | Gap description | Blocking level |
|---|---|---|---|
| | gap / unknown | | |

## Optional Appendices

Create appendix sections only when needed:

- `## Appendix: core-reference details` for wide startup-file review fields.
- `## Appendix: adjudication details` for source, needed_by, resolution, and links.
- `## Appendix: stop-review evidence` for pointers to detailed review artifacts.
