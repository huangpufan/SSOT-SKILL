---
name: ssot-bootstrap
description: Bootstrap or continue repository SSOT creation. Use when SSOT/ is missing, SSOT/STATUS.md coverage_result is bootstrap, an active bootstrap manifest has unfinished phases, or the user asks to create a repository SSOT. Retained review artifacts under .bootstrap/ alone do not mean setup is unfinished. Do not use for normal code-task preflight or routine closeout in an already bootstrapped repo.
---

# SSOT Bootstrap

Build SSOT only from observed repository evidence; a filled template is not
proof. Follow [`bootstrap.md`](references/bootstrap.md) until every phase exit
holds. Load source-material rules for supplied documents and
[`reader-quality.md`](../ssot-preflight/references/reader-quality.md) for every
reader-facing body. Stop only after the required independent Doctor review
passes; never infer bootstrap completion from structure or lint alone.
