# Contributing to SSOT Skill

Thanks for your interest in improving the SSOT Skill bundle.

## Protocol vs. Engineering

This repository hosts a **protocol** (the SSOT Skill bundle), not application
code. Changes fall into two buckets:

| Type | What it touches | Review weight |
|---|---|---|
| Engineering | `install.sh`, `tests/`, `.github/workflows/`, `skills/*/assets/scripts/` | Standard PR review |
| Protocol | `skills/*/SKILL.md`, `skills/*/references/*.md`, `VERSION`, `CHANGELOG.md` | Protocol uplift review |

A protocol change MUST bump `VERSION` and add a `CHANGELOG.md` entry. The bump
also requires updating `metadata.protocol_version` in
`skills/ssot-preflight/SKILL.md` (single semantic owner; the `VERSION` file is
the physical mirror enforced by `tests/test-bundle-shape.sh`).

## Local verification

Before opening a PR:

```bash
bash -n install.sh
bash skills/ssot-doctor/assets/scripts/test/run-tests.sh
bash tests/test-bundle-shape.sh
bash tests/test-installer-e2e.sh
```

CI runs the same set plus `shellcheck`.

## PR checklist

- [ ] `bash -n` clean on all shell files
- [ ] `shellcheck -e SC2034` clean
- [ ] `run-tests.sh` passes
- [ ] `test-bundle-shape.sh` passes
- [ ] `test-installer-e2e.sh` passes
- [ ] If protocol-bumping: `VERSION` updated and `CHANGELOG.md` entry added
- [ ] If touching cross-skill references: every `[text](../path)` link verified
- [ ] If touching templates: both `templates/en/` and `templates/zh/` updated
- [ ] README.md and README.zh.md kept in sync for user-facing changes

## Skill protocol language

`SKILL.md` and `references/*.md` are read directly by the LLM and MUST stay in
English. The English form aligns with mainstream skill ecosystems (Anthropic
official skills, Claude Code built-ins) and maximises routing accuracy and
instruction-following fidelity.

Templates under `assets/templates/{en,zh}/` are user-facing (they get copied
into the consumer repository's SSOT directory). Both languages must stay in
parity: every file in `en/` has a counterpart in `zh/`.

## Code of conduct

Be kind. Surface disagreements via evidence and proposed alternatives, not
broad rejection.

## Upgrading an existing consumer SSOT to PLTL v3

Consumer repositories already running on a pre-2.28 bundle do not need a one-shot rewrite. After upgrading the skill bundle:

1. If `SSOT/STATUS.md` predates v2.28, manually paste the `## Pending Captures` block from the upgraded `skills/ssot-bootstrap/assets/templates/{en,zh}/status.md` template into the consumer's STATUS.md, between `## Open Adjudications` and `## Open Gaps`.
2. Subsequent `$ssot-closeout` batches will opportunistically wrap touched rules with the `<!-- rule: -->` HTML comment as those rules are cited — not as a back-fill pass over the whole repository. Untouched rules stay un-wrapped and remain valid Authority-altitude content.

The altitude-inference rule for pre-v2.28 rules (apex inferred from current location in AGENTS.md or a `SKILL.md`; everything else under `SSOT/` defaults to authority; inbox is empty until the first capture) lives in `skills/ssot-closeout/references/promotion-rationale.md ## Migration of pre-v2.28 rules`. `tracked_skill_version` may advance to `2.28` once `$ssot-audit` reports `no-more-required-changes`.
