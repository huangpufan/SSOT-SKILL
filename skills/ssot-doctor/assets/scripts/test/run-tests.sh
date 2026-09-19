#!/usr/bin/env bash
# run-tests.sh — smoke tests for ssot-lint.sh
#
# Design: no fixture files left on disk. Each scenario builds a minimal SSOT
#         project under mktemp, then asserts on key output and exit codes.
#         Self-contained, easy to read. Covers v2.13 checks 6/7/8/9, the
#         v2.17 handwritten vs SSOT-generated adapter boundary, v2.19
#         product skeleton, v2.31 decision lifecycle fields, v2.34 ledger
#         WARN heuristics, v2.35 actionability WARN heuristics, v2.36 KISS
#         table-density WARN heuristics, v2.47 intent/truth narrative WARN,
#         v2.52 open-risk / temporary-surface checks, v2.53 non-silent
#         deferral checks, v2.54 research-record checks, v2.55 benchmark-owner
#         checks, v2.60 STATUS/register heuristic boundaries, and the clean
#         baseline.
#
# Usage:       bash assets/scripts/test/run-tests.sh
# Exit codes:  0 all pass; 1 some failed.
set -uo pipefail

LINT="$(cd "$(dirname "$0")/.." && pwd)/ssot-lint.sh"
DOCTOR_SKILL="$(cd "$(dirname "$0")/../../.." && pwd)"
SKILLS_DIR="$(cd "$DOCTOR_SKILL/.." && pwd)"
PASS=0
FAIL=0

# Same hash impl as ssot-lint.sh ssot_hash (test env assumes sha256sum).
thash() { sha256sum "$1" | cut -c1-12; }

assert_contains() { # desc out needle
  if printf '%s' "$2" | grep -qF "$3"; then echo "  ok   : $1"; PASS=$((PASS + 1));
  else echo "  FAIL : $1 (output missing: $3)"; FAIL=$((FAIL + 1)); fi
}
assert_not_contains() { # desc out needle
  if printf '%s' "$2" | grep -qF "$3"; then echo "  FAIL : $1 (output should not contain: $3)"; FAIL=$((FAIL + 1));
  else echo "  ok   : $1"; PASS=$((PASS + 1)); fi
}
assert_exit() { # desc actual expected
  if [[ "$2" == "$3" ]]; then echo "  ok   : $1"; PASS=$((PASS + 1));
  else echo "  FAIL : $1 (exit code $2 != $3)"; FAIL=$((FAIL + 1)); fi
}
assert_not_exit() { # desc actual forbidden
  if [[ "$2" != "$3" ]]; then echo "  ok   : $1"; PASS=$((PASS + 1));
  else echo "  FAIL : $1 (unexpected exit code $3)"; FAIL=$((FAIL + 1)); fi
}
# Failures render as "  - [TAG] msg" under "[FAIL] N", so not_contains on
# "[FAIL] [TAG]" is vacuous; scope assertions to real section lines instead.
_in_section_tag() { # $1=section name (FAIL|WARN) $2=output $3=bracketed tag
  printf '%s' "$2" | awk -v tag="$3" -v section="$1" '
    /^\[[A-Z-]+\]/ { inside = (index($0, "[" section "]") == 1); next }
    inside && index($0, tag) { found=1 }
    END { exit(found ? 0 : 1) }
  '
}
assert_no_fail_tag() { # desc out bracketed-tag
  if _in_section_tag 'FAIL' "$2" "$3"; then echo "  FAIL : $1 (unexpected fail tag: $3)"; FAIL=$((FAIL + 1));
  else echo "  ok   : $1"; PASS=$((PASS + 1)); fi
}
assert_has_fail_tag() { # desc out bracketed-tag
  if _in_section_tag 'FAIL' "$2" "$3"; then echo "  ok   : $1"; PASS=$((PASS + 1));
  else echo "  FAIL : $1 (missing fail tag: $3)"; FAIL=$((FAIL + 1)); fi
}
assert_has_warn_tag() { # desc out bracketed-tag
  if _in_section_tag 'WARN' "$2" "$3"; then echo "  ok   : $1"; PASS=$((PASS + 1));
  else echo "  FAIL : $1 (missing warn tag: $3)"; FAIL=$((FAIL + 1)); fi
}
assert_no_warn_tag() { # desc out bracketed-tag
  if _in_section_tag 'WARN' "$2" "$3"; then echo "  FAIL : $1 (unexpected warn tag: $3)"; FAIL=$((FAIL + 1));
  else echo "  ok   : $1"; PASS=$((PASS + 1)); fi
}
assert_file() { # desc path
  if [[ -f "$2" ]]; then echo "  ok   : $1"; PASS=$((PASS + 1));
  else echo "  FAIL : $1 (missing file: $2)"; FAIL=$((FAIL + 1)); fi
}

make_base() { # $1=root — build a clean, all-PASS minimal SSOT project (git repo).
              # Fixture content is intentionally Chinese to exercise
              # documentation_language: 中文 semantics; do not translate.
  local r="$1"
  mkdir -p "$r/SSOT/product/capabilities" "$r/SSOT/product/journeys" "$r/SSOT/architecture" "$r/SSOT/gotchas" "$r/src"
  printf '# SSOT 导航\n\n```\n├── product/\n├── architecture/\n└── gotchas/\n```\n\n- [product](product/README.md)\n- [architecture](architecture/README.md)\n\n## Easily confused with\n\n（待补充）\n\n## Out of scope\n\n（待补充）\n' > "$r/SSOT/README.md"
  printf -- '---\nintent_recovery: gap\n---\n# 产品\n\n```\n├── capabilities/\n├── journeys/\n├── prd.md\n├── product-model.md\n└── roadmap-and-acceptance.md\n```\n\n- [PRD](prd.md)\n- [Product model](product-model.md)\n- [Roadmap](roadmap-and-acceptance.md)\n\n## Easily confused with\n\n（待补充）\n\n## Out of scope\n\n（待补充）\n' > "$r/SSOT/product/README.md"
  printf -- '---\nintent_recovery: gap\n---\n# PRD Spine\n' > "$r/SSOT/product/prd.md"
  printf -- '---\nintent_recovery: gap\n---\n# Product Model\n' > "$r/SSOT/product/product-model.md"
  printf -- '---\nintent_recovery: gap\n---\n# Roadmap And Acceptance\n' > "$r/SSOT/product/roadmap-and-acceptance.md"
  printf -- '---\nintent_recovery: gap\n---\n# 产品能力索引\n\n这里列出用户可获得的能力及其事实所有者。它不负责解释运行时实现；这类问题转到[架构所有者](../../architecture/README.md)。\n' > "$r/SSOT/product/capabilities/README.md"
  printf -- '---\nintent_recovery: gap\n---\n# 用户旅程索引\n\n这里列出用户从开始到结果的主要路径。它不负责重新定义单项能力；这类问题转到[产品所有者](../README.md)。\n' > "$r/SSOT/product/journeys/README.md"
  printf -- '---\nintent_recovery: gap\n---\n# 架构\n\n核心不变量：请求必须经过鉴权。\n\n## Easily confused with\n\n（待补充）\n\n## Out of scope\n\n（待补充）\n' > "$r/SSOT/architecture/README.md"
  printf '# 陷阱索引\n\n- [0001](0001-x.md)\n\n## Easily confused with\n\n（待补充）\n\n## Out of scope\n\n（待补充）\n' > "$r/SSOT/gotchas/README.md"
  printf -- '---\nconfidence: candidate\nsource: code-analysis\ndiscovered_at: 2026-05-29\nevidence: "src/foo.ts#barFunc"\n---\n# 陷阱 X\n' > "$r/SSOT/gotchas/0001-x.md"
  printf 'export function barFunc() { return 1 }\n' > "$r/src/foo.ts"
  printf '| tracked_commit | `PLACEHOLDER` |\n| tracked_session | `2026-06-08T00:00:00Z` |\n| tracked_skill_version | `2.19` |\n| documentation_language | 中文 |\n| documentation_language_evidence | README |\n| coverage_result | in_progress |\n\n| 区域 | 状态 | 备注 |\n|---|---|---|\n| product | gap | |\n| architecture | gap | |\n' > "$r/SSOT/STATUS.md"
  git -C "$r" init -q
  git -C "$r" add -A >/dev/null 2>&1
  git -C "$r" -c user.email=t@t.t -c user.name=t commit -qm init >/dev/null 2>&1
  local head
  head=$(git -C "$r" rev-parse HEAD)
  sed -i "s/PLACEHOLDER/$head/" "$r/SSOT/STATUS.md"
}

