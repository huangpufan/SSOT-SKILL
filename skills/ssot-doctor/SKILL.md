---
name: ssot-doctor
description: Verify SSOT health, run deterministic lint checks, perform scoped stop review, CORE-REF startup/reference doc review, ADAPTER checks, CONSUMPTION checks, or coverage/converged validation. Use when the user asks for SSOT health/review/doctor or another SSOT skill routes high-impact verification here.
---

# SSOT Doctor

Verify existing SSOT; do not author truth or catch up changes. Declare scope
and dependencies, run lint, then follow [`doctor.md`](references/doctor.md) and
[`reader-quality.md`](../ssot-preflight/references/reader-quality.md).
Continue interpretable semantic checks despite unrelated failures. Relevant L1
failures block pass/coverage claims; damaged inputs block dependent checks.
Stop with matching scoped L1/L2 evidence and Stop Review Gate rows.
Repository-wide pass requires repository-wide checks.
