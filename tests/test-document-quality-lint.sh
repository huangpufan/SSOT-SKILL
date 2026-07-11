#!/usr/bin/env bash
# tests/test-document-quality-lint.sh — deterministic guards for covered reader artifacts
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LINT="$PROJECT_ROOT/skills/ssot-doctor/assets/scripts/ssot-lint.sh"
PASS=0
FAIL=0

pass() { echo "  ok   : $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL : $1"; FAIL=$((FAIL + 1)); }
assert_contains() {
  if printf '%s' "$2" | grep -qF -- "$3"; then pass "$1"; else fail "$1 (missing: $3)"; fi
}
assert_not_contains() {
  if printf '%s' "$2" | grep -qF -- "$3"; then fail "$1 (unexpected: $3)"; else pass "$1"; fi
}
assert_exit() {
  if [[ "$2" == "$3" ]]; then pass "$1"; else fail "$1 (exit $2 != $3)"; fi
}
run_quality() { bash "$LINT" --check-document-quality "$1/SSOT" 2>&1; }

make_root() {
  local root="$1"
  mkdir -p "$root/SSOT/01-product/capabilities" "$root/SSOT/01-product/journeys" \
    "$root/SSOT/02-architecture/views" "$root/SSOT/02-architecture/01-runtime" \
    "$root/SSOT/.bootstrap"
  printf '| tracked_skill_version | `2.59` |\n| documentation_language | zh-CN |\n\n| 区域 | 状态 | 备注 |\n|---|---|---|\n| product | covered | |\n| architecture | covered | |\n' > "$root/SSOT/STATUS.md"
  printf '# Reader review\n\nVerdict: no-more-required-changes.\n' > "$root/SSOT/.bootstrap/reader-review.md"
}

echo "=== test-document-quality-lint ==="

echo "== Q1 covered manifest placeholder is a hard failure =="
T=$(mktemp -d); make_root "$T"
printf '## Core recovery manifest\n\n| 核心项 | Owner | Pillars | State | Evidence |\n|---|---|---|---|---|\n| <!-- TODO --> | | | | |\n' > "$T/SSOT/01-product/_manifest.md"
out=$(run_quality "$T"); code=$?
assert_contains "placeholder manifest reports completeness" "$out" "[MANIFEST-COMPLETENESS]"
assert_exit "placeholder manifest exits 2" "$code" "2"
rm -rf "$T"

echo "== Q2 heading-only narrative is a hard failure =="
T=$(mktemp -d); make_root "$T"
printf -- '---\nintent_recovery: covered\n---\n# 产品\n\n## 产品故事\n\n一句口号。\n\n| 能力 | 状态 |\n|---|---|\n| A | current |\n' > "$T/SSOT/01-product/README.md"
out=$(run_quality "$T"); code=$?
assert_contains "heading-only narrative reports sufficiency" "$out" "[NARRATIVE-SUFFICIENCY]"
assert_exit "heading-only narrative exits 2" "$code" "2"
rm -rf "$T"

echo "== Q3 compact table-heavy owner is detected =="
T=$(mktemp -d); make_root "$T"
{
  printf -- '---\nintent_recovery: covered\n---\n# 产品模型\n\n## 产品故事\n\n'
  printf '这两段先说明用户处境、要解决的问题以及当前承诺。\n\n'
  printf '第二段用一个具体场景解释边界和成功结果。\n\n'
  printf '| 项 | 值 |\n|---|---|\n'
  for i in $(seq 1 20); do printf '| row-%s | value |\n' "$i"; done
} > "$T/SSOT/01-product/product-model.md"
out=$(run_quality "$T"); code=$?
assert_contains "compact high-density table reports KISS signal" "$out" "[KISS-TABLE-DENSITY]"
rm -rf "$T"

echo "== Q4 covered domain without first-screen diagram is a hard failure =="
T=$(mktemp -d); make_root "$T"
printf -- '---\nintent_recovery: covered\n---\n# 运行时\n\n## 心智模型\n\n第一段解释边界和职责。\n\n第二段解释一次正常流程。\n\n## 状态\n\n| 状态 | Owner |\n|---|---|\n| task | web |\n' > "$T/SSOT/02-architecture/01-runtime/README.md"
out=$(run_quality "$T"); code=$?
assert_contains "missing first-screen diagram reports DIAGRAM-FIRST" "$out" "[DIAGRAM-FIRST]"
assert_exit "missing first-screen diagram exits 2" "$code" "2"
rm -rf "$T"

