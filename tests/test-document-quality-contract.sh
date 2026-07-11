#!/usr/bin/env bash
# tests/test-document-quality-contract.sh — reader-facing product/architecture template contract
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE_ROOT="$PROJECT_ROOT/skills/ssot-bootstrap/assets/templates"
PASS=0
FAIL=0

pass() { echo "  ok   : $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL : $1"; FAIL=$((FAIL + 1)); }

echo "=== test-document-quality-contract ==="

BODY_TEMPLATES=(
  product-readme.md
  product-prd.md
  product-model.md
  product-roadmap-and-acceptance.md
  product-capabilities-readme.md
  product-capability-entry.md
  product-journeys-readme.md
  product-journey-entry.md
  architecture-readme.md
  architecture-views-readme.md
  architecture-view-operating-model.md
  architecture-view-critical-journeys.md
  architecture-view-current-target-gap.md
  architecture-view-state-and-data-lifecycle.md
  architecture-view-contracts-and-trust-boundaries.md
  architecture-view-failure-and-recovery.md
  architecture-domain-readme.md
)

DIRECTORY_READMES=(
  product-readme.md
  product-capabilities-readme.md
  product-journeys-readme.md
  architecture-readme.md
  architecture-views-readme.md
)

MANIFEST_TEMPLATES=(
  product-root-manifest.md
  product-collection-manifest.md
  architecture-root-manifest.md
  architecture-views-manifest.md
  architecture-domain-manifest.md
)

