#!/usr/bin/env bash
# tests/test-installer-e2e.sh — end-to-end installer test
# Builds a fake $HOME, runs install.sh non-interactively, asserts artifacts.
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTALLER="$PROJECT_ROOT/install.sh"
PASS=0
FAIL=0
WORK_ROOT="$(mktemp -d)"
trap 'rm -rf "$WORK_ROOT"' EXIT

pass() { echo "  ok   : $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL : $1"; FAIL=$((FAIL+1)); }
assert_file() { [[ -f "$2" ]] && pass "$1" || fail "$1 (missing: $2)"; }
assert_dir() { [[ -d "$2" ]] && pass "$1" || fail "$1 (missing: $2)"; }
assert_no_dir() { [[ ! -d "$2" ]] && pass "$1" || fail "$1 (should not exist: $2)"; }
assert_grep() { grep -q "$3" "$2" 2>/dev/null && pass "$1" || fail "$1 (grep '$3' failed in $2)"; }
assert_no_grep() { ! grep -q "$3" "$2" 2>/dev/null && pass "$1" || fail "$1 (unexpected match '$3' in $2)"; }

echo "=== test-installer-e2e ==="

# Scenario 1: global install, en lang, all agents
SCENARIO1="$WORK_ROOT/scenario1"
mkdir -p "$SCENARIO1"
HOME="$SCENARIO1" SOURCE_DIR="$PROJECT_ROOT" \
  bash "$INSTALLER" --non-interactive --agent claude --scope global --lang en --yes \
  >/dev/null 2>&1 || fail "scenario1 install exit code"

CLAUDE_BASE="$SCENARIO1/.claude/skills"
assert_dir "scenario1: claude base created" "$CLAUDE_BASE"
for skill in ssot-preflight ssot-bootstrap ssot-closeout ssot-audit ssot-doctor ssot-skill; do
  assert_file "scenario1: $skill SKILL.md" "$CLAUDE_BASE/$skill/SKILL.md"
  assert_file "scenario1: $skill openai.yaml" "$CLAUDE_BASE/$skill/agents/openai.yaml"
done
assert_dir "scenario1: templates dir flattened" "$CLAUDE_BASE/ssot-bootstrap/assets/templates"
assert_no_dir "scenario1: no en/ subdir in installed templates" "$CLAUDE_BASE/ssot-bootstrap/assets/templates/en"
assert_no_dir "scenario1: no zh/ subdir in installed templates" "$CLAUDE_BASE/ssot-bootstrap/assets/templates/zh"
assert_file "scenario1: architecture-readme template present" "$CLAUDE_BASE/ssot-bootstrap/assets/templates/architecture-readme.md"
assert_file "scenario1: audit current-upgrade installed" "$CLAUDE_BASE/ssot-audit/references/current-upgrade.md"
assert_file "scenario1: audit archive index installed" "$CLAUDE_BASE/ssot-audit/references/archive/index.md"
# English-content check: should NOT contain CJK characters (python3 — macOS grep lacks -P)
if python3 -c "import sys,re; sys.exit(0 if re.search(r'[一-龥]', open(sys.argv[1], encoding='utf-8').read()) else 1)" "$CLAUDE_BASE/ssot-bootstrap/assets/templates/architecture-readme.md" 2>/dev/null; then
  fail "scenario1: en templates should not contain Chinese"
else
  pass "scenario1: en templates have no Chinese"
fi
assert_file "scenario1: ssot-lint.sh installed" "$CLAUDE_BASE/ssot-doctor/assets/scripts/ssot-lint.sh"

# Scenario 2: project install, zh lang, claude only
SCENARIO2="$WORK_ROOT/scenario2"
mkdir -p "$SCENARIO2/project"
HOME="$SCENARIO2" SOURCE_DIR="$PROJECT_ROOT" \
  bash -c "cd '$SCENARIO2/project' && bash '$INSTALLER' --non-interactive --agent claude --scope project --lang zh --yes" \
  >/dev/null 2>&1 || fail "scenario2 install exit code"