echo "== Q5 visible protocol meta is rejected from reader prose =="
T=$(mktemp -d); make_root "$T"
printf -- '---\nintent_recovery: covered\n---\n# 产品\n\n本文按 ssot-bootstrap §3.7 和 Doctor 15H 编写。\n' > "$T/SSOT/01-product/README.md"
out=$(run_quality "$T"); code=$?
assert_contains "protocol meta reports META-LEAKAGE" "$out" "[META-LEAKAGE]"
assert_exit "protocol meta exits 2" "$code" "2"
rm -rf "$T"

echo "== Q6 complete archetype manifests pass the manifest guard =="
T=$(mktemp -d); make_root "$T"
printf '%s\n' \
  '---' 'manifest_archetype: product-root' 'intent_recovery: covered' '---' \
  '' '## Product recovery coverage' '' \
  '| Required product question | Narrative owner | Recovery coverage | Product maturity after verification | Evidence fidelity | Closure |' '|---|---|---|---|---|---|' \
  '| Product brief and surfaces | prd.md | covered | current | browser | accepted |' \
  '| People, objects, and lifecycle | product-model.md | covered | current | integration | accepted |' \
  '| Capabilities | capabilities/README.md | covered | limited | integration | accepted |' \
  '| Journeys | journeys/README.md | covered | limited | browser | accepted |' \
  '| Acceptance and gaps | roadmap-and-acceptance.md | covered | limited | integration | accepted |' \
  '' 'Review: [reader review](../.bootstrap/reader-review.md) — no-more-required-changes (15/16, no zero, no truth error).' > "$T/SSOT/01-product/_manifest.md"
printf '%s\n' \
  '---' 'manifest_archetype: architecture-root' 'intent_recovery: covered' '---' \
  '' '## Architecture recovery coverage' '' \
  '| Required architecture question | Narrative owner | Recovery state | Evidence |' '|---|---|---|---|' \
  '| Current system context | README.md | contract | integration trace |' \
  '| Runtime owner map | README.md | mixed | domain owners |' \
  '| Cross-owner views | views/README.md | mixed | view review |' \
  '| Runtime owner domain | [Runtime](./01-runtime/README.md) | contract | integration trace |' \
  '| Global invariants | README.md | contract | enforcement tests |' \
  '| Current target and gaps | views/current-target-gap.md | mixed | debt owners |' \
  '' 'Review: [reader review](../.bootstrap/reader-review.md) — no-more-required-changes (15/16, no zero, no truth error).' > "$T/SSOT/02-architecture/_manifest.md"
printf '%s\n' \
  '---' 'manifest_archetype: product-collection' 'intent_recovery: covered' '---' \
  '' '| Child owner | User outcome | Recovery coverage | Product maturity | Evidence fidelity | Closure |' '|---|---|---|---|---|---|' \
  '| [Capability](./01-capability.md) | Complete a user job | covered | current | browser | accepted |' \
  '' 'Review: [reader review](../../.bootstrap/reader-review.md) — no-more-required-changes (15/16).' > "$T/SSOT/01-product/capabilities/_manifest.md"
printf '%s\n' \
  '---' 'manifest_archetype: product-collection' 'intent_recovery: covered' '---' \
  '' '| Child owner | User journey | Recovery coverage | Product maturity | Evidence fidelity | Closure |' '|---|---|---|---|---|---|' \
  '| [Journey](./01-journey.md) | Reach a visible result | covered | current | browser | accepted |' \
  '' 'Review: [reader review](../../.bootstrap/reader-review.md) — no-more-required-changes (15/16).' > "$T/SSOT/01-product/journeys/_manifest.md"
printf '%s\n' \
  '---' 'manifest_archetype: architecture-views' 'intent_recovery: covered' '---' \
  '' '| Question class | Narrative owner | Recovery coverage | Evidence |' '|---|---|---|---|' \
  '| Operating pressures | [Operating](./operating-model.md) | mixed | owner review |' \
  '| Critical flow | [Journeys](./critical-journeys.md) | contract | trace |' \
  '| State lifecycle | [State](./state-and-data-lifecycle.md) | contract | schema |' \
  '| Trust boundary | [Trust](./contracts-and-trust-boundaries.md) | contract | auth test |' \
  '| Failure recovery | [Recovery](./failure-and-recovery.md) | contract | regression |' \
  '| Evolution | [Gap](./current-target-gap.md) | mixed | debt owners |' \
  '' 'Review: [reader review](../../.bootstrap/reader-review.md) — no-more-required-changes (15/16).' > "$T/SSOT/02-architecture/views/_manifest.md"
