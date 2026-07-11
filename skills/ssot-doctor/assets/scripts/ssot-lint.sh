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
#   ./ssot-lint.sh --check-document-quality [SSOT_DIR]
#                                    # only run the v2.59 reader-artifact guards.
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
SSOT_DIR="SSOT"
OUTPUT_FORMAT="text"
STRICT_MODE=0
META_LEAKAGE_ONLY=0
DOCUMENT_QUALITY_ONLY=0
declare -a META_LEAKAGE_DIRS=()
declare -a POSITIONAL_ARGS=()

for arg in "$@"; do
  case "$arg" in
    --json) OUTPUT_FORMAT="json" ;;
    --strict) STRICT_MODE=1 ;;
    --check-meta-leakage) META_LEAKAGE_ONLY=1 ;;
    --check-document-quality) DOCUMENT_QUALITY_ONLY=1 ;;
    --help|-h)
      sed -n '2,28p' "$0"
      exit 0
      ;;
    --*)
      echo "ERROR: unknown option: $arg" >&2
      exit 3
      ;;
    *) POSITIONAL_ARGS+=("$arg") ;;
  esac
done

if [[ "$META_LEAKAGE_ONLY" -eq 1 && "$DOCUMENT_QUALITY_ONLY" -eq 1 ]]; then
  echo "ERROR: --check-meta-leakage and --check-document-quality are mutually exclusive" >&2
  exit 3
fi
if [[ "$META_LEAKAGE_ONLY" -ne 1 && "${#POSITIONAL_ARGS[@]}" -gt 1 ]]; then
  echo "ERROR: expected at most one SSOT_DIR positional argument" >&2
  exit 3
fi
if [[ "$META_LEAKAGE_ONLY" -ne 1 && "${#POSITIONAL_ARGS[@]}" -gt 0 ]]; then
  SSOT_DIR="${POSITIONAL_ARGS[0]}"
fi

# Under --check-meta-leakage, collect every non-flag dir argument as a target
# scope. If none are given we fall back to the resolved product and
# architecture areas (the v2.48 default semantic scope).
if [[ "$META_LEAKAGE_ONLY" -eq 1 ]]; then
  for arg in "${POSITIONAL_ARGS[@]}"; do
    if [[ ! -d "$arg" ]]; then
      echo "ERROR: document-quality/meta-leakage directory not found: $arg" >&2
      exit 3
    fi
    META_LEAKAGE_DIRS+=("$arg")
  done
  if [[ "${#META_LEAKAGE_DIRS[@]}" -gt 0 ]]; then
    # Focused meta scans accept one or more area directories, but protocol
    # waterline comes from their common SSOT root. Never let the first scan
    # directory masquerade as the root and silently disable versioned tokens.
    inferred_root=""
    for target_dir in "${META_LEAKAGE_DIRS[@]}"; do
      target_abs=$(cd "$target_dir" && pwd -P)
      candidate="$target_abs"
      while [[ "$candidate" != "/" && ! -f "$candidate/STATUS.md" ]]; do
        candidate=$(dirname "$candidate")
      done
      if [[ ! -f "$candidate/STATUS.md" ]]; then
        echo "ERROR: cannot infer SSOT root with STATUS.md from meta-leakage target: $target_dir" >&2
        exit 3
      fi
      if [[ -z "$inferred_root" ]]; then
        inferred_root="$candidate"
      elif [[ "$candidate" != "$inferred_root" ]]; then
        echo "ERROR: meta-leakage targets do not share one SSOT root: $inferred_root vs $candidate" >&2
        exit 3
      fi
    done
    SSOT_DIR="$inferred_root"
  fi
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

# Resolve one semantic SSOT area to its physical directory. v2.57 numbered
# paths are canonical and win whenever both shapes exist; legacy unnumbered
# paths remain readable for consumers whose tracked protocol is older.
canonical_area_rel() { # $1=semantic area name
  case "$1" in
    product) printf '01-product\n' ;;
    architecture) printf '02-architecture\n' ;;
    development|testing|benchmark|deployment|release) printf '03-process/%s\n' "$1" ;;
    decisions|gotchas|bugs|tech-debt|research) printf '04-records/%s\n' "$1" ;;
    glossary) printf 'glossary\n' ;;
    *) return 1 ;;
  esac
}

legacy_area_rel() { # $1=semantic area name
  case "$1" in
    product|architecture|development|testing|benchmark|deployment|release|decisions|gotchas|bugs|tech-debt|research|glossary)
      printf '%s\n' "$1"
      ;;
    *) return 1 ;;
  esac
}

resolve_area_dir() { # $1=semantic area name; prints canonical candidate when absent
  local canonical legacy
  canonical=$(canonical_area_rel "$1") || return 1
  legacy=$(legacy_area_rel "$1") || return 1
  if [[ -d "$SSOT_DIR/$canonical" ]]; then
    printf '%s/%s\n' "$SSOT_DIR" "$canonical"
  elif [[ -d "$SSOT_DIR/$legacy" ]]; then
    printf '%s/%s\n' "$SSOT_DIR" "$legacy"
  else
    printf '%s/%s\n' "$SSOT_DIR" "$canonical"
  fi
}

# Print the complete leading YAML frontmatter block, excluding delimiters.
# A fixed head window silently misses valid long blocks and can accidentally
# accept body prose that happens to look like a YAML key.
yaml_frontmatter() { # $1=file
  awk '
    NR == 1 && /^---[[:space:]]*$/ { in_frontmatter=1; next }
    in_frontmatter && /^---[[:space:]]*$/ { exit }
    in_frontmatter { print }
  ' "$1"
}

