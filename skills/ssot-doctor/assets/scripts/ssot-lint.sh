#!/usr/bin/env bash
# ssot-lint.sh — deterministic consistency checks for a project's SSOT/.
#
# Purpose: move the mechanically-decidable Doctor L1 items from agent
#          discipline into a script, removing high-frequency low-signal
#          manual review burden.
#
# Applies to: project repos that contain an SSOT/ directory.
# Does NOT apply to: the protocol repo itself (e.g. SSOT-SKILL).
#
# Usage:
#   ./ssot-lint.sh [SSOT_DIR]        # default SSOT_DIR = ./SSOT
#   ./ssot-lint.sh --json            # structured JSON output (CI-friendly)
#   ./ssot-lint.sh --strict          # treat WARN as FAIL (CI gate mode)
#   ./ssot-lint.sh --check-meta-leakage [DIR ...]
#                                    # only run the v2.48 [META-LEAKAGE] (15I) grep;
#                                    # DIRs default to <SSOT>/product and <SSOT>/architecture.
#
# Exit codes:
#   0  PASS (no FAIL, no WARN)
#   1  WARN (no FAIL, has WARN; treated as FAIL under --strict)
#   2  FAIL (has FAIL)
#   3  script error (bad args, SSOT_DIR missing, etc.)
#
# Design principles:
#   - Deterministic checks only (grep / path existence / git ancestry); no
#     semantic judgement.
#   - No external LLM or network calls.
#   - Never mutates files; only emits diagnostics.
#   - Failure messages must give a concrete path (and line if applicable)
#     so an agent or a human can locate the problem fast.

set -euo pipefail

# ---------- arg parsing ----------
SSOT_DIR="${1:-SSOT}"
OUTPUT_FORMAT="text"
STRICT_MODE=0
META_LEAKAGE_ONLY=0
declare -a META_LEAKAGE_DIRS=()

for arg in "$@"; do
  case "$arg" in
    --json) OUTPUT_FORMAT="json" ;;
    --strict) STRICT_MODE=1 ;;
    --check-meta-leakage) META_LEAKAGE_ONLY=1 ;;
    --help|-h)
      sed -n '2,28p' "$0"
      exit 0
      ;;
  esac
done

# First non-flag arg, if a directory, overrides SSOT_DIR.
for arg in "$@"; do
  if [[ "$arg" != --* && -d "$arg" ]]; then
    SSOT_DIR="$arg"
    break
  fi
done

# Under --check-meta-leakage, collect every non-flag dir argument as a target
# scope. If none are given we fall back to <SSOT_DIR>/product and
# <SSOT_DIR>/architecture (the v2.48 default product/architecture scope).
if [[ "$META_LEAKAGE_ONLY" -eq 1 ]]; then
  for arg in "$@"; do
    if [[ "$arg" != --* && -d "$arg" ]]; then
      META_LEAKAGE_DIRS+=("$arg")
    fi
  done
fi

if [[ ! -d "$SSOT_DIR" ]]; then
  echo "ERROR: SSOT directory not found: $SSOT_DIR" >&2
  exit 3
fi

# ---------- diagnostic collection ----------
declare -a FAILS=()
declare -a WARNS=()
declare -a PASSES=()

add_fail() { FAILS+=("$1"); }
add_warn() { WARNS+=("$1"); }
add_pass() { PASSES+=("$1"); }

# Content hash (first 12 chars), cross-platform sha256sum / shasum;
# falls back to cksum if neither is available.
ssot_hash() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -c1-12
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | cut -c1-12
  else
    cksum "$1" | awk '{print $1}'
  fi
}

version_ge() {
  local lhs="$1" rhs="$2"
  local lhs_major lhs_minor rhs_major rhs_minor
  lhs_major="${lhs%%.*}"
  lhs_minor="${lhs#*.}"
  lhs_minor="${lhs_minor%%.*}"
  rhs_major="${rhs%%.*}"
  rhs_minor="${rhs#*.}"
  rhs_minor="${rhs_minor%%.*}"
  [[ "$lhs_major" =~ ^[0-9]+$ ]] || return 1
  [[ "$lhs_minor" =~ ^[0-9]+$ ]] || lhs_minor=0
  [[ "$rhs_major" =~ ^[0-9]+$ ]] || return 1
  [[ "$rhs_minor" =~ ^[0-9]+$ ]] || rhs_minor=0
  if (( lhs_major > rhs_major )); then return 0; fi
  if (( lhs_major < rhs_major )); then return 1; fi
  (( lhs_minor >= rhs_minor ))
}

# ---------- v2.48 [META-LEAKAGE] (15I) helper ----------
# Greps product / architecture prose files for SSOT self-maintenance machinery
# that v2.48 hoists to sibling `_manifest.md`. Always FAIL; tokens are
# mechanically decidable. Called once per target directory; populates the
# global FAILS array via add_fail.
#
# Scope exclusions: `_manifest.md` itself, `STATUS.md`, `CHANGELOG.md`, anything
# under `decisions/` or `tech-debt/`.
META_LEAKAGE_TOKENS='\[CORE-REF-PROSE\]|\[MAXIM-OWNER\]|\[INTENT-OWNER\]|\[INTENT-TRUTH-NARRATIVE\]|\[CORE-COVERAGE-MAP\]|\[VOCAB-PROSE-FORK\]|\[WORKFLOW-STATE-VOCAB\]|\[INTENT-RECOVERY\]|\[META-LEAKAGE\]|(^|[^0-9A-Za-z])(14W|14X|14Y|14Z|15A|15B|15C|15D|15F|15G|15H|15I)([^0-9A-Za-z]|$)|(^|[^0-9A-Za-z])v2\.(43|44|45|46|47|48)([^0-9]|$)|product_intent \+ product_truth|design_intent \+ design_truth|必备 pillar|intent_recovery_pillars|intent_recovery_evidence:[[:space:]]*"|本 README 自身的可恢复性失败模式|本节正文回流|Apex-Maxim → Owner 索引|^##[[:space:]]+核心恢复清单|^##[[:space:]]+Capability → Surface registry'