printf '%s\n' \
  '---' 'manifest_archetype: architecture-domain' 'intent_recovery: covered' '---' \
  '' '| Required owner question | Narrative owner | Recovery coverage | Evidence |' '|---|---|---|---|' \
  '| Boundary | README.md | contract | component trace |' \
  '| State and resources | README.md | contract | schema |' \
  '| Contract and trust | README.md | contract | route test |' \
  '| Canonical flow | README.md | contract | integration test |' \
  '| Failure and recovery | README.md | contract | regression test |' \
  '' 'Review: [reader review](../../.bootstrap/reader-review.md) — no-more-required-changes (15/16).' > "$T/SSOT/02-architecture/01-runtime/_manifest.md"
out=$(run_quality "$T"); code=$?
assert_not_contains "all five complete manifest archetypes have no completeness failure" "$out" "[MANIFEST-COMPLETENESS]"
rm -rf "$T"

echo "== Q7 manifest archetypes reject cargo owned by another level =="
T=$(mktemp -d); make_root "$T"
printf '%s\n' \
  '---' 'manifest_archetype: architecture-domain' 'intent_recovery: covered' '---' \
  '' '## Domain recovery coverage' '' \
  '| Required owner question | Narrative owner | Recovery state | Evidence |' '|---|---|---|---|' \
  '| Boundary | README.md | contract | src/myapp/runtime.py::Runtime |' \
  '| State and lifecycle | README.md | contract | schema.sql::runs |' \
  '| Contracts and trust | README.md | contract | web/routes/runs.py::create |' \
  '| Canonical flow | README.md | contract | tests/test_runtime.py::test_flow |' \
  '| Failure and recovery | README.md | contract | tests/test_runtime.py::test_retry |' \
  '' '## Apex owner index' '' \
  '| Rule | Owner |' '|---|---|' '| Web first | root |' \
  '' 'Review: [reader review](../../.bootstrap/reader-review.md) — no-more-required-changes (16/16).' > "$T/SSOT/02-architecture/01-runtime/_manifest.md"
out=$(run_quality "$T"); code=$?
assert_contains "domain manifest rejects apex registry cargo" "$out" "[MANIFEST-COMPLETENESS]"
assert_exit "forbidden manifest cargo exits 2" "$code" "2"
rm -rf "$T"

echo "== Q7b forbidden cargo cannot bypass the archetype in Chinese =="
T=$(mktemp -d); make_root "$T"
printf '%s\n' \
  '---' 'manifest_archetype: product-collection' 'intent_recovery: covered' '---' \
  '' '| 子所有者 | 用户结果 | 恢复覆盖 | 产品成熟度 | 证据保真度 | 闭合 |' '|---|---|---|---|---|---|' \
  '| [能力](./01-capability.md) | 完成任务 | covered | current | browser | accepted |' \
  '' '## 全局不变量' '' '| 规则 | Owner |' '|---|---|' '| 单写者 | root |' \
  '' '评审：[读者复审](../../.bootstrap/reader-review.md) — no-more-required-changes。' > "$T/SSOT/01-product/capabilities/_manifest.md"
out=$(run_quality "$T"); code=$?
assert_contains "Chinese cargo is rejected at the wrong ownership level" "$out" "contains machinery owned by another level"
assert_exit "Chinese forbidden cargo exits 2" "$code" "2"
rm -rf "$T"

echo "== Q7c duplicate manifest frontmatter keys are rejected =="
T=$(mktemp -d); make_root "$T"
printf '%s\n' \
  '---' 'manifest_archetype: architecture-domain' 'manifest_archetype: product-root' \
  'intent_recovery: covered' 'intent_recovery: gap' '---' \
  '' '| Required owner question | Narrative owner | Recovery state | Evidence |' '|---|---|---|---|' \
  '| Boundary | README.md | contract | trace |' \
  '| State and resources | README.md | contract | schema |' \
  '| Contract and trust | README.md | contract | route test |' \
  '| Canonical flow | README.md | contract | integration |' \
  '| Failure and recovery | README.md | contract | regression |' > "$T/SSOT/02-architecture/01-runtime/_manifest.md"
