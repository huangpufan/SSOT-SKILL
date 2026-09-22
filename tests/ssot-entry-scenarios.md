# Consumer instruction routing review

Use these cases when reviewing the marked block in the bilingual bootstrap
`adapter-thin.md` templates. The installer prints that same block. Compare
each expected route with the selected skill's actual protocol; these are
review cases, not measurements of model reliability.

| Case | Task and repository state | Expected route and boundary |
|---|---|---|
| Ordinary work | Fix a login timeout; SSOT is initialized and current | Preflight before work; closeout before the substantive batch ends. Audit and Doctor run only if a skill routes to them. |
| First use | Fix a bug; `SSOT/` is missing | Preflight routes to bootstrap; resume the original task after its gates clear. |
| Interrupted setup | Continue work; bootstrap is unfinished | Resume bootstrap through preflight's route rather than treating the presence of a directory as completion. |
| Protocol lag | Implement a feature; the project's tracked protocol is older than the installed bundle | Preflight routes to audit; apply its review requirements before advancing the tracking baseline. |
| History catch-up | “Bring SSOT up to date with the last ten commits” | Audit the requested range; do not substitute routine closeout or just rewrite tracking fields. |
| Health check | “Check SSOT health”; no implementation work requested | Doctor; no bootstrap or historical catch-up unless the applicable protocol identifies and routes that separate need. |
| Typo only | Correct punctuation without changing meaning; no SSOT exists | Skip automatic lifecycle work; do not initialize SSOT just for this edit. |
| Pure command | “Run git status” | Run the command; no automatic bootstrap, closeout, or audit. |
| Small but substantive | Change one authorization-setting value | Preflight and substantive-batch closeout apply despite the one-line diff. |
| No durable delta | Substantive work ends without changing durable facts | Closeout makes the no-op decision and records the batch as required; do not rewrite fact bodies merely to show activity. |
| Explicit request | After a trivial edit, user explicitly requests an SSOT health check | Doctor still applies; the automatic skip rule does not erase the explicit request. |
| Missing skill | A substantive task needs an installed skill that cannot be loaded | Pause work that depends on the skill's gates, report the missing prerequisite and recovery step; do not treat this summary as a passed check. |
| Human boundary | The selected skill encounters an unresolved decision or required review | Follow its stop/review requirements; automatic invocation does not bypass them. |
| Project authority | Project rules or the user prohibit pushing | Respect that instruction; closeout is not extra authorization to push. |

Packaging and preservation checks run in `test-installer-e2e.sh` scenario 23:
both languages, initial install and upgrade, exact printed/template parity,
existing instruction files and symlinks, malformed source rejection before
replacement, and flat template sources.
