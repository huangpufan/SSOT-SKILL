#!/usr/bin/env bash
# tests/test-document-quality-lint.sh — deterministic guards for covered reader artifacts
set -uo pipefail

# Canonicalize the trusted temporary root; fixture links remain subject to lint.
TMPDIR=$(cd "${TMPDIR:-/tmp}" && pwd -P) || exit 1
export TMPDIR

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LINT="$PROJECT_ROOT/skills/ssot-doctor/assets/scripts/ssot-lint.sh"
PASS=0
FAIL=0

pass() { echo "  ok   : $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL : $1"; FAIL=$((FAIL + 1)); }
show_lint_failure_context() {
  printf '%s\n' "$1" | awk -v wanted="$2" '
    /^\[FAIL\]/ { failed = 1 }
    failed || index($0, wanted) || /^(ERROR|sed|awk|find):/ {
      if (shown < 24) { print "    lint context: " substr($0, 1, 600); shown++ }
    }
  '
}
assert_contains() {
  if printf '%s' "$2" | grep -qF -- "$3"; then
    pass "$1"
  else
    fail "$1 (missing: $3)"
    show_lint_failure_context "$2" "$3"
  fi
}
assert_not_contains() {
  if printf '%s' "$2" | grep -qF -- "$3"; then
    fail "$1 (unexpected: $3)"
    show_lint_failure_context "$2" "$3"
  else
    pass "$1"
  fi
}
assert_exit() {
  if [[ "$2" == "$3" ]]; then pass "$1"; else fail "$1 (exit $2 != $3)"; fi
}
# Lint failures render as "  - [TAG] msg" inside the "[FAIL] N" section, so a
# plain not_contains on "[FAIL] [TAG]" is vacuous. These scope the assertion
# to actual failure/warning lines. $3 is the bracketed tag, matched literally.
_in_section_tag() { # $1=section name (FAIL|WARN) $2=output $3=bracketed tag
  printf '%s' "$2" | awk -v tag="$3" -v section="$1" '
    /^\[[A-Z-]+\]/ { inside = (index($0, "[" section "]") == 1); next }
    inside && index($0, tag) { found=1 }
    END { exit(found ? 0 : 1) }
  '
}
assert_no_fail_tag() { # $1=label $2=output $3=bracketed tag
  if _in_section_tag 'FAIL' "$2" "$3"; then
    fail "$1 (unexpected fail tag: $3)"; show_lint_failure_context "$2" "$3"
  else pass "$1"; fi
}
assert_has_fail_tag() {
  if _in_section_tag 'FAIL' "$2" "$3"; then pass "$1"
  else fail "$1 (missing fail tag: $3)"; show_lint_failure_context "$2" "$3"; fi
}
assert_no_warn_tag() {
  if _in_section_tag 'WARN' "$2" "$3"; then
    fail "$1 (unexpected warn tag: $3)"; show_lint_failure_context "$2" "$3"
  else pass "$1"; fi
}
assert_has_warn_tag() {
  if _in_section_tag 'WARN' "$2" "$3"; then pass "$1"
  else fail "$1 (missing warn tag: $3)"; show_lint_failure_context "$2" "$3"; fi
}
# Edit fixture content with the same GNU/BSD sed script; failed edits leave it intact.
sed_inplace() { # $1=script remaining args=files
  local script="$1" file temporary code=0
  shift
  for file in "$@"; do
    temporary=$(mktemp) || return $?
    if sed "$script" "$file" > "$temporary"; then
      cat "$temporary" > "$file" || code=$?
    else
      code=$?
    fi
    rm -f "$temporary"
    [[ "$code" -eq 0 ]] || return "$code"
  done
}

run_quality() { bash "$LINT" --check-document-quality "$1/SSOT" 2>&1; }
run_normal() { bash "$LINT" "$1/SSOT" 2>&1; }

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

reader_surface_fingerprint() {
  local ssot_dir="$1" file relative digest
  while IFS= read -r file; do
    relative="${file#"$ssot_dir"/}"
    digest=$(sha256_file "$file")
    printf '%s\0%s\n' "$relative" "$digest"
  done < <(
    {
      [[ -f "$ssot_dir/README.md" ]] && printf '%s\n' "$ssot_dir/README.md"
      find "$ssot_dir/01-product" "$ssot_dir/02-architecture" -type f -name '*.md' -print 2>/dev/null || true
    } | LC_ALL=C sort -u
  ) | {
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum | awk '{print $1}'
    else
      shasum -a 256 | awk '{print $1}'
    fi
  }
}

scope_fingerprint() { # $1=SSOT dir $2=process|records|glossary|root|status
  local ssot_dir="$1" scope="$2" base file relative digest
  case "$scope" in
    process) base="$ssot_dir/03-process" ;;
    records) base="$ssot_dir/04-records" ;;
    glossary) base="$ssot_dir/glossary" ;;
    root) base="$ssot_dir/README.md" ;;
    status) base="$ssot_dir/STATUS.md" ;;
  esac
  {
    if [[ -f "$base" ]]; then
      relative="${base#"$ssot_dir"/}"; digest=$(sha256_file "$base"); printf '%s\0%s\n' "$relative" "$digest"
    else
      while IFS= read -r file; do
        relative="${file#"$ssot_dir"/}"; digest=$(sha256_file "$file"); printf '%s\0%s\n' "$relative" "$digest"
      done < <(find "$base" -type f -name '*.md' -print | LC_ALL=C sort)
    fi
  } | {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum | awk '{print $1}'; else shasum -a 256 | awk '{print $1}'; fi
  }
}

quality_disposition_fingerprint() {
  local status_file="$1" sep rows ids expected
  sep=$(printf '\034')
  rows=$(awk '
    BEGIN { sep=sprintf("%c", 28) }
    function normalize(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/[[:space:]]+/, " ", v); return v }
    function normalize_id(v) { v=normalize(v); gsub(/^`|`$/, "", v); return v }
    function set_header(    i,v,lower) {
      q_i=app_i=product_i=architecture_i=process_i=gap_i=0
      for (i=2; i<cell_count; i++) {
        v=normalize(cells[i]); lower=tolower(v)
        if (lower == "q id") q_i=i
        else if (lower == "applicability" || v == "适用性") app_i=i
        else if (lower == "product owner" || v == "产品事实所有者") product_i=i
        else if (lower == "architecture owner" || v == "架构事实所有者") architecture_i=i
        else if (lower == "process/evidence owner" || v == "流程/证据所有者") process_i=i
        else if (lower == "gap owner" || v == "缺口所有者") gap_i=i
      }
      return q_i && app_i && product_i && architecture_i && process_i && gap_i
    }
    /^##[[:space:]]+/ {
      title=$0; sub(/^##[[:space:]]+/, "", title); lower=tolower(normalize(title))
      in_q=(lower == "quality, risk, and governance" || normalize(title) == "质量、风险与治理")
      have_header=0; next
    }
    in_q && /^\|/ {
      if ($0 ~ /^\|[[:space:]:|-]+(\|[[:space:]:|-]+)+\|?[[:space:]]*$/) next
      cell_count=split($0, cells, "|")
      if (!have_header) { if (set_header()) have_header=1; next }
      print normalize_id(cells[q_i]) sep normalize(cells[app_i]) sep normalize(cells[product_i]) sep normalize(cells[architecture_i]) sep normalize(cells[process_i]) sep normalize(cells[gap_i])
    }
  ' "$status_file" | LC_ALL=C sort -t "$sep" -k1,1)
  ids=$(printf '%s\n' "$rows" | awk -F "$sep" '{ print $1 }')
  expected=$(for i in {1..21}; do printf 'Q%02d\n' "$i"; done)
  [[ "$ids" == "$expected" ]] || return 1
  printf '%s\n' "$rows" | while IFS="$sep" read -r id applicability product architecture process gap; do
    printf '%s\0%s\0%s\0%s\0%s\0%s\n' "$id" "$applicability" "$product" "$architecture" "$process" "$gap"
  done | {
    if command -v sha256sum >/dev/null 2>&1; then
      sha256sum | awk '{print $1}'
    else
      shasum -a 256 | awk '{print $1}'
    fi
  }
}

area_disposition_fingerprint() { # $1=STATUS file $2=profile
  local status_file="$1" profile="$2" area sep row status notes
  sep=$(printf '\034')
  case "$profile" in
    process) set -- process development testing benchmark deployment release operations security-and-compliance ;;
    records) set -- records decisions 'research records' gotchas bugs tech-debt ;;
    glossary) set -- glossary ;;
    root|status) set -- product architecture process development testing benchmark deployment release operations security-and-compliance records decisions 'research records' gotchas bugs tech-debt glossary ;;
  esac
  for area in "$@"; do
    row=$(awk -F'|' -v wanted="$area" '
      function trim(v){gsub(/^[[:space:]`]+|[[:space:]`]+$/,"",v);return v}
      /^##[[:space:]]+(Area Status|区域状态)$/{active=1;next}active&&/^##[[:space:]]/{exit}
      active&&/^\|/{if($0~/^\|[[:space:]:|-]+(\|[[:space:]:|-]+)+\|?[[:space:]]*$/)next;n=split($0,c,"|");if(!h){for(i=2;i<n;i++){v=trim(c[i]);l=tolower(v);if(l=="area"||v=="区域")a=i;else if(l=="status"||v=="状态")s=i;else if(l=="notes"||v=="备注")o=i}h=1;next}if(trim(c[a])==wanted)print trim(c[s]) sprintf("%c",28) trim(c[o])}' "$status_file")
    IFS="$sep" read -r status notes <<< "$row"
    notes=$(printf '%s' "$notes" | awk '{$1=$1;print}')
    printf '%s\0%s\0%s\n' "$area" "$status" "$notes"
  done | {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum | awk '{print $1}'; else shasum -a 256 | awk '{print $1}'; fi
  }
}

fixture_commit() {
  local root="$1"
  if [[ ! -d "$root/.git" ]]; then
    git -C "$root" init -q
    git -C "$root" config user.name 'SSOT fixture'
    git -C "$root" config user.email 'ssot-fixture@example.invalid'
  fi
  git -C "$root" add SSOT
  git -C "$root" commit -q --allow-empty -m 'test: freeze review scope'
  git -C "$root" rev-parse HEAD
}

make_root() {
  local root="$1"
  mkdir -p "$root/SSOT/01-product/capabilities" "$root/SSOT/01-product/journeys" \
    "$root/SSOT/02-architecture/views" "$root/SSOT/02-architecture/01-runtime" \
    "$root/SSOT/.bootstrap"
  printf '| tracked_skill_version | `2.59` |\n| documentation_language | zh-CN |\n\n| 区域 | 状态 | 备注 |\n|---|---|---|\n| product | covered | |\n| architecture | covered | |\n' > "$root/SSOT/STATUS.md"
  printf '# Reader review\n\nVerdict: no-more-required-changes.\n' > "$root/SSOT/.bootstrap/reader-review.md"
  # The root reader router is the declared entrypoint and the Truth-consistency
  # root owner for every v2.60 structured review, so covered-area fixtures must
  # create it with at least two explanatory prose paragraphs.
  printf '%s\n' '# SSOT' '' \
    'This repository durable memory routes the implementation delegator from the product need to the runtime owner that answers for it, without copying either owner truth into this routing page.' '' \
    'Start at the product owner for what the system does and the architecture owner for how it responds, then check STATUS before changing the repo. Each durable fact lives in one owner, and this page only routes to those owners instead of repeating their current truth.' \
    > "$root/SSOT/README.md"
}

make_v260_product_root() {
  local root="$1"
  make_root "$root"
  printf '| tracked_skill_version | `2.60` |\n| documentation_language | zh-CN |\n\n| 区域 | 状态 | 备注 |\n|---|---|---|\n| product | covered | |\n| architecture | gap | |\n' > "$root/SSOT/STATUS.md"
}

append_quality_register() {
  local root="$1" i
  printf '# Quality owner\n\nThis fixture owns the applicable quality disposition.\n' > "$root/SSOT/quality-owner.md"
  {
    printf '\n## Quality, Risk, and Governance\n\n'
    printf '| Q ID | Applicability | Product owner | Architecture owner | Process/evidence owner | Gap owner |\n'
    printf '|---|---|---|---|---|---|\n'
    for i in {1..21}; do
      printf '| Q%02d | applicable | [Quality owner](./quality-owner.md) | [Quality owner](./quality-owner.md) | [Quality owner](./quality-owner.md) | none: covered by the linked owner evidence |\n' "$i"
    done
  } >> "$root/SSOT/STATUS.md"
}

write_exact_area_status() {
  local root="$1"
  mkdir -p "$root/SSOT"
  printf '%s\n' \
    '# Status' '' '## Event-Source Coverage' '' \
    '| Field | Value |' '|---|---|' \
    '| tracked_commit | fixture-sha |' \
    '| tracked_session | fixture-session |' \
    '| tracked_skill_version | `2.60` |' \
    '| documentation_language | en |' \
    '| documentation_language_evidence | fixture decision |' \
    '| coverage_result | in_progress |' \
    '| last_stop_review | `$ssot-bootstrap` |' '' \
    '## Area Status' '' \
    '| Area | Status | Notes |' '|---|---|---|' \
    '| product | gap | `$ssot-bootstrap` |' \
    '| architecture | gap | `$ssot-bootstrap` |' \
    '| process | gap | `$ssot-bootstrap` |' \
    '| development | gap | `$ssot-bootstrap` |' \
    '| testing | gap | `$ssot-bootstrap` |' \
    '| benchmark | gap | `$ssot-bootstrap` |' \
    '| deployment | gap | `$ssot-bootstrap` |' \
    '| release | gap | `$ssot-bootstrap` |' \
    '| operations | gap | `$ssot-bootstrap` |' \
    '| security-and-compliance | gap | `$ssot-bootstrap` |' \
    '| records | gap | `$ssot-bootstrap` |' \
    '| decisions | gap | `$ssot-bootstrap` |' \
    '| research records | gap | `$ssot-bootstrap` |' \
    '| gotchas | gap | `$ssot-bootstrap` |' \
    '| bugs | gap | `$ssot-bootstrap` |' \
    '| tech-debt | gap | `$ssot-bootstrap` |' \
    '| glossary | gap | `$ssot-bootstrap` |' \
    > "$root/SSOT/STATUS.md"
  append_quality_register "$root"
  printf '%s\n' \
    '' '## Source Material Absorption' '' \
    '| Source ID | Source material | Path/source | Lifecycle | Classification | Authority | Durable owner / absorbed_to | Do not use for | Review |' \
    '|---|---|---|---|---|---|---|---|---|' '| | | | | | | | | |' \
    '' '## Source Inventory Exclusions' '' \
    '| Pattern | Reason | Decision owner | Last checked | Review trigger |' '|---|---|---|---|---|' '| | | | | |' \
    '' '## Core Reference Document Review' '' \
    '| Document | Role | Relation | Status | Reviewed baseline | Durable owner / scope | Gap / conflict route |' '|---|---|---|---|---|---|---|' '| | | | | | | |' \
    '' '## Stop Review Gate' '' \
    '| Scope | Stop claim | Reviewer | Reviewer role | Reviewed at | Result | Evidence | Remaining changes | Authorises |' '|---|---|---|---|---|---|---|---|---|' '| | | | | | | | | |' \
    '' '## Open Adjudications' '' \
    '| ID | State | Affected scope / task | Question / missing evidence | Responsible owner | Blocking / retrigger condition | Resolving route | Closure / supersession evidence |' '|---|---|---|---|---|---|---|---|' '| | | | | | | | |' \
    '' '## Pending Captures' '' \
    '| ID | Source | Proposed owner | Reason | Priority / trigger | Responsible owner | State | Closure evidence |' '|---|---|---|---|---|---|---|---|' '| | | | | | | | |' \
    '' '## Open Gaps' '' \
    '| ID | State | Affected scope / task | Question / missing evidence | Responsible owner | Blocking / retrigger condition | Resolving route | Closure / supersession evidence |' '|---|---|---|---|---|---|---|---|' '| | | | | | | | |' \
    >> "$root/SSOT/STATUS.md"
}