PROJ_BASE="$SCENARIO2/project/.claude/skills"
assert_dir "scenario2: project skills dir" "$PROJ_BASE"
assert_file "scenario2: ssot-preflight installed at project" "$PROJ_BASE/ssot-preflight/SKILL.md"
# zh templates: should contain CJK (use python3 — macOS grep lacks -P)
if python3 -c "import sys,re; sys.exit(0 if re.search(r'[一-龥]', open(sys.argv[1], encoding='utf-8').read()) else 1)" "$PROJ_BASE/ssot-bootstrap/assets/templates/architecture-readme.md" 2>/dev/null; then
  pass "scenario2: zh templates contain Chinese"
else
  fail "scenario2: zh templates expected Chinese content"
fi

# Scenario 3: multiple agents
SCENARIO3="$WORK_ROOT/scenario3"
mkdir -p "$SCENARIO3"
HOME="$SCENARIO3" SOURCE_DIR="$PROJECT_ROOT" \
  bash "$INSTALLER" --non-interactive --agent claude,codex --scope global --lang en --yes \
  >/dev/null 2>&1 || fail "scenario3 multi-agent install exit code"
assert_file "scenario3: claude installed" "$SCENARIO3/.claude/skills/ssot-preflight/SKILL.md"
assert_file "scenario3: codex installed" "$SCENARIO3/.codex/skills/ssot-preflight/SKILL.md"

# Scenario 4: upgrade scans and re-installs
SCENARIO4="$WORK_ROOT/scenario4"
mkdir -p "$SCENARIO4"
HOME="$SCENARIO4" SOURCE_DIR="$PROJECT_ROOT" \
  bash "$INSTALLER" --non-interactive --agent claude --scope global --lang en --yes >/dev/null 2>&1
# Touch a sentinel to ensure overwrite happens
echo "OLD" > "$SCENARIO4/.claude/skills/ssot-preflight/SENTINEL"
HOME="$SCENARIO4" SOURCE_DIR="$PROJECT_ROOT" \
  bash "$INSTALLER" --upgrade >/dev/null 2>&1 || fail "scenario4 upgrade exit code"
# SKILL.md should still exist after upgrade
assert_file "scenario4: SKILL.md after upgrade" "$SCENARIO4/.claude/skills/ssot-preflight/SKILL.md"

# Scenario 5: uninstall
SCENARIO5="$WORK_ROOT/scenario5"
mkdir -p "$SCENARIO5"
HOME="$SCENARIO5" SOURCE_DIR="$PROJECT_ROOT" \
  bash "$INSTALLER" --non-interactive --agent claude --scope global --lang en --yes >/dev/null 2>&1
assert_file "scenario5: pre-uninstall SKILL.md exists" "$SCENARIO5/.claude/skills/ssot-preflight/SKILL.md"
HOME="$SCENARIO5" SOURCE_DIR="$PROJECT_ROOT" \
  bash "$INSTALLER" --uninstall --agent claude --scope global --yes >/dev/null 2>&1 || fail "scenario5 uninstall exit code"
assert_no_dir "scenario5: ssot-preflight removed" "$SCENARIO5/.claude/skills/ssot-preflight"
assert_no_dir "scenario5: ssot-skill removed" "$SCENARIO5/.claude/skills/ssot-skill"
assert_dir "scenario5: base skills dir preserved" "$SCENARIO5/.claude/skills"

# Scenario 6: --version
VERSION_OUTPUT="$(bash "$INSTALLER" --version 2>&1)"
EXPECTED_VERSION="$(cat "$PROJECT_ROOT/VERSION" 2>/dev/null | tr -d '[:space:]')"
if [[ -n "$EXPECTED_VERSION" && "$VERSION_OUTPUT" == *"$EXPECTED_VERSION"* ]]; then
  pass "scenario6: --version prints $EXPECTED_VERSION"
else
  fail "scenario6: --version output ('$VERSION_OUTPUT')"
fi

# Scenario 7: --help
HELP_OUTPUT="$(bash "$INSTALLER" --help 2>&1)"
if [[ "$HELP_OUTPUT" == *"USAGE"* || "$HELP_OUTPUT" == *"usage"* ]]; then
  pass "scenario7: --help has USAGE section"
else
  fail "scenario7: --help missing USAGE"
fi

# Scenario 8: non-interactive missing args should fail
SCENARIO8_OUT="$(SSOT_NONINTERACTIVE=1 bash "$INSTALLER" 2>&1)"
SCENARIO8_RC=$?
if [[ $SCENARIO8_RC -ne 0 ]]; then
  pass "scenario8: non-interactive without args exits non-zero"
