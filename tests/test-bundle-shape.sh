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

# 3b. Non-router SKILL bodies stay as activation prompts. Detailed manuals
# belong in references; ssot-preflight alone owns the bundle routing exception.
for skill in ssot-bootstrap ssot-closeout ssot-audit ssot-doctor ssot-skill; do
  SKILL_MD="$PROJECT_ROOT/skills/$skill/SKILL.md"
  BODY="$(awk 'BEGIN{fences=0} /^---[[:space:]]*$/{fences++;next} fences>=2{print}' "$SKILL_MD")"
  BODY_WORDS="$(printf '%s\n' "$BODY" | wc -w | tr -d '[:space:]')"
  if [[ "$BODY_WORDS" -le 60 ]]; then
    pass "$skill: SKILL.md body stays within the 60-word activation budget ($BODY_WORDS)"
  else
    fail "$skill: SKILL.md body exceeds the 60-word activation budget ($BODY_WORDS)"
  fi
  if printf '%s\n' "$BODY" | grep -qE '^\|'; then
    fail "$skill: SKILL.md body contains a routing/manual table"
  else
    pass "$skill: SKILL.md body delegates detailed routing to references"
  fi
done

# 3c. STATUS has one reader-facing name. Historical CHANGELOG/archive entries
# may preserve old language, but active protocol and shipped surfaces may not
# invent synonyms for the same tracking-baseline concept.
BASELINE_OWNER="$PROJECT_ROOT/skills/ssot-preflight/references/status-protocol.md"
if grep -qF 'The canonical reader-facing name is **tracking baseline**' "$BASELINE_OWNER" &&
   grep -qF '“追踪基线”' "$PROJECT_ROOT/skills/ssot-bootstrap/assets/templates/zh/ssot-readme.md"; then
  pass "status-protocol owns the canonical tracking-baseline name"
else
  fail "status-protocol does not own the canonical tracking-baseline name"
fi
BASELINE_SYNONYM_HITS="$({
  printf '%s\n' "$PROJECT_ROOT/AGENTS.md" "$PROJECT_ROOT/README.md" "$PROJECT_ROOT/README.zh.md"
  find "$PROJECT_ROOT/skills" -type f ! -path '*/references/archive/*' ! -name 'CHANGELOG.md' -print
} | xargs rg -n -i 'waterline|coverage baseline|coverage baselines|事实覆盖基线|覆盖基线' 2>/dev/null || true)"
if [[ -z "$BASELINE_SYNONYM_HITS" ]]; then
  pass "active protocol and shipped surfaces use only tracking baseline / 追踪基线"
else
  fail "active protocol or shipped surface forks the tracking-baseline vocabulary"
  printf '%s\n' "$BASELINE_SYNONYM_HITS"
fi

# 4. Each skill has agents/openai.yaml
for skill in "${SKILLS[@]}"; do
  YAML="$PROJECT_ROOT/skills/$skill/agents/openai.yaml"
  if [[ -f "$YAML" ]]; then
    pass "$skill: openai.yaml exists"
  else
    fail "$skill: openai.yaml missing"
  fi
done

# 4b. Protocol-upgrade migration helper exists and is syntactically valid.
MIGRATION_HELPER="$PROJECT_ROOT/skills/ssot-audit/assets/scripts/migrate-faceted-layout.py"
if [[ -f "$MIGRATION_HELPER" ]]; then
  pass "ssot-audit faceted-layout migration helper exists"
  if python3 -c 'import ast, pathlib, sys; path = pathlib.Path(sys.argv[1]); ast.parse(path.read_text(encoding="utf-8"), filename=str(path))' "$MIGRATION_HELPER" >/dev/null 2>&1; then
    pass "ssot-audit faceted-layout migration helper syntax parses without bytecode"
  else
    fail "ssot-audit faceted-layout migration helper does not parse"
  fi
else
  fail "ssot-audit faceted-layout migration helper missing"
fi

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

  # Authoring-only reader guidance is allowed in template comments, but the
  # same template pairs must carry it in both shipped languages.
  EN_AUTHORING_NOTES="$(rg -l 'Writing style:|Reader profile authority:' "$TPL_DIR/en"/*.md 2>/dev/null | xargs -r -n1 basename | sort)"
  ZH_AUTHORING_NOTES="$(rg -l '行文风格：|行文对象：|写作对象(默认)?(是|：)|写作姿态：|读者画像权威：' "$TPL_DIR/zh"/*.md 2>/dev/null | xargs -r -n1 basename | sort)"
  if [[ "$EN_AUTHORING_NOTES" == "$ZH_AUTHORING_NOTES" ]]; then
    pass "template authoring-note en/zh file parity"
  else
    fail "template authoring-note en/zh file parity diverges"
    echo "    en-only: $(comm -23 <(printf '%s\n' "$EN_AUTHORING_NOTES") <(printf '%s\n' "$ZH_AUTHORING_NOTES"))"
    echo "    zh-only: $(comm -13 <(printf '%s\n' "$EN_AUTHORING_NOTES") <(printf '%s\n' "$ZH_AUTHORING_NOTES"))"
  fi