write_process_scope_fixture() {
  local root="$1" ssot="$1/SSOT" artifact="$1/SSOT/.bootstrap/scope-review-process.md"
  local commit scope_hash area_hash q_hash id all_ids
  write_exact_area_status "$root"
  mkdir -p "$ssot/03-process" "$ssot/.bootstrap"
  printf '%s\n' '# Repository route' '' 'This route sends a delegated change to its current process owner, evidence, failure boundary, and next safe action.' > "$ssot/README.md"
  printf '%s\n' '# Process owner' '' 'This owner explains who uses the process, why the method fits, the ordered path, visible acceptance result, failure recovery, evidence, and review trigger.' > "$ssot/03-process/README.md"
  sed_inplace 's#^| process | gap |.*#| process | covered | [process owner](./03-process/README.md); [scope review](./.bootstrap/scope-review-process.md) |#' "$ssot/STATUS.md"
  sed_inplace '/^## Stop Review Gate$/,/^## Open Adjudications$/ { /^| | | | | | | | | |$/a\
| process | covered | agent:test | scoped-self-review | 2026-07-13 | no-more-required-changes | [scope review](./.bootstrap/scope-review-process.md) | none | area:process:covered |
  }' "$ssot/STATUS.md"
  commit=$(fixture_commit "$root")
  scope_hash=$(scope_fingerprint "$ssot" process)
  area_hash=$(area_disposition_fingerprint "$ssot/STATUS.md" process)
  q_hash=$(quality_disposition_fingerprint "$ssot/STATUS.md")
  all_ids=$( { for id in C01 C02 C03 C04 C05 C06 C07 C08 C09; do printf '%s,' "$id"; done; for id in PR01 PR02 PR03 PR04 PR05 PR06 PR07 PR08 PR09 PR10 PR11 PR12 PR13 PR14 PR15 PR16; do printf '%s,' "$id"; done; for id in Q01 Q02 Q03 Q04 Q05 Q06 Q07 Q08 Q09 Q10 Q11 Q12 Q13 Q14 Q15 Q16 Q17 Q18 Q19 Q20 Q21; do printf '%s,' "$id"; done; } | sed 's/,$//' )
  {
    printf '%s\n' '---' \
      'review_id: scope-review:process:20260713:fixture' \
      'review_scope: process' 'completeness_profile: process' 'protocol_version: "2.60"' \
      'reviewed_on: 2026-07-13' 'reviewer: agent:test' 'reviewer_role: scoped-self-review' \
      "repository_commit: $commit" 'entrypoint: SSOT/03-process/README.md' \
      "scope_fingerprint: $scope_hash" "area_disposition_fingerprint: $area_hash" "quality_disposition_fingerprint: $q_hash" \
      'profile_item_count: 46' 'covered_item_count: 46' 'not_applicable_item_count: 0' \
      'unresolved_required_changes: 0' 'authorises: area:process:covered' \
      'verdict: no-more-required-changes' '---' '' '# Exact process review' '' \
      '## Review basis' '' \
      '| Check | Result | Evidence / limit |' '|---|---|---|' \
      '| Scope identity and current fingerprint | pass | Current process Markdown fingerprint was recomputed after the owner body was frozen. |' \
      '| Owner and route resolution | pass | Every sampled link resolves to the current process narrative owner. |' \
      '| STATUS claim and artifact agreement | pass | Area and stop rows name this review and the same covered authorisation. |' '' \
      '| Item ID | Owner/body claim | Repository/evidence sample | Truth result | Limit |' '|---|---|---|---|---|' \
      '| C01 | The process owner identifies its reader and decision. | [process owner](../03-process/README.md) | pass | One owner sample does not prove every child workflow. |' \
      '| PR01 | The process owner states who uses the stable workflow. | [process owner](../03-process/README.md) | pass | This sample does not execute an external system. |' \
      '| Q01 | The process owner exposes the applicable evidence route. | [process owner](../03-process/README.md) | pass | This sample checks documentation truth, not runtime accessibility. |' '' \
      '| Target ID | Target owner | Profile IDs exercised | Repository/evidence sample | Truth result | Limit |' '|---|---|---|---|---|---|' \
      "| process-root | Process narrative owner | $all_ids | [process owner](../03-process/README.md) | pass | The body sample does not execute external side effects. |" '' \
      '## Exact profile' '' '| Item ID | Disposition | Plain answer | Owner / evidence |' '|---|---|---|---|'
    for id in C01 C02 C03 C04 C05 C06 C07 C08 C09; do printf '| %s | covered | The current process owner gives a concrete reader decision and safe handoff for this workflow. | [process owner](../03-process/README.md) |\n' "$id"; done
    for id in PR01 PR02 PR03 PR04 PR05 PR06 PR07 PR08 PR09 PR10 PR11 PR12 PR13 PR14 PR15 PR16; do printf '| %s | covered | The current workflow explains its ordered action, visible result, boundary, and recovery owner in plain language. | [process owner](../03-process/README.md) |\n' "$id"; done
    for id in Q01 Q02 Q03 Q04 Q05 Q06 Q07 Q08 Q09 Q10 Q11 Q12 Q13 Q14 Q15 Q16 Q17 Q18 Q19 Q20 Q21; do printf '| %s | covered | The applicable quality concern has a current owner, evidence route, and explicit operating limit. | [process owner](../03-process/README.md) |\n' "$id"; done
    printf '%s\n' '' '## Required changes and verdict' '' \
      '| Change ID | Status | Required change | Owner | Closure evidence |' '|---|---|---|---|---|' \
      '| none | none | No required change remains after this review. | — | The unresolved count is zero and the final verdict is no-more-required-changes. |' '' \
      'Final verdict: `no-more-required-changes`.'
  } > "$artifact"
}

write_glossary_scope_fixture() {
  local root="$1" ssot="$1/SSOT" artifact="$1/SSOT/.bootstrap/scope-review-glossary.md"
  local commit scope_hash area_hash q_hash id all_ids
  write_exact_area_status "$root"
  mkdir -p "$ssot/glossary" "$ssot/.bootstrap"
  printf '%s\n' '# Repository route' '' 'This route sends repository vocabulary questions to the glossary owner and its current evidence boundary.' > "$ssot/README.md"
  printf '%s\n' '# Ready' '' '**One-sentence definition**: Ready is the repository state in which the named result can be accepted.' '' '## Why it matters' '' 'It changes whether a delegated result may advance.' > "$ssot/glossary/ready.md"
  printf '%s\n' '# Repository vocabulary' '' \
    'This owner explains repository-specific terms, their decision consequence, evidence, nearby confusion, and invalidation trigger.' '' \
    '## Vocabulary-family coverage' '' \
    '| Vocabulary family | Discovery trigger | Disposition | Term-entry owner links or reason |' '|---|---|---|---|' \
    '| Product and user concepts | The repository uses ready as an acceptance state. | applicable | [ready](./ready.md) |' \
    '| Architecture and runtime concepts | No repository-specific term exists. | not_applicable | reason=no term; checked=[root](../README.md); review when=a term appears |' \
    '| State, lifecycle, and workflow terms | No additional term exists. | not_applicable | reason=no term; checked=[root](../README.md); review when=a term appears |' \
    '| Trust, identity, access, and data-governance terms | No repository-specific term exists. | not_applicable | reason=no term; checked=[root](../README.md); review when=a term appears |' \
    '| Evidence, verification, and operating terms | No repository-specific term exists. | not_applicable | reason=no term; checked=[root](../README.md); review when=a term appears |' \
    '| Concurrency-control terms | No repository-specific term exists. | not_applicable | reason=no term; checked=[root](../README.md); review when=a term appears |' \
    > "$ssot/glossary/README.md"
  sed_inplace 's#^| glossary | gap |.*#| glossary | covered | [glossary owner](./glossary/README.md); [scope review](./.bootstrap/scope-review-glossary.md) |#' "$ssot/STATUS.md"
  sed_inplace '/^## Stop Review Gate$/,/^## Open Adjudications$/ { /^| | | | | | | | | |$/a\
| glossary | covered | agent:test | scoped-self-review | 2026-07-13 | no-more-required-changes | [scope review](./.bootstrap/scope-review-glossary.md) | none | area:glossary:covered |
  }' "$ssot/STATUS.md"
  commit=$(fixture_commit "$root")
  scope_hash=$(scope_fingerprint "$ssot" glossary)
  area_hash=$(area_disposition_fingerprint "$ssot/STATUS.md" glossary)
  q_hash=$(quality_disposition_fingerprint "$ssot/STATUS.md")
  all_ids=$( { for id in C01 C02 C03 C04 C05 C06 C07 C08 C09; do printf '%s,' "$id"; done; for id in G01 G02 G03 G04 G05 G06 G07 G08; do printf '%s,' "$id"; done; for id in Q01 Q02 Q03 Q04 Q05 Q06 Q07 Q08 Q09 Q10 Q11 Q12 Q13 Q14 Q15 Q16 Q17 Q18 Q19 Q20 Q21; do printf '%s,' "$id"; done; } | sed 's/,$//' )
  {
    printf '%s\n' '---' \
      'review_id: scope-review:glossary:20260713:fixture' \
      'review_scope: glossary' 'completeness_profile: glossary' 'protocol_version: "2.60"' \
      'reviewed_on: 2026-07-13' 'reviewer: agent:test' 'reviewer_role: scoped-self-review' \
      "repository_commit: $commit" 'entrypoint: SSOT/glossary/README.md' \
      "scope_fingerprint: $scope_hash" "area_disposition_fingerprint: $area_hash" "quality_disposition_fingerprint: $q_hash" \
      'profile_item_count: 38' 'covered_item_count: 38' 'not_applicable_item_count: 0' \
      'unresolved_required_changes: 0' 'authorises: area:glossary:covered' \
      'verdict: no-more-required-changes' '---' '' '# Exact glossary review' '' \
      '## Review basis' '' \
      '| Check | Result | Evidence / limit |' '|---|---|---|' \
      '| Scope identity and current fingerprint | pass | Current glossary Markdown fingerprint was recomputed after both owners were frozen. |' \
      '| Owner and route resolution | pass | Every sample resolves to the current glossary target. |' \
      '| STATUS claim and artifact agreement | pass | Area and stop rows name this review and the same authorisation. |' '' \
      '| Item ID | Owner/body claim | Repository/evidence sample | Truth result | Limit |' '|---|---|---|---|---|' \
      '| C01 | The glossary owner identifies the reader decision. | [glossary owner](../glossary/README.md) | pass | This sample does not prove the term body. |' \
      '| G01 | The ready owner gives a positive definition. | [ready term](../glossary/ready.md) | pass | This sample does not prove every family. |' \
      '| Q01 | The glossary owner exposes the applicable evidence route. | [glossary owner](../glossary/README.md) | pass | This sample checks documentation truth only. |' '' \
      '| Target ID | Target owner | Profile IDs exercised | Repository/evidence sample | Truth result | Limit |' '|---|---|---|---|---|---|' \
      "| glossary-root | Vocabulary inventory owner | $all_ids | [glossary owner](../glossary/README.md) | pass | The inventory sample does not replace term-body review. |" \
      '| glossary-ready | Ready term owner | G01,G02,G03,G04,G05,G06,G07,G08 | [ready term](../glossary/ready.md) | pass | This term sample does not prove other families. |' '' \
      '## Exact profile' '' '| Item ID | Disposition | Plain answer | Owner / evidence |' '|---|---|---|---|'
    for id in C01 C02 C03 C04 C05 C06 C07 C08 C09; do printf '| %s | covered | The glossary owner gives a concrete reader decision and safe evidence route for this vocabulary scope. | [glossary owner](../glossary/README.md) |\n' "$id"; done
    for id in G01 G02 G03 G04 G05 G06 G07 G08; do printf '| %s | covered | The ready entry and finite family inventory expose the definition, distinction, owner, lifecycle, and exact route. | [ready term](../glossary/ready.md) |\n' "$id"; done
    for id in Q01 Q02 Q03 Q04 Q05 Q06 Q07 Q08 Q09 Q10 Q11 Q12 Q13 Q14 Q15 Q16 Q17 Q18 Q19 Q20 Q21; do printf '| %s | covered | The applicable quality concern has a current vocabulary owner, evidence route, and explicit operating limit. | [glossary owner](../glossary/README.md) |\n' "$id"; done
    printf '%s\n' '' '## Required changes and verdict' '' \
      '| Change ID | Status | Required change | Owner | Closure evidence |' '|---|---|---|---|---|' \
      '| none | none | No required change remains after this review. | — | The unresolved count is zero and the final verdict is no-more-required-changes. |' '' \
      'Final verdict: `no-more-required-changes`.'
  } > "$artifact"
}

write_records_index_fixture() {
  local root="$1" ssot="$1/SSOT" records="$1/SSOT/04-records"
  write_exact_area_status "$root"
  mkdir -p "$records"/{decisions,research,bugs,gotchas,tech-debt}
  printf '%s\n' '# Repository route' '' 'This route sends record questions to the unique current record owner and its evidence boundary.' > "$ssot/README.md"
  printf '%s\n' '# Records' '' 'This router separates decisions, research, defects, pitfalls, and repayment work, then sends each ID to one narrative owner.' > "$records/README.md"
  sed_inplace 's#^| records | gap |.*#| records | covered | [records owner](./04-records/README.md) |#' "$ssot/STATUS.md"
  printf '%s\n' '# Decisions' '' '## Decision Index' '' '| ID | Title | Record status | Implementation state | Date | Entry owner |' '|---|---|---|---|---|---|' '| DEC-0001 | Choice | accepted | implemented | 2026-07-13 | [entry](./0001-choice.md) |' > "$records/decisions/README.md"
  printf '%s\n' '---' 'id: DEC-0001' 'record_status: accepted' 'status: accepted' 'implementation_state: implemented' 'created_on: 2026-07-13' 'updated_on: 2026-07-13' 'introduced_in: abcdef1' '---' '# Choice' '' 'This accepted decision is implemented and owns its rationale and evidence.' > "$records/decisions/0001-choice.md"
  printf '%s\n' '# Research' '' '## Research Index' '' '| ID | Title | Record status | Adoption state | Kind | Created | Entry owner |' '|---|---|---|---|---|---|---|' '| RES-0001 | Study | validated | promoted | research | 2026-07-13 | [entry](./0001-study.md) |' > "$records/research/README.md"
  printf '%s\n' '---' 'id: RES-0001' 'record_status: validated' 'adoption_state: promoted' 'promotion_state: promoted' 'status: validated' 'kind: research' 'created_on: 2026-07-13' 'owner: records' 'promotion_targets:' '  - SSOT/04-records/README.md' 'recheck_trigger: owner contract changes' '---' '# Study' '' 'Do not use for claims beyond the promoted owner and current evidence.' > "$records/research/0001-study.md"
  printf '%s\n' '# Bugs' '' '## Bug index' '' '| ID | Failure mode | Record status | Failure state | Severity | Entry owner |' '|---|---|---|---|---|---|' '| BUG-0001 | Failure | current | fixed | major | [entry](./0001-failure.md) |' > "$records/bugs/README.md"
  printf '%s\n' '---' 'id: BUG-0001' 'record_status: current' 'failure_state: fixed' 'status: fixed' 'severity: major' 'created_on: 2026-07-13' '---' '# Failure' '' 'The failure is fixed and its recurrence evidence remains owned here.' > "$records/bugs/0001-failure.md"
  printf '%s\n' '# Gotchas' '' '## Pitfall index' '' '| ID | Pitfall | Record status | Hazard state | Trigger hint | Entry owner |' '|---|---|---|---|---|---|' '| GOT-0001 | Trap | current | active | delegated edit | [entry](./topic.md#got-0001) |' > "$records/gotchas/README.md"
  printf '%s\n' '# Topic' '' '## GOT-0001' '' '- **Record status / hazard state**: `current` / `active`.' '' 'This trap is active when a delegated edit bypasses its unique owner.' > "$records/gotchas/topic.md"
  printf '%s\n' '# Technical debt' '' '## Debt index' '' '| ID | Debt | Record status | Repayment state | Priority | Entry owner |' '|---|---|---|---|---|---|' '| DEBT-0001 | Debt | current | active | high | [entry](./0001-debt.md) |' > "$records/tech-debt/README.md"
  printf '%s\n' '---' 'id: DEBT-0001' 'record_status: current' 'repayment_state: active' 'status: active' 'created_on: 2026-07-13' '---' '# Debt' '' 'This active debt owns its repayment state, risk, and closure trigger.' > "$records/tech-debt/0001-debt.md"
}

write_empty_records_index_fixture() {
  local root="$1" ssot="$1/SSOT" records="$1/SSOT/04-records" name header
  write_exact_area_status "$root"
  mkdir -p "$records"/{decisions,research,bugs,gotchas,tech-debt}
  printf '%s\n' '# Repository route' '' 'This route sends record questions to the current records owner.' > "$ssot/README.md"
  printf '%s\n' '# Records' '' 'This router owns the finite record collections and their empty dispositions.' > "$records/README.md"
  sed_inplace 's#^| records | gap |.*#| records | covered | [records owner](./04-records/README.md) |#' "$ssot/STATUS.md"
  printf '%s\n' '# Decisions' '' 'Empty collection: reason=no durable decision has been accepted; owner=[records owner](../README.md); review when=a hard-to-reverse choice appears.' '' '## Decision Index' '' '| ID | Title | Record status | Implementation state | Date | Entry owner |' '|---|---|---|---|---|---|' > "$records/decisions/README.md"
  printf '%s\n' '# Research' '' 'Empty collection: reason=no bounded study currently exists; owner=[records owner](../README.md); review when=a reusable evidence question appears.' '' '## Research Index' '' '| ID | Title | Record status | Adoption state | Kind | Created | Entry owner |' '|---|---|---|---|---|---|---|' > "$records/research/README.md"
  printf '%s\n' '# Bugs' '' 'Empty collection: reason=no durable defect has been confirmed; owner=[records owner](../README.md); review when=a reproducible failure appears.' '' '## Bug index' '' '| ID | Failure mode | Record status | Failure state | Severity | Entry owner |' '|---|---|---|---|---|---|' > "$records/bugs/README.md"
  printf '%s\n' '# Gotchas' '' 'Empty collection: reason=no repository-specific trap is known; owner=[records owner](../README.md); review when=a repeatable pitfall appears.' '' '## Pitfall index' '' '| ID | Pitfall | Record status | Hazard state | Trigger hint | Entry owner |' '|---|---|---|---|---|---|' > "$records/gotchas/README.md"
  printf '%s\n' '# Technical debt' '' 'Empty collection: reason=no accepted repayment obligation exists; owner=[records owner](../README.md); review when=a named compromise is accepted.' '' '## Debt index' '' '| ID | Debt | Record status | Repayment state | Priority | Entry owner |' '|---|---|---|---|---|---|' > "$records/tech-debt/README.md"
}

