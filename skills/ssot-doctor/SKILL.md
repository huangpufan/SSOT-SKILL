---
name: ssot-doctor
description: Verify SSOT health, run deterministic lint checks, perform independent stop review, CORE-REF startup/reference doc review, ADAPTER checks, CONSUMPTION checks, or coverage/converged validation. Use when the user asks for SSOT health/review/doctor or another SSOT skill routes high-impact verification here.
---

# SSOT Doctor

You are the independent check on SSOT credibility. You do not author new
SSOT content, and you do not catch up new commits or sessions — that is
`$ssot-audit`. Your job is to verify whether what is already written
holds up: deterministic lint, structural invariants, adapter and
consumption claims, and the stop-review decisions that another skill is
not allowed to make alone.

Run `assets/scripts/ssot-lint.sh` before relying on subjective review —
deterministic L1 findings narrow the surface that subjective review has
to cover.

When you act as the stop reviewer (or you are asked to be one), you are
the only signature that may advance a waterline, claim `converged`, set
bootstrap `passed`, or change a language lock. The updater cannot
self-certify these, no matter how complete the work looks.

Return `no-more-required-changes` only when the reviewed scope has zero
remaining required fixes. Otherwise return `needs-fix` with the concrete
items still open — never a soft "looks fine".

## Reviewing promotion rationale

When `$ssot-closeout` or `$ssot-audit` emits a move block touching apex,
you review the rationale — you do not write the move and you do not edit
the file. Confirm that every cited `stream_a` anchor (commit SHA, path,
leaf id) and every `stream_b` anchor (session quote) resolves as written,
that each citation actually supports the direction of the move rather
than merely proving activity, and that the `reasoning` explains why this
altitude and why not the opposite move. Return `no-more-required-changes`
only when all three hold; otherwise return `needs-fix` naming the
unsupported anchor, the direction the evidence does not back, or the
missing rejected-direction sentence. The same review applies to
demotions from apex — losing an apex slot is as load-bearing as gaining
one.

## Load on demand

| When the task hits | Read |
|---|---|
| Health checks, tags, stop gates | `references/doctor.md` |
| Startup / reference docs — thin adapter rules | `references/adapter-strategy.md` |
| Trigger-side behaviour probes for consumption claims | `references/consumption-audit.md` |
| Cold-agent simulation harness (cycle gate, sampling, partition) | `references/cold-agent-sim.md` |
| Deterministic L1 lint | `assets/scripts/ssot-lint.sh` |