else
  fail "templates en/ and zh/ dirs not both present"
fi

# 6a. Current protocol and rendered templates use the numbered
# faceted layout. Unnumbered paths are permitted only where protocol prose
# explicitly labels them as legacy, migration input, deprecated, or archived.
CURRENT_PATH_FILES=(
  "$PROJECT_ROOT/skills/ssot-preflight/SKILL.md"
  "$PROJECT_ROOT/skills/ssot-preflight/references/architecture.md"
  "$PROJECT_ROOT/skills/ssot-preflight/references/source-material.md"
  "$PROJECT_ROOT/skills/ssot-bootstrap/references/bootstrap.md"
  "$PROJECT_ROOT/skills/ssot-bootstrap/references/formatting-conventions.md"
  "$PROJECT_ROOT/skills/ssot-bootstrap/references/templates-index.md"
)
STALE_PATH_PATTERN='SSOT/(product|architecture|development|testing|benchmark|deployment|release|decisions|gotchas|bugs|tech-debt|research)/|`(product|architecture|development|testing|benchmark|deployment|release|decisions|gotchas|bugs|tech-debt|research)/|^[[:space:]]+(product|architecture|development|testing|benchmark|deployment|release|decisions|gotchas|bugs|tech-debt|research)/|02-architecture/(domains|<domain>)/'
LEGACY_CONTEXT_PATTERN='legacy|migration input|migrat(e|ion)|deprecated|obsolete|archive|unnumbered|do not (add|create|use)|must not (add|create|use)'
PATH_HYGIENE_FAILS=()
for f in "${CURRENT_PATH_FILES[@]}"; do
  while IFS= read -r hit; do
    [[ -z "$hit" ]] && continue
    if ! grep -qiE "$LEGACY_CONTEXT_PATTERN" <<<"$hit"; then
      PATH_HYGIENE_FAILS+=("${f#"$PROJECT_ROOT/"}:$hit")
    fi
  done < <(grep -nE "$STALE_PATH_PATTERN" "$f" 2>/dev/null || true)
done
while IFS= read -r f; do
  while IFS= read -r hit; do
    [[ -z "$hit" ]] && continue
    PATH_HYGIENE_FAILS+=("${f#"$PROJECT_ROOT/"}:$hit")
  done < <(grep -nE "$STALE_PATH_PATTERN" "$f" 2>/dev/null || true)