write_v260_review() {
  local file="$1" scope="${2:-SSOT/01-product}" score="${3:-29/32}"
  local ssot_dir root scope_dir repository_commit content_fingerprint quality_disposition_fingerprint_value review_scope_id task_count reason_page
  local task_score_2 task_score_1 all_leaf_ids row task_class authorises status_scope
  local product_reader_count=0 product_surface_count=0 product_bridge_count=0
  local architecture_reader_count=0 architecture_owner_count=0 architecture_view_count=0 architecture_surface_count=0 architecture_bridge_count=0
  local target_id owner_link target_kind target_disposition assigned_task evidence_link product_bridge_inventory architecture_view_inventory
  local -a task_rows task_classes dimension_rows profile_ids target_rows
  ssot_dir=$(cd "$(dirname "$file")/.." && pwd -P)
  root=$(dirname "$ssot_dir")
  scope_dir="$root/$scope"
  if ! grep -qE '^## (Quality, Risk, and Governance|质量、风险与治理)$' "$ssot_dir/STATUS.md"; then
    append_quality_register "$root"
  fi
  repository_commit=$(fixture_commit "$root")
  content_fingerprint=$(reader_surface_fingerprint "$ssot_dir")
  quality_disposition_fingerprint_value=$(quality_disposition_fingerprint "$ssot_dir/STATUS.md")
  if [[ "$scope" == "SSOT/01-product" ]]; then
    review_scope_id=product
    status_scope=product
    authorises=area:product:covered
    task_count=6
    reason_page='../01-product/README.md'
    task_classes=(
      product-orientation-decision
      product-main-journey-acceptance
      product-control-failure-recovery
      product-surface-inventory
      product-boundary-trust-data
      product-architecture-trace
    )
    task_rows=(
      '| product-orientation-decision | Implementation delegator decides whether the product fits the job | Ask the implementation Agent to preserve the declared product promise and boundary | The reader can identify the current entry, result, and acceptance evidence | Stop if the promise or evidence cannot be recovered without source code | SSOT/README.md | SSOT/README.md; SSOT/01-product/README.md | 1 | Audience, promise, prerequisites, and next decision recovered | pass | [product owner](../01-product/README.md); runtime use is outside this sample | pass |'
      '| product-main-journey-acceptance | Outcome reviewer decides whether the main journey meets acceptance | Ask the implementation Agent to deliver the named journey and acceptance result | The current result can be accepted or rejected with visible evidence | Escalate when the result or rejection boundary is missing or contradictory | SSOT/README.md | SSOT/01-product/README.md; SSOT/01-product/prd.md | 3 | Main result, acceptance, reject, and handoff recovered | pass | [product owner](../01-product/prd.md); one journey sampled | pass |'
      '| product-control-failure-recovery | Operator decides how to control, stop, diagnose, and recover | Ask the implementation Agent to preserve control side effects and recovery semantics | The operator sees the control result and the recoverable or irreversible boundary | Stop when a failed control could silently change or lose current state | SSOT/README.md | SSOT/01-product/README.md; SSOT/01-product/prd.md | 3 | Control side effects and irreversible boundaries recovered | pass | [product owner](../01-product/prd.md); one representative failure sampled | pass |'
      '| product-surface-inventory | Reviewer checks that every visible surface class and affordance is disposed | Ask the implementation Agent to add or explicitly disposition every real surface | Every page and non-page surface has one owner maturity and evidence route | Stop when a real surface is absent duplicated or hidden by aggregation | SSOT/README.md | SSOT/01-product/README.md; SSOT/01-product/_manifest.md | 3 | Finite inventory and aggregation boundary recovered | pass | [product inventory](../01-product/_manifest.md); live UI census is sampled | pass |'
      '| product-boundary-trust-data | Reviewer decides whether identity, access, privacy, retention, and audit claims fit | Ask the implementation Agent to preserve the stated trust and data boundary | Identity access retention and audit limits remain visible to the user | Escalate when implementation evidence implies a stronger trust claim | SSOT/README.md | SSOT/01-product/prd.md; SSOT/01-product/_manifest.md | 3 | Trust and data limits recovered without code inspection | pass | [product owner](../01-product/prd.md); one claim sampled | pass |'
      '| product-architecture-trace | Reviewer traces one product promise to its runtime owner and failure view | Ask the implementation Agent to keep the product promise linked to one runtime owner | The surface owner boundary and operations view agree end to end | Stop when the trace invents an owner or changes the product promise | SSOT/README.md | SSOT/01-product/_manifest.md; SSOT/02-architecture/_manifest.md | 4 | Product surface, owner, boundary, and operations view recovered | pass | [product inventory](../01-product/_manifest.md); one cross-scope trace sampled | pass |'
    )
    profile_ids=(C01 C02 C03 C04 C05 C06 C07 C08 C09 P01 P02 P03 P04 P05 P06 P07 P08 P09 P10 P11 P12 P13 P14 P15 P16 P17 P18 P19 P20 P21 P22 P23 Q01 Q02 Q03 Q04 Q05 Q06 Q07 Q08 Q09 Q10 Q11 Q12 Q13 Q14 Q15 Q16 Q17 Q18 Q19 Q20 Q21)

    for row in \
      'owner:01-product/README.md|../01-product/README.md' \
      'owner:01-product/prd.md|../01-product/prd.md' \
      'owner:01-product/product-model.md|../01-product/product-model.md' \
      'owner:01-product/capabilities/README.md|../01-product/capabilities/README.md' \
      'owner:01-product/journeys/README.md|../01-product/journeys/README.md' \
      'owner:01-product/roadmap-and-acceptance.md|../01-product/roadmap-and-acceptance.md'; do
      IFS='|' read -r target_id owner_link <<< "$row"
      [[ -f "$ssot_dir/${owner_link#../}" ]] || continue
      target_rows+=("| $target_id | reader-owner | current owner | [owner/body]($owner_link) | product-orientation-decision | Preserve this reader owner and its delegated decision with the visible result. | pass | [owner evidence]($owner_link); this documentation sample does not execute the product. |")
      product_reader_count=$((product_reader_count + 1))
    done
    while IFS=$'\034' read -r target_id target_disposition; do
      [[ -n "$target_id" ]] || continue
      target_rows+=("| $target_id | product-surface | $target_disposition | [product owner](../01-product/prd.md) | product-surface-inventory | Keep this visible surface assigned to its current product owner and acceptance boundary. | pass | [product evidence](../01-product/prd.md); this owner evidence does not replace live surface verification. |")
      product_surface_count=$((product_surface_count + 1))
    done < <(awk -F'|' '
      function trim(v){gsub(/^[[:space:]`]+|[[:space:]`]+$/,"",v);return v}
      /^\|/ && $0 ~ /(Surface ID|表面 ID)/ { active=1; next }
      active && /^\|[[:space:]:|-]+\|[[:space:]:|-]+(\|[[:space:]:|-]+)+\|?[[:space:]]*$/ { next }
      active && /^\|/ { print trim($2) sprintf("%c",28) trim($6); next }
      active { exit }
    ' "$ssot_dir/01-product/_manifest.md" 2>/dev/null)
    if [[ -f "$ssot_dir/02-architecture/_manifest.md" && -f "$ssot_dir/02-architecture/README.md" ]]; then
      while IFS=$'\034' read -r target_id target_disposition; do
        [[ -n "$target_id" ]] || continue
        target_rows+=("| bridge:$target_id | bridge | $target_disposition | [architecture owner](../02-architecture/README.md) | product-architecture-trace | Preserve this product-to-runtime bridge and its visible product boundary. | pass | [architecture evidence](../02-architecture/README.md); this review does not execute the runtime bridge. |")
        product_bridge_count=$((product_bridge_count + 1))
      done < <(awk -F'|' '
        function trim(v){gsub(/^[[:space:]`]+|[[:space:]`]+$/,"",v);return v}
        /^\|/ && $0 ~ /(Product surface ID|产品表面 ID)/ { active=1; next }
        active && /^\|[[:space:]:|-]+\|[[:space:]:|-]+(\|[[:space:]:|-]+)+\|?[[:space:]]*$/ { next }
        active && /^\|/ { print trim($2) sprintf("%c",28) trim($3); next }
        active { exit }
      ' "$ssot_dir/02-architecture/_manifest.md")
    fi
    product_bridge_inventory='../01-product/_manifest.md'
    [[ -f "$ssot_dir/02-architecture/_manifest.md" ]] && product_bridge_inventory='../02-architecture/_manifest.md'
  else
    review_scope_id=architecture
    status_scope=architecture
    authorises=area:architecture:covered
    task_count=6
    reason_page='../02-architecture/README.md'
    task_classes=(
      architecture-orientation-request-result
      architecture-owner-state-contract
      architecture-failure-recovery
      architecture-deployment-diagnosis
      architecture-product-trace
      architecture-inventory-evidence
    )
    task_rows=(
      '| architecture-orientation-request-result | Implementation delegator decides where a request enters and what result returns | Ask the implementation Agent to preserve the canonical request-to-result path | The reader sees the actors state change and returned result in order | Stop when the current path requires source reading or contradicts a domain owner | SSOT/README.md | SSOT/02-architecture/README.md | 2 | Actors, request, state change, and visible result recovered | pass | [architecture owner](../02-architecture/README.md); one variant sampled | pass |'
      '| architecture-owner-state-contract | Maintainer decides which owner may change state or a contract | Ask the implementation Agent to change only the registered writer and contract owner | The unique writer contract and handoff remain visible and consistent | Escalate when two owners can write the same state or redefine one contract | SSOT/README.md | SSOT/02-architecture/README.md; SSOT/02-architecture/_manifest.md | 3 | Unique owner, writer, contract, and handoff recovered | pass | [owner registry](../02-architecture/_manifest.md); one domain boundary sampled | pass |'
      '| architecture-failure-recovery | Operator decides how failure degrades, recovers, or becomes irreversible | Ask the implementation Agent to preserve detection degradation and recovery boundaries | The operator can identify the failure owner and safe recovery action | Stop when retry rollback or irreversible state cannot be distinguished | SSOT/README.md | SSOT/02-architecture/README.md; SSOT/02-architecture/views/README.md | 3 | Failure partition and recovery owner recovered | pass | [architecture views](../02-architecture/views/README.md); one cross-owner failure sampled | pass |'
      '| architecture-deployment-diagnosis | Operator decides how to deploy, observe, diagnose, restart, or roll back | Ask the implementation Agent to preserve topology signals and rollback identity | The operator can reach the right signal diagnosis and recovery owner | Stop when health can be green for the wrong version or empty data | SSOT/README.md | SSOT/02-architecture/views/README.md | 3 | Topology, signal, diagnosis, and rollback posture recovered | pass | [architecture views](../02-architecture/views/README.md); infrastructure execution is outside this review | pass |'
      '| architecture-product-trace | Outcome reviewer traces a product surface to runtime truth and operations | Ask the implementation Agent to preserve the surface-to-runtime boundary | The product surface resolves to one owner state boundary and operations view | Stop when architecture strengthens or changes the product promise | SSOT/README.md | SSOT/01-product/_manifest.md; SSOT/02-architecture/_manifest.md | 4 | Surface, owner, state boundary, and view recovered | pass | [architecture inventory](../02-architecture/_manifest.md); one cross-scope trace sampled | pass |'
      '| architecture-inventory-evidence | Reviewer checks owner, technical registry, evidence fitness, and gaps | Ask the implementation Agent to disposition every owner technical surface and Q gap | Every registered surface and concern has one owner and fitting evidence limit | Escalate when an owner is inferred from the tree or evidence is only a path | SSOT/README.md | SSOT/02-architecture/_manifest.md | 3 | Owner and surface dispositions plus evidence limits recovered | pass | [architecture inventory](../02-architecture/_manifest.md); exhaustive source audit is outside this task | pass |'
    )
    profile_ids=(C01 C02 C03 C04 C05 C06 C07 C08 C09 A01 A02 A03 A04 A05 A06 A07 A08 A09 A10 A11 A12 A13 A14 A15 A16 A17 A18 Q01 Q02 Q03 Q04 Q05 Q06 Q07 Q08 Q09 Q10 Q11 Q12 Q13 Q14 Q15 Q16 Q17 Q18 Q19 Q20 Q21)

    for row in \
      'owner:02-architecture/README.md|../02-architecture/README.md' \
      'owner:02-architecture/views/README.md|../02-architecture/views/README.md'; do
      IFS='|' read -r target_id owner_link <<< "$row"
      [[ -f "$ssot_dir/${owner_link#../}" ]] || continue
      target_rows+=("| $target_id | reader-owner | current owner | [owner/body]($owner_link) | architecture-orientation-request-result | Preserve this architecture reader owner and the request-to-result decision it teaches. | pass | [owner evidence]($owner_link); this documentation sample does not execute the runtime path. |")
      architecture_reader_count=$((architecture_reader_count + 1))
    done
    while IFS= read -r owner_link; do
      target_id="owner:02-architecture/$(basename "$(dirname "$owner_link")")/README.md"
      owner_link="../02-architecture/$(basename "$(dirname "$owner_link")")/README.md"
      target_rows+=("| $target_id | reader-owner | current owner | [owner/body]($owner_link) | architecture-owner-state-contract | Preserve this domain reader owner and its state and contract boundary. | pass | [owner evidence]($owner_link); this documentation sample does not execute domain behaviour. |")
      architecture_reader_count=$((architecture_reader_count + 1))
    done < <(find "$ssot_dir/02-architecture" -mindepth 2 -maxdepth 2 -type f -name README.md 2>/dev/null | awk -F/ '$(NF-1) ~ /^[0-9][0-9]-/' | LC_ALL=C sort)
    if [[ -f "$ssot_dir/02-architecture/_manifest.md" ]]; then
      while IFS=$'\034' read -r target_id target_disposition owner_link; do
        [[ -n "$target_id" ]] || continue
        owner_link="../02-architecture/${owner_link#./}"
        target_rows+=("| owner:02-architecture/_manifest.md#$target_id | reader-owner | $target_disposition | [owner/body]($owner_link) | architecture-owner-state-contract | Keep this direct owner unique and preserve its state and contract handoff. | pass | [owner evidence]($owner_link); this registry review does not execute owner behaviour. |")
        architecture_owner_count=$((architecture_owner_count + 1))
      done < <(awk -F'|' '
        function trim(v){gsub(/^[[:space:]`]+|[[:space:]`]+$/,"",v);return v}
        /^\|/ && $0 ~ /(Owner ID|所有者 ID)/ { active=1; next }
        active && /^\|[[:space:]:|-]+\|[[:space:]:|-]+(\|[[:space:]:|-]+)+\|?[[:space:]]*$/ { next }
        active && /^\|/ { owner=trim($4); if(match(owner,/\]\(([^)]+[.]md)\)/)){link=substr(owner,RSTART+2,RLENGTH-3); print trim($2) sprintf("%c",28) trim($3) sprintf("%c",28) link}; next }
        active { exit }
      ' "$ssot_dir/02-architecture/_manifest.md")
      if [[ -f "$ssot_dir/02-architecture/views/_manifest.md" ]]; then
        while IFS=$'\034' read -r target_id owner_link; do
          [[ -n "$target_id" ]] || continue
          owner_link="../02-architecture/views/${owner_link#./}"
          target_rows+=("| view:$target_id | cross-owner-view | covered | [owner/body]($owner_link) | architecture-failure-recovery | Preserve this cross-owner view and its delegated diagnosis or recovery decision. | pass | [view evidence]($owner_link); this documentation sample does not execute the cross-owner path. |")
          architecture_view_count=$((architecture_view_count + 1))
        done < <(awk -F'|' '
          function trim(v){gsub(/^[[:space:]`]+|[[:space:]`]+$/,"",v);return v}
          /^\|/ && $0 ~ /(Question class|问题类别)/ { active=1; next }
          active && /^\|[[:space:]:|-]+\|[[:space:]:|-]+(\|[[:space:]:|-]+)+\|?[[:space:]]*$/ { next }
          active && /^\|/ { question=tolower(trim($2)); gsub(/[^a-z0-9]+/,"-",question); gsub(/^-+|-+$/,"",question); owner=trim($3); if(match(owner,/\]\(([^)]+[.]md)\)/)){link=substr(owner,RSTART+2,RLENGTH-3); print question sprintf("%c",28) link}; next }
          active { exit }
        ' "$ssot_dir/02-architecture/views/_manifest.md")
      fi
      while IFS=$'\034' read -r target_id target_disposition owner_link; do
        [[ -n "$target_id" ]] || continue
        target_rows+=("| $target_id | technical-surface | $target_disposition | [owner/body](../02-architecture/01-runtime/README.md) | architecture-inventory-evidence | Keep this technical surface registered to one owner with fitting evidence and limits. | pass | [architecture evidence](../02-architecture/01-runtime/README.md); this inventory sample does not execute the surface. |")
        architecture_surface_count=$((architecture_surface_count + 1))
      done < <(awk -F'|' '
        function trim(v){gsub(/^[[:space:]`]+|[[:space:]`]+$/,"",v);return v}
        /^\|/ && $0 ~ /(Technical surface ID|技术表面 ID)/ { active=1; next }
        active && /^\|[[:space:]:|-]+\|[[:space:]:|-]+(\|[[:space:]:|-]+)+\|?[[:space:]]*$/ { next }
        active && /^\|/ { print trim($2) sprintf("%c",28) trim($5) sprintf("%c",28) trim($4); next }
        active { exit }
      ' "$ssot_dir/02-architecture/_manifest.md")
      while IFS=$'\034' read -r target_id target_disposition; do
        [[ -n "$target_id" ]] || continue
        target_rows+=("| bridge:$target_id | bridge | $target_disposition | [architecture owner](../02-architecture/01-runtime/README.md) | architecture-product-trace | Preserve this product-to-runtime bridge without strengthening the product promise. | pass | [architecture evidence](../02-architecture/01-runtime/README.md); this review does not execute the bridge. |")
        architecture_bridge_count=$((architecture_bridge_count + 1))
      done < <(awk -F'|' '
        function trim(v){gsub(/^[[:space:]`]+|[[:space:]`]+$/,"",v);return v}
        /^\|/ && $0 ~ /(Product surface ID|产品表面 ID)/ { active=1; next }
        active && /^\|[[:space:]:|-]+\|[[:space:]:|-]+(\|[[:space:]:|-]+)+\|?[[:space:]]*$/ { next }
        active && /^\|/ { print trim($2) sprintf("%c",28) trim($3); next }
        active { exit }
      ' "$ssot_dir/02-architecture/_manifest.md")
    fi
    architecture_view_inventory='../02-architecture/views/README.md'
    [[ -f "$ssot_dir/02-architecture/views/_manifest.md" ]] && architecture_view_inventory='../02-architecture/views/_manifest.md'
  fi

  if ! grep -q '^## Stop Review Gate$' "$ssot_dir/STATUS.md"; then
    printf '%s\n' '' '## Stop Review Gate' '' \
      '| Scope | Stop claim | Reviewer | Reviewer role | Reviewed at | Result | Evidence | Remaining changes | Authorises |' \
      '|---|---|---|---|---|---|---|---|---|' \
      >> "$ssot_dir/STATUS.md"
  fi
  sed_inplace "/^## Stop Review Gate$/,/^## / { /^|---|---|---|---|---|---|---|---|---|$/a\\
| $status_scope | covered | agent:test | independent-cold-reader | 2026-01-01 | no-more-required-changes | [reader review](./.bootstrap/reader-review.md) | none | $authorises |
  }" "$ssot_dir/STATUS.md"
  all_leaf_ids='RF1,RF2,LA1,LA2,LA3,CT1,CT2,CT3,CT4,BC1,BC2,BC3,BC4,RP1,RP2,RP3'
  task_score_2="${task_classes[0]}=2"
  task_score_1="${task_classes[0]}=1"
  for task_class in "${task_classes[@]:1}"; do
    task_score_2+=";${task_class}=2"
    task_score_1+=";${task_class}=2"
  done
  dimension_rows=(
    "| Reader fit | RF1 | Reader, decision, and action fit | $task_score_2 | 2 | [current owner]($reason_page) names the implementation delegator, decision, acceptance, and next action. |"
    "| Reader fit | RF2 | Orientation and visible outcome | $task_score_1 | 1 | [current owner]($reason_page) gives the entry and outcome with one minor orientation detour. |"
    "| Plain-language clarity | LA1 | First-use terminology | $task_score_2 | 2 | [current owner]($reason_page) defines repository terms before relying on them. |"
    "| Plain-language clarity | LA2 | Plain-language cognitive load | $task_score_2 | 2 | [current owner]($reason_page) is understandable without reading code and controls abstractions and acronyms. |"
    "| Plain-language clarity | LA3 | Concrete grounding | $task_score_2 | 2 | [current owner]($reason_page) grounds each load-bearing conclusion in a concrete scene or example. |"
    "| Causal and truth story | CT1 | Causal chain | $task_score_2 | 2 | [current owner]($reason_page) connects pressure, action, state change, and outcome in order. |"
    "| Causal and truth story | CT2 | Current truth and cross-owner consistency | $task_score_2 | 2 | [current owner]($reason_page) and sampled owners state one non-conflicting current truth. |"
    "| Causal and truth story | CT3 | Posture, uncertainty, and change | $task_score_2 | 2 | [current owner]($reason_page) separates current, target, gap, unknown, assumptions, and change triggers. |"
    "| Causal and truth story | CT4 | Success, failure, and recovery | $task_score_2 | 2 | [current owner]($reason_page) explains successful completion, failure, recovery, and irreversible limits. |"
    "| Boundary and coverage | BC1 | Boundaries and non-goals | $task_score_2 | 2 | [current owner]($reason_page) says what this owner does and deliberately does not own. |"
    "| Boundary and coverage | BC2 | Unique owner and handoff reachability | $task_score_2 | 2 | [current owner]($reason_page) routes each authority and handoff to one reachable owner. |"
    "| Boundary and coverage | BC3 | Evidence fitness, fidelity, freshness, and invalidation | $task_score_2 | 2 | [current owner]($reason_page) names fitting evidence, its limits, freshness, and invalidation trigger. |"
    "| Boundary and coverage | BC4 | Scope completeness | $task_score_1 | 1 | [current owner]($reason_page) and the completeness profile dispose every required question with one minor detour. |"
    "| Reading path | RP1 | Scannability and progressive disclosure | $task_score_2 | 2 | [current owner]($reason_page) leads with plain conclusions before precision and recovery detail. |"
    "| Reading path | RP2 | Bounded route and locality | $task_score_1 | 1 | [current owner]($reason_page) stays within four hops with one necessary cross-owner route. |"
    "| Reading path | RP3 | Table-independent narrative | $task_score_2 | 2 | [current owner]($reason_page) preserves the causal story when all Markdown tables are hidden. |"
  )
  {
    printf '%s\n' \
    '---' \
    "review_id: review:${review_scope_id}:20260101:fixture" \
    "review_scope: $scope" \
    'review_type: routine' \
    'reader_profile: implementation-delegator' \
    "completeness_profile: $review_scope_id" \
    'protocol_version: "2.60"' \
    'reviewed_on: 2026-01-01' \
    'reviewer: agent:test' \
    'reviewer_role: independent-cold-reader' \
    "repository_commit: $repository_commit" \
    "content_fingerprint: $content_fingerprint" \
    "quality_disposition_fingerprint: $quality_disposition_fingerprint_value" \
    'sample_seed: seed:fixture:001' \
    'rotation_id: rotation:fixture:a' \
    "task_count: $task_count" \
    "passed_task_count: $task_count" \
    'failed_task_count: 0' \
    'entrypoint: SSOT/README.md' \
    'tables_hidden: true' \
    'bounded_read_set: true' \
    'route_probe: passed' \
    'truth_consistency: passed' \
    'evidence_sample: passed' \
    'scored_dimensions: 16' \
    "score: \"$score\"" \
    'critical_truth_errors: 0' \
    'unresolved_required_changes: 0' \
    "authorises: $authorises" \
    'verdict: no-more-required-changes' \
    '---' \
    '# Cold-reader review' '' \
    '## Bounded reading set' '' \
    '| Step | Page | Reason | Hops | Friction |' '|---|---|---|---:|---|' \
    '| 1 | SSOT/README.md | Start at the declared router | 0 | none |' \
    '| 2 | SSOT/01-product/README.md | Follow the product route | 1 | none |' '' \
    '### Mandatory task matrix' '' \
    '| Task class | Reader and decision | Delegated action | Expected visible result | Stop or escalate when | Entrypoint | Files opened | Actual hops | Observed outcome | Table-hidden result | Evidence and limit | Verdict |' '|---|---|---|---|---|---|---|---:|---|---|---|---|' \
    "${task_rows[@]}" '' \
    '### Task-to-leaf applicability' '' \
    '| Task class | Applicable leaf IDs | Why applicable |' '|---|---|---|'
    for task_class in "${task_classes[@]}"; do
      printf '| %s | %s | The task exercises reader fit, language, truth, boundaries, evidence, and the reading path. |\n' "$task_class" "$all_leaf_ids"
    done
    printf '%s\n' '' '### Finite owner and target coverage' '' \
      '| Frozen population | Source inventory | Expected targets | Listed targets | Reconciliation result |' \
      '|---|---|---:|---:|---|'
    if [[ "$review_scope_id" == product ]]; then
      printf '%s\n' \
        "| product-reader-owner | [product owners](../01-product/README.md) | $product_reader_count | $product_reader_count | pass |" \
        "| product-surface | [product inventory](../01-product/_manifest.md) | $product_surface_count | $product_surface_count | pass |" \
        "| product-bridge | [bridge inventory]($product_bridge_inventory) | $product_bridge_count | $product_bridge_count | pass |"
    else
      printf '%s\n' \
        "| architecture-reader-owner | [architecture owners](../02-architecture/README.md) | $architecture_reader_count | $architecture_reader_count | pass |" \
        "| architecture-direct-owner | [owner inventory](../02-architecture/_manifest.md) | $architecture_owner_count | $architecture_owner_count | pass |" \
        "| architecture-view | [view inventory]($architecture_view_inventory) | $architecture_view_count | $architecture_view_count | pass |" \
        "| technical-surface | [surface inventory](../02-architecture/_manifest.md) | $architecture_surface_count | $architecture_surface_count | pass |" \
        "| architecture-bridge | [bridge inventory](../02-architecture/_manifest.md) | $architecture_bridge_count | $architecture_bridge_count | pass |"
    fi
    printf '%s\n' '' \
      '| Target ID | Target kind | Frozen disposition | Owner/body | Assigned mandatory task | Decision, delegated action, and visible result | Result | Evidence and limit |' \
      '|---|---|---|---|---|---|---|---|'
    printf '%s\n' "${target_rows[@]}"
    printf '%s\n' '' \
    '## Teach-back' '' \
    'The table-hidden teach-back explained the current story without implementation knowledge.' '' \
    '## Consistency and evidence sample' '' \
    '### Truth consistency' '' \
    '| Claim | Owner | Compared owner | Result | Note |' '|---|---|---|---|---|' \
    "| Current entry | [scope owner]($reason_page) | [root owner](../README.md) | pass | no conflict in the current posture |" \
    "| Cross-scope trace | [scope owner]($reason_page) | [root owner](../README.md) | pass | owner and boundary agree |" '' \
    '### STATUS covered-claim closure' '' \
    '| STATUS row | Scope | Stop claim | Reviewer | Reviewer role | Reviewed date | Result | STATUS evidence resolves to this artifact | Authorises | Match |' \
    '|---|---|---|---|---|---|---|---|---|---|' \
    "| [Stop Review Gate](../STATUS.md#stop-review-gate) | $status_scope | covered | agent:test | independent-cold-reader | 2026-01-01 | no-more-required-changes | yes | $authorises | pass |" '' \
    '### Evidence sample' '' \
    '| Task class | Claim | Evidence | Fitness, fidelity, and freshness | Result | Limit |' '|---|---|---|---|---|---|'
    for task_class in "${task_classes[@]}"; do
      printf '| %s | Consequential current claim | [current owner](%s) | fitting current repository evidence | pass | one representative path |\n' "$task_class" "$reason_page"
    done
    printf '%s\n' '' '### Cold proof gates' '' \
    '| Probe ID | Evidence from mandatory tasks | Result | Limit |' '|---|---|---|---|' \
    '| CP-D | Every task records a reader decision and observed outcome. | pass | one deterministic rotation |' \
    '| CP-R | Every task starts at the root and stays within four hops. | pass | bounded route only |' \
    '| CP-T | Every task preserves its result with tables hidden. | pass | diagrams remain visible |' \
    '| CP-E | Every task records fitting evidence, fidelity, freshness, and a limit. | pass | representative samples |' \
    '| CP-C | The exact common and scope profile items are disposed. | pass | current profile only |' '' \
    '## Dimension scores' '' \
    '| Family | Leaf ID | Dimension | Applicable task scores | Score /2 | Reason and page |' '|---|---|---|---|---:|---|' \
    "${dimension_rows[@]}" \
    '| **Total** | | | | **29/32** | |' '' \
    '## Completeness profile' '' \
    '| Item ID | Disposition | Reason and evidence |' '|---|---|---|'
    for row in "${profile_ids[@]}"; do
      printf '| %s | covered | [current owner](%s) answers this required question and records the current evidence or explicit disposition. |\n' "$row" "$reason_page"
    done
    printf '%s\n' '' \
    '## Required changes and verdict' '' \
    '| Change ID | Status | Required change | Owner | Closure evidence |' \
    '|---|---|---|---|---|' \
    '| none | none | No required change remains after this review. | — | The unresolved count is zero and the final verdict is no-more-required-changes. |' '' \
    'No required change remains. Verdict: no-more-required-changes.'
  } > "$file"
}

write_v260_product_manifest() {
  local file="$1" ssot_dir root
  ssot_dir=$(cd "$(dirname "$file")/.." && pwd -P)
  root=$(dirname "$ssot_dir")
  mkdir -p "$root/src/ui" "$root/src" "$root/tests/e2e" "$root/tests"
  printf '%s\n\n%s\n' \
    'This product owner explains who uses the product, the current visible result, and the product promise in plain language for a new reader.' \
    'It also explains the normal route, an important failure and recovery path, the current limitation, and where acceptance evidence is owned.' \
    > "$ssot_dir/01-product/prd.md"
  printf '%s\n\n%s\n' \
    'This product route introduces the implementation delegator, the current promise, and the visible result before sending each question to its owner.' \
    'It also explains the main decision, failure boundary, evidence route, and the condition that requires escalation.' \
    > "$ssot_dir/01-product/README.md"
  printf '%s\n\n%s\n' \
    'This product model explains the people, durable objects, lifecycle, access boundary, and the user-visible state change in ordinary language.' \
    'It also records the failure and recovery boundary, current limitation, evidence owner, and the next delegated action.' \
    > "$ssot_dir/01-product/product-model.md"
  printf '%s\n\n%s\n' \
    'This roadmap owner separates the current result from target work and names the acceptance evidence an implementation delegator should request.' \
    'It also names the gap owner, falsifiable closure, failure boundary, and the condition that requires another review.' \
    > "$ssot_dir/01-product/roadmap-and-acceptance.md"
  printf '%s\n\n%s\n' \
    'This capability route sends each durable user outcome to one narrative owner and keeps acceptance visible to an implementation delegator.' \
    'It also explains the current boundary, failure recovery, evidence limitation, and the next safe delegation.' \
    > "$ssot_dir/01-product/capabilities/README.md"
  printf '%s\n\n%s\n' \
    'This journey route sends each normal, control, recovery, and diagnosis path to one narrative owner and visible result.' \
    'It also explains the stop condition, recovery owner, evidence limitation, and the next delegated action.' \
    > "$ssot_dir/01-product/journeys/README.md"
  printf '%s\n' 'export const mainPage = true;' > "$root/src/ui/main.ts"
  printf '%s\n' 'export const start = true;' > "$root/src/entry.ts"
  printf '%s\n' 'export const stop = true;' > "$root/src/control.ts"
  printf '%s\n' 'export const status = true;' > "$root/src/health.ts"
  printf '%s\n' 'main page evidence' > "$root/tests/e2e/main.spec.ts"
  printf '%s\n' 'entry evidence' > "$root/tests/test_entry.py"
  printf '%s\n' 'control evidence' > "$root/tests/test_control.py"
  printf '%s\n' 'health evidence' > "$root/tests/test_health.py"
  printf '%s\n' \
    '---' 'manifest_archetype: product-root' 'intent_recovery: covered' '---' \
    '' '## Product recovery coverage' '' \
    '| Required product question | Narrative owner | Recovery coverage | Product maturity after verification | Evidence fidelity | Closure |' '|---|---|---|---|---|---|' \
    '| Product brief and surfaces | prd.md | covered | current | browser | accepted |' \
    '| People, objects, and lifecycle | product-model.md | covered | current | integration | accepted |' \
    '| Capabilities | capabilities/README.md | covered | limited | integration | accepted |' \
    '| Journeys | journeys/README.md | covered | limited | browser | accepted |' \
    '| Acceptance and gaps | roadmap-and-acceptance.md | covered | limited | integration | accepted |' \
    '' '## User-visible surface inventory' '' \
    '| Surface ID | Surface class | Source surface anchor | Product owner | Product maturity | Evidence fidelity | Stable evidence or closure |' '|---|---|---|---|---|---|---|' \
    '| surface:page-main | page | `src/ui/main.ts::mainPage` | [Product brief](./prd.md) | current | browser | evidence: `tests/e2e/main.spec.ts` |' \
    '| surface:navigation-main | navigation | `src/ui/main.ts::mainPage` | [Product brief](./prd.md) | current | browser | evidence: `tests/e2e/main.spec.ts` |' \
    '| surface:entry-primary | entry-mode | `src/entry.ts::start` | [Product brief](./prd.md) | current | integration | evidence: `tests/test_entry.py` |' \
    '| surface:control-stop | control | `src/control.ts::stop` | [Product brief](./prd.md) | limited | integration | evidence: `tests/test_control.py` |' \
    '| surface:settings-na | settings | `not_applicable: this product exposes no settings surface` | [Product brief](./prd.md) | out | static | disposition: settings are intentionally not exposed |' \
    '| surface:diagnostic-status | diagnostic | `src/health.ts::status` | [Product brief](./prd.md) | current | integration | evidence: `tests/test_health.py` |' \
    '| surface:result-review | page | planned_in: [Product brief](./prd.md#planned-result-review) | [Product brief](./prd.md) | target | missing | closure: acceptance owner must land a real review surface before current |' \
    '| surface:external-na | external-channel | `not_applicable: this product exposes no external channel` | [Product brief](./prd.md) | out | static | disposition: external channels are outside the product boundary |' \
    '| surface:command-na | command | `not_applicable: this product exposes no command interface` | [Product brief](./prd.md) | out | static | disposition: commands are outside the product boundary |' \
    '| surface:public-interface-na | public-interface | `not_applicable: this product exposes no public API SDK or library interface` | [Product brief](./prd.md) | out | static | disposition: public interfaces are outside the product boundary |' \
    '| surface:output-artifact-na | output-artifact | `not_applicable: this product creates no user-consumed output artifact` | [Product brief](./prd.md) | out | static | disposition: output artifacts are outside the product boundary |' \
    '| surface:notification-na | notification | `not_applicable: this product sends no notification` | [Product brief](./prd.md) | out | static | disposition: notifications are outside the product boundary |' \
    '| surface:help-na | help-onboarding | `not_applicable: this product exposes no help or onboarding surface` | [Product brief](./prd.md) | out | static | disposition: help and onboarding are outside the product boundary |' \
    '' 'Review: [reader review](../.bootstrap/reader-review.md) — no-more-required-changes.' \
    > "$file"
}

echo "=== test-document-quality-lint ==="

echo "== Q1 covered manifest placeholder is a hard failure =="
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
printf '## Core recovery manifest\n\n| 核心项 | Owner | Pillars | State | Evidence |\n|---|---|---|---|---|\n| <!-- TODO --> | | | | |\n' > "$T/SSOT/01-product/_manifest.md"
out=$(run_quality "$T"); code=$?
assert_contains "placeholder manifest reports completeness" "$out" "[MANIFEST-COMPLETENESS]"
assert_exit "placeholder manifest exits 2" "$code" "2"
rm -rf "$T"

echo "== Q2 heading-only narrative is a hard failure =="
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
printf -- '---\nintent_recovery: covered\n---\n# 产品\n\n## 产品故事\n\n一句口号。\n\n| 能力 | 状态 |\n|---|---|\n| A | current |\n' > "$T/SSOT/01-product/README.md"
out=$(run_quality "$T"); code=$?
assert_contains "heading-only narrative reports sufficiency" "$out" "[NARRATIVE-SUFFICIENCY]"
assert_exit "heading-only narrative exits 2" "$code" "2"
rm -rf "$T"

echo "== Q3 compact table-heavy owner is detected =="
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
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
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
printf -- '---\nintent_recovery: covered\n---\n# 运行时\n\n## 心智模型\n\n第一段解释边界和职责。\n\n第二段解释一次正常流程。\n\n## 状态\n\n| 状态 | Owner |\n|---|---|\n| task | web |\n' > "$T/SSOT/02-architecture/01-runtime/README.md"
out=$(run_quality "$T"); code=$?
assert_contains "missing first-screen diagram reports DIAGRAM-FIRST" "$out" "[DIAGRAM-FIRST]"
assert_exit "missing first-screen diagram exits 2" "$code" "2"
rm -rf "$T"

echo "== Q5 visible protocol meta is rejected from reader prose =="
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
printf -- '---\nintent_recovery: covered\n---\n# 产品\n\n本文按 ssot-bootstrap §3.7 和 Doctor 15H 编写。\n' > "$T/SSOT/01-product/README.md"
out=$(run_quality "$T"); code=$?
assert_contains "protocol meta reports META-LEAKAGE" "$out" "[META-LEAKAGE]"
assert_exit "protocol meta exits 2" "$code" "2"
rm -rf "$T"

echo "== Q6 complete archetype manifests pass the manifest guard =="
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
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
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
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
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
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
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
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
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
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
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
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
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
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
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
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
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
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

echo "== Q11 architecture views require all seven default questions =="
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
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
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
printf -- '---\nintent_recovery: gap\n---\n# Product\n\nThe body has not been written.\n' > "$T/SSOT/01-product/README.md"
out=$(run_quality "$T"); code=$?
assert_contains "covered area rejects gap reader body" "$out" "covered area has a reader file whose intent_recovery is gap"
assert_exit "covered area gap body exits 2" "$code" "2"
rm -rf "$T"

echo "== Q13 focused flag parses default and explicit paths in either order =="
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
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

echo "== Q14 v2.59 authoring-meta tokens are gated by the tracking baseline =="
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
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
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
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
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
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

echo "== Q17 multi-directory meta scan inherits the common v2.59 tracking baseline =="
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
printf '# Product\n\nVisible ssot-bootstrap authoring machinery.\n' > "$T/SSOT/01-product/README.md"
printf '# Architecture\n\nVisible ssot-bootstrap authoring machinery.\n' > "$T/SSOT/02-architecture/README.md"
multi_before=$(bash "$LINT" --check-meta-leakage "$T/SSOT/01-product" "$T/SSOT/02-architecture" 2>&1); multi_before_code=$?
multi_after=$(bash "$LINT" "$T/SSOT/01-product" "$T/SSOT/02-architecture" --check-meta-leakage 2>&1); multi_after_code=$?
assert_contains "flag-first multi-directory scan applies v2.59 tokens" "$multi_before" "[META-LEAKAGE]"
assert_contains "flag-last multi-directory scan applies v2.59 tokens" "$multi_after" "[META-LEAKAGE]"
assert_exit "flag-first multi-directory scan exits 2" "$multi_before_code" "2"
assert_exit "flag-last multi-directory scan exits 2" "$multi_after_code" "2"
rm -rf "$T"

echo "== Q18 v2.60 rejects a one-line review verdict =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
printf '# Reader review\n\nVerdict: no-more-required-changes.\n' > "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T"); code=$?
assert_contains "one-line verdict reports missing structured review evidence" "$out" "[READER-REVIEW-EVIDENCE]"
assert_exit "one-line verdict exits 2" "$code" "2"
rm -rf "$T"