check_meta_leakage_dir() {
  local target_dir="$1"
  local hit_count=0
  [[ ! -d "$target_dir" ]] && return 0
  while IFS= read -r -d '' md_file; do
    local rel_file="${md_file##*/}"
    [[ "$rel_file" == "_manifest.md" ]] && continue
    [[ "$rel_file" == "STATUS.md" ]] && continue
    [[ "$rel_file" == "CHANGELOG.md" ]] && continue
    local rel_path="${md_file#"$target_dir"/}"
    [[ "$rel_path" == decisions/* ]] && continue
    [[ "$rel_path" == tech-debt/* ]] && continue
    # Skip the bundle-shape v2.4x labels that legitimately reference the
    # protocol generation as prose. The forbidden cases are doctor codes /
    # cycle labels embedded INSIDE product/architecture prose, not protocol
    # files themselves.
    local hit
    hit=$(grep -nE "$META_LEAKAGE_TOKENS" "$md_file" 2>/dev/null | head -3 || true)
    if [[ -n "$hit" ]]; then
      local first_hit_line
      first_hit_line=$(printf '%s\n' "$hit" | head -1 | cut -d: -f1)
      local first_hit_text
      first_hit_text=$(printf '%s\n' "$hit" | head -1 | cut -d: -f2- | head -c 120)
      add_fail "[META-LEAKAGE] $md_file:$first_hit_line -- prose carries SSOT self-maintenance machinery that v2.48 hoists to sibling _manifest.md: $first_hit_text"
      hit_count=$((hit_count + 1))
    fi
    [[ "$hit_count" -ge 40 ]] && break
  done < <(find "$target_dir" -name '*.md' -type f -print0)
  return 0
}

# Run --check-meta-leakage mode: only the v2.48 grep, then output + exit.
if [[ "$META_LEAKAGE_ONLY" -eq 1 ]]; then
  if [[ "${#META_LEAKAGE_DIRS[@]}" -eq 0 ]]; then
    [[ -d "$SSOT_DIR/product" ]] && META_LEAKAGE_DIRS+=("$SSOT_DIR/product")
    [[ -d "$SSOT_DIR/architecture" ]] && META_LEAKAGE_DIRS+=("$SSOT_DIR/architecture")
  fi
  for d in "${META_LEAKAGE_DIRS[@]}"; do
    check_meta_leakage_dir "$d"
  done
  if [[ "${#FAILS[@]}" -eq 0 ]]; then
    add_pass "no [META-LEAKAGE] (15I) hits in product/architecture prose"
  fi
  # jump to output + exit logic at end of script
  META_LEAKAGE_SKIP_OTHER_CHECKS=1
else
  META_LEAKAGE_SKIP_OTHER_CHECKS=0
fi

# ---------- check 1: STATUS.md required fields ----------
if [[ "$META_LEAKAGE_SKIP_OTHER_CHECKS" -ne 1 ]]; then
STATUS_FILE="$SSOT_DIR/STATUS.md"
STATUS_SKILL_VERSION=""
REPO_ROOT=$(dirname "$SSOT_DIR")
if [[ ! -f "$STATUS_FILE" ]]; then
  add_fail "STATUS.md missing: $STATUS_FILE"
else
  STATUS_SKILL_VERSION=$(grep -E '(\|\s*tracked_skill_version\s*\||^tracked_skill_version:)' "$STATUS_FILE" | head -n 1 | grep -oE '[0-9]+\.[0-9]+' | head -n 1 || true)
  for field in "tracked_commit" "tracked_session" "tracked_skill_version" "documentation_language" "documentation_language_evidence" "coverage_result"; do
    if ! grep -qE "(\|\s*$field\s*\||^$field:|^- \*\*$field\*\*)" "$STATUS_FILE"; then
      add_fail "STATUS.md missing required field: $field"
    fi
  done
  if ! grep -qE '^\|\s*product\s*\|' "$STATUS_FILE"; then
    add_fail "STATUS.md area-status block missing required product row (v2.19 required top-level area)"
  fi
  if grep -qE "\|\s*tracked_commit\s*\|" "$STATUS_FILE"; then
    add_pass "STATUS.md required fields complete"
  fi
fi

# ---------- check 2: tracked_commit is an ancestor of HEAD ----------
if [[ -f "$STATUS_FILE" ]] && command -v git >/dev/null 2>&1; then
  TRACKED_COMMIT=$(grep -oE '`[0-9a-f]{7,40}`' "$STATUS_FILE" | head -n 1 | tr -d '`' || true)
  if [[ -n "$TRACKED_COMMIT" ]]; then
    if git -C "$(dirname "$SSOT_DIR")" cat-file -e "$TRACKED_COMMIT" 2>/dev/null; then
      HEAD_SHA=$(git -C "$(dirname "$SSOT_DIR")" rev-parse HEAD)
      if git -C "$(dirname "$SSOT_DIR")" merge-base --is-ancestor "$TRACKED_COMMIT" "$HEAD_SHA" 2>/dev/null; then
        DRIFT=$(git -C "$(dirname "$SSOT_DIR")" rev-list "$TRACKED_COMMIT..$HEAD_SHA" --count 2>/dev/null || echo 0)
        if [[ "$DRIFT" -gt 50 ]]; then
          add_warn "tracked_commit is $DRIFT commits behind HEAD (> 50 threshold); run commit-audit or advance tracked_commit"
        else
          add_pass "tracked_commit is ancestor of HEAD; drift = $DRIFT commits"
        fi

        # If converged is declared but drift > 0, warn (self-reference loop:
        # forcing FAIL here would lock the project out of normal closeout).
        if grep -qE "coverage_result\s*\|\s*\`?converged\`?" "$STATUS_FILE" && [[ "$DRIFT" -gt 0 ]]; then
          add_warn "coverage_result=converged but tracked_commit is $DRIFT commits behind HEAD; converged is a stop conclusion and should be re-reviewed before further advance"
        fi
      else
        add_fail "tracked_commit ($TRACKED_COMMIT) is not an ancestor of current HEAD; the branch may have been rebased/reset"
      fi
    else
      add_fail "tracked_commit ($TRACKED_COMMIT) does not exist in git history"
    fi
  else
    add_warn "could not parse tracked_commit SHA from STATUS.md"
  fi
fi

# ---------- check 3: SSOT-internal markdown link validity ----------
LINK_FAIL_COUNT=0
while IFS= read -r -d '' md_file; do
  # Extract relative-path links in markdown: [label](./path), [label](../path), [label](path.md)
  while IFS= read -r link; do
    # Strip anchor (#section)
    target_path="${link%#*}"
    # Skip external links and mailtos
    [[ "$target_path" =~ ^https?:// ]] && continue
    [[ "$target_path" =~ ^mailto: ]] && continue
    [[ -z "$target_path" ]] && continue
    # Resolve relative to the markdown file's directory
    md_dir=$(dirname "$md_file")
    resolved="$md_dir/$target_path"
    # Canonicalise (strip ./ and ../)
    resolved_canonical=$(cd "$(dirname "$resolved")" 2>/dev/null && pwd -P)/$(basename "$resolved") || resolved_canonical=""
    if [[ -n "$resolved_canonical" && ! -e "$resolved_canonical" ]] && [[ ! -e "$resolved" ]]; then
      add_fail "broken internal link: $md_file -> $target_path"
      LINK_FAIL_COUNT=$((LINK_FAIL_COUNT + 1))
      [[ "$LINK_FAIL_COUNT" -ge 20 ]] && break 2  # cap output volume
    fi
  done < <(grep -oE '\]\([^)]+\)' "$md_file" | sed -E 's/^\]\(([^)]+)\)$/\1/' | grep -vE '^https?://|^mailto:|^#')
done < <(find "$SSOT_DIR" -name '*.md' -type f -print0)

if [[ "$LINK_FAIL_COUNT" -eq 0 ]]; then
  add_pass "all SSOT internal links resolve"
elif [[ "$LINK_FAIL_COUNT" -ge 20 ]]; then
  add_fail "broken-link count hit the 20 cap; there may be more"
fi

# ---------- check 4: bug/tech-debt frontmatter ----------
for entry_dir in "bugs" "tech-debt"; do
  if [[ -d "$SSOT_DIR/$entry_dir" ]]; then
    missing_count=0
    while IFS= read -r -d '' entry_file; do
      filename=$(basename "$entry_file")
      # README.md is exempt from frontmatter
      [[ "$filename" == "README.md" ]] && continue
      # Only inspect numbered-prefix entry files
      [[ ! "$filename" =~ ^[0-9]{4}-.+\.md$ ]] && continue
      # First 3 lines must contain YAML frontmatter opener ---
      if ! head -n 3 "$entry_file" | grep -qE '^---$'; then
        add_warn "$entry_dir entry missing YAML frontmatter: $entry_file"
        missing_count=$((missing_count + 1))
      fi
    done < <(find "$SSOT_DIR/$entry_dir" -name '*.md' -type f -print0)
    if [[ "$missing_count" -eq 0 ]]; then
      add_pass "$entry_dir entries: frontmatter complete"
    fi
  fi
done

# ---------- check 5: STATUS.md Notes must not become an owner/run ledger (v2.34) ----------
if [[ -f "$STATUS_FILE" ]]; then
  # Scope this to the area-status table. Other STATUS sections such as
  # stop-review evidence and source-material absorption are protocol-owned
  # ledgers and should not trigger this heuristic.
  STATUS_AREA_TABLE=$(awk '
    /^\|[[:space:]]*(区域|Area)[[:space:]]*\|/ { in_area=1; print; next }
    in_area && /^##[[:space:]]/ { exit }
    in_area && /^\|/ { print; next }
    in_area && NF == 0 { exit }
  ' "$STATUS_FILE")
  STATUS_LEDGER_PATTERNS=(
    "[0-9]+ active"
    "[0-9]+ \`active\`"
    "[0-9]+ long.?term bug"
    "[0-9]+ gotcha"
    "[0-9]+ ADR"
    "[0-9]+ active.*[0-9]+ resolved"
    "20[0-9]{2}-[0-9]{2}-[0-9]{2}"
    "BUG-[0-9]{4}.*(批次|新增|同步|补强|记录|验证|通过|失败|复发|fixed|passed|failed)"
    "(批次|新增|同步|补强|记录|验证|通过|失败|复发|fixed|passed|failed).*BUG-[0-9]{4}"
    "(latest|recent|最新|近期).*(verification|validation|验证|smoke)"
    "(passed|failed|全绿|未全绿|Web health|Vitest|E2E).*(verification|validation|验证|smoke|run)"
    "(verification|validation|验证|smoke|run).*(passed|failed|全绿|未全绿|Web health|Vitest|E2E)"
  )
  found_status_ledger=0
  for pattern in "${STATUS_LEDGER_PATTERNS[@]}"; do
    if printf '%s\n' "$STATUS_AREA_TABLE" | grep -qE "$pattern"; then
      found_status_ledger=1
      break
    fi
  done
  if [[ "$found_status_ledger" -eq 1 ]]; then
    add_warn "[STATUS-NOTES-LEDGER] STATUS.md area-status Notes look like they carry child-entry state, latest validation, batch history, or count info; switch to coverage pointers / open gaps / owner links"
  else
    add_pass "STATUS.md Notes free of obvious owner/run ledger material"
  fi
fi

# ---------- check 5b: README/index files must not mirror child-derived state (v2.34) ----------
INDEX_DERIVED_PATTERNS=(
  "当前共[[:space:]]*([0-9]+|[一二三四五六七八九十]+)"
  "目前索引"
  "本仓库目前索引"
  "[0-9]+[[:space:]]*条.*(active|resolved|fixed|bug|BUG|DEBT|gotcha|陷阱|债务)"
  "证据账本"
  "验证强度"
  "(latest|recent|最新|近期)[^|]{0,80}(verification|validation|activity|run history|验证|活动)"
)
index_warn_count=0
while IFS= read -r -d '' readme_file; do
  # Architecture domain READMEs may legitimately own their own CTG. This
  # heuristic only targets obvious generated counts and recent-state mirrors.
  found_index_state=0
  for pattern in "${INDEX_DERIVED_PATTERNS[@]}"; do
    if grep -qE "$pattern" "$readme_file"; then
      found_index_state=1
      break
    fi
  done
  if [[ "$found_index_state" -eq 1 ]]; then
    add_warn "[INDEX-DERIVED-STATE] README/index appears to mirror generated counts, latest activity, verification strength, or child-owned lifecycle state: $readme_file"
    index_warn_count=$((index_warn_count + 1))
  fi
  [[ "$index_warn_count" -ge 20 ]] && break
done < <(find "$SSOT_DIR" -name 'README.md' -type f -print0)
if [[ "$index_warn_count" -eq 0 ]]; then
  add_pass "README/index files free of obvious derived-state mirrors"
fi

# ---------- check 5c: non-owner files must not keep shadow proof-of-work ledgers (v2.34) ----------
SHADOW_LEDGER_PATTERNS=(
  "^##[[:space:]]*(证据账本|验证说明|历史验证|运行历史|事故流水|Recent validation|Latest verification|Run history)"
  "^##[[:space:]]*.*(recent run|latest run|verification ledger|validation ledger)"
  "^##[[:space:]]*.*(事故|incident).*(流水|history|ledger)"
  "^### [0-9]{4}-[0-9]{2}-[0-9]{2}.*(事故|incident)"
)
shadow_warn_count=0
while IFS= read -r -d '' md_file; do
  rel_file="${md_file#"$SSOT_DIR"/}"
  [[ "$rel_file" == "STATUS.md" ]] && continue
  [[ "$rel_file" == testing/* ]] && continue
  [[ "$rel_file" == bugs/[0-9][0-9][0-9][0-9]-*.md ]] && continue
  [[ "$rel_file" == decisions/[0-9][0-9][0-9][0-9]-*.md ]] && continue
  [[ "$rel_file" == release/* ]] && continue
  found_shadow_ledger=0
  for pattern in "${SHADOW_LEDGER_PATTERNS[@]}"; do
    if grep -qE "$pattern" "$md_file"; then
      found_shadow_ledger=1
      break
    fi
  done
  if [[ "$found_shadow_ledger" -eq 1 ]]; then
    add_warn "[SHADOW-LEDGER] non-owner SSOT file appears to carry chronological proof-of-work or incident/run ledger material: $md_file"
    shadow_warn_count=$((shadow_warn_count + 1))
  fi
  [[ "$shadow_warn_count" -ge 20 ]] && break
done < <(find "$SSOT_DIR" -name '*.md' -type f -print0)
if [[ "$shadow_warn_count" -eq 0 ]]; then
  add_pass "non-owner SSOT files free of obvious shadow ledgers"
fi

# ---------- check 5d: STATUS stop-review fields must not become batch ledgers (v2.35) ----------
if [[ -f "$STATUS_FILE" ]]; then
  stop_review_warn_count=0
  while IFS= read -r stop_line; do
    line_no="${stop_line%%:*}"
    line="${stop_line#*:}"
    line_len=${#line}
    if [[ "$line_len" -gt 900 ]] || printf '%s\n' "$line" | grep -qE '(pytest|Playwright|Vitest|SKIPPED|stdout|stderr|command|Browser DOM|screenshot|批次|命令|截图|全绿|未全绿|验证.*(通过|失败)|通过.*验证|失败.*验证)'; then
      add_warn "[STATUS-STOP-REVIEW-LEDGER] STATUS.md stop-review surface appears to carry batch transcript, command ledger, or proof-of-work prose; keep conclusion plus evidence pointers: $STATUS_FILE:$line_no"
      stop_review_warn_count=$((stop_review_warn_count + 1))
    fi
  done < <(
    {
      grep -nE '^\|[^|]*(last_stop_review|stop[_ -]?review|停止审查)[^|]*\|' "$STATUS_FILE" || true
      awk '
        /^##[[:space:]]/ {
          in_stop = ($0 ~ /(stop[- ]?review|Stop[- ]?review|停止审查)/)
        }
        in_stop { print FNR ":" $0 }
      ' "$STATUS_FILE"
    } | awk '!seen[$0]++'
  )
  if [[ "$stop_review_warn_count" -eq 0 ]]; then
    add_pass "STATUS.md stop-review summary free of obvious batch ledger material"
  fi
fi

# ---------- check 5e: high-risk entry files need an agent quick entry (v2.35) ----------
entry_actionability_warn_count=0
for entry_dir in "bugs" "tech-debt"; do
  if [[ -d "$SSOT_DIR/$entry_dir" ]]; then
    while IFS= read -r -d '' entry_file; do
      filename=$(basename "$entry_file")
      [[ "$filename" == "README.md" ]] && continue
      [[ ! "$filename" =~ ^[0-9]{4}-.+\.md$ ]] && continue
      entry_head=$(head -n 40 "$entry_file")
      if ! printf '%s\n' "$entry_head" | grep -qiE '^(status:[[:space:]]*(active|recurred)|severity:[[:space:]]*(critical|major)|priority:[[:space:]]*high)'; then
        continue
      fi
      if ! head -n 80 "$entry_file" | grep -qiE '(Agent quick entry|Quick entry|Agent 快速入口|快速入口)'; then
        add_warn "[ENTRY-ACTIONABILITY] numbered $entry_dir entry lacks a quick-entry surface for future agents: $entry_file"
        entry_actionability_warn_count=$((entry_actionability_warn_count + 1))
      fi
      [[ "$entry_actionability_warn_count" -ge 20 ]] && break 2
    done < <(find "$SSOT_DIR/$entry_dir" -name '*.md' -type f -print0)
  fi
done
if [[ "$entry_actionability_warn_count" -eq 0 ]]; then
  add_pass "bug/tech-debt numbered entries have no obvious quick-entry gaps"
fi

# ---------- check 5f: very long Markdown lines hide paragraph content (v2.35) ----------
READABILITY_LONG_LINE_THRESHOLD=${SSOT_READABILITY_LONG_LINE_THRESHOLD:-900}
long_line_warn_count=0
while IFS= read -r -d '' md_file; do
  rel_file="${md_file#"$SSOT_DIR"/}"
  [[ "$rel_file" == .bootstrap/* ]] && continue
  hit=$(awk -v threshold="$READABILITY_LONG_LINE_THRESHOLD" '
    /^```/ { in_code = !in_code; next }
    !in_code && length($0) > threshold { print FNR; exit }
  ' "$md_file")
  if [[ -n "$hit" ]]; then
    add_warn "[READABILITY-LONG-LINE] Markdown line exceeds ${READABILITY_LONG_LINE_THRESHOLD} chars; split prose or lift it out of a table cell: $md_file:$hit"
    long_line_warn_count=$((long_line_warn_count + 1))
  fi
  [[ "$long_line_warn_count" -ge 20 ]] && break
done < <(find "$SSOT_DIR" -name '*.md' -type f -print0)
if [[ "$long_line_warn_count" -eq 0 ]]; then
  add_pass "SSOT Markdown free of obvious overlong-line readability issues"
fi

# ---------- check 5g: table density can hide KISS violations (v2.36) ----------
# This is intentionally WARN-only. Some files are legitimate indexes or
# registers; Doctor decides whether high density is justified.
KISS_TABLE_LINE_THRESHOLD=${SSOT_KISS_TABLE_LINE_THRESHOLD:-70}
KISS_TABLE_RATIO_THRESHOLD=${SSOT_KISS_TABLE_RATIO_THRESHOLD:-35}
kiss_table_warn_count=0
while IFS= read -r -d '' md_file; do
  rel_file="${md_file#"$SSOT_DIR"/}"
  [[ "$rel_file" == .bootstrap/* ]] && continue
  [[ "$rel_file" == "STATUS.md" ]] && continue
  total_lines=$(awk 'END { print NR }' "$md_file")
  [[ "$total_lines" -eq 0 ]] && continue
  table_lines=$(grep -cE '^\|' "$md_file" || true)
  ratio=$(( table_lines * 100 / total_lines ))
  if [[ "$table_lines" -ge "$KISS_TABLE_LINE_THRESHOLD" && "$ratio" -ge "$KISS_TABLE_RATIO_THRESHOLD" ]]; then
    add_warn "[KISS-TABLE-DENSITY] Markdown file has high table-line density (${table_lines}/${total_lines}, ${ratio}%); inspect whether tables replaced the mental-model prose: $md_file"
    kiss_table_warn_count=$((kiss_table_warn_count + 1))
  fi
  [[ "$kiss_table_warn_count" -ge 20 ]] && break
done < <(find "$SSOT_DIR" -name '*.md' -type f -print0)
if [[ "$kiss_table_warn_count" -eq 0 ]]; then
  add_pass "SSOT Markdown free of obvious KISS table-density warnings"
fi

# ---------- check 5g2: product / architecture core manifests need narrative first (v2.47) ----------
# WARN-only: heading/name differences may require semantic Doctor judgement.
intent_truth_warn_count=0
if [[ -f "$STATUS_FILE" ]] && grep -qE '^\|\s*(product|architecture)\s*\|\s*covered\s*\|' "$STATUS_FILE"; then
  declare -a TRUNK_FILES=()
  # v2.50: prefer faceted top-level (01-product, 02-architecture) when present.
  if [[ -d "$SSOT_DIR/01-product" ]]; then
    P_TRUNK="01-product"
  else
    P_TRUNK="product"
  fi
  if [[ -d "$SSOT_DIR/02-architecture" ]]; then
    A_TRUNK="02-architecture"
  else
    A_TRUNK="architecture"
  fi
  [[ -f "$SSOT_DIR/$P_TRUNK/README.md" ]] && TRUNK_FILES+=("$SSOT_DIR/$P_TRUNK/README.md")
  [[ -f "$SSOT_DIR/$P_TRUNK/prd.md" ]] && TRUNK_FILES+=("$SSOT_DIR/$P_TRUNK/prd.md")
  [[ -f "$SSOT_DIR/$A_TRUNK/README.md" ]] && TRUNK_FILES+=("$SSOT_DIR/$A_TRUNK/README.md")
  product_has_intent_truth=0
  if grep -qE '^##[[:space:]].*(Product Intent And Truth|Product intent and truth|产品意图与产品真相|产品一页主线|产品真相)' "$SSOT_DIR/$P_TRUNK/README.md" "$SSOT_DIR/$P_TRUNK/prd.md" 2>/dev/null; then
    product_has_intent_truth=1
  fi
  for trunk_file in "${TRUNK_FILES[@]}"; do
    if ! grep -qE '(Core recovery manifest|核心恢复清单)' "$trunk_file"; then
      continue
    fi
    rel_trunk="${trunk_file#"$SSOT_DIR"/}"
    if [[ "$rel_trunk" == "$P_TRUNK"/* ]]; then
      if [[ "$product_has_intent_truth" -eq 0 ]]; then
        add_warn "[INTENT-TRUTH-NARRATIVE] covered product trunk has a Core recovery manifest but no obvious product intent/truth narrative heading before it: $trunk_file"
        intent_truth_warn_count=$((intent_truth_warn_count + 1))
      fi
    elif [[ "$rel_trunk" == architecture/* ]]; then
      if ! grep -qE '^##[[:space:]].*(Design Intent And Truth|Design intent and truth|设计意图与设计真相|核心设计论证|设计真相)' "$trunk_file"; then
        add_warn "[INTENT-TRUTH-NARRATIVE] covered architecture trunk has a Core recovery manifest but no obvious design intent/truth narrative heading before it: $trunk_file"
        intent_truth_warn_count=$((intent_truth_warn_count + 1))
      fi
    fi
    [[ "$intent_truth_warn_count" -ge 20 ]] && break
  done
fi
if [[ "$intent_truth_warn_count" -eq 0 ]]; then
  add_pass "product/architecture core manifests have no obvious intent/truth narrative heading gaps"
fi

# ---------- check 5h: source inventory and working-doc lifecycle governance (v2.38) ----------
# Enforced only once a project has advanced tracked_skill_version to v2.38.
# This keeps newly installed lint from hard-failing older projects before their
# protocol-upgrade review has run.
if [[ -f "$STATUS_FILE" && -n "$STATUS_SKILL_VERSION" ]] && version_ge "$STATUS_SKILL_VERSION" "2.38"; then
  LIFECYCLE_RE='working/(research|draft|proposal|experiment|poc|prototype|execution-log|closure|report|handoff)|historical/(superseded|deprecated)|external/source-material|public/thin-entry'
  STRONG_FACT_RE='(current|API|SDK|schema|runtime|acceptance|roadmap|implemented|implementation|contract|database|当前|接口|运行时|验收|路线图|实现|契约|数据库)'

  lifecycle_header_ok() { # $1=file
    local header lifecycle
    header=$(head -n 50 "$1")
    lifecycle=$(printf '%s\n' "$header" | grep -Eio "$LIFECYCLE_RE" | head -n 1 || true)
    [[ -n "$lifecycle" ]] || return 1
    printf '%s\n' "$header" | grep -qiE 'authority[[:space:]:=]' || return 1
    printf '%s\n' "$header" | grep -qiE '(owner|ssot_owner)[[:space:]:=]' || return 1
    printf '%s\n' "$header" | grep -qiE 'review_on[[:space:]:=]' || return 1
    if [[ "$lifecycle" =~ ^public/thin-entry$ ]]; then
      printf '%s\n' "$header" | grep -qiE '(absorbed_to|ssot_owner)[[:space:]:=]' || return 1
    else
      printf '%s\n' "$header" | grep -qiE 'absorbed_to[[:space:]:=]' || return 1
      printf '%s\n' "$header" | grep -qiE 'do_not_use_for[[:space:]:=]' || return 1
    fi
    return 0
  }

  status_line_for_source() { # $1=repo-relative markdown path
    local rel="$1" line pattern
    while IFS= read -r line; do
      [[ "$line" == \|* ]] || continue
      if ! printf '%s\n' "$line" | grep -qiE "$LIFECYCLE_RE|pattern=|authority[[:space:]=:]|absorbed_to[[:space:]=:]|do_not_use_for[[:space:]=:]|review_on[[:space:]=:]"; then
        continue
      fi
      if [[ "$line" == *"$rel"* ]]; then
        printf '%s\n' "$line"
        return 0
      fi
      while IFS= read -r pattern; do
        pattern="${pattern#pattern=}"
        pattern="${pattern//\`/}"
        pattern="${pattern//,/}"
        pattern="${pattern//;/}"
        [[ -z "$pattern" ]] && continue
        # shellcheck disable=SC2053  # unquoted $pattern is intentional glob matching
        if [[ "$rel" == $pattern ]]; then
          printf '%s\n' "$line"
          return 0
        fi
      done < <(printf '%s\n' "$line" | grep -oE 'pattern=`?[^ |;,)`]+' || true)
    done < "$STATUS_FILE"
    return 1
  }

  status_inventory_ok() { # $1=matching STATUS row
    local line="$1" lifecycle
    lifecycle=$(printf '%s\n' "$line" | grep -Eio "$LIFECYCLE_RE" | head -n 1 || true)
    [[ -n "$lifecycle" ]] || return 1
    printf '%s\n' "$line" | grep -qiE 'authority[[:space:]=:]' || return 1
    printf '%s\n' "$line" | grep -qiE '(owner|ssot_owner)[[:space:]=:]' || return 1
    printf '%s\n' "$line" | grep -qiE 'review_on[[:space:]=:]' || return 1
    if [[ "$lifecycle" =~ ^public/thin-entry$ ]]; then
      printf '%s\n' "$line" | grep -qiE '(absorbed_to|ssot_owner)[[:space:]=:]' || return 1
    else
      printf '%s\n' "$line" | grep -qiE 'absorbed_to[[:space:]=:]' || return 1
      printf '%s\n' "$line" | grep -qiE 'do_not_use_for[[:space:]=:]' || return 1
    fi
    return 0
  }

  status_exclusion_ok() { # $1=matching STATUS row
    local line="$1"
    printf '%s\n' "$line" | grep -qiE 'reason[[:space:]=:]' || return 1
    printf '%s\n' "$line" | grep -qiE 'owner[[:space:]=:]' || return 1
    printf '%s\n' "$line" | grep -qiE 'last_checked[[:space:]=:]' || return 1
    printf '%s\n' "$line" | grep -qiE 'review_trigger[[:space:]=:]' || return 1
    return 0
  }

  source_inventory_fail_count=0
  while IFS= read -r -d '' source_md; do
    rel_source="${source_md#"$REPO_ROOT"/}"
    [[ "$rel_source" == SSOT/* ]] && continue
    [[ "$rel_source" == .git/* ]] && continue
    line="$(status_line_for_source "$rel_source" || true)"
    if lifecycle_header_ok "$source_md" || { [[ -n "$line" ]] && status_inventory_ok "$line"; } || { [[ -n "$line" ]] && status_exclusion_ok "$line"; }; then
      :
    else
      add_fail "[SOURCE-INVENTORY] root/docs markdown lacks v2.38 lifecycle inventory, in-file header, or audited exclusion: $rel_source"
      source_inventory_fail_count=$((source_inventory_fail_count + 1))
    fi

    combined_meta="$(head -n 50 "$source_md"; printf '\n%s\n' "$line")"
    lifecycle="$(printf '%s\n' "$combined_meta" | grep -Eio "$LIFECYCLE_RE" | head -n 1 || true)"
    if [[ -n "$lifecycle" ]] && [[ "$lifecycle" != "public/thin-entry" ]]; then
      if grep -qiE "$STRONG_FACT_RE" "$source_md"; then
        if ! printf '%s\n' "$combined_meta" | grep -qiE 'absorbed_to[[:space:]=:]' || ! printf '%s\n' "$combined_meta" | grep -qiE 'do_not_use_for[[:space:]=:]'; then
          add_fail "[SOURCE-LIFECYCLE] working/historical/external doc contains strong current-fact words without downgrade fields absorbed_to + do_not_use_for: $rel_source"
          source_inventory_fail_count=$((source_inventory_fail_count + 1))
        fi
      fi
    fi
    if [[ "$lifecycle" == "public/thin-entry" ]]; then
      if ! printf '%s\n' "$combined_meta" | grep -qiE '(ssot_owner|owner)[[:space:]=:]'; then
        add_fail "[THIN-DOCS] public thin doc lacks SSOT owner: $rel_source"
        source_inventory_fail_count=$((source_inventory_fail_count + 1))
      fi
    fi
    [[ "$source_inventory_fail_count" -ge 30 ]] && break
  done < <(
    find "$REPO_ROOT" -maxdepth 1 -name '*.md' -type f -print0
    [[ -d "$REPO_ROOT/docs" ]] && find "$REPO_ROOT/docs" -name '*.md' -type f -print0
  )

  exclusion_shape_fail_count=0
  while IFS= read -r line; do
    [[ "$line" == *"pattern="* ]] || continue
    if printf '%s\n' "$line" | grep -qiE 'reason[[:space:]=:]|last_checked[[:space:]=:]|review_trigger[[:space:]=:]'; then
      if ! status_exclusion_ok "$line"; then
        add_fail "[SOURCE-EXCLUSION] audited exclusion row missing reason, owner, last_checked, or review_trigger: $line"
        exclusion_shape_fail_count=$((exclusion_shape_fail_count + 1))
      fi
    fi
    [[ "$exclusion_shape_fail_count" -ge 20 ]] && break
  done < "$STATUS_FILE"

  if [[ "$source_inventory_fail_count" -eq 0 && "$exclusion_shape_fail_count" -eq 0 ]]; then
    add_pass "root/docs markdown source inventory and lifecycle headers complete"
  fi
fi

# ---------- check 5i: product/architecture IA drift heuristics (v2.38) ----------
# WARN-only: these are obvious anti-pattern detectors, not semantic proof.
product_arch_warn_count=0
if [[ -d "$SSOT_DIR/product" ]]; then
  while IFS= read -r -d '' product_file; do
    if grep -qiE '^##[[:space:]].*(runtime flow|API reference|SDK reference|schema reference|implementation details|database schema)' "$product_file"; then
      add_warn "[PRODUCT-ARCH-DRIFT] product file appears to own runtime/API/SDK/schema implementation detail instead of linking architecture owner: $product_file"
      product_arch_warn_count=$((product_arch_warn_count + 1))
    fi
    [[ "$product_arch_warn_count" -ge 20 ]] && break
  done < <(find "$SSOT_DIR/product" -name '*.md' -type f -print0)
fi
if [[ -d "$SSOT_DIR/architecture" ]]; then
  while IFS= read -r -d '' arch_file; do
    if grep -qiE '^##[[:space:]].*(product promise|product roadmap|product acceptance|users and problems|用户承诺|产品承诺|产品路线图|产品验收)' "$arch_file"; then
      add_warn "[PRODUCT-ARCH-DRIFT] architecture file appears to redefine product facts instead of linking product owner: $arch_file"
      product_arch_warn_count=$((product_arch_warn_count + 1))
    fi
    [[ "$product_arch_warn_count" -ge 20 ]] && break
  done < <(find "$SSOT_DIR/architecture" -name '*.md' -type f -print0)
fi
if [[ "$product_arch_warn_count" -eq 0 ]]; then
  add_pass "product/architecture boundary free of obvious deterministic drift"
fi

arch_checklist_warn_count=0
if [[ -d "$SSOT_DIR/architecture" ]]; then
  while IFS= read -r -d '' arch_readme; do
    rel_arch="${arch_readme#"$SSOT_DIR"/}"
    [[ "$rel_arch" == "architecture/README.md" ]] && continue
    [[ "$rel_arch" == "architecture/views/README.md" ]] && continue
    h2_count=$(grep -cE '^##[[:space:]]' "$arch_readme" || true)
    placeholder_count=$(grep -cE 'not_applicable|OPTIONAL-START|OPTIONAL-END|<[^>]+>' "$arch_readme" || true)
    if [[ "$h2_count" -ge 18 || "$placeholder_count" -ge 12 ]]; then
      add_warn "[ARCH-CHECKLIST-HEAVY] architecture domain/view README looks like a universal checklist instead of a Runtime Owner Map: $arch_readme"
      arch_checklist_warn_count=$((arch_checklist_warn_count + 1))
    fi
    [[ "$arch_checklist_warn_count" -ge 20 ]] && break
  done < <(find "$SSOT_DIR/architecture" -name 'README.md' -type f -print0)
fi
if [[ "$arch_checklist_warn_count" -eq 0 ]]; then
  add_pass "architecture owner files free of obvious checklist-heavy IA warnings"
fi

# ---------- check 6: confidence: hypothesis forbidden in architecture/ body (v2.13) ----------
# Per knowledge-integrity.md §1: hypothesis may only live in gotchas / STATUS.md open gaps.
# candidate inside architecture gap/unknown notes is legal (needs semantic judgement);
# that case belongs to Doctor L2 and is not checked here.
ARCH_DIR="$SSOT_DIR/architecture"
if [[ -d "$ARCH_DIR" ]]; then
  hyp_hits=0
  while IFS= read -r -d '' arch_file; do
    if grep -qE 'confidence:[[:space:]]*hypothesis' "$arch_file"; then
      add_fail "architecture body contains confidence: hypothesis (move to gotchas or STATUS.md open-gap): $arch_file"
      hyp_hits=$((hyp_hits + 1))
    fi
  done < <(find "$ARCH_DIR" -name '*.md' -type f -print0)
  if [[ "$hyp_hits" -eq 0 ]]; then
    add_pass "architecture body free of confidence: hypothesis"
  fi
fi

# ---------- check 7: SSOT-generated thin adapter marker and size (v2.13 / v2.17 boundary) ----------
# Startup reference files live in the repo root (parent of SSOT_DIR), not inside SSOT/.
# Only files carrying the SSOT-generated marker count as generated thin adapters and are
# subject to [ADAPTER] shape checks. Hand-written or mixed startup files do NOT trigger
# ADAPTER for missing marker; their SSOT routing is covered by check 9, and their factual
# correctness by CORE-REF.
ADAPTER_MARKER='<!-- SSOT-generated'
declare -a STARTUP_REF_FILES=()
declare -a GENERATED_ADAPTER_FILES=()
for ref_name in "AGENTS.md" "CLAUDE.md" "GEMINI.md"; do
  [[ -f "$REPO_ROOT/$ref_name" ]] && STARTUP_REF_FILES+=("$REPO_ROOT/$ref_name")
done
if [[ -d "$REPO_ROOT/.cursor/rules" ]]; then
  while IFS= read -r -d '' cf; do
    STARTUP_REF_FILES+=("$cf")
  done < <(find "$REPO_ROOT/.cursor/rules" -maxdepth 1 -type f \( -name '*.md' -o -name '*.mdc' \) -print0)
fi
if [[ -d "$REPO_ROOT/.windsurf/rules" ]]; then
  while IFS= read -r -d '' wf; do
    STARTUP_REF_FILES+=("$wf")
  done < <(find "$REPO_ROOT/.windsurf/rules" -maxdepth 1 -type f -print0)
fi

for sf in "${STARTUP_REF_FILES[@]}"; do
  if head -n 3 "$sf" | grep -qF "$ADAPTER_MARKER"; then
    GENERATED_ADAPTER_FILES+=("$sf")
  fi
done

if [[ "${#GENERATED_ADAPTER_FILES[@]}" -gt 0 ]]; then
  adapter_issue=0
  for af in "${GENERATED_ADAPTER_FILES[@]}"; do
    lines=$(wc -l < "$af" | tr -d ' ')
    if [[ "$lines" -gt 50 ]]; then
      add_warn "SSOT-generated thin adapter exceeds 50 lines (should be routing + core invariants only): $af ($lines lines)"
      adapter_issue=$((adapter_issue + 1))
    fi
    # If a SSOT-source hash line is declared, verify the source file hasn't drifted (v2.13).
    # Missing declaration is not enforced.
    src_line=$(grep -m1 '<!-- SSOT-source:' "$af" || true)
    if [[ -n "$src_line" ]]; then
      refs=$(printf '%s' "$src_line" | sed -E 's/^.*SSOT-source:[[:space:]]*//; s/[[:space:]]*-->.*$//')
      for ref in $refs; do
        [[ "$ref" != *@* ]] && continue
        src_path="${ref%@*}"
        declared_hash="${ref##*@}"
        abs_src="$REPO_ROOT/$src_path"
        if [[ ! -f "$abs_src" ]]; then
          add_warn "SSOT-generated thin adapter references a missing SSOT source file: $src_path ($af)"
          adapter_issue=$((adapter_issue + 1))
        elif [[ "$(ssot_hash "$abs_src")" != "$declared_hash" ]]; then
          add_warn "SSOT-generated thin adapter: source file changed, may need regeneration: $src_path ($af)"
          adapter_issue=$((adapter_issue + 1))
        fi
      done
    fi
  done
  if [[ "$adapter_issue" -eq 0 ]]; then
    add_pass "SSOT-generated thin adapters: marker and size OK"
  fi
fi

# ---------- check 8: evidence symbol-anchor freshness (v2.13) ----------
# Parse path#symbol anchors in confidence-frontmatter evidence; verify path and symbol
# still exist. evidence is free text — only path#symbol anchors are checked here;
# legacy line-number pointers are left alone (backwards-compat).
ptr_stale=0
while IFS= read -r -d '' md_file; do
  while IFS= read -r anchor; do
    a_path="${anchor%#*}"
    a_sym="${anchor#*#}"
    abs_a="$REPO_ROOT/$a_path"
    if [[ ! -f "$abs_a" ]]; then
      add_warn "[STALE] evidence path not found: $a_path ($md_file)"
      ptr_stale=$((ptr_stale + 1))
    elif ! grep -qF "$a_sym" "$abs_a"; then
      add_warn "[STALE] evidence symbol not found: $a_path#$a_sym ($md_file)"
      ptr_stale=$((ptr_stale + 1))
    fi
    [[ "$ptr_stale" -ge 20 ]] && break 2
  done < <(grep -oE 'evidence:[[:space:]]*"?[A-Za-z0-9_./-]+#[A-Za-z0-9_]+' "$md_file" 2>/dev/null | grep -oE '[A-Za-z0-9_./-]+#[A-Za-z0-9_]+' || true)
done < <(find "$SSOT_DIR" -name '*.md' -type f -print0)
if [[ "$ptr_stale" -eq 0 ]]; then
  add_pass "evidence symbol anchors verified (or none present)"
fi

# ---------- check 9: consumption path (v2.13) ----------
# Verifies that SSOT will actually be read by an agent: do startup reference files route
# to SSOT or $ssot-*; does the README navigation entry exist.
# Behavioural probes (L4: does a fresh-context agent really use SSOT) are semantic and
# live in references/consumption-audit.md, not here.
consumption_issue=0
if [[ "${#STARTUP_REF_FILES[@]}" -gt 0 ]]; then
  routed=0
  for sf in "${STARTUP_REF_FILES[@]}"; do
    if grep -qE 'SSOT/|\$ssot-' "$sf"; then routed=1; fi
  done
  if [[ "$routed" -eq 0 ]]; then
    add_warn "[CONSUMPTION] startup reference files exist but none point to SSOT/ or \$ssot-*; agents may never read SSOT"
    consumption_issue=$((consumption_issue + 1))
  fi
fi
if [[ ! -f "$SSOT_DIR/README.md" ]]; then
  add_warn "[CONSUMPTION] missing SSOT/README.md navigation entry; routed reads have no landing point"
  consumption_issue=$((consumption_issue + 1))
fi
if [[ "$consumption_issue" -eq 0 ]]; then
  add_pass "consumption-path check passed"
fi

# ---------- check 10: product skeleton (v2.19) ----------
# product/ is a required top-level area; only deterministic file existence is checked here.
# Body semantics are left to Doctor L2.
# v2.50: consumers may facet the top level (e.g. SSOT/01-product/...); resolve the
# product trunk at runtime by preferring the faceted form when present.
if [[ -d "$SSOT_DIR/01-product" ]]; then
  PRODUCT_TRUNK="01-product"
elif [[ -d "$SSOT_DIR/product" ]]; then
  PRODUCT_TRUNK="product"
else
  PRODUCT_TRUNK="product"  # report the canonical path as missing
fi
PRODUCT_REQUIRED_FILES=(
  "$PRODUCT_TRUNK/README.md"
  "$PRODUCT_TRUNK/prd.md"
  "$PRODUCT_TRUNK/product-model.md"
  "$PRODUCT_TRUNK/roadmap-and-acceptance.md"
  "$PRODUCT_TRUNK/capabilities/README.md"
  "$PRODUCT_TRUNK/journeys/README.md"
)
product_missing=0
for rel in "${PRODUCT_REQUIRED_FILES[@]}"; do
  if [[ ! -f "$SSOT_DIR/$rel" ]]; then
    add_fail "[PRODUCT] missing required product skeleton: $SSOT_DIR/$rel"
    product_missing=$((product_missing + 1))
  fi
done
if [[ "$product_missing" -eq 0 ]]; then
  add_pass "product skeleton complete"
fi

# ---------- check 11: decisions/ frontmatter required fields (v2.31) ----------
# Each decisions/NNNN-<slug>.md must declare lifecycle metadata so future
# agents can anchor the decision in time and to a specific git change.
# Required: status, implementation_state, created_on, updated_on, introduced_in.
# updated_in is omitted: it is optional when a decision has only the
# introducing commit (the area-model rule is "required from the first edit").
# Exemption: bootstrap-archaeology entries (e.g. 0000-bootstrap-recon.md)
# use the v2.12 archive frontmatter and are out of scope for this check.
DEC_DIR="$SSOT_DIR/decisions"
if [[ -d "$DEC_DIR" ]]; then
  dec_missing=0
  while IFS= read -r -d '' dec_file; do
    filename=$(basename "$dec_file")
    [[ "$filename" == "README.md" ]] && continue
    [[ ! "$filename" =~ ^[0-9]{4}-.+\.md$ ]] && continue
    # Frontmatter window: first 30 lines (well past any plausible YAML block).
    fm=$(head -n 30 "$dec_file")
    # Skip bootstrap-archaeology archives.
    if printf '%s' "$fm" | grep -qE '^type:[[:space:]]*bootstrap-archaeology'; then
      continue
    fi
    # Each required field must appear as a YAML key at line start.
    for field in "status" "implementation_state" "created_on" "introduced_in" "updated_on"; do
      if ! printf '%s' "$fm" | grep -qE "^${field}:"; then
        add_fail "[DECISION] decisions entry missing required field '${field}': $dec_file"
        dec_missing=$((dec_missing + 1))
      fi
    done
  done < <(find "$DEC_DIR" -maxdepth 1 -name '*.md' -type f -print0)
  if [[ "$dec_missing" -eq 0 ]]; then
    add_pass "decisions entries: required lifecycle fields present"
  fi
fi

# ---------- check 12: v2.48 [META-LEAKAGE] (15I) ----------
# Always run as part of normal mode so doctor / lint see meta-machinery hoisted
# to `_manifest.md` consistently. The standalone --check-meta-leakage flag runs
# only this check.
meta_leakage_before="${#FAILS[@]}"
[[ -d "$SSOT_DIR/product" ]] && check_meta_leakage_dir "$SSOT_DIR/product"
[[ -d "$SSOT_DIR/architecture" ]] && check_meta_leakage_dir "$SSOT_DIR/architecture"
meta_leakage_after="${#FAILS[@]}"
if [[ "$meta_leakage_after" -eq "$meta_leakage_before" ]]; then
  add_pass "no [META-LEAKAGE] (15I) hits in product/architecture prose"
fi

fi  # end META_LEAKAGE_SKIP_OTHER_CHECKS guard

# ---------- check 13: [PEER-FRONTMATTER] (15J) same-directory frontmatter uniformity ----------
# Scoped to product/ and architecture/ content directories. Ledger directories
# (bugs/, decisions/, tech-debt/) are excluded because their per-entry
# frontmatter intentionally varies with lifecycle state (e.g. ADR-CLOSURE adds
# closure_condition/revisit_signal only on pending/partial decisions per v2.43).
if [[ "$META_LEAKAGE_SKIP_OTHER_CHECKS" -ne 1 ]]; then
PEER_FM_FAIL_COUNT=0
peer_fm_check_dir() {
  local dir="$1"
  [[ ! -d "$dir" ]] && return 0
  local rel="${dir#"$SSOT_DIR"/}"
  rel="${rel%/}"
  # Skip ledger directories — lifecycle-dependent optional fields are legitimate.
  case "$rel" in
    bugs|decisions|tech-debt|bugs/*|decisions/*|tech-debt/*) return 0 ;;
  esac
  # Only apply to product/ and architecture/ scope.
  case "$rel" in
    product|product/*|architecture|architecture/*) ;;
    *) return 0 ;;
  esac
  local -a md_files=()
  while IFS= read -r -d '' f; do
    local bname="${f##*/}"
    [[ "$bname" == "_manifest.md" || "$bname" == "STATUS.md" || "$bname" == "CHANGELOG.md" ]] && continue
    md_files+=("$f")
  done < <(find "$dir" -maxdepth 1 -name '*.md' -type f -print0)
  [[ "${#md_files[@]}" -lt 2 ]] && return
  local -a key_sets=()
  local -a file_names=()
  for f in "${md_files[@]}"; do
    file_names+=("$f")
    local keys=""
    keys=$(awk '
      /^---$/ { cnt++; next }
      cnt == 1 && /^[a-z_][a-z_0-9]*:/ { print $1 }
      cnt == 2 { exit }
    ' "$f" 2>/dev/null | sort -u | tr '\n' '|')
    key_sets+=("$keys")
  done
  local ref_set="${key_sets[0]}"
  local ref_name="${file_names[0]}"
  for i in "${!key_sets[@]}"; do
    if [[ "${key_sets[$i]}" != "$ref_set" ]]; then
      add_fail "[PEER-FRONTMATTER] sibling frontmatter key set mismatch: ${file_names[$i]} differs from $ref_name"
      PEER_FM_FAIL_COUNT=$((PEER_FM_FAIL_COUNT + 1))
      [[ "$PEER_FM_FAIL_COUNT" -ge 20 ]] && break
    fi
  done
}

while IFS= read -r -d '' subdir; do
  peer_fm_check_dir "$subdir"
  [[ "$PEER_FM_FAIL_COUNT" -ge 20 ]] && break
done < <(find "$SSOT_DIR" -maxdepth 3 -type d -print0)

if [[ "$PEER_FM_FAIL_COUNT" -eq 0 ]]; then
  add_pass "[PEER-FRONTMATTER] (15J) no sibling frontmatter key-set mismatches"
fi

# ---------- check 14: [NUMBERED-PREFIX] (15K) ordered-directory numbering ----------
NP_FAIL_COUNT=0
# Ordered content paths under architecture/ — domain directories should have NN- prefix
for d in "$SSOT_DIR"/architecture/*/; do
  [[ -d "$d" ]] || continue
  bname=$(basename "$d")
  [[ "$bname" == "views" ]] && continue
  if ! printf '%s' "$bname" | grep -qE '^[0-9]{2}-'; then
    add_fail "[NUMBERED-PREFIX] architecture domain directory missing NN- prefix: $d"
    NP_FAIL_COUNT=$((NP_FAIL_COUNT + 1))
  fi
done

# product/capabilities/ and product/journeys/ files (not README.md, _manifest.md) must have NN- prefix
for ordered_dir in "$SSOT_DIR/product/capabilities" "$SSOT_DIR/product/journeys"; do
  [[ -d "$ordered_dir" ]] || continue
  while IFS= read -r -d '' f; do
    bname=$(basename "$f")
    [[ "$bname" == "README.md" || "$bname" == "_manifest.md" ]] && continue
    if ! printf '%s' "$bname" | grep -qE '^[0-9]{2}-'; then
      add_fail "[NUMBERED-PREFIX] ordered-content file missing NN- prefix: $f"
      NP_FAIL_COUNT=$((NP_FAIL_COUNT + 1))
    fi
    [[ "$NP_FAIL_COUNT" -ge 20 ]] && break
  done < <(find "$ordered_dir" -maxdepth 1 -name '*.md' -type f -print0)
  [[ "$NP_FAIL_COUNT" -ge 20 ]] && break
done

if [[ "$NP_FAIL_COUNT" -eq 0 ]]; then
  add_pass "[NUMBERED-PREFIX] (15K) ordered-directory numbering OK"
fi

# ---------- check 15: [H1-LANGUAGE] (15L) H1 must not be pure English when doc_lang=zh ----------
H1L_WARN_COUNT=0
if [[ -f "$STATUS_FILE" ]]; then
  DOC_LANG=$(grep -oE 'documentation_language[^a-z]*[a-z]+' "$STATUS_FILE" | grep -oE '[a-z]+$' | head -1 || true)
  if [[ "$DOC_LANG" == "zh" ]]; then
    while IFS= read -r -d '' md_file; do
      rel_file="${md_file#"$SSOT_DIR"/}"
      [[ "$rel_file" == .bootstrap/* ]] && continue
      bname=$(basename "$md_file")
      [[ "$bname" == "_manifest.md" || "$bname" == "STATUS.md" || "$bname" == "CHANGELOG.md" ]] && continue
      h1=$(grep -m1 '^# ' "$md_file" || true)
      [[ -z "$h1" ]] && continue
      h1_text="${h1#\# }"
      # Pure English H1 detection: H1 contains only Latin letters, spaces, punctuation, and /- \
      if printf '%s' "$h1_text" | grep -qE '^[A-Za-z0-9 /_.,;:!?()'"'"'"-]+$'; then
        add_warn "[H1-LANGUAGE] H1 appears pure English in zh documentation_language: $md_file -> $h1"
        H1L_WARN_COUNT=$((H1L_WARN_COUNT + 1))
      fi
      [[ "$H1L_WARN_COUNT" -ge 20 ]] && break
    done < <(find "$SSOT_DIR/product" "$SSOT_DIR/architecture" "$SSOT_DIR/development" -name '*.md' -type f -print0 2>/dev/null || true)
  fi
fi
if [[ "$H1L_WARN_COUNT" -eq 0 ]]; then
  add_pass "[H1-LANGUAGE] (15L) no pure-English H1 in zh documentation_language detected"
fi

# ---------- check 16: [INTENT-RECOVERY-UNIFORM] (15M) product/ and architecture/ prose must carry intent_recovery ----------
IR_FAIL_COUNT=0
for ir_dir in "$SSOT_DIR/product" "$SSOT_DIR/architecture"; do
  [[ -d "$ir_dir" ]] || continue
  while IFS= read -r -d '' f; do
    bname=$(basename "$f")
    [[ "$bname" == "_manifest.md" || "$bname" == "STATUS.md" || "$bname" == "CHANGELOG.md" ]] && continue
    if ! head -n 5 "$f" | grep -q 'intent_recovery:'; then
      add_fail "[INTENT-RECOVERY-UNIFORM] prose file missing intent_recovery: frontmatter: $f"
      IR_FAIL_COUNT=$((IR_FAIL_COUNT + 1))
    fi
    [[ "$IR_FAIL_COUNT" -ge 20 ]] && break
  done < <(find "$ir_dir" -name '*.md' -type f -print0)
  [[ "$IR_FAIL_COUNT" -ge 20 ]] && break
done
if [[ "$IR_FAIL_COUNT" -eq 0 ]]; then
  add_pass "[INTENT-RECOVERY-UNIFORM] (15M) product/ and architecture/ prose files carry intent_recovery: frontmatter"
fi

# ---------- check 17: [DIR-MAP-MISSING] (15N) directory README first screen must contain ASCII tree ----------
DM_FAIL_COUNT=0
while IFS= read -r -d '' readme; do
  dir=$(dirname "$readme")
  # Skip SSOT root scaffolding dirs that have their own non-README owners.
  [[ "$(basename "$dir")" == ".bootstrap" ]] && continue
  # Count immediate children (sub-dirs + non-meta .md files) — only enforce when ≥2.
  child_count=$(find "$dir" -mindepth 1 -maxdepth 1 \( -type d -o \( -type f -name '*.md' ! -name '_manifest.md' ! -name 'README.md' ! -name 'STATUS.md' ! -name 'CHANGELOG.md' \) \) 2>/dev/null | wc -l)
  [[ "$child_count" -lt 2 ]] && continue
  # First 60 lines (≈ first terminal screen) must contain a fenced block with
  # at least one tree-drawing glyph (├── or └──). Don't require an exact
  # ``` block — some READMEs use indented code blocks.
  if ! head -n 60 "$readme" | grep -qE '(├──|└──)'; then
    add_fail "[DIR-MAP-MISSING] directory README missing ASCII tree (15N): $readme"
    DM_FAIL_COUNT=$((DM_FAIL_COUNT + 1))
    [[ "$DM_FAIL_COUNT" -ge 20 ]] && break
  fi
done < <(find "$SSOT_DIR" -name 'README.md' -type f -print0 2>/dev/null || true)
if [[ "$DM_FAIL_COUNT" -eq 0 ]]; then
  add_pass "[DIR-MAP-MISSING] (15N) directory README first screens carry ASCII tree map"
fi

# ---------- check 18: [WALKTHROUGH] (15R) architecture domain README needs canonical-flow walkthrough ----------
WT_WARN_COUNT=0
if [[ -d "$SSOT_DIR/architecture" ]]; then
  while IFS= read -r -d '' readme; do
    # Only domain-level READMEs: $SSOT_DIR/architecture/<domain>/README.md.
    parent_dir=$(dirname "$readme")
    grand_dir=$(dirname "$parent_dir")
    [[ "$grand_dir" != "$SSOT_DIR/architecture" ]] && continue
    [[ "$(basename "$parent_dir")" == "views" ]] && continue
    # Must carry intent_recovery: covered in frontmatter.
    head -n 5 "$readme" | grep -q 'intent_recovery:[[:space:]]*covered' || continue
    # Runtime Flows table present and non-empty? Use a heuristic: a heading
    # whose first 6 words contain "Runtime Flows" followed within 25 lines by
    # at least one pipe-table row that is not the header/divider line.
    if awk '
      /^##+ +Runtime [Ff]lows/ { in_section=1; line_count=0; next }
      in_section {
        line_count++
        if (line_count > 25) { in_section=0; next }
        # Skip header row and divider row.
        if ($0 ~ /^\|[ -]+\|/) { next }
        if ($0 ~ /^\| *Flow *\|/) { next }
        # Real data row: starts with | and has at least one non-space cell.
        if ($0 ~ /^\| *[^| ]/) { found=1; exit }
      }
      END { exit (found ? 0 : 1) }
    ' "$readme"; then
      # Must have an H3 walkthrough heading.
      if ! grep -qE '^### +Walkthrough' "$readme"; then
        add_warn "[WALKTHROUGH] (15R) domain README has Runtime Flows but no '### Walkthrough' H3: $readme"
        WT_WARN_COUNT=$((WT_WARN_COUNT + 1))
        [[ "$WT_WARN_COUNT" -ge 20 ]] && break
      fi
    fi
  done < <(find "$SSOT_DIR/architecture" -name 'README.md' -type f -print0 2>/dev/null || true)
fi
if [[ "$WT_WARN_COUNT" -eq 0 ]]; then
  add_pass "[WALKTHROUGH] (15R) architecture domain READMEs with non-empty Runtime Flows carry canonical-flow walkthrough"
fi

# ---------- check 19: [BOUNDARY-DISAMBIG] (15S) owner READMEs need 'Easily confused with' section ----------
BD_WARN_COUNT=0
while IFS= read -r -d '' readme; do
  rel_path="${readme#"$SSOT_DIR/"}"
  # Only check owner-archetype READMEs: top-level area READMEs + architecture domain READMEs.
  # Skip leaf docs and meta files.
  case "$rel_path" in
    README.md|product/README.md|architecture/README.md|architecture/views/README.md|architecture/*/README.md|development/README.md|testing/README.md|release/README.md|deployment/README.md|decisions/README.md|gotchas/README.md|bugs/README.md|tech-debt/README.md|glossary/README.md|01-product/README.md|02-architecture/README.md|02-architecture/views/README.md|02-architecture/*/README.md|03-process/development/README.md|03-process/testing/README.md|03-process/release/README.md|03-process/deployment/README.md)
      ;;
    *) continue ;;
  esac
  if ! grep -qE '^## +Easily confused with' "$readme"; then
    add_warn "[BOUNDARY-DISAMBIG] (15S) owner README missing '## Easily confused with' section: $readme"
    BD_WARN_COUNT=$((BD_WARN_COUNT + 1))
    [[ "$BD_WARN_COUNT" -ge 20 ]] && break
  fi
done < <(find "$SSOT_DIR" -name 'README.md' -type f -print0 2>/dev/null || true)
if [[ "$BD_WARN_COUNT" -eq 0 ]]; then
  add_pass "[BOUNDARY-DISAMBIG] (15S) owner READMEs carry 'Easily confused with' section"
fi

# ---------- check 20: [OUT-OF-SCOPE-LINK] (15T) owner READMEs need 'Out of scope' section ----------
OOS_WARN_COUNT=0
while IFS= read -r -d '' readme; do
  rel_path="${readme#"$SSOT_DIR/"}"
  case "$rel_path" in
    README.md|product/README.md|architecture/README.md|architecture/views/README.md|architecture/*/README.md|development/README.md|testing/README.md|release/README.md|deployment/README.md|decisions/README.md|gotchas/README.md|bugs/README.md|tech-debt/README.md|glossary/README.md|01-product/README.md|02-architecture/README.md|02-architecture/views/README.md|02-architecture/*/README.md|03-process/development/README.md|03-process/testing/README.md|03-process/release/README.md|03-process/deployment/README.md)
      ;;
    *) continue ;;
  esac
  if ! grep -qE '^## +Out of scope' "$readme"; then
    add_warn "[OUT-OF-SCOPE-LINK] (15T) owner README missing '## Out of scope' section: $readme"
    OOS_WARN_COUNT=$((OOS_WARN_COUNT + 1))
    [[ "$OOS_WARN_COUNT" -ge 20 ]] && break
  fi
done < <(find "$SSOT_DIR" -name 'README.md' -type f -print0 2>/dev/null || true)
if [[ "$OOS_WARN_COUNT" -eq 0 ]]; then
  add_pass "[OUT-OF-SCOPE-LINK] (15T) owner READMEs carry 'Out of scope' section"
fi

# ---------- check 21: [DIAGRAM-TYPE-TAG] (15U) Mermaid blocks need diagram_type comment ----------
DT_WARN_COUNT=0
if [[ -d "$SSOT_DIR/architecture" ]]; then
  while IFS= read -r -d '' f; do
    # awk pass: find every ```mermaid ... ``` block; if the next non-blank
    # line inside the fence is not an HTML comment containing diagram_type:, warn.
    awk -v file="$f" '
      /^```mermaid[[:space:]]*$/ { infence=1; tagged=0; lineno=NR; next }
      infence && /^```/ {
        if (!tagged) { print "MISS|" file "|" lineno }
        infence=0; next
      }
      infence {
        # Skip blank lines while still expecting the tag.
        if (!tagged && $0 ~ /^[[:space:]]*$/) { next }
        if (!tagged) {
          if ($0 ~ /<!--[[:space:]]*diagram_type:/) { tagged=1 }
          else { tagged=2 }  # not-tagged-and-already-saw-real-content
        }
      }
    ' "$f" | while IFS='|' read -r status filepath lineno; do
      if [[ "$status" == "MISS" ]]; then
        add_warn "[DIAGRAM-TYPE-TAG] (15U) Mermaid block missing 'diagram_type:' comment: $filepath (fence opened near line $lineno)"
        DT_WARN_COUNT=$((DT_WARN_COUNT + 1))
        [[ "$DT_WARN_COUNT" -ge 20 ]] && break
      fi
    done
  done < <(find "$SSOT_DIR/architecture" -name '*.md' -type f -print0 2>/dev/null || true)
fi
if [[ "$DT_WARN_COUNT" -eq 0 ]]; then
  add_pass "[DIAGRAM-TYPE-TAG] (15U) architecture Mermaid blocks carry diagram_type comment"
fi

# ---------- check 22: [DIAGRAM-FIRST] (15V) architecture domain README needs first-screen diagram ----------
DF_WARN_COUNT=0
if [[ -d "$SSOT_DIR/architecture" ]]; then
  while IFS= read -r -d '' readme; do
    parent_dir=$(dirname "$readme")
    grand_dir=$(dirname "$parent_dir")
    [[ "$grand_dir" != "$SSOT_DIR/architecture" ]] && continue
    [[ "$(basename "$parent_dir")" == "views" ]] && continue
    head -n 5 "$readme" | grep -q 'intent_recovery:[[:space:]]*covered' || continue
    # First 60 lines must contain a ```mermaid fence opener.
    if ! head -n 60 "$readme" | grep -qE '^```mermaid'; then
      add_warn "[DIAGRAM-FIRST] (15V) architecture domain README missing first-screen Mermaid block: $readme"
      DF_WARN_COUNT=$((DF_WARN_COUNT + 1))
      [[ "$DF_WARN_COUNT" -ge 20 ]] && break
    fi
  done < <(find "$SSOT_DIR/architecture" -name 'README.md' -type f -print0 2>/dev/null || true)
fi
if [[ "$DF_WARN_COUNT" -eq 0 ]]; then
  add_pass "[DIAGRAM-FIRST] (15V) architecture domain READMEs carry first-screen Mermaid block"
fi

fi  # end META_LEAKAGE_SKIP_OTHER_CHECKS guard (checks 13-17 also guarded)

# ---------- output ----------
fail_count=${#FAILS[@]}
warn_count=${#WARNS[@]}
pass_count=${#PASSES[@]}

if [[ "$OUTPUT_FORMAT" == "json" ]]; then
  printf '{\n'
  printf '  "ssot_dir": "%s",\n' "$SSOT_DIR"
  printf '  "summary": { "pass": %d, "warn": %d, "fail": %d },\n' "$pass_count" "$warn_count" "$fail_count"
  printf '  "fails": ['
  for i in "${!FAILS[@]}"; do
    [[ $i -gt 0 ]] && printf ','
    printf '\n    %s' "$(printf '%s' "${FAILS[$i]}" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || printf '"%s"' "${FAILS[$i]}")"
  done
  printf '\n  ],\n  "warns": ['
  for i in "${!WARNS[@]}"; do
    [[ $i -gt 0 ]] && printf ','
    printf '\n    %s' "$(printf '%s' "${WARNS[$i]}" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || printf '"%s"' "${WARNS[$i]}")"
  done
  printf '\n  ]\n}\n'
else
  echo "===== SSOT Lint: $SSOT_DIR ====="
  if [[ "$pass_count" -gt 0 ]]; then
    echo ""
    echo "[PASS] $pass_count"
    for msg in "${PASSES[@]}"; do echo "  - $msg"; done
  fi
  if [[ "$warn_count" -gt 0 ]]; then
    echo ""
    echo "[WARN] $warn_count"
    for msg in "${WARNS[@]}"; do echo "  - $msg"; done
  fi
  if [[ "$fail_count" -gt 0 ]]; then
    echo ""
    echo "[FAIL] $fail_count"
    for msg in "${FAILS[@]}"; do echo "  - $msg"; done
  fi
  echo ""
  echo "===== summary: PASS=$pass_count WARN=$warn_count FAIL=$fail_count ====="
fi

# exit code
if [[ "$fail_count" -gt 0 ]]; then
  exit 2
elif [[ "$warn_count" -gt 0 ]]; then
  if [[ "$STRICT_MODE" -eq 1 ]]; then
    exit 2
  else
    exit 1
  fi
else
  exit 0
fi