for lang in en zh; do
  template_dir="$TEMPLATE_ROOT/$lang"

  for name in "${BODY_TEMPLATES[@]}"; do
    file="$template_dir/$name"
    if [[ ! -f "$file" ]]; then
      fail "$lang/$name exists"
      continue
    fi
    if sed -n '1,3p' "$file" | grep -qE '^intent_recovery:[[:space:]]*(gap|partial|covered)$'; then
      pass "$lang/$name declares intent_recovery frontmatter"
    else
      fail "$lang/$name declares intent_recovery frontmatter"
    fi
    if grep -qiE 'ssot-bootstrap|SKILL_STYLE|doctor[[:space:]]*\[|doctor[[:space:]]+[0-9]|\[(STATE-TAG|SURFACE-PIN|SYMBOL-PIN|FAILURE-TRACE|FORK)\]' "$file"; then
      fail "$lang/$name keeps protocol/Doctor meta out of reader-facing prose"
    else
      pass "$lang/$name keeps protocol/Doctor meta out of reader-facing prose"
    fi
  done

  for name in "${DIRECTORY_READMES[@]}"; do
    file="$template_dir/$name"
    if [[ -f "$file" ]] && sed -n '1,35p' "$file" | grep -qE '^[[:space:]]*(├──|└──)'; then
      pass "$lang/$name opens with an immediate-child directory map"
    else
      fail "$lang/$name opens with an immediate-child directory map"
    fi
  done

  domain="$template_dir/architecture-domain-readme.md"
  if [[ -f "$domain" ]]; then
    first_table=$(grep -nE '^\|' "$domain" | head -1 | cut -d: -f1 || true)
    first_mermaid=$(grep -nE '^```mermaid' "$domain" | head -1 | cut -d: -f1 || true)
    first_diagram_tag=$(awk '
      /^```mermaid[[:space:]]*$/ { inside=1; next }
      inside && /^[[:space:]]*$/ { next }
      inside { print; exit }
    ' "$domain")
    h2_count=$(grep -cE '^##[[:space:]]' "$domain" || true)
    if [[ -n "$first_mermaid" && "$first_mermaid" -le 60 && ( -z "$first_table" || "$first_mermaid" -lt "$first_table" ) && "$first_diagram_tag" == '<!-- diagram_type: component -->' ]]; then
      pass "$lang architecture domain puts a component diagram before the first table and within 60 lines"
    else
      fail "$lang architecture domain puts a component diagram before the first table and within 60 lines"
    fi
    if [[ "$h2_count" -le 12 ]]; then
      pass "$lang architecture domain avoids a universal checklist ($h2_count H2 sections)"
    else
      fail "$lang architecture domain avoids a universal checklist ($h2_count H2 sections)"
    fi
  fi

  invalid_diagram_tags=0
  diagram_blocks=0
  while IFS= read -r architecture_template; do
    blocks=$(grep -cE '^```mermaid[[:space:]]*$' "$architecture_template" || true)
    misses=$(awk '
      /^```mermaid[[:space:]]*$/ { inside=1; checked=0; next }
      inside && !checked && /^[[:space:]]*$/ { next }
      inside && !checked {
        checked=1
        if ($0 !~ /^[[:space:]]*<!--[[:space:]]*diagram_type:[[:space:]]*(component|sequence|state|flow)[[:space:]]*-->[[:space:]]*$/) misses++
      }
      inside && /^```[[:space:]]*$/ { if (!checked) misses++; inside=0 }
      END { print misses + 0 }
    ' "$architecture_template")
    diagram_blocks=$((diagram_blocks + blocks))
    invalid_diagram_tags=$((invalid_diagram_tags + misses))
  done < <(find "$template_dir" -maxdepth 1 -type f -name 'architecture*.md' -print)
  if [[ "$diagram_blocks" -gt 0 && "$invalid_diagram_tags" -eq 0 ]]; then
    pass "$lang architecture templates type every Mermaid block on its first non-blank line ($diagram_blocks blocks)"
  else
    fail "$lang architecture templates type every Mermaid block on its first non-blank line (blocks=$diagram_blocks invalid=$invalid_diagram_tags)"
  fi

  for name in "${MANIFEST_TEMPLATES[@]}"; do
    if [[ -f "$template_dir/$name" ]]; then
      pass "$lang/$name exists"
    else
      fail "$lang/$name exists"
    fi
  done

  if [[ -f "$template_dir/_manifest.md" ]]; then
    fail "$lang no longer ships one universal manifest template"
  else
    pass "$lang no longer ships one universal manifest template"
  fi
done

for lang in en zh; do
  ROOT_TEMPLATE="$TEMPLATE_ROOT/$lang/ssot-readme.md"
  if [[ ! -f "$ROOT_TEMPLATE" ]]; then
    fail "$lang/ssot-readme.md exists"
    continue
  fi
  if sed -n '1,35p' "$ROOT_TEMPLATE" | grep -qE '^[[:space:]]*(├──|└──)'; then
    pass "$lang/ssot-readme.md opens with the SSOT child tree"
  else
    fail "$lang/ssot-readme.md opens with the SSOT child tree"
  fi
  if sed -n '1,35p' "$ROOT_TEMPLATE" | grep -qE '^[[:space:]]*(├──|└──).*_manifest\.md'; then
    fail "$lang/ssot-readme.md root tree does not invent SSOT/_manifest.md"
  else
    pass "$lang/ssot-readme.md root tree does not invent SSOT/_manifest.md"
  fi
  if grep -qiE 'ssot-bootstrap|SKILL_STYLE|doctor[[:space:]]*\[|doctor[[:space:]]+[0-9]' "$ROOT_TEMPLATE"; then
    fail "$lang/ssot-readme.md keeps protocol/Doctor meta out of the reader route"
  else
    pass "$lang/ssot-readme.md keeps protocol/Doctor meta out of the reader route"
  fi
  if grep -qE '^##[[:space:]]+(Walkthrough|Easily confused with|Out of scope|See also|走查|容易混淆|不回答|延伸阅读)' "$ROOT_TEMPLATE"; then
    fail "$lang/ssot-readme.md does not force legacy exact-heading slots"
  else
    pass "$lang/ssot-readme.md does not force legacy exact-heading slots"
  fi
  if [[ "$lang" == "en" ]]; then
    first_day=$(awk '/^## First-day reading order/ {inside=1; next} inside && /^## / {exit} inside {print}' "$ROOT_TEMPLATE")
  else
    first_day=$(awk '/^## 第一天阅读顺序/ {inside=1; next} inside && /^## / {exit} inside {print}' "$ROOT_TEMPLATE")
  fi
  product_line=$(printf '%s\n' "$first_day" | grep -nF '(./01-product/README.md)' | head -1 | cut -d: -f1 || true)
  architecture_line=$(printf '%s\n' "$first_day" | grep -nF '(./02-architecture/README.md)' | head -1 | cut -d: -f1 || true)
  status_line=$(printf '%s\n' "$first_day" | grep -nF '(./STATUS.md)' | head -1 | cut -d: -f1 || true)
  if [[ -n "$product_line" && -n "$architecture_line" && -n "$status_line" && "$product_line" -lt "$architecture_line" && "$architecture_line" -lt "$status_line" ]]; then
    pass "$lang first-day section orders product before architecture and STATUS last"
  else
    fail "$lang first-day section orders product before architecture and STATUS last"
  fi
done

legacy_manifest_branch=$(awk '
  /For `2\.45 <= tracked_skill_version < 2\.48`/ { inside=1 }
  inside { print }
  inside && /Do not require sibling `_manifest\.md` files/ { exit }
' "$PROJECT_ROOT/skills/ssot-doctor/references/cold-agent-sim.md")
if printf '%s\n' "$legacy_manifest_branch" | grep -qF '`product/README.md`' &&
   printf '%s\n' "$legacy_manifest_branch" | grep -qF '`architecture/README.md`' &&
   ! printf '%s\n' "$legacy_manifest_branch" | grep -qE '`(01-product|02-architecture)/[^`]+`'; then
  pass "v2.45-v2.47 manifest simulation routes through legacy product/architecture owners"
else
  fail "v2.45-v2.47 manifest simulation routes through legacy product/architecture owners"
fi

echo
echo "=== RESULT: pass=$PASS fail=$FAIL ==="
[[ "$FAIL" -eq 0 ]]
