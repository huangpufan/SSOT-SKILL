#!/usr/bin/env bash
# tests/test-bundle-shape.sh — bundle structure & link integrity
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0
pass() { echo "  ok   : $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL : $1"; FAIL=$((FAIL+1)); }

echo "=== test-bundle-shape ==="

# 1. VERSION file
if [[ -f "$PROJECT_ROOT/VERSION" ]]; then
  pass "VERSION file exists"
  VERSION_CONTENT="$(cat "$PROJECT_ROOT/VERSION" | tr -d '[:space:]')"
  if [[ -n "$VERSION_CONTENT" ]]; then
    pass "VERSION file non-empty: $VERSION_CONTENT"
  else
    fail "VERSION file empty"
  fi
else
  fail "VERSION file missing"
  VERSION_CONTENT=""
fi

# 2. protocol_version in ssot-preflight/SKILL.md matches VERSION
PREFLIGHT_VERSION="$(grep -E '^\s*protocol_version:' "$PROJECT_ROOT/skills/ssot-preflight/SKILL.md" 2>/dev/null | head -1 | sed -E 's/.*protocol_version:[[:space:]]*"?([^"]+)"?.*/\1/' | tr -d '[:space:]')"
if [[ "$PREFLIGHT_VERSION" == "$VERSION_CONTENT" ]]; then
  pass "ssot-preflight protocol_version matches VERSION ($PREFLIGHT_VERSION)"
else
  fail "ssot-preflight protocol_version='$PREFLIGHT_VERSION' != VERSION='$VERSION_CONTENT'"
fi

# 3. Each skill has SKILL.md with name + description frontmatter
SKILLS=(ssot-preflight ssot-bootstrap ssot-closeout ssot-audit ssot-doctor ssot-skill)
for skill in "${SKILLS[@]}"; do
  SKILL_MD="$PROJECT_ROOT/skills/$skill/SKILL.md"
  if [[ ! -f "$SKILL_MD" ]]; then
    fail "$skill: SKILL.md missing"
    continue
  fi
  if grep -qE '^name:[[:space:]]*'"$skill" "$SKILL_MD"; then
    pass "$skill: name matches dir"
  else
    fail "$skill: name field missing or mismatched"
  fi
  if grep -qE '^description:' "$SKILL_MD"; then
    pass "$skill: description present"
  else
    fail "$skill: description missing"
  fi
done

# 4. Each skill has agents/openai.yaml
for skill in "${SKILLS[@]}"; do
  YAML="$PROJECT_ROOT/skills/$skill/agents/openai.yaml"
  if [[ -f "$YAML" ]]; then
    pass "$skill: openai.yaml exists"
  else
    fail "$skill: openai.yaml missing"
  fi
done

# 5. Cross-skill relative link validity in SKILL.md + references/*.md
# Find all "(../some/path.md)" or "[text](../path)" patterns and resolve.
# Links inside fenced code blocks (```...```) are skipped — they are
# examples, not real cross-references.
check_links_in() {
  local file="$1"
  local file_dir
  file_dir="$(dirname "$file")"
  # Strip fenced code blocks before extracting links
  local stripped
  stripped="$(awk 'BEGIN{infence=0} /^```/{infence=!infence; next} !infence' "$file")"
  # Extract markdown link targets ending in .md or .sh
  printf '%s\n' "$stripped" | grep -oE '\]\([^)]+\.(md|sh)\)' 2>/dev/null | sed -E 's/^\]\(([^)]+)\)$/\1/' | while read -r target; do
    # Strip anchor and query
    local clean_target="${target%%#*}"
    clean_target="${clean_target%%\?*}"
    [[ -z "$clean_target" ]] && continue
    # Skip absolute http(s) links
    [[ "$clean_target" =~ ^https?:// ]] && continue
    # Resolve relative to file_dir (portable: readlink -f is GNU-only, use python3)
    local resolved
    resolved="$(cd "$file_dir" 2>/dev/null && python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$clean_target" 2>/dev/null || true)"
    if [[ -z "$resolved" || ! -e "$resolved" ]]; then
      echo "  FAIL : link broken in ${file#"$PROJECT_ROOT"/}: $clean_target"
      return 1
    fi
  done
  return 0
}

LINK_FAILS=0
while IFS= read -r f; do
  if ! check_links_in "$f"; then
    LINK_FAILS=$((LINK_FAILS+1))
  fi
done < <(find "$PROJECT_ROOT/skills" -type f \( -name "SKILL.md" -o -name "*.md" -path "*/references/*" \))
if [[ $LINK_FAILS -eq 0 ]]; then
  pass "all cross-skill markdown links resolve"
else
  fail "$LINK_FAILS file(s) had broken cross-skill links"
fi

# 6. templates en/zh parity
TPL_DIR="$PROJECT_ROOT/skills/ssot-bootstrap/assets/templates"
if [[ -d "$TPL_DIR/en" && -d "$TPL_DIR/zh" ]]; then
  EN_FILES="$(cd "$TPL_DIR/en" && ls *.md 2>/dev/null | sort)"
  ZH_FILES="$(cd "$TPL_DIR/zh" && ls *.md 2>/dev/null | sort)"
  if [[ "$EN_FILES" == "$ZH_FILES" ]]; then
    pass "templates en/zh file parity"
  else
    fail "templates en/zh diverge"
    echo "    en-only: $(comm -23 <(echo "$EN_FILES") <(echo "$ZH_FILES"))"
    echo "    zh-only: $(comm -13 <(echo "$EN_FILES") <(echo "$ZH_FILES"))"
  fi
  # Should not have stray .md files at templates root
  STRAY="$(find "$TPL_DIR" -maxdepth 1 -name "*.md" -type f 2>/dev/null)"
  if [[ -z "$STRAY" ]]; then
    pass "no stray .md at templates root"
  else
    fail "stray templates at root: $STRAY"
  fi
else
  fail "templates en/ and zh/ dirs not both present"
fi

# 6b. Protocol-upgrade ledger layering
AUDIT_REF="$PROJECT_ROOT/skills/ssot-audit/references"
CURRENT_UPGRADE="$AUDIT_REF/current-upgrade.md"
ARCHIVE_INDEX="$AUDIT_REF/archive/index.md"
ARCHIVE_2234="$AUDIT_REF/archive/v2.22-v2.34.md"
ARCHIVE_0621="$AUDIT_REF/archive/v2.6-v2.21.md"
if [[ -f "$CURRENT_UPGRADE" && -f "$ARCHIVE_INDEX" && -f "$ARCHIVE_2234" && -f "$ARCHIVE_0621" ]]; then
  pass "protocol upgrade current/archive files exist"
else
  fail "protocol upgrade current/archive files missing"
fi
if [[ -f "$CURRENT_UPGRADE" && -n "$VERSION_CONTENT" ]]; then
  CURRENT_HEADING_COUNT="$(grep -cE "^### v${VERSION_CONTENT}$" "$CURRENT_UPGRADE" 2>/dev/null || true)"
  if [[ "$CURRENT_HEADING_COUNT" == "1" ]]; then
    pass "current-upgrade has exactly one current version heading"
  else
    fail "current-upgrade current version heading count=$CURRENT_HEADING_COUNT for v$VERSION_CONTENT"
  fi
fi
if grep -qE '^### v[0-9]' "$AUDIT_REF/protocol-upgrades.md" 2>/dev/null; then
  fail "protocol-upgrades router contains bulk version headings"
else
  pass "protocol-upgrades router has no bulk version headings"
fi
if [[ -f "$CURRENT_UPGRADE" && -d "$AUDIT_REF/archive" ]]; then
  DUP_HEADINGS="$(grep -hE '^### v[0-9]' "$CURRENT_UPGRADE" "$AUDIT_REF"/archive/*.md 2>/dev/null | sort | uniq -d)"
  if [[ -z "$DUP_HEADINGS" ]]; then
    pass "protocol version headings unique across current/archive"
  else
    fail "duplicate protocol version headings: $DUP_HEADINGS"
  fi
fi

# 7. No Chinese in SKILL.md or references (now should be all English).
# Chinese inside inline-code spans (`...`) is allowed: those are protocol
# string literals (canonical heading names, enum values) that must stay
# verbatim and are not prose.
CN_FILES=()
while IFS= read -r f; do
  # Strip inline code spans before checking for Chinese (python3 — macOS grep lacks -P)
  stripped="$(sed 's/`[^`]*`//g' "$f")"
  if printf '%s' "$stripped" | python3 -c "import sys,re; sys.exit(0 if re.search(r'[一-龥]', sys.stdin.read()) else 1)" 2>/dev/null; then
    CN_FILES+=("${f#"$PROJECT_ROOT"/}")
  fi
done < <(find "$PROJECT_ROOT/skills" -type f \( -name "SKILL.md" -o -path "*/references/*.md" \))
if [[ ${#CN_FILES[@]} -eq 0 ]]; then
  pass "no Chinese in SKILL.md / references/"
else
  fail "Chinese remains in: ${CN_FILES[*]}"
fi

# 8. Markdown fenced code blocks must be balanced in shipped Markdown.
FENCE_FAILS=()
while IFS= read -r f; do
  unclosed_line="$(awk '
    /^```/ {
      if (!in_fence) { in_fence=1; start=FNR }
      else { in_fence=0; start=0 }
    }
    END { if (in_fence) print start }
  ' "$f")"
  if [[ -n "$unclosed_line" ]]; then
    FENCE_FAILS+=("${f#"$PROJECT_ROOT"/}:$unclosed_line")
  fi
done < <(find "$PROJECT_ROOT" \
  -path "$PROJECT_ROOT/.git" -prune -o \
  -type f -name '*.md' -print)
if [[ ${#FENCE_FAILS[@]} -eq 0 ]]; then
  pass "all shipped Markdown fences close"
else
  fail "unclosed Markdown fences: ${FENCE_FAILS[*]}"
fi

# 9. Public OSS hygiene: no local-machine paths, origin-project paths/names,
# or real commit SHAs in shipped protocol/templates/tests.
HYGIENE_FILES=()
HOME_PATH_PATTERN="$(printf '/%s/[^\\\\`[:space:]]+' 'home')"
USERS_PATH_PATTERN="$(printf '/%s/[^\\\\`[:space:]]+' 'Users')"
ORIGIN_NAME="$(printf 'sisy%s' 'phus')"
ORIGIN_SRC_PATH="src/${ORIGIN_NAME}"
ORIGIN_FRONTEND_PATH="$(printf 'frontend/src/components/%s' 'tasks')"
REAL_SHA_PATTERN="[0-9a-f]{40}"
HYGIENE_PATTERN="(${HOME_PATH_PATTERN}|${USERS_PATH_PATTERN}|${ORIGIN_SRC_PATH}|${ORIGIN_FRONTEND_PATH}|${ORIGIN_NAME}|${REAL_SHA_PATTERN})"
while IFS= read -r f; do
  if grep -nE "$HYGIENE_PATTERN" "$f" >/dev/null 2>&1; then
    HYGIENE_FILES+=("${f#"$PROJECT_ROOT"/}")
  fi
done < <(find "$PROJECT_ROOT" \
  -path "$PROJECT_ROOT/.git" -prune -o \
  -path "$PROJECT_ROOT/CHANGELOG.md" -prune -o \
  -type f \( -name '*.md' -o -name '*.sh' -o -name '*.yaml' -o -name '*.yml' \) -print)
if [[ ${#HYGIENE_FILES[@]} -eq 0 ]]; then
  pass "public assets avoid local/origin-project leakage"
else
  fail "public hygiene leakage in: ${HYGIENE_FILES[*]}"
fi

echo
echo "=== RESULT: pass=$PASS fail=$FAIL ==="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