echo "== Q19 v2.60 review scope must match the manifest area =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md" "SSOT/02-architecture"
out=$(run_quality "$T"); code=$?
assert_contains "scope-mismatched review reports evidence failure" "$out" "[READER-REVIEW-EVIDENCE]"
assert_exit "scope-mismatched review exits 2" "$code" "2"
rm -rf "$T"

echo "== Q20 v2.60 product covered claim needs a finite surface inventory =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
printf '%s\n' \
  '---' 'manifest_archetype: product-root' 'intent_recovery: covered' '---' \
  '' '| Required product question | Narrative owner | Recovery coverage | Product maturity after verification | Evidence fidelity | Closure |' '|---|---|---|---|---|---|' \
  '| Product brief and surfaces | prd.md | covered | current | browser | accepted |' \
  '| People, objects, and lifecycle | product-model.md | covered | current | integration | accepted |' \
  '| Capabilities | capabilities/README.md | covered | limited | integration | accepted |' \
  '| Journeys | journeys/README.md | covered | limited | browser | accepted |' \
  '| Acceptance and gaps | roadmap-and-acceptance.md | covered | limited | integration | accepted |' \
  '' 'Review: [reader review](../.bootstrap/reader-review.md) — no-more-required-changes.' > "$T/SSOT/01-product/_manifest.md"
