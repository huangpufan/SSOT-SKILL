# Install Guide (Agent-facing)

Use this guide when a user asks you to install, reinstall, update, or remove SSOT Skill. Work in the **user's target repository**, preserve existing instructions, and respond in the user's language.

For a new installation, finish the setup: install the bundle, verify the installed files, and merge the lifecycle instructions. Skill discovery is confirmed only after the agent session restarts.

For an update or removal, resolve the choices and download the installer, then follow [the maintenance section](#update-or-remove-an-existing-installation) instead of running a fresh installation.

## 1. Resolve the installation choices

Honor options the user already supplied. Otherwise use these defaults without asking them to reconfirm:

- **Agent:** the coding agent you are currently running as. Pass its canonical installer key explicitly; a machine may have several agents installed.
- **Scope:** `project` by default; use `global` for an explicit global-only request. Install in both locations only when the user requests both. Run project commands from the target repository root.
- **Template language:** preserve an existing `SSOT/STATUS.md` documentation-language lock or the installed template language on reinstall. For a new setup, use `zh` when the user is communicating in Chinese, otherwise `en`. A template choice does not change an existing SSOT language lock.

If the target repository or agent identity cannot be determined from the current session, ask for that missing information. Routine defaults do not need a separate approval step.

Common keys and project locations:

| Current agent | Key | Project skills directory |
|---|---|---|
| Claude Code | `claude-code` | `.claude/skills/` |
| Codex | `codex` | `.agents/skills/` |
| Cursor | `cursor` | `.agents/skills/` |
| Windsurf | `windsurf` | `.windsurf/skills/` |
| Gemini CLI | `gemini-cli` | `.agents/skills/` |
| GitHub Copilot | `github-copilot` | `.agents/skills/` |

For other agents or global locations, use the installer's `--list-agents` output. Its registry is the authority for paths; respect configuration overrides shown there.

## 2. Install the bundle

Check that Bash 4+, `git`, `curl`, and `python3` are available. On macOS, the system Bash is too old. If Homebrew Bash is already installed, use `"$(brew --prefix)/bin/bash"`; otherwise explain the missing prerequisite and install it only within the user's authorization.

Download the installer to a temporary directory so a failed download cannot look like a successful installation. Replace the placeholder values with the choices resolved above, then run:

```bash
ssot_agent='<agent-key>'
ssot_template_lang='<en-or-zh>'
ssot_scope='<project-or-global>'
ssot_install_dir="$(mktemp -d)"
printf 'Installer directory: %s\n' "$ssot_install_dir"
if ! curl -fsSL --connect-timeout 10 --max-time 60 --retry 2 \
  https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/install.sh \
  -o "$ssot_install_dir/install.sh"; then
  printf 'Installer download failed; setup has not run.\n' >&2
  exit 1
fi
```

For an installation, run:

```bash
bash "$ssot_install_dir/install.sh" --quickstart \
  --agent "$ssot_agent" --scope "$ssot_scope" --lang "$ssot_template_lang"
```

Check the download and installer results separately. Retain the printed temporary path and resolved choices if subsequent steps run in a new shell. A download failure means nothing was installed; an installer failure must be resolved before continuing to verification or instruction wiring. Preserve stderr and report the specific failure.

If the download fails for network reasons, the existing mirror is:

```text
https://gh-proxy.com/https://raw.githubusercontent.com/huangpufan/SSOT-SKILL/main/install.sh
```

Retry the download using that URL, then run the same installer command. Do not treat invalid arguments, missing prerequisites, or verification failures as network problems.

If the user supplied a local SSOT-SKILL checkout, use its `install.sh` with `SOURCE_DIR` set to that checkout instead of downloading another copy. The installer normally fetches the current `main` bundle; `SOURCE_DIR` explicitly selects a local source.

If the user requested both scopes, run the installation once for each scope and verify both locations. Installation does not create or migrate the target repository's `SSOT/`.

## 3. Verify the installed bundle

Read the actual target path from installer output and check that location. Replace the placeholder below with it:

```bash
ssot_skills_dir='<installed-skills-directory>'
for ssot_skill in ssot-preflight ssot-bootstrap ssot-closeout ssot-audit ssot-doctor ssot-skill; do
  test -f "$ssot_skills_dir/$ssot_skill/SKILL.md" || exit 1
  test -f "$ssot_skills_dir/$ssot_skill/agents/openai.yaml" || exit 1
done
SSOT_TEST_PACKAGE_SHAPE_ONLY=1 \
  bash "$ssot_skills_dir/ssot-doctor/assets/scripts/test/run-tests.sh"
```

Also inspect the installed bootstrap templates: they should use the selected language directly under `ssot-bootstrap/assets/templates/`, without `en/` and `zh/` subdirectories. Read the installed `ssot-preflight/SKILL.md` `metadata.protocol_version` and include it in the result.

These checks verify the installation, not the health of the user's repository documentation. Do not run a full SSOT audit or bootstrap as part of installation unless the user requested that work.

## 4. Wire the skills into the repo's agent-instructions file

The installer prints the `SSOT-SKILL:BEGIN` / `SSOT-SKILL:END` block from the selected-language bootstrap `adapter-thin.md` template. That template is the shared source for installation and later bootstrap; the skill protocols own the detailed behavior. Merge the printed block into the target repository's existing instructions; discovery alone does not establish when a skill should run. A global-only installation without a target repository stops after verification and reports that each consuming repository still needs these instructions; it does not authorize editing global agent instructions.

Make clear that these are instructions for the agent: apply the skills automatically when their conditions match, without waiting for the user to name each skill. Users should be able to describe ordinary repository tasks after setup and restart. Explicit skill invocation remains an optional way to request a focused check or diagnose a missed trigger.

| Agent | Instruction entry |
|---|---|
| Claude Code | `CLAUDE.md` |
| Codex / OpenAI-style agents | `AGENTS.md` |
| Cursor | `.cursor/rules/ssot.mdc`, or the repository's existing `.cursorrules` |
| Windsurf | `.windsurf/rules/ssot.md`, or the repository's existing `.windsurfrules` |
| Gemini CLI | `GEMINI.md` |
| Other agents | Their supported repository-instruction entry |

Read existing instructions first. Follow any pointer or symlink to the repository's shared instruction owner, and update that one source. Keep one marked block in that owner so future updates can replace just this section. Reconcile older, unmarked SSOT instructions in place; preserve unrelated instructions and avoid duplicate blocks. Adapt the heading level if needed, preserving the routes and exceptions. Copy only the marked block from the template, not its whole-file `SSOT-generated` marker or project placeholders. When creating a tool-specific rules file, use that agent's supported activation format.

Before finishing, reread the resulting file and confirm it covers:

- automatic preflight and closeout for substantive work, with bootstrap, audit and doctor selected by their conditions;
- the skip cases for chat, pure command execution, and meaning-preserving typo/format edits, while explicit SSOT requests still route to a skill;
- loading the selected skill's full instructions, preserving its review gates, and reporting a missing skill honestly;
- preserving existing project rules, user decisions, and commit/push authorization.

Do not copy or apply SSOT-SKILL's own `AGENTS.md` to the user's repository. It governs maintenance of the bundle source, including its release and commit conventions.

## 5. Report the result and restart step

Remove the temporary installer directory you created after verification. Report:

- the installed version, agent, scope, target path, and template language;
- the instruction file updated, or why its existing block already suffices;
- which installed-file checks passed;
- that the user must restart the agent session to load the skills and repository instructions, then can describe tasks as usual.

Explain that the agent handles the lifecycle: preflight before substantive work, bootstrap when `SSOT/` is missing or unfinished, and closeout before finishing a substantive batch, with audit and doctor used when their conditions apply. Do not hand routine skill invocation back to the user as a manual checklist. Do not claim the skills are active before restart and discovery are confirmed. Do not ask the user to choose a global installation again after a successful project-only setup.

## Update or remove an existing installation

Resolve the target agent and scope as above. To update, use the downloaded installer:

```bash
# Update only the selected agent and scope.
# Omit --lang to preserve its installed template language.
bash "$ssot_install_dir/install.sh" --upgrade --agent "$ssot_agent" --scope "$ssot_scope"
```

To remove the installation instead:

```bash
bash "$ssot_install_dir/install.sh" --uninstall --agent "$ssot_agent" --scope "$ssot_scope" --yes
```

A scoped upgrade honors both `--agent` and `--scope`. Bare `--upgrade` scans every supported location in the current project and globally; use it only when that broader update was requested. Shared directories are updated once, and agents sharing a directory share the same installation.

After an update, repeat verification and reconcile the instruction block, then request a session restart. At the next substantive task, preflight checks the tracked protocol version and routes any required repository migration to `$ssot-audit`; installing new skill files alone does not migrate `SSOT/`.

After removal, verify the bundle files are absent. Preserve generated `SSOT/` documentation and unrelated skills. Reconcile obsolete trigger instructions with any remaining SSOT installation; the installer itself does not edit instruction files. Remove the temporary installer directory afterward.