out=$(run_quality "$T"); code=$?
assert_contains "duplicate YAML keys cannot exploit first-value parsing" "$out" "must declare exactly one manifest_archetype and one intent_recovery key"
assert_exit "duplicate manifest keys exit 2" "$code" "2"
rm -rf "$T"

echo "== Q7d unrelated tables cannot satisfy archetype row minimums =="
T=$(mktemp -d); make_root "$T"
{
  printf '%s\n' \
    '---' 'manifest_archetype: architecture-domain' 'intent_recovery: covered' '---' \
    '' '| Required owner question | Narrative owner | Recovery state | Evidence |' '|---|---|---|---|' \
    '| Boundary | README.md | contract | trace |' \
    '' '| Unrelated evidence | Value |' '|---|---|'
  for i in $(seq 1 8); do printf '| Evidence %s | recorded |\n' "$i"; done
  printf '%s\n' '' 'Review: [reader review](../../.bootstrap/reader-review.md) — no-more-required-changes.'
} > "$T/SSOT/02-architecture/01-runtime/_manifest.md"
out=$(run_quality "$T"); code=$?
assert_contains "only the archetype recovery table counts toward completeness" "$out" "too few completed recovery rows"
assert_exit "unrelated table padding exits 2" "$code" "2"
rm -rf "$T"

echo "== Q7e covered review verdict needs a resolvable artifact pointer =="
T=$(mktemp -d); make_root "$T"
printf '%s\n' \
  '---' 'manifest_archetype: architecture-domain' 'intent_recovery: covered' '---' \
  '' '| Required owner question | Narrative owner | Recovery state | Evidence |' '|---|---|---|---|' \
  '| Boundary | README.md | contract | trace |' \
  '| State and resources | README.md | contract | schema |' \
  '| Contract and trust | README.md | contract | route test |' \
  '| Canonical flow | README.md | contract | integration |' \
  '| Failure and recovery | README.md | contract | regression |' \
  '' 'Self-declared review: no-more-required-changes.' > "$T/SSOT/02-architecture/01-runtime/_manifest.md"
out=$(run_quality "$T"); code=$?
assert_contains "plain verdict text is not a review evidence pointer" "$out" "linked to an existing Markdown review artifact"
assert_exit "unlinked review verdict exits 2" "$code" "2"
rm -rf "$T"

echo "== Q8 covered manifest cannot preserve bootstrap gap states =="
T=$(mktemp -d); make_root "$T"
printf '%s\n' \
  '---' 'manifest_archetype: product-root' 'intent_recovery: covered' '---' \
  '' '| Item | Owner | State | Evidence |' '|---|---|---|---|' \
  '| Product brief | prd.md | current | browser |' \
  '| Product model | product-model.md | current | integration |' \
  '| Capabilities | capabilities/README.md | gap | missing |' \
  '| Journeys | journeys/README.md | current | browser |' \
  '| Acceptance | roadmap-and-acceptance.md | current | integration |' \
  '' 'Independent review: no-more-required-changes (14/16).' > "$T/SSOT/01-product/_manifest.md"
out=$(run_quality "$T"); code=$?
assert_contains "covered manifest rejects gap/missing cells" "$out" "[MANIFEST-COMPLETENESS]"
assert_exit "covered incomplete manifest exits 2" "$code" "2"
rm -rf "$T"

echo "== Q9 product collection requires maturity and evidence semantics =="
T=$(mktemp -d); make_root "$T"
printf '%s\n' \
  '---' 'manifest_archetype: product-collection' 'intent_recovery: covered' '---' \
  '' '| Child owner | Outcome | Product maturity | Closure |' '|---|---|---|---|' \
  '| [Capability](./01-capability.md) | Complete a job | current | accepted |' \
  '' 'Independent review: no-more-required-changes (15/16).' > "$T/SSOT/01-product/capabilities/_manifest.md"
out=$(run_quality "$T"); code=$?
assert_contains "product collection rejects missing evidence-fidelity contract" "$out" "product-collection manifest must index"
assert_exit "incomplete product collection exits 2" "$code" "2"
rm -rf "$T"