out=$(run_quality "$T"); code=$?
assert_contains "missing real surface inventory reports coverage failure" "$out" "[SURFACE-INVENTORY]"
assert_exit "missing surface inventory exits 2" "$code" "2"
rm -rf "$T"

echo "== Q21 v2.60 architecture root needs a unique owner/surface inventory =="
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
printf '| tracked_skill_version | `2.60` |\n| documentation_language | zh-CN |\n\n| 区域 | 状态 | 备注 |\n|---|---|---|\n| product | gap | |\n| architecture | covered | |\n' > "$T/SSOT/STATUS.md"
printf '%s\n' \
  '---' 'manifest_archetype: architecture-root' 'intent_recovery: covered' '---' \
  '' '| Required architecture question | Narrative owner | Recovery state | Evidence |' '|---|---|---|---|' \
  '| Current system context | README.md | contract | integration trace |' \
  '| Runtime owner map | README.md | mixed | domain owners |' \
  '| Cross-owner views | views/README.md | mixed | view review |' \
  '| Runtime owner domain | [Runtime](./01-runtime/README.md) | contract | integration trace |' \
  '| Global invariants | README.md | contract | enforcement tests |' \
  '| Current target and gaps | views/current-target-gap.md | mixed | debt owners |' \
  '' 'Review: [reader review](../.bootstrap/reader-review.md) — no-more-required-changes.' > "$T/SSOT/02-architecture/_manifest.md"
out=$(run_quality "$T"); code=$?
assert_contains "missing architecture surface registry reports owner inventory failure" "$out" "[OWNER-INVENTORY]"
assert_exit "missing owner inventory exits 2" "$code" "2"
rm -rf "$T"

echo "== Q22 v2.60 structured review still fails below 29/32 =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md" "SSOT/01-product" "28/32"
out=$(run_quality "$T"); code=$?
assert_contains "below-threshold review reports evidence failure" "$out" "[READER-REVIEW-EVIDENCE]"
assert_exit "below-threshold review exits 2" "$code" "2"
rm -rf "$T"

echo "== Q23 v2.60 valid product surface and review evidence satisfy their gates =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T")
assert_not_contains "valid product inventory has no surface-inventory failure" "$out" "[SURFACE-INVENTORY]"
assert_not_contains "valid product review has no review-evidence failure" "$out" "[READER-REVIEW-EVIDENCE]"
assert_not_contains "valid planned target is not an incomplete covered-manifest cell" "$out" "[MANIFEST-COMPLETENESS]"
rm -rf "$T"

echo "== Q24 v2.60 valid architecture owner/surface inventory satisfies its gate =="
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
printf '| tracked_skill_version | `2.60` |\n| documentation_language | zh-CN |\n\n| 区域 | 状态 | 备注 |\n|---|---|---|\n| product | gap | |\n| architecture | covered | |\n' > "$T/SSOT/STATUS.md"
mkdir -p "$T/src" "$T/tests"
printf '%s\n\n%s\n' \
  'The architecture entry routes implementation decisions to one runtime owner and one cross-owner operations view.' \
  'It distinguishes current request behaviour, failure recovery, and the product-to-runtime boundary without copying those owners.' \
  > "$T/SSOT/02-architecture/README.md"
printf '%s\n' 'def run(): pass' 'def cli(): pass' 'def contract(): pass' > "$T/src/runtime.py"
printf '%s\n' 'runtime evidence' > "$T/tests/test_runtime.py"
printf '%s\n' \
  '---' 'manifest_archetype: product-root' 'intent_recovery: gap' '---' \
  '' '| Required product question | Narrative owner | Recovery coverage | Product maturity after verification | Evidence fidelity | Closure |' '|---|---|---|---|---|---|' \
  '| Product brief and surfaces | prd.md | gap | not_assessed | missing | product audit |' \
  '| People, objects, and lifecycle | product-model.md | gap | not_assessed | missing | product audit |' \
  '| Capabilities | capabilities/README.md | gap | not_assessed | missing | product audit |' \
  '| Journeys | journeys/README.md | gap | not_assessed | missing | product audit |' \
  '| Acceptance and gaps | roadmap-and-acceptance.md | gap | not_assessed | missing | product audit |' \
  '' '| Surface ID | Surface class | Source surface anchor | Product owner | Product maturity | Evidence fidelity | Stable evidence or closure |' '|---|---|---|---|---|---|---|' \
  '| surface:page-main | page | src/runtime.py::run | prd.md | current | integration | tests/test_runtime.py |' \
  > "$T/SSOT/01-product/_manifest.md"
printf '%s\n\n%s\n' \
  'The runtime owner accepts a request, changes its owned state, and returns one visible result through a boundary that no sibling domain writes.' \
  'When the request fails, this owner records the failure, exposes the diagnostic signal, and gives the operator one bounded recovery route.' \
  > "$T/SSOT/02-architecture/01-runtime/README.md"
printf '%s\n' '```mermaid' '<!-- diagram_type: component -->' 'flowchart LR' '  A[Request] --> B[Runtime owner]' '```' >> "$T/SSOT/02-architecture/01-runtime/README.md"
printf '%s\n\n%s\n' \
  'The cross-owner view explains where an operator starts diagnosis and which runtime owner must answer for the failed request.' \
  'It keeps the recovery route and deployment signal together without copying the domain contract or product promise.' \
  > "$T/SSOT/02-architecture/views/README.md"
printf '%s\n' \
  '---' 'manifest_archetype: architecture-domain' 'intent_recovery: covered' '---' \
  '' '| Required owner question | Narrative owner | Recovery coverage | Evidence |' '|---|---|---|---|' \
  '| Boundary | README.md | contract | tests/test_runtime.py |' \
  '| State and resources | README.md | contract | tests/test_runtime.py |' \
  '| Contracts and trust | README.md | contract | tests/test_runtime.py |' \
  '| Canonical flow | README.md | contract | tests/test_runtime.py |' \
  '| Failure and recovery | README.md | contract | tests/test_runtime.py |' \
  '' 'Review: [reader review](../../.bootstrap/reader-review.md) — no-more-required-changes.' \
  > "$T/SSOT/02-architecture/01-runtime/_manifest.md"
printf '%s\n' \
  '---' 'manifest_archetype: architecture-root' 'intent_recovery: covered' '---' \
  '' '| Required architecture question | Narrative owner | Recovery state | Evidence |' '|---|---|---|---|' \
  '| Current system context | README.md | contract | integration trace |' \
  '| Runtime owner map | README.md | mixed | domain owners |' \
  '| Cross-owner views | views/README.md | mixed | view review |' \
  '| Runtime owner domain | [Runtime](./01-runtime/README.md) | contract | integration trace |' \
  '| Global invariants | README.md | contract | enforcement tests |' \
  '| Current target and gaps | views/current-target-gap.md | mixed | debt owners |' \
  '' '| Owner ID | Owner class | Narrative owner | Current state | Evidence or closure |' '|---|---|---|---|---|' \
  '| owner:runtime | runtime | [Runtime](./01-runtime/README.md) | contract | evidence: tests/test_runtime.py |' \
  '' '| Technical surface ID | Surface kind | Narrative owner | Current state | Stable anchor | Evidence or closure |' '|---|---|---|---|---|---|' \
  '| tech:web-entry | entry | owner:runtime | contract | src/runtime.py::run | evidence: tests/test_runtime.py |' \
  '| tech:cli-entry | entry | owner:runtime | contract | src/runtime.py::cli | evidence: tests/test_runtime.py |' \
  '| tech:runtime-contract | contract | owner:runtime | contract | src/runtime.py::contract | evidence: tests/test_runtime.py |' \
  '' '| Surface kind | Disposition | Registered surfaces | Disposition reason |' '|---|---|---|---|' \
  '| entry | applicable | tech:web-entry, tech:cli-entry | current request entries exist |' \
  '| write-store | not_applicable | none | this small runtime does not persist state |' \
  '| contract | applicable | tech:runtime-contract | one runtime contract exists |' \
  '| operator-surface | not_applicable | none | no separate operator surface exists |' \
  '| external-integration | not_applicable | none | no external integration exists |' \
  '' '| Product surface ID | Runtime owner ID | Contract or state boundary | Failure or operations view |' '|---|---|---|---|' \
  '| surface:page-main | owner:runtime | src/runtime.py::run | [Operations](./views/README.md#failure) |' \
  '' 'Review: [reader review](../.bootstrap/reader-review.md) — no-more-required-changes.' > "$T/SSOT/02-architecture/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md" "SSOT/02-architecture"
out=$(run_quality "$T")
assert_not_contains "valid architecture inventory has no owner-inventory failure" "$out" "[OWNER-INVENTORY]"
assert_not_contains "valid architecture review has no review-evidence failure" "$out" "[READER-REVIEW-EVIDENCE]"

cp "$T/SSOT/02-architecture/_manifest.md" "$T/architecture-kind-valid"
sed_inplace 's/tech:web-entry, tech:cli-entry/tech:missing/' "$T/SSOT/02-architecture/_manifest.md"
out=$(run_quality "$T")
assert_contains "unknown kind-disposition surface ID is rejected" "$out" "[OWNER-INVENTORY]"
cp "$T/architecture-kind-valid" "$T/SSOT/02-architecture/_manifest.md"

sed_inplace 's/tech:web-entry, tech:cli-entry/tech:runtime-contract/' "$T/SSOT/02-architecture/_manifest.md"
out=$(run_quality "$T")
assert_contains "wrong-kind surface ID is rejected" "$out" "[OWNER-INVENTORY]"
cp "$T/architecture-kind-valid" "$T/SSOT/02-architecture/_manifest.md"

sed_inplace 's/tech:web-entry, tech:cli-entry/tech:web-entry, tech:web-entry/' "$T/SSOT/02-architecture/_manifest.md"
out=$(run_quality "$T")
assert_contains "duplicate kind-disposition surface ID is rejected" "$out" "[OWNER-INVENTORY]"
cp "$T/architecture-kind-valid" "$T/SSOT/02-architecture/_manifest.md"

sed_inplace 's/tech:web-entry, tech:cli-entry/tech:web-entry/' "$T/SSOT/02-architecture/_manifest.md"
out=$(run_quality "$T")
assert_contains "omitted same-kind surface ID is rejected" "$out" "[OWNER-INVENTORY]"
cp "$T/architecture-kind-valid" "$T/SSOT/02-architecture/_manifest.md"

sed_inplace '/^| surface:page-main |/a\
| surface:result-review | page | planned_in: [Product brief](./prd.md#planned-result-review) | prd.md | target | missing | closure: acceptance owner must land a real review surface before current |' "$T/SSOT/01-product/_manifest.md"
out=$(run_quality "$T")
assert_not_contains "planned target with missing fidelity is not an incomplete recovery cell" "$out" "[MANIFEST-COMPLETENESS]"
assert_contains "product surface omitted from architecture bridge fails exact-set coverage" "$out" "[OWNER-INVENTORY]"

sed_inplace '/^| surface:page-main | owner:runtime |/a\
| surface:result-review | owner:runtime | planned_in: product acceptance owner | [Operations](./views/README.md#failure) |' "$T/SSOT/02-architecture/_manifest.md"
out=$(run_quality "$T")
assert_not_contains "planned target is valid after exact bridge coverage" "$out" "[MANIFEST-COMPLETENESS]"
assert_not_contains "planned target exact bridge coverage is complete" "$out" "[OWNER-INVENTORY]"

sed_inplace '/^| surface:page-main | owner:runtime |/a\
| surface:page-main | owner:runtime | src/runtime.py::run | [Operations](./views/README.md#failure) |' "$T/SSOT/02-architecture/_manifest.md"
out=$(run_quality "$T")
assert_contains "duplicate architecture bridge row fails exact-set coverage" "$out" "[OWNER-INVENTORY]"
rm -rf "$T"

echo "== Q25 v2.60 architecture views include deployment and observability =="
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
printf '| tracked_skill_version | `2.60` |\n| documentation_language | zh-CN |\n\n| 区域 | 状态 | 备注 |\n|---|---|---|\n| product | gap | |\n| architecture | covered | |\n' > "$T/SSOT/STATUS.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md" "SSOT/02-architecture"
printf '%s\n' \
  '---' 'manifest_archetype: architecture-views' 'intent_recovery: covered' '---' \
  '' '| Question class | Narrative owner | Recovery coverage | Evidence |' '|---|---|---|---|' \
  '| Operating pressures | [Operating](./operating-model.md) | mixed | owner review |' \
  '| Critical flow | [Journeys](./critical-journeys.md) | contract | trace |' \
  '| State lifecycle | [State](./state-and-data-lifecycle.md) | contract | schema |' \
  '| Trust boundary | [Trust](./contracts-and-trust-boundaries.md) | contract | auth test |' \
  '| Failure recovery | [Recovery](./failure-and-recovery.md) | contract | regression |' \
  '| Evolution | [Gap](./current-target-gap.md) | mixed | debt owners |' \
  '' 'Review: [reader review](../../.bootstrap/reader-review.md) — no-more-required-changes.' > "$T/SSOT/02-architecture/views/_manifest.md"
out=$(run_quality "$T"); code=$?
assert_contains "missing deployment/observability view is reported" "$out" "deployment-and-observability"
assert_exit "missing deployment/observability view exits 2" "$code" "2"
rm -rf "$T"

echo "== Q26 v2.60 review headings cannot replace scored task evidence =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
sed_inplace '/^| Family |/,/^| \*\*Total\*\* |/d' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T"); code=$?
assert_contains "missing sixteen-leaf score table reports review evidence failure" "$out" "[READER-REVIEW-EVIDENCE]"
assert_exit "missing score table exits 2" "$code" "2"
rm -rf "$T"

echo "== Q27 v2.60 review evidence expires when scoped Markdown changes =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
printf '%s\n\n%s\n' \
  'This product page explains the current user problem, the reachable result, and the owner of the promise in enough detail for a new reader.' \
  'It also explains the normal route, the recovery boundary, and the current limitation without requiring a table or source-code knowledge.' \
  > "$T/SSOT/01-product/prd.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
printf '\nA later current-truth claim changed after the review was recorded.\n' >> "$T/SSOT/01-product/prd.md"
out=$(run_quality "$T"); code=$?
assert_contains "stale scoped review reports evidence failure" "$out" "[READER-REVIEW-EVIDENCE]"
assert_exit "stale scoped review exits 2" "$code" "2"
rm -rf "$T"

echo "== Q28 v2.60 high-impact adoption cannot use scoped self-review =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
sed_inplace '/^reviewer_role:/c\
reviewer_role: scoped-self-review' "$T/SSOT/.bootstrap/reader-review.md"
sed_inplace '/^review_type:/c\
review_type: high-impact-adoption' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T"); code=$?
assert_contains "high-impact self-review reports evidence failure" "$out" "[READER-REVIEW-EVIDENCE]"
assert_exit "high-impact self-review exits 2" "$code" "2"
rm -rf "$T"

echo "== Q29 v2.60 review needs the complete scope-specific task matrix =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
sed_inplace '/^| Task class |/,/^$/d' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T"); code=$?
assert_contains "review without mandatory task rows reports evidence failure" "$out" "[READER-REVIEW-EVIDENCE]"
assert_exit "review without mandatory task rows exits 2" "$code" "2"
rm -rf "$T"

echo "== Q30 v2.60 product rows cannot invent owner and evidence paths =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
sed_inplace 's@`src/ui/main.ts::mainPage` | \[Product brief\](\./prd.md) | current | browser | evidence: `tests/e2e/main.spec.ts`@`src/ui/does-not-exist.ts::mainPage` | [Missing owner](./missing-owner.md) | current | browser | evidence: `tests/e2e/missing.spec.ts`@' "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T"); code=$?
assert_contains "forged product owner/evidence reports surface failure" "$out" "[SURFACE-INVENTORY]"
assert_exit "forged product owner/evidence exits 2" "$code" "2"
rm -rf "$T"