add_clean_adapter() { # $1=root — thin adapter with marker + correct source hash + SSOT routing.
  local r="$1" ha
  ha=$(thash "$r/SSOT/architecture/README.md")
  {
    printf '<!-- SSOT-generated | generated_at: 2026-05-29 -->\n'
    printf '<!-- SSOT-source: SSOT/architecture/README.md@%s -->\n' "$ha"
    printf '<!-- generated by SSOT -->\n\n'
    printf '# proj\n\n开始任何任务前先读 SSOT/STATUS.md。\n'
  } > "$r/AGENTS.md"
}

run() { bash "$LINT" "$1/SSOT" 2>&1; }

set_protocol_238() { # $1=root — opt the temp fixture into v2.38 checks.
  sed -i 's/| tracked_skill_version | `2.19` |/| tracked_skill_version | `2.38` |/' "$1/SSOT/STATUS.md"
}

resolve_template_placeholders() { # $1=root — replace skeleton residue in fixture prose before marking areas covered.
  find "$1/SSOT" -name '*.md' -type f -print0 | xargs -0 sed -i 's/（待补充）/无/g'
}

set_protocol_version() { # $1=root $2=version
  sed -i -E "s/(\| tracked_skill_version \| \`)[0-9]+\.[0-9]+(\` \|)/\1$2\2/" "$1/SSOT/STATUS.md"
}

facet_base() { # $1=root — migrate the minimal fixture to the v2.57 physical layout.
  local r="$1"
  mkdir -p "$r/SSOT/04-records"
  mv "$r/SSOT/product" "$r/SSOT/01-product"
  mv "$r/SSOT/architecture" "$r/SSOT/02-architecture"
  mv "$r/SSOT/gotchas" "$r/SSOT/04-records/gotchas"
  sed -i 's#product/README.md#01-product/README.md#g; s#architecture/README.md#02-architecture/README.md#g' "$r/SSOT/README.md"
  sed -i 's#../../architecture/README.md#../../02-architecture/README.md#g' "$r/SSOT/01-product/capabilities/README.md"
  set_protocol_version "$r" "2.57"
}

echo "== S0 bundle package shape (each skill has SKILL.md + agents/openai.yaml) =="
for skill in ssot-preflight ssot-bootstrap ssot-closeout ssot-audit ssot-doctor ssot-skill; do
  assert_file "$skill has SKILL.md" "$SKILLS_DIR/$skill/SKILL.md"
  assert_file "$skill has agents/openai.yaml" "$SKILLS_DIR/$skill/agents/openai.yaml"
done
TEMPLATE_ROOT="$SKILLS_DIR/ssot-bootstrap/assets/templates"
for template in product-readme.md product-prd.md product-model.md product-roadmap-and-acceptance.md product-capabilities-readme.md product-journeys-readme.md product-capability-entry.md product-journey-entry.md benchmark-readme.md operations-readme.md security-and-compliance-readme.md reader-review.md; do
  if [[ -d "$TEMPLATE_ROOT/en" || -d "$TEMPLATE_ROOT/zh" ]]; then
    # Source bundle: canonical templates remain bilingual.
    assert_file "template en/$template exists" "$TEMPLATE_ROOT/en/$template"
    assert_file "template zh/$template exists" "$TEMPLATE_ROOT/zh/$template"
  else
    # Installed bundle: the selected language is intentionally flattened.
    assert_file "installed template $template exists" "$TEMPLATE_ROOT/$template"
  fi
