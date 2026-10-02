# Doctor diagnostic scope scenarios

Supply the requested scope, raw lint result, and owner dependencies to an
independent reader of the actual Doctor protocol. Ask what it will examine and
which conclusions the evidence supports, without giving the expected answer.

| Scenario | Expected boundary |
|---|---|
| Payment review; unrelated research frontmatter FAIL | Continue interpretable payment L2; report research debt separately. No whole-repository pass. |
| Relevant owner has broken evidence link | Diagnose what remains interpretable; dependent check is not assessed until repaired; no affected pass. |
| Tool exits 3 without valid results | Report invocation/tool error and missing assessment, not content failure or pass. |
| Only heuristic WARN | Inspect and dispose the warning under the claimed state's rules. |
| The same WARN under `--strict` | Preserve its promoted blocking effect. |
| Shared STATUS schema prevents interpreting scope | Repair the prerequisite before dependent checks; other independent diagnosis may proceed. |

2026-10-03 independent decision comparison: the frozen-v2.64 reader stopped
formal L2 for unrelated research debt; the candidate reader continued scoped
L2 and withheld whole-repository claims. Both reported exit 3 as unassessed.
The candidate also handled damaged shared STATUS and WARN/strict variants
without bypassing the relevant gate. The broken owner-link case was reviewed
in the protocol, not executed as a separate agent trial. These decisions do
not constitute a complete consumer Doctor run; deterministic lint regressions
are tested separately through the CLI suite.