else
  fail "scenario8: non-interactive should fail without args"
fi

# Scenario 9: legacy alias --agent claude resolves to claude-code
SCENARIO9="$WORK_ROOT/scenario9"
mkdir -p "$SCENARIO9/project"
HOME="$SCENARIO9" SOURCE_DIR="$PROJECT_ROOT" \
  bash -c "cd '$SCENARIO9/project' && bash '$INSTALLER' --non-interactive --agent claude --scope project --lang en --yes" \
  >/dev/null 2>&1 || fail "scenario9 alias install exit code"
assert_file "scenario9: alias claude resolved to claude-code → .claude/skills" "$SCENARIO9/project/.claude/skills/ssot-preflight/SKILL.md"

# Scenario 10: install new Vercel-aligned agent (gemini-cli → .agents/skills)
SCENARIO10="$WORK_ROOT/scenario10"
mkdir -p "$SCENARIO10/project"
HOME="$SCENARIO10" SOURCE_DIR="$PROJECT_ROOT" \
  bash -c "cd '$SCENARIO10/project' && bash '$INSTALLER' --non-interactive --agent gemini-cli --scope project --lang en --yes" \
  >/dev/null 2>&1 || fail "scenario10 gemini-cli install exit code"
assert_file "scenario10: gemini-cli project install at .agents/skills" "$SCENARIO10/project/.agents/skills/ssot-preflight/SKILL.md"

# Scenario 11: dedup for agents sharing the same install path
SCENARIO11="$WORK_ROOT/scenario11"
mkdir -p "$SCENARIO11/project"
SCEN11_LOG="$(HOME="$SCENARIO11" SOURCE_DIR="$PROJECT_ROOT" \
  bash -c "cd '$SCENARIO11/project' && bash '$INSTALLER' --non-interactive --agent cline,dexto,loaf --scope project --lang en --yes" 2>&1)"
assert_file "scenario11: dedup installs once at shared path" "$SCENARIO11/project/.agents/skills/ssot-preflight/SKILL.md"
if echo "$SCEN11_LOG" | grep -qi "skipping"; then
  pass "scenario11: dedup warning emitted"
else
  fail "scenario11: expected 'skipping' dedup warning"
fi

# Scenario 12: --list-agents prints 65+ agents including claude-code and gemini-cli
LIST_OUTPUT="$(bash "$INSTALLER" --list-agents 2>&1)"
LIST_COUNT="$(echo "$LIST_OUTPUT" | grep -cE '^  [a-z][a-z0-9_-]+ +' || echo 0)"
if [[ "$LIST_COUNT" -ge 60 ]]; then
  pass "scenario12: --list-agents prints $LIST_COUNT agents (>=60)"
else
  fail "scenario12: --list-agents printed $LIST_COUNT agents (expected >=60)"
fi
if echo "$LIST_OUTPUT" | grep -qE '^  claude-code '; then
  pass "scenario12: --list-agents includes claude-code"
else
  fail "scenario12: --list-agents missing claude-code"
fi
if echo "$LIST_OUTPUT" | grep -qE '^  gemini-cli '; then
  pass "scenario12: --list-agents includes gemini-cli"
else
  fail "scenario12: --list-agents missing gemini-cli"
fi

# Scenario 13: promptscript has no global install location — must fail loudly
SCENARIO13="$WORK_ROOT/scenario13"
mkdir -p "$SCENARIO13"
HOME="$SCENARIO13" SOURCE_DIR="$PROJECT_ROOT" \
  bash "$INSTALLER" --non-interactive --agent promptscript --scope global --lang en --yes \
  >/dev/null 2>&1
SCEN13_RC=$?
if [[ $SCEN13_RC -ne 0 ]]; then
  pass "scenario13: promptscript global install exits non-zero"
else
  fail "scenario13: promptscript global install should fail"
fi

# Scenario 14: --quickstart with SSOT_AGENT env autodetect → project install
SCENARIO14="$WORK_ROOT/scenario14"
mkdir -p "$SCENARIO14/project"
SCEN14_LOG="$(HOME="$SCENARIO14" SOURCE_DIR="$PROJECT_ROOT" SSOT_AGENT=claude-code \
  bash -c "cd '$SCENARIO14/project' && bash '$INSTALLER' --quickstart" 2>&1)"
