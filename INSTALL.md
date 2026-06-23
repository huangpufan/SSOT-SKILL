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

## 4. Read the skill reference

Fetch and read [AGENTS.md](https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/AGENTS.md). It tells you when to invoke each of the six lifecycle skills (`$ssot-preflight`, `$ssot-bootstrap`, `$ssot-closeout`, `$ssot-audit`, `$ssot-doctor`, `$ssot-skill`).

## 5. Tell the user to restart you

The newly installed skills will not load in the current session. Tell the user:

> Bundle installed. Restart this agent session so the new skills are discovered.

After restart, the user can invoke `$ssot-preflight` before substantive work, or `$ssot-bootstrap` to create `SSOT/` if it's missing — but do not invoke those yourself now; wait for the user to call them post-restart.

## Notes

- If `--quickstart` autodetect fails (`agent autodetect failed`), pass `--agent <key>` explicitly. Run `bash install.sh --list-agents` to see canonical keys.
- The installer is idempotent — safe to re-run.
- For uninstall: `bash install.sh --uninstall --agent <key> --scope <global|project> --yes`.
- For upgrade-in-place (re-scan every location and reinstall): `bash install.sh --upgrade`.
