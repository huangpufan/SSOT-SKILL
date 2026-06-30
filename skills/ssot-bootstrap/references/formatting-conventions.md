# SSOT document naming and formatting conventions

This file is the single source of truth for SSOT file naming, ordering, and
formatting. It is referenced from `bootstrap.md` §3.8 and enforced (the
mechanically-decidable portion) by `ssot-lint.sh` checks 13–16 and Doctor L1
rows 15J–15M.

The goal: a cold reader landing on any SSOT directory can derive recommended
reading order from filenames, expect a uniform frontmatter shape across
sibling files, and read every H1 in the project's locked documentation
language without dialect drift.

## Table of contents

- [§1 Naming conventions](#1-naming-conventions)
- [§2 Frontmatter conventions](#2-frontmatter-conventions)
- [§3 H1 language conventions](#3-h1-language-conventions)
- [§4 Validation rules](#4-validation-rules)

---

## 1. Naming conventions

All SSOT files use kebab-case (lowercase, hyphen-separated). `README.md` is
the per-directory index file and the only PascalCase exception. `_manifest.md`
is the per-area machinery container introduced in v2.48; both names skip the
numbered-prefix rule below.

Three filename shapes are recognised. Pick the shape from what the directory
**is**, not from how many files it currently holds.

**Ledger directories** — `bugs/`, `decisions/`, `04-records/research/`,
`tech-debt/`. Each entry uses a 4-digit zero-padded creation-order prefix:
`NNNN-slug.md` (e.g. `0001-unified-web-single-writer.md`). The number
records the order entries were created and never changes after a
renumber-blocking event.

**Ordered content directories** — directories whose sibling documents have a
recommended reading order from the cold reader's perspective. Each file uses
a 2-digit zero-padded reading-order prefix: `NN-slug.md`. When the directory
itself is one of several ordered domain directories, the directory name also
takes the prefix (`NN-domain-name/`). The default ordered directories are:

- `product/capabilities/` — capabilities ordered from user-observable surface
  toward background ability.
- `product/journeys/` — journeys ordered from primary user flow toward
  emergent or recovery paths.
- `architecture/<domain>/` directories — domains ordered from runtime
  foundation toward integration / SDK / terminal layers.

The reading-order number does **not** guarantee creation-time order. When a
new sibling document genuinely belongs between existing files, renumber
adjacent siblings rather than appending out-of-order. Continuous numbering
is the contract; gaps are allowed only when explicitly marked in the
directory `README.md` (e.g. a retired capability whose slot is held for
historical reference).

**Unordered content directories** — directories whose sibling documents have
no inherent reading order. Filenames use plain kebab-case with no numbered
prefix: `slug.md`. By default this applies to `architecture/views/`,
`gotchas/`, `testing/`, `development/`, `deployment/`, `release/`, and
`glossary/`. New unordered directories follow the same convention.

A directory does not switch between ordered and unordered casually. The
choice is recorded in the directory `README.md` opening paragraph; doctor
L2 reviews questionable cases.

## 2. Frontmatter conventions

The first three lines of every body file (excluding `_manifest.md`,
`STATUS.md`, and `CHANGELOG.md`) carry a YAML frontmatter block delimited by
`---`. This is the mechanical contract; Doctor still owns semantic checks on
field values.

**Same-directory frontmatter uniformity.** Sibling files in the same
directory under `product/` or `architecture/` must declare the same YAML
key set. If one capability file declares `intent_recovery: covered`, every
sibling capability file declares the same key. The parent `README.md`'s
frontmatter schema must match the child schema; the README is itself a
sibling for this rule. Doctor `15J` (check 13 in lint) detects mismatched
key sets in this scope.

Ledger directories (`bugs/`, `decisions/`, `04-records/research/`,
`tech-debt/`) are deliberately excluded from the uniformity check because
their per-entry frontmatter varies with lifecycle state (`closure_condition`
and `revisit_signal` only on pending/partial decisions per v2.43
ADR-CLOSURE; `superseded_by` only on superseded entries; research entries add
packet fields such as `promotion_targets` and `recheck_trigger`). The ledger
frontmatter contract is owned by Doctor rows 21, 15B, 15C, and the v2.54
`[RESEARCH-RECORD]` check, not by `15J`.

**`intent_recovery` propagation.** Every prose file under `product/` and
`architecture/` carries `intent_recovery: covered | partial | gap` in
frontmatter unless `STATUS.md` lists the file in an audited uncovered scope.
This applies to the root `product/README.md`, `product/prd.md`,
`product/product-model.md`, `product/roadmap-and-acceptance.md`, every
`product/capabilities/*.md`, every `product/journeys/*.md`,
`architecture/README.md`, every `architecture/<domain>/README.md`, every
`architecture/<domain>/playbook.md`, and every `architecture/views/*.md`.
The frontmatter value is the lifecycle flag only; long
`intent_recovery_evidence:` strings live in `_manifest.md` per v2.48
`[META-LEAKAGE]` (15I). Doctor `15M` (check 16 in lint) detects missing
`intent_recovery:` on in-scope files.

**Resolved-state preservation.** Once a directory's frontmatter schema is
established, resolved-state entries (e.g. a fixed bug or a closed debt item)
do not drop frontmatter fields. They flip the lifecycle flag (`status:
resolved`, `intent_recovery: covered`) so siblings keep the same shape.
Sibling-schema uniformity is a structural contract, not a per-entry
opt-out.

## 3. H1 language conventions

The `documentation_language` value in `STATUS.md` is the project's natural
language lock (typically `zh` or `en`). Every H1 in user-facing SSOT body
files must lead with that language. Code identifiers, file paths, shell
commands, API/route names, schema/enum literals, and verbatim third-party
product names stay in their original form regardless of the lock.

For a `documentation_language: zh` project, an H1 of `# Control Plane` is a
language drift; the correct form is `# 控制平面` (with `Control Plane`
preserved inline when needed for context, e.g. `# 控制平面（Control Plane）`).
For an `en` project, an H1 of `# 控制平面` would be the drift; the corrected
form is `# Control plane`.

Mixed-language H1s are allowed only when the locked language is the leading
language and the secondary language plays a strictly disambiguating role
(`# SDK Agent 运行时` is fine in a `zh` project because `SDK` is a code
identifier). An H1 that is pure English in a `zh` project is a drift even
when the English term is widely understood; the project explicitly chose
its body language to keep cold readers anchored.

Doctor `15L` (check 15 in lint) WARNs on H1s that appear to violate the
lock; the lint heuristic flags purely-English H1s in `zh` projects.
Semantic judgement (does the H1 read naturally? is the mixed form
justified?) stays in Doctor L2.

## 4. Validation rules

`ssot-lint.sh` owns mechanical checks; Doctor L2 owns semantic judgement.
The split is deliberate — agents read formatting-conventions.md to learn
the contract, run lint to catch the mechanical drift, and rely on Doctor
for cases where the agent has to read the file and decide.

`ssot-lint.sh` mechanical checks rooted in this file:

| Check | Doctor row | Level | What it checks |
|---|---|---|---|
| 13 | 15J `[PEER-FRONTMATTER]` | FAIL | Sibling files in the same directory declare the same YAML key set. |
| 14 | 15K `[NUMBERED-PREFIX]` | FAIL | Files under `product/capabilities/`, `product/journeys/`, or `architecture/<domain>/` directories follow `NN-` prefix. Ordered-directory names under `architecture/` also follow `NN-` prefix. |
| 15 | 15L `[H1-LANGUAGE]` | WARN | When `documentation_language=zh`, H1 lines are not pure English. |
| 16 | 15M `[INTENT-RECOVERY-UNIFORM]` | FAIL | Prose files under `product/` and `architecture/` (excluding `_manifest.md`, `STATUS.md`, `CHANGELOG.md`) carry an `intent_recovery:` frontmatter key. |

Doctor L2 owns: whether sibling files use comparable section templates,
whether mixed-language H1s read naturally, whether a not-yet-numbered
directory is actually unordered or just unsorted, and whether
`intent_recovery: covered` claims are honest about their pillar coverage.
