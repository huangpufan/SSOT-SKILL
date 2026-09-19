# SSOT History

<!-- Writing style: register-only. Append-only batch write log; rows are never
     edited, reordered, or deleted — a wrong row is corrected by a later row,
     never rewritten. Cells stay pointer-sized: this log carries provenance
     (when, which skill, which files), never the fact itself; facts live in
     their owners. -->

<!-- One row per batch that ran a writing skill on this SSOT. A `no-op` row is
     still appended when a substantive batch ran closeout and found no durable
     change — the log must distinguish "closeout ran and wrote nothing" from
     "no closeout ever ran". The column contract lives in
     update-routing.md §1.6. -->

| Date | Commit | Actor | Result | Touched | Note |
|---|---|---|---|---|---|
