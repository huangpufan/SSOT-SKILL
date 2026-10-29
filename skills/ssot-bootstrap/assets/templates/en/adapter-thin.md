# SSOT instruction block

Add the block below to the repository's agent instruction file (`AGENTS.md`, `CLAUDE.md`, or the equivalent). If a block with these markers already exists, replace only the text between them.

<!-- SSOT-SKILL:BEGIN -->
## SSOT workflow

This repository keeps its long-term memory in `SSOT/`. Use the SSOT skills automatically; users describe tasks normally.

- **Start:** before substantive work (code, configuration, documentation, review, debugging, or planning), use `$ssot-preflight`.
- **Finish:** before the final response or commit of a substantive change batch, use `$ssot-closeout`. It writes nothing when no durable fact changed.
- **Create or migrate:** use `$ssot-bootstrap`, only with the user's agreement.
- **Check or catch up:** use `$ssot-doctor` when asked, or when another SSOT skill routes there.

Skip these for non-repository chat, pure command runs, and typo or formatting edits. Before planning or changing behavior or architecture, use `$ssot-preflight` to identify protected outcomes, and preserve active registered invariants and protections admitted from evidence unless the user explicitly approves the identified departure. Code, configuration, and tests remain the evidence for current behavior. Commits and pushes follow this repository's existing rules. If an SSOT skill cannot be loaded, say so instead of guessing its steps.
<!-- SSOT-SKILL:END -->
