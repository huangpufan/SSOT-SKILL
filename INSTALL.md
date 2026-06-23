# Install Guide (Agent-facing)

You are an AI coding agent. A user has asked you to install the SSOT Skill bundle into this repository. Follow these steps in order. Respond in the user's language.

## 1. Ask the user two quick questions

Before installing, ask the user — in their language — these two questions in a single message. Pre-select defaults: `zh` for language if the user is chatting in Chinese (otherwise `en`); `project only` for scope.

> Two quick choices before I install:
>
> 1. **Template language** for the `SSOT/` docs we'll create later — `en` or `zh`? (default: \<your inferred default\>)
> 2. **Scope** — install only into this project, or also globally for all your repos? (default: project only)

Wait for the user's reply. Capture two values:

- `LANG` ∈ `{en, zh}` — default `en` (or the inferred default you offered).
- `INSTALL_GLOBAL` ∈ `{yes, no}` — default `no`.

If the user's reply is ambiguous or silent on either question, use the default.

## 2. Install project-locally

Run:

```bash
curl -fsSL https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/install.sh | bash -s -- --quickstart --lang <LANG>
```

If that hangs or fails for network reasons (e.g. mainland China), retry with the mirror:

```bash
curl -fsSL https://gh-proxy.com/https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/install.sh | bash -s -- --quickstart --lang <LANG>
```

`--quickstart` auto-detects which agent you are (env signature → filesystem scan) and installs **project-locally** (into `./.claude/skills/`, `./.agents/skills/`, etc. — depending on which agent you are).

Verify the install: a file like `./.claude/skills/ssot-preflight/SKILL.md` (or your agent's equivalent path) should now exist. If not, surface the installer's stderr to the user and stop — do **not** proceed until project install succeeds.

## 3. If `INSTALL_GLOBAL = yes`, also install globally

```bash
curl -fsSL https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/install.sh | bash -s -- --quickstart --lang <LANG> --scope global
```

(Use the `gh-proxy.com` mirror if step 2 needed it.)

Verify a file like `~/.claude/skills/ssot-preflight/SKILL.md` exists.

## 4. Wire the skills into the repo's agent-instructions file

Step 2 made the skills discoverable, but discovery is not invocation — without an explicit trigger directive, you (and the next agent that opens this repo) may forget to call `$ssot-preflight` at the right moment.

Find this repo's primary agent-instructions file based on which agent you are:

- Claude Code → `CLAUDE.md` at repo root
- Codex / OpenAI-style → `AGENTS.md`
- Cursor → `.cursor/rules/ssot.mdc` (new file) or merge into existing `.cursorrules`
- Windsurf → `.windsurf/rules/ssot.md` or merge into `.windsurfrules`
- Gemini CLI → `GEMINI.md`
- Other agents → their canonical instruction file

Read it first if it exists. Then merge in these six lines (use `LANG` from step 1). Pick a natural section — "Skills", "Conventions", or end-of-file — and adapt wording so it flows with the surrounding text. **Do not** paste verbatim if the file uses a different voice.

**en**

> SSOT Skill is installed here. `SSOT/` is agent long-term memory; code, schema, and tests remain the source of truth.
> - `$ssot-preflight` — before any substantive repository task.
> - `$ssot-bootstrap` — when `SSOT/` is missing or bootstrap is incomplete.
> - `$ssot-closeout` — before final response / `claim_done` / commit on a substantive change batch.
> - `$ssot-audit` — to catch up `tracked_commit` / `tracked_session` / `tracked_skill_version`.
> - `$ssot-doctor` — for health check, stop review, CORE-REF / ADAPTER / CONSUMPTION.

**zh**

> 本仓库已安装 SSOT Skill。`SSOT/` 是 Agent 长期记忆；代码 / schema / 测试仍是事实证据源。
> - `$ssot-preflight` — 实质性仓库任务开始前。
> - `$ssot-bootstrap` — `SSOT/` 缺失或 bootstrap 未完成时。
> - `$ssot-closeout` — 实质性变更批次的 final response / `claim_done` / commit 前。
> - `$ssot-audit` — 同步 `tracked_commit` / `tracked_session` / `tracked_skill_version`。
> - `$ssot-doctor` — 健康检查 / 停止审查 / CORE-REF / ADAPTER / CONSUMPTION。

If the file already references `$ssot-preflight` or `SSOT/`, update that block in place rather than duplicating. Do not modify unrelated sections.

## 5. Read the skill reference

Fetch and read [AGENTS.md](https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/AGENTS.md). It tells you when to invoke each of the six lifecycle skills (`$ssot-preflight`, `$ssot-bootstrap`, `$ssot-closeout`, `$ssot-audit`, `$ssot-doctor`, `$ssot-skill`).

## 6. Tell the user to restart you

The newly installed skills will not load in the current session. Tell the user:

> Bundle installed. Restart this agent session so the new skills are discovered.

After restart, the user can invoke `$ssot-preflight` before substantive work, or `$ssot-bootstrap` to create `SSOT/` if it's missing — but do not invoke those yourself now; wait for the user to call them post-restart.

## Notes

- If `--quickstart` autodetect fails (`agent autodetect failed`), pass `--agent <key>` explicitly. Run `bash install.sh --list-agents` to see canonical keys.
- The installer is idempotent — safe to re-run.
- For uninstall: `bash install.sh --uninstall --agent <key> --scope <global|project> --yes`.
- For upgrade-in-place (re-scan every location and reinstall): `bash install.sh --upgrade`.
