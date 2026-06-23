---
name: ssot-skill
description: Legacy compatibility shim for the split SSOT Skill bundle. Use only when old prompts or docs explicitly request ssot-skill; route to ssot-preflight, ssot-bootstrap, ssot-closeout, ssot-audit, or ssot-doctor. Do not treat this shim as the protocol owner.
---

# SSOT Skill — compatibility shim

You landed here from a legacy `$ssot-skill` mention. Don't stay. Route to the
lifecycle skill that matches *when in the task you are right now*:

- before substantive work → `$ssot-preflight`
- no `SSOT/` yet, or `.bootstrap/` present → `$ssot-bootstrap`
- before final answer, `claim_done`, or commit → `$ssot-closeout`
- catching up commits, sessions, or protocol version → `$ssot-audit`
- verifying health, stop review, CORE-REF / ADAPTER / CONSUMPTION → `$ssot-doctor`

Protocol version lives in `ssot-preflight`. Don't re-decide it here.
