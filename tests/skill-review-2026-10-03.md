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
| Coverage structure | STATUS forbids architecture scope rows while later permitting them, and describes only faceted covered layouts. | Reconcile with scoped roll-up and reviewed single-level contracts. |
| Record retirement | Deprecated/retracted records are told to invent successors; the successor lint accepts blank keys and unverified prose. | Separate withdrawal from replacement and check real successor routes. |

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