echo "== Q31 v2.60 architecture registries cannot merge owners or reuse anchors =="
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
rmdir "$T/SSOT/02-architecture/01-runtime"
mkdir -p "$T/SSOT/02-architecture/01-alpha" "$T/SSOT/02-architecture/02-beta"
printf '| tracked_skill_version | `2.60` |\n| documentation_language | zh-CN |\n\n| 区域 | 状态 | 备注 |\n|---|---|---|\n| product | gap | |\n| architecture | covered | |\n' > "$T/SSOT/STATUS.md"
printf '%s\n' \
  '---' 'manifest_archetype: architecture-root' 'intent_recovery: covered' '---' \
  '' '| Required architecture question | Narrative owner | Recovery state | Evidence |' '|---|---|---|---|' \
  '| Current system context | README.md | contract | integration trace |' \
  '| Runtime owner map | README.md | mixed | domain owners |' \
  '| Cross-owner views | views/README.md | mixed | view review |' \
  '| Runtime owner domain | [Alpha](./01-alpha/README.md) | contract | integration trace |' \
  '| Global invariants | README.md | contract | enforcement tests |' \
  '| Current target and gaps | views/current-target-gap.md | mixed | debt owners |' \
  '' '| Owner ID | Owner class | Narrative owner | Current state | Evidence or closure |' '|---|---|---|---|---|' \
  '| owner:combined | runtime | 01-alpha/README.md plus 02-beta/README.md | contract | tests/test_runtime.py |' \
  '' '| Technical surface ID | Surface kind | Narrative owner | Current state | Stable anchor | Evidence or closure |' '|---|---|---|---|---|---|' \
  '| tech:web-entry | entry | owner:combined | contract | src/shared.py::same | tests/test_runtime.py |' \
  '| tech:run-store | write-store | owner:combined | contract | src/shared.py::same | tests/test_runtime.py |' \
  '| tech:run-api | contract | owner:combined | contract | src/shared.py::same | tests/test_runtime.py |' \
  '| tech:health | operator-surface | owner:combined | contract | src/shared.py::same | tests/test_runtime.py |' \
  '| tech:external | external-integration | owner:combined | design | src/shared.py::same | closure: target integration owner |' \
  '' '| Product capability or surface | Runtime owner | Contract or state boundary | Failure or operations view |' '|---|---|---|---|' \
  '| surface:invented | owner:missing | src/shared.py::same | views/missing.md |' \
  '' 'Review: [reader review](../.bootstrap/reader-review.md) — no-more-required-changes.' > "$T/SSOT/02-architecture/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md" "SSOT/02-architecture"
out=$(run_quality "$T"); code=$?
assert_contains "merged owners and duplicate anchors report owner inventory failure" "$out" "[OWNER-INVENTORY]"
assert_exit "merged owners and duplicate anchors exit 2" "$code" "2"
rm -rf "$T"

echo "== Q32 v2.60 review expires when the root reader entrypoint changes =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
printf '%s\n' '# SSOT reader entrypoint' > "$T/SSOT/README.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
printf '\nThe root route now sends readers through a different owner.\n' >> "$T/SSOT/README.md"
out=$(run_quality "$T"); code=$?
assert_contains "changed root entrypoint expires review evidence" "$out" "[READER-REVIEW-EVIDENCE]"
assert_exit "changed root entrypoint exits 2" "$code" "2"
rm -rf "$T"

echo "== Q33 v2.60 product review expires when architecture trace truth changes =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
printf '%s\n\n%s\n' \
  'The architecture entry explains the current runtime owner reached from the product surface and the decisive state boundary.' \
  'It also explains failure ownership and recovery without requiring a reader to inspect implementation code.' \
  > "$T/SSOT/02-architecture/README.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
printf '\nThe product bridge now routes to a different runtime owner.\n' >> "$T/SSOT/02-architecture/README.md"
out=$(run_quality "$T"); code=$?
assert_contains "changed cross-scope architecture truth expires product review" "$out" "[READER-REVIEW-EVIDENCE]"
assert_exit "changed cross-scope architecture truth exits 2" "$code" "2"
rm -rf "$T"

echo "== Q34 v2.60 legacy ten-dimension reviews cannot satisfy the complete rubric =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
sed_inplace '/^| Plain-language clarity | LA2 |/d' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T"); code=$?
assert_contains "review missing a canonical leaf reports evidence failure" "$out" "[READER-REVIEW-EVIDENCE]"
assert_exit "review missing a canonical leaf exits 2" "$code" "2"
rm -rf "$T"

echo "== Q35 v2.60 STATUS registers reject paragraph-sized evidence cells =="
T=$(mktemp -d -p "$TMPDIR"); make_root "$T"
printf '%s\n' \
  '| tracked_skill_version | `2.60` |' \
  '| documentation_language | zh-CN |' '' \
  '## Core Reference Document Review' '' \
  '| Document | Role | Relation | Status | Evidence/action |' '|---|---|---|---|---|' \
  '| AGENTS.md | agent-rules | thin-adapter | covered | workflow/subagent/Plan-mode declaration and delegation plan/commit-only default（开发阶段默认不 push）/TDD 约束已吸收到 development 与 testing；核心调用日志/审计追溯约束已吸收到 architecture；Agent Console 全 agent 过程可见性已吸收到 product owner、decision、architecture owners 和 testing gates；USER_GATE now points to its ruling and product capability owner；SSOT section routes preflight/bootstrap/closeout/audit/doctor and keeps source-vs-install boundary；2026-07-10 ran bash tests/test-bundle-shape.sh；2026-07-11 checked every migration item；2026-07-12 confirmed no remaining change |' \
  > "$T/SSOT/STATUS.md"
out=$(bash "$LINT" "$T/SSOT" 2>&1); code=$?
assert_contains "paragraph-sized STATUS evidence cell is a deterministic failure" "$out" "[STATUS-REGISTER-CELL]"
assert_exit "paragraph-sized STATUS evidence cell exits 2" "$code" "2"
rm -rf "$T"

echo "== Q36 v2.60 EN/ZH STATUS templates remain valid register schemas =="
for lang in en zh; do
  T=$(mktemp -d -p "$TMPDIR"); mkdir -p "$T/SSOT"
  cp "$PROJECT_ROOT/skills/ssot-bootstrap/assets/templates/$lang/status.md" "$T/SSOT/STATUS.md"
  sed_inplace 's/<ssot-preflight-protocol-version>/2.60/' "$T/SSOT/STATUS.md"
  out=$(bash "$LINT" "$T/SSOT" 2>&1 || true)
  assert_not_contains "$lang STATUS template has no register-cell failure" "$out" "[STATUS-REGISTER-CELL]"
  rm -rf "$T"
done

echo "== Q37 implementation-delegator hard floors cannot be averaged away =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
sed_inplace '/^| Reader fit | RF1 |/ { s/=2/=1/g; s/ | 2 |/ | 1 |/; }' "$T/SSOT/.bootstrap/reader-review.md"
sed_inplace '/^| Reader fit | RF2 |/ { s/=1/=2/g; s/ | 1 |/ | 2 |/; }' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T"); code=$?
assert_contains "RF1 hard-floor miss fails even when total and family sum stay passing" "$out" "[READER-REVIEW-EVIDENCE]"
assert_exit "RF1 hard-floor miss exits 2" "$code" "2"
rm -rf "$T"

echo "== Q38 Q01-Q21 completeness profile IDs are exact, not sampleable =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
sed_inplace '/^| Q21 |/d' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T"); code=$?
assert_contains "missing Q21 completeness row fails review" "$out" "[READER-REVIEW-EVIDENCE]"
assert_exit "missing completeness row exits 2" "$code" "2"
rm -rf "$T"

echo "== Q39 a mandatory task over four hops cannot pass by narration =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
sed_inplace '/^| product-architecture-trace |/ s/ | 4 | / | 5 | /' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T"); code=$?
assert_contains "over-budget mandatory task fails review" "$out" "[READER-REVIEW-EVIDENCE]"
assert_exit "over-budget task exits 2" "$code" "2"
rm -rf "$T"

echo "== Q39b delegation acceptance fields cannot be left implicit =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
sed_inplace '/^| product-orientation-decision |/ s/| Ask the implementation Agent to preserve the declared product promise and boundary |/| |/' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T"); code=$?
assert_contains "missing delegated action fails structured review" "$out" "[READER-REVIEW-EVIDENCE]"
assert_exit "missing delegated action exits 2" "$code" "2"
rm -rf "$T"

echo "== Q40 a resolvable but non-ancestor review commit is stale =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
tree=$(git -C "$T" write-tree)
unrelated_commit=$(printf '%s\n' 'unrelated review snapshot' | git -C "$T" commit-tree "$tree")
sed_inplace "s/^repository_commit:.*/repository_commit: $unrelated_commit/" "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T"); code=$?
assert_contains "non-ancestor repository commit fails review freshness" "$out" "[READER-REVIEW-EVIDENCE]"
assert_exit "non-ancestor review commit exits 2" "$code" "2"
rm -rf "$T"

echo "== Q41-Q46 v2.60 Open Gaps actionability follows the exact eight-column owner =="
T=$(mktemp -d -p "$TMPDIR"); write_exact_area_status "$T"
sed_inplace '/^## Open Gaps$/,/^| | | | | | | | |$/ { /^| | | | | | | | |$/c\
| GAP-20260713-01 | gap | | Browser acceptance is not automated | `$ssot-bootstrap` | Before a release claim | `$ssot-bootstrap` | none: open |
}' "$T/SSOT/STATUS.md"
out=$(run_normal "$T"); code=$?
assert_contains "open gap missing affected task fails actionability" "$out" "[STATUS-GAP-ACTIONABILITY]"
assert_exit "open gap missing affected task exits 2" "$code" "2"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_exact_area_status "$T"
sed_inplace '/^## Open Gaps$/,/^| | | | | | | | |$/ { /^| | | | | | | | |$/c\
| GAP-20260713-01 | gap | testing release claim | Browser acceptance is not automated | DEBT-0001 | Before a release claim | `$ssot-bootstrap` | none: open |
}' "$T/SSOT/STATUS.md"
out=$(run_normal "$T"); code=$?
assert_contains "bare durable record ID is not a clickable responsible owner" "$out" "[STATUS-GAP-ACTIONABILITY]"
assert_exit "bare durable record ID exits 2" "$code" "2"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_exact_area_status "$T"
sed_inplace '/^## Open Gaps$/,/^| | | | | | | | |$/ { /^| | | | | | | | |$/c\
| GAP-20260713-01 | gap | testing release claim | Browser acceptance is not automated | `$ssot-bootstrap` | Before a release claim | DEBT-0001 | none: open |
}' "$T/SSOT/STATUS.md"
out=$(run_normal "$T"); code=$?
assert_contains "bare durable record ID is not an actionable resolving route" "$out" "[STATUS-GAP-ACTIONABILITY]"
assert_exit "bare resolving route exits 2" "$code" "2"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_exact_area_status "$T"
sed_inplace '/^## Open Gaps$/,/^| | | | | | | | |$/ { /^| | | | | | | | |$/c\
| GAP-20260713-01 | gap | testing release claim | Browser acceptance is not automated | `$ssot-bootstrap` | Before a release claim | `$ssot-bootstrap` | none: open |
}' "$T/SSOT/STATUS.md"
out=$(run_normal "$T" || true)
assert_no_fail_tag "exact eight-column skill-routed gap passes actionability" "$out" "[STATUS-GAP-ACTIONABILITY]"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_exact_area_status "$T"
out=$(run_normal "$T" || true)
assert_no_fail_tag "empty exact Open Gaps starter row remains valid" "$out" "[STATUS-GAP-ACTIONABILITY]"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_exact_area_status "$T"
sed_inplace 's/^## Open Gaps$/## 开放缺口/; s/^| ID | State | Affected scope \/ task | Question \/ missing evidence | Responsible owner | Blocking \/ retrigger condition | Resolving route | Closure \/ supersession evidence |$/| ID | 状态 | 受影响范围或任务 | 问题或缺失证据 | 责任所有者 | 阻断或复核触发条件 | 解决路由 | 闭合或取代证据 |/' "$T/SSOT/STATUS.md"
out=$(run_normal "$T" || true)
assert_no_fail_tag "Chinese exact Open Gaps header passes actionability" "$out" "[STATUS-GAP-ACTIONABILITY]"
rm -rf "$T"

echo "== Q47 v2.60 requires the exact Q01-Q21 disposition register =="
T=$(mktemp -d -p "$TMPDIR"); mkdir -p "$T/SSOT"
printf '%s\n' '| tracked_skill_version | `2.60` |' > "$T/SSOT/STATUS.md"
out=$(run_normal "$T"); code=$?
assert_contains "missing quality disposition register fails" "$out" "[QUALITY-DISPOSITION]"
assert_exit "missing quality disposition register exits 2" "$code" "2"
rm -rf "$T"

echo "== Q48 a complete cross-layer quality disposition register passes =="
T=$(mktemp -d -p "$TMPDIR"); mkdir -p "$T/SSOT"
printf '%s\n' '| tracked_skill_version | `2.60` |' > "$T/SSOT/STATUS.md"
append_quality_register "$T"
out=$(run_normal "$T" 2>&1 || true)
assert_no_fail_tag "complete Q01-Q21 register has no quality failure" "$out" "[QUALITY-DISPOSITION]"
rm -rf "$T"

echo "== Q49 an omitted exact Q item is rejected =="
T=$(mktemp -d -p "$TMPDIR"); mkdir -p "$T/SSOT"
printf '%s\n' '| tracked_skill_version | `2.60` |' > "$T/SSOT/STATUS.md"
append_quality_register "$T"
sed_inplace '/^| Q21 |/d' "$T/SSOT/STATUS.md"
out=$(run_normal "$T"); code=$?
assert_contains "missing Q21 disposition fails" "$out" "missing exact Q21 disposition"
assert_exit "missing Q21 disposition exits 2" "$code" "2"
rm -rf "$T"

echo "== Q50 applicable Q layers require resolving owner or gap routes =="
T=$(mktemp -d -p "$TMPDIR"); mkdir -p "$T/SSOT"
printf '%s\n' '| tracked_skill_version | `2.60` |' > "$T/SSOT/STATUS.md"
append_quality_register "$T"
sed_inplace '/^| Q01 |/ s#\[Quality owner\](./quality-owner.md)#missing owner#' "$T/SSOT/STATUS.md"
out=$(run_normal "$T"); code=$?
assert_contains "unrouted applicable Q layer fails" "$out" "Q01 applicable product layer"
assert_exit "unrouted applicable Q layer exits 2" "$code" "2"
rm -rf "$T"

echo "== Q51 evidenced global non-applicability is accepted =="
T=$(mktemp -d -p "$TMPDIR"); mkdir -p "$T/SSOT"
printf '%s\n' '| tracked_skill_version | `2.60` |' > "$T/SSOT/STATUS.md"
append_quality_register "$T"
sed_inplace '/^| Q01 |/c\
| Q01 | not_applicable: no end-user UI; [quality boundary](./quality-owner.md) | — | — | — | — |' "$T/SSOT/STATUS.md"
out=$(run_normal "$T" 2>&1 || true)
assert_no_fail_tag "evidenced global not_applicable has no quality failure" "$out" "[QUALITY-DISPOSITION]"
rm -rf "$T"

echo "== Q52 unsupported non-applicability is rejected =="
T=$(mktemp -d -p "$TMPDIR"); mkdir -p "$T/SSOT"
printf '%s\n' '| tracked_skill_version | `2.60` |' > "$T/SSOT/STATUS.md"
append_quality_register "$T"
sed_inplace '/^| Q01 |/c\
| Q01 | not_applicable: no end-user UI exists | — | — | — | — |' "$T/SSOT/STATUS.md"
out=$(run_normal "$T"); code=$?
assert_contains "unsupported global not_applicable fails" "$out" "named reason and resolving evidence/owner link"
assert_exit "unsupported global not_applicable exits 2" "$code" "2"
rm -rf "$T"

echo "== Q53 changing Q semantics expires both cold-review artifacts =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
sed_inplace '/^| Q21 |/ s/none: covered by the linked owner evidence/none: commercial boundary was reclassified/' "$T/SSOT/STATUS.md"
out=$(run_quality "$T"); code=$?
assert_contains "changed Q semantics fails review freshness" "$out" "quality_disposition_fingerprint does not match"
assert_exit "changed Q semantics exits 2" "$code" "2"
rm -rf "$T"

echo "== Q54 unrelated STATUS tracking baselines do not expire cold-review artifacts =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
sed_inplace 's/| documentation_language | zh-CN |/| documentation_language | zh-Hans |/' "$T/SSOT/STATUS.md"
out=$(run_quality "$T" 2>&1 || true)
assert_not_contains "unrelated STATUS edit leaves Q fingerprint fresh" "$out" "quality_disposition_fingerprint does not match"
assert_no_fail_tag "unrelated STATUS edit leaves review evidence valid" "$out" "[READER-REVIEW-EVIDENCE]"
rm -rf "$T"

echo "== Q55 review artifacts allow only the exact six H2 sections =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
printf '\n## Appendix\n\nExtra protocol section.\n' >> "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T"); code=$?
assert_contains "extra review H2 fails exact section set" "$out" "body H2 headings must be exactly the six protocol sections"
assert_exit "extra review H2 exits 2" "$code" "2"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
printf '\n## Teach-back\n\nDuplicate protocol section.\n' >> "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T"); code=$?
assert_contains "duplicate review H2 fails exact section set" "$out" "body H2 headings must be exactly the six protocol sections"
assert_exit "duplicate review H2 exits 2" "$code" "2"
rm -rf "$T"

echo "== Q56 required-change rows must agree with count and verdict =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
sed_inplace '/^| none | none |/c\
| RC-01 | pending | Rewrite the unclear current promise. | product owner | Closure review is still pending. |' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T"); code=$?
assert_contains "pending required change contradicts passing review" "$out" "unresolved rows must equal unresolved_required_changes"
assert_exit "pending required change exits 2" "$code" "2"
rm -rf "$T"

echo "== Q57 review identity binds scope and reviewed date =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
sed_inplace 's/^review_id: review:product:/review_id: review:architecture:/' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T"); code=$?
assert_contains "review ID scope mismatch fails" "$out" "review_id scope segment"
assert_exit "review ID scope mismatch exits 2" "$code" "2"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
sed_inplace 's/^reviewed_on: 2026-01-01/reviewed_on: 2026-01-02/' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T"); code=$?
assert_contains "review ID date mismatch fails" "$out" "must equal reviewed_on"
assert_exit "review ID date mismatch exits 2" "$code" "2"
rm -rf "$T"

echo "== Q58 product surface rows have one owner and class-XOR disposition =="
T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
sed_inplace '/surface:page-main/ s#\[Product brief\](./prd.md)#\[Product brief\](./prd.md) [Second owner](./prd.md)#' "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T"); code=$?
assert_contains "two product owner links fail" "$out" "product owner cell must contain exactly one Markdown owner link"
assert_exit "two product owner links exit 2" "$code" "2"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
sed_inplace '/surface:settings-na/a\
| surface:settings-real | settings | `src/ui/main.ts::mainPage` | [Product brief](./prd.md) | current | browser | evidence: `tests/e2e/main.spec.ts` |' "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T"); code=$?
assert_contains "real and not-applicable rows cannot coexist for a surface class" "$out" "real and not_applicable rows coexist"
assert_exit "surface class XOR conflict exits 2" "$code" "2"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$T"
write_v260_product_manifest "$T/SSOT/01-product/_manifest.md"
sed_inplace '/surface:result-review/ s#planned_in: \[Product brief\](./prd.md#planned_in: [Product brief](./prd.md) [Second plan](./prd.md)#' "$T/SSOT/01-product/_manifest.md"
write_v260_review "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T"); code=$?
assert_contains "planned source has exactly one owner link" "$out" "planned_in surface"
assert_exit "planned source double link exits 2" "$code" "2"
rm -rf "$T"

