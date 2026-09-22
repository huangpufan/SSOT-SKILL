<div align="center">

# SSOT Skill

**Shared repository memory for coding agents, maintained in Markdown.**

[![CI](https://github.com/huangpufan/SSOT-SKILL/actions/workflows/ci.yml/badge.svg)](https://github.com/huangpufan/SSOT-SKILL/actions/workflows/ci.yml) [![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE) [![Agents](https://img.shields.io/badge/agents-70%2B-purple)](#supported-agents) [![Stars](https://img.shields.io/github/stars/huangpufan/SSOT-SKILL?style=social)](https://github.com/huangpufan/SSOT-SKILL/stargazers)

[English](./README.md) · [中文](./README.zh.md) · [Install guide](./INSTALL.md) · [Protocol version](./VERSION) · [Changelog](./CHANGELOG.md)

</div>

A new coding session often starts with the same questions: what does this project promise, why was it built this way, and which fixes must not be undone? SSOT Skill helps your agent preserve those answers in a version-controlled `SSOT/` directory, so the next session has a place to start. Once wired into the repository instructions, your agent reads and maintains that memory during normal work.

**SSOT** means **Single Source of Truth**: each durable fact has one maintained home; other documents link to it. The bundle supplies six skills, Markdown templates, and a local checker that work inside your existing coding agent.

- **Carry context across sessions.** Keep product intent, architecture boundaries, decisions, and known pitfalls alongside the code.
- **Share context across tools.** Agents working in the same repository can read and update the same files.
- **Know what has been checked.** Record reviewed commits, remaining gaps, and decisions that still need human input.

It is most useful for repositories you return to over time, especially when people or agents hand work to one another.

## Quickstart

### 1. Install in the repository you want to document

Open that repository in your coding agent and paste:

```text
Read https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/INSTALL.md and follow it.
```

The agent follows the [install guide](./INSTALL.md) to identify its installation target, install and verify all six skills, and merge lifecycle instructions into the repository's `AGENTS.md`, `CLAUDE.md`, or equivalent file. The default is **the current project only**, preserving an existing template language or choosing `en` / `zh` from your conversation. You can specify a different language or explicitly request a global installation in the same message.

<details>
<summary>Prefer to install from a terminal?</summary>

You need **Bash 4+**, `git`, `curl`, and `python3`. On macOS, run `brew install bash` first and use `"$(brew --prefix)/bin/bash"` in place of `bash` below; the system Bash is too old.

Run this from the root of the repository you want to document:

```bash
set -o pipefail
curl -fsSL https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/install.sh | bash -s -- --quickstart --scope project --lang en
```

Use `--lang zh` for Chinese templates. `--quickstart` detects the agent and skips interactive prompts. If detection is ambiguous or you want to choose explicitly, append `--agent codex`, `--agent claude-code`, or another [supported key](#supported-agents).

The script installs the skills and prints a suggested instruction block. **It does not edit your agent-instructions file or create `SSOT/`.** Merge the block using [install guide step 4](./INSTALL.md#4-wire-the-skills-into-the-repos-agent-instructions-file), updating any existing SSOT block instead of duplicating it. Then continue below.

</details>

### 2. Restart the agent, then work as usual

Restart the agent session so it loads the installed skills and repository instructions. **Describe your task as usual; the agent applies the SSOT workflow automatically.** For example:

```text
Investigate and fix the login timeout, and verify the fix.
```

The repository instructions tell the agent when to act:

- **Before substantive work:** check SSOT state and read the relevant context through preflight. Missing or unfinished `SSOT/` routes to bootstrap; an older tracked protocol routes to audit.
- **During work:** capture durable facts, decisions, and evidence in their maintained homes.
- **Before finishing or committing a substantive batch:** run closeout, reconcile the changes with SSOT, and route to Doctor when review is required. Work that changes no durable facts can leave SSOT unchanged.

You do not need to select or invoke a skill at every step. Initial bootstrap explores the repository and reviews its documentation; large repositories may need several sessions, with progress saved for continuation. Read the result at `SSOT/README.md` and check `SSOT/STATUS.md` for reviewed areas and open issues.

<details>
<summary>Optional: request setup or a focused check directly</summary>

You can ask in ordinary language:

```text
Create or continue this repository's SSOT from its code and existing documentation.
Check the health of this repository's SSOT.
Catch SSOT up with the recent commits.
```

Naming a skill explicitly is also available, for example `Use $ssot-doctor to check this repository's SSOT.` This can help when diagnosing a missed trigger. It is an agent chat prompt; invocation syntax varies by agent.

</details>

## How the agent selects skills

The agent selects from five lifecycle skills according to the task and repository state; the sixth preserves compatibility with older prompts. This table explains the routing for reference. Follow a skill link for its protocol and detailed references.

| Situation | Skill | Purpose |
|---|---|---|
| Starting a substantive repository task | [`ssot-preflight`](./skills/ssot-preflight/SKILL.md) | Check reviewed state, unresolved decisions, language, and version; route the necessary reading |
| Creating `SSOT/` or resuming its initial setup | [`ssot-bootstrap`](./skills/ssot-bootstrap/SKILL.md) | Build repository memory from evidence and review its coverage |
| Finishing a substantive change batch | [`ssot-closeout`](./skills/ssot-closeout/SKILL.md) | Reconcile changes with durable facts before the final response or commit |
| Catching up on commits, sessions, or protocol changes | [`ssot-audit`](./skills/ssot-audit/SKILL.md) | Review history in segments and update the tracking baseline |
| Checking documentation health or reviewing a completion claim | [`ssot-doctor`](./skills/ssot-doctor/SKILL.md) | Run structural checks and review evidence, consistency, and readability |
| Using an older `$ssot-skill` prompt | [`ssot-skill`](./skills/ssot-skill/SKILL.md) | Route to one of the five skills above |

The **tracking baseline** records which commit, session, and protocol version the documentation has reviewed. It is not a claim that every fact is current or every area is complete.

## What appears in your repository?

The installed skills are the instructions and tools. Your repository's `SSOT/` is the memory they help maintain:

```text
Your task → agent reads SSOT → does the work → updates SSOT as needed
```

The main reading paths are:

```text
 your-repo/SSOT/
 ├── README.md           What this repository does and where to find answers
 ├── STATUS.md           Reviewed state, open decisions, gaps, and tracking baseline
 ├── HISTORY.md          Brief log of SSOT update batches and the files they touched
 ├── 01-product/         Users, capabilities, journeys, and acceptance criteria
 ├── 02-architecture/    How the system works, owns state, and handles failure
 │   ├── views/          Explanations that span system boundaries
 │   └── NN-domain/      Details for a repository-specific responsibility boundary
 ├── 03-process/         How to develop, test, benchmark, deploy, and release
 ├── 04-records/         Decisions, research, pitfalls, bugs, and technical debt
 ├── glossary/           Repository-specific terms and their meanings
 └── .bootstrap/         Progress and review evidence during initial setup
```

Architecture domains follow the repository's actual responsibilities. Operations and security/compliance process areas are included when applicable. See the [template index](./skills/ssot-bootstrap/references/templates-index.md) for the detailed layout.

Existing READMEs, design documents, and decisions are input to this process. Durable facts are consolidated into their designated owners, with navigation links pointing readers there; see the [source-material rules](./skills/ssot-preflight/references/source-material.md).

## What keeps the memory useful?

**Readable by people who delegate implementation.** The writing rules ask documents to explain the user situation, current behavior, boundaries, failure and recovery, and the evidence needed to accept a result. A reader should be able to decide what to ask an agent to do without first reconstructing the code. Detailed acceptance criteria live in the [reader-quality protocol](./skills/ssot-preflight/references/reader-quality.md).

**Evidence stays attached to claims.** Code, schemas, tests, and observed runtime behavior remain the evidence for current implementation. SSOT preserves the explanations and decisions around them, and distinguishes current behavior, intended behavior, and unknowns.

**Checks have explicit limits.** The [local checker](./skills/ssot-doctor/assets/scripts/ssot-lint.sh) checks mechanically decidable properties such as structure, links, and tracking consistency. Doctor adds agent review. Passing lint alone does not prove a document is true, understandable, or complete; bootstrap completion requires independent review.

**Maintenance follows the agent workflow.** Once the skills and repository instructions are loaded, the agent triggers the appropriate skills as it works. This automation depends on the agent following those instructions; changes made outside that workflow are reviewed when the agent next works in the repository or you request a catch-up.

## Supported agents

The installer contains installation paths for **70+ agents**, including Claude Code, Codex, Cursor, Windsurf, Gemini CLI, GitHub Copilot, OpenCode, and Cline. Examples of project-local locations:

| Agent | Installer key | Project skills directory |
|---|---|---|
| Claude Code | `claude-code` | `.claude/skills/` |
| Codex | `codex` | `.agents/skills/` |
| Cursor | `cursor` | `.agents/skills/` |
| Windsurf | `windsurf` | `.windsurf/skills/` |
| Gemini CLI | `gemini-cli` | `.agents/skills/` |

List all keys and installation paths without installing anything:

```bash
set -o pipefail
curl -fsSL https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/install.sh | bash -s -- --list-agents
```

An installation path in the registry does not establish identical skill discovery or behavior across agent versions. Restart the agent after installation and verify that it can discover the skills.

## Update or uninstall

Ask your agent to handle updates through the same guide:

```text
Read https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/INSTALL.md and update SSOT Skill for this agent in the current project. Preserve the template language.
```

Restart the agent afterward. At the next substantive task, preflight checks the repository's tracked protocol and routes an older version to audit for upgrade review. Replacing the installed skills does not migrate `SSOT/` by itself. To uninstall, ask the agent to follow the guide's removal steps for the chosen scope, including checking for obsolete trigger instructions.

<details>
<summary>Manual update and removal commands</summary>

For a project-local Codex installation, run from the consuming repository:

```bash
set -o pipefail
curl -fsSL https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/install.sh | bash -s -- --upgrade --agent codex --scope project
```

To remove it:

```bash
set -o pipefail
curl -fsSL https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/install.sh | bash -s -- --uninstall --agent codex --scope project --yes
```

Choose the same key and scope used during installation. Agents sharing a skills directory also share the installed bundle, so removal affects that shared location. The command leaves your `SSOT/` documents and agent-instructions file in place; remove obsolete SSOT trigger instructions yourself if you stop using the bundle.

Bare `--upgrade` updates all detected installations in the current project and globally. Use the scoped form above when you want to update just one installation.

</details>

## Documentation and contributing

- [Install guide](./INSTALL.md) — agent-driven setup, instruction wiring, and network fallback.
- [Changelog](./CHANGELOG.md) and [current protocol version](./VERSION) — what changed in the bundle.
- [Protocol upgrade guide](./skills/ssot-audit/references/protocol-upgrades.md) — how existing repository documentation catches up.
- [Contributing](./CONTRIBUTING.md) — how to propose changes and run local checks.
- [AGENTS.md](./AGENTS.md) — instructions for agents maintaining **this bundle repository**.
- [Security policy](./SECURITY.md) — how to report a vulnerability.

## Star History

<a href="https://www.star-history.com/#huangpufan/SSOT-SKILL&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=huangpufan/SSOT-SKILL&type=Date&theme=dark" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=huangpufan/SSOT-SKILL&type=Date" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=huangpufan/SSOT-SKILL&type=Date" />
  </picture>
</a>

## License

[MIT](./LICENSE) © [huangpufan](https://github.com/huangpufan)
