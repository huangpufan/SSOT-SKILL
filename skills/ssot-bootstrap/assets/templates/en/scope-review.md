---
review_id: scope-review:<process|records|glossary|root|status>:YYYYMMDD:<slug>
review_scope: <process|records|glossary|root|status>
completeness_profile: <same-scope-token>
protocol_version: "<tracked-skill-version>"
reviewed_on: YYYY-MM-DD
reviewer: <stable-human-or-agent-id>
reviewer_role: <scoped-self-review|independent-reviewer>
repository_commit: <resolvable-full-or-short-commit>
entrypoint: <canonical-scope-entrypoint>
scope_fingerprint: <lowercase-sha256>
area_disposition_fingerprint: <lowercase-sha256>
quality_disposition_fingerprint: <lowercase-sha256>
profile_item_count: <46|46|38|37|32>
covered_item_count: <integer>
not_applicable_item_count: <integer>
unresolved_required_changes: <integer>
authorises: <area:process:covered|area:records:covered|area:glossary:covered|scope:root:covered|scope:status:covered|coverage_result:converged>
verdict: <needs-fix|no-more-required-changes>
---

# Exact-scope review: <scope>

<!-- Use this lightweight artifact for process, records, glossary, root, or
     STATUS only. Product and architecture use reader-review.md. Do not copy
     the sixteen-leaf score here. Remove every author comment before linking a
     passing artifact from STATUS. -->

## Review basis

State what was frozen, who reviewed it, which current claim this artifact
authorises, and the evidence limit. When the review is area-scoped, the matching
Area Status and Stop Review Gate rows must resolve to this same file; root and
STATUS use their Stop Review Gate rows.

| Check | Result | Evidence / limit |
|---|---|---|
| Scope identity and current fingerprint | pass / needs-fix | <evidence-and-limit> |
| Owner and route resolution | pass / needs-fix | <evidence-and-limit> |
| STATUS claim and artifact agreement | pass / needs-fix | <evidence-and-limit> |

Sample semantic truth as well as routes. Include at least one row from every
profile family (for example C, PR, and Q for process). If the exact profile uses
both `covered` and `not_applicable`, sample at least one item of each
disposition. A passing artifact records only `pass` truth results.

| Item ID | Owner/body claim | Repository/evidence sample | Truth result | Limit |
|---|---|---|---|---|
| <sampled-profile-id> | <specific claim checked in the linked owner body> | [repository or evidence sample](<resolving-path>) | pass / needs-fix | <what this sample does not prove> |

List every real reader target in this scope exactly once. Put all profile IDs
actually checked against that target in one comma-separated cell. Across the
table, those IDs must cover the whole exact profile.

| Target ID | Target owner | Profile IDs exercised | Repository/evidence sample | Truth result | Limit |
|---|---|---|---|---|---|
| <stable-target-id> | <plain owner name> | <comma-separated exact-profile IDs> | [exact target owner](<resolving-path-or-anchor>) | pass / needs-fix | <what this target check does not prove> |

## Exact profile

<!-- Use exactly one profile: process=C01-C09+PR01-PR16+Q01-Q21 (46),
     records=C01-C09+R01-R16+Q01-Q21 (46),
     glossary=C01-C09+G01-G08+Q01-Q21 (38),
     root=C01-C09+RT01-RT07+Q01-Q21 (37), or
     status=S01-S11+Q01-Q21 (32). Each owner/evidence cell contains exactly one
     resolving Markdown link. Plain answer states the current conclusion in
     ordinary language; it cannot repeat the profile question or protocol ID. -->

| Item ID | Disposition | Plain answer | Owner / evidence |
|---|---|---|---|
| <exact-profile-id> | covered / not_applicable: <named reason> | <specific current conclusion in ordinary language> | [owner or evidence](<resolving-path>) |

## Required changes and verdict

| Change ID | Status | Required change | Owner | Closure evidence |
|---|---|---|---|---|
| none | none | No required change remains after this review. | — | The unresolved count is zero and the final verdict is no-more-required-changes. |

Final verdict: `<needs-fix|no-more-required-changes>`.