echo "== Q59 Area Status extensions and not-applicable rows have exact routes =="
T=$(mktemp -d -p "$TMPDIR"); write_exact_area_status "$T"
printf '# Boundary owner\n' > "$T/SSOT/boundary.md"
printf '# Second boundary\n' > "$T/SSOT/boundary-two.md"
sed_inplace '/^| glossary |/a\
| x-bad! | gap | extension: [boundary](./boundary.md) |' "$T/SSOT/STATUS.md"
out=$(run_normal "$T"); code=$?
assert_contains "invalid extension slug fails" "$out" "extensions use x-<slug>"
assert_exit "invalid extension slug exits 2" "$code" "2"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_exact_area_status "$T"
printf '# Boundary owner\n' > "$T/SSOT/boundary.md"
printf '# Second boundary\n' > "$T/SSOT/boundary-two.md"
sed_inplace '/^| glossary |/a\
| x-mobile | gap | extension: [boundary](./boundary.md) and [second](./boundary-two.md) |' "$T/SSOT/STATUS.md"
out=$(run_normal "$T"); code=$?
assert_contains "extension with two owners fails" "$out" "one resolving Markdown owner link"
assert_exit "extension double-owner exits 2" "$code" "2"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_exact_area_status "$T"
printf '# Boundary owner\n' > "$T/SSOT/boundary.md"
printf '# Second boundary\n' > "$T/SSOT/boundary-two.md"
sed_inplace 's#^| operations | gap |.*#| operations | not_applicable | No live service; [boundary](./boundary.md) and [second](./boundary-two.md) |#' "$T/SSOT/STATUS.md"
out=$(run_normal "$T"); code=$?
assert_contains "whole-area N/A with two owners fails" "$out" "exactly one resolving boundary-owner link"
assert_exit "whole-area N/A double-owner exits 2" "$code" "2"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_exact_area_status "$T"
printf '# Boundary owner\n' > "$T/SSOT/boundary.md"
sed_inplace 's#^| development | gap |.*#| development | not_applicable | No contributor workflow; [boundary](./boundary.md) |#' "$T/SSOT/STATUS.md"
out=$(run_normal "$T"); code=$?
assert_contains "development is always applicable" "$out" "not_applicable is not legal for always-applicable area development"
assert_exit "development N/A exits 2" "$code" "2"
rm -rf "$T"

echo "== Q60 global body hygiene reaches records and fenced placeholders =="
T=$(mktemp -d -p "$TMPDIR"); write_exact_area_status "$T"
mkdir -p "$T/SSOT/04-records/decisions"
printf '# Decision index\n\nThis reader page follows ssot-bootstrap authoring rules.\n' > "$T/SSOT/04-records/decisions/README.md"
out=$(run_normal "$T"); code=$?
assert_contains "record prose participates in META-LEAKAGE" "$out" "[META-LEAKAGE]"
assert_exit "record meta leakage exits 2" "$code" "2"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_exact_area_status "$T"
mkdir -p "$T/SSOT/03-process/testing"
sed_inplace 's#^| testing | gap |.*#| testing | covered | [testing](./03-process/testing/README.md) |#' "$T/SSOT/STATUS.md"
printf '%s\n' '# Root route' '' 'This root explains where a reader starts and how a current change reaches the fitting process owner in ordinary language.' '' 'It also names the visible result, evidence direction, failure boundary, and the next reader action before any reference table.' > "$T/SSOT/README.md"
mkdir -p "$T/SSOT/03-process"
printf '%s\n' '# Process route' '' 'This process route explains which workflow owns a change and what result the reader should expect before choosing a command.' '' 'It also explains the verification handoff, important failure boundary, and recovery direction in ordinary language for a newcomer.' > "$T/SSOT/03-process/README.md"
printf '%s\n' '# Testing' '' 'This testing owner explains which correctness decision the reader must make and what visible result proves the delegated change.' '' 'It also explains a failure, the safe recovery route, the evidence limitation, and when the reader must stop or escalate.' '' '```sh' 'run <command-or-test>' '```' > "$T/SSOT/03-process/testing/README.md"
out=$(run_normal "$T"); code=$?
assert_contains "placeholder inside fenced code fails covered-body hygiene" "$out" "protocol placeholder remains in prose or code"
assert_exit "fenced placeholder exits 2" "$code" "2"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_exact_area_status "$T"
mkdir -p "$T/SSOT/03-process/testing"
sed_inplace 's#^| testing | gap |.*#| testing | covered | [testing](./03-process/testing/README.md) |#' "$T/SSOT/STATUS.md"
printf '%s\n' '# Root route' '' 'This root explains where a reader starts and how a current change reaches the fitting process owner in ordinary language.' '' 'It also names the visible result, evidence direction, failure boundary, and the next reader action before any reference table.' > "$T/SSOT/README.md"
mkdir -p "$T/SSOT/03-process"
printf '%s\n' '# Process route' '' 'This process route explains which workflow owns a change and what result the reader should expect before choosing a command.' '' 'It also explains the verification handoff, important failure boundary, and recovery direction in ordinary language for a newcomer.' > "$T/SSOT/03-process/README.md"
printf '%s\n' '# Testing' '' 'This testing owner explains which correctness decision the reader must make and what visible result proves the delegated change.' '' 'It also explains a failure, the safe recovery route, the evidence limitation, and when the reader must stop or escalate.' '' '```c' 'if (value < limit) { return value; }' '```' > "$T/SSOT/03-process/testing/README.md"
out=$(run_normal "$T" 2>&1 || true)
assert_no_fail_tag "real comparison syntax is not a placeholder" "$out" "[COVERED-PLACEHOLDER]"
rm -rf "$T"

echo "== Q61 covered children require root, process, and records routers =="
T=$(mktemp -d -p "$TMPDIR"); write_exact_area_status "$T"
mkdir -p "$T/SSOT/03-process/testing"
sed_inplace 's#^| testing | gap |.*#| testing | covered | [testing](./03-process/testing/README.md) |#' "$T/SSOT/STATUS.md"
printf '%s\n' '# Testing' '' 'This testing owner explains the correctness decision, delegated check, and visible result in ordinary language for a new reader.' '' 'It also explains failure detection, recovery, evidence limits, and the next action before any command reference.' > "$T/SSOT/03-process/testing/README.md"
out=$(run_normal "$T"); code=$?
assert_contains "covered child requires root router" "$out" "a covered area requires the root reader router"
assert_contains "covered process child requires process router" "$out" "a covered process child requires the process reader router"
assert_exit "missing root and process routers exit 2" "$code" "2"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_exact_area_status "$T"
mkdir -p "$T/SSOT/04-records/decisions"
sed_inplace 's#^| decisions | gap |.*#| decisions | covered | [decisions](./04-records/decisions/README.md) |#' "$T/SSOT/STATUS.md"
printf '%s\n' '# Decisions' '' 'This decision index explains which long-lived choices belong here and how a reader reaches the unique entry owner.' '' 'It also explains validation, supersession, evidence limits, and when a new decision or review is required.' > "$T/SSOT/04-records/decisions/README.md"
out=$(run_normal "$T"); code=$?
assert_contains "covered record child requires records router" "$out" "a covered record child requires the records reader router"
assert_exit "missing root and records routers exit 2" "$code" "2"
rm -rf "$T"

echo "== Q62 covered bodies reject author comments and glossary tokens =="
T=$(mktemp -d -p "$TMPDIR"); write_exact_area_status "$T"
mkdir -p "$T/SSOT/glossary"
sed_inplace 's#^| glossary | gap |.*#| glossary | covered | [glossary](./glossary/README.md) |#' "$T/SSOT/STATUS.md"
printf '%s\n' '# Root route' '' 'This root explains the repository outcome and routes the reader to the one owner that answers the current question.' '' 'It also explains the evidence direction, important boundary, failure posture, and the next action in ordinary language.' > "$T/SSOT/README.md"
printf '%s\n' '# Glossary' '' 'This glossary explains repository-specific words that change a reader decision and routes every definition to one fact owner.' '' 'It also gives examples, nearby confusion, evidence, lifecycle, and the condition that requires another review.' '' '<!-- Remove this author note after filling the page. -->' '' 'The remaining <term> must be replaced.' > "$T/SSOT/glossary/README.md"
out=$(run_normal "$T"); code=$?
assert_contains "covered author comment fails" "$out" "authoring HTML comment remains in covered body"
assert_exit "covered author comment exits 2" "$code" "2"
rm -rf "$T"

echo "== Q63 global Q non-applicability uses exact em dashes =="
T=$(mktemp -d -p "$TMPDIR"); write_exact_area_status "$T"
printf '# Boundary\n' > "$T/SSOT/boundary.md"
sed_inplace '/^| Q01 |/c\
| Q01 | not_applicable: no interactive surface; [boundary](./boundary.md) | - | — | — | — |' "$T/SSOT/STATUS.md"
out=$(run_normal "$T"); code=$?
assert_contains "ASCII dash cannot replace global N/A em dash" "$out" "global not_applicable row must use exact em dash"
assert_exit "wrong global N/A dash exits 2" "$code" "2"
rm -rf "$T"

echo "== Q64 architecture covered is a manifest-and-review aggregate =="
T=$(mktemp -d -p "$TMPDIR"); write_exact_area_status "$T"
mkdir -p "$T/SSOT/02-architecture"
sed_inplace 's#^| architecture | gap |.*#| architecture | covered | [architecture](./02-architecture/README.md) |#' "$T/SSOT/STATUS.md"
printf '%s\n' '# Architecture' '' 'This architecture root explains the current request-to-result path and the system owner that carries the visible outcome.' '' 'It also explains the main state boundary, failure recovery, evidence limit, and the next architecture reading route.' > "$T/SSOT/02-architecture/README.md"
out=$(run_normal "$T"); code=$?
assert_contains "architecture aggregate requires views/domains/manifests/review" "$out" "architecture covered aggregate is incoherent"
assert_exit "incomplete architecture aggregate exits 2" "$code" "2"
rm -rf "$T"

echo "== Q65 exact all-gap Area Status schema is structurally valid =="
T=$(mktemp -d -p "$TMPDIR"); write_exact_area_status "$T"
out=$(run_normal "$T" 2>&1 || true)
assert_no_fail_tag "exact 17-row all-gap Area Status has no area-schema failure" "$out" "[AREA-STATUS]"
rm -rf "$T"

echo "== Q66 lightweight scope review binds plain answers, every target, and child Area freshness =="
BASE=$(mktemp -d -p "$TMPDIR"); write_process_scope_fixture "$BASE"
out=$(run_quality "$BASE" || true)
assert_contains "complete lightweight process artifact passes its exact gate" "$out" "v2.60 covered/converged lightweight exact profiles have current linked artifacts"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^| process-root |/d' "$T/SSOT/.bootstrap/scope-review-process.md"
out=$(run_quality "$T" || true)
assert_contains "empty target matrix cannot authorise a lightweight review" "$out" "target coverage must contain every real target exactly once"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^| C02 |/ { s/The current process owner gives a concrete reader decision and safe handoff for this workflow\./See link./; }' "$T/SSOT/.bootstrap/scope-review-process.md"
out=$(run_quality "$T" || true)
assert_contains "profile row needs a concrete plain-language conclusion" "$out" "exact profile must contain each required ID once"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^area_disposition_fingerprint:/d' "$T/SSOT/.bootstrap/scope-review-process.md"
out=$(run_quality "$T" || true)
assert_contains "lightweight artifact uses the exact 18-key schema" "$out" "exact 18-key scalar schema"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace 's#^| development | gap |.*#| development | covered | `$ssot-bootstrap` |#' "$T/SSOT/STATUS.md"
out=$(run_quality "$T" || true)
assert_contains "child Area change expires the parent lightweight review" "$out" "area_disposition_fingerprint does not match current dependent Area Status rows"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
mkdir -p "$T/SSOT/03-process/development"
printf '%s\n' '# Development owner' '' 'This actual child explains the delegated development path and the visible result.' > "$T/SSOT/03-process/development/README.md"
new_scope_hash=$(scope_fingerprint "$T/SSOT" process)
sed_inplace "s/^scope_fingerprint:.*/scope_fingerprint: $new_scope_hash/" "$T/SSOT/.bootstrap/scope-review-process.md"
out=$(run_quality "$T" || true)
assert_contains "new actual child README must appear in the target matrix" "$out" "target coverage must contain every real target exactly once"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
mv "$T/SSOT/.bootstrap/scope-review-process.md" "$T/SSOT/.bootstrap/real-scope-review.md"
ln -s real-scope-review.md "$T/SSOT/.bootstrap/scope-review-process.md"
out=$(run_quality "$T" || true)
assert_contains "scope artifact symlink cannot authorise coverage" "$out" "regular non-symlink Markdown artifact link"
rm -rf "$T" "$BASE"

echo "== Q66b glossary exact-scope coverage includes every applicable term owner =="
BASE=$(mktemp -d -p "$TMPDIR"); write_glossary_scope_fixture "$BASE"
out=$(run_quality "$BASE" || true)
assert_contains "complete glossary root and term target matrix passes" "$out" "v2.60 covered/converged lightweight exact profiles have current linked artifacts"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^| glossary-ready |/d' "$T/SSOT/.bootstrap/scope-review-glossary.md"
out=$(run_quality "$T" || true)
assert_contains "omitted applicable glossary term owner is rejected" "$out" "target coverage must contain every real target exactly once"
rm -rf "$T" "$BASE"

echo "== Q67 record indexes validate child coverage, recursion, IDs, aliases, and visible truth =="
T=$(mktemp -d -p "$TMPDIR"); write_records_index_fixture "$T"
sed_inplace 's#^| records | covered |.*#| records | gap | `$ssot-bootstrap` |#; s#^| decisions | gap |.*#| decisions | covered | [decisions owner](./04-records/decisions/README.md) |#' "$T/SSOT/STATUS.md"
out=$(run_quality "$T" || true)
assert_contains "covered decisions are validated while records aggregate is gap" "$out" "covered record collections have unique dual-axis entries and exact mirrored indexes"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_records_index_fixture "$T"
sed_inplace 's/^status: accepted$/status:/' "$T/SSOT/04-records/decisions/0001-choice.md"
out=$(run_quality "$T" || true)
assert_contains "present empty compatibility alias is rejected" "$out" "compatibility status must be non-empty and mirror record"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_records_index_fixture "$T"
sed_inplace 's/^promotion_state: promoted$/promotion_state:/' "$T/SSOT/04-records/research/0001-study.md"
out=$(run_quality "$T" || true)
assert_contains "present empty research alias is rejected" "$out" "promotion_state must be non-empty and mirror adoption_state"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_records_index_fixture "$T"
mkdir -p "$T/SSOT/04-records/decisions/domain"
mv "$T/SSOT/04-records/decisions/0001-choice.md" "$T/SSOT/04-records/decisions/domain/0001-choice.md"
sed_inplace 's#(./0001-choice.md)#(./domain/0001-choice.md)#' "$T/SSOT/04-records/decisions/README.md"
out=$(run_quality "$T" || true)
assert_contains "nested leaf entry remains covered by the root index" "$out" "covered record collections have unique dual-axis entries and exact mirrored indexes"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_records_index_fixture "$T"
mkdir -p "$T/SSOT/04-records/decisions/domain"
cp "$T/SSOT/04-records/decisions/0001-choice.md" "$T/SSOT/04-records/decisions/domain/0001-copy.md"
out=$(run_quality "$T" || true)
assert_contains "recursive duplicate entry ID is rejected" "$out" "entry ID is duplicated: DEC-0001"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_records_index_fixture "$T"
mv "$T/SSOT/04-records/decisions/0001-choice.md" "$T/SSOT/04-records/decisions/0002-choice.md"
sed_inplace 's#0001-choice.md#0002-choice.md#' "$T/SSOT/04-records/decisions/README.md"
out=$(run_quality "$T" || true)
assert_contains "entry ID digits must match its filename" "$out" "must use matching NNNN-slug.md filename"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_records_index_fixture "$T"
sed_inplace 's/DEC-0001/DEC-00001/g; s#0001-choice.md#00001-choice.md#' "$T/SSOT/04-records/decisions/README.md" "$T/SSOT/04-records/decisions/0001-choice.md"
mv "$T/SSOT/04-records/decisions/0001-choice.md" "$T/SSOT/04-records/decisions/00001-choice.md"
out=$(run_quality "$T" || true)
assert_contains "five-digit record ID is outside the NNNN contract" "$out" "expected DEC-NNNN"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_records_index_fixture "$T"
sed_inplace 's/^## GOT-0001$/## GOT-0001 Trap/' "$T/SSOT/04-records/gotchas/topic.md"
sed_inplace 's/#got-0001)/#got-0001-trap)/' "$T/SSOT/04-records/gotchas/README.md"
out=$(run_quality "$T" || true)
assert_contains "gotcha aggregate H2 must remain the ID-only stable anchor" "$out" "aggregate H2 must be the exact stable ID only"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_records_index_fixture "$T"
printf '%s\n' '# Orphan topic' '' 'This unindexed topic has no stable gotcha block.' > "$T/SSOT/04-records/gotchas/orphan.md"
out=$(run_quality "$T" || true)
assert_contains "gotcha topic without frontmatter ID or exact block is rejected" "$out" "needs frontmatter id or at least one exact ## GOT-NNNN block"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_records_index_fixture "$T"
sed_inplace '/Record status \/ hazard state/d' "$T/SSOT/04-records/gotchas/topic.md"
out=$(run_quality "$T" || true)
assert_contains "gotcha block cannot omit its two canonical states" "$out" "needs one explicit valid Record status / hazard state line"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_records_index_fixture "$T"
sed_inplace 's/#got-0001)/#missing-anchor)/' "$T/SSOT/04-records/gotchas/README.md"
out=$(run_quality "$T" || true)
assert_contains "gotcha index anchor must resolve exactly" "$out" "needs one resolving owner/anchor link"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_records_index_fixture "$T"
printf '%s\n' '# Decisions' '' '## Decision Index' '' '```markdown' '| ID | Title | Record status | Implementation state | Date | Entry owner |' '|---|---|---|---|---|---|' '| DEC-0001 | Choice | accepted | implemented | 2026-07-13 | [entry](./0001-choice.md) |' '```' > "$T/SSOT/04-records/decisions/README.md"
out=$(run_quality "$T" || true)
assert_contains "fenced example table cannot fake the visible root index" "$out" "exact table under its unique Decision Index"
rm -rf "$T"

