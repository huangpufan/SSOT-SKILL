---
name: ssot-audit
description: Compatibility name for catching a repository's SSOT up on past commits. Use only when a prompt or an instruction file explicitly asks for $ssot-audit; it hands the work to $ssot-doctor's catch-up.
---

# SSOT Audit (compatibility name)

This name exists so that older prompts and instruction files keep working.
Catching up on past commits is now part of `$ssot-doctor`: follow its
section 4. A new release of the bundle never obliges a repository to catch up.
Only commits that landed without SSOT updates do.
