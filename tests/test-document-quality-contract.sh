#!/usr/bin/env bash
# tests/test-document-quality-contract.sh — reader-facing product/architecture template contract
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE_ROOT="$PROJECT_ROOT/skills/ssot-bootstrap/assets/templates"
PASS=0
FAIL=0

pass() { echo "  ok   : $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL : $1"; FAIL=$((FAIL + 1)); }

strip_html_comments() {
  awk '
    BEGIN { in_comment=0 }
    {
      line=$0
      while (1) {
        if (in_comment) {
          if (match(line, /-->/)) {
            line=substr(line, RSTART + RLENGTH)
            in_comment=0
            continue
          }
          line=""
          break
        }
        if (match(line, /<!--/)) {
          before=substr(line, 1, RSTART - 1)
          rest=substr(line, RSTART + RLENGTH)
          if (match(rest, /-->/)) {
            line=before substr(rest, RSTART + RLENGTH)
            continue
          }
          line=before
          in_comment=1
          break
        }
        break
      }
      if (line != "") print line
    }
  ' "$1"
}

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
  architecture-view-deployment-and-observability.md
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

  review_template="$template_dir/reader-review.md"
  dimension_pattern='^\| [^|]+ \| (RF1|RF2|LA1|LA2|LA3|CT1|CT2|CT3|CT4|BC1|BC2|BC3|BC4|RP1|RP2|RP3) \|'
  dimension_rows=$(grep -Ec "$dimension_pattern" "$review_template" 2>/dev/null || true)
  h2_count=$(grep -Ec '^##[[:space:]]' "$review_template" 2>/dev/null || true)
  if [[ ! -f "$review_template" ]]; then
    fail "$lang/reader-review.md exists"
  elif grep -qE '^review_scope:[[:space:]]*"<SSOT/01-product \| SSOT/02-architecture>"$' "$review_template" &&
       grep -qE '^review_type:[[:space:]]*"<high-impact-adoption \| routine>"$' "$review_template" &&
       grep -qE '^reader_profile:[[:space:]]*implementation-delegator$' "$review_template" &&
       grep -qE '^completeness_profile:[[:space:]]*"<product \| architecture>"$' "$review_template" &&
       grep -qE '^reviewer_role:[[:space:]]*"<independent-cold-reader \| scoped-self-review>"$' "$review_template" &&
       grep -qE '^repository_commit:' "$review_template" &&
       grep -qE '^content_fingerprint:' "$review_template" &&
       grep -qE '^quality_disposition_fingerprint:' "$review_template" &&
       grep -qE '^sample_seed:' "$review_template" &&
       grep -qE '^rotation_id:' "$review_template" &&
       grep -qE '^task_count:[[:space:]]*6$' "$review_template" &&
       grep -qE '^entrypoint:[[:space:]]*SSOT/README\.md$' "$review_template" &&
       grep -qE '^bounded_read_set:[[:space:]]*true$' "$review_template" &&
       grep -qE '^route_probe:[[:space:]]*"<passed \| failed>"$' "$review_template" &&
       grep -qE '^scored_dimensions:[[:space:]]*16$' "$review_template" &&
       grep -qE '^##[[:space:]]+(Bounded reading set|有界阅读集)' "$review_template" &&
       grep -qE '^##[[:space:]]+(Teach-back|复述)$' "$review_template" &&
       grep -qE '^##[[:space:]]+(Dimension scores|维度评分)$' "$review_template" &&
       grep -qE '^##[[:space:]]+(Consistency and evidence sample|一致性与证据抽样)$' "$review_template" &&
       grep -qE '^##[[:space:]]+(Completeness profile|完整性画像)$' "$review_template" &&
       grep -qE '^##[[:space:]]+(Required changes and verdict|必改项与结论)$' "$review_template" &&
       grep -qE '^\| (CP-D|CP-R|CP-T|CP-E|CP-C) \|' "$review_template" &&
       grep -qE '(Delegated action|委托动作)' "$review_template" &&
       grep -qE '(Expected visible result|预期可见结果)' "$review_template" &&
       grep -qE '(Stop or escalate when|停止或升级条件)' "$review_template" &&
       grep -qE 'C01-C09.*P01-P23.*Q01-Q21' "$review_template" &&
       grep -qE 'C01-C09.*A01-A18.*Q01-Q21' "$review_template" &&
       grep -qE '53[[:space:]]*(rows|行)' "$review_template" &&
       grep -qE '48[[:space:]]*(rows|行)' "$review_template" &&
       grep -qE '(Plain-language clarity|平实清晰与易懂性)' "$review_template" &&
       [[ "$dimension_rows" -eq 16 && "$h2_count" -eq 6 ]]; then
    pass "$lang/reader-review.md carries the v2.60 structured cold-review contract"
  else
    fail "$lang/reader-review.md carries the v2.60 structured cold-review contract"
  fi

  scope_review_template="$template_dir/scope-review.md"
  if [[ "$lang" == en ]]; then
    scope_semantic_header='| Item ID | Owner/body claim | Repository/evidence sample | Truth result | Limit |'
    scope_target_header='| Target ID | Target owner | Profile IDs exercised | Repository/evidence sample | Truth result | Limit |'
    scope_profile_header='| Item ID | Disposition | Plain answer | Owner / evidence |'
  else
    scope_semantic_header='| 项目 ID | 所有者正文结论 | 仓库或证据样本 | 真实性结果 | 限制 |'
    scope_target_header='| 目标 ID | 目标所有者 | 已核验画像 ID | 仓库或证据样本 | 真实性结果 | 限制 |'
    scope_profile_header='| 项目 ID | 处置 | 白话结论 | 所有者或证据 |'
  fi
  scope_h2_count=$(grep -Ec '^##[[:space:]]' "$scope_review_template" 2>/dev/null || true)
  if [[ -f "$scope_review_template" ]] &&
     grep -qE '^area_disposition_fingerprint:[[:space:]]*<lowercase-sha256>$' "$scope_review_template" &&
     grep -qF "$scope_semantic_header" "$scope_review_template" &&
     grep -qF "$scope_target_header" "$scope_review_template" &&
     grep -qF "$scope_profile_header" "$scope_review_template" &&
     [[ "$scope_h2_count" -eq 3 ]]; then
    pass "$lang/scope-review.md binds area freshness, full targets, semantic truth, and plain answers"
  else
    fail "$lang/scope-review.md binds area freshness, full targets, semantic truth, and plain answers"
  fi

  status_template="$template_dir/status.md"
  q_ids=$(awk -F'|' '
    /^##[[:space:]]+(Quality, Risk, and Governance|质量、风险与治理)[[:space:]]*$/ { active=1; next }
    active && /^##[[:space:]]/ { exit }
    active && /^\|[[:space:]]*Q[0-9][0-9][[:space:]]*\|/ {
      id=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", id); print id
    }
  ' "$status_template" 2>/dev/null || true)
  expected_q_ids=$(for i in {1..21}; do printf 'Q%02d\n' "$i"; done)
  if [[ "$q_ids" == "$expected_q_ids" ]]; then
    pass "$lang/status.md carries exact Q01-Q21 register IDs"
  else
    fail "$lang/status.md carries exact Q01-Q21 register IDs"
  fi

  area_ids=$(awk -F'|' '
    /^##[[:space:]]+(Area Status|区域状态)[[:space:]]*$/ { active=1; next }
    active && /^##[[:space:]]/ { exit }
    active && /^\|[[:space:]]*(product|architecture|process|development|testing|benchmark|deployment|release|operations|security-and-compliance|records|decisions|research records|gotchas|bugs|tech-debt|glossary)[[:space:]]*\|/ {
      id=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", id); print id
    }
  ' "$status_template")
  expected_area_ids=$(printf '%s\n' product architecture process development testing benchmark deployment release operations security-and-compliance records decisions 'research records' gotchas bugs tech-debt glossary)
  if [[ "$area_ids" == "$expected_area_ids" ]]; then
    pass "$lang/status.md carries the exact ordered 17-row Area Status schema"
  else
    fail "$lang/status.md carries the exact ordered 17-row Area Status schema"
  fi

  if grep -qF '$ssot-preflight references/reader-quality.md' "$status_template" &&
     ! grep -qF 'system-service recoverability' "$status_template" &&
     ! grep -qF '系统或服务可恢复性' "$status_template"; then
    pass "$lang/status.md routes Q01-Q21 meanings to their unique reader-quality owner"
  else
    fail "$lang/status.md routes Q01-Q21 meanings to their unique reader-quality owner"
  fi

  bootstrap_manifest="$template_dir/bootstrap-manifest.md"
  if grep -qE '^\| process \| pending \|.*(aggregate|聚合)' "$bootstrap_manifest" &&
     grep -qE '^\| records \| pending \|.*(aggregate|聚合)' "$bootstrap_manifest"; then
    pass "$lang/bootstrap-manifest.md gives process and records aggregate closeout slots"
  else
    fail "$lang/bootstrap-manifest.md gives process and records aggregate closeout slots"
  fi

  process_template="$template_dir/process-readme.md"
  if ! grep -qF '(./operations/README.md)' "$process_template" &&
     ! grep -qF '(./security-and-compliance/README.md)' "$process_template" &&
     grep -qF '../STATUS.md#' "$process_template"; then
    pass "$lang/process-readme.md does not link conditional owners before they exist"
  else
    fail "$lang/process-readme.md does not link conditional owners before they exist"
  fi
done

for lang in en zh; do
  record_contract_ok=1
  for name in decisions research bugs gotchas tech-debt; do
    file="$TEMPLATE_ROOT/$lang/${name}-readme.md"
    if [[ "$lang" == en ]]; then
      grep -qE '^Empty collection: reason=<named reason>; owner=\[responsible owner\]\(<resolving-path>\); review when=<observable event>\.$' "$file" || record_contract_ok=0
    else
      grep -qE '^空集合说明：原因=<具体理由>；负责人=\[责任所有者\]\(<可解析路径>\)；复核条件=<可观察事件>。$' "$file" || record_contract_ok=0
    fi
  done
  if [[ "$record_contract_ok" -eq 1 ]]; then
    pass "$lang record indexes expose the readable owner-routed empty-collection sentence"
  else
    fail "$lang record indexes expose the readable owner-routed empty-collection sentence"
  fi
done

if grep -qE '^failure_state:[[:space:]]*open$' "$TEMPLATE_ROOT/en/bug-entry.md" &&
   grep -qE '^failure_state:[[:space:]]*open$' "$TEMPLATE_ROOT/zh/bug-entry.md" &&
   grep -qF 'Only `open`, `fixed`, and `recurred` are valid routing states.' "$TEMPLATE_ROOT/en/bugs-readme.md" &&
   grep -qF '`open`（尚未修复）、`fixed`（已修复）和 `recurred`' "$TEMPLATE_ROOT/zh/bugs-readme.md"; then
  pass "bug entry templates keep the open/fixed/recurred canonical failure axis"
else
  fail "bug entry templates keep the open/fixed/recurred canonical failure axis"
fi

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

for lang in en zh; do
  glossary="$TEMPLATE_ROOT/$lang/glossary-readme.md"
  family_rows=$(awk '
    /^##[[:space:]]+(Vocabulary-family coverage|术语家族覆盖)[[:space:]]*$/ { active=1; next }
    active && /^##[[:space:]]/ { exit }
    active && /^\|/ && $0 !~ /^\|[-:|[:space:]]+$/ && $0 !~ /(Vocabulary family|术语家族)/ { rows++ }
    END { print rows + 0 }
  ' "$glossary")
  if [[ "$family_rows" -eq 6 ]] && grep -qiE '(Concurrency-control terms|并发控制术语)' "$glossary"; then
    pass "$lang/glossary-readme.md owns exactly six mandatory families including concurrency control"
  else
    fail "$lang/glossary-readme.md owns exactly six mandatory families including concurrency control"
  fi
  if ! grep -qE '^intent_recovery:' "$TEMPLATE_ROOT/$lang/glossary-entry.md"; then
    pass "$lang/glossary-entry.md avoids the product/architecture-only recovery axis"
  else
    fail "$lang/glossary-entry.md avoids the product/architecture-only recovery axis"
  fi
done

zh_root_visible=$(strip_html_comments "$TEMPLATE_ROOT/zh/ssot-readme.md")
zh_views_visible=$(strip_html_comments "$TEMPLATE_ROOT/zh/architecture-views-readme.md")
zh_glossary_visible=$(strip_html_comments "$TEMPLATE_ROOT/zh/glossary-readme.md")
if printf '%s\n' "$zh_root_visible" | grep -qF '追踪基线' &&
   printf '%s\n' "$zh_root_visible" | grep -qF '登记表（register）' &&
   printf '%s\n' "$zh_root_visible" | grep -qF '何时复核' &&
   printf '%s\n' "$zh_root_visible" | grep -qF '当前、目标与缺口状态' &&
   printf '%s\n' "$zh_root_visible" | grep -qF '产品表面是人能' &&
   printf '%s\n' "$zh_root_visible" | grep -qF '运行时所有者（runtime owner）' &&
   printf '%s\n' "$zh_root_visible" | grep -qF 'Q01-Q21 是二十一类'; then
  pass "zh/ssot-readme.md visibly explains the required ordinary-language terms"
else
  fail "zh/ssot-readme.md visibly explains the required ordinary-language terms"
fi
if printf '%s\n' "$zh_views_visible" | grep -qF '所有者（owner）' &&
   printf '%s\n' "$zh_views_visible" | grep -qF '运行时所有者（runtime owner）' &&
   printf '%s\n' "$zh_views_visible" | grep -qF '机器清单'; then
  pass "zh/architecture-views-readme.md visibly defines owner and manifest concepts"
else
  fail "zh/architecture-views-readme.md visibly defines owner and manifest concepts"
fi
if printf '%s\n' "$zh_glossary_visible" | grep -qF '所有者（owner）' &&
   printf '%s\n' "$zh_glossary_visible" | grep -qF '不是评分'; then
  pass "zh/glossary-readme.md visibly defines owner and Q IDs"
else
  fail "zh/glossary-readme.md visibly defines owner and Q IDs"
fi

READER_QUALITY="$PROJECT_ROOT/skills/ssot-preflight/references/reader-quality.md"
DOCTOR_REFERENCE="$PROJECT_ROOT/skills/ssot-doctor/references/doctor.md"
for spec in C:9 P:23 A:18 PR:16 R:16 G:8 RT:7 S:11 Q:21; do
  prefix=${spec%%:*}
  max=${spec##*:}
  expected=""
  for i in $(seq 1 "$max"); do
    printf -v id '%s%02d' "$prefix" "$i"
    expected+="$id"$'\n'
  done
  actual=$(awk -F'|' -v prefix="$prefix" '
    /^\|/ {
      id=$2
      gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", id)
      if (id ~ ("^" prefix "[0-9][0-9]$")) print id
    }
  ' "$READER_QUALITY")
  if [[ "$actual"$'\n' == "$expected" ]]; then
    pass "reader-quality owns the exact ${prefix}01-${prefix}$(printf '%02d' "$max") profile"
  else
    fail "reader-quality owns the exact ${prefix}01-${prefix}$(printf '%02d' "$max") profile"
  fi
done

if grep -qiE '^\| `Q14` \|.*classification.*purpose limitation.*minimisation.*lineage' "$READER_QUALITY" &&
   grep -qiE '^\| `Q15` \|.*physical.*psychological.*financial.*safe failure' "$READER_QUALITY" &&
   grep -qiE '^\| `Q16` \|.*oversight.*approval.*override.*redress' "$READER_QUALITY" &&
   grep -qiE '^\| `Q17` \|.*fairness.*explainability.*bias.*notices' "$READER_QUALITY" &&
   grep -qiE '^\| `Q18` \|.*maintainability.*testability.*decommissioning' "$READER_QUALITY" &&
   grep -qiE '^\| `Q19` \|.*energy.*carbon.*water.*end-of-life' "$READER_QUALITY" &&
   grep -qiE '^\| `Q20` \|.*accuracy.*calibration.*drift.*evaluation limits' "$READER_QUALITY" &&
   grep -qiE '^\| `Q21` \|.*pricing.*billing.*refund.*accounting reconciliation.*paid-action authority' "$READER_QUALITY" &&
   grep -qF '`Q21` owns correctness and authority at the commercial transaction' "$READER_QUALITY"; then
  pass "reader-quality owns the expanded Q14-Q21 concerns and overlap boundaries"
else
  fail "reader-quality owns the expanded Q14-Q21 concerns and overlap boundaries"
fi

if grep -qF 'area_disposition_fingerprint: <lowercase-sha256>' "$READER_QUALITY" &&
   grep -qF 'The collection-root README is the one complete state index' "$READER_QUALITY" &&
   grep -qF 'The two states in `R03` answer different plain-language questions.' "$READER_QUALITY" &&
   grep -qF 'exact target-coverage table' "$READER_QUALITY" &&
   grep -qF '`Plain answer`' "$READER_QUALITY" &&
   grep -qF 'regenerate the affected SSOT from the repaired' "$READER_QUALITY"; then
  pass "reader-quality binds child freshness, recursive records, plain dual-axis truth, full targets, and regeneration"
else
  fail "reader-quality binds child freshness, recursive records, plain dual-axis truth, full targets, and regeneration"
fi

for skill in ssot-preflight ssot-bootstrap ssot-doctor ssot-closeout ssot-audit; do
  if grep -qF 'reader-quality.md' "$PROJECT_ROOT/skills/$skill/SKILL.md"; then
    pass "$skill routes reader-facing body work to the shared writing floor"
  else
    fail "$skill routes reader-facing body work to the shared writing floor"
  fi
done
if grep -qF 'Product and architecture use the full v2.60 task-based cold-review' "$READER_QUALITY" &&
   grep -qF 'Process, records,' "$READER_QUALITY" &&
   grep -qF 'the SSOT root, and STATUS use the lighter exact-scope review' "$READER_QUALITY"; then
  pass "product/architecture use full scored review and five scopes use lightweight exact review"
else
  fail "product/architecture use full scored review and five scopes use lightweight exact review"
fi

if [[ "$(grep -c '^- `\[META-LEAKAGE\]`' "$DOCTOR_REFERENCE")" -eq 1 ]] &&
   grep -qF 'universal body scope v2.60' "$DOCTOR_REFERENCE" &&
   grep -qF 'decisions, research, bugs, gotchas, and debt have no broad subject-area exemption' "$DOCTOR_REFERENCE" &&
   ! grep -qF '`STATUS.md`, `CHANGELOG.md`, and `decisions/` files are out of scope' "$DOCTOR_REFERENCE"; then
  pass "doctor keeps one universal reader-body META-LEAKAGE contract"
else
  fail "doctor forks or narrows the universal reader-body META-LEAKAGE contract"
fi

if [[ "$(grep -c '^- `\[LIGHTWEIGHT-REVIEW-TRUTH\]`' "$DOCTOR_REFERENCE")" -eq 1 ]] &&
   grep -qF 'a plain answer for any exact profile row' "$DOCTOR_REFERENCE" &&
   grep -qF 'any real finite target' "$DOCTOR_REFERENCE"; then
  pass "doctor keeps one complete-target lightweight-review contract"
else
  fail "doctor duplicates or weakens the complete-target lightweight-review contract"
fi

# Authoring guidance belongs in HTML comments. It must not become reader prose
# when a consumer-facing template is copied into SSOT/.
for lang in en zh; do
  visible_meta_files=()
  while IFS= read -r file; do
    visible=$(strip_html_comments "$file")
    if printf '%s\n' "$visible" | grep -qiE '^>[[:space:]]*(Writing style|行文风格|写作姿态)|^>.*(`?ssot-bootstrap`?.*§3\.7|Doctor[[:space:]]+[0-9]|SKILL_STYLE|protocol[ -]writing note|协议写作说明)'; then
      visible_meta_files+=("$(basename "$file")")
    fi
  done < <(find "$TEMPLATE_ROOT/$lang" -maxdepth 1 -type f -name '*.md' -print | sort)
  if [[ ${#visible_meta_files[@]} -eq 0 ]]; then
    pass "$lang consumer templates hide protocol authoring notes in HTML comments"
  else
    fail "$lang consumer templates expose protocol authoring notes: ${visible_meta_files[*]}"
  fi
done

for lang in en zh; do
  for name in development-readme.md testing-readme.md benchmark-readme.md release-readme.md; do
    file="$TEMPLATE_ROOT/$lang/$name"
    if [[ "$lang" == "en" ]]; then
      story_count=$(grep -Ec '^## (When and for whom|Canonical path and branches|Output and acceptance|Failure, recovery, and handoff|Reproduce and keep current)$' "$file" || true)
    else
      story_count=$(grep -Ec '^## (何时由谁使用|标准路径与分支|产物与验收|失败、恢复与交接|怎样复现，以及何时重新检查)$' "$file" || true)
    fi
    first_table=$(grep -nE '^\|' "$file" | head -1 | cut -d: -f1 || true)
    last_story=$(grep -nE '^## (When and for whom|Canonical path and branches|Output and acceptance|Failure, recovery, and handoff|Reproduce and keep current|何时由谁使用|标准路径与分支|产物与验收|失败、恢复与交接|怎样复现，以及何时重新检查)$' "$file" | tail -1 | cut -d: -f1 || true)
    if [[ "$story_count" -eq 5 && -n "$first_table" && -n "$last_story" && "$last_story" -lt "$first_table" ]]; then
      pass "$lang/$name teaches the complete process story before reference tables"
    else
      fail "$lang/$name teaches the complete process story before reference tables"
    fi
  done

  if grep -qE '^## (Record orientation|记录定位)$' "$TEMPLATE_ROOT/$lang/decision-entry.md" &&
     grep -qE '^## (Validation and follow-up|验证与跟进)$' "$TEMPLATE_ROOT/$lang/decision-entry.md" &&
     grep -qE '^## (Closure, supersession, and invalidation|完成条件、取代与失效)$' "$TEMPLATE_ROOT/$lang/decision-entry.md"; then
    pass "$lang decision entry exposes record orientation, validation, and closure"
  else
    fail "$lang decision entry exposes record orientation, validation, and closure"
  fi
  if grep -qE '^## (Record orientation|记录定位)$' "$TEMPLATE_ROOT/$lang/research-entry.md" &&
     grep -qE '^## (Closure, supersession, and invalidation|完成条件、取代与失效)$' "$TEMPLATE_ROOT/$lang/research-entry.md"; then
    pass "$lang research entry exposes record orientation and invalidation"
  else
    fail "$lang research entry exposes record orientation and invalidation"
  fi
  if grep -qE '^## (Why it matters|为什么重要)$' "$TEMPLATE_ROOT/$lang/glossary-entry.md" &&
     grep -qE '^## (Example and non-example|例子与反例)$' "$TEMPLATE_ROOT/$lang/glossary-entry.md" &&
     grep -qE '^## (Scope and invalidation|范围与失效)$' "$TEMPLATE_ROOT/$lang/glossary-entry.md"; then
    pass "$lang glossary entry exposes consequence, example, and invalidation"
  else
    fail "$lang glossary entry exposes consequence, example, and invalidation"
  fi
done

# PR15/PR16 stay consistent across all seven process owners: each explains the
# chosen method and trade-off, then routes the same finite eight-field asset
# contract. One assertion per language is enough to catch a single-file drift.
for lang in en zh; do
  process_contract_ok=1
  for name in development testing benchmark deployment release operations security-and-compliance; do
    file="$TEMPLATE_ROOT/$lang/${name}-readme.md"
    if [[ "$lang" == en ]]; then
      grep -qiE '(trade-off|trade-offs|tradeoff)' "$file" || process_contract_ok=0
      grep -qF '| Asset | Class | Purpose | Selection rule | Owner | Evidence | Risk | Retirement or replacement trigger |' "$file" || process_contract_ok=0
    else
      grep -qF '取舍' "$file" || process_contract_ok=0
      grep -qF '| 资产 | 类别 | 用途 | 选择规则 | 所有者 | 证据 | 风险 | 退役或替换触发条件 |' "$file" || process_contract_ok=0
    fi
  done
  if [[ "$process_contract_ok" -eq 1 ]]; then
    pass "$lang seven process owners keep the PR15 method/trade-off and PR16 exact asset contract"
  else
    fail "$lang seven process owners keep the PR15 method/trade-off and PR16 exact asset contract"
  fi
done

for lang in en zh; do
  product_manifest="$TEMPLATE_ROOT/$lang/product-root-manifest.md"
  architecture_manifest="$TEMPLATE_ROOT/$lang/architecture-root-manifest.md"
  if grep -qE 'Source surface anchor|源表面锚点' "$product_manifest" &&
     grep -qF 'planned_in:' "$product_manifest"; then
    pass "$lang product manifest distinguishes planned target surfaces from absent classes"
  else
    fail "$lang product manifest distinguishes planned target surfaces from absent classes"
  fi
  if grep -qE 'Product surface ID|产品表面 ID' "$architecture_manifest" &&
     grep -qE 'Runtime owner ID|运行时所有者 ID' "$architecture_manifest" &&
     grep -qE 'Surface kind.*Disposition|表面类型.*处置' "$architecture_manifest"; then
    pass "$lang architecture manifest exposes exact bridge and kind dispositions"
  else
    fail "$lang architecture manifest exposes exact bridge and kind dispositions"
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

# v2.60: reader-quality.md is the one owner of product maturity and evidence
# fidelity. Lifecycle adapters link that contract instead of preserving the
# older architecture-state vocabulary for product truth.
PRODUCT_CONTRACT_ADAPTERS=(
  "$PROJECT_ROOT/skills/ssot-preflight/references/area-model.md"
  "$PROJECT_ROOT/skills/ssot-preflight/references/knowledge-integrity.md"
  "$PROJECT_ROOT/skills/ssot-bootstrap/references/bootstrap.md"
  "$PROJECT_ROOT/skills/ssot-doctor/references/cold-agent-sim.md"
  "$PROJECT_ROOT/skills/ssot-doctor/references/doctor.md"
)
for adapter in "${PRODUCT_CONTRACT_ADAPTERS[@]}"; do
  if grep -qiE 'Product current-truth anchors|product_truth[^\n]*(state:[[:space:]]*(contract|design|debt)|shipped contract)|product maturity[^\n]*production[[:space:]]*\|' "$adapter"; then
    fail "$(basename "$adapter") does not preserve a legacy product-state interface"
  else
    pass "$(basename "$adapter") routes product state through the reader-quality owner"
  fi
done

echo
echo "=== RESULT: pass=$PASS fail=$FAIL ==="
[[ "$FAIL" -eq 0 ]]