echo "== Q68 empty record collections are visible, localised, owner-routed, and mutually exclusive =="
T=$(mktemp -d -p "$TMPDIR"); write_empty_records_index_fixture "$T"
out=$(run_quality "$T" || true)
assert_contains "five legitimately empty collections pass their exact indexes" "$out" "covered record collections have unique dual-axis entries and exact mirrored indexes"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_empty_records_index_fixture "$T"
sed_inplace 's#owner=\[records owner\](../README.md)#owner=[missing owner](./missing.md)#' "$T/SSOT/04-records/decisions/README.md"
out=$(run_quality "$T" || true)
assert_contains "empty collection owner must resolve" "$out" "empty index needs one reason/owner/review_trigger disposition"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_empty_records_index_fixture "$T"
sed_inplace 's#^Empty collection: reason=no durable decision has been accepted; owner=\[records owner\](../README.md); review when=a hard-to-reverse choice appears\.$#`Empty collection: reason=no durable decision has been accepted; owner=[records owner](../README.md); review when=a hard-to-reverse choice appears.`#' "$T/SSOT/04-records/decisions/README.md"
out=$(run_quality "$T" || true)
assert_contains "inline-code template text is not a visible empty disposition" "$out" "empty index needs one reason/owner/review_trigger disposition"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_empty_records_index_fixture "$T"
sed_inplace 's#^Empty collection: reason=no durable decision has been accepted; owner=\[records owner\](../README.md); review when=a hard-to-reverse choice appears\.$#空集合说明：原因=尚未出现需要长期保留的不可逆决策；负责人=[记录所有者](../README.md)；复核条件=出现跨域且难以回退的选择。#' "$T/SSOT/04-records/decisions/README.md"
out=$(run_quality "$T" || true)
assert_contains "localised Chinese empty disposition passes" "$out" "covered record collections have unique dual-axis entries and exact mirrored indexes"
rm -rf "$T"

echo "== Q69 open bug is canonical active work for indexes, risk, actionability, and deferral =="
T=$(mktemp -d -p "$TMPDIR"); write_records_index_fixture "$T"
sed_inplace 's/| BUG-0001 | Failure | current | fixed |/| BUG-0001 | Failure | current | open |/' "$T/SSOT/04-records/bugs/README.md"
sed_inplace 's/^failure_state: fixed$/failure_state: open/; s/^status: fixed$/status: open/' "$T/SSOT/04-records/bugs/0001-failure.md"
out=$(run_normal "$T" || true)
assert_contains "open bug passes the canonical dual-axis index" "$out" "covered record collections have unique dual-axis entries and exact mirrored indexes"
assert_contains "open major bug requires a quick-entry surface" "$out" "[ENTRY-ACTIONABILITY]"
printf '%s\n' '' 'We will investigate this later when capacity becomes available.' >> "$T/SSOT/04-records/bugs/0001-failure.md"
out=$(run_normal "$T" || true)
assert_contains "open bug future-work wording cannot bypass deferral ownership" "$out" "[SILENT-DEFERRAL]"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); write_records_index_fixture "$T"
sed_inplace 's/| BUG-0001 | Failure | current | fixed |/| BUG-0001 | Failure | current | pending |/' "$T/SSOT/04-records/bugs/README.md"
sed_inplace 's/^failure_state: fixed$/failure_state: pending/; s/^status: fixed$/status: pending/' "$T/SSOT/04-records/bugs/0001-failure.md"
out=$(run_quality "$T" || true)
assert_contains "illegal bug failure state is rejected" "$out" "invalid failure_state pending"
rm -rf "$T"

echo "== Q70 full reader review frontmatter is a closed exact 29-key schema =="
BASE=$(mktemp -d -p "$TMPDIR"); make_v260_product_root "$BASE"
write_v260_product_manifest "$BASE/SSOT/01-product/_manifest.md"
write_v260_review "$BASE/SSOT/.bootstrap/reader-review.md"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^reviewer:/d' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "missing full-review reviewer key is rejected" "$out" "frontmatter must be one closed exact 29-key scalar schema"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^authorises:/d' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "missing full-review authorises key is rejected" "$out" "frontmatter must be one closed exact 29-key scalar schema"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^reviewer:/a\
unexpected_field: forbidden' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "extra full-review frontmatter key is rejected" "$out" "frontmatter must be one closed exact 29-key scalar schema"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^reviewer:/a\
reviewer: agent:duplicate' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "duplicate full-review frontmatter key is rejected" "$out" "frontmatter must be one closed exact 29-key scalar schema"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace 's/^reviewer: agent:test$/reviewer: reviewer/' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "placeholder reviewer ID is rejected" "$out" "reviewer must be a stable non-placeholder ID"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace 's/^authorises: area:product:covered$/authorises: area:architecture:covered/' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "cross-scope authorises value is rejected" "$out" "authorises must be area:product:covered"
rm -rf "$T"

echo "== Q71 full reader review reconciles every frozen target and mandatory task =="
T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^| surface:page-main |/d' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "omitted full-review target row is rejected" "$out" "target coverage must contain every real target exactly once"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^| product-surface |/ s/| [0-9][0-9]* | [0-9][0-9]* | pass |$/| 999 | 999 | pass |/' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "tampered frozen-population count is rejected" "$out" "frozen population reconciliation count does not match the real inventory"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^| product-surface |/ s#\[product inventory\](../01-product/_manifest.md)#[wrong inventory](../01-product/README.md)#' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "frozen population must link its real source inventory" "$out" "frozen population product-surface must link its real source inventory"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^| surface:page-main |/ s/| product-surface-inventory |/| architecture-owner-state-contract |/' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "cross-scope assigned task is rejected" "$out" "assigned mandatory task is outside the product review scope"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^| surface:page-main |/ s/| product-surface |/| reader-owner |/' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "target kind must match its frozen population" "$out" "target coverage has invalid Target kind"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace 's/^| surface:page-main |/| product-surface:surface:page-main |/' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "target ID must use the canonical inventory ID" "$out" "invalid or duplicate stable Target ID product-surface:surface:page-main"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^| surface:page-main |/p' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "duplicate canonical target ID is rejected" "$out" "invalid or duplicate stable Target ID surface:page-main"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^| surface:page-main |/ s/| current |/| target |/' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "target disposition must match its inventory row" "$out" "frozen disposition does not match the real inventory"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^| surface:page-main |/ s#\[product owner\](../01-product/prd.md)#[product owner](../01-product/product-model.md)#' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "target owner must match its inventory row" "$out" "owner/body does not match its real inventory owner"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^| surface:page-main |/ s/| pass |/| unexpected | pass |/' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "target rows reject extra columns" "$out" "target coverage rows need the exact eight columns"
rm -rf "$T"

echo "== Q72 full reader review closure row matches its artifact and STATUS row =="
T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^| \[Stop Review Gate\]/d' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "missing covered-claim closure row is rejected" "$out" "STATUS covered-claim closure must contain exactly one current row"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^| \[Stop Review Gate\]/ s/| agent:test | independent-cold-reader |/| agent:other | independent-cold-reader |/' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "tampered covered-claim closure row is rejected" "$out" "STATUS covered-claim closure disagrees with the review artifact or Stop Review Gate"
rm -rf "$T"

echo "== Q73 independent cold-reader is valid in the exact STATUS schema =="
out=$(run_normal "$BASE" || true)
assert_not_contains "full-review cold-reader role passes STATUS exact role validation" "$out" "[STATUS-EXACT-SCHEMA] stop-review 'product' has invalid claim/role/result"
assert_not_contains "canonical product full review passes reader-review validation" "$out" "[READER-REVIEW-EVIDENCE]"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^| product | covered | agent:test |/ s/| product | covered |/| process | covered |/; /^| process | covered | agent:test |/ s/| area:product:covered |$/| area:process:covered |/' "$T/SSOT/STATUS.md"
out=$(run_normal "$T" || true)
assert_contains "cold-reader role is confined to product and architecture full-review rows" "$out" "independent-cold-reader is only valid for product/architecture covered full-review rows"
rm -rf "$T"

echo "== Q74 full-review evidence and completeness rows require bounded Markdown links =="
T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^| product-orientation-decision | Consequential current claim |/ s#\[current owner\](../01-product/README.md)#SSOT/01-product/README.md#' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "bare per-task evidence path is rejected" "$out" "evidence sample must use one resolving non-review consumer-SSOT Markdown link"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^| C01 | covered |/ s#\[current owner\](../01-product/README.md)#SSOT/01-product/README.md#' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "bare completeness evidence path is rejected" "$out" "completeness profile must use one resolving non-review consumer-SSOT Markdown evidence link"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR"); cp -a "$BASE/." "$T/"
sed_inplace '/^| C01 | covered |/ s#\[current owner\](../01-product/README.md)#[review artifact](./reader-review.md)#' "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_quality "$T" || true)
assert_contains "self-referential completeness evidence is rejected" "$out" "completeness profile must use one resolving non-review consumer-SSOT Markdown evidence link"
rm -rf "$T"

rm -rf "$BASE"

echo "== V62a ledger consistency: file stamp must not outrun the STATUS area row =="
T=$(mktemp -d -p "$TMPDIR")
write_exact_area_status "$T"
mkdir -p "$T/SSOT/01-product"
printf -- '---\nintent_recovery: covered\n---\n# Product\n' > "$T/SSOT/01-product/README.md"
out=$(run_normal "$T" || true)
assert_has_fail_tag "covered stamp under gap area fails ledger consistency" "$out" "[LEDGER-CONSISTENCY]"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR")
write_exact_area_status "$T"
mkdir -p "$T/SSOT/01-product"
printf -- '---\nintent_recovery: gap\n---\n# Product\n' > "$T/SSOT/01-product/README.md"
out=$(run_normal "$T" || true)
assert_no_fail_tag "gap stamp under gap area has no ledger failure" "$out" "[LEDGER-CONSISTENCY]"
rm -rf "$T"

echo "== V62b an open gap blocking the converged claim forbids coverage_result=converged =="
T=$(mktemp -d -p "$TMPDIR")
write_exact_area_status "$T"
sed_inplace 's/| coverage_result | in_progress |/| coverage_result | converged |/' "$T/SSOT/STATUS.md"
sed_inplace '/^## Open Gaps/,${s#^| | | | | | | | |$#| GAP-20260919-01 | gap | release | evidence absent | [owner](./03-process/README.md) | blocks converged | [route](./03-process/README.md) | pending |#}' "$T/SSOT/STATUS.md"
out=$(run_normal "$T" || true)
assert_has_fail_tag "registered converged blocker forbids the converged claim" "$out" "[GAP-BLOCK]"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR")
write_exact_area_status "$T"
sed_inplace '/^## Open Gaps/,${s#^| | | | | | | | |$#| GAP-20260919-01 | gap | release | evidence absent | [owner](./03-process/README.md) | blocks converged | [route](./03-process/README.md) | pending |#}' "$T/SSOT/STATUS.md"
out=$(run_normal "$T" || true)
assert_no_fail_tag "registered blocker with in_progress coverage has no GAP-BLOCK failure" "$out" "[GAP-BLOCK]"
rm -rf "$T"

echo "== V62c legacy lean Open Gaps schema warns once instead of failing per row =="
T=$(mktemp -d -p "$TMPDIR")
mkdir -p "$T/SSOT"
printf '%s\n' \
  '| tracked_skill_version | `2.60` |' '| documentation_language | zh-CN |' '| coverage_result | in_progress |' '' \
  '## Open Gaps' '' \
  '| 编号 | 状态 | 影响范围 | 说明 | 路由 |' '|---|---|---|---|---|' \
  '| legacy-gap | gap | release | 缺验收证据 | [路由](./03-process/README.md) |' \
  '| legacy-gap-2 | gap | testing | 缺少回归 | [路由](./03-process/README.md) |' \
  > "$T/SSOT/STATUS.md"
out=$(run_normal "$T" || true)
assert_has_warn_tag "lean Open Gaps schema produces one migration warning" "$out" "[STATUS-GAP-ACTIONABILITY]"
assert_no_fail_tag "lean Open Gaps schema has no per-row actionability failures" "$out" "[STATUS-GAP-ACTIONABILITY]"
rm -rf "$T"

echo "== V62d open-gap actionability reads the canonical columns (regression: route lives in column 8) =="
T=$(mktemp -d -p "$TMPDIR")
write_exact_area_status "$T"
sed_inplace '/^## Open Gaps/,${s#^| | | | | | | | |$#| GAP-20260919-02 | gap | release | evidence absent | [owner](./03-process/README.md) | retrigger on ship | not-a-link | pending |#}' "$T/SSOT/STATUS.md"
out=$(run_normal "$T" || true)
assert_contains "non-resolving Resolving route cell is rejected" "$out" "Resolving route must be one resolvable Markdown link"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR")
write_exact_area_status "$T"
sed_inplace '/^## Open Gaps/,${s#^| | | | | | | | |$#| GAP-20260919-03 | gap | release | evidence absent | plain text owner | retrigger on ship | [route](./03-process/README.md) | pending |#}' "$T/SSOT/STATUS.md"
out=$(run_normal "$T" || true)
assert_contains "non-link Responsible owner cell is rejected" "$out" "Responsible owner must be one resolvable Markdown owner link"
rm -rf "$T"

echo "== V62e ephemeral evidence paths are flagged =="
T=$(mktemp -d -p "$TMPDIR")
write_exact_area_status "$T"
mkdir -p "$T/SSOT/.bootstrap"
printf '# Review\n\nEvidence: `/tmp/scope-review-2026.md`\n' > "$T/SSOT/.bootstrap/reader-review.md"
out=$(run_normal "$T" || true)
assert_has_warn_tag "/tmp evidence path is flagged as ephemeral" "$out" "[EPHEMERAL-EVIDENCE]"
rm -rf "$T"

echo "== V62f live baselines need a Stop Review Gate row naming them =="
T=$(mktemp -d -p "$TMPDIR")
write_exact_area_status "$T"
sed_inplace '/^## Stop Review Gate/,/^## Open Adjudications/{s#^| | | | | | | | | |$#| baseline | tracked_commit | agent:test | scoped-self-review | 2026-01-01 | no-more-required-changes | [evidence](./.bootstrap/scope-review-process.md) | none | baseline:tracked_commit |#}' "$T/SSOT/STATUS.md"
out=$(run_normal "$T" || true)
assert_has_warn_tag "unreviewed tracked_session and tracked_skill_version baselines warn" "$out" "[BASELINE-REVIEW]"
assert_not_contains "reviewed tracked_commit baseline does not warn" "$(printf '%s' "$out" | grep 'BASELINE-REVIEW' || true)" "tracked_commit has a live baseline"
rm -rf "$T"

echo "== V62g inline-code table cells are content, not placeholders =="
T=$(mktemp -d -p "$TMPDIR")
write_exact_area_status "$T"
mkdir -p "$T/SSOT/01-product"
printf -- '---\nintent_recovery: gap\n---\n# Product\n\n| Tool | Command |\n|---|---|\n| Pencil CLI | `pencil inspect` |\n' > "$T/SSOT/01-product/README.md"
out=$(run_normal "$T" || true)
assert_no_fail_tag "code-only table cell is not a covered placeholder" "$out" "[COVERED-PLACEHOLDER]"
rm -rf "$T"

echo "== V62h repo path references must resolve unless marked retired =="
T=$(mktemp -d -p "$TMPDIR")
write_exact_area_status "$T"
mkdir -p "$T/SSOT/02-architecture"
printf -- '---\nintent_recovery: gap\n---\n# Architecture\n\nThe dispatcher lives at `engine/mission_executor.py`.\nRetired path: `historical: engine/old_dfs.py`\n' > "$T/SSOT/02-architecture/README.md"
out=$(run_normal "$T" || true)
assert_has_warn_tag "missing source path warns" "$out" "[REF-RESOLVE]"
assert_not_contains "retired marker exempts the historical path" "$(printf '%s' "$out" | grep 'REF-RESOLVE' || true)" "old_dfs.py"
rm -rf "$T"

echo "== V62i superseded records name their successor =="
T=$(mktemp -d -p "$TMPDIR")
write_exact_area_status "$T"
mkdir -p "$T/SSOT/04-records/decisions"
printf -- '---\nrecord_status: superseded\n---\n# Old decision\n' > "$T/SSOT/04-records/decisions/0001-old.md"
out=$(run_normal "$T" || true)
assert_has_warn_tag "superseded record without successor warns" "$out" "[SUPERSEDE-LINK]"
rm -rf "$T"

T=$(mktemp -d -p "$TMPDIR")
write_exact_area_status "$T"
mkdir -p "$T/SSOT/04-records/decisions"
printf -- '---\nrecord_status: superseded\nsuperseded_by: 0002-new.md\n---\n# Old decision\n' > "$T/SSOT/04-records/decisions/0001-old.md"
out=$(run_normal "$T" || true)
assert_no_warn_tag "superseded record with superseded_by does not warn" "$out" "[SUPERSEDE-LINK]"
rm -rf "$T"

echo "== V62j tracked_skill_version must not outrun installed artifacts =="
T=$(mktemp -d -p "$TMPDIR")
write_exact_area_status "$T"
sed_inplace 's/| tracked_skill_version | `2.60` |/| tracked_skill_version | `9.99` |/' "$T/SSOT/STATUS.md"
mkdir -p "$T/.agents/skills/ssot-preflight"
printf -- '---\nmetadata:\n  protocol_version: "2.60"\n---\n# preflight\n' > "$T/.agents/skills/ssot-preflight/SKILL.md"
out=$(run_normal "$T" || true)
assert_has_fail_tag "tracked version outrunning installed artifact fails" "$out" "[SKILL-VERSION-BINDING]"
rm -rf "$T"

echo "== V62k failure digest groups large failure sets by check =="
T=$(mktemp -d -p "$TMPDIR")
write_exact_area_status "$T"
mkdir -p "$T/SSOT/01-product" "$T/SSOT/02-architecture" "$T/SSOT/03-process"
for area in 01-product 02-architecture 03-process; do
  for n in 1 2 3 4 5; do
    printf -- '---\nintent_recovery: covered\n---\n# f\n' > "$T/SSOT/$area/f$n.md"
  done
done
out=$(run_normal "$T" || true)
assert_contains "large failure sets render the per-check digest" "$out" "[DIGEST] failures by check"
rm -rf "$T"

echo
echo "=== RESULT: pass=$PASS fail=$FAIL ==="
[[ "$FAIL" -eq 0 ]]
