---
name: ssot-doctor
description: Verify SSOT health, run deterministic lint checks, perform scoped stop review, CORE-REF startup/reference doc review, ADAPTER checks, CONSUMPTION checks, or coverage/converged validation. Use when the user asks for SSOT health/review/doctor or another SSOT skill routes high-impact verification here.
---

# SSOT Doctor

Verify existing SSOT; do not author truth or catch up changes. Run bundled
lint, then follow [`doctor.md`](references/doctor.md) and
[`reader-quality.md`](../ssot-preflight/references/reader-quality.md).
Structural success never substitutes for semantic review. Doctor stops on its
own definition of done, not deferred elsewhere: L1 lint clean, L2 checks
return `no-more-required-changes` or a `needs-fix` list, and claimed
`covered`/`partial`/`converged` match Stop Review Gate rows.
