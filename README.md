<div align="center">

# SSOT Skill

**Durable, verifiable, cross-session long-term memory for coding agents.**

[![Version](https://img.shields.io/github/v/tag/huangpufan/SSOT-SKILL?label=protocol&color=2ea44f)](./VERSION)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![CI](https://github.com/huangpufan/SSOT-SKILL/actions/workflows/ci.yml/badge.svg)](https://github.com/huangpufan/SSOT-SKILL/actions/workflows/ci.yml)
[![Agents](https://img.shields.io/badge/agents-70%2B-purple)](#supported-agents)
[![Stars](https://img.shields.io/github/stars/huangpufan/SSOT-SKILL?style=social)](https://github.com/huangpufan/SSOT-SKILL/stargazers)

[English](./README.md) · [中文](./README.zh.md) · [Skill Reference](./AGENTS.md) · [Changelog](./CHANGELOG.md)

</div>

---

SSOT Skill turns your repository's long-lived facts — product intent, architecture boundaries, decisions, pitfalls, test policy — into a reviewable Markdown `SSOT/` directory. Any agent (Claude Code, Codex, Cursor, Windsurf, Gemini CLI, …) reads the same waterline before starting work, instead of reconstructing context from scratch every session.

> `SSOT/` is **agent long-term memory**, not a substitute for code. Code, schema, tests, and runtime behavior remain the source of truth for current implementation; SSOT records the durable conclusions around them.

## Quickstart

**Tell your agent (paste this into your repo's chat):**

> Install the SSOT Skill bundle into this project. Run:
> ```bash
> curl -fsSL https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/install.sh | bash -s -- --quickstart
> ```
> If the download is slow or blocked, use the mirror:
> ```bash
> curl -fsSL https://gh-proxy.com/https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/install.sh | bash -s -- --quickstart
> ```
> The installer auto-detects your agent + template language and installs
> **project-locally by default**. After it finishes, **ask me whether to also
> install globally (default: no)**. If yes, re-run the same command with
> `--scope global` appended (after `--quickstart`).
> Finally, read `AGENTS.md` and restart yourself so the skills load.

**Or run the interactive installer yourself:**

```bash
curl -fsSL https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/install.sh | bash
```

The interactive installer opens pickers for agent, scope, and template language. After install, restart your agent session, then run `$ssot-bootstrap` to create `SSOT/` and wire the adapter.

## Requirements

- **Bash 4+**. macOS ships bash 3.2 by default — install a newer bash first: `brew install bash` (then re-run the installer through `/opt/homebrew/bin/bash`).
- `git`, `curl`, and `python3` on `PATH`.

## Uninstall

```bash
bash install.sh --uninstall --agent <key> --scope <global|project> --yes
```

`<key>` is the canonical agent key you installed into (e.g. `claude-code`, `codex`, `cursor`). The installer also supports `--upgrade` (re-scan all detected installs and reinstall) and `--version`.

## The Six Lifecycle Skills

| Skill | When to use |
|---|---|
| `$ssot-preflight` | Before any substantive code task — reads waterline, open adjudications, routes you to the minimal SSOT files |
| `$ssot-bootstrap` | First time on a repo with no `SSOT/`, or bootstrap is incomplete |
| `$ssot-closeout`  | Before final response / `claim_done` / commit — decides whether durable facts need absorbing |
| `$ssot-audit`     | Catch up commits, sessions, or protocol upgrades in segments |
| `$ssot-doctor`    | Health check, stop review, lint, CORE-REF / ADAPTER / CONSUMPTION audits |
| `$ssot-skill`     | Compatibility shim; routes calls to one of the five above (kept for legacy prompts) |

The protocol version is single-sourced in [`skills/ssot-preflight/SKILL.md`](./skills/ssot-preflight/SKILL.md) and mirrored in [`VERSION`](./VERSION).

## How It Fits Together

```
┌─────────────────────────┐    install.sh    ┌────────────────────────────────┐
│  SSOT-SKILL (this repo) │ ───────────────▶ │  PROJECT scope (default):      │  ← agent loads
│  installer · 6 skills   │                  │    .claude/skills/...          │     these at startup
│  protocol · templates   │                  │    .agents/skills/...  (Codex, │
│                         │                  │      Cursor, Gemini CLI, …)    │
│                         │                  │  GLOBAL scope (opt-in):        │
│                         │                  │    ~/.claude/skills/...        │
│                         │                  │    ~/.codex/skills/...         │
└─────────────────────────┘                  └──────────────┬─────────────────┘
                                                            │ skills run inside
                                                            ▼
                                              ┌────────────────────────────────┐
                                              │  your-repo/SSOT/               │  ← long-term memory
                                              │  product / architecture        │     of your repo
                                              │  testing / development         │
                                              └────────────────────────────────┘
```

Three layers, one purpose: keep agent memory of a repository **reviewable**, **verifiable**, and **portable across tools**.

## Common Flows

```text
# Starting a code task
Use $ssot-preflight before starting this repository task.

# Wrapping up
Use $ssot-closeout before the final response.

# Brand-new repo
Use $ssot-bootstrap to create repository SSOT.

# Catching up history
Use $ssot-audit to catch up tracked_commit and tracked_session.

# Sanity check
Use $ssot-doctor to run an SSOT health check.
```

## Supported Agents

Aligned with the [vercel-labs/skills](https://github.com/vercel-labs/skills) registry. Headliners: **Claude Code · Cursor · Codex · Windsurf · Gemini CLI · GitHub Copilot · OpenCode · Cline · Roo Code · Continue · Augment · Zed · Goose · Aider · Junie · Trae · Crush · Warp · OpenHands · Replit · Devin · Droid · Qwen Code · Lingma · Kilo · ForgeCode · Tabnine**, plus 40+ more. The interactive installer shows which agents it detects on your machine.

## Documentation

- [`AGENTS.md`](./AGENTS.md) — full skill reference and routing rules
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — contribution guide
- [`CHANGELOG.md`](./CHANGELOG.md) — protocol history (Keep a Changelog)
- [`skills/ssot-audit/references/protocol-upgrades.md`](./skills/ssot-audit/references/protocol-upgrades.md) — upgrade router

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
