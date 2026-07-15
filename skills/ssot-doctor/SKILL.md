---
name: ssot-doctor
description: Verify SSOT health, run deterministic lint checks, perform scoped stop review, CORE-REF startup/reference doc review, ADAPTER checks, CONSUMPTION checks, or coverage/converged validation. Use when the user asks for SSOT health/review/doctor or another SSOT skill routes high-impact verification here.
---

# SSOT Doctor

Verify existing SSOT; do not author truth or catch up changes. Run the bundled
lint, then follow [`doctor.md`](references/doctor.md). Load
[`reader-quality.md`](../ssot-preflight/references/reader-quality.md) for
reader bodies, adapter strategy for generated startup files, and consumption
audit for trigger claims. Structural success never substitutes for semantic
review. Return only `no-more-required-changes` or concrete `needs-fix` items.