yaml_field_has_value() { # $1=frontmatter text $2=top-level key
  local frontmatter="$1" key="$2"
  printf '%s\n' "$frontmatter" | awk -v key="$key" '
    function trim(value) {
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      return value
    }
    function meaningful(value) {
      value=trim(value)
      sub(/[[:space:]]+#.*$/, "", value)
      value=trim(value)
      return value != "" && value !~ /^#/ && value !~ /^"[[:space:]]*"$/ && \
        value !~ /^\047[[:space:]]*\047$/ && value !~ /^\[[[:space:]]*\]$/ && \
        value != "null" && value != "~"
    }
    $0 ~ ("^" key ":[[:space:]]*") {
      found=1
      value=$0
      sub(("^" key ":[[:space:]]*"), "", value)
      if (meaningful(value)) {
        valid=1
        exit
      }
      in_block=1
      next
    }
    in_block && /^[a-z_][a-z_0-9-]*:[[:space:]]*/ { exit }
    in_block && /^[[:space:]]*-[[:space:]]*/ {
      value=$0
      sub(/^[[:space:]]*-[[:space:]]*/, "", value)
      if (meaningful(value)) { valid=1; exit }
    }
    END { exit(found && valid ? 0 : 1) }
  '
}

PRODUCT_DIR=$(resolve_area_dir product)
ARCHITECTURE_DIR=$(resolve_area_dir architecture)
DEVELOPMENT_DIR=$(resolve_area_dir development)
TESTING_DIR=$(resolve_area_dir testing)
BENCHMARK_AREA_DIR=$(resolve_area_dir benchmark)
DEPLOYMENT_DIR=$(resolve_area_dir deployment)
RELEASE_DIR=$(resolve_area_dir release)
DECISIONS_DIR=$(resolve_area_dir decisions)
GOTCHAS_DIR=$(resolve_area_dir gotchas)
BUGS_DIR=$(resolve_area_dir bugs)
TECH_DEBT_DIR=$(resolve_area_dir tech-debt)
RESEARCH_AREA_DIR=$(resolve_area_dir research)
GLOSSARY_DIR=$(resolve_area_dir glossary)

# ---------- v2.48 [META-LEAKAGE] (15I) helper ----------
# Greps product / architecture prose files for SSOT self-maintenance machinery
# that v2.48 hoists to sibling `_manifest.md`. Always FAIL; tokens are
# mechanically decidable. Called once per target directory; populates the
# global FAILS array via add_fail.
#
# Scope exclusions: `_manifest.md` itself, `STATUS.md`, `CHANGELOG.md`, anything
# under `decisions/` or `tech-debt/`.
META_LEAKAGE_TOKENS_BASE='\[CORE-REF-PROSE\]|\[MAXIM-OWNER\]|\[INTENT-OWNER\]|\[INTENT-TRUTH-NARRATIVE\]|\[CORE-COVERAGE-MAP\]|\[VOCAB-PROSE-FORK\]|\[WORKFLOW-STATE-VOCAB\]|\[INTENT-RECOVERY\]|\[META-LEAKAGE\]|(^|[^0-9A-Za-z])(14W|14X|14Y|14Z|15A|15B|15C|15D|15F|15G|15H|15I)([^0-9A-Za-z]|$)|(^|[^0-9A-Za-z])v2\.(43|44|45|46|47|48)([^0-9]|$)|product_intent \+ product_truth|design_intent \+ design_truth|必备 pillar|intent_recovery_pillars|intent_recovery_evidence:[[:space:]]*"|本 README 自身的可恢复性失败模式|本节正文回流|Apex-Maxim → Owner 索引|^##[[:space:]]+核心恢复清单|^##[[:space:]]+Capability → Surface registry'
META_LEAKAGE_TOKENS_V259='ssot-bootstrap|SKILL_STYLE|[Dd]octor[[:space:]]+(row[[:space:]]+)?[0-9]+[A-Z]?'

check_meta_leakage_dir() {
  local target_dir="$1"
  local hit_count=0
  local meta_leakage_tokens="$META_LEAKAGE_TOKENS_BASE" status_version=""
  if [[ -f "$SSOT_DIR/STATUS.md" ]]; then
    status_version=$(grep -E '(\|\s*tracked_skill_version\s*\||^tracked_skill_version:)' "$SSOT_DIR/STATUS.md" | head -n 1 | grep -oE '[0-9]+\.[0-9]+' | head -n 1 || true)
  fi
  if [[ "$DOCUMENT_QUALITY_ONLY" -eq 1 ]] || { [[ -n "$status_version" ]] && version_ge "$status_version" "2.59"; }; then
    meta_leakage_tokens="$meta_leakage_tokens|$META_LEAKAGE_TOKENS_V259"
  fi
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
    hit=$(grep -nE "$meta_leakage_tokens" "$md_file" 2>/dev/null | head -3 || true)
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

# ---------- v2.59 reader-artifact quality helpers ----------
# These checks are deliberately structural. They do not pretend to replace a
# cold-reader review; they prevent the known false-positive shape where a
# covered area is only headings, tables, placeholders, or protocol machinery.
document_quality_active() {
  [[ "$DOCUMENT_QUALITY_ONLY" -eq 1 ]] && return 0
  local status_file="$SSOT_DIR/STATUS.md" version
  [[ -f "$status_file" ]] || return 1
  version=$(grep -E '(\|\s*tracked_skill_version\s*\||^tracked_skill_version:)' "$status_file" | head -n 1 | grep -oE '[0-9]+\.[0-9]+' | head -n 1 || true)
  [[ -n "$version" ]] && version_ge "$version" "2.59"
}

document_area_is_covered() { # $1=product|architecture
  [[ -f "$SSOT_DIR/STATUS.md" ]] || return 1
  grep -qE "^\|[[:space:]]*$1[[:space:]]*\|[[:space:]]*covered[[:space:]]*\|" "$SSOT_DIR/STATUS.md"
}

directory_has_reader_children() { # $1=directory
  find "$1" -mindepth 1 -maxdepth 1 -type f -name '*.md' \
    ! -name 'README.md' ! -name '_manifest.md' -print -quit 2>/dev/null | grep -q .
}

expected_manifest_archetype() { # $1=manifest path
  local manifest="$1" parent grand
  parent=$(dirname "$manifest")
  grand=$(dirname "$parent")
  if [[ "$manifest" == "$PRODUCT_DIR/_manifest.md" ]]; then
    printf 'product-root\n'
  elif [[ "$parent" == "$PRODUCT_DIR/capabilities" || "$parent" == "$PRODUCT_DIR/journeys" ]]; then
    printf 'product-collection\n'
  elif [[ "$manifest" == "$ARCHITECTURE_DIR/_manifest.md" ]]; then
    printf 'architecture-root\n'
  elif [[ "$parent" == "$ARCHITECTURE_DIR/views" ]]; then
    printf 'architecture-views\n'
  elif [[ "$grand" == "$ARCHITECTURE_DIR" ]]; then
    printf 'architecture-domain\n'
  else
    printf 'unknown\n'
  fi
}

check_required_manifest() { # $1=directory $2=archetype
  local dir="$1" archetype="$2" manifest="$1/_manifest.md"
  [[ -d "$dir" ]] || return 0
  if [[ ! -f "$manifest" ]]; then
    add_fail "[MANIFEST-COMPLETENESS] covered reader area is missing $archetype manifest: $manifest"
  fi
}

# Print only the archetype's required recovery table. This prevents an
# unrelated evidence or lifecycle table from satisfying the minimum-row gate.
manifest_primary_table() { # $1=manifest $2=archetype
  awk -v archetype="$2" '
    function is_header(line, lower) {
      lower=tolower(line)
      if (archetype == "product-root")
        return (lower ~ /required product question/ || line ~ /必答产品问题/) && \
          (lower ~ /narrative owner/ || line ~ /叙事所有者/) && \
          (lower ~ /recovery coverage/ || line ~ /恢复覆盖/) && \
          (lower ~ /product maturity/ || line ~ /产品成熟度/) && \
          (lower ~ /evidence fidelity/ || line ~ /证据保真度/)
      if (archetype == "product-collection")
        return (lower ~ /child owner/ || line ~ /子所有者/) && \
          (lower ~ /recovery coverage/ || line ~ /恢复覆盖/) && \
          (lower ~ /product maturity/ || line ~ /产品成熟度/) && \
          (lower ~ /evidence fidelity/ || line ~ /证据保真度/)
      if (archetype == "architecture-root")
        return (lower ~ /required architecture question/ || line ~ /必答架构问题/) && \
          (lower ~ /narrative owner/ || line ~ /叙事所有者/) && \
          (lower ~ /(recovery|coverage)/ || line ~ /恢复|覆盖/) && \
          (lower ~ /evidence/ || line ~ /证据/)
      if (archetype == "architecture-views")
        return (lower ~ /question class/ || line ~ /问题类别/) && \
          (lower ~ /narrative owner/ || line ~ /叙事所有者/) && \
          (lower ~ /(recovery|coverage)/ || line ~ /恢复|覆盖/) && \
          (lower ~ /evidence/ || line ~ /证据/)
      if (archetype == "architecture-domain")
        return (lower ~ /required owner question/ || line ~ /所有者必答问题/) && \
          (lower ~ /narrative owner/ || line ~ /叙事所有者/) && \
          (lower ~ /(recovery|coverage)/ || line ~ /恢复|覆盖/) && \
          (lower ~ /evidence/ || line ~ /证据/)
      return 0
    }
    !active && /^\|/ && is_header($0) { active=1; print; next }
    active && /^\|/ { print; next }
    active { exit }
  ' "$1"
}

manifest_has_resolved_review_pointer() { # $1=manifest
  local manifest="$1" line target resolved project_root
  while IFS= read -r line; do
    target=$(printf '%s\n' "$line" | sed -nE 's@.*\]\(([^) #]+\.md)(#[^)]*)?\).*@\1@p')
    if [[ -z "$target" ]]; then
      target=$(printf '%s\n' "$line" | grep -oE '`[^`]+\.md(#[^`]*)?`' | head -1 | tr -d '`' || true)
      target="${target%%#*}"
    fi
    [[ -n "$target" ]] || continue
    case "$target" in
      /*) resolved="$target" ;;
      SSOT/*)
        project_root=$(cd "$(dirname "$SSOT_DIR")" && pwd -P)
        resolved="$project_root/$target"
        ;;
      *) resolved="$(dirname "$manifest")/$target" ;;
    esac
    if [[ -f "$resolved" ]] && grep -qi 'no-more-required-changes' "$resolved"; then
      return 0
    fi
  done < <(grep -i 'no-more-required-changes' "$manifest" || true)
  return 1
}

check_document_quality() {
  document_quality_active || return 0

  # Covered roots and non-empty reader collections need the manifest archetype
  # that matches their ownership level. Empty bootstrap directories are exempt.
  document_area_is_covered product && check_required_manifest "$PRODUCT_DIR" product-root
  document_area_is_covered architecture && check_required_manifest "$ARCHITECTURE_DIR" architecture-root
  for collection in "$PRODUCT_DIR/capabilities" "$PRODUCT_DIR/journeys"; do
    [[ -d "$collection" ]] && directory_has_reader_children "$collection" && \
      check_required_manifest "$collection" product-collection
  done
  if [[ -d "$ARCHITECTURE_DIR/views" ]] && directory_has_reader_children "$ARCHITECTURE_DIR/views"; then
    check_required_manifest "$ARCHITECTURE_DIR/views" architecture-views
  fi
  if [[ -d "$ARCHITECTURE_DIR" ]]; then
    while IFS= read -r -d '' domain; do
      [[ "$(basename "$domain")" == "views" ]] && continue
      [[ -f "$domain/README.md" ]] && check_required_manifest "$domain" architecture-domain
    done < <(find "$ARCHITECTURE_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)
  fi

  local manifest_count=0 manifest_fail_count=0
  while IFS= read -r -d '' manifest; do
    manifest_count=$((manifest_count + 1))
    local expected declared recovery_state manifest_frontmatter declared_count recovery_count
    local empty_row required_rows minimum_rows primary_table area_covered=0
    expected=$(expected_manifest_archetype "$manifest")
    manifest_frontmatter=$(yaml_frontmatter "$manifest")
    declared_count=$(printf '%s\n' "$manifest_frontmatter" | grep -Ec '^manifest_archetype:[[:space:]]*' || true)
    recovery_count=$(printf '%s\n' "$manifest_frontmatter" | grep -Ec '^intent_recovery:[[:space:]]*' || true)
    declared=$(printf '%s\n' "$manifest_frontmatter" | grep -E '^manifest_archetype:[[:space:]]*' | head -1 | sed -E 's/^manifest_archetype:[[:space:]]*//' | tr -d '`"' || true)
    recovery_state=$(printf '%s\n' "$manifest_frontmatter" | grep -E '^intent_recovery:[[:space:]]*' | head -1 | sed -E 's/^intent_recovery:[[:space:]]*//' | tr -d '`"' || true)
    case "$manifest" in
      "$PRODUCT_DIR"/*) document_area_is_covered product && area_covered=1 ;;
      "$ARCHITECTURE_DIR"/*) document_area_is_covered architecture && area_covered=1 ;;
    esac
    if [[ "$declared_count" -ne 1 || "$recovery_count" -ne 1 ]]; then
      add_fail "[MANIFEST-COMPLETENESS] manifest frontmatter must declare exactly one manifest_archetype and one intent_recovery key: $manifest (manifest_archetype=$declared_count intent_recovery=$recovery_count)"
      manifest_fail_count=$((manifest_fail_count + 1))
    fi
    if [[ -z "$declared" || "$expected" == "unknown" || "$declared" != "$expected" ]]; then
      add_fail "[MANIFEST-COMPLETENESS] manifest archetype mismatch: $manifest (expected=$expected declared=${declared:-missing})"
      manifest_fail_count=$((manifest_fail_count + 1))
    fi
    if [[ ! "$recovery_state" =~ ^(gap|partial|covered)$ ]]; then
      add_fail "[MANIFEST-COMPLETENESS] manifest needs intent_recovery: gap|partial|covered in YAML frontmatter: $manifest"
      manifest_fail_count=$((manifest_fail_count + 1))
    elif [[ "$area_covered" -eq 1 && "$recovery_state" != "covered" ]]; then
      add_fail "[MANIFEST-COMPLETENESS] covered area has a non-covered manifest: $manifest (intent_recovery=$recovery_state)"
      manifest_fail_count=$((manifest_fail_count + 1))
    fi
    if grep -qiE '<!--[[:space:]]*(TODO|TBD)|(^|[^A-Za-z])(TODO|TBD|FIXME)([^A-Za-z]|$)|待补充|（待补充）' "$manifest"; then
      add_fail "[MANIFEST-COMPLETENESS] manifest contains unresolved placeholder text: $manifest"
      manifest_fail_count=$((manifest_fail_count + 1))
    fi
    empty_row=$(awk '
      /^\|/ && $0 !~ /^\|[[:space:]:|-]+\|[[:space:]:|-]+/ && $0 ~ /\|[[:space:]]*\|/ { print FNR; exit }
    ' "$manifest")
    if [[ -n "$empty_row" ]]; then
      add_fail "[MANIFEST-COMPLETENESS] manifest table has an empty required cell: $manifest:$empty_row"
      manifest_fail_count=$((manifest_fail_count + 1))
    fi
    minimum_rows=0
    case "$declared" in
      product-root|architecture-root|architecture-domain) minimum_rows=5 ;;
      architecture-views) minimum_rows=6 ;;
      product-collection) minimum_rows=1 ;;
    esac
    primary_table=$(manifest_primary_table "$manifest" "$declared")
    required_rows=$(printf '%s\n' "$primary_table" | awk '
      NR <= 2 { next }
      /^\|/ { rows++ }
      END { print rows + 0 }
    ')
    if (( minimum_rows > 0 )) && [[ -z "$primary_table" ]]; then
      add_fail "[MANIFEST-COMPLETENESS] $declared manifest is missing its archetype-specific recovery table header: $manifest"
      manifest_fail_count=$((manifest_fail_count + 1))
    fi
    if (( minimum_rows > 0 && required_rows < minimum_rows )); then
      add_fail "[MANIFEST-COMPLETENESS] $declared manifest has too few completed recovery rows: $manifest (rows=$required_rows minimum=$minimum_rows)"
      manifest_fail_count=$((manifest_fail_count + 1))
    fi
    if [[ "$recovery_state" == "covered" ]]; then
      if grep -q '<!--' "$manifest"; then
        add_fail "[MANIFEST-COMPLETENESS] covered manifest still contains template/author comments: $manifest"
        manifest_fail_count=$((manifest_fail_count + 1))
      fi
      if grep -qiE '\|[[:space:]]*(gap|missing|unresolved|not-run|needs-review|not-scored|not_assessed|pending|unknown)[[:space:]]*\|' "$manifest"; then
        add_fail "[MANIFEST-COMPLETENESS] covered manifest still contains incomplete recovery state cells: $manifest"
        manifest_fail_count=$((manifest_fail_count + 1))
      fi
      if grep -qiE '(not yet recorded|no .* recorded yet|尚未(记录|采样|审查)|未记录|未采样)' "$manifest"; then
        add_fail "[MANIFEST-COMPLETENESS] covered manifest still contains unresolved handoff text: $manifest"
        manifest_fail_count=$((manifest_fail_count + 1))
      fi
      if grep -qE '<[^>]+>|(^|[^[:alnum:]_])(path/to|src/path|tests/path|NN-<domain>)([^[:alnum:]_]|$)' "$manifest"; then
        add_fail "[MANIFEST-COMPLETENESS] covered manifest still contains placeholder paths or angle-bracket handoff values: $manifest"
        manifest_fail_count=$((manifest_fail_count + 1))
      fi
      if ! manifest_has_resolved_review_pointer "$manifest"; then
        add_fail "[MANIFEST-COMPLETENESS] covered manifest lacks a no-more-required-changes verdict linked to an existing Markdown review artifact: $manifest"
        manifest_fail_count=$((manifest_fail_count + 1))
      fi
      case "$declared" in
        product-root)
          for required_pattern in 'prd\.md' 'product-model\.md' 'capabilities/README\.md' 'journeys/README\.md' 'roadmap-and-acceptance\.md'; do
            if ! printf '%s\n' "$primary_table" | grep -qiE "$required_pattern"; then
              add_fail "[MANIFEST-COMPLETENESS] product-root manifest misses required product spine owner '$required_pattern': $manifest"
              manifest_fail_count=$((manifest_fail_count + 1))
            fi
          done
          if grep -qiE '\|[[:space:]]*(mixed|contract|design|poc|debt)[[:space:]]*\|' "$manifest"; then
            add_fail "[MANIFEST-COMPLETENESS] covered product manifest uses architecture state as product maturity: $manifest"
            manifest_fail_count=$((manifest_fail_count + 1))
          fi
          ;;
        product-collection)
          if ! printf '%s\n' "$primary_table" | grep -qE '\]\(\./[0-9]{2}-[^)]+\.md\)' ||
             ! printf '%s\n' "$primary_table" | grep -qiE '(product maturity|产品成熟度)' ||
             ! printf '%s\n' "$primary_table" | grep -qiE '(evidence fidelity|证据保真度)'; then
            add_fail "[MANIFEST-COMPLETENESS] product-collection manifest must index numbered child owners with product maturity and evidence fidelity: $manifest"
            manifest_fail_count=$((manifest_fail_count + 1))
          fi
          ;;
        architecture-root)
          for required_pattern in 'views/README\.md' '(runtime owner|运行时[[:space:]]*(owner|所有者))' '(invariant|不变量)' '(context|上下文|系统边界)'; do
            if ! printf '%s\n' "$primary_table" | grep -qiE "$required_pattern"; then
              add_fail "[MANIFEST-COMPLETENESS] architecture-root manifest misses required recovery class '$required_pattern': $manifest"
              manifest_fail_count=$((manifest_fail_count + 1))
            fi
          done
          if ! grep -qiE 'current-target-gap\.md' "$manifest"; then
            add_fail "[MANIFEST-COMPLETENESS] architecture-root manifest misses required recovery class 'current-target-gap\\.md': $manifest"
            manifest_fail_count=$((manifest_fail_count + 1))
          fi
          if ! printf '%s\n' "$primary_table" | grep -qE '\]\(\./[0-9]{2}-[^/)]+/README\.md\)'; then
            add_fail "[MANIFEST-COMPLETENESS] architecture-root manifest does not index any direct numbered runtime-owner domain: $manifest"
            manifest_fail_count=$((manifest_fail_count + 1))
          fi
          ;;
        architecture-views)
          for required_pattern in 'operating-model\.md' 'critical-journeys\.md' 'state-and-data-lifecycle\.md' 'contracts-and-trust-boundaries\.md' 'failure-and-recovery\.md' 'current-target-gap\.md'; do
            if ! printf '%s\n' "$primary_table" | grep -qiE "$required_pattern"; then
              add_fail "[MANIFEST-COMPLETENESS] architecture-views manifest misses required view or reasoned not_applicable row '$required_pattern': $manifest"
              manifest_fail_count=$((manifest_fail_count + 1))
            fi
          done
          ;;
        architecture-domain)
          for required_pattern in '(boundary|边界)' '(state|resource|状态|资源)' '(contract|trust|契约|信任)' '(flow|journey|流程|旅程)' '(failure|recovery|失败|恢复)'; do
            if ! printf '%s\n' "$primary_table" | grep -qiE "$required_pattern"; then
              add_fail "[MANIFEST-COMPLETENESS] architecture-domain manifest misses required recovery class '$required_pattern': $manifest"
              manifest_fail_count=$((manifest_fail_count + 1))
            fi
          done
          ;;
      esac
    fi
    local forbidden_pattern=""
    case "$declared" in
      product-root) forbidden_pattern='^##[[:space:]]+(Apex|Maxim|Runtime surface registry|Domain symbol inventory|顶层规则|最高规则|运行时表面注册表|领域符号清单)' ;;
      product-collection) forbidden_pattern='^##[[:space:]]+(Apex|Maxim|Runtime Owner Map|Global invariants|Core product spine|顶层规则|最高规则|运行时所有者图|全局不变量|产品主干)' ;;
      architecture-root) forbidden_pattern='^##[[:space:]]+(Child symbol inventory|Domain-local flows|子项符号清单|领域局部流程)' ;;
      architecture-views) forbidden_pattern='^##[[:space:]]+(Apex|Maxim|Domain symbol inventory|Capability surface registry|顶层规则|最高规则|领域符号清单|能力表面注册表)' ;;
      architecture-domain) forbidden_pattern='^##[[:space:]]+(Apex|Maxim|Global invariant registry|Capability surface registry|顶层规则|最高规则|全局不变量注册表|能力表面注册表)' ;;
    esac
    if [[ -n "$forbidden_pattern" ]] && grep -qiE "$forbidden_pattern" "$manifest"; then
      add_fail "[MANIFEST-COMPLETENESS] $declared manifest contains machinery owned by another level: $manifest"
      manifest_fail_count=$((manifest_fail_count + 1))
    fi
  done < <(find "$PRODUCT_DIR" "$ARCHITECTURE_DIR" -name '_manifest.md' -type f -print0 2>/dev/null || true)
  if [[ "$manifest_fail_count" -eq 0 ]]; then
    add_pass "v2.59 reader manifests use complete location-specific archetypes"
  fi

  # A covered reader file needs at least two real prose paragraphs. Headings,
  # tables, lists, comments, and fenced examples do not count as explanation.
  local narrative_fail_count=0 density_warn_count=0
  while IFS= read -r -d '' reader_file; do
    [[ "$(basename "$reader_file")" == "_manifest.md" ]] && continue
    local body_frontmatter body_recovery body_area_covered=0
    body_frontmatter=$(yaml_frontmatter "$reader_file")
    body_recovery=$(printf '%s\n' "$body_frontmatter" | grep -E '^intent_recovery:[[:space:]]*' | head -1 | sed -E 's/^intent_recovery:[[:space:]]*//' | tr -d '`"' || true)
    case "$reader_file" in
      "$PRODUCT_DIR"/*) document_area_is_covered product && body_area_covered=1 ;;
      "$ARCHITECTURE_DIR"/*) document_area_is_covered architecture && body_area_covered=1 ;;
    esac
    if [[ "$body_area_covered" -eq 1 && "$body_recovery" != "covered" ]]; then
      add_fail "[NARRATIVE-SUFFICIENCY] covered area has a reader file whose intent_recovery is ${body_recovery:-missing}: $reader_file"
      narrative_fail_count=$((narrative_fail_count + 1))
      continue
    fi
    [[ "$body_recovery" == "covered" ]] || continue
    local prose_stats paragraphs prose_chars line_stats body_lines table_lines
    prose_stats=$(awk '
      function flush() {
        if (block_chars >= 20) { paragraphs++; prose_chars += block_chars }
        block_chars=0
      }
      NR==1 && /^---[[:space:]]*$/ { front=1; next }
      front && /^---[[:space:]]*$/ { front=0; next }
      front { next }
      /^```/ { flush(); code=!code; next }
      code { next }
      /<!--[[:space:]]*/ { flush(); comment=1 }
      comment { if ($0 ~ /-->/) comment=0; next }
      /^[[:space:]]*$/ { flush(); next }
      /^#/ || /^\|/ || /^[[:space:]]*[-*+] / || /^[[:space:]]*[0-9]+\. / { flush(); next }
      { line=$0; gsub(/[[:space:]]/, "", line); block_chars += length(line) }
      END { flush(); print paragraphs ":" prose_chars }
    ' "$reader_file")
    paragraphs=${prose_stats%%:*}
    prose_chars=${prose_stats#*:}
    if (( paragraphs < 2 || prose_chars < 80 )); then
      add_fail "[NARRATIVE-SUFFICIENCY] covered reader file needs at least two explanatory prose paragraphs (found paragraphs=$paragraphs prose_chars=$prose_chars): $reader_file"
      narrative_fail_count=$((narrative_fail_count + 1))
    fi
    line_stats=$(awk '
      NR==1 && /^---[[:space:]]*$/ { front=1; next }
      front && /^---[[:space:]]*$/ { front=0; next }
      front || /^[[:space:]]*$/ { next }
      { body++ }
      /^\|/ { table++ }
      END { print body ":" table }
    ' "$reader_file")
    body_lines=${line_stats%%:*}
    table_lines=${line_stats#*:}
    if (( table_lines >= 15 && body_lines > 0 && table_lines * 100 >= body_lines * 35 )); then
      add_warn "[KISS-TABLE-DENSITY] reader file is compact but table-dominant; move reference inventory after a self-contained explanation or into the manifest: $reader_file (table=$table_lines body=$body_lines)"
      density_warn_count=$((density_warn_count + 1))
    fi
  done < <(find "$PRODUCT_DIR" "$ARCHITECTURE_DIR" -name '*.md' -type f -print0 2>/dev/null || true)
  [[ "$narrative_fail_count" -eq 0 ]] && add_pass "[NARRATIVE-SUFFICIENCY] covered product/architecture files contain explanatory prose"
  [[ "$density_warn_count" -eq 0 ]] && add_pass "[KISS-TABLE-DENSITY] no covered reader file is dominated by compact reference tables"

  # Architecture domains are where readers most need a boundary picture. A
  # covered v2.59 domain without one is a false covered claim, not a warning.
  local diagram_fail_count=0
  if [[ -d "$ARCHITECTURE_DIR" ]]; then
    while IFS= read -r -d '' readme; do
      local parent_dir grand_dir first_table first_mermaid diagram_info diagram_type
      parent_dir=$(dirname "$readme")
      grand_dir=$(dirname "$parent_dir")
      [[ "$grand_dir" != "$ARCHITECTURE_DIR" || "$(basename "$parent_dir")" == "views" ]] && continue
      head -n 6 "$readme" | grep -qE '^intent_recovery:[[:space:]]*covered' || continue
      first_table=$(grep -nE '^\|' "$readme" | head -1 | cut -d: -f1 || true)
      diagram_info=$(awk '
        /^```mermaid[[:space:]]*$/ { fence=NR; inside=1; next }
        inside && /^[[:space:]]*$/ { next }
        inside {
          if ($0 ~ /^[[:space:]]*<!--[[:space:]]*diagram_type:[[:space:]]*component[[:space:]]*-->[[:space:]]*$/)
            print fence "|component"
          else
            print fence "|wrong-or-missing"
          exit
        }
      ' "$readme")
      first_mermaid=${diagram_info%%|*}
      diagram_type=${diagram_info#*|}
      if [[ -z "$diagram_info" || "$diagram_type" != "component" || "$first_mermaid" -gt 60 || ( -n "$first_table" && "$first_mermaid" -gt "$first_table" ) ]]; then
        add_fail "[DIAGRAM-FIRST] (15V) covered architecture domain needs a Mermaid component/boundary diagram tagged '<!-- diagram_type: component -->' within 60 lines and before its first table: $readme"
        diagram_fail_count=$((diagram_fail_count + 1))
      fi
    done < <(find "$ARCHITECTURE_DIR" -name 'README.md' -type f -print0 2>/dev/null || true)
  fi
  [[ "$diagram_fail_count" -eq 0 ]] && add_pass "[DIAGRAM-FIRST] (15V) covered architecture domains teach the boundary before reference tables"

  # Root coverage cannot be declared while the default reader route is absent.
  local surface_fail_count=0 required
  surface_exception_present() { # $1=root manifest $2=relative path
    local manifest="$1" rel="$2" stem
    [[ -f "$manifest" ]] || return 1
    stem=$(basename "$rel" .md)
    grep -qiE "\|[^|]*(${rel//\//\\/}|$stem)[^|]*\|[^|]*not_applicable[^|]*\|[^|]{5,}" "$manifest"
  }
  if document_area_is_covered product; then
    for required in README.md prd.md product-model.md roadmap-and-acceptance.md capabilities/README.md journeys/README.md; do
      if [[ ! -f "$PRODUCT_DIR/$required" ]] && ! surface_exception_present "$PRODUCT_DIR/_manifest.md" "$required"; then
        add_fail "[SURFACE-COVERAGE] covered product area is missing default reader surface: $PRODUCT_DIR/$required"
        surface_fail_count=$((surface_fail_count + 1))
      fi
    done
  fi
  if document_area_is_covered architecture; then
    for required in README.md views/README.md views/operating-model.md views/critical-journeys.md views/current-target-gap.md views/state-and-data-lifecycle.md views/contracts-and-trust-boundaries.md views/failure-and-recovery.md; do
      if [[ ! -f "$ARCHITECTURE_DIR/$required" ]] && ! surface_exception_present "$ARCHITECTURE_DIR/_manifest.md" "$required"; then
        add_fail "[SURFACE-COVERAGE] covered architecture area is missing default reader surface: $ARCHITECTURE_DIR/$required"
        surface_fail_count=$((surface_fail_count + 1))
      fi
    done
  fi
  [[ "$surface_fail_count" -eq 0 ]] && add_pass "[SURFACE-COVERAGE] covered product/architecture roots expose the v2.59 default reader route"

  # Normal lint already runs the shared meta-leakage check later. Focused mode
  # skips the normal suite, so it invokes the same helper here.
  if [[ "$DOCUMENT_QUALITY_ONLY" -eq 1 ]]; then
    check_meta_leakage_dir "$PRODUCT_DIR"
    check_meta_leakage_dir "$ARCHITECTURE_DIR"
  fi
}

# Run a focused mode, or include document quality in the normal v2.59 lint.
if [[ "$DOCUMENT_QUALITY_ONLY" -eq 1 ]]; then
  check_document_quality
  META_LEAKAGE_SKIP_OTHER_CHECKS=1
elif [[ "$META_LEAKAGE_ONLY" -eq 1 ]]; then
  if [[ "${#META_LEAKAGE_DIRS[@]}" -eq 0 ]]; then
    [[ -d "$PRODUCT_DIR" ]] && META_LEAKAGE_DIRS+=("$PRODUCT_DIR")
    [[ -d "$ARCHITECTURE_DIR" ]] && META_LEAKAGE_DIRS+=("$ARCHITECTURE_DIR")
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
  check_document_quality
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

# ---------- check 1b: v2.57 canonical physical layout ----------
# Legacy directories remain readable below the v2.57 waterline. Once the
# consumer records 2.57+, the migration must already be complete; otherwise
# canonical-first resolution would hide a mixed-layout conflict.
if [[ -f "$STATUS_FILE" && -n "$STATUS_SKILL_VERSION" ]] && version_ge "$STATUS_SKILL_VERSION" "2.57"; then
  FACETED_LAYOUT_FAIL_COUNT=0
  for area in product architecture development testing benchmark deployment release decisions gotchas bugs tech-debt research; do
    legacy_rel=$(legacy_area_rel "$area")
    canonical_rel=$(canonical_area_rel "$area")
    if [[ -d "$SSOT_DIR/$legacy_rel" ]]; then
      add_fail "[FACETED-LAYOUT] tracked_skill_version=$STATUS_SKILL_VERSION still has legacy area $SSOT_DIR/$legacy_rel; migrate it to $SSOT_DIR/$canonical_rel before advancing the waterline"
      FACETED_LAYOUT_FAIL_COUNT=$((FACETED_LAYOUT_FAIL_COUNT + 1))
    fi
  done
  for required_owner in "01-product/README.md" "02-architecture/README.md"; do
    if [[ ! -f "$SSOT_DIR/$required_owner" ]]; then
      add_fail "[FACETED-LAYOUT] tracked_skill_version=$STATUS_SKILL_VERSION requires canonical owner $SSOT_DIR/$required_owner"
      FACETED_LAYOUT_FAIL_COUNT=$((FACETED_LAYOUT_FAIL_COUNT + 1))
    fi
  done
  if [[ -d "$SSOT_DIR/02-architecture/domains" ]]; then
    add_fail "[FACETED-LAYOUT] v2.57+ architecture domains must be direct numbered children of $SSOT_DIR/02-architecture, not $SSOT_DIR/02-architecture/domains"
    FACETED_LAYOUT_FAIL_COUNT=$((FACETED_LAYOUT_FAIL_COUNT + 1))
  fi
  if [[ "$FACETED_LAYOUT_FAIL_COUNT" -eq 0 ]]; then
    add_pass "[FACETED-LAYOUT] v2.57+ consumer has no legacy unnumbered area directories"
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
for entry_dir in "$BUGS_DIR" "$TECH_DEBT_DIR"; do
  if [[ -d "$entry_dir" ]]; then
    missing_count=0
    while IFS= read -r -d '' entry_file; do
      filename=$(basename "$entry_file")
      # README.md is exempt from frontmatter
      [[ "$filename" == "README.md" ]] && continue
      # Only inspect numbered-prefix entry files
      [[ ! "$filename" =~ ^[0-9]{4}-.+\.md$ ]] && continue
      # First 3 lines must contain YAML frontmatter opener ---
      if ! head -n 3 "$entry_file" | grep -qE '^---$'; then
        add_warn "$(basename "$entry_dir") entry missing YAML frontmatter: $entry_file"
        missing_count=$((missing_count + 1))
      fi
    done < <(find "$entry_dir" -name '*.md' -type f -print0)
    if [[ "$missing_count" -eq 0 ]]; then
      add_pass "$(basename "$entry_dir") entries: frontmatter complete"
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
  [[ "$md_file" == "$TESTING_DIR"/* ]] && continue
  [[ "$md_file" == "$BUGS_DIR"/[0-9][0-9][0-9][0-9]-*.md ]] && continue
  [[ "$md_file" == "$DECISIONS_DIR"/[0-9][0-9][0-9][0-9]-*.md ]] && continue
  [[ "$md_file" == "$RELEASE_DIR"/* ]] && continue
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
for entry_dir in "$BUGS_DIR" "$TECH_DEBT_DIR"; do
  if [[ -d "$entry_dir" ]]; then
    while IFS= read -r -d '' entry_file; do
      filename=$(basename "$entry_file")
      [[ "$filename" == "README.md" ]] && continue
      [[ ! "$filename" =~ ^[0-9]{4}-.+\.md$ ]] && continue
      entry_head=$(head -n 40 "$entry_file")
      if ! printf '%s\n' "$entry_head" | grep -qiE '^(status:[[:space:]]*(active|recurred)|severity:[[:space:]]*(critical|major)|priority:[[:space:]]*high)'; then
        continue
      fi
      if ! head -n 80 "$entry_file" | grep -qiE '(Agent quick entry|Quick entry|Agent 快速入口|快速入口)'; then
        add_warn "[ENTRY-ACTIONABILITY] numbered $(basename "$entry_dir") entry lacks a quick-entry surface for future agents: $entry_file"
        entry_actionability_warn_count=$((entry_actionability_warn_count + 1))
      fi
      [[ "$entry_actionability_warn_count" -ge 20 ]] && break 2
    done < <(find "$entry_dir" -name '*.md' -type f -print0)
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
    elif [[ "$rel_trunk" == "$A_TRUNK"/* ]]; then
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
if [[ -d "$PRODUCT_DIR" ]]; then
  while IFS= read -r -d '' product_file; do
    if grep -qiE '^##[[:space:]].*(runtime flow|API reference|SDK reference|schema reference|implementation details|database schema)' "$product_file"; then
      add_warn "[PRODUCT-ARCH-DRIFT] product file appears to own runtime/API/SDK/schema implementation detail instead of linking architecture owner: $product_file"
      product_arch_warn_count=$((product_arch_warn_count + 1))
    fi
    [[ "$product_arch_warn_count" -ge 20 ]] && break
  done < <(find "$PRODUCT_DIR" -name '*.md' -type f -print0)
fi
if [[ -d "$ARCHITECTURE_DIR" ]]; then
  while IFS= read -r -d '' arch_file; do
    if grep -qiE '^##[[:space:]].*(product promise|product roadmap|product acceptance|users and problems|用户承诺|产品承诺|产品路线图|产品验收)' "$arch_file"; then
      add_warn "[PRODUCT-ARCH-DRIFT] architecture file appears to redefine product facts instead of linking product owner: $arch_file"
      product_arch_warn_count=$((product_arch_warn_count + 1))
    fi
    [[ "$product_arch_warn_count" -ge 20 ]] && break
  done < <(find "$ARCHITECTURE_DIR" -name '*.md' -type f -print0)
fi
if [[ "$product_arch_warn_count" -eq 0 ]]; then
  add_pass "product/architecture boundary free of obvious deterministic drift"
fi

arch_checklist_warn_count=0
if [[ -d "$ARCHITECTURE_DIR" ]]; then
  while IFS= read -r -d '' arch_readme; do
    [[ "$arch_readme" == "$ARCHITECTURE_DIR/README.md" ]] && continue
    [[ "$arch_readme" == "$ARCHITECTURE_DIR/views/README.md" ]] && continue
    h2_count=$(grep -cE '^##[[:space:]]' "$arch_readme" || true)
    placeholder_count=$(grep -cE 'not_applicable|OPTIONAL-START|OPTIONAL-END|<[^>]+>' "$arch_readme" || true)
    if [[ "$h2_count" -ge 18 || "$placeholder_count" -ge 12 ]]; then
      add_warn "[ARCH-CHECKLIST-HEAVY] architecture domain/view README looks like a universal checklist instead of a Runtime Owner Map: $arch_readme"
      arch_checklist_warn_count=$((arch_checklist_warn_count + 1))
    fi
    [[ "$arch_checklist_warn_count" -ge 20 ]] && break
  done < <(find "$ARCHITECTURE_DIR" -name 'README.md' -type f -print0)
fi
if [[ "$arch_checklist_warn_count" -eq 0 ]]; then
  add_pass "architecture owner files free of obvious checklist-heavy IA warnings"
fi

# ---------- check 6: confidence: hypothesis forbidden in architecture/ body (v2.13) ----------
# Per knowledge-integrity.md §1: hypothesis may only live in gotchas / STATUS.md open gaps.
# candidate inside architecture gap/unknown notes is legal (needs semantic judgement);
# that case belongs to Doctor L2 and is not checked here.
ARCH_DIR="$ARCHITECTURE_DIR"
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
# The product trunk is required; only deterministic file existence is checked here.
# Body semantics are left to Doctor L2.
PRODUCT_REQUIRED_FILES=(
  "README.md"
  "prd.md"
  "product-model.md"
  "roadmap-and-acceptance.md"
  "capabilities/README.md"
  "journeys/README.md"
)
product_missing=0
for rel in "${PRODUCT_REQUIRED_FILES[@]}"; do
  if [[ ! -f "$PRODUCT_DIR/$rel" ]]; then
    add_fail "[PRODUCT] missing required product skeleton: $PRODUCT_DIR/$rel"
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
DEC_DIR="$DECISIONS_DIR"
if [[ -d "$DEC_DIR" ]]; then
  dec_missing=0
  while IFS= read -r -d '' dec_file; do
    filename=$(basename "$dec_file")
    [[ "$filename" == "README.md" ]] && continue
    [[ ! "$filename" =~ ^[0-9]{4}-.+\.md$ ]] && continue
    fm=$(yaml_frontmatter "$dec_file")
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
[[ -d "$PRODUCT_DIR" ]] && check_meta_leakage_dir "$PRODUCT_DIR"
[[ -d "$ARCHITECTURE_DIR" ]] && check_meta_leakage_dir "$ARCHITECTURE_DIR"
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
  # Only apply to the resolved product and architecture scope. Ledger areas
  # are outside these trunks and keep lifecycle-dependent key sets.
  case "$dir" in
    "$PRODUCT_DIR"|"$PRODUCT_DIR"/*|"$ARCHITECTURE_DIR"|"$ARCHITECTURE_DIR"/*) ;;
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
# Ordered content paths under the architecture trunk — domain directories should have NN- prefix
for d in "$ARCHITECTURE_DIR"/*/; do
  [[ -d "$d" ]] || continue
  bname=$(basename "$d")
  [[ "$bname" == "views" ]] && continue
  if ! printf '%s' "$bname" | grep -qE '^[0-9]{2}-'; then
    add_fail "[NUMBERED-PREFIX] architecture domain directory missing NN- prefix: $d"
    NP_FAIL_COUNT=$((NP_FAIL_COUNT + 1))
  fi
done

# product capabilities/journeys files (not README.md, _manifest.md) must have NN- prefix
for ordered_dir in "$PRODUCT_DIR/capabilities" "$PRODUCT_DIR/journeys"; do
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
    done < <(find "$PRODUCT_DIR" "$ARCHITECTURE_DIR" "$DEVELOPMENT_DIR" -name '*.md' -type f -print0 2>/dev/null || true)
  fi
fi
if [[ "$H1L_WARN_COUNT" -eq 0 ]]; then
  add_pass "[H1-LANGUAGE] (15L) no pure-English H1 in zh documentation_language detected"
fi

# ---------- check 16: [INTENT-RECOVERY-UNIFORM] (15M) product/ and architecture/ prose must carry intent_recovery ----------
IR_FAIL_COUNT=0
for ir_dir in "$PRODUCT_DIR" "$ARCHITECTURE_DIR"; do
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
if document_quality_active; then
  : # v2.59 uses narrative sufficiency plus independent cold-reader review.
elif [[ -d "$ARCHITECTURE_DIR" ]]; then
  while IFS= read -r -d '' readme; do
    # Only domain-level READMEs: <resolved architecture>/<domain>/README.md.
    parent_dir=$(dirname "$readme")
    grand_dir=$(dirname "$parent_dir")
    [[ "$grand_dir" != "$ARCHITECTURE_DIR" ]] && continue
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
  done < <(find "$ARCHITECTURE_DIR" -name 'README.md' -type f -print0 2>/dev/null || true)
fi
if [[ "$WT_WARN_COUNT" -eq 0 ]]; then
  if document_quality_active; then
    add_pass "[WALKTHROUGH] (15R) v2.59 does not require an exact walkthrough heading"
  else
    add_pass "[WALKTHROUGH] (15R) architecture domain READMEs with non-empty Runtime Flows carry canonical-flow walkthrough"
  fi
fi

# ---------- check 19: [BOUNDARY-DISAMBIG] (15S) owner READMEs need 'Easily confused with' section ----------
is_owner_archetype_readme() { # $1=README path
  local readme="$1" parent grand
  case "$readme" in
    "$SSOT_DIR/README.md"|"$PRODUCT_DIR/README.md"|"$ARCHITECTURE_DIR/README.md"|"$ARCHITECTURE_DIR/views/README.md"|"$DEVELOPMENT_DIR/README.md"|"$TESTING_DIR/README.md"|"$BENCHMARK_AREA_DIR/README.md"|"$DEPLOYMENT_DIR/README.md"|"$RELEASE_DIR/README.md"|"$DECISIONS_DIR/README.md"|"$GOTCHAS_DIR/README.md"|"$BUGS_DIR/README.md"|"$TECH_DEBT_DIR/README.md"|"$GLOSSARY_DIR/README.md")
      return 0
      ;;
  esac
  parent=$(dirname "$readme")
  grand=$(dirname "$parent")
  [[ "$grand" == "$ARCHITECTURE_DIR" && "$(basename "$parent")" != "views" ]]
}

BD_WARN_COUNT=0
while IFS= read -r -d '' readme; do
  is_owner_archetype_readme "$readme" || continue
  if ! grep -qiE '(easily confused|out of scope|does not own|boundary|boundaries|边界|不负责|不在此处|区别|转到.+(owner|文档|README))' "$readme"; then
    add_warn "[BOUNDARY-DISAMBIG] (15S) owner README does not explain its nearest confusing boundary in prose: $readme"
    BD_WARN_COUNT=$((BD_WARN_COUNT + 1))
    [[ "$BD_WARN_COUNT" -ge 20 ]] && break
  fi
done < <(find "$SSOT_DIR" -name 'README.md' -type f -print0 2>/dev/null || true)
if [[ "$BD_WARN_COUNT" -eq 0 ]]; then
  add_pass "[BOUNDARY-DISAMBIG] (15S) owner READMEs explain likely boundary confusion without requiring an exact heading"
fi

# ---------- check 20: [OUT-OF-SCOPE-LINK] (15T) owner READMEs need 'Out of scope' section ----------
OOS_WARN_COUNT=0
while IFS= read -r -d '' readme; do
  is_owner_archetype_readme "$readme" || continue
  if ! grep -qiE '(out of scope|does not answer|does not own|see .*(README|owner)|不负责|不回答|不在此处|另见|转到)' "$readme"; then
    add_warn "[OUT-OF-SCOPE-LINK] (15T) owner README does not name an excluded question and successor owner: $readme"
    OOS_WARN_COUNT=$((OOS_WARN_COUNT + 1))
    [[ "$OOS_WARN_COUNT" -ge 20 ]] && break
  fi
done < <(find "$SSOT_DIR" -name 'README.md' -type f -print0 2>/dev/null || true)
if [[ "$OOS_WARN_COUNT" -eq 0 ]]; then
  add_pass "[OUT-OF-SCOPE-LINK] (15T) owner READMEs route excluded questions without requiring an exact heading"
fi

# ---------- check 21: [DIAGRAM-TYPE-TAG] (15U) Mermaid blocks need diagram_type comment ----------
DT_WARN_COUNT=0
if [[ -d "$ARCHITECTURE_DIR" ]]; then
  while IFS= read -r -d '' f; do
    # Find every Mermaid block. Its first non-blank fenced line must be one
    # valid type tag. Process substitution keeps counter/diagnostic updates in
    # this shell rather than losing them in a pipeline subshell.
    while IFS='|' read -r status filepath lineno; do
      if [[ "$status" == "MISS" ]]; then
        add_warn "[DIAGRAM-TYPE-TAG] (15U) Mermaid block has a missing/invalid first-line diagram_type tag or mixes diagram kinds: $filepath (fence opened near line $lineno)"
        DT_WARN_COUNT=$((DT_WARN_COUNT + 1))
        [[ "$DT_WARN_COUNT" -ge 20 ]] && break
      fi
    done < <(
    awk -v file="$f" '
      /^```mermaid[[:space:]]*$/ { infence=1; checked=0; valid=0; mixed=0; dtype=""; lineno=NR; next }
      infence && /^```/ {
        if (!valid || mixed) { print "MISS|" file "|" lineno }
        infence=0; next
      }
      infence {
        if (!checked && $0 ~ /^[[:space:]]*$/) { next }
        if (!checked) {
          checked=1
          if ($0 ~ /^[[:space:]]*<!--[[:space:]]*diagram_type:[[:space:]]*(component|sequence|state|flow)[[:space:]]*-->[[:space:]]*$/) {
            valid=1
            if ($0 ~ /diagram_type:[[:space:]]*component/) dtype="component"
            else if ($0 ~ /diagram_type:[[:space:]]*sequence/) dtype="sequence"
            else if ($0 ~ /diagram_type:[[:space:]]*state/) dtype="state"
            else dtype="flow"
          }
          next
        }
        if (valid && dtype == "component" && $0 ~ /^[[:space:]]*(sequenceDiagram|participant[[:space:]])/) mixed=1
        if (valid && dtype == "sequence" && $0 ~ /^[[:space:]]*(flowchart|graph|stateDiagram)/) mixed=1
        if (valid && dtype == "state" && $0 ~ /^[[:space:]]*(flowchart|graph|sequenceDiagram|participant[[:space:]])/) mixed=1
      }
    ' "$f"
    )
    [[ "$DT_WARN_COUNT" -ge 20 ]] && break
  done < <(find "$ARCHITECTURE_DIR" -name '*.md' -type f -print0 2>/dev/null || true)
fi
if [[ "$DT_WARN_COUNT" -eq 0 ]]; then
  add_pass "[DIAGRAM-TYPE-TAG] (15U) architecture Mermaid blocks carry diagram_type comment"
fi

# ---------- check 22: [DIAGRAM-FIRST] (15V) architecture domain README needs first-screen diagram ----------
DF_WARN_COUNT=0
if document_quality_active; then
  : # v2.59 hard enforcement already ran in check_document_quality.
elif [[ -d "$ARCHITECTURE_DIR" ]]; then
  while IFS= read -r -d '' readme; do
    parent_dir=$(dirname "$readme")
    grand_dir=$(dirname "$parent_dir")
    [[ "$grand_dir" != "$ARCHITECTURE_DIR" ]] && continue
    [[ "$(basename "$parent_dir")" == "views" ]] && continue
    head -n 5 "$readme" | grep -q 'intent_recovery:[[:space:]]*covered' || continue
    # First 60 lines must contain a ```mermaid fence opener.
    if ! head -n 60 "$readme" | grep -qE '^```mermaid'; then
      add_warn "[DIAGRAM-FIRST] (15V) architecture domain README missing first-screen Mermaid block: $readme"
      DF_WARN_COUNT=$((DF_WARN_COUNT + 1))
      [[ "$DF_WARN_COUNT" -ge 20 ]] && break
    fi
  done < <(find "$ARCHITECTURE_DIR" -name 'README.md' -type f -print0 2>/dev/null || true)
fi
if [[ "$DF_WARN_COUNT" -eq 0 ]]; then
  add_pass "[DIAGRAM-FIRST] (15V) architecture domain READMEs carry first-screen Mermaid block"
fi

# ---------- check 23: [MARKDOWN-FENCE] fenced code blocks must close ----------
MF_FAIL_COUNT=0
while IFS= read -r -d '' md_file; do
  hit=$(awk '
    /^```/ {
      if (!in_fence) { in_fence=1; start=FNR }
      else { in_fence=0; start=0 }
    }
    END {
      if (in_fence) { print start }
    }
  ' "$md_file")
  if [[ -n "$hit" ]]; then
    add_fail "[MARKDOWN-FENCE] unclosed fenced code block: $md_file:$hit"
    MF_FAIL_COUNT=$((MF_FAIL_COUNT + 1))
    [[ "$MF_FAIL_COUNT" -ge 20 ]] && break
  fi
done < <(find "$SSOT_DIR" -name '*.md' -type f -print0 2>/dev/null || true)
if [[ "$MF_FAIL_COUNT" -eq 0 ]]; then
  add_pass "[MARKDOWN-FENCE] SSOT Markdown fenced code blocks are balanced"
fi

# ---------- check 24: [ADR-CLOSURE] / [DEBT-CLOSURE] deterministic lifecycle fields ----------
ADR_DEBT_FAIL_COUNT=0
dec_dir="$DECISIONS_DIR"
if [[ -d "$dec_dir" ]]; then
  while IFS= read -r -d '' dec_file; do
    bname=$(basename "$dec_file")
    [[ "$bname" == "README.md" ]] && continue
    [[ ! "$bname" =~ ^[0-9]{4}-.+\.md$ ]] && continue
    fm=$(yaml_frontmatter "$dec_file")
    state=$(printf '%s\n' "$fm" | awk -F: '/^implementation_state:/ { gsub(/[ "`]/, "", $2); print tolower($2); exit }')
    if [[ "$state" =~ ^(pending|partial|diverged)$ ]]; then
      for field in closure_condition revisit_signal; do
        if ! printf '%s\n' "$fm" | grep -qE "^${field}:"; then
          add_fail "[ADR-CLOSURE] decision implementation_state=$state missing '${field}' frontmatter: $dec_file"
          ADR_DEBT_FAIL_COUNT=$((ADR_DEBT_FAIL_COUNT + 1))
        fi
      done
    fi
    [[ "$ADR_DEBT_FAIL_COUNT" -ge 30 ]] && break
  done < <(find "$dec_dir" -maxdepth 1 -name '*.md' -type f -print0)
fi
debt_dir="$TECH_DEBT_DIR"
if [[ -d "$debt_dir" ]]; then
  while IFS= read -r -d '' debt_file; do
    bname=$(basename "$debt_file")
    [[ "$bname" == "README.md" ]] && continue
    [[ ! "$bname" =~ ^[0-9]{4}-.+\.md$ ]] && continue
    fm=$(yaml_frontmatter "$debt_file")
    status=$(printf '%s\n' "$fm" | awk -F: '/^status:/ { gsub(/[ "`]/, "", $2); print tolower($2); exit }')
    if [[ "$status" == "active" ]]; then
      for field in closure_condition revisit_signal; do
        if ! printf '%s\n' "$fm" | grep -qE "^${field}:"; then
          add_fail "[DEBT-CLOSURE] active tech-debt missing '${field}' frontmatter: $debt_file"
          ADR_DEBT_FAIL_COUNT=$((ADR_DEBT_FAIL_COUNT + 1))
        fi
      done
      if printf '%s\n' "$fm" | grep -qiE '^temporary_surface:[[:space:]]*(true|yes)'; then
        for field in owner reason verification_guard; do
          if ! printf '%s\n' "$fm" | grep -qE "^${field}:"; then
            add_fail "[TEMP-SURFACE] active temporary tech-debt missing '${field}' frontmatter: $debt_file"
            ADR_DEBT_FAIL_COUNT=$((ADR_DEBT_FAIL_COUNT + 1))
          fi
        done
      fi
    fi
    [[ "$ADR_DEBT_FAIL_COUNT" -ge 30 ]] && break
  done < <(find "$debt_dir" -maxdepth 1 -name '*.md' -type f -print0)
fi
if [[ "$ADR_DEBT_FAIL_COUNT" -eq 0 ]]; then
  add_pass "[ADR-CLOSURE]/[DEBT-CLOSURE] open lifecycle entries carry closure fields"
fi

# ---------- check 25: [COVERED-PLACEHOLDER] covered areas cannot contain starter residue ----------
area_is_covered() { # $1=area key as written in STATUS area table
  [[ -f "$STATUS_FILE" ]] || return 1
  grep -qE "^\|[[:space:]]*$1[[:space:]]*\|[[:space:]]*covered[[:space:]]*\|" "$STATUS_FILE"
}
scan_covered_placeholders() { # $1=dir $2=label
  local dir="$1" label="$2"
  [[ -d "$dir" ]] || return 0
  while IFS= read -r -d '' md_file; do
    local bname hit
    bname=$(basename "$md_file")
    [[ "$bname" == "_manifest.md" || "$bname" == "STATUS.md" || "$bname" == "CHANGELOG.md" ]] && continue
    hit=$(awk '
      /^```/ { in_code = !in_code; next }
      !in_code && $0 ~ /(TODO:[[:space:]]|FIXME|review-needed|starter skeleton|to be filled|fill this|TBD:|待补充|（待补充）)/ {
        print FNR ":" $0
        exit
      }
    ' "$md_file")
    if [[ -n "$hit" ]]; then
      add_fail "[COVERED-PLACEHOLDER] covered $label area contains unresolved placeholder/starter residue: $md_file:$hit"
      COVERED_PLACEHOLDER_FAIL_COUNT=$((COVERED_PLACEHOLDER_FAIL_COUNT + 1))
      [[ "$COVERED_PLACEHOLDER_FAIL_COUNT" -ge 20 ]] && break
    fi
  done < <(find "$dir" -name '*.md' -type f -print0 2>/dev/null || true)
  return 0
}
COVERED_PLACEHOLDER_FAIL_COUNT=0
area_is_covered product && scan_covered_placeholders "$PRODUCT_DIR" product
area_is_covered architecture && scan_covered_placeholders "$ARCHITECTURE_DIR" architecture
area_is_covered development && scan_covered_placeholders "$DEVELOPMENT_DIR" development
area_is_covered testing && scan_covered_placeholders "$TESTING_DIR" testing
area_is_covered deployment && scan_covered_placeholders "$DEPLOYMENT_DIR" deployment
area_is_covered release && scan_covered_placeholders "$RELEASE_DIR" release
area_is_covered decisions && scan_covered_placeholders "$DECISIONS_DIR" decisions
area_is_covered gotchas && scan_covered_placeholders "$GOTCHAS_DIR" gotchas
area_is_covered bugs && scan_covered_placeholders "$BUGS_DIR" bugs
area_is_covered tech-debt && scan_covered_placeholders "$TECH_DEBT_DIR" tech-debt
area_is_covered glossary && scan_covered_placeholders "$GLOSSARY_DIR" glossary
if [[ "$COVERED_PLACEHOLDER_FAIL_COUNT" -eq 0 ]]; then
  add_pass "[COVERED-PLACEHOLDER] covered areas have no obvious unresolved starter residue"
fi

# ---------- check 26: [STATUS-AGGREGATE] stop summaries must not contradict open work ----------
status_open_gap_count() {
  [[ -f "$STATUS_FILE" ]] || { printf '0\n'; return; }
  awk '
    /^##[[:space:]]+(Open Gaps|开放缺口)/ { in_gap=1; next }
    /^##[[:space:]]/ && in_gap { exit }
    in_gap && /^\|/ && $0 !~ /\|[[:space:]]*-+[[:space:]]*\|/ && $0 !~ /(Area|区域|Gap description|缺口描述)/ { count++ }
    END { print count + 0 }
  ' "$STATUS_FILE"
}
active_high_risk_record_count() {
  local count=0
  bug_dir="$BUGS_DIR"
  if [[ -d "$bug_dir" ]]; then
    while IFS= read -r -d '' bug_file; do
      local head
      head=$(yaml_frontmatter "$bug_file")
      if printf '%s\n' "$head" | grep -qiE '^status:[[:space:]]*(active|recurred)' &&
         printf '%s\n' "$head" | grep -qiE '^severity:[[:space:]]*(critical|major|high)'; then
        count=$((count + 1))
      fi
    done < <(find "$bug_dir" -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-*.md' -type f -print0)
  fi
  debt_dir="$TECH_DEBT_DIR"
  if [[ -d "$debt_dir" ]]; then
    while IFS= read -r -d '' debt_file; do
      local head
      head=$(yaml_frontmatter "$debt_file")
      if printf '%s\n' "$head" | grep -qiE '^status:[[:space:]]*active' &&
         printf '%s\n' "$head" | grep -qiE '^priority:[[:space:]]*(critical|high)'; then
        count=$((count + 1))
      fi
    done < <(find "$debt_dir" -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-*.md' -type f -print0)
  fi
  printf '%s\n' "$count"
}
STATUS_AGG_FAIL_COUNT=0
if [[ -f "$STATUS_FILE" ]]; then
  open_gap_count=$(status_open_gap_count)
  high_risk_count=$(active_high_risk_record_count)
  if (( open_gap_count > 0 || high_risk_count > 0 )); then
    while IFS= read -r summary_line; do
      line_no="${summary_line%%:*}"
      line="${summary_line#*:}"
      if printf '%s\n' "$line" | grep -qiE '(remaining[^|]*(only|none|no remaining)|no open gaps|zero remaining|当前无.*缺口|仅剩|只有.*DEBT)'; then
        add_fail "[STATUS-AGGREGATE] stop/status summary claims only/no remaining work while open gaps=$open_gap_count and active high-risk records=$high_risk_count: $STATUS_FILE:$line_no"
        STATUS_AGG_FAIL_COUNT=$((STATUS_AGG_FAIL_COUNT + 1))
      fi
    done < <(grep -nEi '(remaining|no open gaps|zero remaining|当前无.*缺口|仅剩|只有.*DEBT)' "$STATUS_FILE" || true)
  fi
fi
if [[ "$STATUS_AGG_FAIL_COUNT" -eq 0 ]]; then
  add_pass "[STATUS-AGGREGATE] stop summaries do not obviously contradict open gaps/high-risk records"
fi

# ---------- check 27: [GAP-OWNER] open gap rows must not say "create the owner later" ----------
GAP_OWNER_FAIL_COUNT=0
if [[ -f "$STATUS_FILE" ]]; then
  while IFS= read -r gap_line; do
    line_no="${gap_line%%:*}"
    line="${gap_line#*:}"
    if printf '%s\n' "$line" | grep -qiE '(待立|TODO debt|create .*debt|debt later|owner later|unowned|无 owner)' &&
       ! printf '%s\n' "$line" | grep -qE '(DEBT-[0-9]{4}|BUG-[0-9]{4}|DEC-[0-9]{4}|ADJ-[0-9]{8})'; then
      add_fail "[GAP-OWNER] open gap row defers ownership instead of linking an owner record: $STATUS_FILE:$line_no"
      GAP_OWNER_FAIL_COUNT=$((GAP_OWNER_FAIL_COUNT + 1))
    fi
  done < <(awk '
    /^##[[:space:]]+(Open Gaps|开放缺口)/ { in_gap=1; next }
    /^##[[:space:]]/ && in_gap { exit }
    in_gap && /^\|/ && $0 !~ /\|[[:space:]]*-+[[:space:]]*\|/ && $0 !~ /(Area|区域|Gap description|缺口描述)/ { print FNR ":" $0 }
  ' "$STATUS_FILE")
fi
if [[ "$GAP_OWNER_FAIL_COUNT" -eq 0 ]]; then
  add_pass "[GAP-OWNER] open gap rows have no obvious unowned follow-up wording"
fi

# ---------- check 28: [CAPTURE-LIFECYCLE] resolved/passed captures cannot hide pending actions ----------
CAPTURE_LIFECYCLE_FAIL_COUNT=0
if [[ -f "$STATUS_FILE" ]]; then
  while IFS= read -r cap_line; do
    line_no="${cap_line%%:*}"
    line="${cap_line#*:}"
    add_fail "[CAPTURE-LIFECYCLE] STATUS capture/summary contains actionable follow-up wording that must be promoted, deferred with owner/trigger, or expired: $STATUS_FILE:$line_no -- ${line:0:120}"
    CAPTURE_LIFECYCLE_FAIL_COUNT=$((CAPTURE_LIFECYCLE_FAIL_COUNT + 1))
    [[ "$CAPTURE_LIFECYCLE_FAIL_COUNT" -ge 20 ]] && break
  done < <(grep -nEi '(Pending action|Outstanding .*follow[- ]?ups?|opportunistic follow[- ]?ups?|routed to the next .* audit batch|待处理|后续.*待立)' "$STATUS_FILE" || true)
fi
if [[ "$CAPTURE_LIFECYCLE_FAIL_COUNT" -eq 0 ]]; then
  add_pass "[CAPTURE-LIFECYCLE] STATUS resolved/passed captures have no obvious hidden pending actions"
fi

# ---------- check 28b: [CAPTURE-LIFECYCLE] placeholder debt / follow-up wording in owner files ----------
CAPTURE_PLACEHOLDER_FAIL_COUNT=0
CAPTURE_PLACEHOLDER_RE='TODO debt|todo debt|Pending action|follow up later|follow-up later|opportunistic follow-up|后续待立|待立 tech-debt'
for owner_dir in "$TECH_DEBT_DIR" "$BUGS_DIR" "$DECISIONS_DIR"; do
  [[ -d "$owner_dir" ]] || continue
  while IFS= read -r -d '' owner_file; do
    bname=$(basename "$owner_file")
    [[ "$bname" == "README.md" ]] && continue
    [[ ! "$bname" =~ ^[0-9]{4}-.+\.md$ ]] && continue
    owner_frontmatter=$(yaml_frontmatter "$owner_file")
    owner_lifecycle_registered=1
    for field in owner closure_condition revisit_signal verification_guard; do
      if ! yaml_field_has_value "$owner_frontmatter" "$field"; then
        owner_lifecycle_registered=0
        break
      fi
    done
    while IFS= read -r numbered_line; do
      line_no="${numbered_line%%:*}"
      line="${numbered_line#*:}"
      if printf '%s\n' "$line" | grep -qiE "$CAPTURE_PLACEHOLDER_RE" &&
         [[ "$owner_lifecycle_registered" -ne 1 ]]; then
        add_fail "[CAPTURE-LIFECYCLE] owner file contains placeholder follow-up wording without owner/trigger guard: $owner_file:$line_no"
        CAPTURE_PLACEHOLDER_FAIL_COUNT=$((CAPTURE_PLACEHOLDER_FAIL_COUNT + 1))
        [[ "$CAPTURE_PLACEHOLDER_FAIL_COUNT" -ge 20 ]] && break 2
      fi
    done < <(awk '
      /^```/ { in_code = !in_code; next }
      !in_code && $0 !~ /^[[:space:]]*>/ { print FNR ":" $0 }
    ' "$owner_file")
  done < <(find "$owner_dir" -maxdepth 1 -name '*.md' -type f -print0)
done
if [[ "$CAPTURE_PLACEHOLDER_FAIL_COUNT" -eq 0 ]]; then
  add_pass "[CAPTURE-LIFECYCLE] owner files have no obvious placeholder debt/follow-up wording"
fi

# ---------- check 29: [SILENT-DEFERRAL] vague future-work wording needs an owner/retrigger signal ----------
SILENT_DEFERRAL_FAIL_COUNT=0
DEFERRAL_WORD_RE='later|someday|future work|handle[[:space:]].*later|do[[:space:]].*later|create[[:space:]].*later|后续处理|之后处理|以后处理|稍后处理|下次.*处理|未来工作'
DEFERRAL_SIGNAL_RE='DEBT-[0-9]{4}|BUG-[0-9]{4}|DEC-[0-9]{4}|ADJ-[0-9]{8}|owner[[:space:]]*[:=]|closure_condition[[:space:]]*:|revisit_signal[[:space:]]*:|verification_guard[[:space:]]*:|next_action[[:space:]]*:|next action|next concrete action|retrigger|path-glob:|guard'
strip_code_for_deferral_scan() {
  awk '
    /^```/ { in_code = !in_code; next }
    !in_code && $0 !~ /^[[:space:]]*>/ { print FNR ":" $0 }
  ' "$1"
}
line_has_deferral_signal() {
  printf '%s\n' "$1" | grep -qiE "$DEFERRAL_SIGNAL_RE"
}
file_head_has_deferral_signal() {
  yaml_frontmatter "$1" | grep -qiE "$DEFERRAL_SIGNAL_RE"
}
record_is_active_for_deferral_scan() {
  local record_file="$1"
  local head state status
  head=$(yaml_frontmatter "$record_file")
  status=$(printf '%s\n' "$head" | awk -F: '/^status:/ { gsub(/[ "`]/, "", $2); print tolower($2); exit }')
  state=$(printf '%s\n' "$head" | awk -F: '/^implementation_state:/ { gsub(/[ "`]/, "", $2); print tolower($2); exit }')
  [[ "$status" =~ ^(active|recurred)$ || "$state" =~ ^(pending|partial|diverged)$ ]]
}
scan_deferral_lines() { # $1=file $2=label $3=file-level-signal-ok (0/1)
  local target_file="$1" label="$2" file_signal_ok="${3:-0}"
  while IFS= read -r numbered_line; do
    local line_no line
    line_no="${numbered_line%%:*}"
    line="${numbered_line#*:}"
    if printf '%s\n' "$line" | grep -qiE "$DEFERRAL_WORD_RE"; then
      if ! line_has_deferral_signal "$line" && [[ "$file_signal_ok" -ne 1 ]]; then
        add_fail "[SILENT-DEFERRAL] ${label} contains future-work wording without owner/reference or retrigger signal: $target_file:$line_no"
        SILENT_DEFERRAL_FAIL_COUNT=$((SILENT_DEFERRAL_FAIL_COUNT + 1))
        [[ "$SILENT_DEFERRAL_FAIL_COUNT" -ge 30 ]] && return 0
      fi
    fi
  done < <(strip_code_for_deferral_scan "$target_file")
}
if [[ -f "$STATUS_FILE" ]]; then
  while IFS= read -r gap_line; do
    line_no="${gap_line%%:*}"
    line="${gap_line#*:}"
    if printf '%s\n' "$line" | grep -qiE "$DEFERRAL_WORD_RE" && ! line_has_deferral_signal "$line"; then
      add_fail "[SILENT-DEFERRAL] open gap row uses future-work wording without owner/reference or retrigger signal: $STATUS_FILE:$line_no"
      SILENT_DEFERRAL_FAIL_COUNT=$((SILENT_DEFERRAL_FAIL_COUNT + 1))
    fi
  done < <(awk '
    /^##[[:space:]]+(Open Gaps|开放缺口)/ { in_gap=1; next }
    /^##[[:space:]]/ && in_gap { exit }
    in_gap && /^\|/ && $0 !~ /\|[[:space:]]*-+[[:space:]]*\|/ && $0 !~ /(Area|区域|Gap description|缺口描述)/ { print FNR ":" $0 }
  ' "$STATUS_FILE")
fi
for record_dir in "$TECH_DEBT_DIR" "$BUGS_DIR" "$DECISIONS_DIR"; do
  [[ -d "$record_dir" ]] || continue
  while IFS= read -r -d '' record_file; do
    bname=$(basename "$record_file")
    [[ "$bname" == "README.md" ]] && continue
    [[ ! "$bname" =~ ^[0-9]{4}-.+\.md$ ]] && continue
    record_is_active_for_deferral_scan "$record_file" || continue
    if file_head_has_deferral_signal "$record_file"; then
      scan_deferral_lines "$record_file" "active record" 1
    else
      scan_deferral_lines "$record_file" "active record" 0
    fi
    [[ "$SILENT_DEFERRAL_FAIL_COUNT" -ge 30 ]] && break
  done < <(find "$record_dir" -maxdepth 1 -name '*.md' -type f -print0)
done
if [[ "$SILENT_DEFERRAL_FAIL_COUNT" -eq 0 ]]; then
  add_pass "[SILENT-DEFERRAL] obvious future-work wording has owner/reference or retrigger signals"
fi

# ---------- check 30: [RESEARCH-RECORD] research/POC evidence packets ----------
# Canonical research records live under 04-records/research/. They are
# structured evidence packets, not a top-level authority area and not required
# merely because source-material rows mention research or POC docs.
RESEARCH_RECORD_FAIL_COUNT=0
if [[ -d "$SSOT_DIR/research" ]]; then
  add_fail "[RESEARCH-RECORD] top-level SSOT/research is not a valid authority area; use SSOT/04-records/research: $SSOT_DIR/research"
  RESEARCH_RECORD_FAIL_COUNT=$((RESEARCH_RECORD_FAIL_COUNT + 1))
fi
RESEARCH_DIR="$RESEARCH_AREA_DIR"
if [[ -d "$RESEARCH_DIR" ]]; then
  if [[ ! -f "$RESEARCH_DIR/README.md" ]]; then
    add_fail "[RESEARCH-RECORD] research records area missing README index: $RESEARCH_DIR/README.md"
    RESEARCH_RECORD_FAIL_COUNT=$((RESEARCH_RECORD_FAIL_COUNT + 1))
  fi
  while IFS= read -r -d '' research_file; do
    bname=$(basename "$research_file")
    [[ "$bname" == "README.md" ]] && continue
    if [[ ! "$bname" =~ ^[0-9]{4}-.+\.md$ ]]; then
      add_fail "[RESEARCH-RECORD] research entry must use NNNN-<slug>.md numbering: $research_file"
      RESEARCH_RECORD_FAIL_COUNT=$((RESEARCH_RECORD_FAIL_COUNT + 1))
      [[ "$RESEARCH_RECORD_FAIL_COUNT" -ge 30 ]] && break
      continue
    fi
    fm=$(yaml_frontmatter "$research_file")
    for field in status kind created_on owner promotion_targets recheck_trigger; do
      if ! printf '%s\n' "$fm" | grep -qE "^${field}:"; then
        add_fail "[RESEARCH-RECORD] research entry missing required frontmatter field '${field}': $research_file"
        RESEARCH_RECORD_FAIL_COUNT=$((RESEARCH_RECORD_FAIL_COUNT + 1))
      fi
    done
    if printf '%s\n' "$fm" | grep -qE '^promotion_targets:' && ! yaml_field_has_value "$fm" promotion_targets; then
      add_fail "[RESEARCH-RECORD] research entry promotion_targets must name owner targets or explicit not_applicable reason: $research_file"
      RESEARCH_RECORD_FAIL_COUNT=$((RESEARCH_RECORD_FAIL_COUNT + 1))
    fi
    if printf '%s\n' "$fm" | grep -qE '^recheck_trigger:' && ! yaml_field_has_value "$fm" recheck_trigger; then
      add_fail "[RESEARCH-RECORD] research entry recheck_trigger must be concrete: $research_file"
      RESEARCH_RECORD_FAIL_COUNT=$((RESEARCH_RECORD_FAIL_COUNT + 1))
    fi
    for field in status kind created_on owner; do
      if printf '%s\n' "$fm" | grep -qE "^${field}:" && ! yaml_field_has_value "$fm" "$field"; then
        add_fail "[RESEARCH-RECORD] research entry frontmatter field '${field}' must not be empty: $research_file"
        RESEARCH_RECORD_FAIL_COUNT=$((RESEARCH_RECORD_FAIL_COUNT + 1))
      fi
    done
    if ! head -n 120 "$research_file" | grep -qiE 'do_not_use_for|Do not use for|Applicability|Boundar(y|ies)|适用边界|不适用|不得用于|不要用于'; then
      add_fail "[RESEARCH-RECORD] research entry lacks a mechanical boundary / do_not_use_for signal: $research_file"
      RESEARCH_RECORD_FAIL_COUNT=$((RESEARCH_RECORD_FAIL_COUNT + 1))
    fi
    [[ "$RESEARCH_RECORD_FAIL_COUNT" -ge 30 ]] && break
  done < <(find "$RESEARCH_DIR" -maxdepth 1 -name '*.md' -type f -print0)
fi
if [[ "$RESEARCH_RECORD_FAIL_COUNT" -eq 0 ]]; then
  add_pass "[RESEARCH-RECORD] research evidence packets are canonical and mechanically complete"
fi

# ---------- check 31: [BENCHMARK-OWNER] benchmark process owner ----------
# Canonical benchmark policy lives under 03-process/benchmark/. Legacy
# top-level benchmark/ is accepted only when the consumer has not adopted the
# faceted process layout. The check is deliberately structural: semantic
# quality of floors/trends remains Doctor L2 judgement.
BENCHMARK_OWNER_FAIL_COUNT=0
BENCHMARK_DIR=""
[[ -d "$BENCHMARK_AREA_DIR" ]] && BENCHMARK_DIR="$BENCHMARK_AREA_DIR"
if [[ -n "$BENCHMARK_DIR" && ! -f "$BENCHMARK_DIR/README.md" ]]; then
  add_fail "[BENCHMARK-OWNER] benchmark area missing README owner: $BENCHMARK_DIR/README.md"
  BENCHMARK_OWNER_FAIL_COUNT=$((BENCHMARK_OWNER_FAIL_COUNT + 1))
fi
if [[ -d "$SSOT_DIR/03-process" && ! -d "$SSOT_DIR/03-process/benchmark" ]]; then
  add_fail "[BENCHMARK-OWNER] 03-process layout missing benchmark owner: $SSOT_DIR/03-process/benchmark/README.md"
  BENCHMARK_OWNER_FAIL_COUNT=$((BENCHMARK_OWNER_FAIL_COUNT + 1))
fi
TESTING_README=""
[[ -f "$TESTING_DIR/README.md" ]] && TESTING_README="$TESTING_DIR/README.md"
if [[ -n "$TESTING_README" && -z "$BENCHMARK_DIR" ]]; then
  if grep -qiE '(benchmark floor|benchmark baseline|performance floor|latency floor|throughput floor|capacity floor|cost floor|trend interpretation|comparison rule|canonical workload|性能.*(基线|阈值|floor)|成本.*(基线|阈值|floor)|容量.*(基线|阈值|floor))' "$TESTING_README"; then
    add_fail "[BENCHMARK-OWNER] testing README appears to own benchmark floors or interpretation but benchmark owner is missing: $TESTING_README"
    BENCHMARK_OWNER_FAIL_COUNT=$((BENCHMARK_OWNER_FAIL_COUNT + 1))
  fi
fi
if [[ -n "$BENCHMARK_DIR" ]]; then
  BENCHMARK_LEDGER_HIT=$(grep -RInE '(latest benchmark|recent benchmark|benchmark run history|performance run history|20[0-9]{2}-[0-9]{2}-[0-9]{2}.*(benchmark|latency|throughput|perf|performance)|最近.*benchmark|最近.*性能|运行历史)' "$BENCHMARK_DIR" 2>/dev/null | head -1 || true)
  if [[ -n "$BENCHMARK_LEDGER_HIT" ]]; then
    add_warn "[BENCHMARK-LEDGER] benchmark area appears to carry chronological run history; keep stable suites/floors/rules only: $BENCHMARK_LEDGER_HIT"
  fi
fi
if [[ "$BENCHMARK_OWNER_FAIL_COUNT" -eq 0 ]]; then
  add_pass "[BENCHMARK-OWNER] benchmark process owner is present or no obvious benchmark facts are hidden in testing"
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
