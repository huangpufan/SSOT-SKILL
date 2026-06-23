# <Directory Name>

> One-sentence purpose: what this directory owns, who reads it, when to stop drilling.

## Directory map

```
<dir-name>/                         <one-line summary of this directory's role>
├── <child-or-file-1>               <what this child does; plain language; no undefined jargon>
├── <child-or-file-2>               <what this child does; if the file name is jargon, translate it here>
├── ...
├── README.md                       This file
└── _manifest.md                    Machine-only, skip
```

Recommended reading order: start with `<child-A>` (baseline), then `<child-B>` (main path), then `<child-C>` if your task needs it.
(Omit this line when children already carry an `NN-` numeric prefix.)

## Why this split

<One paragraph (≤5 sentences): why this directory stands on its own; what axis it uses; what axis it rejected; which sibling boundary is most easily confused with it by a cold reader.>

## Further reading

- Parent entry: [`../README.md`](../README.md)
- Cross-cutting view: [`<view>`](<path>) (optional)
- Task routing: see [STATUS.md](<path-to-status>)

<!--
Template notes:

1. The directory map must be the first content after the H1 + one-line purpose.
2. Each row's annotation is a single plain-language sentence with zero jargon undefined elsewhere in the map.
3. The `_manifest.md` row must carry the explicit "Machine-only, skip" marker.
4. If there are many children (>10), group them by facet with a one-line subhead per group.
5. Doctor 15N/15O/15P/15Q enforce these four guardrails; see doctor.md.
6. Maintenance registries, capability tables, and stop-review notes belong in `_manifest.md`, not the README's first screen.
-->
