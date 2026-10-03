# Bundle review — 2026-10-03

Baseline: `439b800` (protocol 2.77), clean `main`. This review examines the six
skill entrypoints and their shared ownership, routing, evidence, template, and
lint contracts. Prior v2.65–v2.77 fixes are retained. It does not claim that a
finite scenario set proves general agent quality.

## Findings and dispositions

| Finding | Failure mechanism | Disposition |
|---|---|---|
| Mermaid generation | HTML comments inside fences are accepted by local checks but rejected by Mermaid. | v2.78 changes templates and lint together and adds real-parser CI coverage. |
| Vocabulary explanation | One-sentence/15-word restrictions conflict with locally understandable prose; style, area, and Doctor files duplicate policy. | v2.79 centralises the rule and preserves contextual explanation while rejecting definition forks. |
| Coverage structure | STATUS forbids architecture scope rows while later permitting them, describes only faceted covered layouts, and rejects some required stop claims. | v2.80 reconciles scoped roll-up, reviewed single-level layouts, and stop-claim enums across protocol, templates, and lint. |
| Record retirement | Deprecated/retracted records are told to invent successors; the successor lint accepts blank keys and unverified prose. | v2.81 separates retirement from replacement and checks resolving successor routes across the five record collections. |
| Decision scope | The owner admits only hard-to-reverse or cross-domain decisions, and the English index calls the collection architecture-only; general routing also sends lasting trade-offs there. | Reconcile selection with the durable rationale the next reader needs, while excluding routine edits. |

## Evidence boundaries

The baseline suites passed bundle shape (51), document contracts (189),
document-quality lint (263), and Doctor (211). The baseline Mermaid trial used Mermaid 11.12.0 in Node 24:
the shipped HTML marker failed diagram-type detection; the same graph with a
native comment parsed. The new parser test uses a DOM implementation for label
sanitisation, reads template fences unchanged, and rejects invalid marker and
grammar controls. Parsing proves syntax, not visual layout or semantic truth.

Independent baseline/candidate trials use the same six bounded closeout
scenarios: contextual term explanation, contradictory redefinition, scoped
architecture progress, reviewed single-level layout, retirement without a
replacement, and supersession without a successor. They do not advance consumer
coverage or stand in for an end-to-end bootstrap.

## v2.78 verification

On Linux, `node tests/test-mermaid-templates.mjs <isolated-node_modules>` parsed
all 16 shipped fences and rejected both invalid controls. The candidate passed
`tests/test-bundle-shape.sh` (51), `tests/test-document-quality-contract.sh`
(189), `tests/test-document-quality-lint.sh` (263), Doctor `run-tests.sh`
(211), and `tests/test-installer-e2e.sh` (92). `bash -n`, `git diff --check`,
and ShellCheck with CI's `-S warning -e SC2034` policy passed. Browser layout
and remote CI execution are not established by these local checks.

## v2.79 verification

Two independent agents read frozen baseline/candidate protocols, starting at
closeout. In both trials the glossary uniquely defined an attempt as one
execution of the same task. The proposed runtime text was: “Each retry creates
another attempt of the same task. The recovery screen groups these attempts so
the operator can inspect why the previous execution stopped.” It included the
definition link and introduced no state enum. Baseline required combining the
sentences because of `area-model.md`; candidate retained both. Both rejected a
control that redefined an attempt as a new independent task and invented states.

These are bounded editing decisions under supplied facts, not full consumer
closeout runs or proof of better prose on unseen tasks. The baseline read 12
files for six scenarios; the candidate read six for two, so those counts do not
establish a reading-cost improvement. Shape (51), document contracts (189),
installer regression (92), and `git diff --check` passed for v2.79. Existing
glossary families, domain ownership, and reader review gates remain in force.

## v2.80 verification

The initial real-CLI boundary suite reproduced six failing test methods: valid
scope names were rejected, scoped rows looked for an invented child-directory
owner or skipped owner checks, and non-applicable scopes were not aggregated
correctly. The final suite has 11 passing methods, including subcases for all
17 area names, exact scoped reviews, missing owners, parent coverage/depth,
conditional applicability, invalid scope names, and every documented stop-claim
token. It also confirms that lint leaves input Markdown unchanged. The fixture
intentionally omits unrelated full-reader evidence; these assertions establish
specific lint boundaries, not overall consumer convergence.

An independent agent read the frozen candidate for scoped architecture progress
and a reviewed single-level layout. It accepted both and rejected a parent
claiming covered while a child remained gap. It also caught a candidate defect:
the exact Stop Review Gate enum rejected the `partial` token required by the
scoped-row rule. The final fix aligns the reference table, bilingual templates,
and parser; the CLI suite now checks that token and other previously omitted
documented claims. The independent trial itself remains a record of that
pre-correction candidate, not evidence that the agent retested the final tree.

Final local checks passed shape (51), document contracts (189), document-quality
lint (263), Doctor (211), the boundary suite (11), Bash syntax, and configured
ShellCheck. The final reference-table enumeration was also checked against the
template and parser tokens. None of these checks claims a complete bootstrap or
that single-level documentation is appropriate for every repository.

## v2.81 verification

Five new real-CLI test methods produced nine failed assertions/subcases against
the preceding lint: blank/missing/self/invalid-anchor routes, withdrawal flags,
and unlinked claims were accepted; capitalised valid body links, lifecycle-field
precedence, and nested records were mishandled. The final boundary suite passed
all 16 methods, including valid scalar/Markdown/anchored/wrapped/localised links,
all five nested collections, and retirement/rejection without a successor.
Every invocation checks that the input Markdown is unchanged. These fixtures
establish file-level diagnostics, not semantic replacement truth or validation
of aggregated record bodies.

Local checks also passed shape (51), document contracts (189), document-quality
lint (263), Doctor (211), installer regression (92), layout migration (49),
STATUS migration (16), Bash syntax, configured ShellCheck, and the unchanged
Mermaid parser suite (16 fences plus two rejected controls). The document-quality
successor fixture now creates the successor it claims, rather than treating a
missing target as a passing example.

The independent closeout trial accepted the authorised deprecated decision
without a successor and rejected superseded-without-successor. It also found
two candidate glossary defects: index templates still unconditionally asked
for a replacement, and the English entry template could turn incomplete
deprecation into completed retirement. Those findings remain part of the
trial. A targeted reread of the final G06 and both languages' index/entry
templates found no remaining conflict for either retired-without-replacement
or deprecated-with-compatibility-use. No consumer state was advanced and no
retirement authorisation was requested again. This supports these bounded
editing choices, not general lifecycle correctness on unseen repositories.
The trial and directed follow-up read 15 snapshot files, used 27 execution/time
calls, and took about ten minutes including writing; the extended scenario set
does not support a speed comparison with baseline.
