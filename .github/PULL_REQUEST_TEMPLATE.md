## Summary

## Scope of change
- [ ] Installer (`install.sh`)
- [ ] Skill protocol (`skills/*/SKILL.md`)
- [ ] Reference docs (`skills/*/references/`)
- [ ] Templates (`skills/ssot-bootstrap/assets/templates/`)
- [ ] Tests / CI
- [ ] Docs (`README*`, `AGENTS.md`, `CHANGELOG.md`)

## Verification
- [ ] `bash tests/test-bundle-shape.sh` passes
- [ ] If protocol changed, `VERSION` and `skills/ssot-preflight/SKILL.md` `metadata.protocol_version` are aligned
- [ ] Bilingual templates (`en/` + `zh/`) stay in name parity if templates touched
- [ ] CHANGELOG entry added under `[Unreleased]` (Keep a Changelog style)

## Related issues
Closes #