done < <(find "$TPL_DIR/en" "$TPL_DIR/zh" -maxdepth 1 -type f -name '*.md' -print)
if [[ ${#PATH_HYGIENE_FAILS[@]} -eq 0 ]]; then
  pass "current protocol/templates use canonical numbered SSOT paths"
else
  fail "current protocol/templates contain unnumbered concrete SSOT paths"
  printf '    %s\n' "${PATH_HYGIENE_FAILS[@]}"
fi

# Root Reader Map links must route into the canonical facets, and architecture
# domains are direct numbered children rather than an intermediate domains/ tree.
ROOT_LINK_FAILS=()
for lang in en zh; do
  ROOT_TEMPLATE="$TPL_DIR/$lang/ssot-readme.md"
  grep -qF '(./01-product/README.md)' "$ROOT_TEMPLATE" || ROOT_LINK_FAILS+=("$lang root product link")
  grep -qF '(./02-architecture/README.md)' "$ROOT_TEMPLATE" || ROOT_LINK_FAILS+=("$lang root architecture link")
  grep -qF '(../02-architecture/README.md)' "$TPL_DIR/$lang/product-prd.md" || ROOT_LINK_FAILS+=("$lang product-to-architecture link")
  grep -qF '(../../02-architecture/README.md)' "$TPL_DIR/$lang/product-capabilities-readme.md" || ROOT_LINK_FAILS+=("$lang capability-to-architecture link")
  grep -qF '(../../02-architecture/views/critical-journeys.md)' "$TPL_DIR/$lang/product-journeys-readme.md" || ROOT_LINK_FAILS+=("$lang journey-to-architecture link")
  grep -qF '`../../01-product/roadmap-and-acceptance.md`' "$TPL_DIR/$lang/architecture-view-current-target-gap.md" || ROOT_LINK_FAILS+=("$lang architecture-to-product link")
  grep -qF 'SSOT/02-architecture/NN-<domain>/README.md' "$TPL_DIR/$lang/research-entry.md" || ROOT_LINK_FAILS+=("$lang research promotion target")
  if grep -qE '02-architecture/domains/|02-architecture/<domain>|\./domains/' "$TPL_DIR/$lang/architecture-readme.md"; then
    ROOT_LINK_FAILS+=("$lang architecture domains are not direct numbered children")
  fi
  for manifest_template in product-root-manifest.md product-collection-manifest.md architecture-root-manifest.md architecture-views-manifest.md architecture-domain-manifest.md; do
    if [[ ! -f "$TPL_DIR/$lang/$manifest_template" ]]; then
      ROOT_LINK_FAILS+=("$lang missing $manifest_template")
    elif grep -qE '\| v2\.[0-9]+ \| 20[0-9]{2}-[0-9]{2} \|' "$TPL_DIR/$lang/$manifest_template"; then
      ROOT_LINK_FAILS+=("$lang $manifest_template hard-codes a protocol/date")
    fi
  done
  [[ ! -f "$TPL_DIR/$lang/_manifest.md" ]] || ROOT_LINK_FAILS+=("$lang still ships universal _manifest.md")
done
if [[ ${#ROOT_LINK_FAILS[@]} -eq 0 ]]; then
  pass "root links and direct numbered architecture-domain paths are canonical"
else
  fail "root/domain canonical link contract failed: ${ROOT_LINK_FAILS[*]}"
fi

# templates-index.md is the complete public inventory, not a hand-maintained
# subset: each template filename appears exactly once and no unknown row exists.
TEMPLATE_INDEX="$PROJECT_ROOT/skills/ssot-bootstrap/references/templates-index.md"
ACTUAL_TEMPLATE_NAMES="$(find "$TPL_DIR/en" -maxdepth 1 -type f -name '*.md' -exec basename {} \; | sort)"
INDEXED_TEMPLATE_NAMES="$(sed -nE 's/^\| `([^`]+\.md)` \|.*$/\1/p' "$TEMPLATE_INDEX" | sort)"
if [[ "$ACTUAL_TEMPLATE_NAMES" == "$INDEXED_TEMPLATE_NAMES" ]]; then
  pass "templates index completely matches shipped templates"
else
  fail "templates index does not match shipped templates"
  echo "    missing from index: $(comm -23 <(printf '%s\n' "$ACTUAL_TEMPLATE_NAMES") <(printf '%s\n' "$INDEXED_TEMPLATE_NAMES") | tr '\n' ' ')"
  echo "    unknown in index: $(comm -13 <(printf '%s\n' "$ACTUAL_TEMPLATE_NAMES") <(printf '%s\n' "$INDEXED_TEMPLATE_NAMES") | tr '\n' ' ')"
fi

# 6b. Process/records/glossary use dedicated bilingual templates and Phase 1
# wires only their roots/indexes. Entry templates remain event-driven.
SPECIALIZED_TEMPLATES=(
  process-readme.md
  deployment-readme.md
  operations-readme.md
  security-and-compliance-readme.md
  records-readme.md
  glossary-readme.md
  gotchas-readme.md
  gotcha-entry.md
  bugs-readme.md
  bug-entry.md
  tech-debt-readme.md
  tech-debt-entry.md
)
SPECIALIZED_TEMPLATE_FAILS=()
for template in "${SPECIALIZED_TEMPLATES[@]}"; do
  for lang in en zh; do
    [[ -f "$TPL_DIR/$lang/$template" ]] || SPECIALIZED_TEMPLATE_FAILS+=("$lang missing $template")
  done
  grep -qF "| \`$template\` |" "$TEMPLATE_INDEX" || SPECIALIZED_TEMPLATE_FAILS+=("index missing $template")
done

for lang in en zh; do
  for template in process-readme.md deployment-readme.md operations-readme.md security-and-compliance-readme.md; do
    grep -qF 'C01-C09' "$TPL_DIR/$lang/$template" || SPECIALIZED_TEMPLATE_FAILS+=("$lang $template common profile IDs")
    grep -qF 'PR01-PR16' "$TPL_DIR/$lang/$template" || SPECIALIZED_TEMPLATE_FAILS+=("$lang $template process profile IDs")
    grep -qF 'Q01-Q21' "$TPL_DIR/$lang/$template" || SPECIALIZED_TEMPLATE_FAILS+=("$lang $template quality profile IDs")
  done
  grep -qF '(../01-product/README.md)' "$TPL_DIR/$lang/process-readme.md" || SPECIALIZED_TEMPLATE_FAILS+=("$lang process-to-product link")
  grep -qF '(../02-architecture/README.md)' "$TPL_DIR/$lang/process-readme.md" || SPECIALIZED_TEMPLATE_FAILS+=("$lang process-to-architecture link")
  grep -qF '(../04-records/README.md)' "$TPL_DIR/$lang/process-readme.md" || SPECIALIZED_TEMPLATE_FAILS+=("$lang process-to-records link")
  grep -qF '(../01-product/README.md)' "$TPL_DIR/$lang/records-readme.md" || SPECIALIZED_TEMPLATE_FAILS+=("$lang records-to-product link")
  grep -qF '(../02-architecture/README.md)' "$TPL_DIR/$lang/records-readme.md" || SPECIALIZED_TEMPLATE_FAILS+=("$lang records-to-architecture link")
  for template in records-readme.md decisions-readme.md decision-entry.md research-readme.md research-entry.md gotchas-readme.md gotcha-entry.md bugs-readme.md bug-entry.md tech-debt-readme.md tech-debt-entry.md; do
    grep -qF 'C01-C09' "$TPL_DIR/$lang/$template" || SPECIALIZED_TEMPLATE_FAILS+=("$lang $template common profile IDs")
    grep -qF 'R01-R16' "$TPL_DIR/$lang/$template" || SPECIALIZED_TEMPLATE_FAILS+=("$lang $template record profile IDs")
  done
  grep -qF 'C01-C09' "$TPL_DIR/$lang/glossary-readme.md" || SPECIALIZED_TEMPLATE_FAILS+=("$lang glossary common profile IDs")
  grep -qF 'G01-G08' "$TPL_DIR/$lang/glossary-readme.md" || SPECIALIZED_TEMPLATE_FAILS+=("$lang glossary profile IDs")
  grep -qF 'C01-C09' "$TPL_DIR/$lang/glossary-entry.md" || SPECIALIZED_TEMPLATE_FAILS+=("$lang glossary entry common profile IDs")
  grep -qF 'G01-G08' "$TPL_DIR/$lang/glossary-entry.md" || SPECIALIZED_TEMPLATE_FAILS+=("$lang glossary entry profile IDs")
done

BOOTSTRAP_REF="$PROJECT_ROOT/skills/ssot-bootstrap/references/bootstrap.md"
SKELETON_PATHS=(
  SSOT/03-process/README.md
  SSOT/03-process/development/README.md
  SSOT/03-process/testing/README.md
  SSOT/03-process/benchmark/README.md
  SSOT/03-process/release/README.md
  SSOT/03-process/deployment/README.md
  SSOT/03-process/operations/README.md
  SSOT/03-process/security-and-compliance/README.md
  SSOT/04-records/README.md
  SSOT/04-records/decisions/README.md
  SSOT/04-records/research/README.md
  SSOT/04-records/gotchas/README.md
  SSOT/04-records/bugs/README.md
  SSOT/04-records/tech-debt/README.md
  SSOT/glossary/README.md
)
for path in "${SKELETON_PATHS[@]}"; do
  grep -qF "$path" "$BOOTSTRAP_REF" || SPECIALIZED_TEMPLATE_FAILS+=("bootstrap missing $path")
done
for template in "${SPECIALIZED_TEMPLATES[@]}"; do
  grep -qF "$template" "$BOOTSTRAP_REF" || SPECIALIZED_TEMPLATE_FAILS+=("bootstrap missing $template")
done
grep -qF 'Phase 1 must not create empty `04-records/*/NNNN-<slug>.md` entries.' "$BOOTSTRAP_REF" || SPECIALIZED_TEMPLATE_FAILS+=("bootstrap permits empty record entries")
grep -qF 'do not create empty term files' "$BOOTSTRAP_REF" || SPECIALIZED_TEMPLATE_FAILS+=("bootstrap permits empty glossary entries")

if [[ ${#SPECIALIZED_TEMPLATE_FAILS[@]} -eq 0 ]]; then
  pass "specialized process/records/glossary templates and skeleton wiring"
else
  fail "specialized template contract failed: ${SPECIALIZED_TEMPLATE_FAILS[*]}"
fi

# 6c. Protocol-upgrade ledger layering
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
  -type f \( -name '*.md' -o -name '*.sh' -o -name '*.py' -o -name '*.yaml' -o -name '*.yml' \) -print)
if [[ ${#HYGIENE_FILES[@]} -eq 0 ]]; then
  pass "public assets avoid local/origin-project leakage"
else
  fail "public hygiene leakage in: ${HYGIENE_FILES[*]}"
fi

echo
echo "=== RESULT: pass=$PASS fail=$FAIL ==="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