done
if [[ "${SSOT_TEST_PACKAGE_SHAPE_ONLY:-0}" == "1" ]]; then
  echo ""
  echo "===== summary: PASS=$PASS FAIL=$FAIL ====="
  [[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
fi

echo "== S1 clean (all PASS, exit 0) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
out=$(run "$T"); code=$?
assert_exit "clean exits 0" "$code" "0"
assert_not_contains "clean has no FAIL" "$out" "[FAIL]"
assert_not_contains "clean has no WARN" "$out" "[WARN]"
rm -rf "$T"

echo "== S2 architecture body contains hypothesis (check 6 -> FAIL) =="
T=$(mktemp -d); make_base "$T"
printf '\nconfidence: hypothesis\n' >> "$T/SSOT/architecture/README.md"
out=$(run "$T"); code=$?
assert_contains "hypothesis triggers FAIL" "$out" "confidence: hypothesis"
assert_exit "hypothesis exits 2" "$code" "2"
rm -rf "$T"

echo "== S3 handwritten AGENTS with SSOT routing (no ADAPTER WARN) =="
T=$(mktemp -d); make_base "$T"
printf '# 手写 AGENTS\n\n实质性任务开始前使用 $ssot-preflight，并按 SSOT/README.md 路由。\n' > "$T/AGENTS.md"
out=$(run "$T"); code=$?
assert_exit "handwritten routed file exits 0" "$code" "0"
assert_not_contains "handwritten routed file: no ADAPTER" "$out" "[ADAPTER]"
assert_not_contains "handwritten routed file: no WARN" "$out" "[WARN]"
rm -rf "$T"

echo "== S4 handwritten AGENTS without SSOT routing (check 9 -> CONSUMPTION) =="
T=$(mktemp -d); make_base "$T"
printf '# 手写 AGENTS\n\n这里只有仓库命令，没有长期记忆入口。\n' > "$T/AGENTS.md"
out=$(run "$T"); code=$?
assert_contains "handwritten unrouted triggers CONSUMPTION" "$out" "[CONSUMPTION]"
assert_exit "handwritten unrouted exits 1" "$code" "1"
assert_not_contains "handwritten unrouted: no ADAPTER" "$out" "[ADAPTER]"
rm -rf "$T"

echo "== S5 SSOT-generated adapter: source hash drift (check 7 -> WARN) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
printf '\n额外改动导致源 hash 变化。\n' >> "$T/SSOT/architecture/README.md"
out=$(run "$T"); code=$?
assert_contains "source drift triggers WARN" "$out" "source file changed"
rm -rf "$T"

echo "== S6 SSOT-generated adapter: too long (check 7 -> WARN) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
for i in $(seq 1 55); do printf 'extra line %s\n' "$i" >> "$T/AGENTS.md"; done
out=$(run "$T"); code=$?
assert_contains "over-length triggers WARN" "$out" "exceeds 50 lines"
rm -rf "$T"

echo "== S7 evidence symbol stale (check 8 -> STALE) =="
T=$(mktemp -d); make_base "$T"
sed -i 's/#barFunc/#ghostFunc/' "$T/SSOT/gotchas/0001-x.md"
out=$(run "$T"); code=$?
assert_contains "missing symbol triggers STALE" "$out" "[STALE] evidence symbol not found"
rm -rf "$T"

echo "== S8 SSOT-generated adapter without SSOT routing (check 9 -> CONSUMPTION) =="
T=$(mktemp -d); make_base "$T"
{
  printf '<!-- SSOT-generated | generated_at: 2026-05-29 -->\n'
  printf '# proj\n\n这里没有指向长期记忆目录的指令。\n'
} > "$T/AGENTS.md"
out=$(run "$T"); code=$?
assert_contains "no SSOT routing triggers CONSUMPTION" "$out" "[CONSUMPTION]"
rm -rf "$T"

echo "== S9 product skeleton missing (check 10 -> PRODUCT FAIL) =="
T=$(mktemp -d); make_base "$T"
rm -rf "$T/SSOT/product/journeys"
out=$(run "$T"); code=$?
assert_contains "missing product skeleton triggers PRODUCT" "$out" "[PRODUCT]"
assert_exit "missing product skeleton exits 2" "$code" "2"
rm -rf "$T"

echo "== S10 STATUS missing product row (check 1 -> FAIL) =="
T=$(mktemp -d); make_base "$T"
sed -i '/| product |/d' "$T/SSOT/STATUS.md"
out=$(run "$T"); code=$?
assert_contains "missing product row triggers FAIL" "$out" "missing required product row"
assert_exit "missing product row exits 2" "$code" "2"
rm -rf "$T"

echo "== S11 decisions entry missing lifecycle fields (check 11 -> DECISION FAIL) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/decisions"
printf '# Decisions\n' > "$T/SSOT/decisions/README.md"
# Decision entry with only status; missing implementation_state/created_on/introduced_in.
{
  printf -- '---\nstatus: accepted\n---\n# 0001 Example\n'
} > "$T/SSOT/decisions/0001-example.md"
out=$(run "$T"); code=$?
assert_contains "missing implementation_state triggers DECISION" "$out" "[DECISION]"
assert_contains "missing created_on flagged" "$out" "missing required field 'created_on'"
assert_contains "missing introduced_in flagged" "$out" "missing required field 'introduced_in'"
assert_exit "missing decision fields exits 2" "$code" "2"
rm -rf "$T"

echo "== S12 decisions entry with all required fields (check 11 -> PASS) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/decisions"
printf '# Decisions\n\n## Easily confused with\n\n（待补充）\n\n## Out of scope\n\n（待补充）\n' > "$T/SSOT/decisions/README.md"
{
  printf -- '---\nstatus: accepted\nimplementation_state: pending\ncreated_on: 2026-06-12\nupdated_on: 2026-06-12\nintroduced_in: abcdef1\nclosure_condition: "implementation_state becomes implemented or decision is superseded"\nrevisit_signal: "path-glob:src/**"\n---\n# 0001 Example\n'
} > "$T/SSOT/decisions/0001-example.md"
out=$(run "$T"); code=$?
assert_not_contains "complete decision entry has no DECISION FAIL" "$out" "[DECISION]"
assert_exit "complete decision entry exits 0" "$code" "0"
rm -rf "$T"

echo "== S13 bootstrap-archaeology archive is exempt (check 11) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/decisions"
printf '# Decisions\n\n## Easily confused with\n\n（待补充）\n\n## Out of scope\n\n（待补充）\n' > "$T/SSOT/decisions/README.md"
{
  printf -- '---\nid: DEC-0000\ntype: bootstrap-archaeology\nstatus: archived\narchived_at: 2026-06-12\n---\n# 0000 Bootstrap Recon\n'
} > "$T/SSOT/decisions/0000-bootstrap-recon.md"
out=$(run "$T"); code=$?
assert_not_contains "archaeology archive exempt from DECISION check" "$out" "[DECISION]"
assert_exit "archaeology-only decisions area exits 0" "$code" "0"
rm -rf "$T"

echo "== S14 STATUS Notes ledger warning (check 5 -> STATUS-NOTES-LEDGER WARN) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
resolve_template_placeholders "$T"
sed -i 's/| product | gap | |/| product | covered | 2026-06-13 BUG-0001 批次验证 passed |/' "$T/SSOT/STATUS.md"
out=$(run "$T"); code=$?
assert_contains "STATUS notes ledger triggers WARN tag" "$out" "[STATUS-NOTES-LEDGER]"
assert_exit "STATUS notes ledger exits 1" "$code" "1"
rm -rf "$T"

echo "== S14a STATUS Date column is not a Notes ledger =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
sed -i \
  -e 's/| 区域 | 状态 | 备注 |/| 区域 | 状态 | 日期 | 备注 |/' \
  -e 's/|---|---|---|/|---|---|---|---|/' \
  -e 's/| product | gap | |/| product | gap | 2026-07-13 | |/' \
  -e 's/| architecture | gap | |/| architecture | gap | 2026-07-13 | |/' \
  "$T/SSOT/STATUS.md"
out=$(run "$T"); code=$?
assert_not_contains "explicit STATUS Date column has no Notes-ledger warning" "$out" "[STATUS-NOTES-LEDGER]"
assert_exit "explicit STATUS Date column exits 0" "$code" "0"
rm -rf "$T"

echo "== S15 README derived-state warning (check 5b -> INDEX-DERIVED-STATE WARN) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
printf '\n本仓库目前索引 12 条 bug，其中 10 条 fixed、2 条 active。\n' >> "$T/SSOT/product/README.md"
out=$(run "$T"); code=$?
assert_contains "README derived state triggers WARN tag" "$out" "[INDEX-DERIVED-STATE]"
assert_exit "README derived state exits 1" "$code" "1"
rm -rf "$T"

echo "== S15a release owner may explain the literal latest image tag =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/release"
printf '# 发布\n\n镜像标签 `latest` 只是可变别名；发布前需要重新拉取验证镜像身份。\n\n## 容易混淆\n\n本页不负责产品验收，另见 product owner。\n\n## 不负责\n\n运行时实现另见 architecture owner。\n' > "$T/SSOT/release/README.md"
out=$(run "$T"); code=$?
assert_not_contains "literal latest image tag is not derived-state mirroring" "$out" "[INDEX-DERIVED-STATE]"
assert_exit "literal latest image tag exits 0" "$code" "0"
rm -rf "$T"

echo "== S15b explicit latest verification mirror still warns =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
printf '\nLatest verification: smoke passed on 2026-07-13.\n' >> "$T/SSOT/product/README.md"
out=$(run "$T"); code=$?
assert_contains "explicit latest verification mirror triggers INDEX-DERIVED-STATE" "$out" "[INDEX-DERIVED-STATE]"
assert_exit "explicit latest verification mirror exits 1" "$code" "1"
rm -rf "$T"

echo "== S16 non-owner shadow ledger warning (check 5c -> SHADOW-LEDGER WARN) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/development"
printf '# Audit Playbook\n\n## 验证说明\n\n2026-06-13 smoke passed。\n' > "$T/SSOT/development/audit-playbook.md"
out=$(run "$T"); code=$?
assert_contains "shadow ledger triggers WARN tag" "$out" "[SHADOW-LEDGER]"
assert_exit "shadow ledger exits 1" "$code" "1"
rm -rf "$T"

echo "== S17 STATUS last_stop_review ledger warning (check 5d -> STATUS-STOP-REVIEW-LEDGER WARN) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
printf '\n| last_stop_review | pytest passed, Playwright screenshot archived, Browser DOM verification command output copied into STATUS |\n' >> "$T/SSOT/STATUS.md"
out=$(run "$T"); code=$?
assert_contains "STATUS stop-review ledger triggers WARN tag" "$out" "[STATUS-STOP-REVIEW-LEDGER]"
assert_exit "STATUS stop-review ledger exits 1" "$code" "1"
rm -rf "$T"

echo "== S18 fixed major bug entry missing quick entry warning (check 5e -> ENTRY-ACTIONABILITY WARN) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/bugs"
printf '# Bugs\n' > "$T/SSOT/bugs/README.md"
printf -- '---\nstatus: fixed\nseverity: major\n---\n# Runtime output missing\n\n## Root cause\n\nThe event was not projected.\n' > "$T/SSOT/bugs/0001-runtime-output.md"
out=$(run "$T"); code=$?
assert_contains "bug missing quick entry triggers WARN tag" "$out" "[ENTRY-ACTIONABILITY]"
assert_exit "bug missing quick entry exits 1" "$code" "1"
rm -rf "$T"

echo "== S19 stop-review section ledger warning (check 5d -> STATUS-STOP-REVIEW-LEDGER WARN) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
printf '\n## 停止审查闸门\n\n| scope | result | evidence |\n|---|---|---|\n| protocol | passed | pytest command output copied here, Playwright screenshot copied here, full verification transcript copied here |\n' >> "$T/SSOT/STATUS.md"
out=$(run "$T"); code=$?
assert_contains "stop-review section ledger triggers WARN tag" "$out" "[STATUS-STOP-REVIEW-LEDGER]"
assert_exit "stop-review section ledger exits 1" "$code" "1"
rm -rf "$T"

echo "== S20 overlong markdown line warning (check 5f -> READABILITY-LONG-LINE WARN) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
printf '\n' >> "$T/SSOT/product/prd.md"
for _ in $(seq 1 950); do printf 'x' >> "$T/SSOT/product/prd.md"; done
printf '\n' >> "$T/SSOT/product/prd.md"
out=$(run "$T"); code=$?
assert_contains "overlong line triggers WARN tag" "$out" "[READABILITY-LONG-LINE]"
assert_exit "overlong line exits 1" "$code" "1"
rm -rf "$T"

echo "== S21 reader-owner table-density warning (check 5g -> KISS-TABLE-DENSITY WARN) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
{
  printf -- '---\nintent_recovery: gap\n---\n'
  printf '# 表格化文档\n\n这份文档只有一句开场，然后用表格承载全部内容。\n\n'
  printf '| a | b | c |\n|---|---|---|\n'
  for i in $(seq 1 75); do printf '| row-%s | value | value |\n' "$i"; done
} > "$T/SSOT/architecture/README.md"
out=$(run "$T"); code=$?
assert_contains "table density triggers KISS WARN tag" "$out" "[KISS-TABLE-DENSITY]"
assert_exit "table density exits 1" "$code" "1"
rm -rf "$T"

echo "== S21a machine manifest table density is governed by manifest checks =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
{
  printf -- '---\nmanifest_archetype: architecture-root\nintent_recovery: gap\n---\n'
  printf '# Architecture registry\n\n| ID | Owner | State |\n|---|---|---|\n'
  for i in $(seq 1 75); do printf '| tech:%s | owner:runtime | contract |\n' "$i"; done
} > "$T/SSOT/architecture/_manifest.md"
out=$(run "$T"); code=$?
assert_not_contains "machine _manifest.md has no generic KISS table-density warning" "$out" "[KISS-TABLE-DENSITY]"
assert_exit "machine _manifest.md table density exits 0" "$code" "0"
rm -rf "$T"

echo "== S22 v2.38 missing source inventory (check 5h -> SOURCE-INVENTORY FAIL) =="
T=$(mktemp -d); make_base "$T"; set_protocol_238 "$T"
mkdir -p "$T/docs"
printf '# Working Note\n\nCurrent runtime API notes without inventory.\n' > "$T/docs/work-note.md"
out=$(run "$T"); code=$?
assert_contains "missing source inventory triggers FAIL tag" "$out" "[SOURCE-INVENTORY]"
assert_exit "missing source inventory exits 2" "$code" "2"
rm -rf "$T"

echo "== S22b covered architecture manifest without intent/truth narrative (check 5g2 -> INTENT-TRUTH-NARRATIVE WARN) =="
T=$(mktemp -d); make_base "$T"
sed -i 's/| architecture | gap | |/| architecture | covered | |/' "$T/SSOT/STATUS.md"
{
  printf -- '---\nintent_recovery: gap\n---\n'
  printf '# 架构\n\n'
  printf '## 设计简报\n\n这里是一句开场。\n\n'
  printf '本文档的核心恢复清单见 _manifest.md。\n'
} > "$T/SSOT/architecture/README.md"
add_clean_adapter "$T"
out=$(run "$T"); code=$?
assert_contains "missing intent/truth narrative triggers WARN tag" "$out" "[INTENT-TRUTH-NARRATIVE]"
assert_exit "missing intent/truth narrative exits 1" "$code" "1"
rm -rf "$T"

echo "== S22c covered architecture manifest with intent/truth narrative (check 5g2 -> PASS) =="
T=$(mktemp -d); make_base "$T"
sed -i 's/| architecture | gap | |/| architecture | covered | |/' "$T/SSOT/STATUS.md"
{
  printf -- '---\nintent_recovery: gap\n---\n'
  printf '# 架构\n\n'
  printf '## 设计简报\n\n这里是一句开场。\n\n'
  printf '## 设计意图与设计真相\n\n当前 runtime-owner 拆分解释了设计意图和设计真相。\n\n'
  printf '本文档的核心恢复清单见 _manifest.md。\n\n'
  printf '## Easily confused with\n\n无易混淆 owner。\n\n## Out of scope\n\n无。\n'
} > "$T/SSOT/architecture/README.md"
add_clean_adapter "$T"
out=$(run "$T"); code=$?
assert_not_contains "present intent/truth narrative has no WARN tag" "$out" "[INTENT-TRUTH-NARRATIVE]"
assert_exit "present intent/truth narrative exits 0" "$code" "0"
rm -rf "$T"

echo "== S22d product README narrative covers PRD manifest (check 5g2 -> PASS) =="
T=$(mktemp -d); make_base "$T"
resolve_template_placeholders "$T"
add_clean_adapter "$T"
sed -i 's/| product | gap | |/| product | covered | |/' "$T/SSOT/STATUS.md"
printf '\n## 产品意图与产品真相\n\n产品入口先解释用户、问题、承诺和当前真相。\n' >> "$T/SSOT/product/README.md"
{
  printf -- '---\nintent_recovery: gap\n---\n'
  printf '# PRD Spine\n\n'
  printf '本文档的核心恢复清单见 _manifest.md。\n'
} > "$T/SSOT/product/prd.md"
out=$(run "$T"); code=$?
assert_not_contains "product README narrative covers PRD manifest" "$out" "[INTENT-TRUTH-NARRATIVE]"
assert_exit "product README narrative exits 0" "$code" "0"
rm -rf "$T"

echo "== S23 v2.38 complete working-doc lifecycle header (check 5h -> PASS) =="
T=$(mktemp -d); make_base "$T"; set_protocol_238 "$T"
mkdir -p "$T/docs"
cat > "$T/docs/poc-plan.md" <<'EOF'
<!--
lifecycle: working/poc
authority: downgraded
owner: SSOT/architecture/sdk-agent-runtime/README.md
absorbed_to: SSOT/architecture/sdk-agent-runtime/README.md
do_not_use_for: current runtime/API authority
review_on: 2026-06-16
-->
# PoC Plan

Current runtime API notes are exploratory; use the SSOT owner for authority.
EOF
out=$(run "$T"); code=$?
assert_not_contains "complete lifecycle header has no SOURCE-INVENTORY FAIL" "$out" "[SOURCE-INVENTORY]"
assert_not_contains "complete lifecycle header has no SOURCE-LIFECYCLE FAIL" "$out" "[SOURCE-LIFECYCLE]"
assert_exit "complete lifecycle header exits 0" "$code" "0"
rm -rf "$T"

echo "== S24 v2.38 strong facts without downgrade fields (check 5h -> SOURCE-LIFECYCLE FAIL) =="
T=$(mktemp -d); make_base "$T"; set_protocol_238 "$T"
mkdir -p "$T/docs"
printf '# Draft\n\nCurrent SDK runtime schema details.\n' > "$T/docs/draft.md"
printf '\n| Draft | docs/draft.md | lifecycle=working/draft | absorb | authority=downgraded | owner=SSOT/architecture/README.md | | review_on=2026-06-16 |\n' >> "$T/SSOT/STATUS.md"
out=$(run "$T"); code=$?
assert_contains "strong facts without downgrade triggers SOURCE-LIFECYCLE" "$out" "[SOURCE-LIFECYCLE]"
assert_exit "strong facts without downgrade exits 2" "$code" "2"
rm -rf "$T"

echo "== S25 v2.38 public thin doc without owner (check 5h -> THIN-DOCS FAIL) =="
T=$(mktemp -d); make_base "$T"; set_protocol_238 "$T"
mkdir -p "$T/docs"
cat > "$T/docs/public.md" <<'EOF'
<!--
lifecycle: public/thin-entry
authority: current
absorbed_to: SSOT/product/README.md
review_on: 2026-06-16
-->
# Public Entry
EOF
out=$(run "$T"); code=$?
assert_contains "public thin without owner triggers THIN-DOCS" "$out" "[THIN-DOCS]"
assert_exit "public thin without owner exits 2" "$code" "2"
rm -rf "$T"

echo "== S26 v2.38 audited exclusion missing owner (check 5h -> SOURCE-EXCLUSION FAIL) =="
T=$(mktemp -d); make_base "$T"; set_protocol_238 "$T"
printf '\n| Generated docs | pattern=docs/generated/* reason=generated last_checked=2026-06-16 review_trigger=generator-change |\n' >> "$T/SSOT/STATUS.md"
out=$(run "$T"); code=$?
assert_contains "audited exclusion missing owner triggers SOURCE-EXCLUSION" "$out" "[SOURCE-EXCLUSION]"
assert_exit "audited exclusion missing owner exits 2" "$code" "2"
rm -rf "$T"

echo "== S27 product owns implementation detail warning (check 5i -> PRODUCT-ARCH-DRIFT WARN) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/product/capabilities"
printf -- '---\nintent_recovery: gap\n---\n# Capability\n\n## API Reference\n\nRuntime endpoint details belong in architecture.\n' > "$T/SSOT/product/capabilities/01-bad.md"
out=$(run "$T"); code=$?
assert_contains "product implementation heading triggers PRODUCT-ARCH-DRIFT" "$out" "[PRODUCT-ARCH-DRIFT]"
assert_exit "product implementation heading exits 1" "$code" "1"
rm -rf "$T"

echo "== S28 checklist-heavy architecture warning (check 5i -> ARCH-CHECKLIST-HEAVY WARN) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/architecture/01-foo"
{
  printf -- '---\nintent_recovery: gap\n---\n'
  printf '# Foo\n\n'
  for i in $(seq 1 19); do printf '## Section %s\n\n<placeholder-%s>\n\n' "$i" "$i"; done
} > "$T/SSOT/architecture/01-foo/README.md"
out=$(run "$T"); code=$?
assert_contains "checklist-heavy architecture triggers ARCH-CHECKLIST-HEAVY" "$out" "[ARCH-CHECKLIST-HEAVY]"
assert_exit "checklist-heavy architecture exits 1" "$code" "1"
rm -rf "$T"

echo "== S29 unclosed markdown fence (check 23 -> MARKDOWN-FENCE FAIL) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
printf '\n```text\nunterminated\n' >> "$T/SSOT/product/prd.md"
out=$(run "$T"); code=$?
assert_contains "unclosed fence triggers MARKDOWN-FENCE" "$out" "[MARKDOWN-FENCE]"
assert_exit "unclosed fence exits 2" "$code" "2"
rm -rf "$T"

echo "== S30 partial ADR missing closure fields (check 24 -> ADR-CLOSURE FAIL) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/decisions"
printf '# Decisions\n' > "$T/SSOT/decisions/README.md"
{
  printf -- '---\nstatus: accepted\nimplementation_state: partial\ncreated_on: 2026-06-30\nupdated_on: 2026-06-30\nintroduced_in: abcdef1\n---\n# 0001 Partial\n'
} > "$T/SSOT/decisions/0001-partial.md"
out=$(run "$T"); code=$?
assert_contains "partial ADR missing closure triggers ADR-CLOSURE" "$out" "[ADR-CLOSURE]"
assert_exit "partial ADR missing closure exits 2" "$code" "2"
rm -rf "$T"

echo "== S31 active debt missing closure fields (check 24 -> DEBT-CLOSURE FAIL) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/tech-debt"
printf '# Tech debt\n\n## Easily confused with\n\nThis index does not own implementation detail; see the architecture owner.\n\n## Out of scope\n\nRelease execution belongs to the release owner.\n' > "$T/SSOT/tech-debt/README.md"
printf -- '---\nid: DEBT-0001\nstatus: active\npriority: high\n---\n# Active debt\n' > "$T/SSOT/tech-debt/0001-active.md"
out=$(run "$T"); code=$?
assert_contains "active debt missing closure triggers DEBT-CLOSURE" "$out" "[DEBT-CLOSURE]"
assert_exit "active debt missing closure exits 2" "$code" "2"
rm -rf "$T"

echo "== S32 temporary debt missing owner/reason/guard (check 24 -> TEMP-SURFACE FAIL) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/tech-debt"
printf '# Tech debt\n' > "$T/SSOT/tech-debt/README.md"
{
  printf -- '---\nid: DEBT-0002\nstatus: active\npriority: medium\ntemporary_surface: true\nclosure_condition: "grep -nR TODO src returns no match"\nrevisit_signal: "path-glob:src/**"\n---\n# Temporary surface\n'
} > "$T/SSOT/tech-debt/0002-temp.md"
out=$(run "$T"); code=$?
assert_contains "temporary debt missing guard fields triggers TEMP-SURFACE" "$out" "[TEMP-SURFACE]"
assert_exit "temporary debt missing guard fields exits 2" "$code" "2"
rm -rf "$T"

echo "== S33 covered area with placeholder residue (check 25 -> COVERED-PLACEHOLDER FAIL) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
printf '\nTODO: replace this starter section.\n' >> "$T/SSOT/product/README.md"
sed -i 's/| product | gap | |/| product | covered | |/' "$T/SSOT/STATUS.md"
out=$(run "$T"); code=$?
assert_contains "covered placeholder triggers COVERED-PLACEHOLDER" "$out" "[COVERED-PLACEHOLDER]"
assert_exit "covered placeholder exits 2" "$code" "2"
rm -rf "$T"

echo "== S34 STATUS only/no remaining contradicts open gaps (check 26 -> STATUS-AGGREGATE FAIL) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
printf '\n| last_stop_review | remaining=existing non-blocking gaps only (DEBT-0009) |\n\n## Open Gaps\n\n| Area | Status | Gap description | Blocking level |\n|---|---|---|---|\n| testing | gap | Browser smoke missing | non-blocking |\n| release | gap | Release automation missing | non-blocking |\n' >> "$T/SSOT/STATUS.md"
out=$(run "$T"); code=$?
assert_contains "contradictory remaining summary triggers STATUS-AGGREGATE" "$out" "[STATUS-AGGREGATE]"
assert_contains "contradictory remaining summary emits the aggregate diagnostic" "$out" "stop/status summary claims"
assert_exit "contradictory remaining summary exits 2" "$code" "2"
rm -rf "$T"

echo "== S34a actionable Chinese gap text is not a stop summary =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/tech-debt"
printf '# Tech debt\n' > "$T/SSOT/tech-debt/README.md"
printf '%s\n' '---' 'id: DEBT-0019' 'status: resolved' 'priority: medium' '---' '# Shell integration gap' > "$T/SSOT/tech-debt/0019-shell-integration.md"
printf '\n## Open Gaps\n\n| Area | Status | Gap description | Blocking level |\n|---|---|---|---|\n| shell integration | gap | 只有单元 harness 时阻断集成正确声明 | [DEBT-0019](tech-debt/0019-shell-integration.md) |\n' >> "$T/SSOT/STATUS.md"
out=$(run "$T"); code=$?
assert_not_contains "Open Gaps actionability text is excluded from aggregate summaries" "$out" "stop/status summary claims"
assert_not_exit "Open Gaps actionability text is not a hard aggregate failure" "$code" "2"
rm -rf "$T"

echo "== S35 open gap with待立 debt and no owner (check 27 -> GAP-OWNER FAIL) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
printf '\n## Open Gaps\n\n| Area | Status | Gap description | Blocking level |\n|---|---|---|---|\n| testing | gap | frontend lint CI 待立 tech-debt | non-blocking |\n' >> "$T/SSOT/STATUS.md"
out=$(run "$T"); code=$?
assert_contains "unowned gap triggers GAP-OWNER" "$out" "[GAP-OWNER]"
assert_exit "unowned gap exits 2" "$code" "2"
rm -rf "$T"

echo "== S36 STATUS resolved capture with pending action (check 28 -> CAPTURE-LIFECYCLE FAIL) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
printf '\n### Pending Captures (cycle passed)\n\nCycle passed. Pending action: add this later during the next audit batch.\n' >> "$T/SSOT/STATUS.md"
out=$(run "$T"); code=$?
assert_contains "pending action in capture triggers CAPTURE-LIFECYCLE" "$out" "[CAPTURE-LIFECYCLE]"
assert_exit "pending action in capture exits 2" "$code" "2"
rm -rf "$T"

echo "== S36b registered owner file with TODO debt wording passes check 28b =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/tech-debt"
printf '# Tech debt\n\n## Easily confused with\n\nnone\n\n## Out of scope\n\nnone -- covers complete intent\n' > "$T/SSOT/tech-debt/README.md"
printf -- '---\nid: DEBT-0004\nstatus: active\npriority: medium\nowner: platform team\nclosure_condition: "real owner is registered"\nrevisit_signal: "path-glob:SSOT/**"\nverification_guard: "ssot-lint passes"\n---\n# Placeholder debt\n\nTODO debt: capture the real owner later.\n\n## Agent quick entry\n\nTrigger: SSOT owner changes. First check: run ssot-lint. Do not close without lint evidence.\n' > "$T/SSOT/tech-debt/0004-placeholder-debt.md"
out=$(run "$T"); code=$?
assert_no_fail_tag "registered owner placeholder is not misclassified" "$out" "[CAPTURE-LIFECYCLE]"
assert_exit "registered owner placeholder exits 0" "$code" "0"
rm -rf "$T"

echo "== S36c unregistered owner file with TODO debt placeholder fails check 28b =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/tech-debt"
printf '# Tech debt\n\n## Easily confused with\n\nnone\n\n## Out of scope\n\nnone -- covers complete intent\n' > "$T/SSOT/tech-debt/README.md"
printf -- '---\nid: DEBT-0005\nstatus: resolved\npriority: medium\n---\n# Placeholder debt\n\nTODO debt: capture the real owner later.\n' > "$T/SSOT/tech-debt/0005-unregistered-placeholder.md"
out=$(run "$T"); code=$?
assert_contains "unregistered placeholder debt triggers CAPTURE-LIFECYCLE" "$out" "[CAPTURE-LIFECYCLE] owner file contains placeholder follow-up wording"
assert_exit "unregistered placeholder debt exits 2" "$code" "2"
rm -rf "$T"

echo "== S36d quoted and fenced placeholder examples are ignored =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/tech-debt"
printf '# Tech debt\n\n## Easily confused with\n\nnone\n\n## Out of scope\n\nnone -- covers complete intent\n' > "$T/SSOT/tech-debt/README.md"
printf -- '---\nid: DEBT-0006\nstatus: resolved\npriority: low\n---\n# Historical wording\n\n> TODO debt: capture the real owner later.\n\n```text\nPending action: follow up later\n```\n' > "$T/SSOT/tech-debt/0006-historical-wording.md"
out=$(run "$T"); code=$?
assert_no_fail_tag "quoted/fenced placeholder has no CAPTURE-LIFECYCLE fail" "$out" "[CAPTURE-LIFECYCLE]"
assert_exit "quoted/fenced placeholder exits 0" "$code" "0"
rm -rf "$T"

echo "== S37 open gap with vague later wording and no owner (check 29 -> SILENT-DEFERRAL FAIL) =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
printf '\n## Open Gaps\n\n| Area | Status | Gap description | Blocking level |\n|---|---|---|---|\n| testing | gap | Handle frontend lint later when convenient | non-blocking |\n' >> "$T/SSOT/STATUS.md"
out=$(run "$T"); code=$?
assert_contains "silent deferral triggers SILENT-DEFERRAL" "$out" "[SILENT-DEFERRAL]"
assert_exit "silent deferral exits 2" "$code" "2"
rm -rf "$T"

echo "== S38 owner-backed deferral with revisit signal passes check 29 =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/tech-debt"
printf '# Tech debt\n\n## Easily confused with\n\nnone\n\n## Out of scope\n\nnone -- covers complete intent\n' > "$T/SSOT/tech-debt/README.md"
{
  printf -- '---\nid: DEBT-0003\nstatus: active\npriority: medium\nowner: SSOT/tech-debt/0003-visible.md\nclosure_condition: "tests/frontend-lint passes in CI"\nrevisit_signal: "path-glob:frontend/**"\nverification_guard: "npm run lint"\n---\n# Visible deferral\n\nHandle this later only when the frontend lint CI gate is touched.\n'
  printf '\n## Agent quick entry\n\nTrigger: frontend lint CI changes. First check: `npm run lint`. Do not close without CI evidence.\n'
} > "$T/SSOT/tech-debt/0003-visible.md"
out=$(run "$T"); code=$?
assert_exit "owner-backed deferral exits 0" "$code" "0"
assert_no_fail_tag "owner-backed deferral has no SILENT-DEFERRAL fail" "$out" "[SILENT-DEFERRAL]"
rm -rf "$T"

echo "== S39 valid research record passes check 30 =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/04-records/research"
printf '# 研究记录\n\n本页只索引有来源的研究证据包。它不负责声明当前产品或运行事实；请转到每条记录列出的 SSOT 事实所有者。\n\n- [0001 sandbox options](0001-sandbox-options.md)\n' > "$T/SSOT/04-records/research/README.md"
{
  printf -- '---\nstatus: source-backed\nkind: poc\ncreated_on: 2026-06-30\nowner: platform team\npromotion_targets: [SSOT/02-architecture/domains/sandbox/README.md]\nrecheck_trigger: "runtime isolation model changes"\n---\n'
  printf '# Sandbox options\n\n## Question\n\nWhich local execution option is practical?\n\n## Conclusion\n\nUse direct shell first and container isolation only when the run needs it.\n\n## Applicability and boundaries\n\n'
  printf 'do_not_use_for: production isolation guarantees.\n\n## Candidates / options\n\n- direct shell\n- container fallback\n\n## Method and environment\n\nSmall local smoke on a synthetic project.\n\n'
  printf '## Verification steps\n\n1. Run the smoke command.\n\n## Evidence\n\n- command exited 0.\n\n## Negative findings\n\n- container startup was slower.\n\n'
  printf '## Reusable claim rows\n\n| Claim | Confidence | Evidence |\n|---|---|---|\n| direct shell is enough for this POC | source-backed | smoke output |\n\n'
  printf '## Promoted SSOT owners\n\n- SSOT/02-architecture/domains/sandbox/README.md\n\n## Follow-up actions\n\n- Recheck when the runtime isolation model changes.\n'
} > "$T/SSOT/04-records/research/0001-sandbox-options.md"
out=$(run "$T"); code=$?
assert_exit "valid research record exits 0" "$code" "0"
assert_no_fail_tag "valid research record has no RESEARCH-RECORD fail" "$out" "[RESEARCH-RECORD]"
rm -rf "$T"

echo "== S40 research record missing required frontmatter fails check 30 =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/04-records/research"
printf '# 研究记录\n\n本页只索引有来源的研究证据包。它不负责声明当前产品或运行事实；请转到每条记录列出的 SSOT 事实所有者。\n' > "$T/SSOT/04-records/research/README.md"
{
  printf -- '---\nstatus: source-backed\nkind: research\ncreated_on: 2026-06-30\nowner: platform team\npromotion_targets: [SSOT/testing/README.md]\n---\n'
  printf '# Missing trigger\n\n## Applicability and boundaries\n\ndo_not_use_for: current production fact.\n'
} > "$T/SSOT/04-records/research/0001-missing-trigger.md"
out=$(run "$T"); code=$?
assert_contains "missing research frontmatter triggers RESEARCH-RECORD" "$out" "[RESEARCH-RECORD]"
assert_contains "missing recheck_trigger flagged" "$out" "missing required frontmatter field 'recheck_trigger'"
assert_exit "missing research frontmatter exits 2" "$code" "2"
rm -rf "$T"

echo "== S41 top-level research directory fails check 30 =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/research"
printf '# Wrong research area\n' > "$T/SSOT/research/README.md"
out=$(run "$T"); code=$?
assert_contains "top-level research triggers RESEARCH-RECORD" "$out" "top-level SSOT/research is not a valid authority area"
assert_exit "top-level research exits 2" "$code" "2"
rm -rf "$T"

echo "== S42 unnumbered research entry fails check 30 =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/04-records/research"
printf '# Research records\n' > "$T/SSOT/04-records/research/README.md"
printf -- '---\nstatus: source-backed\nkind: poc\ncreated_on: 2026-06-30\nowner: platform team\npromotion_targets: [SSOT/testing/README.md]\nrecheck_trigger: "test harness changes"\n---\n# Bad name\n\n## Applicability and boundaries\n\ndo_not_use_for: current production fact.\n' > "$T/SSOT/04-records/research/sandbox-options.md"
out=$(run "$T"); code=$?
assert_contains "bad research filename triggers RESEARCH-RECORD" "$out" "must use NNNN-<slug>.md"
assert_exit "bad research filename exits 2" "$code" "2"
rm -rf "$T"

echo "== S43 faceted process layout missing benchmark owner fails check 31 =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/03-process/testing"
printf '# Testing\n' > "$T/SSOT/03-process/testing/README.md"
out=$(run "$T"); code=$?
assert_contains "missing benchmark owner triggers BENCHMARK-OWNER" "$out" "[BENCHMARK-OWNER]"
assert_exit "missing benchmark owner exits 2" "$code" "2"
rm -rf "$T"

echo "== S44 faceted benchmark owner passes check 31 =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/03-process/testing" "$T/SSOT/03-process/benchmark"
printf '# 测试\n\nCorrectness gates live here.\n\n## Easily confused with\n\n无。\n\n## Out of scope\n\n无。\n' > "$T/SSOT/03-process/testing/README.md"
printf '# 基准测试\n\nStable suites and floors live here.\n\n## Easily confused with\n\n无。\n\n## Out of scope\n\n无。\n' > "$T/SSOT/03-process/benchmark/README.md"
out=$(run "$T"); code=$?
assert_no_fail_tag "benchmark owner present has no BENCHMARK-OWNER fail" "$out" "[BENCHMARK-OWNER]"
assert_exit "benchmark owner present exits 0" "$code" "0"
rm -rf "$T"

echo "== S45 benchmark facts hidden in testing fail check 31 =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/testing"
printf '# Testing\n\nCurrent benchmark floor is p95 < 200ms and comparison rule is branch-to-branch.\n' > "$T/SSOT/testing/README.md"
out=$(run "$T"); code=$?
assert_contains "testing-owned benchmark floor triggers BENCHMARK-OWNER" "$out" "testing README appears to own benchmark floors"
assert_exit "testing-owned benchmark floor exits 2" "$code" "2"
rm -rf "$T"

echo "== S46 benchmark run log warns check 31 =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/benchmark"
printf '# Benchmark Strategy\n\n## Recent benchmark run history\n\n2026-07-03 benchmark p95 passed.\n' > "$T/SSOT/benchmark/README.md"
out=$(run "$T"); code=$?
assert_contains "benchmark ledger triggers WARN" "$out" "[BENCHMARK-LEDGER]"
assert_exit "benchmark ledger exits 1" "$code" "1"
rm -rf "$T"

echo "== S47 canonical v2.57 architecture is scanned by legacy-era checks =="
T=$(mktemp -d); make_base "$T"; facet_base "$T"
printf '\nconfidence: hypothesis\n' >> "$T/SSOT/02-architecture/README.md"
out=$(run "$T"); code=$?
assert_contains "canonical architecture hypothesis is scanned" "$out" "architecture body contains confidence: hypothesis"
assert_exit "canonical architecture hypothesis exits 2" "$code" "2"
rm -rf "$T"

echo "== S48 canonical v2.57 decisions are scanned =="
T=$(mktemp -d); make_base "$T"; facet_base "$T"
mkdir -p "$T/SSOT/04-records/decisions"
printf '# Decisions\n' > "$T/SSOT/04-records/decisions/README.md"
printf -- '---\nstatus: accepted\n---\n# Missing lifecycle fields\n' > "$T/SSOT/04-records/decisions/0001-missing-fields.md"
out=$(run "$T"); code=$?
assert_contains "canonical decisions entry is scanned" "$out" "[DECISION]"
assert_contains "canonical decisions missing introduced_in is flagged" "$out" "missing required field 'introduced_in'"
assert_exit "canonical decisions missing fields exits 2" "$code" "2"
rm -rf "$T"

echo "== S49 v2.57 legacy directories fail FACETED-LAYOUT gate =="
T=$(mktemp -d); make_base "$T"
set_protocol_version "$T" "2.57"
out=$(run "$T"); code=$?
assert_contains "v2.57 legacy layout triggers FACETED-LAYOUT" "$out" "[FACETED-LAYOUT]"
assert_exit "v2.57 legacy layout exits 2" "$code" "2"
rm -rf "$T"

echo "== S50 pre-v2.57 legacy layout remains compatible and scanned =="
T=$(mktemp -d); make_base "$T"
set_protocol_version "$T" "2.56"
printf '\nconfidence: hypothesis\n' >> "$T/SSOT/architecture/README.md"
out=$(run "$T"); code=$?
assert_not_contains "pre-v2.57 legacy layout has no FACETED-LAYOUT failure" "$out" "[FACETED-LAYOUT]"
assert_contains "pre-v2.57 legacy architecture is still scanned" "$out" "architecture body contains confidence: hypothesis"
assert_exit "pre-v2.57 legacy hypothesis exits 2" "$code" "2"
rm -rf "$T"

echo "== S51 canonical v2.57 layout passes FACETED-LAYOUT gate =="
T=$(mktemp -d); make_base "$T"; facet_base "$T"
out=$(run "$T"); code=$?
assert_no_fail_tag "canonical layout has no FACETED-LAYOUT failure" "$out" "[FACETED-LAYOUT]"
assert_exit "canonical minimal layout exits 0" "$code" "0"
rm -rf "$T"

echo "== S51b v2.57 nested architecture domains fail FACETED-LAYOUT gate =="
T=$(mktemp -d); make_base "$T"; facet_base "$T"
mkdir -p "$T/SSOT/02-architecture/domains/runtime"
printf '# Runtime\n' > "$T/SSOT/02-architecture/domains/runtime/README.md"
out=$(run "$T"); code=$?
assert_contains "nested domains trigger FACETED-LAYOUT" "$out" "architecture domains must be direct numbered children"
assert_exit "nested domains exit 2" "$code" "2"
rm -rf "$T"

echo "== S51c v2.57 missing canonical architecture owner fails =="
T=$(mktemp -d); make_base "$T"; facet_base "$T"
rm "$T/SSOT/02-architecture/README.md"
out=$(run "$T"); code=$?
assert_contains "missing canonical architecture owner triggers FACETED-LAYOUT" "$out" "requires canonical owner"
assert_exit "missing canonical architecture owner exits 2" "$code" "2"
rm -rf "$T"

echo "== S52 long research frontmatter with block promotion_targets passes =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/04-records/research"
printf '# 研究记录\n\n本页只索引有来源的研究证据包。它不负责声明当前产品或运行事实；请转到每条记录列出的 SSOT 事实所有者。\n' > "$T/SSOT/04-records/research/README.md"
{
  printf -- '---\nstatus: source-backed\nkind: research\ncreated_on: 2026-07-10\nowner: platform team\npromotion_targets:\n  - SSOT/testing/README.md\n'
  for i in $(seq 1 48); do printf 'note_%02d: value\n' "$i"; done
  printf 'recheck_trigger: "test harness changes"\n---\n# Long packet\n\n## Applicability and boundaries\n\ndo_not_use_for: current production fact.\n'
} > "$T/SSOT/04-records/research/0001-long-frontmatter.md"
out=$(run "$T"); code=$?
assert_no_fail_tag "long block-list frontmatter has no RESEARCH-RECORD fail" "$out" "[RESEARCH-RECORD]"
assert_exit "long block-list frontmatter exits 0" "$code" "0"
rm -rf "$T"

echo "== S53 empty inline research promotion_targets fails =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/04-records/research"
printf '# Research records\n' > "$T/SSOT/04-records/research/README.md"
printf -- '---\nstatus: source-backed\nkind: research\ncreated_on: 2026-07-10\nowner: platform team\npromotion_targets: [ ]\nrecheck_trigger: "test harness changes"\n---\n# Empty targets\n\n## Applicability and boundaries\n\ndo_not_use_for: current production fact.\n' > "$T/SSOT/04-records/research/0001-empty-inline.md"
out=$(run "$T"); code=$?
assert_contains "empty inline promotion_targets is rejected" "$out" "promotion_targets must name owner targets"
assert_exit "empty inline promotion_targets exits 2" "$code" "2"
rm -rf "$T"

echo "== S54 empty block research promotion_targets fails =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/04-records/research"
printf '# Research records\n' > "$T/SSOT/04-records/research/README.md"
printf -- '---\nstatus: source-backed\nkind: research\ncreated_on: 2026-07-10\nowner: platform team\npromotion_targets:\nrecheck_trigger: "test harness changes"\n---\n# Empty targets\n\n## Applicability and boundaries\n\ndo_not_use_for: current production fact.\n' > "$T/SSOT/04-records/research/0001-empty-block.md"
out=$(run "$T"); code=$?
assert_contains "empty block promotion_targets is rejected" "$out" "promotion_targets must name owner targets"
assert_exit "empty block promotion_targets exits 2" "$code" "2"
rm -rf "$T"

echo "== S55 commented-empty research promotion_targets fails =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/04-records/research"
printf '# Research records\n' > "$T/SSOT/04-records/research/README.md"
printf -- '---\nstatus: source-backed\nkind: research\ncreated_on: 2026-07-10\nowner: platform team\npromotion_targets: # intentionally empty\nrecheck_trigger: "test harness changes"\n---\n# Empty targets\n\n## Applicability and boundaries\n\ndo_not_use_for: current production fact.\n' > "$T/SSOT/04-records/research/0001-comment-empty.md"
out=$(run "$T"); code=$?
assert_contains "commented-empty promotion_targets is rejected" "$out" "promotion_targets must name owner targets"
assert_exit "commented-empty promotion_targets exits 2" "$code" "2"
rm -rf "$T"

echo "== S56 empty-valued research promotion_targets list fails =="
T=$(mktemp -d); make_base "$T"; add_clean_adapter "$T"
mkdir -p "$T/SSOT/04-records/research"
printf '# Research records\n' > "$T/SSOT/04-records/research/README.md"
printf -- '---\nstatus: source-backed\nkind: research\ncreated_on: 2026-07-10\nowner: platform team\npromotion_targets:\n  - ""\n  - []\n  - # still empty\nrecheck_trigger: "test harness changes"\n---\n# Empty targets\n\n## Applicability and boundaries\n\ndo_not_use_for: current production fact.\n' > "$T/SSOT/04-records/research/0001-empty-valued-list.md"
out=$(run "$T"); code=$?
assert_contains "empty-valued promotion_targets list is rejected" "$out" "promotion_targets must name owner targets"
assert_exit "empty-valued promotion_targets list exits 2" "$code" "2"
rm -rf "$T"

echo "== S57 oversized STATUS preserves JSON diagnostics =="
code=0
bash "$(dirname "$LINT")/test/test-large-status-json.sh" || code=$?
assert_exit "large STATUS JSON diagnostics regression" "$code" "0"

echo "== S58 portable lexical path normalization =="
code=0
bash "$(dirname "$LINT")/test/test-lexical-path.sh" || code=$?
assert_exit "portable lexical normalization regression" "$code" "0"

echo "== S59 v2.63 valid HISTORY.md passes HISTORY-LOG =="
T=$(mktemp -d); make_base "$T"; facet_base "$T"
set_protocol_version "$T" "2.63"
{
  printf '# SSOT History\n\n'
  printf '| Date | Commit | Actor | Result | Touched | Note |\n'
  printf '|---|---|---|---|---|---|\n'
  printf '| 2026-07-10 | abc1234 | bootstrap | wrote | skeleton | initial skeleton |\n'
  printf '| 2026-07-11 | def5678 | closeout | no-op | none | - |\n'
} > "$T/SSOT/HISTORY.md"
out=$(run "$T"); code=$?
assert_no_fail_tag "valid history has no HISTORY-LOG fail" "$out" "[HISTORY-LOG]"
assert_no_warn_tag "valid history has no HISTORY-LOG warn" "$out" "[HISTORY-LOG]"
assert_contains "valid history reports schema pass" "$out" "batch write log rows match the append-only schema"
rm -rf "$T"

echo "== S60 v2.63 missing HISTORY.md warns =="
T=$(mktemp -d); make_base "$T"; facet_base "$T"
set_protocol_version "$T" "2.63"
out=$(run "$T"); code=$?
assert_has_warn_tag "missing history warns" "$out" "[HISTORY-LOG]"
assert_no_fail_tag "missing history does not fail" "$out" "[HISTORY-LOG]"
rm -rf "$T"

echo "== S61 v2.63 malformed HISTORY.md fails schema =="
T=$(mktemp -d); make_base "$T"; facet_base "$T"
set_protocol_version "$T" "2.63"
{
  printf '# SSOT History\n\n'
  printf '| Date | Commit | Actor | Result | Touched | Note |\n'
  printf '|---|---|---|---|---|---|\n'
  printf '| 2026-07-11 | abc1234 | closeout | wrote | STATUS.md | ok row |\n'
  printf '| 2026-07-09 | abc1234 | wizard | maybe | none | backward + bad actor/result |\n'
  printf '| 07/10/2026 | abc1234 | closeout | no-op | none | bad date |\n'
} > "$T/SSOT/HISTORY.md"
out=$(run "$T"); code=$?
assert_has_fail_tag "bad date fails" "$out" "[HISTORY-LOG]"
assert_contains "bad date flagged" "$out" "Date is not YYYY-MM-DD"
assert_contains "bad result flagged" "$out" "Result must be wrote or no-op"
assert_contains "non-monotonic order warned" "$out" "date goes backward"
rm -rf "$T"

echo "== S62 pre-v2.63 missing HISTORY.md is not checked =="
T=$(mktemp -d); make_base "$T"; facet_base "$T"
set_protocol_version "$T" "2.62"
out=$(run "$T"); code=$?
assert_not_contains "pre-v2.63 has no HISTORY-LOG at all" "$out" "[HISTORY-LOG]"
rm -rf "$T"

echo "== S63 v2.64 valid adjudication boundary passes INV-REGISTRY =="
T=$(mktemp -d); make_base "$T"; facet_base "$T"
set_protocol_version "$T" "2.64"
{
  printf '\n## Adjudication boundary\n\n'
  printf 'Rules an agent must not rewrite on its own; bodies stay at the owners.\n\n'
  printf '| ID | Kind | Rule | Owner | Established by | State |\n'
  printf '|---|---|---|---|---|---|\n'
  printf '| INV-01 | arch-invariant | requests must pass auth | [02-architecture/README.md](02-architecture/README.md) | DEC-0001 | confirmed |\n'
  printf '| INV-02 | product-promise | drafts never silently vanish | [01-product/product-model.md](01-product/product-model.md) | user-directive | candidate |\n'
  printf '| CLAUDE-MAXIM-1 | apex-maxim | never re-enter silent deferral | - | user-directive | not_yet_owned |\n'
} >> "$T/SSOT/README.md"
printf '\n- **INV-01** 请求必须经过鉴权。\n' >> "$T/SSOT/02-architecture/README.md"
out=$(run "$T"); code=$?
assert_no_fail_tag "valid boundary has no INV-REGISTRY fail" "$out" "[INV-REGISTRY]"
assert_no_fail_tag "valid boundary has no INV-BODY fail" "$out" "[INV-BODY]"
rm -rf "$T"

echo "== S64 v2.64 missing adjudication boundary warns =="
T=$(mktemp -d); make_base "$T"; facet_base "$T"
set_protocol_version "$T" "2.64"
out=$(run "$T"); code=$?
assert_has_warn_tag "missing boundary section warns" "$out" "[INV-REGISTRY]"
assert_no_fail_tag "missing boundary section does not fail" "$out" "[INV-REGISTRY]"
rm -rf "$T"

echo "== S65 v2.64 malformed boundary rows fail schema =="
T=$(mktemp -d); make_base "$T"; facet_base "$T"
set_protocol_version "$T" "2.64"
{
  printf '\n## Adjudication boundary\n\n'
  printf '| ID | Kind | Rule | Owner | Established by | State |\n'
  printf '|---|---|---|---|---|---|\n'
  printf '| INV-01 | arch-invariant | rule one | [02-architecture/README.md](02-architecture/README.md) | DEC-0001 | confirmed |\n'
  printf '| INV-01 | arch-invariant | duplicate id | [02-architecture/README.md](02-architecture/README.md) | DEC-0001 | confirmed |\n'
  printf '| INV-02 | wrong-kind | bad kind | [02-architecture/README.md](02-architecture/README.md) | DEC-0002 | confirmed |\n'
  printf '| INV-03 | process-rule | bad state | [02-architecture/README.md](02-architecture/README.md) | DEC-0003 | locked |\n'
  printf '| RULE-9 | apex-maxim | bad id shape | - | user-directive | not_yet_owned |\n'
} >> "$T/SSOT/README.md"
printf '\n- **INV-01** 请求必须经过鉴权。\n- **INV-02** x\n- **INV-03** y\n' >> "$T/SSOT/02-architecture/README.md"
out=$(run "$T"); code=$?
assert_has_fail_tag "duplicate id fails" "$out" "[INV-REGISTRY]"
assert_contains "bad kind flagged" "$out" "kind 'wrong-kind'"
assert_contains "bad state flagged" "$out" "state 'locked'"
assert_contains "bad id flagged" "$out" "id 'RULE-9'"
rm -rf "$T"

echo "== S66 v2.64 confirmed row without owner tag fails INV-BODY =="
T=$(mktemp -d); make_base "$T"; facet_base "$T"
set_protocol_version "$T" "2.64"
{
  printf '\n## Adjudication boundary\n\n'
  printf '| ID | Kind | Rule | Owner | Established by | State |\n'
  printf '|---|---|---|---|---|---|\n'
  printf '| INV-01 | arch-invariant | requests must pass auth | [02-architecture/README.md](02-architecture/README.md) | DEC-0001 | confirmed |\n'
} >> "$T/SSOT/README.md"
out=$(run "$T"); code=$?
assert_has_fail_tag "untagged confirmed owner fails" "$out" "[INV-BODY]"
assert_contains "untagged names the rule" "$out" "INV-01"
rm -rf "$T"

echo "== S67 v2.64 orphan body tag warns INV-BODY =="
T=$(mktemp -d); make_base "$T"; facet_base "$T"
set_protocol_version "$T" "2.64"
{
  printf '\n## Adjudication boundary\n\n'
  printf '当前没有跨任务红线需要登记：规则均为域内局部约束，下一次晋升信号是重复的越权修改。\n'
} >> "$T/SSOT/README.md"
printf '\n相关约束见 INV-09。\n' >> "$T/SSOT/04-records/gotchas/0001-x.md"
out=$(run "$T"); code=$?
assert_has_warn_tag "orphan body tag warns" "$out" "[INV-BODY]"
assert_contains "orphan names the id" "$out" "INV-09"
rm -rf "$T"

echo "== S68 v2.64 reasoned empty note passes =="
T=$(mktemp -d); make_base "$T"; facet_base "$T"
set_protocol_version "$T" "2.64"
{
  printf '\n## Adjudication boundary\n\n'
  printf '当前没有跨任务红线需要登记：所有约束均为域内局部规则，晋升信号是重复的越权修改或人工登记的决定。\n'
} >> "$T/SSOT/README.md"
out=$(run "$T"); code=$?
assert_no_fail_tag "empty note has no INV-REGISTRY fail" "$out" "[INV-REGISTRY]"
assert_no_warn_tag "empty note has no INV-REGISTRY warn" "$out" "[INV-REGISTRY]"
assert_contains "empty note reports pass" "$out" "reasoned empty note"
rm -rf "$T"

echo "== S69 pre-v2.64 boundary is not checked =="
T=$(mktemp -d); make_base "$T"; facet_base "$T"
set_protocol_version "$T" "2.63"
out=$(run "$T"); code=$?
assert_not_contains "pre-v2.64 has no INV-REGISTRY at all" "$out" "[INV-REGISTRY]"
assert_not_contains "pre-v2.64 has no INV-BODY at all" "$out" "[INV-BODY]"
rm -rf "$T"

echo "== S70 v2.64 boundary in zh heading is found =="
T=$(mktemp -d); make_base "$T"; facet_base "$T"
set_protocol_version "$T" "2.64"
{
  printf '\n## 裁决边界\n\n'
  printf '| ID | Kind | Rule | Owner | Established by | State |\n'
  printf '|---|---|---|---|---|---|\n'
  printf '| INV-01 | arch-invariant | 请求必须经过鉴权 | [02-architecture/README.md](02-architecture/README.md) | DEC-0001 | confirmed |\n'
} >> "$T/SSOT/README.md"
printf '\n- **INV-01** 请求必须经过鉴权。\n' >> "$T/SSOT/02-architecture/README.md"
out=$(run "$T"); code=$?
assert_no_fail_tag "zh boundary has no INV-REGISTRY fail" "$out" "[INV-REGISTRY]"
rm -rf "$T"

echo ""
echo "===== summary: PASS=$PASS FAIL=$FAIL ====="
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
