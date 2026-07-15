# Repository Vocabulary

<!-- Writing style: implementation-delegator. A reader must understand a term,
     its consequence, and the next lookup without knowing repository meta. -->

<!-- Completeness authority: reader-quality.md C01-C09, G01-G08, and applicable
     Q01-Q21 vocabulary. Per-term
     bodies use glossary-entry.md only when a real repository term exists. -->

Use this page when a repository word changes how you interpret a requirement,
state, role, boundary, or record. Find the exact term, open its entry, and answer
three questions before acting: what it positively means here, why the
distinction matters, and what nearby case does not qualify.

Here, an **owner** is the one place where a fact is explained and maintained;
it does not necessarily mean a person. Q01-Q21 are routing IDs for twenty-one
quality, risk, and governance question families in STATUS, not scores. A term
entry explains only the repository vocabulary used by those questions; STATUS
still owns whether a question applies and where its answer lives.

For example, a repository may use `ready` once for a user-visible object and
again for service health. Do not treat those meanings as interchangeable. Open
both term entries, compare their examples and non-examples, then follow the
unique product, architecture, process, or record owner linked by each term.

Each term entry explains the term in plain language, the decision it changes,
one concrete example, one non-example or common confusion, its unique owner and
evidence, related terms, canonical spelling, aliases/acronyms, user label,
machine token, translation constraint, scope, and the change that invalidates
the definition. It also states whether the term is active, deprecated, or
retired and, when it is no longer active, what replaces it and how readers
migrate. Include applicable Q01-Q21 vocabulary without defining the Q
protocol itself. Pay particular attention to privacy/data-governance labels,
safety and appeal terms, fairness or explanation claims, lifecycle/retirement
states, output-quality or drift labels, and price/plan/entitlement words: a
reader must know their repository meaning before delegating a change.
The family inventory below is the only glossary inventory. It helps the reader
find an entry without creating a second alphabetical or protocol-specific list.
An owner may be a dedicated term file or one unique term H2 anchor in this
README or a topic file.

## Vocabulary-family coverage

Dispose exactly the six families below. This table is the finite inventory:
every real term entry is linked exactly once in one family. Do not repeat the
same entry in another list. A family becomes applicable only when repository
source, schema, product, architecture, process, records, or root instructions
actually use a repository-specific term in that family. If none exists, name
what was checked and the change that would require another review; do not
invent a term to fill the row.

Use `applicable` only when the final cell links every term owner in that family.
For an empty family use `not_applicable` and put this visible form in the final
cell: `reason=<specific reason>; checked=[evidence owner](<resolving-path>);
review when=<observable event>.` Replace every placeholder with repository
truth.

| Vocabulary family | Discovery trigger | Disposition | Term-entry owner links or reason |
|---|---|---|---|
| Product and user concepts | A repository-specific user role, problem, promise, capability, journey, plan, entitlement, or visible label exists. | applicable / not_applicable | |
| Architecture and runtime concepts | A named runtime owner, component/domain, agent role, deployable unit, contract, resource, or technical boundary exists. | applicable / not_applicable | |
| State, lifecycle, and workflow terms | A persisted state, transition, workflow result, record state, or repository-specific lifecycle label exists. | applicable / not_applicable | |
| Trust, identity, access, and data-governance terms | A named identity, role, permission, tenant/workspace boundary, data class, consent, privacy, or governance label exists. | applicable / not_applicable | |
| Evidence, verification, and operating terms | A repository-specific gate, proof level, signal, SLO, operating label, rule family, or rule-placement term exists. | applicable / not_applicable | |
| Concurrency-control terms | A named queue, lease, lock, scheduler key, quota key, or concurrency limit exists. | applicable / not_applicable | |

## Adding or changing a term

Create a term entry only when the repository actually uses a specific or
redefined term. Use a dedicated `glossary/<term>.md` file or a unique H2 anchor
in this README/topic file. Write its positive definition before distinctions, explain
why a mistaken interpretation changes a decision, give a real example and the
nearest non-example, and link one authoritative owner plus fitting code,
schema, decision, or test evidence. Then link it once in the one family
inventory above.

Do not split an existing readable topic page merely to satisfy inventory
shape. Split when the collection exceeds 30 entries or spans distinct business
domains that need independent ownership and maintenance.

When an enum, schema, product promise, architecture contract, process rule, or
decision changes the meaning, update the term entry and every consumer that
relies on the old distinction. If two entries claim the same definition,
choose one owner and turn the other into a related-term link.

## Boundaries and when to recheck

This glossary records only repository-specific language or standard words that
have a special meaning here. It does not teach general framework vocabulary or
replace the product, architecture, process, or record owner. Recheck the index
when a term is added, renamed, merged, split, or retired; recheck an entry when
its owner, evidence, scope, or invalidation trigger changes.