SCEN14_RC=$?
if [[ $SCEN14_RC -eq 0 ]]; then
  pass "scenario14: --quickstart with SSOT_AGENT=claude-code exits 0"
else
  fail "scenario14: --quickstart exit code ($SCEN14_RC); log: $SCEN14_LOG"
fi
assert_file "scenario14: project install landed at .claude/skills" "$SCENARIO14/project/.claude/skills/ssot-preflight/SKILL.md"
assert_file "scenario14: ssot-skill shim installed too" "$SCENARIO14/project/.claude/skills/ssot-skill/SKILL.md"
if echo "$SCEN14_LOG" | grep -q "also install globally"; then
  pass "scenario14: post-install prints global install hint"
else
  fail "scenario14: missing 'also install globally' hint"
fi

# Scenario 15: --quickstart with CLAUDECODE=1 signature env (no SSOT_AGENT)
SCENARIO15="$WORK_ROOT/scenario15"
mkdir -p "$SCENARIO15/project"
SCEN15_LOG="$(HOME="$SCENARIO15" SOURCE_DIR="$PROJECT_ROOT" CLAUDECODE=1 \
  bash -c "unset SSOT_AGENT; cd '$SCENARIO15/project' && bash '$INSTALLER' --quickstart" 2>&1)"
SCEN15_RC=$?
if [[ $SCEN15_RC -eq 0 ]]; then
  pass "scenario15: --quickstart with CLAUDECODE=1 exits 0"
else
  fail "scenario15: --quickstart exit code ($SCEN15_RC); log: $SCEN15_LOG"
fi
assert_file "scenario15: project install landed at .claude/skills via CLAUDECODE=1" "$SCENARIO15/project/.claude/skills/ssot-preflight/SKILL.md"

# Scenario 16: --quickstart --scope global → global install, no project hint
SCENARIO16="$WORK_ROOT/scenario16"
mkdir -p "$SCENARIO16"
SCEN16_LOG="$(HOME="$SCENARIO16" SOURCE_DIR="$PROJECT_ROOT" SSOT_AGENT=claude-code \
  bash "$INSTALLER" --quickstart --scope global 2>&1)"
SCEN16_RC=$?
if [[ $SCEN16_RC -eq 0 ]]; then
  pass "scenario16: --quickstart --scope global exits 0"
else
  fail "scenario16: --quickstart --scope global exit code ($SCEN16_RC); log: $SCEN16_LOG"
fi
assert_file "scenario16: global install landed at \$HOME/.claude/skills" "$SCENARIO16/.claude/skills/ssot-preflight/SKILL.md"
if echo "$SCEN16_LOG" | grep -q "also install globally"; then
  fail "scenario16: global scope should NOT print 'also install globally' hint"
else
  pass "scenario16: global scope omits project-only hint"
fi

# Scenario 17: no tty + no flag → actionable die message
SCENARIO17="$WORK_ROOT/scenario17"
mkdir -p "$SCENARIO17/project"
# Closing stdin (< /dev/null) AND running outside a tty simulates curl|bash without /dev/tty.
SCEN17_LOG="$(HOME="$SCENARIO17" SOURCE_DIR="$PROJECT_ROOT" \
  bash -c "cd '$SCENARIO17/project' && bash '$INSTALLER' < /dev/null" 2>&1)"
SCEN17_RC=$?
if [[ $SCEN17_RC -ne 0 ]]; then
  pass "scenario17: no-tty no-flag invocation exits non-zero"
else
  fail "scenario17: should fail without flags + no tty"
fi
if echo "$SCEN17_LOG" | grep -q "no tty available"; then
  pass "scenario17: error mentions 'no tty available'"
else
  fail "scenario17: missing 'no tty available' in error; log: $SCEN17_LOG"
fi
if echo "$SCEN17_LOG" | grep -q -- "--quickstart"; then
  pass "scenario17: error suggests --quickstart"
else
  fail "scenario17: missing --quickstart suggestion; log: $SCEN17_LOG"
fi
if echo "$SCEN17_LOG" | grep -q -- "--agent"; then
  pass "scenario17: error suggests --agent"
else
  fail "scenario17: missing --agent suggestion; log: $SCEN17_LOG"
fi

echo
echo "=== RESULT: pass=$PASS fail=$FAIL ==="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