echo "== Q10 architecture root requires runtime/view/invariant recovery classes =="
T=$(mktemp -d); make_root "$T"
printf '%s\n' \
  '---' 'manifest_archetype: architecture-root' 'intent_recovery: covered' '---' \
  '' '| Item | Owner | State | Evidence |' '|---|---|---|---|' \
  '| Context | README.md | contract | trace |' \
  '| Views | views/README.md | contract | review |' \
  '| Evolution | views/current-target-gap.md | mixed | debt |' \
  '| Detail A | README.md | contract | test |' \
  '| Detail B | README.md | contract | test |' \
  '' 'Independent review: no-more-required-changes (15/16).' > "$T/SSOT/02-architecture/_manifest.md"
out=$(run_quality "$T"); code=$?
assert_contains "architecture root rejects missing runtime-owner/invariant classes" "$out" "architecture-root manifest misses required recovery class"
assert_exit "incomplete architecture root exits 2" "$code" "2"
rm -rf "$T"

echo "== Q11 architecture views require all six default questions =="
T=$(mktemp -d); make_root "$T"
printf '%s\n' \
  '---' 'manifest_archetype: architecture-views' 'intent_recovery: covered' '---' \
  '' '| Question | Owner | State | Evidence |' '|---|---|---|---|' \
  '| Operating | operating-model.md | mixed | review |' \
  '| Journey | critical-journeys.md | contract | trace |' \
  '| State | state-and-data-lifecycle.md | contract | schema |' \
  '| Trust | contracts-and-trust-boundaries.md | contract | auth |' \
  '| Evolution | current-target-gap.md | mixed | debt |' \
  '| Extra | README.md | contract | review |' \
  '' 'Independent review: no-more-required-changes (15/16).' > "$T/SSOT/02-architecture/views/_manifest.md"
out=$(run_quality "$T"); code=$?
assert_contains "architecture views reject missing failure/recovery question" "$out" "failure-and-recovery"
assert_exit "incomplete architecture views exits 2" "$code" "2"
rm -rf "$T"

echo "== Q12 covered area cannot hide a gap body from narrative checks =="
T=$(mktemp -d); make_root "$T"
printf -- '---\nintent_recovery: gap\n---\n# Product\n\nThe body has not been written.\n' > "$T/SSOT/01-product/README.md"
out=$(run_quality "$T"); code=$?
assert_contains "covered area rejects gap reader body" "$out" "covered area has a reader file whose intent_recovery is gap"
assert_exit "covered area gap body exits 2" "$code" "2"
rm -rf "$T"

echo "== Q13 focused flag parses default and explicit paths in either order =="
T=$(mktemp -d); make_root "$T"
out=$(cd "$T" && bash "$LINT" --check-document-quality 2>&1); default_code=$?
out_before=$(bash "$LINT" --check-document-quality "$T/SSOT" 2>&1); before_code=$?
out_after=$(bash "$LINT" "$T/SSOT" --check-document-quality 2>&1); after_code=$?
assert_not_contains "flag-only mode defaults to ./SSOT" "$out" "ERROR: SSOT directory not found: --check-document-quality"
assert_not_contains "flag-before-path does not treat the flag as a directory" "$out_before" "ERROR: SSOT directory not found: --check-document-quality"
assert_not_contains "path-before-flag does not treat the flag as a directory" "$out_after" "ERROR: SSOT directory not found: --check-document-quality"
assert_exit "flag-only default reaches quality checks" "$default_code" "2"
assert_exit "flag-before-path reaches quality checks" "$before_code" "2"
assert_exit "path-before-flag reaches quality checks" "$after_code" "2"
mutual_out=$(bash "$LINT" --check-meta-leakage --check-document-quality "$T/SSOT" 2>&1); mutual_code=$?
assert_contains "focused modes are mutually exclusive" "$mutual_out" "mutually exclusive"
assert_exit "mutually exclusive focused modes exit 3" "$mutual_code" "3"
rm -rf "$T"

echo "== Q14 v2.59 authoring-meta tokens are waterline gated =="
T=$(mktemp -d); make_root "$T"
printf '| tracked_skill_version | `2.58` |\n| documentation_language | zh-CN |\n\n| 区域 | 状态 | 备注 |\n|---|---|---|\n| product | gap | |\n| architecture | gap | |\n' > "$T/SSOT/STATUS.md"
printf -- '---\nintent_recovery: gap\n---\n# 产品\n\n本文暂时引用 ssot-bootstrap 与 Doctor 15V 的旧模板说明。\n' > "$T/SSOT/01-product/README.md"
legacy_out=$(bash "$LINT" "$T/SSOT" 2>&1)
assert_not_contains "v2.58 normal lint does not retroactively apply v2.59 meta tokens" "$legacy_out" "- [META-LEAKAGE] "
printf '| tracked_skill_version | `2.59` |\n| documentation_language | zh-CN |\n\n| 区域 | 状态 | 备注 |\n|---|---|---|\n| product | gap | |\n| architecture | gap | |\n' > "$T/SSOT/STATUS.md"
current_out=$(bash "$LINT" "$T/SSOT" 2>&1); current_code=$?
assert_contains "v2.59 normal lint rejects visible authoring meta" "$current_out" "[META-LEAKAGE]"
assert_exit "v2.59 visible authoring meta exits 2" "$current_code" "2"
rm -rf "$T"

echo "== Q15 a sequence diagram cannot satisfy the covered domain boundary gate =="
T=$(mktemp -d); make_root "$T"
printf '%s\n' \
  '---' 'intent_recovery: covered' '---' \
  '# Runtime domain' '' \
  'This domain owns one runtime boundary and explains its callers and result.' '' \
  'The next paragraph explains state ownership and representative recovery.' '' \
  '```mermaid' '<!-- diagram_type: sequence -->' 'sequenceDiagram' '  User->>Web: request' '```' \
  '' '| State | Owner |' '|---|---|' '| run | web |' > "$T/SSOT/02-architecture/01-runtime/README.md"
out=$(run_quality "$T"); code=$?
assert_contains "sequence-only first screen fails the component boundary requirement" "$out" "tagged '<!-- diagram_type: component -->'"
assert_exit "sequence-only covered domain exits 2" "$code" "2"
rm -rf "$T"

echo "== Q16 diagram_type state machine reports missing and invalid tags =="
T=$(mktemp -d); make_root "$T"
printf '| tracked_skill_version | `2.58` |\n| documentation_language | zh-CN |\n\n| 区域 | 状态 | 备注 |\n|---|---|---|\n| product | gap | |\n| architecture | gap | |\n' > "$T/SSOT/STATUS.md"
printf '%s\n' \
  '---' 'intent_recovery: gap' '---' '# Runtime' '' \
  '```mermaid' 'flowchart LR' '  A --> B' '```' '' \
  '```mermaid' '<!-- diagram_type: database -->' 'flowchart LR' '  DB --> API' '```' '' \
  '```mermaid' '<!-- diagram_type: component -->' 'sequenceDiagram' '  A->>B: mixed' '```' > "$T/SSOT/02-architecture/01-runtime/README.md"
normal_out=$(bash "$LINT" "$T/SSOT" 2>&1)
tag_hits=$(printf '%s\n' "$normal_out" | grep -c '\[DIAGRAM-TYPE-TAG\].*fence opened' || true)
assert_contains "normal lint reports a missing or invalid diagram type tag" "$normal_out" "[DIAGRAM-TYPE-TAG]"
assert_exit "state machine reports missing, invalid, and mixed diagram contracts" "$tag_hits" "3"
rm -rf "$T"

echo "== Q17 multi-directory meta scan inherits the common v2.59 waterline =="
T=$(mktemp -d); make_root "$T"
printf '# Product\n\nVisible ssot-bootstrap authoring machinery.\n' > "$T/SSOT/01-product/README.md"
printf '# Architecture\n\nVisible ssot-bootstrap authoring machinery.\n' > "$T/SSOT/02-architecture/README.md"
multi_before=$(bash "$LINT" --check-meta-leakage "$T/SSOT/01-product" "$T/SSOT/02-architecture" 2>&1); multi_before_code=$?
multi_after=$(bash "$LINT" "$T/SSOT/01-product" "$T/SSOT/02-architecture" --check-meta-leakage 2>&1); multi_after_code=$?
assert_contains "flag-first multi-directory scan applies v2.59 tokens" "$multi_before" "[META-LEAKAGE]"
assert_contains "flag-last multi-directory scan applies v2.59 tokens" "$multi_after" "[META-LEAKAGE]"
assert_exit "flag-first multi-directory scan exits 2" "$multi_before_code" "2"
assert_exit "flag-last multi-directory scan exits 2" "$multi_after_code" "2"
rm -rf "$T"

echo
echo "=== RESULT: pass=$PASS fail=$FAIL ==="
[[ "$FAIL" -eq 0 ]]
