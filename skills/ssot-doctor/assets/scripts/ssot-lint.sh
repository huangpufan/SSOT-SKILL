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
    # tracking baseline comes from their common SSOT root. Never let the first scan
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

sha256_file() { # $1=file; full digest for durable review fingerprints
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    return 1
  fi
}

sha256_stream() { # stdin -> full digest
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  else
    return 1
  fi
}

review_content_fingerprint_stream() { # shared root + product + architecture reader surface
  local ssot_dir="$1" file relative digest
  [[ -d "$ssot_dir" ]] || return 1
  while IFS= read -r file; do
    relative="${file#"$ssot_dir"/}"
    digest=$(sha256_file "$file") || return 1
    printf '%s\0%s\n' "$relative" "$digest"
  done < <(
    {
      [[ -f "$ssot_dir/README.md" ]] && printf '%s\n' "$ssot_dir/README.md"
      find "$ssot_dir/01-product" "$ssot_dir/02-architecture" -type f -name '*.md' -print 2>/dev/null || true
    } | LC_ALL=C sort -u
  )
}

current_review_content_fingerprint() { # root entrypoint + both cross-traced reader scopes
  review_content_fingerprint_stream "$SSOT_DIR" | sha256_stream
}

status_quality_disposition_rows() { # normalized six-column Q register, sorted by Q ID
  local status_file="$1"
  [[ -f "$status_file" ]] || return 1
  awk '
    BEGIN { sep=sprintf("%c", 28) }
    function normalize(v) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
      gsub(/[[:space:]]+/, " ", v)
      return v
    }
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
      have_header=0
      next
    }
    in_q && /^\|/ {
      if ($0 ~ /^\|[[:space:]:|-]+(\|[[:space:]:|-]+)+\|?[[:space:]]*$/) next
      cell_count=split($0, cells, "|")
      if (!have_header) {
        if (set_header()) have_header=1
        next
      }
      print normalize_id(cells[q_i]) sep normalize(cells[app_i]) sep \
        normalize(cells[product_i]) sep normalize(cells[architecture_i]) sep \
        normalize(cells[process_i]) sep normalize(cells[gap_i])
    }
  ' "$status_file" | LC_ALL=C sort -t "$(printf '\034')" -k1,1
}

current_quality_disposition_fingerprint() { # exact normalized Q01-Q21 STATUS semantics
  local rows ids expected sep
  sep=$(printf '\034')
  # This helper is used by the focused document-quality pass before the normal
  # suite assigns STATUS_FILE, so derive the path from the already-resolved
  # SSOT root rather than depending on later global initialisation.
  rows=$(status_quality_disposition_rows "$SSOT_DIR/STATUS.md") || return 1
  ids=$(printf '%s\n' "$rows" | awk -F "$sep" '{ print $1 }')
  expected=$(for i in {1..21}; do printf 'Q%02d\n' "$i"; done)
  [[ "$ids" == "$expected" ]] || return 1
  printf '%s\n' "$rows" | while IFS="$sep" read -r id applicability product architecture process gap; do
    printf '%s\0%s\0%s\0%s\0%s\0%s\n' \
      "$id" "$applicability" "$product" "$architecture" "$process" "$gap"
  done | sha256_stream
}

scope_review_fingerprint_stream() { # $1=process|records|glossary|root|status
  local profile="$1" base file relative digest
  case "$profile" in
    process) base="$PROCESS_DIR" ;;
    records) base="$RECORDS_DIR" ;;
    glossary) base="$GLOSSARY_DIR" ;;
    root) base="$SSOT_DIR/README.md" ;;
    status) base="$SSOT_DIR/STATUS.md" ;;
    *) return 1 ;;
  esac
  if [[ "$profile" == "root" || "$profile" == "status" ]]; then
    [[ -f "$base" && ! -L "$base" ]] || return 1
    relative="${base#"$SSOT_DIR"/}"
    digest=$(sha256_file "$base") || return 1
    printf '%s\0%s\n' "$relative" "$digest"
    return 0
  fi
  [[ -d "$base" ]] || return 1
  # A covered scope must have one enumerable content set. Following symlinks
  # makes that set depend on external filesystem state; ignoring them hides
  # content from the fingerprint. Fail closed instead.
  ! find "$base" -type l -print -quit 2>/dev/null | grep -q . || return 1
  while IFS= read -r file; do
    relative="${file#"$SSOT_DIR"/}"
    digest=$(sha256_file "$file") || return 1
    printf '%s\0%s\n' "$relative" "$digest"
  done < <(find "$base" -type f -name '*.md' -print 2>/dev/null | LC_ALL=C sort)
}

current_scope_review_fingerprint() { # $1=scope profile
  scope_review_fingerprint_stream "$1" | sha256_stream
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
    process) printf '03-process\n' ;;
    records) printf '04-records\n' ;;
    product) printf '01-product\n' ;;
    architecture) printf '02-architecture\n' ;;
    development|testing|benchmark|deployment|release|operations|security-and-compliance) printf '03-process/%s\n' "$1" ;;
    decisions|gotchas|bugs|tech-debt|research|"research records")
      [[ "$1" == "research records" ]] && printf '04-records/research\n' || printf '04-records/%s\n' "$1"
      ;;
    glossary) printf 'glossary\n' ;;
    *) return 1 ;;
  esac
}

legacy_area_rel() { # $1=semantic area name
  case "$1" in
    process|records|product|architecture|development|testing|benchmark|deployment|release|operations|security-and-compliance|decisions|gotchas|bugs|tech-debt|research|glossary)
      printf '%s\n' "$1"
      ;;
    "research records") printf 'research\n' ;;
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
PROCESS_DIR=$(resolve_area_dir process)
DEVELOPMENT_DIR=$(resolve_area_dir development)
TESTING_DIR=$(resolve_area_dir testing)
BENCHMARK_AREA_DIR=$(resolve_area_dir benchmark)
DEPLOYMENT_DIR=$(resolve_area_dir deployment)
RELEASE_DIR=$(resolve_area_dir release)
OPERATIONS_DIR=$(resolve_area_dir operations)
SECURITY_COMPLIANCE_DIR=$(resolve_area_dir security-and-compliance)
RECORDS_DIR=$(resolve_area_dir records)
DECISIONS_DIR=$(resolve_area_dir decisions)
GOTCHAS_DIR=$(resolve_area_dir gotchas)
BUGS_DIR=$(resolve_area_dir bugs)
TECH_DEBT_DIR=$(resolve_area_dir tech-debt)
RESEARCH_AREA_DIR=$(resolve_area_dir research)
GLOSSARY_DIR=$(resolve_area_dir glossary)

# ---------- v2.48 [META-LEAKAGE] (15I) helper; all-body scope in v2.60 ----------
# Scan visible prose in every reader body under SSOT. Registers and machine
# artifacts are excluded by shape, not by subject area; decisions and debt get
# no broad exemption. Authoring comments are hidden here because the covered-
# placeholder gate rejects them separately before coverage.
META_LEAKAGE_TOKENS_BASE='\[CORE-REF-PROSE\]|\[MAXIM-OWNER\]|\[INTENT-OWNER\]|\[INTENT-TRUTH-NARRATIVE\]|\[CORE-COVERAGE-MAP\]|\[VOCAB-PROSE-FORK\]|\[WORKFLOW-STATE-VOCAB\]|\[INTENT-RECOVERY\]|\[META-LEAKAGE\]|(^|[^0-9A-Za-z])(14W|14X|14Y|14Z|15A|15B|15C|15D|15F|15G|15H|15I)([^0-9A-Za-z]|$)|(^|[^0-9A-Za-z])v2\.(43|44|45|46|47|48)([^0-9]|$)|product_intent \+ product_truth|design_intent \+ design_truth|必备 pillar|intent_recovery_pillars|intent_recovery_evidence:[[:space:]]*"|本 README 自身的可恢复性失败模式|本节正文回流|Apex-Maxim → Owner 索引|^##[[:space:]]+核心恢复清单|^##[[:space:]]+Capability → Surface registry'
META_LEAKAGE_TOKENS_V259='ssot-(preflight|bootstrap|closeout|audit|doctor|skill)|reader-quality[.]md|status-protocol[.]md|area-model[.]md|SKILL_STYLE|[Dd]octor[[:space:]]+(row[[:space:]]+)?[0-9]+[A-Z]?'

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
    [[ "$rel_file" == _*.md ]] && continue
    [[ "$rel_file" == "STATUS.md" ]] && continue
    [[ "$rel_file" == "CHANGELOG.md" ]] && continue
    local rel_path="${md_file#"$target_dir"/}"
    [[ "$rel_path" == .bootstrap/* || "$rel_path" == */.bootstrap/* ]] && continue
    local hit
    hit=$(awk '
      NR==1 && /^---[[:space:]]*$/ { front=1; next }
      front && /^---[[:space:]]*$/ { front=0; next }
      front { next }
      {
        line=$0
        while (1) {
          if (comment) {
            if (match(line, /-->/)) { line=substr(line, RSTART + RLENGTH); comment=0; continue }
            line=""; break
          }
          if (match(line, /<!--/)) {
            before=substr(line, 1, RSTART - 1); rest=substr(line, RSTART + RLENGTH)
            if (match(rest, /-->/)) { line=before substr(rest, RSTART + RLENGTH); continue }
            line=before; comment=1; break
          }
          break
        }
        if (line != "") print FNR ":" line
      }
    ' "$md_file" | grep -E "$meta_leakage_tokens" | head -3 || true)
    if [[ -n "$hit" ]]; then
      local first_hit_line
      first_hit_line=$(printf '%s\n' "$hit" | head -1 | cut -d: -f1)
      local first_hit_text
      first_hit_text=$(printf '%s\n' "$hit" | head -1 | cut -d: -f2- | head -c 120)
      add_fail "[META-LEAKAGE] $md_file:$first_hit_line -- reader prose carries SSOT authoring or self-maintenance machinery; move it to the protocol/register/manifest owner: $first_hit_text"
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

document_quality_status_version() {
  local status_file="$SSOT_DIR/STATUS.md" exact
  [[ -f "$status_file" ]] || return 1
  # v2.60 makes Event-Source Coverage the sole owner. A similarly named row in
  # prose or a later table must not shadow that tracking baseline. Legacy documents did
  # not have the exact section, so retain the old fallback only for that shape.
  exact=$(awk '
    function trim(v){gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", v); return v}
    /^##[[:space:]]+/ {
      title=$0; sub(/^##[[:space:]]+/, "", title)
      active=(tolower(trim(title))=="event-source coverage" || trim(title)=="事件源覆盖")
      if(active) found=1
      next
    }
    active && /^\|/ {
      count=split($0,cells,"|")
      if(trim(cells[2])=="tracked_skill_version") {
        value=trim(cells[3]); if(match(value,/[0-9]+\.[0-9]+/)) print substr(value,RSTART,RLENGTH)
      }
    }
    END { if(found) exit 0; else exit 4 }
  ' "$status_file" 2>/dev/null) || true
  if awk '
    function trim(v){gsub(/^[[:space:]]+|[[:space:]]+$/, "", v);return v}
    /^##[[:space:]]+/ {v=$0;sub(/^##[[:space:]]+/,"",v);v=trim(v);if(tolower(v)=="event-source coverage"||v=="事件源覆盖")found=1}
    END{exit(found?0:1)}
  ' "$status_file"; then
    printf '%s\n' "$exact" | sed '/^$/d' | head -1
    return
  fi
  grep -E '(\|\s*tracked_skill_version\s*\||^tracked_skill_version:)' "$status_file" | \
    head -n 1 | grep -oE '[0-9]+\.[0-9]+' | head -n 1
}

document_quality_v260_active() {
  local version status_file="$SSOT_DIR/STATUS.md"
  [[ -f "$status_file" ]] || return 1
  # Any real tracking baseline row at or above v2.60 activates the stricter parser. A
  # duplicate or misplaced row is then reported as an error; it cannot disable
  # the gate by appearing before the authoritative row.
  while IFS= read -r version; do
    [[ -n "$version" ]] && version_ge "$version" "2.60" && return 0
  done < <(grep -E '(\|[[:space:]]*tracked_skill_version[[:space:]]*\||^tracked_skill_version:)' "$status_file" | grep -oE '[0-9]+\.[0-9]+' || true)
  return 1
}

document_area_is_covered() { # $1=semantic Area Status token
  [[ -f "$SSOT_DIR/STATUS.md" ]] || return 1
  grep -qE "^\|[[:space:]]*${1// /[[:space:]]+}[[:space:]]*\|[[:space:]]*covered[[:space:]]*\|" "$SSOT_DIR/STATUS.md"
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

manifest_product_surface_table() { # $1=product-root manifest
  awk '
    function is_header(line, lower) {
      lower=tolower(line)
      return (lower ~ /surface id/ || line ~ /表面[[:space:]]*ID/) && \
        (lower ~ /surface class/ || line ~ /表面类别/) && \
        (lower ~ /source surface anchor/ || line ~ /源表面锚点/) && \
        (lower ~ /product owner/ || line ~ /产品所有者/) && \
        (lower ~ /product maturity/ || line ~ /产品成熟度/) && \
        (lower ~ /evidence fidelity/ || line ~ /证据保真度/) && \
        (lower ~ /(stable evidence|closure)/ || line ~ /稳定证据|闭合/)
    }
    !active && /^\|/ && is_header($0) { active=1; print; next }
    active && /^\|/ { print; next }
    active { exit }
  ' "$1"
}

trim_table_cell() {
  printf '%s' "$1" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'
}

manifest_markdown_link_resolved_path() { # $1=manifest $2=cell
  local manifest="$1" cell="$2" target candidate project_root resolved
  target=$(printf '%s\n' "$cell" | sed -nE 's@.*\]\(([^)#]+\.md)(#[^)]*)?\).*@\1@p' | head -1)
  [[ -n "$target" ]] || return 1
  case "$target" in
    /*) return 1 ;;
    SSOT/*)
      project_root=$(cd "$(dirname "$SSOT_DIR")" && pwd -P)
      candidate="$project_root/$target"
      ;;
    *) candidate="$(dirname "$manifest")/$target" ;;
  esac
  [[ -f "$candidate" ]] || return 1
  resolved=$(realpath "$candidate" 2>/dev/null) || return 1
  [[ -f "$resolved" ]] || return 1
  project_root=$(cd "$(dirname "$SSOT_DIR")" && pwd -P)
  [[ "$resolved" == "$project_root/"* ]] || return 1
  printf '%s\n' "$resolved"
}

manifest_markdown_link_resolves() { # $1=manifest $2=cell
  manifest_markdown_link_resolved_path "$1" "$2" >/dev/null
}

manifest_markdown_link_count() { # $1=cell; count Markdown links to .md owners
  printf '%s\n' "$1" | awk '
    {
      value=$0
      while (match(value, /\[[^][]+\]\([^()]+[.]md(#[^()]*)?\)/)) {
        count++
        value=substr(value, RSTART + RLENGTH)
      }
    }
    END { print count + 0 }
  '
}

markdown_link_fragment() { # $1=cell; first Markdown .md link fragment without '#'
  printf '%s\n' "$1" | sed -nE 's@.*\]\([^)]*[.]md#([^)]*)\).*@\1@p' | head -1
}

markdown_heading_slug() { # stdin=heading text; GitHub-compatible for protocol headings
  sed -E 's/-/ZZHYPHENZZ/g; s/_/ZZUNDERSCOREZZ/g; s/<[^>]*>//g; s/[[:punct:]]//g; s/[[:space:]]+/-/g; s/^-+//; s/-+$//' | \
    tr '[:upper:]' '[:lower:]' | sed -E 's/zzhyphenzz/-/g; s/zzunderscorezz/_/g'
}

markdown_file_has_fragment() { # $1=file $2=fragment
  local file="$1" wanted="$2" heading slug
  [[ -n "$wanted" ]] || return 0
  while IFS= read -r heading; do
    slug=$(printf '%s\n' "$heading" | markdown_heading_slug)
    [[ "$slug" == "$wanted" ]] && return 0
  done < <(awk '
    BEGIN{fence=0;comment=0}
    {
      line=$0
      if(comment){if(line~/-->/)comment=0;next}
      if(line~/<!--/){if(line!~/-->/)comment=1;next}
      if(line~/^[[:space:]]*```/){fence=!fence;next}
      if(!fence && line~/^#{1,6}[[:space:]]+/){sub(/^#{1,6}[[:space:]]+/,"",line);sub(/[[:space:]]+#+[[:space:]]*$/,"",line);print line}
    }
  ' "$file")
  return 1
}

markdown_link_resolves_with_anchor() { # $1=owner document $2=cell
  local owner="$1" cell="$2" resolved fragment
  resolved=$(manifest_markdown_link_resolved_path "$owner" "$cell" 2>/dev/null || true)
  [[ -n "$resolved" ]] || return 1
  fragment=$(markdown_link_fragment "$cell")
  [[ -z "$fragment" ]] || markdown_file_has_fragment "$resolved" "$fragment"
}

# Normalize lexical spelling without following links or requiring any component.
lexical_path() {
  [[ -n "$1" ]] || return 1
  python3 -c 'import os,sys; print("/" + os.path.abspath(sys.argv[1]).lstrip("/"))' "$1"
}

markdown_link_uses_symlink_path() { # $1=owner document $2=cell; success means unsafe
  local owner="$1" cell="$2" target candidate project_root lexical resolved
  target=$(printf '%s\n' "$cell" | sed -nE 's@.*\]\(([^)#]+\.md)(#[^)]*)?\).*@\1@p' | head -1)
  [[ -n "$target" && "$target" != /* ]] || return 1
  project_root=$(cd "$(dirname "$SSOT_DIR")" && pwd -P)
  if [[ "$target" == SSOT/* ]]; then candidate="$project_root/$target"; else candidate="$(dirname "$owner")/$target"; fi
  [[ -e "$candidate" ]] || return 1
  lexical=$(lexical_path "$candidate" 2>/dev/null) || return 1
  resolved=$(realpath "$candidate" 2>/dev/null) || return 1
  [[ "$lexical" != "$resolved" ]]
}

cell_has_resolvable_project_file() { # $1=cell
  local cell="$1" project_root candidate
  project_root=$(cd "$(dirname "$SSOT_DIR")" && pwd -P)
  while IFS= read -r candidate; do
    candidate="${candidate#path:}"
    candidate="${candidate#evidence:}"
    candidate="${candidate#证据:}"
    candidate="${candidate%%::*}"
    candidate="${candidate%%#*}"
    candidate=$(trim_table_cell "$candidate")
    [[ -n "$candidate" && "$candidate" != /* && "$candidate" != SSOT/* && "$candidate" != *://* ]] || continue
    [[ -f "$project_root/$candidate" ]] && return 0
  done < <(
    printf '%s\n' "$cell" | grep -oE '`[^`]+`' | tr -d '`' || true
    printf '%s\n' "$cell" | tr -d '`' | grep -oE '([[:alnum:]_.-]+/)+[[:alnum:]_.-]+' || true
  )
  return 1
}

cell_has_stable_runtime_anchor() { # $1=cell
  local value
  value=$(printf '%s' "$1" | tr -d '`')
  [[ "$value" =~ runtime:(route|command|selector|endpoint|signal):[^[:space:]]{3,} ]]
}

manifest_architecture_owner_table() { # $1=architecture-root manifest
  awk '
    function is_header(line, lower) {
      lower=tolower(line)
      return (lower ~ /owner id/ || line ~ /所有者[[:space:]]*ID/) && \
        (lower ~ /owner class/ || line ~ /所有者类别/) && \
        (lower ~ /narrative owner/ || line ~ /叙事所有者/) && \
        (lower ~ /current state/ || line ~ /当前状态/) && \
        (lower ~ /(evidence|closure)/ || line ~ /证据|闭合/)
    }
    !active && /^\|/ && is_header($0) { active=1; print; next }
    active && /^\|/ { print; next }
    active { exit }
  ' "$1"
}

manifest_architecture_surface_table() { # $1=architecture-root manifest
  awk '
    function is_header(line, lower) {
      lower=tolower(line)
      return (lower ~ /technical surface id/ || line ~ /技术表面[[:space:]]*ID/) && \
        (lower ~ /surface kind/ || line ~ /表面类型/) && \
        (lower ~ /narrative owner/ || line ~ /叙事所有者/) && \
        (lower ~ /current state/ || line ~ /当前状态/) && \
        (lower ~ /stable anchor/ || line ~ /稳定锚点/) && \
        (lower ~ /(evidence|closure)/ || line ~ /证据|闭合/)
    }
    !active && /^\|/ && is_header($0) { active=1; print; next }
    active && /^\|/ { print; next }
    active { exit }
  ' "$1"
}

manifest_architecture_product_bridge_table() { # $1=architecture-root manifest
  awk '
    function is_header(line, lower) {
      lower=tolower(line)
      return (lower ~ /product surface id/ || line ~ /产品表面[[:space:]]*ID/) && \
        (lower ~ /runtime owner id/ || line ~ /运行时所有者[[:space:]]*ID/) && \
        (lower ~ /contract or state boundary/ || line ~ /契约或状态边界/) && \
        (lower ~ /failure or operations view/ || line ~ /失败或运维视图/)
    }
    !active && /^\|/ && is_header($0) { active=1; print; next }
    active && /^\|/ { print; next }
    active { exit }
  ' "$1"
}

manifest_architecture_kind_disposition_table() { # $1=architecture-root manifest
  awk '
    function is_header(line, lower) {
      lower=tolower(line)
      return (lower ~ /surface kind/ || line ~ /表面类型/) && \
        (lower ~ /disposition/ || line ~ /处置/) && \
        (lower ~ /registered surfaces/ || line ~ /已登记表面/) && \
        (lower ~ /(reason|evidence)/ || line ~ /原因|证据/)
    }
    !active && /^\|/ && is_header($0) { active=1; print; next }
    active && /^\|/ { print; next }
    active { exit }
  ' "$1"
}

validate_v260_product_surface_inventory() { # $1=product-root manifest
  local manifest="$1" table invalid duplicate class class_disposition row_number=0
  local ignored id surface_class source_anchor owner maturity fidelity closure normalized_source owner_link_count
  table=$(manifest_product_surface_table "$manifest")
  [[ -n "$table" ]] || { printf 'missing the finite user-visible surface table'; return 1; }
  invalid=$(printf '%s\n' "$table" | awk -F'|' '
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/`/, "", v); return v }
    NR <= 2 { next }
    /^\|/ {
      id=trim($2); class=trim($3); source=trim($4); owner=trim($5); maturity=trim($6); fidelity=trim($7); closure=trim($8)
      if (id !~ /^surface:[a-z0-9][a-z0-9-]*$/) { print "invalid surface ID " id; exit }
      if (class !~ /^(page|navigation|entry-mode|control|settings|diagnostic|external-channel|command|public-interface|output-artifact|notification|help-onboarding)$/) { print "invalid surface class " class; exit }
      if (length(source) < 4) { print "missing source surface anchor for " id; exit }
      if (length(owner) < 3) { print "missing product owner for " id; exit }
      if (maturity !~ /^(current|limited|target|out)$/) { print "invalid product maturity for " id; exit }
      if (fidelity !~ /^(browser|integration|unit|static|missing)$/) { print "invalid evidence fidelity for " id; exit }
      if (length(closure) < 8) { print "missing evidence or closure for " id; exit }
    }
  ')
  [[ -z "$invalid" ]] || { printf '%s' "$invalid"; return 1; }
  while IFS='|' read -r ignored id surface_class source_anchor owner maturity fidelity closure ignored; do
    row_number=$((row_number + 1))
    (( row_number <= 2 )) && continue
    id=$(trim_table_cell "$id"); id="${id//\`/}"
    source_anchor=$(trim_table_cell "$source_anchor"); normalized_source=$(printf '%s' "$source_anchor" | tr -d '`')
    owner=$(trim_table_cell "$owner")
    maturity=$(trim_table_cell "$maturity"); maturity="${maturity//\`/}"
    fidelity=$(trim_table_cell "$fidelity"); fidelity="${fidelity//\`/}"
    closure=$(trim_table_cell "$closure")
    owner_link_count=$(manifest_markdown_link_count "$owner")
    [[ "$owner_link_count" -eq 1 ]] || { printf 'product owner cell must contain exactly one Markdown owner link for %s (got %s)' "$id" "$owner_link_count"; return 1; }
    manifest_markdown_link_resolves "$manifest" "$owner" || { printf 'product owner Markdown link does not resolve for %s' "$id"; return 1; }
    if [[ "$normalized_source" =~ ^planned_in:[[:space:]]+ ]]; then
      [[ "$maturity" == "target" && "$fidelity" == "missing" ]] || { printf 'planned_in surface %s must use maturity target and fidelity missing' "$id"; return 1; }
      [[ "$(manifest_markdown_link_count "$source_anchor")" -eq 1 ]] || { printf 'planned_in surface %s must contain exactly one product roadmap or acceptance owner link' "$id"; return 1; }
      manifest_markdown_link_resolves "$manifest" "$source_anchor" || { printf 'planned_in surface %s must link a resolvable product roadmap or acceptance owner' "$id"; return 1; }
      [[ "$closure" =~ (closure|闭合):[[:space:]]*.{8,} ]] || { printf 'planned_in surface %s needs a falsifiable named closure' "$id"; return 1; }
      continue
    fi
    if [[ "$normalized_source" =~ ^not_applicable:[[:space:]]+.{8,}$ ]]; then
      [[ "$maturity" == "out" && "$fidelity" == "static" ]] || { printf 'not_applicable surface %s must use maturity out and fidelity static' "$id"; return 1; }
      [[ "$closure" =~ (disposition|closure|处置|闭合):[[:space:]]*.{8,} ]] || { printf 'not_applicable surface %s needs a named disposition or closure reason' "$id"; return 1; }
      continue
    fi
    cell_has_resolvable_project_file "$source_anchor" || { printf 'source surface anchor does not resolve to a repository file for %s' "$id"; return 1; }
    if [[ "$maturity" =~ ^(current|limited)$ ]]; then
      cell_has_resolvable_project_file "$closure" || cell_has_stable_runtime_anchor "$closure" || { printf 'current or limited surface %s needs resolvable evidence or a stable runtime anchor' "$id"; return 1; }
    elif ! cell_has_resolvable_project_file "$closure" && ! cell_has_stable_runtime_anchor "$closure" && [[ ! "$closure" =~ (closure|disposition|闭合|处置):[[:space:]]*.{8,} ]]; then
      printf 'target or out surface %s needs resolvable evidence or a named closure' "$id"
      return 1
    fi
  done <<< "$table"
  duplicate=$(printf '%s\n' "$table" | awk -F'|' 'NR > 2 && /^\|/ { id=$2; gsub(/[[:space:]`]/, "", id); print id }' | sort | uniq -d | head -1)
  [[ -z "$duplicate" ]] || { printf 'duplicate surface ID %s' "$duplicate"; return 1; }
  class_disposition=$(printf '%s\n' "$table" | awk -F'|' '
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/`/, "", v); return v }
    BEGIN {
      names="page navigation entry-mode control settings diagnostic external-channel command public-interface output-artifact notification help-onboarding"
      n=split(names, list, " "); for (i=1; i<=n; i++) required[list[i]]=1
    }
    NR > 2 && /^\|/ {
      class=trim($3); source=trim($4)
      if (source ~ /^not_applicable:[[:space:]]+/) absent[class]++
      else real[class]++
    }
    END {
      for (class in required) {
        if (real[class] > 0 && absent[class] > 0) { print class ": real and not_applicable rows coexist"; exit }
        if (real[class] == 0 && absent[class] != 1) { print class ": expected exactly one reasoned not_applicable row, got " absent[class] + 0; exit }
      }
    }
  ')
  [[ -z "$class_disposition" ]] || { printf 'surface class disposition must use real items XOR exactly one reasoned not_applicable row (%s)' "$class_disposition"; return 1; }
  return 0
}

validate_v260_architecture_owner_inventory() { # $1=architecture-root manifest
  local manifest="$1" owner_table surface_table bridge_table kind_table product_table invalid duplicate class domain base
  local architecture_abs domain_count owner_row_count row_number=0 ignored id owner_class owner state closure owner_path owner_paths="" owner_ids=""
  local kind anchor normalized_anchor anchors="" tech_ids="" disposition registered reason surface_count kind_row_count
  local expected_registered actual_registered registered_id registered_kind
  local bridge_rows=0 surface_id boundary view view_path project_root product_maturity product_ids bridge_ids
  architecture_abs=$(cd "$ARCHITECTURE_DIR" && pwd -P)
  project_root=$(cd "$(dirname "$SSOT_DIR")" && pwd -P)
  owner_table=$(manifest_architecture_owner_table "$manifest")
  [[ -n "$owner_table" ]] || { printf 'missing the direct owner classification table'; return 1; }
  invalid=$(printf '%s\n' "$owner_table" | awk -F'|' '
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/`/, "", v); return v }
    NR <= 2 { next }
    /^\|/ {
      id=trim($2); class=trim($3); owner=trim($4); state=trim($5); closure=trim($6)
      if (id !~ /^owner:[a-z0-9][a-z0-9-]*$/) { print "invalid owner ID " id; exit }
      if (class !~ /^(runtime|support|target)$/) { print "invalid owner class " class; exit }
      if (length(owner) < 3) { print "missing narrative owner for " id; exit }
      if (state !~ /^(contract|design|poc|debt|mixed)$/) { print "invalid current state for " id; exit }
      if (length(closure) < 8 || closure !~ /(\/|::|#|closure:|evidence:|闭合:|证据:|https?:)/) { print "non-stable evidence or closure for " id; exit }
    }
  ')
  [[ -z "$invalid" ]] || { printf '%s' "$invalid"; return 1; }
  duplicate=$(printf '%s\n' "$owner_table" | awk -F'|' 'NR > 2 && /^\|/ { id=$2; gsub(/[[:space:]`]/, "", id); print id }' | sort | uniq -d | head -1)
  [[ -z "$duplicate" ]] || { printf 'duplicate owner ID %s' "$duplicate"; return 1; }
  domain_count=$(find "$ARCHITECTURE_DIR" -mindepth 1 -maxdepth 1 -type d -name '[0-9][0-9]-*' -print 2>/dev/null | wc -l | tr -d ' ')
  owner_row_count=$(printf '%s\n' "$owner_table" | awk 'NR > 2 && /^\|/ { rows++ } END { print rows + 0 }')
  [[ "$owner_row_count" == "$domain_count" ]] || { printf 'direct numbered domain count %s does not match owner row count %s' "$domain_count" "$owner_row_count"; return 1; }
  while IFS='|' read -r ignored id owner_class owner state closure ignored; do
    row_number=$((row_number + 1))
    (( row_number <= 2 )) && continue
    id=$(trim_table_cell "$id"); id="${id//\`/}"
    owner=$(trim_table_cell "$owner")
    [[ $(printf '%s\n' "$owner" | grep -oE '\]\([^)]+\.md(#[^)]*)?\)' | wc -l | tr -d ' ') == "1" ]] || { printf 'owner %s must contain exactly one Markdown owner link' "$id"; return 1; }
    owner_path=$(manifest_markdown_link_resolved_path "$manifest" "$owner" 2>/dev/null || true)
    [[ -n "$owner_path" && "$owner_path" == "$architecture_abs"/[0-9][0-9]-*/README.md ]] || { printf 'owner %s must resolve to one direct numbered domain README' "$id"; return 1; }
    owner_paths+="$owner_path"$'\n'
    owner_ids+="$id"$'\n'
  done <<< "$owner_table"
  duplicate=$(printf '%s' "$owner_paths" | sed '/^$/d' | sort | uniq -d | head -1)
  [[ -z "$duplicate" ]] || { printf 'direct domain README is registered by more than one owner row: %s' "$duplicate"; return 1; }
  while IFS= read -r -d '' domain; do
    base=$(basename "$domain")
    owner_path="$(cd "$domain" && pwd -P)/README.md"
    [[ $(printf '%s' "$owner_paths" | grep -Fxc "$owner_path" || true) == "1" ]] || { printf 'direct owner %s must have exactly one owner row' "$base"; return 1; }
  done < <(find "$ARCHITECTURE_DIR" -mindepth 1 -maxdepth 1 -type d -name '[0-9][0-9]-*' -print0 2>/dev/null || true)

  surface_table=$(manifest_architecture_surface_table "$manifest")
  [[ -n "$surface_table" ]] || { printf 'missing the unique technical surface registry'; return 1; }
  invalid=$(printf '%s\n' "$surface_table" | awk -F'|' '
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/`/, "", v); return v }
    NR <= 2 { next }
    /^\|/ {
      id=trim($2); kind=trim($3); owner=trim($4); state=trim($5); anchor=trim($6); closure=trim($7)
      if (id !~ /^tech:[a-z0-9][a-z0-9-]*$/) { print "invalid technical surface ID " id; exit }
      if (kind !~ /^(entry|write-store|contract|operator-surface|external-integration)$/) { print "invalid technical surface kind " kind; exit }
      if (owner !~ /^owner:[a-z0-9][a-z0-9-]*$/) { print "technical surface does not reference a registered owner ID for " id; exit }
      if (state !~ /^(contract|design|poc|debt|mixed)$/) { print "invalid current state for " id; exit }
      if (length(anchor) < 4 || length(closure) < 8 || closure !~ /(\/|::|#|closure:|evidence:|闭合:|证据:|https?:)/) { print "missing stable anchor or evidence for " id; exit }
    }
  ')
  [[ -z "$invalid" ]] || { printf '%s' "$invalid"; return 1; }
  duplicate=$(printf '%s\n' "$surface_table" | awk -F'|' 'NR > 2 && /^\|/ { id=$2; gsub(/[[:space:]`]/, "", id); print id }' | sort | uniq -d | head -1)
  [[ -z "$duplicate" ]] || { printf 'duplicate technical surface ID %s' "$duplicate"; return 1; }
  row_number=0
  while IFS='|' read -r ignored id kind owner state anchor closure ignored; do
    row_number=$((row_number + 1))
    (( row_number <= 2 )) && continue
    id=$(trim_table_cell "$id"); id="${id//\`/}"
    owner=$(trim_table_cell "$owner"); owner="${owner//\`/}"
    anchor=$(trim_table_cell "$anchor"); normalized_anchor=$(printf '%s' "$anchor" | tr -d '`[:space:]')
    printf '%s' "$owner_ids" | grep -Fqx "$owner" || { printf 'technical surface %s references unregistered owner %s' "$id" "$owner"; return 1; }
    cell_has_resolvable_project_file "$anchor" || { printf 'technical surface %s has an unresolvable stable anchor' "$id"; return 1; }
    anchors+="$normalized_anchor"$'\n'
    tech_ids+="$id"$'\n'
  done <<< "$surface_table"
  duplicate=$(printf '%s' "$anchors" | sed '/^$/d' | sort | uniq -d | head -1)
  [[ -z "$duplicate" ]] || { printf 'stable technical anchor is reused across registry rows: %s' "$duplicate"; return 1; }

  kind_table=$(manifest_architecture_kind_disposition_table "$manifest")
  [[ -n "$kind_table" ]] || { printf 'missing the technical surface kind disposition table'; return 1; }
  kind_row_count=$(printf '%s\n' "$kind_table" | awk 'NR > 2 && /^\|/ { rows++ } END { print rows + 0 }')
  [[ "$kind_row_count" == "5" ]] || { printf 'technical surface kind disposition table must contain exactly five rows'; return 1; }
  duplicate=$(printf '%s\n' "$kind_table" | awk -F'|' 'NR > 2 && /^\|/ { kind=$2; gsub(/[[:space:]`]/, "", kind); print kind }' | sort | uniq -d | head -1)
  [[ -z "$duplicate" ]] || { printf 'duplicate technical surface kind disposition %s' "$duplicate"; return 1; }
  for class in entry write-store contract operator-surface external-integration; do
    disposition=$(printf '%s\n' "$kind_table" | awk -F'|' -v wanted="$class" '
      function trim(v) { gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", v); return v }
      NR > 2 && /^\|/ && trim($2) == wanted { print trim($3); exit }
    ')
    registered=$(printf '%s\n' "$kind_table" | awk -F'|' -v wanted="$class" '
      function trim(v) { gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", v); return v }
      NR > 2 && /^\|/ && trim($2) == wanted { print $4; exit }
    ')
    reason=$(printf '%s\n' "$kind_table" | awk -F'|' -v wanted="$class" '
      function trim(v) { gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", v); return v }
      NR > 2 && /^\|/ && trim($2) == wanted { print trim($5); exit }
    ')
    [[ "$disposition" =~ ^(applicable|not_applicable)$ ]] || { printf 'surface kind %s needs applicable or not_applicable disposition' "$class"; return 1; }
    surface_count=$(printf '%s\n' "$surface_table" | awk -F'|' -v wanted="$class" '
      function trim(v) { gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", v); return v }
      NR > 2 && /^\|/ && trim($3) == wanted { rows++ } END { print rows + 0 }
    ')
    expected_registered=$(printf '%s\n' "$surface_table" | awk -F'|' -v wanted="$class" '
      function trim(v) { gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", v); return v }
      NR > 2 && /^\|/ && trim($3) == wanted { print trim($2) }
    ' | LC_ALL=C sort)
    actual_registered=$(printf '%s\n' "$registered" | grep -oE 'tech:[a-z0-9][a-z0-9-]*' || true)
    duplicate=$(printf '%s\n' "$actual_registered" | sed '/^$/d' | LC_ALL=C sort | uniq -d | head -1)
    [[ -z "$duplicate" ]] || { printf 'surface kind %s names registered surface %s more than once' "$class" "$duplicate"; return 1; }
    for registered_id in $actual_registered; do
      printf '%s' "$tech_ids" | grep -Fqx "$registered_id" || { printf 'surface kind %s names unregistered technical surface %s' "$class" "$registered_id"; return 1; }
      registered_kind=$(printf '%s\n' "$surface_table" | awk -F'|' -v wanted="$registered_id" '
        function trim(v) { gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", v); return v }
        NR > 2 && /^\|/ && trim($2) == wanted { print trim($3); exit }
      ')
      [[ "$registered_kind" == "$class" ]] || { printf 'surface kind %s names %s of kind %s' "$class" "$registered_id" "$registered_kind"; return 1; }
    done
    if [[ "$disposition" == "applicable" ]]; then
      (( surface_count >= 1 )) || { printf 'applicable surface kind %s has no registry row' "$class"; return 1; }
      [[ "$(printf '%s\n' "$actual_registered" | sed '/^$/d' | LC_ALL=C sort)" == "$expected_registered" ]] || { printf 'applicable surface kind %s must name every registry row of that kind exactly once' "$class"; return 1; }
    else
      [[ "$surface_count" == "0" ]] || { printf 'not_applicable surface kind %s still has registry rows' "$class"; return 1; }
      [[ -z "$actual_registered" ]] || { printf 'not_applicable surface kind %s must not name registered surfaces' "$class"; return 1; }
      (( ${#reason} >= 8 )) || { printf 'not_applicable surface kind %s needs a named reason' "$class"; return 1; }
    fi
  done

  bridge_table=$(manifest_architecture_product_bridge_table "$manifest")
  [[ -n "$bridge_table" ]] || { printf 'missing the product-to-architecture bridge'; return 1; }
  product_table=$(manifest_product_surface_table "$PRODUCT_DIR/_manifest.md" 2>/dev/null || true)
  [[ -n "$product_table" ]] || { printf 'product-to-architecture bridge cannot resolve the product surface inventory'; return 1; }
  row_number=0
  while IFS='|' read -r ignored surface_id owner boundary view ignored; do
    row_number=$((row_number + 1))
    (( row_number <= 2 )) && continue
    bridge_rows=$((bridge_rows + 1))
    surface_id=$(trim_table_cell "$surface_id"); surface_id="${surface_id//\`/}"
    owner=$(trim_table_cell "$owner"); owner="${owner//\`/}"
    boundary=$(trim_table_cell "$boundary")
    view=$(trim_table_cell "$view")
    [[ "$surface_id" =~ ^surface:[a-z0-9][a-z0-9-]*$ ]] || { printf 'bridge row has invalid product surface ID %s' "$surface_id"; return 1; }
    printf '%s\n' "$product_table" | awk -F'|' -v wanted="$surface_id" '
      function trim(v) { gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", v); return v }
      NR > 2 && /^\|/ && trim($2) == wanted { found=1 } END { exit(found ? 0 : 1) }
    ' || { printf 'bridge surface %s is absent from the product inventory' "$surface_id"; return 1; }
    product_maturity=$(printf '%s\n' "$product_table" | awk -F'|' -v wanted="$surface_id" '
      function trim(v) { gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", v); return v }
      NR > 2 && /^\|/ && trim($2) == wanted { print trim($6); exit }
    ')
    if [[ "$product_maturity" == "out" ]]; then
      [[ "$owner" =~ ^not_applicable:[[:space:]]+.{8,}$ ]] || { printf 'out surface %s bridge must use a reasoned not_applicable runtime-owner disposition' "$surface_id"; return 1; }
      [[ "$boundary" =~ ^not_applicable:[[:space:]]+.{8,}$ && "$view" =~ ^not_applicable:[[:space:]]+.{8,}$ ]] || { printf 'out surface %s bridge must dispose boundary and view as not_applicable with reasons' "$surface_id"; return 1; }
    else
      printf '%s' "$owner_ids" | grep -Fqx "$owner" || { printf 'bridge surface %s references unregistered owner %s' "$surface_id" "$owner"; return 1; }
      (( ${#boundary} >= 4 )) || { printf 'bridge surface %s has no contract or state boundary' "$surface_id"; return 1; }
      [[ $(printf '%s\n' "$view" | grep -oE '\]\([^)]+\.md(#[^)]*)?\)' | wc -l | tr -d ' ') == "1" ]] || { printf 'bridge surface %s needs exactly one Markdown view link' "$surface_id"; return 1; }
      view_path=$(manifest_markdown_link_resolved_path "$manifest" "$view" 2>/dev/null || true)
      [[ -n "$view_path" && "$view_path" == "$architecture_abs/views/"* ]] || { printf 'bridge surface %s view link does not resolve under architecture/views' "$surface_id"; return 1; }
    fi
  done <<< "$bridge_table"
  (( bridge_rows >= 1 )) || { printf 'product-to-architecture bridge has no routed row'; return 1; }
  duplicate=$(printf '%s\n' "$bridge_table" | awk -F'|' 'NR > 2 && /^\|/ { id=$2; gsub(/[[:space:]`]/, "", id); print id }' | sort | uniq -d | head -1)
  [[ -z "$duplicate" ]] || { printf 'duplicate product surface bridge row %s' "$duplicate"; return 1; }
  duplicate=$(printf '%s\n' "$product_table" | awk -F'|' 'NR > 2 && /^\|/ { id=$2; gsub(/[[:space:]`]/, "", id); print id }' | sort | uniq -d | head -1)
  [[ -z "$duplicate" ]] || { printf 'duplicate product inventory surface ID %s prevents exact bridge coverage' "$duplicate"; return 1; }
  product_ids=$(printf '%s\n' "$product_table" | awk -F'|' 'NR > 2 && /^\|/ { id=$2; gsub(/[[:space:]`]/, "", id); print id }' | LC_ALL=C sort)
  bridge_ids=$(printf '%s\n' "$bridge_table" | awk -F'|' 'NR > 2 && /^\|/ { id=$2; gsub(/[[:space:]`]/, "", id); print id }' | LC_ALL=C sort)
  [[ "$bridge_ids" == "$product_ids" ]] || { printf 'product-to-architecture bridge IDs must exactly equal the product surface inventory, including target and out dispositions'; return 1; }
  return 0
}

review_visible_markdown() { # $1=Markdown; strips frontmatter, HTML comments, and fenced blocks
  awk '
    BEGIN{front=fence=comment=0}
    NR==1&&/^---[[:space:]]*$/{front=1;next}
    front{if(/^---[[:space:]]*$/)front=0;next}
    {
      line=$0
      while(1){
        if(comment){if(match(line,/-->/)){line=substr(line,RSTART+RLENGTH);comment=0;continue};line="";break}
        if(match(line,/<!--/)){
          before=substr(line,1,RSTART-1);rest=substr(line,RSTART+RLENGTH)
          if(match(rest,/-->/)){line=before substr(rest,RSTART+RLENGTH);continue}
          line=before;comment=1;break
        }
        break
      }
      if(line~/^[[:space:]]*(```|~~~)/){fence=!fence;next}
      if(!fence&&line!="")print line
    }
  ' "$1"
}

strict_review_artifact_path() { # $1=owner $2=cell; emits a real file under SSOT/.bootstrap
  local owner="$1" cell="$2" target candidate project_root lexical resolved bootstrap_real
  [[ "$(manifest_markdown_link_count "$cell")" -eq 1 ]] || return 1
  target=$(printf '%s\n' "$cell" | sed -nE 's@.*\]\(([^)#]+\.md)(#[^)]*)?\).*@\1@p' | head -1)
  [[ -n "$target" && "$target" != /* && "$target" != *://* ]] || return 1
  project_root=$(cd "$(dirname "$SSOT_DIR")" && pwd -P)
  if [[ "$target" == SSOT/* ]]; then candidate="$project_root/$target"; else candidate="$(dirname "$owner")/$target"; fi
  [[ -d "$SSOT_DIR/.bootstrap" && ! -L "$SSOT_DIR/.bootstrap" && -f "$candidate" && ! -L "$candidate" ]] || return 1
  lexical=$(lexical_path "$candidate" 2>/dev/null) || return 1
  resolved=$(realpath "$candidate" 2>/dev/null) || return 1
  bootstrap_real=$(realpath "$SSOT_DIR/.bootstrap" 2>/dev/null) || return 1
  [[ "$lexical" == "$resolved" && "$resolved" == "$bootstrap_real/"* ]] || return 1
  ! find "$SSOT_DIR/.bootstrap" -type l -print -quit 2>/dev/null | grep -q . || return 1
  printf '%s\n' "$resolved"
}

manifest_review_artifact_path() { # $1=manifest
  local manifest="$1" line target resolved project_root
  if document_quality_v260_active; then
    while IFS= read -r line; do
      [[ "${line,,}" == *no-more-required-changes* ]] || continue
      resolved=$(strict_review_artifact_path "$manifest" "$line" 2>/dev/null || true)
      [[ -n "$resolved" ]] || continue
      printf '%s\n' "$resolved"
      return 0
    done < <(review_visible_markdown "$manifest")
    return 1
  fi
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
    if [[ -f "$resolved" ]]; then
      printf '%s\n' "$resolved"
      return 0
    fi
  done < <(grep -i 'no-more-required-changes' "$manifest" || true)
  return 1
}

review_frontmatter_value() { # $1=artifact $2=key
  yaml_frontmatter "$1" | awk -v key="$2" '
    index($0, key ":") == 1 {
      value=substr($0, length(key) + 2)
      sub(/^[[:space:]]*/, "", value)
      gsub(/^['\''\"]|['\''\"]$/, "", value)
      print value
      exit
    }
  '
}

review_dimension_table() { # $1=review artifact
  review_visible_markdown "$1" | awk '
    function is_header(line, lower) {
      lower=tolower(line)
      return (lower ~ /family/ || line ~ /族/) && \
        (lower ~ /leaf id/ || line ~ /叶维度[[:space:]]*ID/) && \
        (lower ~ /dimension/ || line ~ /维度/) && \
        (lower ~ /applicable task scores/ || line ~ /适用任务得分/) && \
        (lower ~ /score/ || line ~ /得分/) && \
        (lower ~ /reason/ || line ~ /原因/)
    }
    !active && /^\|/ && is_header($0) { active=1; print; next }
    active && /^\|/ { print; next }
    active { exit }
  '
}

review_task_matrix() { # $1=review artifact
  review_visible_markdown "$1" | awk '
    function is_header(line, lower) {
      lower=tolower(line)
      return (lower ~ /task class/ || line ~ /任务类别/) && \
        (lower ~ /reader and decision/ || line ~ /读者与决策/) && \
        (lower ~ /delegated action/ || line ~ /委托动作/) && \
        (lower ~ /expected visible result/ || line ~ /预期可见结果/) && \
        (lower ~ /stop or escalate when/ || line ~ /停止或升级条件/) && \
        (lower ~ /entrypoint/ || line ~ /入口/) && \
        (lower ~ /files opened/ || line ~ /打开的文件/) && \
        (lower ~ /actual hops/ || line ~ /实际跳数/) && \
        (lower ~ /observed outcome/ || line ~ /观察结果/) && \
        (lower ~ /table-hidden result/ || line ~ /隐藏表格结果/) && \
        (lower ~ /evidence and limit/ || line ~ /证据与限制/) && \
        (lower ~ /verdict/ || line ~ /结论/)
    }
    !active && /^\|/ && is_header($0) { active=1; print; next }
    active && /^\|/ { print; next }
    active { exit }
  '
}

review_task_leaf_map() { # $1=review artifact
  review_visible_markdown "$1" | awk '
    function is_header(line, lower) {
      lower=tolower(line)
      return (lower ~ /task class/ || line ~ /任务类别/) && \
        (lower ~ /applicable leaf ids/ || line ~ /适用叶维度[[:space:]]*ID/) && \
        (lower ~ /why applicable/ || line ~ /适用原因/)
    }
    !active && /^\|/ && is_header($0) { active=1; print; next }
    active && /^\|/ { print; next }
    active { exit }
  '
}

review_exact_subheading_count() { # $1=artifact $2=English H3 $3=localized H3
  awk -v english="$2" -v localized="$3" '
    function trim(v){gsub(/^[[:space:]]+|[[:space:]]+$/, "", v);return v}
    BEGIN{front=fence=comment=0}
    NR==1&&/^---[[:space:]]*$/{front=1;next}
    front{if(/^---[[:space:]]*$/)front=0;next}
    {
      line=$0
      if(comment){if(line~/-->/)comment=0;next}
      if(line~/<!--/){if(line!~/-->/)comment=1;next}
      if(line~/^[[:space:]]*(```|~~~)/){fence=!fence;next}
      if(fence)next
    }
    /^###[[:space:]]+/{title=$0;sub(/^###[[:space:]]+/,"",title);title=trim(title);if(title==english||title==localized)n++}
    END{print n+0}
  ' "$1"
}

review_frozen_population_table() { # $1=review artifact
  awk '
    function trim(v){gsub(/^[[:space:]]+|[[:space:]]+$/, "", v);return v}
    function is_heading(v){return tolower(v)=="finite owner and target coverage"||v=="有限所有者与目标覆盖"}
    function is_header(v,l){l=tolower(v);return (l~/frozen population/||v~/冻结清单类别/)&&(l~/source inventory/||v~/来源清单/)&&(l~/expected targets/||v~/应有目标数/)&&(l~/listed targets/||v~/已列目标数/)&&(l~/reconciliation result/||v~/对账结果/)}
    BEGIN{front=fence=comment=0}
    NR==1&&/^---[[:space:]]*$/{front=1;next}front{if(/^---[[:space:]]*$/)front=0;next}
    {line=$0;if(comment){if(line~/-->/)comment=0;next};if(line~/<!--/){if(line!~/-->/)comment=1;next};if(line~/^[[:space:]]*(```|~~~)/){fence=!fence;next};if(fence)next}
    /^###[[:space:]]+/{title=$0;sub(/^###[[:space:]]+/,"",title);title=trim(title);in_section=is_heading(title);active=0;next}
    /^##[[:space:]]+/{in_section=active=0;next}
    in_section&&!active&&/^\|/&&is_header($0){active=1;print;next}
    in_section&&active&&/^\|/{print;next}
    in_section&&active{exit}
  ' "$1"
}

review_full_target_table() { # $1=review artifact
  awk '
    function trim(v){gsub(/^[[:space:]]+|[[:space:]]+$/, "", v);return v}
    function is_heading(v){return tolower(v)=="finite owner and target coverage"||v=="有限所有者与目标覆盖"}
    function is_header(v,l){l=tolower(v);return (l~/target id/||v~/目标[[:space:]]*ID/)&&(l~/target kind/||v~/目标类别/)&&(l~/frozen disposition/||v~/冻结处置/)&&(l~/owner[[:space:]]*\/?[[:space:]]*body/||v~/所有者正文/)&&(l~/assigned mandatory task/||v~/分配到的必做任务/)&&(l~/decision.*delegated action.*visible result/||v~/决定、委托动作与可见结果/)&&(l~/result/||v~/结果/)&&(l~/evidence and limit/||v~/证据与限制/)}
    BEGIN{front=fence=comment=0}
    NR==1&&/^---[[:space:]]*$/{front=1;next}front{if(/^---[[:space:]]*$/)front=0;next}
    {line=$0;if(comment){if(line~/-->/)comment=0;next};if(line~/<!--/){if(line!~/-->/)comment=1;next};if(line~/^[[:space:]]*(```|~~~)/){fence=!fence;next};if(fence)next}
    /^###[[:space:]]+/{title=$0;sub(/^###[[:space:]]+/,"",title);title=trim(title);in_section=is_heading(title);active=0;next}
    /^##[[:space:]]+/{in_section=active=0;next}
    in_section&&!active&&/^\|/&&is_header($0){active=1;print;next}
    in_section&&active&&/^\|/{print;next}
    in_section&&active{exit}
  ' "$1"
}

review_status_closure_table() { # $1=review artifact
  awk '
    function trim(v){gsub(/^[[:space:]]+|[[:space:]]+$/, "", v);return v}
    function is_heading(v){return tolower(v)=="status covered-claim closure"||v=="STATUS 覆盖结论闭环"}
    function is_header(v,l){l=tolower(v);return (l~/status row/||v~/STATUS 行/)&&(l~/scope/||v~/范围/)&&(l~/stop claim/||v~/停止结论/)&&(l~/reviewer/||v~/评审者/)&&(l~/reviewer role/||v~/评审者角色/)&&(l~/reviewed date/||v~/评审日期/)&&(l~/result/||v~/结果/)&&(l~/status evidence resolves to this artifact/||v~/STATUS 证据解析到本产物/)&&(l~/authorises/)&&(l~/match/||v~/匹配结果/)}
    BEGIN{front=fence=comment=0}
    NR==1&&/^---[[:space:]]*$/{front=1;next}front{if(/^---[[:space:]]*$/)front=0;next}
    {line=$0;if(comment){if(line~/-->/)comment=0;next};if(line~/<!--/){if(line!~/-->/)comment=1;next};if(line~/^[[:space:]]*(```|~~~)/){fence=!fence;next};if(fence)next}
    /^###[[:space:]]+/{title=$0;sub(/^###[[:space:]]+/,"",title);title=trim(title);in_section=is_heading(title);active=0;next}
    /^##[[:space:]]+/{in_section=active=0;next}
    in_section&&!active&&/^\|/&&is_header($0){active=1;print;next}
    in_section&&active&&/^\|/{print;next}
    in_section&&active{exit}
  ' "$1"
}

review_table_header_signature() { # stdin=one Markdown header row
  awk -F'|' '
    function trim(v){gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", v);return v}
    {for(i=2;i<NF;i++){v=trim($i);if(v~/^[A-Za-z ,_\/-]+$/)v=tolower(v);printf "%s%s",(i==2?"":"|"),v}print ""}
  '
}

architecture_owner_target_key() { # $1=architecture manifest $2=registered owner ID
  local table owner
  table=$(manifest_architecture_owner_table "$1")
  owner=$(printf '%s\n' "$table" | awk -F'|' -v wanted="$2" '
    function trim(v){gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", v);return v}
    NR>2&&/^\|/&&trim($2)==wanted{print $4;exit}
  ')
  [[ -n "$owner" ]] && strict_ssot_markdown_target_key "$1" "$owner"
}

full_review_population_source_file() { # $1=profile $2=frozen population
  local profile="$1" population="$2" source
  case "$profile|$population" in
    product\|product-reader-owner) source="$PRODUCT_DIR/README.md" ;;
    product\|product-surface) source="$PRODUCT_DIR/_manifest.md" ;;
    product\|product-bridge)
      if [[ -f "$ARCHITECTURE_DIR/_manifest.md" ]]; then source="$ARCHITECTURE_DIR/_manifest.md"; else source="$PRODUCT_DIR/_manifest.md"; fi
      ;;
    architecture\|architecture-reader-owner) source="$ARCHITECTURE_DIR/README.md" ;;
    architecture\|architecture-direct-owner|architecture\|technical-surface|architecture\|architecture-bridge) source="$ARCHITECTURE_DIR/_manifest.md" ;;
    architecture\|architecture-view)
      if [[ -f "$ARCHITECTURE_DIR/views/_manifest.md" ]]; then source="$ARCHITECTURE_DIR/views/_manifest.md"; else source="$ARCHITECTURE_DIR/views/README.md"; fi
      ;;
    *) return 1 ;;
  esac
  [[ -f "$source" ]] && realpath "$source"
}

full_review_expected_targets() { # $1=product|architecture $2=root manifest; POP<FS>canonical-target-id<FS>disposition<FS>owner-key
  local profile="$1" manifest="$2" file table target_id disposition owner owner_key architecture_manifest owner_id views_manifest
  local canonical_id relative owner_class question coverage view_slug current_state
  local sep
  sep=$(printf '\034')
  if [[ "$profile" == product ]]; then
    for file in "$PRODUCT_DIR/README.md" "$PRODUCT_DIR/prd.md" "$PRODUCT_DIR/product-model.md" "$PRODUCT_DIR/capabilities/README.md" "$PRODUCT_DIR/journeys/README.md" "$PRODUCT_DIR/roadmap-and-acceptance.md"; do
      [[ -f "$file" ]] || continue
      owner_key=$(realpath "$file")
      relative=${file#"$SSOT_DIR"/}
      canonical_id="owner:$relative"
      printf 'product-reader-owner%s%s%scurrent owner%s%s\n' "$sep" "$canonical_id" "$sep" "$sep" "$owner_key"
    done
    for file in "$PRODUCT_DIR"/{capabilities,journeys}/[0-9][0-9]-*.md; do
      [[ -f "$file" ]] || continue
      owner_key=$(realpath "$file")
      relative=${file#"$SSOT_DIR"/}
      canonical_id="owner:$relative"
      printf 'product-reader-owner%s%s%scurrent owner%s%s\n' "$sep" "$canonical_id" "$sep" "$sep" "$owner_key"
    done
    table=$(manifest_product_surface_table "$manifest")
    while IFS='|' read -r _ target_id _ _ owner disposition _ _; do
      target_id=$(trim_table_cell "$target_id"); target_id="${target_id//\`/}"
      [[ "$target_id" =~ ^surface: ]] || continue
      disposition=$(trim_table_cell "$disposition"); disposition="${disposition//\`/}"
      owner=$(trim_table_cell "$owner")
      owner_key=$(strict_ssot_markdown_target_key "$manifest" "$owner" 2>/dev/null || true)
      printf 'product-surface%s%s%s%s%s%s\n' "$sep" "$target_id" "$sep" "$disposition" "$sep" "$owner_key"
    done <<< "$table"
    architecture_manifest="$ARCHITECTURE_DIR/_manifest.md"
    if [[ -f "$architecture_manifest" ]]; then
      table=$(manifest_architecture_product_bridge_table "$architecture_manifest")
      while IFS='|' read -r _ target_id owner_id _ _ _; do
        target_id=$(trim_table_cell "$target_id"); target_id="${target_id//\`/}"
        [[ "$target_id" =~ ^surface: ]] || continue
        owner_id=$(trim_table_cell "$owner_id"); owner_id="${owner_id//\`/}"
        owner_key=$(architecture_owner_target_key "$architecture_manifest" "$owner_id" 2>/dev/null || true)
        [[ -n "$owner_key" ]] || owner_key=$(realpath "$ARCHITECTURE_DIR/README.md" 2>/dev/null || true)
        canonical_id="bridge:$target_id"
        printf 'product-bridge%s%s%s%s%s%s\n' "$sep" "$canonical_id" "$sep" "$owner_id" "$sep" "$owner_key"
      done <<< "$table"
    fi
    return
  fi

  for file in "$ARCHITECTURE_DIR/README.md" "$ARCHITECTURE_DIR/views/README.md"; do
    [[ -f "$file" ]] || continue
    owner_key=$(realpath "$file")
    relative=${file#"$SSOT_DIR"/}
    canonical_id="owner:$relative"
    printf 'architecture-reader-owner%s%s%scurrent owner%s%s\n' "$sep" "$canonical_id" "$sep" "$sep" "$owner_key"
  done
  while IFS= read -r file; do
    owner_key=$(realpath "$file")
    relative=${file#"$SSOT_DIR"/}
    canonical_id="owner:$relative"
    printf 'architecture-reader-owner%s%s%scurrent owner%s%s\n' "$sep" "$canonical_id" "$sep" "$sep" "$owner_key"
  done < <(find "$ARCHITECTURE_DIR" -mindepth 2 -maxdepth 2 -type f -name README.md 2>/dev/null | awk -F/ '$(NF-1) ~ /^[0-9][0-9]-/' | LC_ALL=C sort)
  table=$(manifest_architecture_owner_table "$manifest")
  while IFS='|' read -r _ target_id owner_class owner _ _ _; do
    target_id=$(trim_table_cell "$target_id"); target_id="${target_id//\`/}"
    [[ "$target_id" =~ ^owner: ]] || continue
    owner_class=$(trim_table_cell "$owner_class"); owner_class="${owner_class//\`/}"
    owner=$(trim_table_cell "$owner")
    owner_key=$(strict_ssot_markdown_target_key "$manifest" "$owner" 2>/dev/null || true)
    canonical_id="owner:02-architecture/_manifest.md#$target_id"
    printf 'architecture-direct-owner%s%s%s%s%s%s\n' "$sep" "$canonical_id" "$sep" "$owner_class" "$sep" "$owner_key"
  done <<< "$table"
  views_manifest="$ARCHITECTURE_DIR/views/_manifest.md"
  if [[ -f "$views_manifest" ]]; then
    table=$(manifest_primary_table "$views_manifest" architecture-views)
    while IFS='|' read -r _ question owner coverage _; do
      question=$(trim_table_cell "$question")
      owner=$(trim_table_cell "$owner")
      [[ -n "$owner" && "$owner" != "Narrative owner" && "$owner" != "叙事所有者" ]] || continue
      coverage=$(trim_table_cell "$coverage"); coverage="${coverage//\`/}"
      owner_key=$(strict_ssot_markdown_target_key "$views_manifest" "$owner" 2>/dev/null || true)
      view_slug=$(printf '%s\n' "$question" | markdown_heading_slug)
      [[ -n "$view_slug" ]] || continue
      canonical_id="view:$view_slug"
      printf 'architecture-view%s%s%s%s%s%s\n' "$sep" "$canonical_id" "$sep" "$coverage" "$sep" "$owner_key"
    done <<< "$(printf '%s\n' "$table" | tail -n +3)"
  fi
  table=$(manifest_architecture_surface_table "$manifest")
  while IFS='|' read -r _ target_id _ owner_id current_state _ _; do
    target_id=$(trim_table_cell "$target_id"); target_id="${target_id//\`/}"
    [[ "$target_id" =~ ^tech: ]] || continue
    owner_id=$(trim_table_cell "$owner_id"); owner_id="${owner_id//\`/}"
    current_state=$(trim_table_cell "$current_state"); current_state="${current_state//\`/}"
    owner_key=$(architecture_owner_target_key "$manifest" "$owner_id" 2>/dev/null || true)
    printf 'technical-surface%s%s%s%s%s%s\n' "$sep" "$target_id" "$sep" "$current_state" "$sep" "$owner_key"
  done <<< "$table"
  table=$(manifest_architecture_product_bridge_table "$manifest")
  while IFS='|' read -r _ target_id owner_id _ _ _; do
    target_id=$(trim_table_cell "$target_id"); target_id="${target_id//\`/}"
    [[ "$target_id" =~ ^surface: ]] || continue
    owner_id=$(trim_table_cell "$owner_id"); owner_id="${owner_id//\`/}"
    owner_key=$(architecture_owner_target_key "$manifest" "$owner_id" 2>/dev/null || true)
    [[ -n "$owner_key" ]] || owner_key=$(realpath "$ARCHITECTURE_DIR/README.md" 2>/dev/null || true)
    canonical_id="bridge:$target_id"
    printf 'architecture-bridge%s%s%s%s%s%s\n' "$sep" "$canonical_id" "$sep" "$owner_id" "$sep" "$owner_key"
  done <<< "$table"
}

review_evidence_sample_table() { # $1=review artifact
  review_visible_markdown "$1" | awk '
    function is_header(line, lower) {
      lower=tolower(line)
      return (lower ~ /task class/ || line ~ /任务类别/) && \
        (lower ~ /claim/ || line ~ /结论/) && \
        (lower ~ /evidence/ || line ~ /证据/) && \
        (lower ~ /fitness/ || line ~ /适配/) && \
        (lower ~ /result/ || line ~ /结果/) && \
        (lower ~ /limit/ || line ~ /限制/)
    }
    !active && /^\|/ && is_header($0) { active=1; print; next }
    active && /^\|/ { print; next }
    active { exit }
  '
}

review_cold_proof_table() { # $1=review artifact
  review_visible_markdown "$1" | awk '
    function is_header(line, lower) {
      lower=tolower(line)
      return (lower ~ /probe id/ || line ~ /探针[[:space:]]*ID/) && \
        (lower ~ /evidence from mandatory tasks/ || line ~ /必做任务证据/) && \
        (lower ~ /result/ || line ~ /结果/) && \
        (lower ~ /limit/ || line ~ /限制/)
    }
    !active && /^\|/ && is_header($0) { active=1; print; next }
    active && /^\|/ { print; next }
    active { exit }
  '
}

review_completeness_table() { # $1=review artifact
  review_visible_markdown "$1" | awk '
    function is_header(line, lower) {
      lower=tolower(line)
      return (lower ~ /item id/ || line ~ /项目[[:space:]]*ID/) && \
        (lower ~ /disposition/ || line ~ /处置/) && \
        (lower ~ /reason and evidence/ || line ~ /原因与证据/)
    }
    !active && /^\|/ && is_header($0) { active=1; print; next }
    active && /^\|/ { print; next }
    active { exit }
  '
}

review_truth_consistency_table() { # $1=review artifact
  review_visible_markdown "$1" | awk '
    function is_header(line,lower){lower=tolower(line);return (lower~/claim/||line~/结论/)&&(lower~/owner/||line~/所有者/)&&(lower~/compared owner/||line~/对照所有者/)&&(lower~/result/||line~/结果/)&&(lower~/note/||line~/说明/)}
    !active&&/^\|/&&is_header($0){active=1;print;next}
    active&&/^\|/{print;next}
    active{exit}
  '
}

review_required_changes_table() { # $1=review artifact
  awk '
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); return v }
    function is_header(line, lower) {
      lower=tolower(line)
      return (lower ~ /change id/ || line ~ /必改项[[:space:]]*ID/) && \
        (lower ~ /status/ || line ~ /状态/) && \
        (lower ~ /required change/ || line ~ /必改内容/) && \
        (lower ~ /owner/ || line ~ /所有者/) && \
        (lower ~ /closure evidence/ || line ~ /闭合证据/)
    }
    BEGIN { fence=comment=front=0 }
    NR==1 && /^---[[:space:]]*$/ { front=1; next }
    front { if(/^---[[:space:]]*$/) front=0; next }
    {
      line=$0
      if(comment){if(line~/-->/)comment=0;next}
      if(line~/<!--/){if(line!~/-->/)comment=1;next}
      if(line~/^[[:space:]]*```/){fence=!fence;next}
      if(fence)next
    }
    /^##[[:space:]]+/ {
      title=$0; sub(/^##[[:space:]]+/, "", title); title=trim(title)
      in_section=(tolower(title) == "required changes and verdict" || title == "必改项与结论")
      active=0
      next
    }
    in_section && !active && /^\|/ && is_header($0) { active=1; print; next }
    in_section && active && /^\|/ { print; next }
    in_section && active { exit }
  ' "$1"
}

scope_review_expected_ids() { # $1=profile; one ID per line
  local profile="$1" i
  case "$profile" in
    process|records|glossary|root)
      for i in {1..9}; do printf 'C%02d\n' "$i"; done
      ;;
  esac
  case "$profile" in
    process) for i in {1..16}; do printf 'PR%02d\n' "$i"; done ;;
    records) for i in {1..16}; do printf 'R%02d\n' "$i"; done ;;
    glossary) for i in {1..8}; do printf 'G%02d\n' "$i"; done ;;
    root) for i in {1..7}; do printf 'RT%02d\n' "$i"; done ;;
    status) for i in {1..11}; do printf 'S%02d\n' "$i"; done ;;
    *) return 1 ;;
  esac
  for i in {1..21}; do printf 'Q%02d\n' "$i"; done
}

scope_review_profile_table() { # $1=review artifact
  awk '
    function is_header(line, lower) {
      lower=tolower(line)
      return (lower ~ /item id/ || line ~ /项目[[:space:]]*ID/) && \
        (lower ~ /disposition/ || line ~ /处置/) && \
        (lower ~ /owner[[:space:]]*\/[[:space:]]*evidence/ || line ~ /所有者或证据/)
    }
    function trim(v){gsub(/^[[:space:]]+|[[:space:]]+$/, "", v);return v}
    BEGIN { fence=comment=front=0 }
    NR==1 && /^---[[:space:]]*$/ { front=1; next }
    front { if(/^---[[:space:]]*$/) front=0; next }
    {
      line=$0
      if(comment){if(line~/-->/)comment=0;next}
      if(line~/<!--/){if(line!~/-->/)comment=1;next}
      if(line~/^[[:space:]]*```/){fence=!fence;next}
      if(fence)next
    }
    /^##[[:space:]]+/ {title=$0;sub(/^##[[:space:]]+/,"",title);title=trim(title);in_section=(tolower(title)=="exact profile"||title=="精确画像");active=0;next}
    in_section && !active && /^\|/ && is_header($0) { active=1; print; next }
    in_section && active && /^\|/ { print; next }
    in_section && active { exit }
  ' "$1"
}

scope_review_basis_table() { # $1=review artifact
  awk '
    function trim(v){gsub(/^[[:space:]]+|[[:space:]]+$/, "",v);return v}
    function is_header(line,lower){lower=tolower(line);return (lower~/check/||line~/检查/)&&(lower~/result/||line~/结果/)&&(lower~/evidence[[:space:]]*\/[[:space:]]*limit/||line~/证据与限制/)}
    BEGIN{fence=comment=front=0}
    NR==1&&/^---[[:space:]]*$/{front=1;next}
    front{if(/^---[[:space:]]*$/)front=0;next}
    {line=$0;if(comment){if(line~/-->/)comment=0;next};if(line~/<!--/){if(line!~/-->/)comment=1;next};if(line~/^[[:space:]]*```/){fence=!fence;next};if(fence)next}
    /^##[[:space:]]+/{title=$0;sub(/^##[[:space:]]+/,"",title);title=trim(title);in_section=(tolower(title)=="review basis"||title=="评审基线");active=0;next}
    in_section&&!active&&/^\|/&&is_header($0){active=1;print;next}
    in_section&&active&&/^\|/{print;next}
    in_section&&active{exit}
  ' "$1"
}

scope_review_semantic_table() { # $1=review artifact
  awk '
    function trim(v){gsub(/^[[:space:]]+|[[:space:]]+$/,"",v);return v}
    function is_header(line,lower){lower=tolower(line);return (lower~/item id/||line~/项目[[:space:]]*ID/)&&(lower~/owner[[:space:]]*\/[[:space:]]*body claim/||line~/所有者正文结论/)&&(lower~/repository[[:space:]]*\/[[:space:]]*evidence sample/||line~/仓库或证据样本/)&&(lower~/truth result/||line~/真实性结果/)&&(lower~/limit/||line~/限制/)}
    BEGIN{fence=comment=front=0}
    NR==1&&/^---[[:space:]]*$/{front=1;next}front{if(/^---[[:space:]]*$/)front=0;next}
    {line=$0;if(comment){if(line~/-->/)comment=0;next};if(line~/<!--/){if(line!~/-->/)comment=1;next};if(line~/^[[:space:]]*```/){fence=!fence;next};if(fence)next}
    /^##[[:space:]]+/{title=$0;sub(/^##[[:space:]]+/,"",title);title=trim(title);in_section=(tolower(title)=="review basis"||title=="评审基线");active=0;next}
    in_section&&!active&&/^\|/&&is_header($0){active=1;print;next}
    in_section&&active&&/^\|/{print;next}
    in_section&&active{exit}
  ' "$1"
}

scope_review_target_table() { # $1=review artifact
  awk '
    function trim(v){gsub(/^[[:space:]]+|[[:space:]]+$/,"",v);return v}
    function is_header(line,lower){lower=tolower(line);return (lower~/target id/||line~/目标[[:space:]]*ID/)&&(lower~/target owner/||line~/目标所有者/)&&(lower~/profile ids exercised/||line~/已核验画像[[:space:]]*ID/)&&(lower~/repository[[:space:]]*\/[[:space:]]*evidence sample/||line~/仓库或证据样本/)&&(lower~/truth result/||line~/真实性结果/)&&(lower~/limit/||line~/限制/)}
    BEGIN{fence=comment=front=0}
    NR==1&&/^---[[:space:]]*$/{front=1;next}front{if(/^---[[:space:]]*$/)front=0;next}
    {line=$0;if(comment){if(line~/-->/)comment=0;next};if(line~/<!--/){if(line!~/-->/)comment=1;next};if(line~/^[[:space:]]*(```|~~~)/){fence=!fence;next};if(fence)next}
    /^##[[:space:]]+/{title=$0;sub(/^##[[:space:]]+/,"",title);title=trim(title);in_section=(tolower(title)=="review basis"||title=="评审基线");active=0;next}
    in_section&&!active&&/^\|/&&is_header($0){active=1;print;next}
    in_section&&active&&/^\|/{print;next}
    in_section&&active{exit}
  ' "$1"
}

strict_ssot_markdown_target_key() { # $1=owner $2=one Markdown link; emits realpath[#fragment]
  local owner="$1" cell="$2" target candidate project_root lexical resolved fragment
  [[ "$(manifest_markdown_link_count "$cell")" -eq 1 ]] || return 1
  target=$(printf '%s\n' "$cell" | sed -nE 's@.*\]\(([^)#]+\.md)(#[^)]*)?\).*@\1@p' | head -1)
  [[ -n "$target" && "$target" != /* && "$target" != *://* ]] || return 1
  project_root=$(cd "$(dirname "$SSOT_DIR")" && pwd -P)
  if [[ "$target" == SSOT/* ]]; then candidate="$project_root/$target"; else candidate="$(dirname "$owner")/$target"; fi
  [[ -f "$candidate" ]] || return 1
  lexical=$(lexical_path "$candidate" 2>/dev/null) || return 1
  resolved=$(realpath "$candidate" 2>/dev/null) || return 1
  [[ "$lexical" == "$resolved" && "$resolved" == "$SSOT_DIR"/* && "$resolved" != "$SSOT_DIR/.bootstrap/"* ]] || return 1
  fragment=$(markdown_link_fragment "$cell")
  [[ -z "$fragment" ]] || markdown_file_has_fragment "$resolved" "$fragment" || return 1
  printf '%s%s\n' "$resolved" "${fragment:+#$fragment}"
}

glossary_family_inventory_table() { # $1=glossary README; exact six-family inventory table
  awk '
    function trim(v){gsub(/^[[:space:]]+|[[:space:]]+$/,"",v);return v}
    function is_header(line,lower){lower=tolower(line);return (lower~/vocabulary family/||line~/术语家族/)&&(lower~/discovery trigger/||line~/发现条件/)&&(lower~/disposition/||line~/处理/)&&(lower~/term-entry owner links or reason/||line~/条目所有者链接或原因/)}
    BEGIN{front=fence=comment=active=0}
    NR==1&&/^---[[:space:]]*$/{front=1;next}
    front{if(/^---[[:space:]]*$/)front=0;next}
    {
      line=$0
      if(comment){if(line~/-->/)comment=0;next}
      if(line~/<!--/){if(line!~/-->/)comment=1;next}
      if(line~/^[[:space:]]*(```|~~~)/){fence=!fence;next}
      if(fence)next
    }
    /^##[[:space:]]+/{title=$0;sub(/^##[[:space:]]+/,"",title);title=trim(title);in_section=(tolower(title)=="vocabulary-family coverage"||title=="术语家族覆盖");active=0;next}
    in_section&&!active&&/^\|/&&is_header($0){active=1;print;next}
    in_section&&active&&/^\|/{print;next}
    in_section&&active{exit}
  ' "$1"
}

scope_review_expected_targets() { # $1=profile; absolute file[#fragment] targets
  local profile="$1" file fm id heading slug index table cell link resolved fragment
  case "$profile" in
    process)
      [[ -f "$PROCESS_DIR/README.md" ]] && realpath "$PROCESS_DIR/README.md"
      find "$PROCESS_DIR" -mindepth 2 -maxdepth 2 -type f -name 'README.md' -print 2>/dev/null | LC_ALL=C sort | while IFS= read -r file; do realpath "$file"; done
      ;;
    records)
      for file in "$RECORDS_DIR/README.md" "$DECISIONS_DIR/README.md" "$RESEARCH_AREA_DIR/README.md" "$GOTCHAS_DIR/README.md" "$BUGS_DIR/README.md" "$TECH_DEBT_DIR/README.md"; do [[ -f "$file" ]] && realpath "$file"; done
      for index in "$DECISIONS_DIR" "$RESEARCH_AREA_DIR" "$BUGS_DIR" "$TECH_DEBT_DIR"; do
        [[ -d "$index" ]] || continue
        find "$index" -type f -name '*.md' ! -name 'README.md' ! -name '_*.md' -print 2>/dev/null | LC_ALL=C sort | while IFS= read -r file; do realpath "$file"; done
      done
      if [[ -d "$GOTCHAS_DIR" ]]; then
        while IFS= read -r file; do
          id=$(review_frontmatter_value "$file" id 2>/dev/null || true)
          if [[ -n "$id" ]]; then
            realpath "$file"
          else
            while IFS=$'\034' read -r id _ _ _ heading; do
              [[ "$id" =~ ^GOT-[0-9]{4}$ ]] || continue
              slug=$(printf '%s\n' "$heading" | markdown_heading_slug)
              printf '%s#%s\n' "$(realpath "$file")" "$slug"
            done < <(gotcha_aggregate_entries "$file")
          fi
        done < <(find "$GOTCHAS_DIR" -type f -name '*.md' ! -name 'README.md' ! -name '_*.md' -print 2>/dev/null | LC_ALL=C sort)
      fi
      ;;
    glossary)
      [[ -f "$GLOSSARY_DIR/README.md" ]] && realpath "$GLOSSARY_DIR/README.md"
      if [[ -f "$GLOSSARY_DIR/README.md" ]]; then
        table=$(glossary_family_inventory_table "$GLOSSARY_DIR/README.md" 2>/dev/null || true)
        while IFS= read -r cell; do
          while IFS= read -r link; do
            [[ -n "$link" ]] || continue
            strict_ssot_markdown_target_key "$GLOSSARY_DIR/README.md" "$link" 2>/dev/null || true
          done < <(printf '%s\n' "$cell" | grep -oE '\[[^]]+\]\([^)]+[.]md(#[^)]*)?\)' || true)
        done < <(printf '%s\n' "$table" | awk -F'|' 'NR>2&&/^\|/{d=$4;gsub(/^[[:space:]`]+|[[:space:]`]+$/,"",d);if(tolower(d)=="applicable")print $5}')
        find "$GLOSSARY_DIR" -type f -name '*.md' ! -name 'README.md' ! -name '_*.md' -print 2>/dev/null | LC_ALL=C sort | while IFS= read -r file; do realpath "$file"; done
      fi
      ;;
    root) [[ -f "$SSOT_DIR/README.md" ]] && realpath "$SSOT_DIR/README.md" ;;
    status) [[ -f "$SSOT_DIR/STATUS.md" ]] && realpath "$SSOT_DIR/STATUS.md" ;;
    *) return 1 ;;
  esac | LC_ALL=C sort -u
}

status_area_row() { # $1=area; emits line<FS>status<FS>notes
  local wanted="$1"
  awk -v wanted="$wanted" '
    BEGIN { sep=sprintf("%c", 28) }
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/^`|`$/, "", v); return v }
    /^##[[:space:]]+(Area Status|区域状态)[[:space:]]*$/ { active=1; next }
    active && /^##[[:space:]]/ { exit }
    active && /^\|/ && $0 !~ /^\|[[:space:]:|-]+(\|[[:space:]:|-]+)+\|?[[:space:]]*$/ {
      count=split($0, cells, "|")
      if (!header) {
        for (i=2; i<count; i++) {
          value=trim(cells[i]); lower=tolower(value)
          if (lower == "area" || value == "区域") area_i=i
          else if (lower == "status" || value == "状态") status_i=i
          else if (lower == "notes" || value == "备注") notes_i=i
        }
        header=1; next
      }
      if (trim(cells[area_i]) == wanted) print NR sep trim(cells[status_i]) sep trim(cells[notes_i])
    }
  ' "$SSOT_DIR/STATUS.md"
}

scope_review_area_tokens() { # $1=profile; normalized Area Status dependency set
  case "$1" in
    process) printf '%s\n' process development testing benchmark deployment release operations security-and-compliance ;;
    records) printf '%s\n' records decisions 'research records' gotchas bugs tech-debt ;;
    glossary) printf '%s\n' glossary ;;
    root|status) printf '%s\n' product architecture process development testing benchmark deployment release operations security-and-compliance records decisions 'research records' gotchas bugs tech-debt glossary ;;
    *) return 1 ;;
  esac
}

current_area_disposition_fingerprint() { # $1=scope profile
  local profile="$1" area row sep line status notes
  sep=$(printf '\034')
  while IFS= read -r area; do
    row=$(status_area_row "$area")
    [[ $(printf '%s\n' "$row" | sed '/^$/d' | wc -l | tr -d ' ') -eq 1 ]] || return 1
    IFS="$sep" read -r line status notes <<< "$row"
    notes=$(printf '%s' "$notes" | awk '{$1=$1;print}')
    printf '%s\0%s\0%s\n' "$area" "$status" "$notes"
  done < <(scope_review_area_tokens "$profile") | sha256_stream
}

status_coverage_result() {
  awk -F'|' '
    $0 ~ /^\|[[:space:]]*coverage_result[[:space:]]*\|/ {
      value=$3; gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", value); print value; exit
    }
    /^coverage_result:[[:space:]]*/ {
      value=$0; sub(/^coverage_result:[[:space:]]*/, "", value); gsub(/["`]/, "", value); print value; exit
    }
  ' "$SSOT_DIR/STATUS.md"
}

status_stop_review_rows() { # emits EVENT<FS>line<FS>nine exact cells
  awk '
    BEGIN { sep=sprintf("%c", 28) }
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/^`|`$/, "", v); return v }
    function set_header(    i,v,lower) {
      scope_i=claim_i=reviewer_i=role_i=at_i=result_i=evidence_i=remaining_i=authorises_i=0
      for (i=2; i<count; i++) {
        v=trim(cells[i]); lower=tolower(v)
        if (lower == "scope" || v == "范围") scope_i=i
        else if (lower == "stop claim" || lower == "stop_claim" || v == "停止结论") claim_i=i
        else if (lower == "reviewer" || v == "评审者") reviewer_i=i
        else if (lower == "reviewer role" || lower == "reviewer_role" || v == "评审者角色") role_i=i
        else if (lower == "reviewed at" || lower == "reviewed_at" || v == "评审时间") at_i=i
        else if (lower == "result" || v == "结果") result_i=i
        else if (lower == "evidence" || v == "证据") evidence_i=i
        else if (lower == "remaining changes" || lower == "remaining_changes" || v == "剩余改动") remaining_i=i
        else if (lower == "authorises" || lower == "authorizes" || v == "授权对象") authorises_i=i
      }
      return scope_i && claim_i && reviewer_i && role_i && at_i && result_i && evidence_i && remaining_i && authorises_i
    }
    /^##[[:space:]]+(Stop Review Gate|停止审查闸门)[[:space:]]*$/ { active=1; found=1; next }
    active && /^##[[:space:]]/ { exit }
    active && /^\|/ {
      if ($0 ~ /^\|[[:space:]:|-]+(\|[[:space:]:|-]+)+\|?[[:space:]]*$/) next
      count=split($0, cells, "|")
      if (!header) {
        if (set_header()) header=1
        else print "HEADER" sep NR
        next
      }
      real=0; for (i=2; i<count; i++) if (trim(cells[i]) != "") real=1
      if (!real) next
      print "ROW" sep NR sep trim(cells[scope_i]) sep trim(cells[claim_i]) sep trim(cells[reviewer_i]) sep trim(cells[role_i]) sep trim(cells[at_i]) sep trim(cells[result_i]) sep trim(cells[evidence_i]) sep trim(cells[remaining_i]) sep trim(cells[authorises_i])
    }
    END { if (!found) print "SECTION" sep 0 }
  ' "$SSOT_DIR/STATUS.md"
}

status_area_scope_review_links() { # $1=Notes cell $2=profile; emits KIND<FS>path
  local cell="$1" profile="$2" link resolved declared canonical_owner
  canonical_owner="$SSOT_DIR/$(canonical_area_rel "$profile")/README.md"
  if [[ -f "$canonical_owner" ]]; then
    canonical_owner=$(realpath "$canonical_owner" 2>/dev/null || true)
  fi
  while IFS= read -r link; do
    [[ -n "$link" ]] || continue
    markdown_link_resolves_with_anchor "$SSOT_DIR/STATUS.md" "$link" || continue
    resolved=$(manifest_markdown_link_resolved_path "$SSOT_DIR/STATUS.md" "$link" 2>/dev/null || true)
    [[ -n "$resolved" ]] || continue
    if [[ "$resolved" == "$canonical_owner" ]]; then
      printf 'OWNER\034%s\n' "$resolved"
    fi
    declared=$(review_frontmatter_value "$resolved" review_scope 2>/dev/null || true)
    if [[ "$declared" == "$profile" ]] && [[ "$(review_frontmatter_value "$resolved" review_id 2>/dev/null || true)" == scope-review:"$profile":* ]]; then
      printf 'REVIEW\034%s\n' "$resolved"
    fi
  done < <(printf '%s\n' "$cell" | grep -oE '\[[^]]+\]\([^)]+[.]md(#[^)]*)?\)' || true)
}

status_passing_stop_exists() { # $1=scope $2=claim $3=authorises
  local wanted_scope="$1" wanted_claim="$2" wanted_authorises="$3" sep event line scope claim reviewer role at result evidence remaining authorises
  sep=$(printf '\034')
  while IFS="$sep" read -r event line scope claim reviewer role at result evidence remaining authorises; do
    [[ "$event" == ROW && "$scope" == "$wanted_scope" && "$claim" == "$wanted_claim" && "$authorises" == "$wanted_authorises" && "$result" == no-more-required-changes ]] && return 0
  done < <(status_stop_review_rows)
  return 1
}

status_notes_canonical_owner_count() { # $1=area $2=Notes cell
  local area="$1" cell="$2" canonical link resolved count=0
  canonical="$SSOT_DIR/$(canonical_area_rel "$area")/README.md"
  canonical=$(realpath "$canonical" 2>/dev/null || true)
  [[ -n "$canonical" ]] || { printf '0\n'; return; }
  while IFS= read -r link; do
    [[ -n "$link" ]] || continue
    markdown_link_resolves_with_anchor "$SSOT_DIR/STATUS.md" "$link" || continue
    resolved=$(manifest_markdown_link_resolved_path "$SSOT_DIR/STATUS.md" "$link" 2>/dev/null || true)
    [[ "$resolved" == "$canonical" ]] && count=$((count + 1))
  done < <(printf '%s\n' "$cell" | grep -oE '\[[^]]+\]\([^)]+[.]md(#[^)]*)?\)' || true)
  printf '%s\n' "$count"
}

validate_v260_converged_area_status() {
  local sep area status notes canonical_count rows=0
  local -A seen=()
  sep=$(printf '\034')
  while IFS="$sep" read -r area status notes; do
    [[ -n "$area" ]] || continue
    case "$area" in
      product|architecture|process|development|testing|benchmark|deployment|release|operations|security-and-compliance|records|decisions|"research records"|gotchas|bugs|tech-debt|glossary) ;;
      *) continue ;;
    esac
    rows=$((rows + 1))
    [[ -z "${seen[$area]:-}" ]] || { printf 'duplicate Area Status row %s' "$area"; return 1; }
    seen[$area]=1
    if [[ "$status" == covered ]]; then
      canonical_count=$(status_notes_canonical_owner_count "$area" "$notes")
      [[ "$canonical_count" -eq 1 ]] || { printf 'covered Area %s must link its canonical owner exactly once' "$area"; return 1; }
    elif [[ "$status" == not_applicable ]]; then
      case "$area" in testing|benchmark|deployment|release|operations|security-and-compliance|"research records") ;; *) printf 'Area %s cannot be not_applicable at convergence' "$area"; return 1 ;; esac
      [[ ${#notes} -ge 12 && "$(manifest_markdown_link_count "$notes")" -eq 1 ]] && markdown_link_resolves_with_anchor "$SSOT_DIR/STATUS.md" "$notes" || { printf 'not_applicable Area %s lacks one resolving boundary owner' "$area"; return 1; }
    else
      printf 'Area %s is %s, not covered or legally not_applicable' "$area" "${status:-blank}"
      return 1
    fi
  done < <(awk '
    BEGIN{sep=sprintf("%c",28)}
    function trim(v){gsub(/^[[:space:]`]+|[[:space:]`]+$/,"",v);return v}
    /^##[[:space:]]+/{v=$0;sub(/^##[[:space:]]+/,"",v);v=trim(v);active=(tolower(v)=="area status"||v=="区域状态");header=0;next}
    active&&/^\|/{if($0~/^\|[[:space:]:|-]+(\|[[:space:]:|-]+)+\|?[[:space:]]*$/)next;n=split($0,c,"|");if(!header){for(i=2;i<n;i++){v=trim(c[i]);l=tolower(v);if(l=="area"||v=="区域")ai=i;else if(l=="status"||v=="状态")si=i;else if(l=="notes"||v=="备注")ni=i}header=1;next}print trim(c[ai]) sep trim(c[si]) sep trim(c[ni])}
  ' "$SSOT_DIR/STATUS.md")
  [[ "$rows" -eq 17 ]] || { printf 'convergence needs the exact 17 baseline Area rows (got %s)' "$rows"; return 1; }
  return 0
}

validate_v260_scope_review_artifact() { # $1=profile $2=artifact $3=expected authorises
  local profile="$1" artifact="$2" expected_authorises="$3" field value version reviewed_on id_date compact_date
  local expected_scope expected_entrypoint expected_count expected_ids actual_fingerprint expected_fingerprint
  local area_fingerprint expected_area_fingerprint quality_fingerprint expected_quality_fingerprint table stats h2_stats required_table required_stats basis_table basis_stats semantic_table semantic_stats expected_families
  local target_table target_stats expected_targets actual_targets target_id target_owner exercised_ids target_evidence target_result target_limit target_key id
  local repository_commit project_root covered_count na_count declared_covered declared_na declared_unresolved
  local bootstrap_real artifact_real frontmatter_stats header resolved linked_review_id final_stats
  case "$profile" in
    process) expected_entrypoint='SSOT/03-process/README.md'; expected_count=46 ;;
    records) expected_entrypoint='SSOT/04-records/README.md'; expected_count=46 ;;
    glossary) expected_entrypoint='SSOT/glossary/README.md'; expected_count=38 ;;
    root) expected_entrypoint='SSOT/README.md'; expected_count=37 ;;
    status) expected_entrypoint='SSOT/STATUS.md'; expected_count=32 ;;
    *) printf 'unknown lightweight completeness profile %s' "$profile"; return 1 ;;
  esac
  case "$profile" in
    process) expected_families='C,PR,Q' ;;
    records) expected_families='C,R,Q' ;;
    glossary) expected_families='C,G,Q' ;;
    root) expected_families='C,RT,Q' ;;
    status) expected_families='S,Q' ;;
  esac
  [[ -d "$SSOT_DIR/.bootstrap" && ! -L "$SSOT_DIR/.bootstrap" ]] || { printf 'review artifact directory SSOT/.bootstrap must be a real directory'; return 1; }
  bootstrap_real=$(realpath "$SSOT_DIR/.bootstrap" 2>/dev/null || true)
  artifact_real=$(realpath "$artifact" 2>/dev/null || true)
  [[ -n "$bootstrap_real" && -n "$artifact_real" && "$artifact_real" == "$bootstrap_real/"* && -f "$artifact_real" && ! -L "$artifact" ]] || { printf 'review artifact must be a regular non-symlink file under SSOT/.bootstrap'; return 1; }
  ! find "$SSOT_DIR/.bootstrap" -type l -print -quit 2>/dev/null | grep -q . || { printf 'review artifact path must not traverse or contain symlinks'; return 1; }
  artifact="$artifact_real"
  frontmatter_stats=$(awk '
    BEGIN{allowed="review_id review_scope completeness_profile protocol_version reviewed_on reviewer reviewer_role repository_commit entrypoint scope_fingerprint area_disposition_fingerprint quality_disposition_fingerprint profile_item_count covered_item_count not_applicable_item_count unresolved_required_changes authorises verdict";n=split(allowed,a," ");for(i=1;i<=n;i++)ok[a[i]]=1}
    NR==1{if($0!~/^---[[:space:]]*$/)invalid++;else front=1;next}
    front&&/^---[[:space:]]*$/{front=0;closed++;next}
    front{
      if($0~/^[[:space:]]*($|#)/)next
      if(match($0,/^[A-Za-z_][A-Za-z0-9_-]*:/)){key=substr($0,1,RLENGTH-1);keys++;if(!(key in ok)||seen[key]++)invalid++;next}
      invalid++
    }
    END{for(k in ok)if(seen[k]!=1)invalid++;if(front||closed!=1)invalid++;printf "%d|%d|%d",closed+0,keys+0,invalid+0}
  ' "$artifact")
  [[ "$frontmatter_stats" == "1|18|0" ]] || { printf 'frontmatter must be one closed exact 18-key scalar schema (got %s)' "$frontmatter_stats"; return 1; }
  for field in review_id review_scope completeness_profile protocol_version reviewed_on reviewer reviewer_role repository_commit entrypoint scope_fingerprint area_disposition_fingerprint quality_disposition_fingerprint profile_item_count covered_item_count not_applicable_item_count unresolved_required_changes authorises verdict; do
    [[ $(yaml_frontmatter "$artifact" | grep -Ec "^${field}:[[:space:]]*" || true) -eq 1 ]] || { printf 'frontmatter must declare exactly one %s' "$field"; return 1; }
  done
  value=$(review_frontmatter_value "$artifact" review_id)
  [[ "$value" =~ ^scope-review:${profile}:[0-9]{8}:[a-z0-9][a-z0-9-]*$ ]] || { printf 'review_id must use scope-review:%s:<YYYYMMDD>:<slug>' "$profile"; return 1; }
  reviewed_on=$(review_frontmatter_value "$artifact" reviewed_on)
  [[ "$reviewed_on" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || { printf 'reviewed_on is not YYYY-MM-DD'; return 1; }
  id_date=$(printf '%s' "$value" | cut -d: -f3); compact_date=${reviewed_on//-/}
  [[ "$id_date" == "$compact_date" ]] || { printf 'review_id date must equal reviewed_on'; return 1; }
  [[ "$(review_frontmatter_value "$artifact" review_scope)" == "$profile" ]] || { printf 'review_scope must be %s' "$profile"; return 1; }
  [[ "$(review_frontmatter_value "$artifact" completeness_profile)" == "$profile" ]] || { printf 'completeness_profile must be %s' "$profile"; return 1; }
  version=$(document_quality_status_version 2>/dev/null || true)
  [[ "$(review_frontmatter_value "$artifact" protocol_version)" == "$version" ]] || { printf 'protocol_version does not match tracked_skill_version %s' "$version"; return 1; }
  [[ "$(review_frontmatter_value "$artifact" reviewer)" =~ ^[A-Za-z0-9][A-Za-z0-9._:@/-]{1,127}$ ]] || { printf 'reviewer must be a stable non-placeholder ID'; return 1; }
  [[ "$(review_frontmatter_value "$artifact" reviewer_role)" =~ ^(scoped-self-review|independent-reviewer)$ ]] || { printf 'reviewer_role is not allowed'; return 1; }
  repository_commit=$(review_frontmatter_value "$artifact" repository_commit)
  [[ "$repository_commit" =~ ^[0-9a-fA-F]{7,40}$ ]] || { printf 'repository_commit must be a Git commit ID'; return 1; }
  project_root=$(cd "$(dirname "$SSOT_DIR")" && pwd -P)
  git -C "$project_root" cat-file -e "${repository_commit}^{commit}" 2>/dev/null || { printf 'repository_commit is not resolvable in the current repository'; return 1; }
  git -C "$project_root" merge-base --is-ancestor "$repository_commit" HEAD 2>/dev/null || { printf 'repository_commit is not an ancestor of current HEAD'; return 1; }
  [[ "$(review_frontmatter_value "$artifact" entrypoint)" == "$expected_entrypoint" ]] || { printf 'entrypoint must be %s' "$expected_entrypoint"; return 1; }
  actual_fingerprint=$(review_frontmatter_value "$artifact" scope_fingerprint)
  [[ "$actual_fingerprint" =~ ^[0-9a-f]{64}$ ]] || { printf 'scope_fingerprint must be a lowercase SHA-256 digest'; return 1; }
  expected_fingerprint=$(current_scope_review_fingerprint "$profile" 2>/dev/null || true)
  [[ -n "$expected_fingerprint" && "$actual_fingerprint" == "$expected_fingerprint" ]] || { printf 'scope_fingerprint does not match current %s Markdown' "$profile"; return 1; }
  area_fingerprint=$(review_frontmatter_value "$artifact" area_disposition_fingerprint)
  [[ "$area_fingerprint" =~ ^[0-9a-f]{64}$ ]] || { printf 'area_disposition_fingerprint must be a lowercase SHA-256 digest'; return 1; }
  expected_area_fingerprint=$(current_area_disposition_fingerprint "$profile" 2>/dev/null || true)
  [[ -n "$expected_area_fingerprint" && "$area_fingerprint" == "$expected_area_fingerprint" ]] || { printf 'area_disposition_fingerprint does not match current dependent Area Status rows'; return 1; }
  quality_fingerprint=$(review_frontmatter_value "$artifact" quality_disposition_fingerprint)
  [[ "$quality_fingerprint" =~ ^[0-9a-f]{64}$ ]] || { printf 'quality_disposition_fingerprint must be a lowercase SHA-256 digest'; return 1; }
  expected_quality_fingerprint=$(current_quality_disposition_fingerprint 2>/dev/null || true)
  [[ -n "$expected_quality_fingerprint" && "$quality_fingerprint" == "$expected_quality_fingerprint" ]] || { printf 'quality_disposition_fingerprint does not match current Q01-Q21 disposition'; return 1; }
  [[ "$(review_frontmatter_value "$artifact" profile_item_count)" == "$expected_count" ]] || { printf 'profile_item_count must be %s' "$expected_count"; return 1; }
  declared_covered=$(review_frontmatter_value "$artifact" covered_item_count)
  declared_na=$(review_frontmatter_value "$artifact" not_applicable_item_count)
  [[ "$declared_covered" =~ ^[0-9]+$ && "$declared_na" =~ ^[0-9]+$ ]] || { printf 'covered and not_applicable counts must be integers'; return 1; }
  declared_unresolved=$(review_frontmatter_value "$artifact" unresolved_required_changes)
  [[ "$declared_unresolved" == "0" ]] || { printf 'unresolved_required_changes must be 0'; return 1; }
  [[ "$(review_frontmatter_value "$artifact" authorises)" == "$expected_authorises" ]] || { printf 'authorises must be %s' "$expected_authorises"; return 1; }
  [[ "$(review_frontmatter_value "$artifact" verdict)" == "no-more-required-changes" ]] || { printf 'verdict must be no-more-required-changes'; return 1; }
  h2_stats=$(awk '
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); return v }
    function key(v, lower) { lower=tolower(v); if (lower=="review basis" || v=="评审基线") return "basis"; if (lower=="exact profile" || v=="精确画像") return "profile"; if (lower=="required changes and verdict" || v=="必改项与结论") return "changes"; return "" }
    BEGIN{front=fence=comment=0}
    NR==1&&/^---[[:space:]]*$/{front=1;next}
    front{if(/^---[[:space:]]*$/)front=0;next}
    {line=$0;if(comment){if(line~/-->/)comment=0;next};if(line~/<!--/){if(line!~/-->/)comment=1;next};if(line~/^[[:space:]]*```/){fence=!fence;next};if(fence)next}
    /^##[[:space:]]+/ { v=$0; sub(/^##[[:space:]]+/, "", v); v=trim(v); rows++; k=key(v); if (k=="" || seen[k]++) invalid++ }
    END { required["basis"]=required["profile"]=required["changes"]=1; for (k in required) if (seen[k]!=1) invalid++; printf "%d|%d", rows+0, invalid+0 }
  ' "$artifact")
  [[ "$h2_stats" == "3|0" ]] || { printf 'body H2 headings must be exactly the three lightweight review sections'; return 1; }
  ! grep -q '<!--' "$artifact" || { printf 'passing review artifact must not contain HTML author comments'; return 1; }
  grep -qE '<[^>]+>|(^|[^[:alnum:]_])(TODO|TBD)([^[:alnum:]_]|$)|待补充' "$artifact" && { printf 'body still contains placeholders'; return 1; }
  basis_table=$(scope_review_basis_table "$artifact")
  [[ -n "$basis_table" ]] || { printf 'body is missing the review-basis table'; return 1; }
  header=$(printf '%s\n' "$basis_table" | head -1 | awk -F'|' '{for(i=2;i<NF;i++){v=$i;gsub(/^[[:space:]`]+|[[:space:]`]+$/,"",v);if(v~/^[A-Za-z _\/-]+$/)v=tolower(v);printf "%s%s",(i==2?"":"|"),v}print ""}')
  [[ "$header" == 'check|result|evidence / limit' || "$header" == '检查|结果|证据与限制' ]] || { printf 'review-basis table needs the exact three columns'; return 1; }
  basis_stats=$(printf '%s\n' "$basis_table" | awk -F'|' '
    function trim(v){gsub(/^[[:space:]`*]+|[[:space:]`*]+$/,"",v);return v}
    BEGIN{en["Scope identity and current fingerprint"]=1;en["Owner and route resolution"]=1;en["STATUS claim and artifact agreement"]=1;zh["范围身份与当前指纹"]=1;zh["所有者与路由可解析"]=1;zh["STATUS 结论与产物一致"]=1}
    NR<=2{next}/^\|/{label=trim($2);result=tolower(trim($3));evidence=trim($4);rows++;if((!(label in en)&&!(label in zh))||seen[label]++||result!="pass"||length(evidence)<8)invalid++}
    END{en_ok=(seen["Scope identity and current fingerprint"]&&seen["Owner and route resolution"]&&seen["STATUS claim and artifact agreement"]);zh_ok=(seen["范围身份与当前指纹"]&&seen["所有者与路由可解析"]&&seen["STATUS 结论与产物一致"]);if(!en_ok&&!zh_ok)invalid++;printf "%d|%d",rows+0,invalid+0}' )
  [[ "$basis_stats" == '3|0' ]] || { printf 'review basis must contain the three exact passing checks with non-empty evidence (got %s)' "$basis_stats"; return 1; }
  table=$(scope_review_profile_table "$artifact")
  [[ -n "$table" ]] || { printf 'body is missing the exact profile table'; return 1; }
  header=$(printf '%s\n' "$table" | head -1 | awk -F'|' '{for(i=2;i<NF;i++){v=$i;gsub(/^[[:space:]`]+|[[:space:]`]+$/,"",v);if(v~/^[A-Za-z _\/-]+$/)v=tolower(v);printf "%s%s",(i==2?"":"|"),v}print ""}')
  [[ "$header" == 'item id|disposition|plain answer|owner / evidence' || "$header" == '项目 id|处置|白话结论|所有者或证据' ]] || { printf 'exact-profile table needs the exact four columns including Plain answer'; return 1; }
  expected_ids=$(scope_review_expected_ids "$profile" | paste -sd, -)
  stats=$(printf '%s\n' "$table" | awk -F'|' -v expected="$expected_ids" -v artifact="$artifact" '
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/[`*]/, "", v); return v }
    BEGIN { n=split(expected,list,","); for(i=1;i<=n;i++) required[list[i]]=1 }
    NR<=2 { next }
    /^\|/ { id=trim($2); disposition=tolower(trim($3)); answer=trim($4); evidence=trim($5); rows++; if (!(id in required) || seen[id]++) invalid++; if (disposition=="covered") covered++; else if (disposition ~ /^not_applicable:[[:space:]].{8,}$/) { na++; if (length(evidence)<8) invalid++ } else invalid++; if(length(answer)<16||tolower(answer)~/^(covered|not applicable|see |link |pass$)/||answer~/(C|PR|R|G|RT|S|Q)[0-9][0-9]/)invalid++; links=evidence; link_count=gsub(/\[[^]]+\]\([^)]+[.]md(#[^)]*)?\)/,"",links); if (link_count!=1) invalid++ }
    END { for(id in required) if(seen[id]!=1) invalid++; printf "%d|%d|%d|%d", rows+0, invalid+0, covered+0, na+0 }
  ' 2>/dev/null)
  [[ "$stats" == "${expected_count}|0|${declared_covered}|${declared_na}" ]] || { printf 'exact profile must contain each required ID once with one link and declared counts (got %s)' "$stats"; return 1; }
  while IFS= read -r evidence; do
    [[ -n "$evidence" ]] || continue
    [[ "$(manifest_markdown_link_count "$evidence")" -eq 1 ]] && markdown_link_resolves_with_anchor "$artifact" "$evidence" || { printf 'profile owner/evidence link or fragment does not resolve: %s' "$evidence"; return 1; }
    resolved=$(manifest_markdown_link_resolved_path "$artifact" "$evidence" 2>/dev/null || true)
    [[ "$resolved" != "$artifact" ]] || { printf 'profile evidence must not self-link the review artifact'; return 1; }
    linked_review_id=$(review_frontmatter_value "$resolved" review_id 2>/dev/null || true)
    [[ "$linked_review_id" != scope-review:* ]] || { printf 'profile evidence must link a fact owner, not another current scope-review artifact'; return 1; }
  done < <(printf '%s\n' "$table" | awk -F'|' 'NR>2 && /^\|/ { value=$5; gsub(/^[[:space:]]+|[[:space:]]+$/, "", value); print value }')
  (( declared_covered + declared_na == expected_count )) || { printf 'covered plus not_applicable counts must equal profile_item_count'; return 1; }
  semantic_table=$(scope_review_semantic_table "$artifact")
  [[ -n "$semantic_table" ]] || { printf 'body is missing the semantic-truth sample table'; return 1; }
  header=$(printf '%s\n' "$semantic_table" | head -1 | awk -F'|' '{for(i=2;i<NF;i++){v=$i;gsub(/^[[:space:]`]+|[[:space:]`]+$/,"",v);if(v~/^[A-Za-z _\/-]+$/)v=tolower(v);printf "%s%s",(i==2?"":"|"),v}print ""}')
  [[ "$header" == 'item id|owner/body claim|repository/evidence sample|truth result|limit' || "$header" == '项目 id|所有者正文结论|仓库或证据样本|真实性结果|限制' ]] || { printf 'semantic-truth sample needs the exact five columns'; return 1; }
  semantic_stats=$(awk -F'|' -v families="$expected_families" '
    function trim(v){gsub(/^[[:space:]`*]+|[[:space:]`*]+$/,"",v);return v}
    function family(id){if(id~/^PR/)return "PR";if(id~/^RT/)return "RT";if(id~/^C/)return "C";if(id~/^R/)return "R";if(id~/^G/)return "G";if(id~/^S/)return "S";if(id~/^Q/)return "Q";return ""}
    BEGIN{n=split(families,a,",");for(i=1;i<=n;i++)required_family[a[i]]=1}
    NR==FNR{if(FNR>2&&/^\|/){id=trim($2);d=tolower(trim($3));disposition[id]=d;if(d=="covered")profile_covered++;else if(d~/^not_applicable:/)profile_na++};next}
    FNR>2&&/^\|/{id=trim($2);claim=trim($3);sample=trim($4);result=tolower(trim($5));limit=trim($6);rows++;f=family(id);if(!(id in disposition)||seen[id]++||!(f in required_family)||result!="pass"||length(claim)<12||length(sample)<8||length(limit)<8)invalid++;family_seen[f]=1;if(disposition[id]=="covered")sample_covered++;else if(disposition[id]~/^not_applicable:/)sample_na++}
    END{for(f in required_family)if(!family_seen[f])invalid++;if(profile_covered&&profile_na&&(!sample_covered||!sample_na))invalid++;printf "%d|%d",rows+0,invalid+0}
  ' <(printf '%s\n' "$table") <(printf '%s\n' "$semantic_table"))
  [[ "$semantic_stats" =~ ^[0-9]+\|0$ ]] || { printf 'semantic sample must pass unique exact-profile IDs, every profile family, and both used dispositions (got %s)' "$semantic_stats"; return 1; }
  while IFS= read -r evidence; do
    [[ "$(manifest_markdown_link_count "$evidence")" -eq 1 ]] && markdown_link_resolves_with_anchor "$artifact" "$evidence" || { printf 'semantic repository/evidence sample does not resolve: %s' "$evidence"; return 1; }
    resolved=$(manifest_markdown_link_resolved_path "$artifact" "$evidence" 2>/dev/null || true)
    [[ "$resolved" != "$artifact" ]] || { printf 'semantic evidence must not self-link the review artifact'; return 1; }
    linked_review_id=$(review_frontmatter_value "$resolved" review_id 2>/dev/null || true)
    [[ "$linked_review_id" != scope-review:* ]] || { printf 'semantic evidence must link current fact/evidence, not another scope-review artifact'; return 1; }
  done < <(printf '%s\n' "$semantic_table" | awk -F'|' 'NR>2&&/^\|/{v=$4;gsub(/^[[:space:]]+|[[:space:]]+$/,"",v);print v}')
  target_table=$(scope_review_target_table "$artifact")
  [[ -n "$target_table" ]] || { printf 'body is missing the exact target-coverage table'; return 1; }
  header=$(printf '%s\n' "$target_table" | head -1 | awk -F'|' '{for(i=2;i<NF;i++){v=$i;gsub(/^[[:space:]`]+|[[:space:]`]+$/,"",v);if(v~/^[A-Za-z _\/-]+$/)v=tolower(v);printf "%s%s",(i==2?"":"|"),v}print ""}')
  [[ "$header" == 'target id|target owner|profile ids exercised|repository/evidence sample|truth result|limit' || "$header" == '目标 id|目标所有者|已核验画像 id|仓库或证据样本|真实性结果|限制' ]] || { printf 'target coverage table needs the exact six columns'; return 1; }
  expected_targets=$(scope_review_expected_targets "$profile" 2>/dev/null || true)
  [[ -n "$expected_targets" ]] || { printf 'scope has no enumerable real review target'; return 1; }
  declare -A expected_target_set=() seen_target_set=() expected_profile_set=() exercised_profile_set=() target_id_set=()
  while IFS= read -r target_key; do [[ -n "$target_key" ]] && expected_target_set[$target_key]=1; done <<< "$expected_targets"
  while IFS= read -r id; do expected_profile_set[$id]=1; done < <(scope_review_expected_ids "$profile")
  while IFS=$'\034' read -r target_id target_owner exercised_ids target_evidence target_result target_limit; do
    [[ -n "$target_id" ]] || continue
    [[ "$target_id" =~ ^[A-Za-z0-9][A-Za-z0-9:._/-]*$ && -z "${target_id_set[$target_id]:-}" ]] || { printf 'target coverage has invalid or duplicate Target ID %s' "$target_id"; return 1; }
    target_id_set[$target_id]=1
    [[ ${#target_owner} -ge 4 && "$target_result" == pass && ${#target_limit} -ge 8 ]] || { printf 'target %s needs a plain owner, pass result, and real limit' "$target_id"; return 1; }
    target_key=$(strict_ssot_markdown_target_key "$artifact" "$target_evidence" 2>/dev/null || true)
    [[ -n "$target_key" && -n "${expected_target_set[$target_key]:-}" && -z "${seen_target_set[$target_key]:-}" ]] || { printf 'target %s evidence is missing, duplicated, outside the scope target set, a review, or a symlink' "$target_id"; return 1; }
    seen_target_set[$target_key]=1
    [[ -n "$exercised_ids" ]] || { printf 'target %s has no exercised profile IDs' "$target_id"; return 1; }
    while IFS= read -r id; do
      id=$(printf '%s' "$id" | awk '{$1=$1;print}')
      [[ -n "$id" && -n "${expected_profile_set[$id]:-}" ]] || { printf 'target %s exercises invalid profile ID %s' "$target_id" "$id"; return 1; }
      exercised_profile_set[$id]=1
    done < <(printf '%s\n' "$exercised_ids" | tr ',' '\n')
  done < <(printf '%s\n' "$target_table" | awk -F'|' 'BEGIN{s=sprintf("%c",28)}NR>2&&/^\|/{for(i=2;i<=7;i++){v=$i;gsub(/^[[:space:]`]+|[[:space:]`]+$/,"",v);c[i]=v}print c[2] s c[3] s c[4] s c[5] s tolower(c[6]) s c[7]}')
  [[ "${#seen_target_set[@]}" -eq "${#expected_target_set[@]}" ]] || { printf 'target coverage must contain every real target exactly once (%s/%s)' "${#seen_target_set[@]}" "${#expected_target_set[@]}"; return 1; }
  for target_key in "${!expected_target_set[@]}"; do [[ -n "${seen_target_set[$target_key]:-}" ]] || { printf 'target coverage omits %s' "${target_key#"$SSOT_DIR/"}"; return 1; }; done
  [[ "${#exercised_profile_set[@]}" -eq "${#expected_profile_set[@]}" ]] || { printf 'target coverage profile-ID union is incomplete (%s/%s)' "${#exercised_profile_set[@]}" "${#expected_profile_set[@]}"; return 1; }
  for id in "${!expected_profile_set[@]}"; do [[ -n "${exercised_profile_set[$id]:-}" ]] || { printf 'target coverage does not exercise %s' "$id"; return 1; }; done
  required_table=$(review_required_changes_table "$artifact")
  [[ -n "$required_table" ]] || { printf 'body is missing the required-changes table'; return 1; }
  header=$(printf '%s\n' "$required_table" | head -1 | awk -F'|' '{for(i=2;i<NF;i++){v=$i;gsub(/^[[:space:]`]+|[[:space:]`]+$/,"",v);if(v~/^[A-Za-z _\/-]+$/)v=tolower(v);printf "%s%s",(i==2?"":"|"),v}print ""}')
  [[ "$header" == 'change id|status|required change|owner|closure evidence' || "$header" == '必改项 id|状态|必改内容|所有者|闭合证据' ]] || { printf 'required-changes table needs the exact five columns'; return 1; }
  required_stats=$(printf '%s\n' "$required_table" | awk -F'|' '
    function trim(v){gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/[`*]/, "", v); return v}
    NR<=2{next} /^\|/{id=trim($2); state=tolower(trim($3)); change=trim($4); owner=trim($5); evidence=trim($6); rows++; if(tolower(id)=="none" || id=="无"){sentinel++; if(state!="none" || length(change)<8 || length(evidence)<8) invalid++; next} if(id!~/^RC-[0-9][0-9]+$/ || seen[id]++)invalid++; if(state!~/^(resolved|pending|required|open)$/)invalid++; if(length(change)<8 || length(owner)<2 || length(evidence)<8)invalid++; if(state~/^(pending|required|open)$/)unresolved++} END{if(rows<1)invalid++; if(sentinel>0 && (sentinel!=1 || rows!=1))invalid++; printf "%d|%d|%d",rows+0,invalid+0,unresolved+0}' )
  [[ "$(printf '%s' "$required_stats" | cut -d'|' -f2-3)" == "0|0" ]] || { printf 'required-changes table contradicts passing verdict (got %s)' "$required_stats"; return 1; }
  final_stats=$(awk -v expected="$(review_frontmatter_value "$artifact" verdict)" '
    BEGIN{front=fence=comment=0}
    NR==1&&/^---[[:space:]]*$/{front=1;next}front{if(/^---[[:space:]]*$/)front=0;next}
    {line=$0;if(comment){if(line~/-->/)comment=0;next};if(line~/<!--/){if(line!~/-->/)comment=1;next};if(line~/^[[:space:]]*```/){fence=!fence;next};if(fence)next
      if(line~/^(Final verdict[[:space:]]*:|最终结论[[:space:]]*[：:])/){count++;sub(/^(Final verdict[[:space:]]*:|最终结论[[:space:]]*[：:])[[:space:]]*/,"",line);gsub(/[`[:space:].。]/,"",line);if(line!=expected)invalid++}}
    END{printf "%d|%d",count+0,invalid+0}' "$artifact")
  [[ "$final_stats" == '1|0' ]] || { printf 'body must contain one visible Final verdict matching frontmatter (got %s)' "$final_stats"; return 1; }
  return 0
}

record_index_header_count() { # README en-signature zh-signature en-H2 zh-H2
  local file="$1" expected_en="$2" expected_zh="$3" heading_en="$4" heading_zh="$5"
  awk -F'|' -v en="$expected_en" -v zh="$expected_zh" -v h_en="$heading_en" -v h_zh="$heading_zh" '
    BEGIN{front=fence=comment=active=sections=0}
    function trim(v){gsub(/^[[:space:]`]+|[[:space:]`]+$/,"",v);return tolower(v)}
    NR==1&&/^---[[:space:]]*$/{front=1;next}front{if(/^---[[:space:]]*$/)front=0;next}
    {line=$0;if(comment){if(line~/-->/)comment=0;next};if(line~/<!--/){if(line!~/-->/)comment=1;next};if(line~/^[[:space:]]*(```|~~~)/){fence=!fence;next};if(fence)next}
    /^##[[:space:]]+/{title=$0;sub(/^##[[:space:]]+/,"",title);title=trim(title);active=(title==tolower(h_en)||title==tolower(h_zh));if(active)sections++;next}
    active&&/^\|/{sig="";for(i=2;i<NF;i++)sig=sig (i==2?"":"|") trim($i);if(sig==en||sig==zh)count++}
    END{if(sections!=1)print -1;else print count+0}
  ' "$file"
}

record_index_table() { # README en-signature zh-signature en-H2 zh-H2
  local file="$1" expected_en="$2" expected_zh="$3" heading_en="$4" heading_zh="$5"
  awk -F'|' -v en="$expected_en" -v zh="$expected_zh" -v h_en="$heading_en" -v h_zh="$heading_zh" '
    BEGIN{front=fence=comment=section=table=0}
    function trim(v){gsub(/^[[:space:]`]+|[[:space:]`]+$/,"",v);return tolower(v)}
    NR==1&&/^---[[:space:]]*$/{front=1;next}front{if(/^---[[:space:]]*$/)front=0;next}
    {line=$0;if(comment){if(line~/-->/)comment=0;next};if(line~/<!--/){if(line!~/-->/)comment=1;next};if(line~/^[[:space:]]*(```|~~~)/){fence=!fence;next};if(fence)next}
    /^##[[:space:]]+/{title=$0;sub(/^##[[:space:]]+/,"",title);title=trim(title);section=(title==tolower(h_en)||title==tolower(h_zh));if(table)exit;next}
    section&&/^\|/{sig="";for(i=2;i<NF;i++)sig=sig (i==2?"":"|") trim($i);if(!table&&(sig==en||sig==zh)){table=1;print;next};if(table){print;next}}
    table{exit}
  ' "$file"
}

record_frontmatter_closed() { # $1=entry
  awk 'NR==1{if($0!~/^---[[:space:]]*$/)exit 1;front=1;next}front&&/^---[[:space:]]*$/{closed=1;exit}END{exit(closed?0:1)}' "$1"
}

record_visible_empty_collection_lines() { # $1=collection README
  # Only visible body prose can declare an empty collection. A template inside
  # frontmatter, an HTML comment, a code fence, or inline code is not evidence.
  awk '
    BEGIN{front=fence=comment=0}
    NR==1&&/^---[[:space:]]*$/{front=1;next}
    front{if(/^---[[:space:]]*$/)front=0;next}
    {line=$0
      if(comment){if(line~/-->/)comment=0;next}
      if(line~/<!--/){if(line!~/-->/)comment=1;next}
      if(line~/^[[:space:]]*(```|~~~)/){fence=!fence;next}
      if(fence)next
      if(line~/^(Empty collection:[[:space:]]*|空集合说明：)/)print line
    }
  ' "$1"
}

record_index_has_empty_disposition() { # $1=collection README
  local index="$1" lines line reason owner trigger en_re zh_re
  lines=$(record_visible_empty_collection_lines "$index")
  [[ $(printf '%s\n' "$lines" | sed '/^$/d' | wc -l | tr -d ' ') -eq 1 ]] || return 1
  line=$(printf '%s\n' "$lines" | sed '/^$/d')
  en_re='^Empty collection:[[:space:]]*reason=([^;]+);[[:space:]]*owner=([^;]+);[[:space:]]*review when=(.+)\.$'
  zh_re='^空集合说明：原因=([^；]+)；负责人=([^；]+)；复核条件=(.+)。$'
  if [[ "$line" =~ $en_re ]]; then
    reason="${BASH_REMATCH[1]}"; owner="${BASH_REMATCH[2]}"; trigger="${BASH_REMATCH[3]}"
  elif [[ "$line" =~ $zh_re ]]; then
    reason="${BASH_REMATCH[1]}"; owner="${BASH_REMATCH[2]}"; trigger="${BASH_REMATCH[3]}"
  else
    return 1
  fi
  [[ ${#reason} -ge 8 && ${#trigger} -ge 8 ]] || return 1
  printf '%s\n%s\n' "$reason" "$trigger" | grep -qE '<[^>]+>|TODO|TBD|待补|待定' && return 1
  if [[ "$(manifest_markdown_link_count "$owner")" -eq 1 ]]; then
    markdown_link_resolves_with_anchor "$index" "$owner" || return 1
  else
    printf '%s\n' "$owner" | grep -Eq '^`?\$ssot-(preflight|bootstrap|closeout|audit|doctor|skill)`?$' || return 1
  fi
  return 0
}

validate_v260_standard_record_collection() { # name dir prefix axis rec-enum axis-enum alias-target en-header zh-header en-H2 zh-H2
  local name="$1" dir="$2" prefix="$3" axis_key="$4" record_enum="$5" axis_enum="$6" alias_target="$7" expected_en="$8" expected_zh="$9"
  local heading_en="${10}" heading_zh="${11}"
  local index="$dir/README.md" file fm id id_number basename record axis status promotion table sep row_id row_record row_axis owner resolved expected_alias
  local status_count promotion_count nested_index
  local entry_count=0 index_count=0
  declare -A entry_record=() entry_axis=() entry_path=() index_seen=()
  [[ -d "$dir" && -f "$index" ]] || { printf '%s collection needs its directory and README index' "$name"; return 1; }
  [[ "$(record_index_header_count "$index" "$expected_en" "$expected_zh" "$heading_en" "$heading_zh")" -eq 1 ]] || { printf '%s index needs exactly one visible exact table under its unique %s / %s H2' "$name" "$heading_en" "$heading_zh"; return 1; }
  while IFS= read -r -d '' nested_index; do
    [[ "$(record_index_header_count "$nested_index" "$expected_en" "$expected_zh" "$heading_en" "$heading_zh")" -ne 1 ]] || { printf '%s nested README may navigate but must not duplicate the root state index: %s' "$name" "${nested_index#"$SSOT_DIR/"}"; return 1; }
  done < <(find "$dir" -mindepth 2 -type f -name 'README.md' -print0 2>/dev/null)
  while IFS= read -r -d '' file; do
    record_frontmatter_closed "$file" || { printf '%s entry has no closed leading frontmatter: %s' "$name" "${file#"$SSOT_DIR/"}"; return 1; }
    fm=$(yaml_frontmatter "$file")
    for field in id record_status "$axis_key"; do
      [[ $(printf '%s\n' "$fm" | grep -Ec "^${field}:[[:space:]]*" || true) -eq 1 ]] || { printf '%s entry must declare exactly one %s: %s' "$name" "$field" "${file#"$SSOT_DIR/"}"; return 1; }
    done
    id=$(review_frontmatter_value "$file" id); record=$(review_frontmatter_value "$file" record_status); axis=$(review_frontmatter_value "$file" "$axis_key")
    [[ "$id" =~ ^${prefix}-[0-9]{4}$ ]] || { printf '%s entry has invalid stable ID %s; expected %s-NNNN' "$name" "$id" "$prefix"; return 1; }
    id_number="${id#${prefix}-}"; basename=$(basename "$file")
    [[ "$basename" =~ ^${id_number}-.+\.md$ ]] || { printf '%s entry %s must use matching NNNN-slug.md filename (got %s)' "$name" "$id" "$basename"; return 1; }
    [[ -z "${entry_path[$id]:-}" ]] || { printf '%s entry ID is duplicated: %s' "$name" "$id"; return 1; }
    [[ "$record" =~ ^($record_enum)$ ]] || { printf '%s entry %s has invalid record_status %s' "$name" "$id" "$record"; return 1; }
    [[ "$axis" =~ ^($axis_enum)$ ]] || { printf '%s entry %s has invalid %s %s' "$name" "$id" "$axis_key" "$axis"; return 1; }
    status_count=$(printf '%s\n' "$fm" | grep -Ec '^status:[[:space:]]*' || true)
    [[ "$status_count" -le 1 ]] || { printf '%s entry %s repeats compatibility status' "$name" "$id"; return 1; }
    status=$(review_frontmatter_value "$file" status)
    expected_alias="$record"; [[ "$alias_target" == axis ]] && expected_alias="$axis"
    [[ "$status_count" -eq 0 || ( -n "$status" && "$status" == "$expected_alias" ) ]] || { printf '%s entry %s compatibility status must be non-empty and mirror %s' "$name" "$id" "$alias_target"; return 1; }
    if [[ "$name" == research ]]; then
      promotion_count=$(printf '%s\n' "$fm" | grep -Ec '^promotion_state:[[:space:]]*' || true)
      [[ "$promotion_count" -le 1 ]] || { printf 'research entry %s repeats promotion_state alias' "$id"; return 1; }
      promotion=$(review_frontmatter_value "$file" promotion_state)
      [[ "$promotion_count" -eq 0 || ( -n "$promotion" && "$promotion" == "$axis" ) ]] || { printf 'research entry %s promotion_state must be non-empty and mirror adoption_state' "$id"; return 1; }
    fi
    entry_record[$id]="$record"; entry_axis[$id]="$axis"; entry_path[$id]=$(realpath "$file"); entry_count=$((entry_count + 1))
  done < <(find "$dir" -type f -name '*.md' ! -name 'README.md' ! -name '_*.md' -print0 2>/dev/null)
  table=$(record_index_table "$index" "$expected_en" "$expected_zh" "$heading_en" "$heading_zh")
  sep=$(printf '\034')
  while IFS="$sep" read -r row_id row_record row_axis owner; do
    [[ -n "$row_id" ]] || continue
    [[ "$row_id" =~ ^${prefix}-[0-9]{4}$ ]] || { printf '%s index has invalid ID %s; expected %s-NNNN' "$name" "$row_id" "$prefix"; return 1; }
    [[ -z "${index_seen[$row_id]:-}" ]] || { printf '%s index duplicates %s' "$name" "$row_id"; return 1; }
    index_seen[$row_id]=1; index_count=$((index_count + 1))
    [[ -n "${entry_path[$row_id]:-}" ]] || { printf '%s index row %s has no entry owner' "$name" "$row_id"; return 1; }
    [[ "$row_record" == "${entry_record[$row_id]}" && "$row_axis" == "${entry_axis[$row_id]}" ]] || { printf '%s index row %s does not mirror both entry state axes' "$name" "$row_id"; return 1; }
    [[ "$(manifest_markdown_link_count "$owner")" -eq 1 ]] && markdown_link_resolves_with_anchor "$index" "$owner" || { printf '%s index row %s needs one resolving entry-owner link' "$name" "$row_id"; return 1; }
    resolved=$(manifest_markdown_link_resolved_path "$index" "$owner" 2>/dev/null || true)
    [[ "$resolved" == "${entry_path[$row_id]}" ]] || { printf '%s index row %s points to the wrong entry owner' "$name" "$row_id"; return 1; }
  done < <(printf '%s\n' "$table" | awk -F'|' '
    BEGIN{sep=sprintf("%c",28)}function trim(v){gsub(/^[[:space:]`]+|[[:space:]`]+$/,"",v);return v}
    NR>2&&/^\|/{print trim($2) sep trim($4) sep trim($5) sep trim($(NF-1))}
  ')
  [[ "$index_count" -eq "$entry_count" ]] || { printf '%s index/entry count mismatch (%s/%s)' "$name" "$index_count" "$entry_count"; return 1; }
  if [[ "$entry_count" -eq 0 ]]; then
    record_index_has_empty_disposition "$index" || { printf '%s empty index needs one reason/owner/review_trigger disposition' "$name"; return 1; }
  elif [[ -n "$(record_visible_empty_collection_lines "$index")" ]]; then
    printf '%s populated index must remove its empty disposition' "$name"; return 1
  fi
  for id in "${!entry_path[@]}"; do [[ -n "${index_seen[$id]:-}" ]] || { printf '%s entry %s is missing from the index' "$name" "$id"; return 1; }; done
  return 0
}

gotcha_aggregate_entries() { # $1=topic file; ID<FS>record<FS>hazard<FS>state-line-count<FS>heading
  awk '
    BEGIN{sep=sprintf("%c",28);front=fence=comment=0}
    NR==1&&/^---[[:space:]]*$/{front=1;next}front{if(/^---[[:space:]]*$/)front=0;next}
    function emit(){if(id!="")print id sep record sep hazard sep states sep heading}
    {line=$0;if(comment){if(line~/-->/)comment=0;next};if(line~/<!--/){if(line!~/-->/)comment=1;next};if(line~/^[[:space:]]*```/){fence=!fence;next};if(fence)next}
    /^##[[:space:]]+/{emit();id=record=hazard=heading="";states=0;heading=$0;sub(/^##[[:space:]]+/,"",heading);gsub(/[[:space:]]+#+[[:space:]]*$/,"",heading);gsub(/^[[:space:]]+|[[:space:]]+$/,"",heading);if(heading~/^GOT-[0-9]{4}$/)id=heading;else if(heading~/^GOT-/)print "__INVALID__" sep "" sep "" sep "0" sep heading;next}
    id!=""&&(/Record status[[:space:]]*\/[[:space:]]*hazard state/||/记录状态[[:space:]]*\/[[:space:]]*危险状态/){n=split($0,a,"`");if(n>=5){record=a[2];hazard=a[4]};states++}
    END{emit()}
  ' "$1"
}

validate_v260_gotcha_collection() {
  local dir="$GOTCHAS_DIR" index="$GOTCHAS_DIR/README.md" expected_en='id|pitfall|record status|hazard state|trigger hint|entry owner' expected_zh='id|陷阱|记录状态|危险状态|触发提示|条目所有者'
  local heading_en='Pitfall index' heading_zh='陷阱索引'
  local file fm id id_number basename record hazard status table sep row_id row_record row_hazard owner resolved fragment expected_fragment heading state_count
  local status_count nested_index per_file_count
  local entry_count=0 index_count=0
  declare -A entry_record=() entry_hazard=() entry_path=() entry_fragment=() index_seen=()
  [[ -d "$dir" && -f "$index" ]] || { printf 'gotchas collection needs its directory and README index'; return 1; }
  [[ "$(record_index_header_count "$index" "$expected_en" "$expected_zh" "$heading_en" "$heading_zh")" -eq 1 ]] || { printf 'gotchas index needs exactly one visible exact table under its unique Pitfall index / 陷阱索引 H2'; return 1; }
  while IFS= read -r -d '' nested_index; do
    [[ "$(record_index_header_count "$nested_index" "$expected_en" "$expected_zh" "$heading_en" "$heading_zh")" -ne 1 ]] || { printf 'gotchas nested README may navigate but must not duplicate the root state index: %s' "${nested_index#"$SSOT_DIR/"}"; return 1; }
  done < <(find "$dir" -mindepth 2 -type f -name 'README.md' -print0 2>/dev/null)
  while IFS= read -r -d '' file; do
    fm=$(yaml_frontmatter "$file")
    id=$(review_frontmatter_value "$file" id)
    if [[ -n "$id" ]]; then
      record_frontmatter_closed "$file" || { printf 'gotcha entry has no closed frontmatter: %s' "${file#"$SSOT_DIR/"}"; return 1; }
      for field in id record_status hazard_state; do [[ $(printf '%s\n' "$fm" | grep -Ec "^${field}:[[:space:]]*" || true) -eq 1 ]] || { printf 'gotcha entry %s needs exactly one %s' "$id" "$field"; return 1; }; done
      record=$(review_frontmatter_value "$file" record_status); hazard=$(review_frontmatter_value "$file" hazard_state); status=$(review_frontmatter_value "$file" status)
      [[ "$id" =~ ^GOT-[0-9]{4}$ && "$record" =~ ^(current|archived|superseded)$ && "$hazard" =~ ^(active|resolved)$ ]] || { printf 'gotcha entry %s has invalid ID or state axis; expected GOT-NNNN' "$id"; return 1; }
      id_number="${id#GOT-}"; basename=$(basename "$file")
      [[ "$basename" =~ ^${id_number}-.+\.md$ ]] || { printf 'gotcha entry %s must use matching NNNN-slug.md filename (got %s)' "$id" "$basename"; return 1; }
      status_count=$(printf '%s\n' "$fm" | grep -Ec '^status:[[:space:]]*' || true)
      [[ "$status_count" -le 1 ]] || { printf 'gotcha entry %s repeats compatibility status' "$id"; return 1; }
      [[ "$status_count" -eq 0 || ( -n "$status" && "$status" == "$hazard" ) ]] || { printf 'gotcha entry %s compatibility status must be non-empty and mirror hazard_state' "$id"; return 1; }
      [[ -z "${entry_path[$id]:-}" ]] || { printf 'gotcha ID is duplicated: %s' "$id"; return 1; }
      entry_record[$id]="$record"; entry_hazard[$id]="$hazard"; entry_path[$id]=$(realpath "$file"); entry_fragment[$id]=""; entry_count=$((entry_count + 1))
    else
      per_file_count=0
      while IFS=$'\034' read -r id record hazard state_count heading; do
        [[ -n "$id" ]] || continue
        [[ "$id" != "__INVALID__" ]] || { printf 'gotcha aggregate H2 must be the exact stable ID only (got %s)' "$heading"; return 1; }
        [[ -z "${entry_path[$id]:-}" ]] || { printf 'gotcha aggregate ID is duplicated: %s' "$id"; return 1; }
        [[ "$state_count" -eq 1 && "$record" =~ ^(current|archived|superseded)$ && "$hazard" =~ ^(active|resolved)$ ]] || { printf 'gotcha aggregate %s needs one explicit valid Record status / hazard state line' "$id"; return 1; }
        entry_record[$id]="$record"; entry_hazard[$id]="$hazard"; entry_path[$id]=$(realpath "$file"); entry_fragment[$id]=$(printf '%s\n' "$heading" | markdown_heading_slug); entry_count=$((entry_count + 1))
        per_file_count=$((per_file_count + 1))
      done < <(gotcha_aggregate_entries "$file")
      [[ "$per_file_count" -gt 0 ]] || { printf 'gotcha topic needs frontmatter id or at least one exact ## GOT-NNNN block: %s' "${file#"$SSOT_DIR/"}"; return 1; }
    fi
  done < <(find "$dir" -type f -name '*.md' ! -name 'README.md' ! -name '_*.md' -print0 2>/dev/null)
  table=$(record_index_table "$index" "$expected_en" "$expected_zh" "$heading_en" "$heading_zh"); sep=$(printf '\034')
  while IFS="$sep" read -r row_id row_record row_hazard owner; do
    [[ -n "$row_id" ]] || continue
    [[ "$row_id" =~ ^GOT-[0-9]{4}$ && -z "${index_seen[$row_id]:-}" ]] || { printf 'gotchas index has invalid or duplicate ID %s; expected GOT-NNNN' "$row_id"; return 1; }
    index_seen[$row_id]=1; index_count=$((index_count + 1))
    [[ -n "${entry_path[$row_id]:-}" && "$row_record" == "${entry_record[$row_id]}" && "$row_hazard" == "${entry_hazard[$row_id]}" ]] || { printf 'gotchas index row %s lacks an entry or does not mirror both axes' "$row_id"; return 1; }
    [[ "$(manifest_markdown_link_count "$owner")" -eq 1 ]] && markdown_link_resolves_with_anchor "$index" "$owner" || { printf 'gotchas index row %s needs one resolving owner/anchor link' "$row_id"; return 1; }
    resolved=$(manifest_markdown_link_resolved_path "$index" "$owner" 2>/dev/null || true); fragment=$(markdown_link_fragment "$owner")
    [[ "$resolved" == "${entry_path[$row_id]}" ]] || { printf 'gotchas index row %s points to the wrong topic file' "$row_id"; return 1; }
    expected_fragment="${entry_fragment[$row_id]}"
    if [[ -n "$expected_fragment" ]]; then [[ "$fragment" == "$expected_fragment" ]] || { printf 'gotchas index row %s must link its exact heading anchor' "$row_id"; return 1; }; fi
  done < <(printf '%s\n' "$table" | awk -F'|' 'BEGIN{sep=sprintf("%c",28)}function trim(v){gsub(/^[[:space:]`]+|[[:space:]`]+$/,"",v);return v}NR>2&&/^\|/{print trim($2) sep trim($4) sep trim($5) sep trim($(NF-1))}')
  [[ "$index_count" -eq "$entry_count" ]] || { printf 'gotchas index/entry count mismatch (%s/%s)' "$index_count" "$entry_count"; return 1; }
  if [[ "$entry_count" -eq 0 ]]; then
    record_index_has_empty_disposition "$index" || { printf 'gotchas empty index needs one reason/owner/review_trigger disposition'; return 1; }
  elif [[ -n "$(record_visible_empty_collection_lines "$index")" ]]; then
    printf 'gotchas populated index must remove its empty disposition'; return 1
  fi
  for id in "${!entry_path[@]}"; do [[ -n "${index_seen[$id]:-}" ]] || { printf 'gotcha entry %s is missing from the index' "$id"; return 1; }; done
  return 0
}

check_v260_record_exact_indexes() {
  local failures=0 checked=0 reason aggregate=0
  document_area_is_covered records && aggregate=1
  if [[ "$aggregate" -eq 1 ]] || document_area_is_covered decisions; then
    checked=$((checked + 1)); if ! reason=$(validate_v260_standard_record_collection decisions "$DECISIONS_DIR" DEC implementation_state 'accepted|deprecated|superseded' 'pending|partial|implemented|diverged|superseded' record 'id|title|record status|implementation state|date|entry owner' '编号|标题|记录状态|实现状态|日期|条目所有者' 'Decision Index' '决策索引' 2>&1); then add_fail "[RECORD-EXACT-INDEX] $reason"; failures=$((failures + 1)); fi
  fi
  if [[ "$aggregate" -eq 1 ]] || document_area_is_covered 'research records'; then
    checked=$((checked + 1)); if ! reason=$(validate_v260_standard_record_collection research "$RESEARCH_AREA_DIR" RES adoption_state 'draft|validated|stale|superseded' 'unpromoted|partial|promoted|rejected' record 'id|title|record status|adoption state|kind|created|entry owner' '编号|标题|记录状态|结论采纳状态|类型|创建日期|条目所有者' 'Research Index' '研究索引' 2>&1); then add_fail "[RECORD-EXACT-INDEX] $reason"; failures=$((failures + 1)); fi
  fi
  if [[ "$aggregate" -eq 1 ]] || document_area_is_covered bugs; then
    checked=$((checked + 1)); if ! reason=$(validate_v260_standard_record_collection bugs "$BUGS_DIR" BUG failure_state 'current|archived|superseded' 'open|fixed|recurred' axis 'id|failure mode|record status|failure state|severity|entry owner' 'id|失败方式|记录状态|失败状态|严重性|条目所有者' 'Bug index' '缺陷索引' 2>&1); then add_fail "[RECORD-EXACT-INDEX] $reason"; failures=$((failures + 1)); fi
  fi
  if [[ "$aggregate" -eq 1 ]] || document_area_is_covered gotchas; then
    checked=$((checked + 1)); if ! reason=$(validate_v260_gotcha_collection 2>&1); then add_fail "[RECORD-EXACT-INDEX] $reason"; failures=$((failures + 1)); fi
  fi
  if [[ "$aggregate" -eq 1 ]] || document_area_is_covered tech-debt; then
    checked=$((checked + 1)); if ! reason=$(validate_v260_standard_record_collection tech-debt "$TECH_DEBT_DIR" DEBT repayment_state 'current|archived|superseded' 'active|resolved|obsolete' axis 'id|debt|record status|repayment state|priority|entry owner' 'id|债务|记录状态|偿还状态|优先级|条目所有者' 'Debt index' '债务索引' 2>&1); then add_fail "[RECORD-EXACT-INDEX] $reason"; failures=$((failures + 1)); fi
  fi
  [[ "$checked" -gt 0 && "$failures" -eq 0 ]] && add_pass '[RECORD-EXACT-INDEX] v2.60 covered record collections have unique dual-axis entries and exact mirrored indexes'
  return 0
}

validate_v260_review_artifact() { # $1=manifest $2=artifact
  local manifest="$1" artifact="$2" expected_scope expected_profile version field value score score_value
  local artifact_input
  local review_id reviewed_on review_id_date reviewed_on_compact
  local repository_commit content_fingerprint current_fingerprint quality_disposition_fingerprint current_quality_fingerprint project_root review_type reviewer reviewer_role expected_task_count expected_authorises
  local bounded_section task_table task_stats task_leaf_table task_leaf_stats task_leaf_pairs
  local evidence_table evidence_stats cold_proof_table cold_proof_stats completeness_table completeness_stats
  local dimension_table dimension_stats expected_tasks expected_profile_ids h2_stats truth_table truth_stats
  local required_changes_table required_changes_stats declared_required_changes declared_verdict
  local frontmatter_stats population_table population_header population_table_shape target_table target_header target_table_shape closure_table closure_header closure_table_shape
  local population target_disposition target_owner_key expected_target_id expected_kind
  local target_id target_kind target_population disposition owner_body assigned_task decision_result result evidence_limit evidence_key
  local expected_count listed_count reconciliation source_inventory source_inventory_key expected_source_inventory population_result sep line event
  local closure_status closure_scope closure_claim closure_reviewer closure_role closure_date closure_result closure_resolves closure_authorises closure_match
  local status_line status_scope status_claim status_reviewer status_role status_date status_result status_evidence status_remaining status_authorises status_artifact
  local expected_target_total=0 actual_target_total=0 status_matches=0
  local -A expected_target=() seen_target=() expected_population_count=() actual_population_count=() seen_population=() allowed_task=()
  artifact_input="$artifact"
  case "$manifest" in
    "$PRODUCT_DIR"/*)
      expected_scope="SSOT/01-product"
      expected_profile="product"
      expected_task_count=6
      expected_authorises='area:product:covered'
      expected_tasks='product-orientation-decision,product-main-journey-acceptance,product-control-failure-recovery,product-surface-inventory,product-boundary-trust-data,product-architecture-trace'
      expected_profile_ids='C01,C02,C03,C04,C05,C06,C07,C08,C09,P01,P02,P03,P04,P05,P06,P07,P08,P09,P10,P11,P12,P13,P14,P15,P16,P17,P18,P19,P20,P21,P22,P23,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,Q21'
      ;;
    "$ARCHITECTURE_DIR"/*)
      expected_scope="SSOT/02-architecture"
      expected_profile="architecture"
      expected_task_count=6
      expected_authorises='area:architecture:covered'
      expected_tasks='architecture-orientation-request-result,architecture-owner-state-contract,architecture-failure-recovery,architecture-deployment-diagnosis,architecture-product-trace,architecture-inventory-evidence'
      expected_profile_ids='C01,C02,C03,C04,C05,C06,C07,C08,C09,A01,A02,A03,A04,A05,A06,A07,A08,A09,A10,A11,A12,A13,A14,A15,A16,A17,A18,Q01,Q02,Q03,Q04,Q05,Q06,Q07,Q08,Q09,Q10,Q11,Q12,Q13,Q14,Q15,Q16,Q17,Q18,Q19,Q20,Q21'
      ;;
    *) printf 'manifest is outside a reader area'; return 1 ;;
  esac
  # Area-level full reviews are shared by every manifest in the covered
  # reader area. Inventory truth therefore always comes from the area root,
  # never from whichever child manifest happens to point at the artifact.
  if [[ "$expected_profile" == product ]]; then
    manifest="$PRODUCT_DIR/_manifest.md"
  else
    manifest="$ARCHITECTURE_DIR/_manifest.md"
  fi
  [[ -f "$artifact_input" && ! -L "$artifact_input" && -d "$SSOT_DIR/.bootstrap" && ! -L "$SSOT_DIR/.bootstrap" ]] || { printf 'review artifact must be a regular non-symlink Markdown file under SSOT/.bootstrap'; return 1; }
  [[ "$(lexical_path "$artifact_input" 2>/dev/null || true)" == "$(realpath "$artifact_input" 2>/dev/null || true)" ]] || { printf 'review artifact path must not traverse symlinks'; return 1; }
  artifact=$(realpath "$artifact_input" 2>/dev/null || true)
  [[ -n "$artifact" && "$artifact" == "$(realpath "$SSOT_DIR/.bootstrap")/"* ]] || { printf 'review artifact must be a regular non-symlink Markdown file under SSOT/.bootstrap'; return 1; }
  ! find "$SSOT_DIR/.bootstrap" -type l -print -quit 2>/dev/null | grep -q . || { printf 'review artifact path must not traverse or contain symlinks'; return 1; }
  version=$(document_quality_status_version 2>/dev/null || true)
  frontmatter_stats=$(awk '
    BEGIN{allowed="review_id review_scope review_type reader_profile completeness_profile protocol_version reviewed_on reviewer reviewer_role repository_commit content_fingerprint quality_disposition_fingerprint sample_seed rotation_id task_count passed_task_count failed_task_count entrypoint tables_hidden bounded_read_set route_probe truth_consistency evidence_sample scored_dimensions score critical_truth_errors unresolved_required_changes authorises verdict";n=split(allowed,a," ");for(i=1;i<=n;i++)ok[a[i]]=1}
    NR==1{if($0!~/^---[[:space:]]*$/)invalid++;else front=1;next}
    front&&/^---[[:space:]]*$/{front=0;closed++;next}
    front{
      if($0~/^[[:space:]]*($|#)/)next
      if($0~/^[[:space:]]/) {invalid++;next}
      if(match($0,/^[A-Za-z_][A-Za-z0-9_-]*:/)){
        key=substr($0,1,RLENGTH-1);value=substr($0,RLENGTH+1);gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        keys++;if(!(key in ok)||seen[key]++||value==""||value~/^[{[]/||value~/^[|>][+-]?$/)invalid++;next
      }
      invalid++
    }
    END{for(k in ok)if(seen[k]!=1)invalid++;if(front||closed!=1)invalid++;printf "%d|%d|%d",closed+0,keys+0,invalid+0}
  ' "$artifact")
  [[ "$frontmatter_stats" == "1|29|0" ]] || { printf 'frontmatter must be one closed exact 29-key scalar schema (got %s)' "$frontmatter_stats"; return 1; }
  for field in review_id review_scope review_type reader_profile completeness_profile protocol_version reviewed_on reviewer reviewer_role repository_commit content_fingerprint quality_disposition_fingerprint sample_seed rotation_id task_count passed_task_count failed_task_count entrypoint tables_hidden bounded_read_set route_probe truth_consistency evidence_sample scored_dimensions score critical_truth_errors unresolved_required_changes authorises verdict; do
    [[ $(yaml_frontmatter "$artifact" | grep -Ec "^${field}:[[:space:]]*" || true) -eq 1 ]] || { printf 'frontmatter must declare exactly one %s' "$field"; return 1; }
  done
  review_id=$(review_frontmatter_value "$artifact" review_id)
  [[ "$review_id" =~ ^review:${expected_profile}:[0-9]{8}:[a-z0-9][a-z0-9-]*$ ]] || { printf 'review_id scope segment must match completeness_profile %s and use review:<scope>:<YYYYMMDD>:<slug>' "$expected_profile"; return 1; }
  [[ "$(review_frontmatter_value "$artifact" review_scope)" == "$expected_scope" ]] || { printf 'review_scope does not match %s' "$expected_scope"; return 1; }
  review_type=$(review_frontmatter_value "$artifact" review_type)
  [[ "$review_type" =~ ^(high-impact-adoption|routine)$ ]] || { printf 'review_type must be high-impact-adoption or routine'; return 1; }
  [[ "$(review_frontmatter_value "$artifact" reader_profile)" == "implementation-delegator" ]] || { printf 'reader_profile must be implementation-delegator'; return 1; }
  [[ "$(review_frontmatter_value "$artifact" completeness_profile)" == "$expected_profile" ]] || { printf 'completeness_profile must be %s for %s' "$expected_profile" "$expected_scope"; return 1; }
  [[ "$(review_frontmatter_value "$artifact" protocol_version)" == "$version" ]] || { printf 'protocol_version does not match tracked_skill_version %s' "$version"; return 1; }
  reviewed_on=$(review_frontmatter_value "$artifact" reviewed_on)
  [[ "$reviewed_on" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || { printf 'reviewed_on is not YYYY-MM-DD'; return 1; }
  review_id_date=$(printf '%s' "$review_id" | cut -d: -f3)
  reviewed_on_compact=${reviewed_on//-/}
  [[ "$review_id_date" == "$reviewed_on_compact" ]] || { printf 'review_id date %s must equal reviewed_on %s' "$review_id_date" "$reviewed_on"; return 1; }
  reviewer=$(review_frontmatter_value "$artifact" reviewer)
  [[ "$reviewer" =~ ^[A-Za-z0-9][A-Za-z0-9._:@/-]{1,127}$ ]] || { printf 'reviewer must be a stable non-placeholder ID'; return 1; }
  case "${reviewer,,}" in
    reviewer|author|agent|user|unknown|none|null|todo|tbd|placeholder|example|sample|test|n/a|na)
      printf 'reviewer must be a stable non-placeholder ID'; return 1 ;;
  esac
  reviewer_role=$(review_frontmatter_value "$artifact" reviewer_role)
  [[ "$reviewer_role" =~ ^(independent-cold-reader|scoped-self-review)$ ]] || { printf 'reviewer_role is not an allowed cold-reader role'; return 1; }
  [[ "$review_type" != "high-impact-adoption" || "$reviewer_role" == "independent-cold-reader" ]] || { printf 'high-impact-adoption requires reviewer_role independent-cold-reader'; return 1; }
  repository_commit=$(review_frontmatter_value "$artifact" repository_commit)
  [[ "$repository_commit" =~ ^[0-9a-fA-F]{7,40}$ ]] || { printf 'repository_commit must be a Git commit ID'; return 1; }
  project_root=$(cd "$(dirname "$SSOT_DIR")" && pwd -P)
  git -C "$project_root" cat-file -e "${repository_commit}^{commit}" 2>/dev/null || { printf 'repository_commit is not resolvable in the current repository'; return 1; }
  git -C "$project_root" merge-base --is-ancestor "$repository_commit" HEAD 2>/dev/null || { printf 'repository_commit is not an ancestor of current HEAD'; return 1; }
  content_fingerprint=$(review_frontmatter_value "$artifact" content_fingerprint)
  [[ "$content_fingerprint" =~ ^[0-9a-f]{64}$ ]] || { printf 'content_fingerprint must be a lowercase SHA-256 digest'; return 1; }
  current_fingerprint=$(current_review_content_fingerprint 2>/dev/null || true)
  [[ -n "$current_fingerprint" && "$content_fingerprint" == "$current_fingerprint" ]] || { printf 'content_fingerprint does not match the current shared reader surface (SSOT/README.md plus product and architecture Markdown)'; return 1; }
  quality_disposition_fingerprint=$(review_frontmatter_value "$artifact" quality_disposition_fingerprint)
  [[ "$quality_disposition_fingerprint" =~ ^[0-9a-f]{64}$ ]] || { printf 'quality_disposition_fingerprint must be a lowercase SHA-256 digest'; return 1; }
  current_quality_fingerprint=$(current_quality_disposition_fingerprint 2>/dev/null || true)
  [[ -n "$current_quality_fingerprint" && "$quality_disposition_fingerprint" == "$current_quality_fingerprint" ]] || { printf 'quality_disposition_fingerprint does not match the normalized STATUS Q01-Q21 disposition register'; return 1; }
  [[ "$(review_frontmatter_value "$artifact" sample_seed)" =~ ^[A-Za-z0-9][A-Za-z0-9._:-]{3,127}$ ]] || { printf 'sample_seed must be a stable non-placeholder token'; return 1; }
  [[ "$(review_frontmatter_value "$artifact" rotation_id)" =~ ^[A-Za-z0-9][A-Za-z0-9._:-]{3,127}$ ]] || { printf 'rotation_id must be a stable non-placeholder token'; return 1; }
  [[ "$(review_frontmatter_value "$artifact" task_count)" == "$expected_task_count" ]] || { printf 'task_count must be %s for %s' "$expected_task_count" "$expected_scope"; return 1; }
  [[ "$(review_frontmatter_value "$artifact" passed_task_count)" == "$expected_task_count" ]] || { printf 'passed_task_count must equal task_count for a passing review'; return 1; }
  [[ "$(review_frontmatter_value "$artifact" failed_task_count)" == "0" ]] || { printf 'failed_task_count must be 0 for a passing review'; return 1; }
  [[ "$(review_frontmatter_value "$artifact" entrypoint)" == "SSOT/README.md" ]] || { printf 'entrypoint must be SSOT/README.md'; return 1; }
  for field in tables_hidden bounded_read_set; do
    [[ "$(review_frontmatter_value "$artifact" "$field")" == "true" ]] || { printf '%s must be true' "$field"; return 1; }
  done
  for field in route_probe truth_consistency evidence_sample; do
    [[ "$(review_frontmatter_value "$artifact" "$field")" == "passed" ]] || { printf '%s must be passed' "$field"; return 1; }
  done
  [[ "$(review_frontmatter_value "$artifact" scored_dimensions)" == "16" ]] || { printf 'scored_dimensions must be 16'; return 1; }
  score=$(review_frontmatter_value "$artifact" score)
  [[ "$score" =~ ^([0-9]{1,2})/32$ ]] || { printf 'score must use N/32'; return 1; }
  score_value=${BASH_REMATCH[1]}
  (( score_value >= 29 && score_value <= 32 )) || { printf 'score must be at least 29/32'; return 1; }
  [[ "$(review_frontmatter_value "$artifact" critical_truth_errors)" == "0" ]] || { printf 'critical_truth_errors must be 0'; return 1; }
  declared_required_changes=$(review_frontmatter_value "$artifact" unresolved_required_changes)
  [[ "$declared_required_changes" == "0" ]] || { printf 'unresolved_required_changes must be 0'; return 1; }
  [[ "$(review_frontmatter_value "$artifact" authorises)" == "$expected_authorises" ]] || { printf 'authorises must be %s for %s' "$expected_authorises" "$expected_scope"; return 1; }
  declared_verdict=$(review_frontmatter_value "$artifact" verdict)
  [[ "$declared_verdict" == "no-more-required-changes" ]] || { printf 'verdict must be no-more-required-changes'; return 1; }
  h2_stats=$(awk '
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); return v }
    function key(title, lower) {
      lower=tolower(title)
      if (lower == "bounded reading set" || title == "有界阅读集") return "bounded"
      if (lower == "teach-back" || title == "复述") return "teachback"
      if (lower == "consistency and evidence sample" || title == "一致性与证据抽样") return "evidence"
      if (lower == "dimension scores" || title == "维度评分") return "scores"
      if (lower == "completeness profile" || title == "完整性画像") return "profile"
      if (lower == "required changes and verdict" || title == "必改项与结论") return "changes"
      return ""
    }
    /^##[[:space:]]+/ {
      title=$0; sub(/^##[[:space:]]+/, "", title); title=trim(title); rows++
      canonical=key(title)
      if (canonical == "" || seen[canonical]++) invalid++
    }
    END {
      required["bounded"]=required["teachback"]=required["evidence"]=1
      required["scores"]=required["profile"]=required["changes"]=1
      for (canonical in required) if (seen[canonical] != 1) invalid++
      printf "%d|%d", rows + 0, invalid + 0
    }
  ' "$artifact")
  [[ "$h2_stats" == "6|0" ]] || { printf 'body H2 headings must be exactly the six protocol sections, each once and with no extra H2 (got %s)' "$h2_stats"; return 1; }
  if grep -qE '<[^>]+>|(^|[^[:alnum:]_])(TODO|TBD)([^[:alnum:]_]|$)|REVIEW-<n>|待补充' "$artifact"; then
    printf 'body still contains template placeholders or author handoff text'
    return 1
  fi
  bounded_section=$(awk '
    /^##[[:space:]]+(Bounded reading set|有界阅读集)[[:space:]]*$/ { active=1; next }
    active && /^##[[:space:]]/ { exit }
    active { print }
  ' "$artifact")
  [[ $(printf '%s\n' "$bounded_section" | grep -cE '^\|[^|]+\|[^|]+\|[^|]+\|[^|]+\|' || true) -ge 4 ]] || { printf 'bounded reading set needs at least two completed route rows'; return 1; }
  printf '%s\n' "$bounded_section" | grep -qF 'SSOT/README.md' || { printf 'bounded reading set does not start from SSOT/README.md'; return 1; }
  task_table=$(review_task_matrix "$artifact")
  [[ -n "$task_table" ]] || { printf 'body is missing the scope-specific mandatory task matrix'; return 1; }
  task_stats=$(printf '%s\n' "$task_table" | awk -F'|' -v expected="$expected_tasks" '
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/[`*]/, "", v); return v }
    BEGIN { count=split(expected, required_list, ","); for (i=1; i<=count; i++) required[required_list[i]]=1 }
    NR <= 2 { next }
    /^\|/ {
      class=trim($2); reader=trim($3); delegated=trim($4); visible=trim($5); stop=trim($6)
      entry=trim($7); files=trim($8); hops=trim($9); outcome=trim($10)
      hidden=tolower(trim($11)); evidence=trim($12); verdict=tolower(trim($13)); rows++
      if (!(class in required) || seen[class]++) invalid++
      if (length(reader) < 12) invalid++
      if (length(delegated) < 12 || length(visible) < 12 || length(stop) < 12) invalid++
      if (entry != "SSOT/README.md") invalid++
      if (length(files) < 8 || files !~ /SSOT\// || files !~ /\.md/) invalid++
      if (hops !~ /^[0-9]+$/ || (hops + 0) > 4) invalid++
      if (length(outcome) < 12 || hidden != "pass" || length(evidence) < 12) invalid++
      if (verdict != "pass") invalid++
    }
    END {
      for (class in required) if (seen[class] != 1) invalid++
      printf "%d|%d", rows + 0, invalid + 0
    }
  ')
  [[ "$task_stats" == "${expected_task_count}|0" ]] || { printf 'task matrix must contain each mandatory %s class exactly once with a delegated action, expected visible result, stop/escalation boundary, complete passing evidence, and actual_hops <= 4 (got %s)' "$expected_scope" "$task_stats"; return 1; }
  while IFS= read -r evidence; do
    [[ -n "$(strict_ssot_markdown_target_key "$artifact" "$evidence" 2>/dev/null || true)" ]] || { printf 'task matrix Evidence and limit must use one resolving non-review consumer-SSOT Markdown link: %s' "$evidence"; return 1; }
  done < <(printf '%s\n' "$task_table" | awk -F'|' 'NR>2&&/^\|/{v=$12;gsub(/^[[:space:]]+|[[:space:]]+$/,"",v);print v}')

  # A passing full review is an exhaustive reconciliation, not a sampled
  # narrative. Freeze the real owner/inventory population and require the
  # artifact to account for each member once under the exact H3 contract.
  [[ "$(review_exact_subheading_count "$artifact" 'Finite owner and target coverage' '有限所有者与目标覆盖')" == 1 ]] || { printf 'body needs exactly one ### Finite owner and target coverage section'; return 1; }
  population_table=$(review_frozen_population_table "$artifact")
  [[ -n "$population_table" ]] || { printf 'Finite owner and target coverage is missing the frozen-population reconciliation table'; return 1; }
  population_header=$(printf '%s\n' "$population_table" | head -1 | review_table_header_signature)
  [[ "$population_header" == 'frozen population|source inventory|expected targets|listed targets|reconciliation result' || "$population_header" == '冻结清单类别|来源清单|应有目标数|已列目标数|对账结果' ]] || { printf 'frozen-population reconciliation needs the exact five columns'; return 1; }
  population_table_shape=$(printf '%s\n' "$population_table" | awk -F'|' 'NR>2&&/^\|/{rows++;if(NF!=7)invalid++}END{printf "%d|%d",rows+0,invalid+0}')
  [[ "${population_table_shape##*|}" == 0 ]] || { printf 'frozen-population reconciliation rows need the exact five columns'; return 1; }
  target_table=$(review_full_target_table "$artifact")
  [[ -n "$target_table" ]] || { printf 'Finite owner and target coverage is missing the target table'; return 1; }
  target_header=$(printf '%s\n' "$target_table" | head -1 | review_table_header_signature)
  [[ "$target_header" == 'target id|target kind|frozen disposition|owner/body|assigned mandatory task|decision, delegated action, and visible result|result|evidence and limit' || "$target_header" == '目标 id|目标类别|冻结处置|所有者正文|分配到的必做任务|决定、委托动作与可见结果|结果|证据与限制' ]] || { printf 'target coverage needs the exact eight columns'; return 1; }
  target_table_shape=$(printf '%s\n' "$target_table" | awk -F'|' 'NR>2&&/^\|/{rows++;if(NF!=10)invalid++}END{printf "%d|%d",rows+0,invalid+0}')
  [[ "${target_table_shape##*|}" == 0 ]] || { printf 'target coverage rows need the exact eight columns'; return 1; }
  for field in ${expected_tasks//,/ }; do allowed_task[$field]=1; done
  sep=$(printf '\034')
  while IFS="$sep" read -r population expected_target_id target_disposition target_owner_key; do
    [[ -n "$population" && -n "$expected_target_id" && -n "$target_owner_key" ]] || { printf 'real %s inventory contains an unresolved target owner' "$expected_profile"; return 1; }
    [[ -z "${expected_target[$expected_target_id]:-}" ]] || { printf 'real inventory contains duplicate canonical Target ID %s' "$expected_target_id"; return 1; }
    expected_target[$expected_target_id]="$population${sep}$target_disposition${sep}$target_owner_key"
    expected_population_count[$population]=$(( ${expected_population_count[$population]:-0} + 1 ))
    expected_target_total=$((expected_target_total + 1))
  done < <(full_review_expected_targets "$expected_profile" "$manifest")

  while IFS='|' read -r _ population source_inventory expected_count listed_count population_result _; do
    population=$(trim_table_cell "$population"); source_inventory=$(trim_table_cell "$source_inventory")
    expected_count=$(trim_table_cell "$expected_count"); listed_count=$(trim_table_cell "$listed_count")
    population_result=$(trim_table_cell "$population_result"); population_result="${population_result,,}"
    [[ "$population" != "Frozen population" && "$population" != "冻结清单类别" && ! "$population" =~ ^[-:[:space:]]+$ ]] || continue
    [[ "$population" =~ ^(product-reader-owner|product-surface|product-bridge|architecture-reader-owner|architecture-direct-owner|architecture-view|technical-surface|architecture-bridge)$ ]] || { printf 'frozen population reconciliation contains invalid population %s' "$population"; return 1; }
    [[ -z "${seen_population[$population]:-}" ]] || { printf 'frozen population reconciliation repeats %s' "$population"; return 1; }
    seen_population[$population]=1
    source_inventory_key=$(strict_ssot_markdown_target_key "$artifact" "$source_inventory" 2>/dev/null || true)
    expected_source_inventory=$(full_review_population_source_file "$expected_profile" "$population" 2>/dev/null || true)
    [[ "$(manifest_markdown_link_count "$source_inventory")" -eq 1 && -n "$source_inventory_key" && -n "$expected_source_inventory" && "${source_inventory_key%%#*}" == "$expected_source_inventory" ]] || { printf 'frozen population %s must link its real source inventory' "$population"; return 1; }
    [[ "$expected_count" =~ ^[0-9]+$ && "$listed_count" =~ ^[0-9]+$ && "$population_result" == pass ]] || { printf 'frozen population reconciliation for %s needs integer counts and pass' "$population"; return 1; }
    [[ "$expected_count" == "${expected_population_count[$population]:-0}" ]] || { printf 'frozen population reconciliation count does not match the real inventory for %s' "$population"; return 1; }
  done <<< "$(printf '%s\n' "$population_table" | tail -n +3)"
  if [[ "$expected_profile" == product ]]; then
    for population in product-reader-owner product-surface product-bridge; do [[ -n "${seen_population[$population]:-}" ]] || { printf 'frozen population reconciliation omits %s' "$population"; return 1; }; done
    [[ "${#seen_population[@]}" -eq 3 ]] || { printf 'product review needs exactly three frozen-population reconciliation rows'; return 1; }
  else
    for population in architecture-reader-owner architecture-direct-owner architecture-view technical-surface architecture-bridge; do [[ -n "${seen_population[$population]:-}" ]] || { printf 'frozen population reconciliation omits %s' "$population"; return 1; }; done
    [[ "${#seen_population[@]}" -eq 5 ]] || { printf 'architecture review needs exactly five frozen-population reconciliation rows'; return 1; }
  fi

  while IFS='|' read -r _ target_id target_kind disposition owner_body assigned_task decision_result result evidence_limit _; do
    target_id=$(trim_table_cell "$target_id"); target_kind=$(trim_table_cell "$target_kind")
    disposition=$(trim_table_cell "$disposition"); owner_body=$(trim_table_cell "$owner_body")
    assigned_task=$(trim_table_cell "$assigned_task"); assigned_task="${assigned_task//\`/}"
    decision_result=$(trim_table_cell "$decision_result"); result=$(trim_table_cell "$result"); result="${result,,}"
    evidence_limit=$(trim_table_cell "$evidence_limit")
    [[ "$target_id" != "Target ID" && "$target_id" != "目标 ID" && ! "$target_id" =~ ^[-:[:space:]]+$ ]] || continue
    case "$target_id" in
      owner:*) [[ "${target_id#owner:}" =~ ^[^\|[:space:]]+$ ]] || { printf 'target coverage has invalid or duplicate stable Target ID %s' "$target_id"; return 1; } ;;
      surface:*) [[ "$target_id" =~ ^surface:[a-z0-9][a-z0-9-]*$ ]] || { printf 'target coverage has invalid or duplicate stable Target ID %s' "$target_id"; return 1; } ;;
      tech:*) [[ "$target_id" =~ ^tech:[a-z0-9][a-z0-9-]*$ ]] || { printf 'target coverage has invalid or duplicate stable Target ID %s' "$target_id"; return 1; } ;;
      view:*) [[ "${target_id#view:}" =~ ^[^\|[:space:]]+$ ]] || { printf 'target coverage has invalid or duplicate stable Target ID %s' "$target_id"; return 1; } ;;
      bridge:surface:*) [[ "$target_id" =~ ^bridge:surface:[a-z0-9][a-z0-9-]*$ ]] || { printf 'target coverage has invalid or duplicate stable Target ID %s' "$target_id"; return 1; } ;;
      *) printf 'target coverage has invalid or duplicate stable Target ID %s' "$target_id"; return 1 ;;
    esac
    [[ -z "${seen_target[$target_id]:-}" ]] || { printf 'target coverage has invalid or duplicate stable Target ID %s' "$target_id"; return 1; }
    [[ -n "${expected_target[$target_id]:-}" ]] || { printf 'target coverage contains a target absent from the real %s inventory: %s' "$expected_profile" "$target_id"; return 1; }
    seen_target[$target_id]=1
    IFS="$sep" read -r target_population target_disposition target_owner_key <<< "${expected_target[$target_id]}"
    case "$target_population" in
      product-reader-owner|architecture-reader-owner|architecture-direct-owner) expected_kind=reader-owner ;;
      product-surface) expected_kind='product-surface' ;;
      architecture-view) expected_kind=cross-owner-view ;;
      technical-surface) expected_kind=technical-surface ;;
      product-bridge|architecture-bridge) expected_kind=bridge ;;
      *) printf 'real inventory contains unknown frozen population %s' "$target_population"; return 1 ;;
    esac
    [[ "$target_kind" == "$expected_kind" ]] || { printf 'target coverage has invalid Target kind %s for %s' "$target_kind" "$target_population"; return 1; }
    [[ "$disposition" == "$target_disposition" ]] || { printf 'target %s frozen disposition does not match the real inventory' "$target_id"; return 1; }
    evidence_key=$(strict_ssot_markdown_target_key "$artifact" "$owner_body" 2>/dev/null || true)
    [[ -n "$evidence_key" && "$evidence_key" == "$target_owner_key" ]] || { printf 'target %s owner/body does not match its real inventory owner' "$target_id"; return 1; }
    [[ -n "${allowed_task[$assigned_task]:-}" ]] || { printf 'assigned mandatory task is outside the %s review scope: %s' "$expected_profile" "$assigned_task"; return 1; }
    [[ ${#decision_result} -ge 24 && "$result" == pass ]] || { printf 'target %s needs a complete decision, delegated action, visible result, and pass result' "$target_id"; return 1; }
    [[ "$(manifest_markdown_link_count "$evidence_limit")" -eq 1 && ${#evidence_limit} -ge 24 ]] && strict_ssot_markdown_target_key "$artifact" "$evidence_limit" >/dev/null 2>&1 || { printf 'target %s needs one resolving evidence link and a real limit' "$target_id"; return 1; }
    actual_population_count[$target_population]=$(( ${actual_population_count[$target_population]:-0} + 1 ))
    actual_target_total=$((actual_target_total + 1))
  done <<< "$(printf '%s\n' "$target_table" | tail -n +3)"
  [[ "$actual_target_total" -eq "$expected_target_total" ]] || { printf 'target coverage must contain every real target exactly once (%s/%s)' "$actual_target_total" "$expected_target_total"; return 1; }
  for expected_target_id in "${!expected_target[@]}"; do [[ -n "${seen_target[$expected_target_id]:-}" ]] || { printf 'target coverage must contain every real target exactly once (missing %s)' "$expected_target_id"; return 1; }; done
  for population in "${!seen_population[@]}"; do
    listed_count=$(printf '%s\n' "$population_table" | awk -F'|' -v wanted="$population" 'function trim(v){gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", v);return v}NR>2&&/^\|/&&trim($2)==wanted{print trim($5);exit}')
    [[ "$listed_count" == "${actual_population_count[$population]:-0}" ]] || { printf 'frozen population reconciliation listed count does not match the target table for %s' "$population"; return 1; }
  done

  [[ "$(review_exact_subheading_count "$artifact" 'STATUS covered-claim closure' 'STATUS 覆盖结论闭环')" == 1 ]] || { printf 'body needs exactly one ### STATUS covered-claim closure section'; return 1; }
  closure_table=$(review_status_closure_table "$artifact")
  [[ -n "$closure_table" ]] || { printf 'STATUS covered-claim closure must contain exactly one current row'; return 1; }
  closure_header=$(printf '%s\n' "$closure_table" | head -1 | review_table_header_signature)
  [[ "$closure_header" == 'status row|scope|stop claim|reviewer|reviewer role|reviewed date|result|status evidence resolves to this artifact|authorises|match' || "$closure_header" == 'status 行|范围|停止结论|评审者|评审者角色|评审日期|结果|status 证据解析到本产物|authorises|匹配结果' ]] || { printf 'STATUS covered-claim closure needs the exact ten columns'; return 1; }
  closure_table_shape=$(printf '%s\n' "$closure_table" | awk -F'|' 'NR>2&&/^\|/{rows++;if(NF!=12)invalid++}END{printf "%d|%d",rows+0,invalid+0}')
  [[ "$closure_table_shape" == '1|0' ]] || { printf 'STATUS covered-claim closure must contain exactly one current row'; return 1; }
  IFS='|' read -r _ closure_status closure_scope closure_claim closure_reviewer closure_role closure_date closure_result closure_resolves closure_authorises closure_match _ <<< "$(printf '%s\n' "$closure_table" | sed -n '3p')"
  closure_status=$(trim_table_cell "$closure_status")
  closure_scope=$(trim_table_cell "$closure_scope"); closure_claim=$(trim_table_cell "$closure_claim")
  closure_reviewer=$(trim_table_cell "$closure_reviewer"); closure_role=$(trim_table_cell "$closure_role")
  closure_date=$(trim_table_cell "$closure_date"); closure_result=$(trim_table_cell "$closure_result")
  closure_resolves=$(trim_table_cell "$closure_resolves"); closure_authorises=$(trim_table_cell "$closure_authorises")
  closure_match=$(trim_table_cell "$closure_match")
  if [[ "$(manifest_markdown_link_count "$closure_status")" -ne 1 ]] || ! markdown_link_resolves_with_anchor "$artifact" "$closure_status"; then
    printf 'STATUS covered-claim closure row must link the current Stop Review Gate anchor'
    return 1
  fi
  if [[ ! "$(markdown_link_fragment "$closure_status")" =~ ^(stop-review-gate|停止审查闸门)$ ]]; then
    printf 'STATUS covered-claim closure row must link the current Stop Review Gate anchor'
    return 1
  fi
  status_artifact=$(manifest_markdown_link_resolved_path "$artifact" "$closure_status" 2>/dev/null || true)
  [[ "$status_artifact" == "$(realpath "$SSOT_DIR/STATUS.md" 2>/dev/null || true)" ]] || { printf 'STATUS covered-claim closure row does not resolve to STATUS.md'; return 1; }
  while IFS="$sep" read -r event line status_scope status_claim status_reviewer status_role status_date status_result status_evidence status_remaining status_authorises; do
    [[ "$event" == ROW && "$status_scope" == "$expected_profile" && "$status_claim" == covered && "$status_authorises" == "$expected_authorises" ]] || continue
    status_matches=$((status_matches + 1)); status_line=$line
    status_artifact=$(manifest_markdown_link_resolved_path "$SSOT_DIR/STATUS.md" "$status_evidence" 2>/dev/null || true)
  done <<< "$(status_stop_review_rows)"
  [[ "$status_matches" -eq 1 ]] || { printf 'STATUS covered-claim closure needs exactly one matching current Stop Review Gate row'; return 1; }
  IFS="$sep" read -r event status_line status_scope status_claim status_reviewer status_role status_date status_result status_evidence status_remaining status_authorises <<< "$(status_stop_review_rows | awk -F "$sep" -v scope="$expected_profile" -v auth="$expected_authorises" '$1=="ROW"&&$3==scope&&$4=="covered"&&$11==auth{print;exit}')"
  status_artifact=$(manifest_markdown_link_resolved_path "$SSOT_DIR/STATUS.md" "$status_evidence" 2>/dev/null || true)
  [[ "$closure_scope" == "$expected_profile" && "$closure_claim" == covered && "$closure_reviewer" == "$reviewer" && "$closure_role" == "$reviewer_role" && "$closure_date" == "$reviewed_on" && "$closure_result" == "$declared_verdict" && "${closure_resolves,,}" == yes && "$closure_authorises" == "$expected_authorises" && "${closure_match,,}" == pass && "$status_reviewer" == "$reviewer" && "$status_role" == "$reviewer_role" && "${status_date:0:10}" == "$reviewed_on" && "$status_result" == "$declared_verdict" && "$status_authorises" == "$expected_authorises" && "$status_artifact" == "$(realpath "$artifact")" ]] || { printf 'STATUS covered-claim closure disagrees with the review artifact or Stop Review Gate'; return 1; }

  truth_table=$(review_truth_consistency_table "$artifact")
  [[ -n "$truth_table" ]] || { printf 'body is missing the cross-owner truth consistency table'; return 1; }
  truth_stats=$(printf '%s\n' "$truth_table" | awk -F'|' '
    function trim(v){gsub(/^[[:space:]]+|[[:space:]]+$/,"",v);return v}
    NR<=2{next}/^\|/{claim=trim($2);owner=trim($3);compared=trim($4);result=tolower(trim($5));note=trim($6);rows++;if(length(claim)<8||length(owner)<8||length(compared)<8||result!="pass"||length(note)<8)invalid++}
    END{printf "%d|%d",rows+0,invalid+0}
  ')
  [[ "$truth_stats" =~ ^[1-9][0-9]*\|0$ ]] || { printf 'truth consistency needs one or more complete passing comparisons (got %s)' "$truth_stats"; return 1; }
  while IFS=$'\034' read -r owner compared; do
    [[ -n "$(strict_ssot_markdown_target_key "$artifact" "$owner" 2>/dev/null || true)" && -n "$(strict_ssot_markdown_target_key "$artifact" "$compared" 2>/dev/null || true)" ]] || { printf 'truth consistency owner and compared owner must each use one resolving non-review consumer-SSOT Markdown link'; return 1; }
  done < <(printf '%s\n' "$truth_table" | awk -F'|' 'BEGIN{s=sprintf("%c",28)}NR>2&&/^\|/{a=$3;b=$4;gsub(/^[[:space:]]+|[[:space:]]+$/,"",a);gsub(/^[[:space:]]+|[[:space:]]+$/,"",b);print a s b}')

  task_leaf_table=$(review_task_leaf_map "$artifact")
  [[ -n "$task_leaf_table" ]] || { printf 'body is missing the task-to-leaf applicability table'; return 1; }
  task_leaf_stats=$(printf '%s\n' "$task_leaf_table" | awk -F'|' -v expected="$expected_tasks" '
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/[`*[:space:]]/, "", v); return v }
    BEGIN {
      count=split(expected, required_list, ","); for (i=1; i<=count; i++) required[required_list[i]]=1
      canonical="RF1,RF2,LA1,LA2,LA3,CT1,CT2,CT3,CT4,BC1,BC2,BC3,BC4,RP1,RP2,RP3"
      leaf_count=split(canonical, leaf_list, ","); for (i=1; i<=leaf_count; i++) allowed[leaf_list[i]]=1
    }
    NR <= 2 { next }
    /^\|/ {
      class=trim($2); ids=trim($3); reason=$4; gsub(/^[[:space:]]+|[[:space:]]+$/, "", reason); rows++
      if (!(class in required) || seen_task[class]++ || length(reason) < 12) invalid++
      n=split(ids, parts, ","); if (n < 1) invalid++
      delete local_seen
      for (i=1; i<=n; i++) {
        leaf=parts[i]
        if (!(leaf in allowed) || local_seen[leaf]++) invalid++
        else { seen_leaf[leaf]++; pairs=pairs class "=" leaf ";" }
      }
    }
    END {
      for (class in required) if (seen_task[class] != 1) invalid++
      for (leaf in allowed) if (seen_leaf[leaf] < 1) invalid++
      printf "%d|%d|%s", rows + 0, invalid + 0, pairs
    }
  ')
  task_leaf_pairs=${task_leaf_stats#*|*|}
  [[ "${task_leaf_stats%%|*}|$(printf '%s' "$task_leaf_stats" | cut -d'|' -f2)" == "${expected_task_count}|0" ]] || { printf 'task-to-leaf applicability must map every canonical leaf to one or more exact mandatory tasks (got %s)' "$task_leaf_stats"; return 1; }

  evidence_table=$(review_evidence_sample_table "$artifact")
  [[ -n "$evidence_table" ]] || { printf 'body is missing the per-task evidence sample'; return 1; }
  evidence_stats=$(printf '%s\n' "$evidence_table" | awk -F'|' -v expected="$expected_tasks" '
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/[`*]/, "", v); return v }
    BEGIN { count=split(expected, list, ","); for (i=1; i<=count; i++) required[list[i]]=1 }
    NR <= 2 { next }
    /^\|/ {
      class=trim($2); claim=trim($3); evidence=trim($4); fitness=trim($5); result=tolower(trim($6)); limit=trim($7); rows++
      if (!(class in required) || seen[class]++ || length(claim) < 12 || length(evidence) < 8 || length(fitness) < 12 || result != "pass" || length(limit) < 8) invalid++
    }
    END { for (class in required) if (seen[class] != 1) invalid++; printf "%d|%d", rows + 0, invalid + 0 }
  ')
  [[ "$evidence_stats" == "${expected_task_count}|0" ]] || { printf 'evidence sample must contain one complete passing row per mandatory task (got %s)' "$evidence_stats"; return 1; }
  while IFS= read -r evidence; do
    [[ -n "$(strict_ssot_markdown_target_key "$artifact" "$evidence" 2>/dev/null || true)" ]] || { printf 'evidence sample must use one resolving non-review consumer-SSOT Markdown link: %s' "$evidence"; return 1; }
  done < <(printf '%s\n' "$evidence_table" | awk -F'|' 'NR>2&&/^\|/{v=$4;gsub(/^[[:space:]]+|[[:space:]]+$/,"",v);print v}')

  cold_proof_table=$(review_cold_proof_table "$artifact")
  [[ -n "$cold_proof_table" ]] || { printf 'body is missing the cold proof gates'; return 1; }
  cold_proof_stats=$(printf '%s\n' "$cold_proof_table" | awk -F'|' '
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/[`*]/, "", v); return v }
    BEGIN { required["CP-D"]=1; required["CP-R"]=1; required["CP-T"]=1; required["CP-E"]=1; required["CP-C"]=1 }
    NR <= 2 { next }
    /^\|/ { id=trim($2); evidence=trim($3); result=tolower(trim($4)); limit=trim($5); rows++; if (!(id in required) || seen[id]++ || length(evidence) < 12 || result != "pass" || length(limit) < 8) invalid++ }
    END { for (id in required) if (seen[id] != 1) invalid++; printf "%d|%d", rows + 0, invalid + 0 }
  ')
  [[ "$cold_proof_stats" == "5|0" ]] || { printf 'cold proof must pass CP-D, CP-R, CP-T, CP-E, and CP-C exactly once (got %s)' "$cold_proof_stats"; return 1; }

  completeness_table=$(review_completeness_table "$artifact")
  [[ -n "$completeness_table" ]] || { printf 'body is missing the completeness profile table'; return 1; }
  completeness_stats=$(printf '%s\n' "$completeness_table" | awk -F'|' -v expected="$expected_profile_ids" '
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/[`*]/, "", v); return v }
    BEGIN { count=split(expected, list, ","); for (i=1; i<=count; i++) required[list[i]]=1 }
    NR <= 2 { next }
    /^\|/ {
      id=trim($2); disposition=tolower(trim($3)); reason=trim($4); rows++
      if (!(id in required) || seen[id]++ || disposition !~ /^(covered|not_applicable)$/ || length(reason) < 12) invalid++
      if (reason !~ /(\.md|owner:|surface:|tech:|evidence:|runtime:|route:)/) invalid++
    }
    END { for (id in required) if (seen[id] != 1) invalid++; printf "%d|%d", rows + 0, invalid + 0 }
  ')
  [[ "$completeness_stats" == "$(printf '%s' "$expected_profile_ids" | awk -F',' '{print NF}')|0" ]] || { printf 'completeness profile must dispose every exact common and %s item with reason and evidence (got %s)' "$expected_profile" "$completeness_stats"; return 1; }
  while IFS= read -r reason; do
    [[ -n "$(strict_ssot_markdown_target_key "$artifact" "$reason" 2>/dev/null || true)" ]] || { printf 'completeness profile must use one resolving non-review consumer-SSOT Markdown evidence link: %s' "$reason"; return 1; }
  done < <(printf '%s\n' "$completeness_table" | awk -F'|' 'NR>2&&/^\|/{v=$4;gsub(/^[[:space:]]+|[[:space:]]+$/,"",v);print v}')

  required_changes_table=$(review_required_changes_table "$artifact")
  [[ -n "$required_changes_table" ]] || { printf 'body is missing the deterministic required-changes table'; return 1; }
  required_changes_stats=$(printf '%s\n' "$required_changes_table" | awk -F'|' '
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/[`*]/, "", v); return v }
    NR <= 2 { next }
    /^\|/ {
      id=trim($2); status=tolower(trim($3)); change=trim($4); owner=trim($5); evidence=trim($6); rows++
      if (tolower(id) == "none" || id == "无") {
        sentinel++
        if (status != "none" || length(change) < 8 || length(evidence) < 8) invalid++
        next
      }
      if (id !~ /^RC-[0-9][0-9]+$/ || seen[id]++) invalid++
      if (status !~ /^(resolved|pending|required|open)$/) invalid++
      if (length(change) < 8 || length(owner) < 2 || length(evidence) < 8) invalid++
      if (status ~ /^(pending|required|open)$/) unresolved++
    }
    END {
      if (rows < 1) invalid++
      if (sentinel > 0 && (sentinel != 1 || rows != 1)) invalid++
      printf "%d|%d|%d", rows + 0, invalid + 0, unresolved + 0
    }
  ')
  [[ "$(printf '%s' "$required_changes_stats" | cut -d'|' -f2)" == "0" ]] || { printf 'required-changes table must use unique RC-NN rows or one none sentinel with complete owner/closure data (got %s)' "$required_changes_stats"; return 1; }
  [[ "$(printf '%s' "$required_changes_stats" | cut -d'|' -f3)" == "$declared_required_changes" ]] || { printf 'required-changes table unresolved rows must equal unresolved_required_changes (got %s, declared %s)' "$(printf '%s' "$required_changes_stats" | cut -d'|' -f3)" "$declared_required_changes"; return 1; }
  if [[ "$declared_verdict" == "no-more-required-changes" && "$(printf '%s' "$required_changes_stats" | cut -d'|' -f3)" != "0" ]]; then
    printf 'pending, required, or open change rows contradict verdict no-more-required-changes'
    return 1
  fi
  while IFS=$'\034' read -r id owner closure; do
    [[ -n "$id" && "${id,,}" != none && "$id" != 无 ]] || continue
    [[ -n "$(strict_ssot_markdown_target_key "$artifact" "$owner" 2>/dev/null || true)" && -n "$(strict_ssot_markdown_target_key "$artifact" "$closure" 2>/dev/null || true)" ]] || { printf 'real required-change rows must use resolving non-review consumer-SSOT owner and closure links'; return 1; }
  done < <(printf '%s\n' "$required_changes_table" | awk -F'|' 'BEGIN{s=sprintf("%c",28)}NR>2&&/^\|/{id=$2;o=$5;c=$6;gsub(/^[[:space:]]+|[[:space:]]+$/,"",id);gsub(/^[[:space:]]+|[[:space:]]+$/,"",o);gsub(/^[[:space:]]+|[[:space:]]+$/,"",c);print id s o s c}')

  dimension_table=$(review_dimension_table "$artifact")
  [[ -n "$dimension_table" ]] || { printf 'body is missing the sixteen-leaf dimension table'; return 1; }
  dimension_stats=$(printf '%s\n' "$dimension_table" | awk -F'|' -v task_map="$task_leaf_pairs" '
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/[*`]/, "", v); return v }
    function add(id, family, en, zh) { expected_family[id]=family; expected_en[id]=en; expected_zh[id]=zh }
    BEGIN {
      add("RF1", "RF", "Reader, decision, and action fit", "读者、决策与行动适配")
      add("RF2", "RF", "Orientation and visible outcome", "定位与可见结果")
      add("LA1", "LA", "First-use terminology", "首次使用术语")
      add("LA2", "LA", "Plain-language cognitive load", "白话认知负担")
      add("LA3", "LA", "Concrete grounding", "具体场景落地")
      add("CT1", "CT", "Causal chain", "因果链")
      add("CT2", "CT", "Current truth and cross-owner consistency", "当前事实与跨所有者一致性")
      add("CT3", "CT", "Posture, uncertainty, and change", "姿态、不确定性与变化")
      add("CT4", "CT", "Success, failure, and recovery", "成功、失败与恢复")
      add("BC1", "BC", "Boundaries and non-goals", "边界与非目标")
      add("BC2", "BC", "Unique owner and handoff reachability", "唯一所有者与交接可达性")
      add("BC3", "BC", "Evidence fitness, fidelity, freshness, and invalidation", "证据适配度、保真度、新鲜度与失效")
      add("BC4", "BC", "Scope completeness", "范围完整性")
      add("RP1", "RP", "Scannability and progressive disclosure", "可扫描性与渐进披露")
      add("RP2", "RP", "Bounded route and locality", "有界路由与局部性")
      add("RP3", "RP", "Table-independent narrative", "脱离表格的叙事")
      family_en["RF"]="Reader fit"; family_zh["RF"]="读者适配"
      family_en["LA"]="Plain-language clarity"; family_zh["LA"]="平实清晰与易懂性"
      family_en["CT"]="Causal and truth story"; family_zh["CT"]="因果与事实叙事"
      family_en["BC"]="Boundary and coverage"; family_zh["BC"]="边界与覆盖"
      family_en["RP"]="Reading path"; family_zh["RP"]="阅读路径"
      n=split(task_map, pairs, ";")
      for (i=1; i<=n; i++) if (pairs[i] != "") { split(pairs[i], p, "="); applicable[p[2], p[1]]=1 }
    }
    NR <= 2 { next }
    /^\|/ {
      family_label=trim($2); id=trim($3); label=trim($4); task_scores=trim($5); value=trim($6); reason=trim($7)
      if (tolower(family_label) == "total" || family_label == "总分") next
      rows++
      family=expected_family[id]
      if (family == "" || seen[id]++ || (label != expected_en[id] && label != expected_zh[id]) || (family_label != family_en[family] && family_label != family_zh[family])) invalid++
      if (value !~ /^[012]$/ || length(reason) < 12 || reason !~ /\.md/) invalid++
      delete score_seen; minimum=3; score_count=split(task_scores, score_parts, ";")
      for (i=1; i<=score_count; i++) {
        pair=trim(score_parts[i]); if (pair == "") continue
        split(pair, score_pair, "="); task=trim(score_pair[1]); task_value=trim(score_pair[2])
        if (!applicable[id, task] || score_seen[task]++ || task_value !~ /^[012]$/) invalid++
        else if ((task_value + 0) < minimum) minimum=task_value + 0
      }
      for (key in applicable) { split(key, bits, SUBSEP); if (bits[1] == id && !score_seen[bits[2]]) invalid++ }
      if (minimum == 3 || value != minimum) invalid++
      if (value == "0") zeros++
      if (value ~ /^[012]$/) { sum+=value; family_sum[family]+=value }
      leaf_score[id]=value + 0
    }
    END {
      for (id in expected_family) if (seen[id] != 1) invalid++
      if (family_sum["RF"] < 3 || family_sum["LA"] < 5 || family_sum["CT"] < 7 || family_sum["BC"] < 7 || family_sum["RP"] < 5) floors++
      if (leaf_score["RF1"] != 2 || leaf_score["LA2"] != 2) persona++
      printf "%d|%d|%d|%d|%d|%d", rows + 0, sum + 0, zeros + 0, invalid + 0, floors + 0, persona + 0
    }
  ')
  [[ "$dimension_stats" == "16|${score_value}|0|0|0|0" ]] || { printf 'dimension table must contain the 16 canonical leaves, per-task minimum scores, family floors, and implementation-delegator hard floors, summing to %s (got %s)' "$score_value" "$dimension_stats"; return 1; }
  while IFS= read -r reason; do
    [[ -n "$(strict_ssot_markdown_target_key "$artifact" "$reason" 2>/dev/null || true)" ]] || { printf 'dimension Reason and page must use one resolving non-review consumer-SSOT Markdown link: %s' "$reason"; return 1; }
  done < <(printf '%s\n' "$dimension_table" | awk -F'|' 'NR>2&&/^\|/{id=$3;gsub(/[*`[:space:]]/,"",id);if(id!="") {v=$7;gsub(/^[[:space:]]+|[[:space:]]+$/,"",v);print v}}')
  return 0
}

manifest_has_resolved_review_pointer() { # $1=manifest
  local artifact
  artifact=$(manifest_review_artifact_path "$1" 2>/dev/null || true)
  [[ -n "$artifact" ]] && grep -qi 'no-more-required-changes' "$artifact"
}

check_document_quality() {
  document_quality_active || return 0

  # v2.60 removes the former staged false-green for process, records, glossary,
  # root, and STATUS. These scopes use a lightweight exact-profile artifact,
  # not the product/architecture task matrix and sixteen-leaf score.
  if document_quality_v260_active; then
    local scope_review_fail_count=0 coverage_result profile global_version_rows exact_version_rows convergence_reason
    declare -A scope_review_ids_seen=()
    global_version_rows=$(grep -Ec '(^tracked_skill_version:[[:space:]]*|^\|[[:space:]]*tracked_skill_version[[:space:]]*\|)' "$SSOT_DIR/STATUS.md" || true)
    exact_version_rows=$(awk '
      function trim(v){gsub(/^[[:space:]`]+|[[:space:]`]+$/,"",v);return v}
      /^##[[:space:]]+/{v=$0;sub(/^##[[:space:]]+/,"",v);v=trim(v);active=(tolower(v)=="event-source coverage"||v=="事件源覆盖");next}
      active&&/^\|/{n=split($0,c,"|");if(trim(c[2])=="tracked_skill_version")count++}
      END{print count+0}
    ' "$SSOT_DIR/STATUS.md")
    if [[ "$global_version_rows" -ne 1 || "$exact_version_rows" -ne 1 ]]; then
      add_fail "[STATUS-EXACT-SCHEMA] v2.60 needs exactly one tracked_skill_version row owned by Event-Source Coverage (global=$global_version_rows exact=$exact_version_rows)"
      scope_review_fail_count=$((scope_review_fail_count + 1))
    fi
    check_lightweight_scope_gate() { # $1=profile $2=stop claim $3=authorises $4=area-linked (0/1)
      local profile="$1" expected_claim="$2" expected_authorises="$3" area_linked="$4"
      local sep area_data area_line area_status area_notes area_artifact="" stop_artifact="" link_kind link_path
      local area_review_links=0 area_owner_links=0
      local event line scope claim reviewer reviewer_role reviewed_at result evidence remaining authorises
      local matched_reviewer="" matched_reviewer_role="" matched_reviewed_at="" matched_result="" matched_authorises=""
      local stop_matches=0 stop_schema_error=0 artifact reason review_id artifact_date
      sep=$(printf '\034')
      if [[ "$area_linked" == "1" ]]; then
        area_data=$(status_area_row "$profile")
        if [[ $(printf '%s\n' "$area_data" | sed '/^$/d' | wc -l | tr -d ' ') -ne 1 ]]; then
          add_fail "[SCOPE-REVIEW] $profile claim must have exactly one Area Status row"
          scope_review_fail_count=$((scope_review_fail_count + 1))
          area_status=""
          area_notes=""
        else
          IFS="$sep" read -r area_line area_status area_notes <<< "$area_data"
        fi
        if [[ "$area_status" != "covered" ]]; then
          add_fail "[SCOPE-REVIEW] passing area:${profile}:covered claim contradicts Area Status '${area_status:-missing}'"
          scope_review_fail_count=$((scope_review_fail_count + 1))
        else
          while IFS="$sep" read -r link_kind link_path; do
            [[ -n "$link_kind" ]] || continue
            if [[ "$link_kind" == "OWNER" ]]; then
              area_owner_links=$((area_owner_links + 1))
            elif [[ "$link_kind" == "REVIEW" ]]; then
              area_review_links=$((area_review_links + 1))
              area_artifact="$link_path"
            fi
          done < <(status_area_scope_review_links "$area_notes" "$profile")
          if [[ "$area_owner_links" -ne 1 || "$area_review_links" -ne 1 ]]; then
            add_fail "[SCOPE-REVIEW] covered $profile Area Status Notes need one canonical owner link and exactly one current matching scope-review artifact link: $SSOT_DIR/STATUS.md:$area_line"
            scope_review_fail_count=$((scope_review_fail_count + 1))
          fi
        fi
      fi
      while IFS="$sep" read -r event line scope claim reviewer reviewer_role reviewed_at result evidence remaining authorises; do
        [[ -n "$event" ]] || continue
        if [[ "$event" == "SECTION" || "$event" == "HEADER" ]]; then
          stop_schema_error=1
          continue
        fi
        [[ "$scope" == "$profile" && "$claim" == "$expected_claim" && "$authorises" == "$expected_authorises" ]] || continue
        stop_matches=$((stop_matches + 1))
        matched_reviewer="$reviewer"; matched_reviewer_role="$reviewer_role"; matched_reviewed_at="$reviewed_at"
        matched_result="$result"; matched_authorises="$authorises"
        if [[ "$result" != "no-more-required-changes" ]]; then
          add_fail "[SCOPE-REVIEW] $profile stop row cannot authorise $expected_authorises with result '$result': $SSOT_DIR/STATUS.md:$line"
          scope_review_fail_count=$((scope_review_fail_count + 1))
        fi
        if [[ "$(manifest_markdown_link_count "$evidence")" -ne 1 ]] || ! markdown_link_resolves_with_anchor "$SSOT_DIR/STATUS.md" "$evidence" || markdown_link_uses_symlink_path "$SSOT_DIR/STATUS.md" "$evidence"; then
          add_fail "[SCOPE-REVIEW] $profile stop row Evidence must contain exactly one resolving regular non-symlink Markdown artifact link: $SSOT_DIR/STATUS.md:$line"
          scope_review_fail_count=$((scope_review_fail_count + 1))
        else
          stop_artifact=$(manifest_markdown_link_resolved_path "$SSOT_DIR/STATUS.md" "$evidence" 2>/dev/null || true)
        fi
        if [[ ! "$remaining" =~ ^(none|None|NONE|—|无|0)$ ]]; then
          add_fail "[SCOPE-REVIEW] passing $profile stop row must state that no required change remains: $SSOT_DIR/STATUS.md:$line"
          scope_review_fail_count=$((scope_review_fail_count + 1))
        fi
      done < <(status_stop_review_rows)
      if [[ "$stop_schema_error" -eq 1 ]]; then
        add_fail "[SCOPE-REVIEW] STATUS Stop Review Gate is missing the exact v2.60 reviewer-role/authorises schema"
        scope_review_fail_count=$((scope_review_fail_count + 1))
        return
      fi
      if [[ "$stop_matches" -ne 1 ]]; then
        add_fail "[SCOPE-REVIEW] $profile needs exactly one current Stop Review Gate row for $expected_claim and $expected_authorises (got $stop_matches)"
        scope_review_fail_count=$((scope_review_fail_count + 1))
        return
      fi
      artifact="$stop_artifact"
      if [[ -z "$artifact" ]]; then
        add_fail "[SCOPE-REVIEW] $profile Stop Review Gate artifact link does not resolve"
        scope_review_fail_count=$((scope_review_fail_count + 1))
        return
      fi
      if [[ "$area_linked" == "1" && "$area_status" == covered && "$artifact" != "$area_artifact" ]]; then
        add_fail "[SCOPE-REVIEW] covered $profile Area Status and Stop Review Gate must link the same artifact"
        scope_review_fail_count=$((scope_review_fail_count + 1))
      fi
      if ! reason=$(validate_v260_scope_review_artifact "$profile" "$artifact" "$expected_authorises" 2>&1); then
        add_fail "[SCOPE-REVIEW] invalid $profile exact-scope artifact: ${reason:-validator failed without a diagnostic} ($artifact)"
        scope_review_fail_count=$((scope_review_fail_count + 1))
        return
      fi
      if [[ "$(review_frontmatter_value "$artifact" reviewer)" != "$matched_reviewer" ||
            "$(review_frontmatter_value "$artifact" reviewer_role)" != "$matched_reviewer_role" ||
            "$(review_frontmatter_value "$artifact" verdict)" != "$matched_result" ||
            "$(review_frontmatter_value "$artifact" authorises)" != "$matched_authorises" ]]; then
        add_fail "[SCOPE-REVIEW] $profile stop row and artifact disagree on reviewer, role, verdict, or authorisation"
        scope_review_fail_count=$((scope_review_fail_count + 1))
        return
      fi
      artifact_date=$(review_frontmatter_value "$artifact" reviewed_on)
      if [[ "${matched_reviewed_at:0:10}" != "$artifact_date" ]]; then
        add_fail "[SCOPE-REVIEW] $profile stop row reviewed_at date and artifact reviewed_on disagree"
        scope_review_fail_count=$((scope_review_fail_count + 1))
        return
      fi
      review_id=$(review_frontmatter_value "$artifact" review_id)
      if [[ -n "${scope_review_ids_seen[$review_id]:-}" ]]; then
        add_fail "[SCOPE-REVIEW] review_id '$review_id' is reused by $profile and ${scope_review_ids_seen[$review_id]}"
        scope_review_fail_count=$((scope_review_fail_count + 1))
        return
      fi
      scope_review_ids_seen[$review_id]="$profile"
    }

    for profile in process records glossary; do
      if document_area_is_covered "$profile" || status_passing_stop_exists "$profile" covered "area:${profile}:covered"; then
        check_lightweight_scope_gate "$profile" covered "area:${profile}:covered" 1
      fi
    done
    coverage_result=$(status_coverage_result)
    if [[ "$coverage_result" == "converged" ]]; then
      if ! convergence_reason=$(validate_v260_converged_area_status 2>&1); then
        add_fail "[SCOPE-REVIEW] coverage_result converged lacks exact covered/not-applicable Area preconditions: ${convergence_reason:-validation failed}"
        scope_review_fail_count=$((scope_review_fail_count + 1))
      fi
      check_lightweight_scope_gate root converged coverage_result:converged 0
      check_lightweight_scope_gate status converged coverage_result:converged 0
    else
      if status_passing_stop_exists root converged coverage_result:converged; then
        add_fail "[SCOPE-REVIEW] passing root convergence claim contradicts coverage_result '$coverage_result'"
        scope_review_fail_count=$((scope_review_fail_count + 1))
        check_lightweight_scope_gate root converged coverage_result:converged 0
      fi
      if status_passing_stop_exists status converged coverage_result:converged; then
        add_fail "[SCOPE-REVIEW] passing status convergence claim contradicts coverage_result '$coverage_result'"
        scope_review_fail_count=$((scope_review_fail_count + 1))
        check_lightweight_scope_gate status converged coverage_result:converged 0
      fi
    fi
    status_passing_stop_exists root covered scope:root:covered && check_lightweight_scope_gate root covered scope:root:covered 0
    status_passing_stop_exists status covered scope:status:covered && check_lightweight_scope_gate status covered scope:status:covered 0
    check_v260_record_exact_indexes
    [[ "$scope_review_fail_count" -eq 0 ]] && add_pass "[SCOPE-REVIEW] v2.60 covered/converged lightweight exact profiles have current linked artifacts"
    unset scope_review_ids_seen
  fi

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
      architecture-views)
        minimum_rows=6
        document_quality_v260_active && minimum_rows=7
        ;;
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
      local incomplete_state_rows
      incomplete_state_rows=$(grep -iE '\|[[:space:]]*(gap|missing|unresolved|not-run|needs-review|not-scored|not_assessed|pending|unknown)[[:space:]]*\|' "$manifest" || true)
      if [[ "$declared" == "product-root" && -n "$incomplete_state_rows" ]]; then
        incomplete_state_rows=$(printf '%s\n' "$incomplete_state_rows" | awk -F'|' '
          function trim(v) {
            gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", v)
            return v
          }
          {
            source=trim($4)
            maturity=trim($6)
            fidelity=trim($7)
            if (source ~ /^planned_in:[[:space:]]+/ && maturity == "target" && fidelity == "missing") next
            print
          }
        ')
      fi
      if [[ -n "$incomplete_state_rows" ]]; then
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
      local review_artifact review_reason
      review_artifact=$(manifest_review_artifact_path "$manifest" 2>/dev/null || true)
      if document_quality_v260_active && [[ "$declared" =~ ^(product-root|architecture-root)$ ]]; then
        if [[ -z "$review_artifact" ]]; then
          add_fail "[READER-REVIEW-EVIDENCE] covered manifest lacks a linked structured no-more-required-changes review artifact: $manifest"
          manifest_fail_count=$((manifest_fail_count + 1))
        else
          review_reason=$(validate_v260_review_artifact "$manifest" "$review_artifact" 2>/dev/null || true)
          if [[ -n "$review_reason" ]]; then
            add_fail "[READER-REVIEW-EVIDENCE] invalid structured review for $manifest: $review_reason ($review_artifact)"
            manifest_fail_count=$((manifest_fail_count + 1))
          fi
        fi
      elif ! manifest_has_resolved_review_pointer "$manifest"; then
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
          if document_quality_v260_active; then
            local surface_reason
            surface_reason=$(validate_v260_product_surface_inventory "$manifest" 2>/dev/null || true)
            if [[ -n "$surface_reason" ]]; then
              add_fail "[SURFACE-INVENTORY] invalid product surface inventory: $manifest ($surface_reason)"
              manifest_fail_count=$((manifest_fail_count + 1))
            fi
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
          if document_quality_v260_active; then
            local owner_reason
            owner_reason=$(validate_v260_architecture_owner_inventory "$manifest" 2>/dev/null || true)
            if [[ -n "$owner_reason" ]]; then
              add_fail "[OWNER-INVENTORY] invalid architecture owner/surface inventory: $manifest ($owner_reason)"
              manifest_fail_count=$((manifest_fail_count + 1))
            fi
          fi
          ;;
        architecture-views)
          local view_patterns=('operating-model\.md' 'critical-journeys\.md' 'state-and-data-lifecycle\.md' 'contracts-and-trust-boundaries\.md' 'failure-and-recovery\.md' 'current-target-gap\.md')
          document_quality_v260_active && view_patterns+=('deployment-and-observability\.md')
          for required_pattern in "${view_patterns[@]}"; do
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
    add_pass "reader manifests use complete location-specific archetypes at the active tracking baseline"
  fi

  # Every covered body uses the shared writing floor. Headings, tables, lists,
  # comments, and fenced examples do not count as explanatory prose. STATUS,
  # manifests, .bootstrap artifacts, and other register-only files are not body
  # prose and are deliberately excluded.
  local narrative_fail_count=0 density_warn_count=0
  check_shared_narrative_file() { # $1=body file
    local reader_file="$1" prose_stats paragraphs prose_chars line_stats body_lines table_lines
    [[ -f "$reader_file" ]] || return 0
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
      add_fail "[NARRATIVE-SUFFICIENCY] covered reader body needs at least two explanatory prose paragraphs (found paragraphs=$paragraphs prose_chars=$prose_chars): $reader_file"
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
      add_warn "[KISS-TABLE-DENSITY] reader body is compact but table-dominant; move reference inventory after a self-contained explanation or into a register: $reader_file (table=$table_lines body=$body_lines)"
      density_warn_count=$((density_warn_count + 1))
    fi
  }

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
    check_shared_narrative_file "$reader_file"
  done < <(find "$PRODUCT_DIR" "$ARCHITECTURE_DIR" -name '*.md' -type f -print0 2>/dev/null || true)

  local any_covered=0 any_process_covered=0 any_records_covered=0 area dir
  for area in product architecture process development testing benchmark deployment release operations security-and-compliance records decisions "research records" gotchas bugs tech-debt glossary; do
    document_area_is_covered "$area" && any_covered=1
  done
  if [[ "$any_covered" -eq 1 ]]; then
    if [[ -f "$SSOT_DIR/README.md" ]]; then
      check_shared_narrative_file "$SSOT_DIR/README.md"
    else
      add_fail "[NARRATIVE-SUFFICIENCY] a covered area requires the root reader router: $SSOT_DIR/README.md"
      narrative_fail_count=$((narrative_fail_count + 1))
    fi
  fi
  for area in process development testing benchmark deployment release operations security-and-compliance; do
    document_area_is_covered "$area" && any_process_covered=1
  done
  if [[ "$any_process_covered" -eq 1 ]]; then
    if [[ -f "$PROCESS_DIR/README.md" ]]; then
      check_shared_narrative_file "$PROCESS_DIR/README.md"
    else
      add_fail "[NARRATIVE-SUFFICIENCY] a covered process child requires the process reader router: $PROCESS_DIR/README.md"
      narrative_fail_count=$((narrative_fail_count + 1))
    fi
  fi
  for area in records decisions "research records" gotchas bugs tech-debt; do
    document_area_is_covered "$area" && any_records_covered=1
  done
  if [[ "$any_records_covered" -eq 1 ]]; then
    if [[ -f "$RECORDS_DIR/README.md" ]]; then
      check_shared_narrative_file "$RECORDS_DIR/README.md"
    else
      add_fail "[NARRATIVE-SUFFICIENCY] a covered record child requires the records reader router: $RECORDS_DIR/README.md"
      narrative_fail_count=$((narrative_fail_count + 1))
    fi
  fi

  for area in development testing benchmark deployment release operations security-and-compliance decisions "research records" gotchas bugs tech-debt glossary; do
    document_area_is_covered "$area" || continue
    dir=$(resolve_area_dir "$area")
    [[ -d "$dir" ]] || continue
    while IFS= read -r -d '' reader_file; do
      [[ "$(basename "$reader_file")" == _*.md ]] && continue
      check_shared_narrative_file "$reader_file"
    done < <(find "$dir" -name '*.md' -type f -print0 2>/dev/null || true)
  done

  [[ "$narrative_fail_count" -eq 0 ]] && add_pass "[NARRATIVE-SUFFICIENCY] every covered reader body contains explanatory prose"
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
    local architecture_reader_surfaces=(README.md views/README.md views/operating-model.md views/critical-journeys.md views/current-target-gap.md views/state-and-data-lifecycle.md views/contracts-and-trust-boundaries.md views/failure-and-recovery.md)
    document_quality_v260_active && architecture_reader_surfaces+=(views/deployment-and-observability.md)
    for required in "${architecture_reader_surfaces[@]}"; do
      if [[ ! -f "$ARCHITECTURE_DIR/$required" ]] && ! surface_exception_present "$ARCHITECTURE_DIR/_manifest.md" "$required"; then
        add_fail "[SURFACE-COVERAGE] covered architecture area is missing default reader surface: $ARCHITECTURE_DIR/$required"
        surface_fail_count=$((surface_fail_count + 1))
      fi
    done
  fi
  [[ "$surface_fail_count" -eq 0 ]] && add_pass "[SURFACE-COVERAGE] covered product/architecture roots expose the active default reader route"

  # Normal lint already runs the shared meta-leakage check later. Focused mode
  # skips the normal suite, so it invokes the same helper here.
  if [[ "$DOCUMENT_QUALITY_ONLY" -eq 1 ]]; then
    check_meta_leakage_dir "$SSOT_DIR"
  fi
}

# Run a focused mode, or include document quality in the normal v2.59 lint.
if [[ "$DOCUMENT_QUALITY_ONLY" -eq 1 ]]; then
  check_document_quality
  META_LEAKAGE_SKIP_OTHER_CHECKS=1
elif [[ "$META_LEAKAGE_ONLY" -eq 1 ]]; then
  if [[ "${#META_LEAKAGE_DIRS[@]}" -eq 0 ]]; then
    [[ -d "$SSOT_DIR" ]] && META_LEAKAGE_DIRS+=("$SSOT_DIR")
  fi
  for d in "${META_LEAKAGE_DIRS[@]}"; do
    check_meta_leakage_dir "$d"
  done
  if [[ "${#FAILS[@]}" -eq 0 ]]; then
    add_pass "no [META-LEAKAGE] (15I) hits in reader-facing SSOT prose"
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
  STATUS_SKILL_VERSION=$(document_quality_status_version 2>/dev/null || true)
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

# ---------- check 1aa: v2.60 exact Area Status schema and owner coherence ----------
# Area Status is a finite authority map. Aggregate process/records rows remain
# visible beside their children; conditional owners remain explicit even when
# their reviewed status is not_applicable.
status_area_note_has_route() { # $1=Notes cell
  local note normalized
  note=$(trim_table_cell "$1")
  normalized=$(printf '%s\n' "$note" | sed -E 's/^`//; s/`$//')
  manifest_markdown_link_resolves "$STATUS_FILE" "$note" || \
    printf '%s\n' "$normalized" | grep -qE '^\$ssot-(preflight|bootstrap|closeout|audit|doctor|skill)$'
}

architecture_area_covered_reason() {
  local dir manifest expected artifact reason owner_reason root_artifact
  [[ -f "$ARCHITECTURE_DIR/README.md" ]] || { printf 'missing architecture root README'; return 1; }
  [[ -f "$ARCHITECTURE_DIR/_manifest.md" ]] || { printf 'missing architecture root manifest'; return 1; }
  [[ -f "$ARCHITECTURE_DIR/views/README.md" ]] || { printf 'missing architecture views README'; return 1; }
  [[ -f "$ARCHITECTURE_DIR/views/_manifest.md" ]] || { printf 'missing architecture views manifest'; return 1; }
  owner_reason=$(validate_v260_architecture_owner_inventory "$ARCHITECTURE_DIR/_manifest.md" 2>/dev/null || true)
  [[ -z "$owner_reason" ]] || { printf 'root owner inventory is incoherent: %s' "$owner_reason"; return 1; }
  while IFS= read -r -d '' dir; do
    [[ -f "$dir/README.md" ]] || { printf 'numbered domain is missing README: %s' "${dir#"$SSOT_DIR/"}"; return 1; }
    [[ -f "$dir/_manifest.md" ]] || { printf 'numbered domain is missing manifest: %s' "${dir#"$SSOT_DIR/"}"; return 1; }
  done < <(find "$ARCHITECTURE_DIR" -mindepth 1 -maxdepth 1 -type d -name '[0-9][0-9]-*' -print0 2>/dev/null || true)
  while IFS= read -r -d '' manifest; do
    expected=$(expected_manifest_archetype "$manifest")
    [[ "$expected" =~ ^architecture-(root|views|domain)$ ]] || continue
    [[ $(yaml_frontmatter "$manifest" | grep -Ec '^intent_recovery:[[:space:]]*covered[[:space:]]*$' || true) -eq 1 ]] || {
      printf '%s manifest is not intent_recovery covered' "${manifest#"$SSOT_DIR/"}"; return 1;
    }
    artifact=$(manifest_review_artifact_path "$manifest" 2>/dev/null || true)
    [[ -n "$artifact" ]] || { printf '%s has no resolving structured review' "${manifest#"$SSOT_DIR/"}"; return 1; }
    # The full architecture review is area-owned and validated once against
    # the root inventory. Child manifests must resolve to that same artifact;
    # they do not each define another independent full-review scope.
    if [[ "$manifest" == "$ARCHITECTURE_DIR/_manifest.md" ]]; then
      reason=$(validate_v260_review_artifact "$manifest" "$artifact" 2>/dev/null || true)
      [[ -z "$reason" ]] || { printf '%s has invalid structured review: %s' "${manifest#"$SSOT_DIR/"}" "$reason"; return 1; }
      root_artifact=$(realpath "$artifact")
    elif [[ -n "${root_artifact:-}" && "$(realpath "$artifact")" != "$root_artifact" ]]; then
      printf '%s does not resolve to the architecture root full review' "${manifest#"$SSOT_DIR/"}"; return 1
    fi
  done < <({ printf '%s\0' "$ARCHITECTURE_DIR/_manifest.md"; find "$ARCHITECTURE_DIR" -mindepth 2 -maxdepth 2 -type f -name '_manifest.md' -print0 2>/dev/null || true; })
  return 0
}

if [[ -f "$STATUS_FILE" && -n "$STATUS_SKILL_VERSION" ]] && version_ge "$STATUS_SKILL_VERSION" "2.60"; then
  AREA_STATUS_FAIL_COUNT=0
  declare -A AREA_STATUS_SEEN=() AREA_STATUS_VALUE=()
  coverage_state=$(awk -F'|' '
    /^\|[[:space:]]*coverage_result[[:space:]]*\|/ { v=$3; gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", v); print v; exit }
    /^coverage_result:[[:space:]]*/ { v=$0; sub(/^coverage_result:[[:space:]]*/, "", v); gsub(/["`]/, "", v); print v; exit }
  ' "$STATUS_FILE")
  while IFS=$'\034' read -r event line_no area status notes; do
    [[ -n "$event" ]] || continue
    if [[ "$event" == "SECTION" ]]; then
      add_fail "[AREA-STATUS] STATUS.md is missing the Area Status / 区域状态 table"
      AREA_STATUS_FAIL_COUNT=$((AREA_STATUS_FAIL_COUNT + 1))
      continue
    fi
    if [[ "$event" == "HEADER" ]]; then
      add_fail "[AREA-STATUS] Area Status table needs exact Area, Status, and Notes columns: $STATUS_FILE:$line_no"
      AREA_STATUS_FAIL_COUNT=$((AREA_STATUS_FAIL_COUNT + 1))
      continue
    fi
    case "$area" in
      product|architecture|process|development|testing|benchmark|deployment|release|operations|security-and-compliance|records|decisions|"research records"|gotchas|bugs|tech-debt|glossary) ;;
      *)
        if [[ "$area" =~ ^x-[a-z0-9][a-z0-9-]*$ ]]; then
          if [[ ! "$notes" =~ ^extension: ]] || [[ "$(manifest_markdown_link_count "$notes")" -ne 1 ]] || ! manifest_markdown_link_resolves "$STATUS_FILE" "$notes"; then
          add_fail "[AREA-STATUS] extension row $area needs 'extension:' and one resolving Markdown owner link: $STATUS_FILE:$line_no"
          AREA_STATUS_FAIL_COUNT=$((AREA_STATUS_FAIL_COUNT + 1))
          fi
        else
          add_fail "[AREA-STATUS] unknown Area token '$area'; baseline tokens are fixed and extensions use x-<slug>: $STATUS_FILE:$line_no"
          AREA_STATUS_FAIL_COUNT=$((AREA_STATUS_FAIL_COUNT + 1))
          continue
        fi
        ;;
    esac
    if [[ -n "${AREA_STATUS_SEEN[$area]:-}" ]]; then
      add_fail "[AREA-STATUS] duplicate Area row '$area': $STATUS_FILE:$line_no"
      AREA_STATUS_FAIL_COUNT=$((AREA_STATUS_FAIL_COUNT + 1))
      continue
    fi
    AREA_STATUS_SEEN[$area]="$line_no"
    AREA_STATUS_VALUE[$area]="$status"

    if [[ -z "$status" ]]; then
      if [[ "$coverage_state" != "bootstrap" ]]; then
        add_fail "[AREA-STATUS] blank Status is allowed only while coverage_result is bootstrap: $STATUS_FILE:$line_no area=$area"
        AREA_STATUS_FAIL_COUNT=$((AREA_STATUS_FAIL_COUNT + 1))
      fi
      continue
    fi
    if [[ ! "$status" =~ ^(covered|gap|stale|unknown|not_applicable|conflict)$ ]]; then
      add_fail "[AREA-STATUS] invalid Status '$status' for $area: $STATUS_FILE:$line_no"
      AREA_STATUS_FAIL_COUNT=$((AREA_STATUS_FAIL_COUNT + 1))
      continue
    fi
    if ! status_area_note_has_route "$notes"; then
      add_fail "[AREA-STATUS] non-empty Status '$status' for $area needs a resolving owner/gap route in Notes: $STATUS_FILE:$line_no"
      AREA_STATUS_FAIL_COUNT=$((AREA_STATUS_FAIL_COUNT + 1))
    fi
    if [[ "$status" == "covered" ]]; then
      if [[ "$area" =~ ^x-[a-z0-9][a-z0-9-]*$ ]]; then
        { [[ "$(manifest_markdown_link_count "$notes")" -eq 1 ]] && manifest_markdown_link_resolves "$STATUS_FILE" "$notes"; } || {
          add_fail "[AREA-STATUS] covered extension $area needs a resolving owner link: $STATUS_FILE:$line_no"
          AREA_STATUS_FAIL_COUNT=$((AREA_STATUS_FAIL_COUNT + 1))
        }
      else
        owner_rel=$(canonical_area_rel "$area" 2>/dev/null || true)
        if [[ -z "$owner_rel" || ! -f "$SSOT_DIR/$owner_rel/README.md" ]]; then
          add_fail "[AREA-STATUS] covered $area requires canonical owner README: $SSOT_DIR/${owner_rel:-<unresolved>}/README.md"
          AREA_STATUS_FAIL_COUNT=$((AREA_STATUS_FAIL_COUNT + 1))
        fi
        if [[ "$(status_notes_canonical_owner_count "$area" "$notes")" -ne 1 ]]; then
          add_fail "[AREA-STATUS] covered $area Notes must link its canonical owner README exactly once: $STATUS_FILE:$line_no"
          AREA_STATUS_FAIL_COUNT=$((AREA_STATUS_FAIL_COUNT + 1))
        fi
        if [[ "$area" == "architecture" ]]; then
          architecture_reason=$(architecture_area_covered_reason 2>/dev/null || true)
          if [[ -n "$architecture_reason" ]]; then
            add_fail "[AREA-STATUS] architecture covered aggregate is incoherent: $architecture_reason"
            AREA_STATUS_FAIL_COUNT=$((AREA_STATUS_FAIL_COUNT + 1))
          fi
        fi
      fi
    elif [[ "$status" == "not_applicable" ]]; then
      case "$area" in
        testing|benchmark|deployment|release|operations|security-and-compliance|"research records") ;;
        *)
          add_fail "[AREA-STATUS] not_applicable is not legal for always-applicable area $area: $STATUS_FILE:$line_no"
          AREA_STATUS_FAIL_COUNT=$((AREA_STATUS_FAIL_COUNT + 1))
          ;;
      esac
      if [[ ${#notes} -lt 12 ]] || [[ "$(manifest_markdown_link_count "$notes")" -ne 1 ]] || ! manifest_markdown_link_resolves "$STATUS_FILE" "$notes"; then
        add_fail "[AREA-STATUS] not_applicable $area needs a named reason and exactly one resolving boundary-owner link: $STATUS_FILE:$line_no"
        AREA_STATUS_FAIL_COUNT=$((AREA_STATUS_FAIL_COUNT + 1))
      fi
    fi
  done < <(awk '
    BEGIN { sep=sprintf("%c", 28) }
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/^`|`$/, "", v); return v }
    function set_header(    i,v,lower) {
      area_i=status_i=notes_i=0
      for (i=2; i<cell_count; i++) {
        v=trim(cells[i]); lower=tolower(v)
        if (lower == "area" || v == "区域") area_i=i
        else if (lower == "status" || v == "状态") status_i=i
        else if (lower == "notes" || lower == "note" || v == "备注") notes_i=i
      }
      return area_i && status_i && notes_i
    }
    /^##[[:space:]]+/ {
      title=$0; sub(/^##[[:space:]]+/, "", title); lower=tolower(trim(title))
      in_area=(lower == "area status" || trim(title) == "区域状态")
      if (in_area) found=1
      have_header=0; next
    }
    in_area && /^\|/ {
      if ($0 ~ /^\|[[:space:]:|-]+(\|[[:space:]:|-]+)+\|?[[:space:]]*$/) next
      cell_count=split($0, cells, "|")
      if (!have_header) {
        if (!set_header()) print "HEADER" sep NR
        else have_header=1
        next
      }
      print "ROW" sep NR sep trim(cells[area_i]) sep trim(cells[status_i]) sep trim(cells[notes_i])
    }
    END { if (!found) print "SECTION" sep 0 }
  ' "$STATUS_FILE")

  for required_area in product architecture process development testing benchmark deployment release operations security-and-compliance records decisions "research records" gotchas bugs tech-debt glossary; do
    if [[ -z "${AREA_STATUS_SEEN[$required_area]:-}" ]]; then
      add_fail "[AREA-STATUS] missing exact baseline Area row '$required_area'"
      AREA_STATUS_FAIL_COUNT=$((AREA_STATUS_FAIL_COUNT + 1))
    fi
  done
  if [[ "${AREA_STATUS_VALUE[process]:-}" == "covered" ]]; then
    for child in development testing benchmark deployment release operations security-and-compliance; do
      [[ "${AREA_STATUS_VALUE[$child]:-}" =~ ^(covered|not_applicable)$ ]] || {
        add_fail "[AREA-STATUS] process cannot be covered while child $child is '${AREA_STATUS_VALUE[$child]:-missing}'"
        AREA_STATUS_FAIL_COUNT=$((AREA_STATUS_FAIL_COUNT + 1))
      }
    done
  fi
  if [[ "${AREA_STATUS_VALUE[records]:-}" == "covered" ]]; then
    for child in decisions "research records" gotchas bugs tech-debt; do
      [[ "${AREA_STATUS_VALUE[$child]:-}" =~ ^(covered|not_applicable)$ ]] || {
        add_fail "[AREA-STATUS] records cannot be covered while child $child is '${AREA_STATUS_VALUE[$child]:-missing}'"
        AREA_STATUS_FAIL_COUNT=$((AREA_STATUS_FAIL_COUNT + 1))
      }
    done
  fi
  [[ "$AREA_STATUS_FAIL_COUNT" -eq 0 ]] && add_pass "[AREA-STATUS] v2.60 exact area schema, aggregate states, and covered owner routes are coherent"
  unset AREA_STATUS_SEEN AREA_STATUS_VALUE
fi

# ---------- check 1ab: v2.60 exact S01-S11 STATUS section schemas ----------
status_section_table() { # $1=canonical key
  local wanted="$1"
  awk -v wanted="$wanted" '
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); return v }
    function key(v, lower) {
      lower=tolower(v)
      if (lower=="event-source coverage" || v=="事件源覆盖") return "event"
      if (lower=="area status" || v=="区域状态") return "area"
      if (lower=="quality, risk, and governance" || v=="质量、风险与治理") return "quality"
      if (lower=="source material absorption" || v=="源资料吸收") return "source"
      if (lower=="source inventory exclusions" || v=="不纳入源资料清单的范围") return "exclusions"
      if (lower=="core reference document review" || v=="核心参考文档审查") return "core"
      if (lower=="stop review gate" || v=="停止审查闸门") return "stop"
      if (lower=="open adjudications" || v=="开放裁决项") return "adjudications"
      if (lower=="pending captures" || v=="待捕获项") return "captures"
      if (lower=="open gaps" || v=="开放缺口") return "gaps"
      return ""
    }
    /^##[[:space:]]+/ { title=$0; sub(/^##[[:space:]]+/,"",title); active=(key(trim(title))==wanted); next }
    active && /^\|/ { print }
  ' "$STATUS_FILE"
}

status_header_signature() { # stdin one Markdown header row
  awk -F'|' '
    function trim(v) { gsub(/^[[:space:]`]+|[[:space:]`]+$/, "", v); return v }
    { for(i=2;i<NF;i++){v=trim($i); if(v ~ /^[A-Za-z _\/-]+$/) v=tolower(v); printf "%s%s", (i==2?"":"|"), v} print "" }
  '
}

status_section_data_cells() { # $1=section key; emits normalized cells with FS
  local key="$1"
  status_section_table "$key" | awk -F'|' '
    BEGIN { sep=sprintf("%c",28) }
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/^`|`$/, "", v); return v }
    NR<=2 { next }
    /^\|/ {
      real=0; for(i=2;i<NF;i++) if(trim($i)!="") real=1
      if(!real) next
      for(i=2;i<NF;i++) printf "%s%s", (i==2?"":sep), trim($i)
      print ""
    }
  '
}

status_exact_one_link() { # $1=cell
  [[ "$(manifest_markdown_link_count "$1")" -eq 1 ]] && manifest_markdown_link_resolves "$STATUS_FILE" "$1"
}

status_exact_route() { # $1=cell $2=allow-none
  local cell="$1" allow_none="$2" normalized
  normalized=$(printf '%s' "$cell" | sed -E 's/^`//;s/`$//')
  status_exact_one_link "$cell" && return 0
  [[ "$normalized" =~ ^\$ssot-(preflight|bootstrap|closeout|audit|doctor|skill)$ ]] && return 0
  [[ "$allow_none" == "1" && "$normalized" =~ ^none:[[:space:]].{4,}$ ]]
}

if [[ -f "$STATUS_FILE" && -n "$STATUS_SKILL_VERSION" ]] && version_ge "$STATUS_SKILL_VERSION" "2.60"; then
  STATUS_EXACT_FAIL_COUNT=0
  declare -A STATUS_EXACT_IDS=() STATUS_EVENT_FIELDS=()
  for section in event area quality source exclusions core stop adjudications captures gaps; do
    section_count=$(awk -v wanted="$section" '
      function trim(v){gsub(/^[[:space:]]+|[[:space:]]+$/, "", v);return v}
      function key(v,l){l=tolower(v);if(l=="event-source coverage"||v=="事件源覆盖")return "event";if(l=="area status"||v=="区域状态")return "area";if(l=="quality, risk, and governance"||v=="质量、风险与治理")return "quality";if(l=="source material absorption"||v=="源资料吸收")return "source";if(l=="source inventory exclusions"||v=="不纳入源资料清单的范围")return "exclusions";if(l=="core reference document review"||v=="核心参考文档审查")return "core";if(l=="stop review gate"||v=="停止审查闸门")return "stop";if(l=="open adjudications"||v=="开放裁决项")return "adjudications";if(l=="pending captures"||v=="待捕获项")return "captures";if(l=="open gaps"||v=="开放缺口")return "gaps";return ""}
      /^##[[:space:]]+/{v=$0;sub(/^##[[:space:]]+/,"",v);if(key(trim(v))==wanted)n++}END{print n+0}
    ' "$STATUS_FILE")
    if [[ "$section_count" -ne 1 ]]; then
      add_fail "[STATUS-EXACT-SCHEMA] v2.60 STATUS needs exactly one '$section' section (got $section_count)"
      STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1))
      continue
    fi
    # Drain the table: an early-closing head can SIGPIPE awk under pipefail.
    header=$(status_section_table "$section" | sed -n '1p' | status_header_signature)
    case "$section" in
      event) expected_a='field|value'; expected_b='字段|值' ;;
      area) expected_a='area|status|notes'; expected_b='区域|状态|备注' ;;
      quality) expected_a='q id|applicability|product owner|architecture owner|process/evidence owner|gap owner'; expected_b='q id|适用性|产品事实所有者|架构事实所有者|流程/证据所有者|缺口所有者' ;;
      source) expected_a='source id|source material|path/source|lifecycle|classification|authority|durable owner / absorbed_to|do not use for|review'; expected_b='源资料 ID|源资料|路径/来源|生命周期|分类|权威性|持久所有者或吸收位置|不能用于|复核' ;;
      exclusions) expected_a='pattern|reason|decision owner|last checked|review trigger'; expected_b='路径模式|原因|决策所有者|最近检查日期|复核触发条件' ;;
      core) expected_a='document|role|relation|status|reviewed baseline|durable owner / scope|gap / conflict route'; expected_b='文档|角色|权威关系|状态|审查基线|持久所有者或范围|缺口或冲突路由' ;;
      stop) expected_a='scope|stop claim|reviewer|reviewer role|reviewed at|result|evidence|remaining changes|authorises'; expected_b='范围|停止结论|评审者|评审者角色|评审时间|结果|证据|剩余改动|授权对象' ;;
      adjudications) expected_a='id|state|affected scope / task|question / missing evidence|responsible owner|blocking / retrigger condition|resolving route|closure / supersession evidence'; expected_b='id|状态|受影响范围或任务|问题或缺失证据|责任所有者|阻断或复核触发条件|解决路由|闭合或取代证据' ;;
      captures) expected_a='id|source|proposed owner|reason|priority / trigger|responsible owner|state|closure evidence'; expected_b='id|来源|建议所有者|原因|优先级或触发条件|责任所有者|状态|闭合证据' ;;
      gaps) expected_a='id|state|affected scope / task|question / missing evidence|responsible owner|blocking / retrigger condition|resolving route|closure / supersession evidence'; expected_b='id|状态|受影响范围或任务|问题或缺失证据|责任所有者|阻断或复核触发条件|解决路由|闭合或取代证据' ;;
    esac
    if [[ "$header" != "$expected_a" && "$header" != "$expected_b" ]]; then
      add_fail "[STATUS-EXACT-SCHEMA] '$section' has wrong exact columns: '$header'"
      STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1))
    fi
  done

  while IFS=$'\034' read -r field value; do
    [[ -n "$field" ]] || continue
    case "$field" in tracked_commit|tracked_session|tracked_skill_version|documentation_language|documentation_language_evidence|coverage_result|last_stop_review) ;; *) add_fail "[STATUS-EXACT-SCHEMA] unexpected Event-Source field '$field'"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); continue ;; esac
    [[ -z "${STATUS_EVENT_FIELDS[$field]:-}" ]] || { add_fail "[STATUS-EXACT-SCHEMA] duplicate Event-Source field '$field'"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    STATUS_EVENT_FIELDS[$field]=1
    [[ -n "$value" ]] || { add_fail "[STATUS-EXACT-SCHEMA] Event-Source field '$field' is empty"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    [[ "$field" != coverage_result || "$value" =~ ^(bootstrap|catching_up|in_progress|converged)$ ]] || { add_fail "[STATUS-EXACT-SCHEMA] invalid coverage_result '$value'"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
  done < <(status_section_data_cells event)
  for field in tracked_commit tracked_session tracked_skill_version documentation_language documentation_language_evidence coverage_result last_stop_review; do
    [[ -n "${STATUS_EVENT_FIELDS[$field]:-}" ]] || { add_fail "[STATUS-EXACT-SCHEMA] missing Event-Source field '$field'"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
  done

  while IFS=$'\034' read -r id material path lifecycle classification authority owner do_not_use review; do
    [[ "$id" =~ ^SRC-[0-9]{8}-[0-9]{2}$ ]] || { add_fail "[STATUS-EXACT-SCHEMA] invalid Source Material ID '$id'"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); continue; }
    [[ -z "${STATUS_EXACT_IDS[$id]:-}" ]] || { add_fail "[STATUS-EXACT-SCHEMA] duplicate stable ID '$id'"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    STATUS_EXACT_IDS[$id]=source
    [[ -n "$material" && -n "$path" && -n "$do_not_use" ]] || { add_fail "[STATUS-EXACT-SCHEMA] source row $id has an empty required field"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    [[ "$lifecycle" =~ ^(working/(research|draft|proposal|experiment|poc|prototype|execution-log|closure|report|handoff)|historical/(superseded|deprecated)|external/source-material|public/thin-entry)$ ]] || { add_fail "[STATUS-EXACT-SCHEMA] source row $id has invalid lifecycle '$lifecycle'"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    [[ "$classification" =~ ^(absorb|link-only|stale/conflict|obsolete)$ ]] || { add_fail "[STATUS-EXACT-SCHEMA] source row $id has invalid classification '$classification'"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    [[ "$authority" =~ ^(current|downgraded|external|historical)$ ]] || { add_fail "[STATUS-EXACT-SCHEMA] source row $id has invalid authority '$authority'"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    status_exact_one_link "$owner" || { add_fail "[STATUS-EXACT-SCHEMA] source row $id durable owner must be one resolving link"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    [[ "$review" =~ review_on=[0-9]{4}-[0-9]{2}-[0-9]{2} && "$review" =~ status=(pending|absorbed|linked|conflict-recorded|obsolete) && "$review" =~ conflict= ]] || { add_fail "[STATUS-EXACT-SCHEMA] source row $id has invalid Review lifecycle"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
  done < <(status_section_data_cells source)

  while IFS=$'\034' read -r pattern reason owner last_checked trigger; do
    [[ -n "$pattern" && -z "${STATUS_EXACT_IDS[exclusion:$pattern]:-}" ]] || { add_fail "[STATUS-EXACT-SCHEMA] blank or duplicate source-exclusion pattern '$pattern'"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    STATUS_EXACT_IDS[exclusion:$pattern]=exclusion
    [[ ${#reason} -ge 8 && "$last_checked" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ && ${#trigger} -ge 6 ]] || { add_fail "[STATUS-EXACT-SCHEMA] source exclusion '$pattern' lacks reason, date, or review trigger"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    status_exact_one_link "$owner" || { add_fail "[STATUS-EXACT-SCHEMA] source exclusion '$pattern' decision owner must resolve"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
  done < <(status_section_data_cells exclusions)

  while IFS=$'\034' read -r document role relation state baseline owner route; do
    [[ -n "$document" && -z "${STATUS_EXACT_IDS[core:$document]:-}" ]] || { add_fail "[STATUS-EXACT-SCHEMA] blank or duplicate core-reference document '$document'"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    STATUS_EXACT_IDS[core:$document]=core
    [[ "$role" =~ ^(startup|agent-rules|reference|none)$ && "$relation" =~ ^(thin-adapter|source-material|mixed)$ && "$state" =~ ^(covered|stale|conflict|missing|not_applicable)$ ]] || { add_fail "[STATUS-EXACT-SCHEMA] core-reference '$document' has invalid role/relation/state"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    [[ "$baseline" =~ commit=.{7,} && "$baseline" =~ session=.+ ]] || { add_fail "[STATUS-EXACT-SCHEMA] core-reference '$document' lacks reviewed commit/session"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    status_exact_one_link "$owner" || { add_fail "[STATUS-EXACT-SCHEMA] core-reference '$document' durable owner/scope must resolve"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    status_exact_route "$route" 1 || { add_fail "[STATUS-EXACT-SCHEMA] core-reference '$document' gap/conflict route is not actionable"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
  done < <(status_section_data_cells core)

  while IFS=$'\034' read -r scope claim reviewer role reviewed_at result evidence remaining authorises; do
    [[ -n "$scope" && -n "$reviewer" && -n "$authorises" ]] || { add_fail "[STATUS-EXACT-SCHEMA] stop-review row has empty scope/reviewer/authorises"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    [[ "$claim" =~ ^(covered|converged|no-op|tracked_commit|tracked_session|tracked_skill_version|protocol-upgrade|documentation_language)$ && "$role" =~ ^(scoped-self-review|independent-reviewer|independent-cold-reader)$ && "$result" =~ ^(no-more-required-changes|needs-fix)$ ]] || { add_fail "[STATUS-EXACT-SCHEMA] stop-review '$scope' has invalid claim/role/result"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    [[ "$role" != independent-cold-reader || ( "$scope" =~ ^(product|architecture)$ && "$claim" == covered && "$authorises" == "area:$scope:covered" ) ]] || { add_fail "[STATUS-EXACT-SCHEMA] independent-cold-reader is only valid for product/architecture covered full-review rows"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    [[ "$reviewed_at" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}([T ][0-9]{2}:[0-9]{2}(:[0-9]{2})?([Zz]|[+-][0-9]{2}:[0-9]{2})?)?$ ]] || { add_fail "[STATUS-EXACT-SCHEMA] stop-review '$scope' reviewed_at is not an ISO date/time"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    status_exact_one_link "$evidence" || { add_fail "[STATUS-EXACT-SCHEMA] stop-review '$scope' Evidence must be one resolving Markdown link"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    [[ -n "$remaining" ]] || { add_fail "[STATUS-EXACT-SCHEMA] stop-review '$scope' Remaining changes is empty"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
  done < <(status_section_data_cells stop)

  validate_status_lifecycle_rows() { # $1=section $2=id regex $3=state regex
    local section="$1" id_regex="$2" state_regex="$3" id state affected question owner retrigger route closure
    while IFS=$'\034' read -r id state affected question owner retrigger route closure; do
      [[ "$id" =~ $id_regex ]] || { add_fail "[STATUS-EXACT-SCHEMA] $section has invalid stable ID '$id'"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); continue; }
      [[ -z "${STATUS_EXACT_IDS[$id]:-}" ]] || { add_fail "[STATUS-EXACT-SCHEMA] duplicate stable ID '$id'"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
      STATUS_EXACT_IDS[$id]="$section"
      [[ "$state" =~ $state_regex ]] || { add_fail "[STATUS-EXACT-SCHEMA] $id has invalid state '$state'"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
      [[ -n "$affected" && -n "$question" && -n "$owner" && -n "$retrigger" ]] || { add_fail "[STATUS-EXACT-SCHEMA] $id lacks affected task, question, owner, or retrigger"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
      status_exact_route "$route" 0 || { add_fail "[STATUS-EXACT-SCHEMA] $id resolving route is not actionable"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
      if [[ "$state" =~ ^(resolved|superseded)$ ]]; then status_exact_one_link "$closure" || { add_fail "[STATUS-EXACT-SCHEMA] closed $id needs resolving closure evidence"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
      else status_exact_route "$closure" 1 || { add_fail "[STATUS-EXACT-SCHEMA] open $id closure cell must be a route or reasoned none"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }; fi
    done < <(status_section_data_cells "$section")
  }
  validate_status_lifecycle_rows adjudications '^ADJ-[0-9]{8}-[0-9]{2}$' '^(pending|deferred|resolved|superseded)$'
  validate_status_lifecycle_rows gaps '^GAP-[0-9]{8}-[0-9]{2}$' '^(gap|unknown|resolved|superseded)$'

  while IFS=$'\034' read -r id source proposed reason priority responsible state closure; do
    [[ "$id" =~ ^CAP-[0-9]{8}-[0-9]{2}$ ]] || { add_fail "[STATUS-EXACT-SCHEMA] invalid Pending Capture ID '$id'"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); continue; }
    [[ -z "${STATUS_EXACT_IDS[$id]:-}" ]] || { add_fail "[STATUS-EXACT-SCHEMA] duplicate stable ID '$id'"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    STATUS_EXACT_IDS[$id]=capture
    [[ -n "$source" && ${#reason} -ge 8 && ${#priority} -ge 4 ]] || { add_fail "[STATUS-EXACT-SCHEMA] capture $id lacks source, reason, or priority/trigger"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    status_exact_one_link "$proposed" || { add_fail "[STATUS-EXACT-SCHEMA] capture $id proposed owner must resolve"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    status_exact_route "$responsible" 0 || { add_fail "[STATUS-EXACT-SCHEMA] capture $id responsible owner is not actionable"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    [[ "$state" =~ ^(pending|routed|absorbed|deferred|expired)$ ]] || { add_fail "[STATUS-EXACT-SCHEMA] capture $id has invalid state '$state'"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    if [[ "$state" =~ ^(absorbed|expired)$ ]]; then status_exact_one_link "$closure" || { add_fail "[STATUS-EXACT-SCHEMA] closed capture $id needs closure evidence"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }
    else status_exact_route "$closure" 1 || { add_fail "[STATUS-EXACT-SCHEMA] open capture $id closure cell must be a route or reasoned none"; STATUS_EXACT_FAIL_COUNT=$((STATUS_EXACT_FAIL_COUNT + 1)); }; fi
  done < <(status_section_data_cells captures)

  [[ "$STATUS_EXACT_FAIL_COUNT" -eq 0 ]] && add_pass "[STATUS-EXACT-SCHEMA] v2.60 STATUS sections, columns, states, IDs, and routes are exact"
  unset STATUS_EXACT_IDS STATUS_EVENT_FIELDS
fi

# ---------- check 1a: v2.60 STATUS cells remain pointer-sized ----------
# STATUS.md is a register. A table cell may name state plus one pointer, but it
# must not become the paragraph, command transcript, checklist, or chronology
# that the pointer is supposed to reach. Source-material rows get a wider cap
# because their schema carries lifecycle and authority dispositions.
if [[ -f "$STATUS_FILE" && -n "$STATUS_SKILL_VERSION" ]] && version_ge "$STATUS_SKILL_VERSION" "2.60"; then
  STATUS_REGISTER_CELL_FAIL_COUNT=0
  while IFS='|' read -r line_no section column reason; do
    [[ -n "$line_no" ]] || continue
    add_fail "[STATUS-REGISTER-CELL] STATUS.md register cell must be pointer-sized: $STATUS_FILE:$line_no section='$section' column=$column ($reason); move prose/checklists/commands/history to an owner or appendix and leave one state plus pointer"
    STATUS_REGISTER_CELL_FAIL_COUNT=$((STATUS_REGISTER_CELL_FAIL_COUNT + 1))
  done < <(awk '
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); return v }
    function source_material_section(v, lower) {
      lower=tolower(v)
      return lower == "source material absorption" || v == "源资料吸收"
    }
    /^##[[:space:]]+/ {
      section=$0
      sub(/^##[[:space:]]+/, "", section)
      in_table=0
      next
    }
    /^\|/ {
      if ($0 ~ /^\|[[:space:]:|-]+(\|[[:space:]:|-]+)+\|?[[:space:]]*$/) next
      count=split($0, cells, "|")
      if (!in_table) { in_table=1; next }
      limit=source_material_section(section) ? 320 : 180
      for (i=2; i<count; i++) {
        cell=trim(cells[i])
        if (cell == "") continue
        probe=cell; semicolons=gsub(/[;；]/, "", probe)
        probe=cell; dates=gsub(/20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]/, "", probe)
        reason=""
        if (length(cell) > limit) reason="length " length(cell) " exceeds " limit
        else if (semicolons >= 4) reason="contains " semicolons " semicolon-delimited clauses"
        else if (dates >= 2) reason="contains a multi-event chronology"
        else if (cell ~ /(^|[[:space:]`])(bash|sh|zsh|pnpm|npm|yarn|pytest|cargo|git)([[:space:]]|$)/ || cell ~ /(^|[[:space:]`])(uv[[:space:]]+run|go[[:space:]]+test)([[:space:]]|$)/) reason="contains an executable command instead of an evidence pointer"
        else if (tolower(cell) ~ /(\[[ x]\]|checklist|检查清单)/) reason="contains checklist prose"
        if (reason != "") print NR "|" section "|" (i - 1) "|" reason
      }
      next
    }
    /^[[:space:]]*$/ { in_table=0 }
  ' "$STATUS_FILE")
  if [[ "$STATUS_REGISTER_CELL_FAIL_COUNT" -eq 0 ]]; then
    add_pass "v2.60 STATUS register cells remain pointer-sized"
  fi
fi

# ---------- check 1b: v2.60 open gaps remain actionable ----------
# STATUS is only the gap router. Each real row must say what task is affected,
# the observable condition that blocks or retriggers work, and which clickable
# owner (or explicit runtime skill route) to open. The owner body keeps the
# explanation and evidence.
status_gap_owner_is_actionable() { # $1=Owner cell
  local owner normalized
  owner=$(trim_table_cell "$1")
  normalized=$(printf '%s\n' "$owner" | sed -E 's/^`//; s/`$//')

  if printf '%s\n' "$owner" | grep -qE '^\[[^]]+\]\([^)]+\.md(#[^)]*)?\)$'; then
    manifest_markdown_link_resolves "$STATUS_FILE" "$owner"
    return
  fi

  printf '%s\n' "$normalized" | grep -qE '^\$ssot-(preflight|bootstrap|closeout|audit|doctor|skill)$'
}

if [[ -f "$STATUS_FILE" && -n "$STATUS_SKILL_VERSION" ]] && version_ge "$STATUS_SKILL_VERSION" "2.60"; then
  STATUS_GAP_ACTIONABILITY_FAIL_COUNT=0
  while IFS=$'\034' read -r line_no affected retrigger responsible route; do
    [[ -n "$line_no" ]] || continue
    if [[ -z "$affected" ]]; then
      add_fail "[STATUS-GAP-ACTIONABILITY] open gap row has empty Affected scope / task: $STATUS_FILE:$line_no"
      STATUS_GAP_ACTIONABILITY_FAIL_COUNT=$((STATUS_GAP_ACTIONABILITY_FAIL_COUNT + 1))
    fi
    if [[ -z "$retrigger" ]]; then
      add_fail "[STATUS-GAP-ACTIONABILITY] open gap row has empty Blocking / retrigger condition: $STATUS_FILE:$line_no"
      STATUS_GAP_ACTIONABILITY_FAIL_COUNT=$((STATUS_GAP_ACTIONABILITY_FAIL_COUNT + 1))
    fi
    if [[ -z "$responsible" ]]; then
      add_fail "[STATUS-GAP-ACTIONABILITY] open gap row has empty Responsible owner: $STATUS_FILE:$line_no"
      STATUS_GAP_ACTIONABILITY_FAIL_COUNT=$((STATUS_GAP_ACTIONABILITY_FAIL_COUNT + 1))
    elif ! status_gap_owner_is_actionable "$responsible"; then
      add_fail "[STATUS-GAP-ACTIONABILITY] open gap Responsible owner must be one resolvable Markdown owner link or an explicit \$ssot-* runtime route; a bare record ID is not reachable: $STATUS_FILE:$line_no owner='$responsible'"
      STATUS_GAP_ACTIONABILITY_FAIL_COUNT=$((STATUS_GAP_ACTIONABILITY_FAIL_COUNT + 1))
    fi
    if [[ -z "$route" ]] || ! status_gap_owner_is_actionable "$route"; then
      add_fail "[STATUS-GAP-ACTIONABILITY] open gap Resolving route must be one resolvable Markdown link or an explicit \$ssot-* runtime route: $STATUS_FILE:$line_no route='$route'"
      STATUS_GAP_ACTIONABILITY_FAIL_COUNT=$((STATUS_GAP_ACTIONABILITY_FAIL_COUNT + 1))
    fi
  done < <(status_section_table gaps | awk -F'|' '
    BEGIN { sep=sprintf("%c",28); row=0 }
    function trim(v){gsub(/^[[:space:]]+|[[:space:]]+$/,"",v);return v}
    NR<=2{next}
    /^\|/{
      real=0; for(i=2;i<NF;i++)if(trim($i)!="")real=1; if(!real)next
      row++; print row sep trim($4) sep trim($6) sep trim($5) sep trim($7)
    }
  ')

  if [[ "$STATUS_GAP_ACTIONABILITY_FAIL_COUNT" -eq 0 ]]; then
    add_pass "[STATUS-GAP-ACTIONABILITY] v2.60 open gap rows expose affected tasks, blocking/retrigger conditions, and clickable owner routes"
  fi
fi

# ---------- check 1c: v2.60 quality/risk/governance disposition ----------
# STATUS owns only the cross-layer disposition register. Product,
# architecture, process, and record owners keep the actual explanation. The
# register prevents an applicable quality dimension from disappearing merely
# because no template happened to mention it.
status_q_owner_is_disposed() { # $1=cell $2=allow-none
  local cell normalized allow_none="$2"
  cell=$(trim_table_cell "$1")
  normalized=$(printf '%s\n' "$cell" | sed -E 's/^`//; s/`$//')

  if printf '%s\n' "$cell" | grep -qE '^\[[^]]+\]\([^)]+\.md(#[^)]*)?\)$'; then
    manifest_markdown_link_resolves "$STATUS_FILE" "$cell"
    return
  fi
  if printf '%s\n' "$normalized" | grep -qE '^not_applicable:[[:space:]].{8,}$'; then
    manifest_markdown_link_resolves "$STATUS_FILE" "$cell"
    return
  fi
  [[ "$allow_none" == "1" ]] && printf '%s\n' "$normalized" | grep -qE '^none:[[:space:]].{8,}$'
}

if [[ -f "$STATUS_FILE" && -n "$STATUS_SKILL_VERSION" ]] && version_ge "$STATUS_SKILL_VERSION" "2.60"; then
  STATUS_Q_REGISTER_FAIL_COUNT=0
  declare -A STATUS_Q_SEEN=()
  while IFS=$'\034' read -r event line_no q_id applicability product_owner architecture_owner process_owner gap_owner; do
    [[ -n "$event" ]] || continue
    if [[ "$event" == "SECTION" ]]; then
      add_fail "[QUALITY-DISPOSITION] STATUS.md is missing the Quality, Risk, and Governance / 质量、风险与治理 register"
      STATUS_Q_REGISTER_FAIL_COUNT=$((STATUS_Q_REGISTER_FAIL_COUNT + 1))
      continue
    fi
    if [[ "$event" == "HEADER" ]]; then
      add_fail "[QUALITY-DISPOSITION] STATUS.md quality register is missing required columns at $STATUS_FILE:$line_no; use Q ID, Applicability, Product owner, Architecture owner, Process/evidence owner, and Gap owner"
      STATUS_Q_REGISTER_FAIL_COUNT=$((STATUS_Q_REGISTER_FAIL_COUNT + 1))
      continue
    fi
    if [[ ! "$q_id" =~ ^Q(0[1-9]|1[0-9]|2[01])$ ]]; then
      add_fail "[QUALITY-DISPOSITION] unexpected quality ID at $STATUS_FILE:$line_no: '$q_id'"
      STATUS_Q_REGISTER_FAIL_COUNT=$((STATUS_Q_REGISTER_FAIL_COUNT + 1))
      continue
    fi
    if [[ -n "${STATUS_Q_SEEN[$q_id]:-}" ]]; then
      add_fail "[QUALITY-DISPOSITION] duplicate $q_id row at $STATUS_FILE:$line_no"
      STATUS_Q_REGISTER_FAIL_COUNT=$((STATUS_Q_REGISTER_FAIL_COUNT + 1))
      continue
    fi
    STATUS_Q_SEEN[$q_id]="$line_no"

    if [[ "$applicability" == "applicable" ]]; then
      if ! status_q_owner_is_disposed "$product_owner" 0; then
        add_fail "[QUALITY-DISPOSITION] $q_id applicable product layer needs a resolvable owner/gap link or named not_applicable reason: $STATUS_FILE:$line_no"
        STATUS_Q_REGISTER_FAIL_COUNT=$((STATUS_Q_REGISTER_FAIL_COUNT + 1))
      fi
      if ! status_q_owner_is_disposed "$architecture_owner" 0; then
        add_fail "[QUALITY-DISPOSITION] $q_id applicable architecture layer needs a resolvable owner/gap link or named not_applicable reason: $STATUS_FILE:$line_no"
        STATUS_Q_REGISTER_FAIL_COUNT=$((STATUS_Q_REGISTER_FAIL_COUNT + 1))
      fi
      if ! status_q_owner_is_disposed "$process_owner" 0; then
        add_fail "[QUALITY-DISPOSITION] $q_id applicable process/evidence layer needs a resolvable owner/gap link or named not_applicable reason: $STATUS_FILE:$line_no"
        STATUS_Q_REGISTER_FAIL_COUNT=$((STATUS_Q_REGISTER_FAIL_COUNT + 1))
      fi
      if ! status_q_owner_is_disposed "$gap_owner" 1; then
        add_fail "[QUALITY-DISPOSITION] $q_id Gap owner needs a resolvable gap link or named none reason: $STATUS_FILE:$line_no"
        STATUS_Q_REGISTER_FAIL_COUNT=$((STATUS_Q_REGISTER_FAIL_COUNT + 1))
      fi
    else
      if [[ ! "$applicability" =~ ^not_applicable:[[:space:]].{8,}$ ]] || ! manifest_markdown_link_resolves "$STATUS_FILE" "$applicability"; then
        add_fail "[QUALITY-DISPOSITION] $q_id Applicability must be applicable or not_applicable with a named reason and resolving evidence/owner link: $STATUS_FILE:$line_no"
        STATUS_Q_REGISTER_FAIL_COUNT=$((STATUS_Q_REGISTER_FAIL_COUNT + 1))
      fi
      for global_na_cell in "$product_owner" "$architecture_owner" "$process_owner" "$gap_owner"; do
        if [[ "$global_na_cell" != "—" ]]; then
          add_fail "[QUALITY-DISPOSITION] $q_id global not_applicable row must use exact em dash in every owner/gap cell, not '$global_na_cell': $STATUS_FILE:$line_no"
          STATUS_Q_REGISTER_FAIL_COUNT=$((STATUS_Q_REGISTER_FAIL_COUNT + 1))
        fi
      done
    fi
  done < <(awk '
    BEGIN { sep=sprintf("%c", 28) }
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); gsub(/^`|`$/, "", v); return v }
    function set_header(    i,v,lower) {
      q_i=app_i=product_i=architecture_i=process_i=gap_i=0
      for (i=2; i<cell_count; i++) {
        v=trim(cells[i]); lower=tolower(v)
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
      title=$0; sub(/^##[[:space:]]+/, "", title); lower=tolower(trim(title))
      if (lower == "quality, risk, and governance" || trim(title) == "质量、风险与治理") { in_q=1; found_section=1; have_header=0 }
      else in_q=0
      next
    }
    in_q && /^\|/ {
      if ($0 ~ /^\|[[:space:]:|-]+(\|[[:space:]:|-]+)+\|?[[:space:]]*$/) next
      cell_count=split($0, cells, "|")
      if (!have_header) {
        if (!set_header()) print "HEADER" sep NR
        else have_header=1
        next
      }
      print "ROW" sep NR sep trim(cells[q_i]) sep trim(cells[app_i]) sep trim(cells[product_i]) sep trim(cells[architecture_i]) sep trim(cells[process_i]) sep trim(cells[gap_i])
      next
    }
    END { if (!found_section) print "SECTION" sep 0 }
  ' "$STATUS_FILE")

  for i in {1..21}; do
    printf -v q_id 'Q%02d' "$i"
    if [[ -z "${STATUS_Q_SEEN[$q_id]:-}" ]]; then
      add_fail "[QUALITY-DISPOSITION] STATUS.md quality register is missing exact $q_id disposition"
      STATUS_Q_REGISTER_FAIL_COUNT=$((STATUS_Q_REGISTER_FAIL_COUNT + 1))
    fi
  done
  if [[ "$STATUS_Q_REGISTER_FAIL_COUNT" -eq 0 ]]; then
    add_pass "[QUALITY-DISPOSITION] v2.60 STATUS.md disposes Q01-Q21 with cross-layer owner or gap routes"
  fi
  unset STATUS_Q_SEEN
fi

# ---------- check 1d: v2.57 canonical physical layout ----------
# Legacy directories remain readable below the v2.57 tracking baseline. Once the
# consumer records 2.57+, the migration must already be complete; otherwise
# canonical-first resolution would hide a mixed-layout conflict.
if [[ -f "$STATUS_FILE" && -n "$STATUS_SKILL_VERSION" ]] && version_ge "$STATUS_SKILL_VERSION" "2.57"; then
  FACETED_LAYOUT_FAIL_COUNT=0
  for area in product architecture development testing benchmark deployment release decisions gotchas bugs tech-debt research; do
    legacy_rel=$(legacy_area_rel "$area")
    canonical_rel=$(canonical_area_rel "$area")
    if [[ -d "$SSOT_DIR/$legacy_rel" ]]; then
      add_fail "[FACETED-LAYOUT] tracked_skill_version=$STATUS_SKILL_VERSION still has legacy area $SSOT_DIR/$legacy_rel; migrate it to $SSOT_DIR/$canonical_rel before advancing the tracking baseline"
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
  # Only Notes/备注 owns this heuristic. STATUS may legitimately carry a Date
  # column, and scanning the whole table turns every explicit review date into
  # a false chronology warning. If the table has no Notes column, do not guess.
  STATUS_AREA_NOTES=$(awk '
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); return v }
    /^\|/ && !in_area {
      count=split($0, cells, "|")
      area_i=status_i=notes_i=0
      for (i=2; i<count; i++) {
        value=trim(cells[i]); lower=tolower(value)
        if (lower == "area" || value == "区域") area_i=i
        else if (lower == "status" || value == "状态") status_i=i
        else if (lower == "notes" || lower == "note" || value == "备注") notes_i=i
      }
      if (area_i && status_i) { in_area=1; next }
    }
    in_area && /^##[[:space:]]/ { exit }
    in_area && /^\|[[:space:]:|-]+(\|[[:space:]:|-]+)+\|?[[:space:]]*$/ { next }
    in_area && /^\|/ {
      if (!notes_i) next
      count=split($0, cells, "|")
      print trim(cells[notes_i])
      next
    }
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
    if printf '%s\n' "$STATUS_AREA_NOTES" | grep -qE "$pattern"; then
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
)
index_warn_count=0
while IFS= read -r -d '' readme_file; do
  # A README may be a narrative process/domain owner, not just an index.
  # Strip inline literals such as the image tag `latest`, then flag generated
  # counts plus explicit latest/recent state labels. Ordinary owner prose that
  # happens to explain a version tag or a future verification action is not a
  # derived-state mirror.
  readme_probe=$(sed -E 's/`[^`]*`//g' "$readme_file")
  found_index_state=0
  for pattern in "${INDEX_DERIVED_PATTERNS[@]}"; do
    if printf '%s\n' "$readme_probe" | grep -qE "$pattern"; then
      found_index_state=1
      break
    fi
  done
  if [[ "$found_index_state" -eq 0 ]] && printf '%s\n' "$readme_probe" | grep -qiE '^[[:space:]#>*-]*(latest[[:space:]]+(verification|validation|activity|run history)|recent[[:space:]]+(verification|validation|activity|run history)|最新验证|近期验证|最新活动|近期活动)([[:space:]:：]|$)'; then
    found_index_state=1
  fi
  if [[ "$found_index_state" -eq 0 ]] && printf '%s\n' "$readme_probe" | grep -qiE '^\|[[:space:]]*(latest[[:space:]]+(verification|validation|activity|run history)|recent[[:space:]]+(verification|validation|activity|run history)|最新验证|近期验证|最新活动|近期活动)[[:space:]]*\|'; then
    found_index_state=1
  fi
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
record_effective_activity_state() { # $1=entry $2=bug|tech-debt
  local fm canonical status
  fm=$(yaml_frontmatter "$1")
  if [[ "$2" == bug ]]; then
    canonical=$(printf '%s\n' "$fm" | awk -F: '/^failure_state:/ {gsub(/^[[:space:]"`]+|[[:space:]"`]+$/,"",$2);print tolower($2);exit}')
  else
    canonical=$(printf '%s\n' "$fm" | awk -F: '/^repayment_state:/ {gsub(/^[[:space:]"`]+|[[:space:]"`]+$/,"",$2);print tolower($2);exit}')
  fi
  status=$(printf '%s\n' "$fm" | awk -F: '/^status:/ {gsub(/^[[:space:]"`]+|[[:space:]"`]+$/,"",$2);print tolower($2);exit}')
  # Canonical dual-axis state wins whenever it exists. status is only the
  # compatibility fallback for pre-v2.60 entries that do not declare it.
  [[ -n "$canonical" ]] && printf '%s\n' "$canonical" || printf '%s\n' "$status"
}

entry_actionability_warn_count=0
for entry_dir in "$BUGS_DIR" "$TECH_DEBT_DIR"; do
  if [[ -d "$entry_dir" ]]; then
    while IFS= read -r -d '' entry_file; do
      filename=$(basename "$entry_file")
      [[ "$filename" == "README.md" ]] && continue
      [[ ! "$filename" =~ ^[0-9]{4}-.+\.md$ ]] && continue
      entry_head=$(head -n 40 "$entry_file")
      entry_kind=bug; [[ "$entry_dir" == "$TECH_DEBT_DIR" ]] && entry_kind=tech-debt
      entry_activity_state=$(record_effective_activity_state "$entry_file" "$entry_kind")
      if [[ "$entry_activity_state" != open && "$entry_activity_state" != recurred && "$entry_activity_state" != active ]] &&
         ! printf '%s\n' "$entry_head" | grep -qiE '^(severity:[[:space:]]*(critical|major)|priority:[[:space:]]*high)'; then
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
# This is intentionally WARN-only for reader-facing Markdown. Protocol-owned
# `_manifest.md` files are machine registers whose density is governed by the
# manifest completeness/inventory checks, not by a prose readability heuristic.
KISS_TABLE_LINE_THRESHOLD=${SSOT_KISS_TABLE_LINE_THRESHOLD:-70}
KISS_TABLE_RATIO_THRESHOLD=${SSOT_KISS_TABLE_RATIO_THRESHOLD:-35}
kiss_table_warn_count=0
while IFS= read -r -d '' md_file; do
  rel_file="${md_file#"$SSOT_DIR"/}"
  [[ "$rel_file" == .bootstrap/* ]] && continue
  [[ "$rel_file" == "STATUS.md" ]] && continue
  [[ "$(basename "$rel_file")" == "_manifest.md" ]] && continue
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
    # v2.60 separates record lifecycle from implementation state. Older
    # consumers keep the historical status field contract.
    decision_required_fields=(status implementation_state created_on introduced_in updated_on)
    document_quality_v260_active && decision_required_fields=(id record_status implementation_state created_on introduced_in updated_on)
    for field in "${decision_required_fields[@]}"; do
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
[[ -d "$SSOT_DIR" ]] && check_meta_leakage_dir "$SSOT_DIR"
meta_leakage_after="${#FAILS[@]}"
if [[ "$meta_leakage_after" -eq "$meta_leakage_before" ]]; then
  add_pass "no [META-LEAKAGE] (15I) hits in reader-facing SSOT prose"
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

# ---------- check 15: [H1-LANGUAGE] (15L) every reader body follows language lock ----------
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
    done < <(find "$SSOT_DIR" -name '*.md' -type f \
      ! -path "$SSOT_DIR/.bootstrap/*" ! -name 'STATUS.md' ! -name '_*.md' ! -name 'CHANGELOG.md' -print0 2>/dev/null || true)
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
    "$SSOT_DIR/README.md"|"$PRODUCT_DIR/README.md"|"$PRODUCT_DIR/capabilities/README.md"|"$PRODUCT_DIR/journeys/README.md"|"$ARCHITECTURE_DIR/README.md"|"$ARCHITECTURE_DIR/views/README.md"|"$PROCESS_DIR/README.md"|"$DEVELOPMENT_DIR/README.md"|"$TESTING_DIR/README.md"|"$BENCHMARK_AREA_DIR/README.md"|"$DEPLOYMENT_DIR/README.md"|"$RELEASE_DIR/README.md"|"$OPERATIONS_DIR/README.md"|"$SECURITY_COMPLIANCE_DIR/README.md"|"$RECORDS_DIR/README.md"|"$DECISIONS_DIR/README.md"|"$RESEARCH_AREA_DIR/README.md"|"$GOTCHAS_DIR/README.md"|"$BUGS_DIR/README.md"|"$TECH_DEBT_DIR/README.md"|"$GLOSSARY_DIR/README.md")
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
    repayment_state=$(printf '%s\n' "$fm" | awk -F: '/^repayment_state:/ { gsub(/[ "`]/, "", $2); print tolower($2); exit }')
    document_quality_v260_active && status="$repayment_state"
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
area_is_covered() { document_area_is_covered "$1"; }
scan_covered_placeholder_file() { # $1=file $2=label
  local md_file="$1" label="$2" bname hit strict=0
  [[ -f "$md_file" ]] || return 0
  bname=$(basename "$md_file")
  [[ "$bname" == _*.md || "$bname" == "STATUS.md" || "$bname" == "CHANGELOG.md" ]] && return 0
  document_quality_v260_active && strict=1
  hit=$(awk -v strict="$strict" '
    NR==1 && /^---[[:space:]]*$/ { front=1; next }
    front && /^---[[:space:]]*$/ { front=0; next }
    front { next }
    /^```/ { in_code = !in_code; next }
    {
      line=$0
      # Before v2.60 retain the original, narrow compatibility gate: obvious
      # starter words in visible prose only.  v2.60 adds code, comment, angle-
      # token, and empty-cell checks without rewriting older consumers.
      if (!strict) {
        if (!in_code && line ~ /(TODO:[[:space:]]|FIXME|review-needed|starter skeleton|to be filled|fill this|TBD:|待补充|（待补充）)/) {
          print FNR ":starter token remains"; exit
        }
        next
      }
      if (line ~ /<!--[[:space:]]*/ && line !~ /^[[:space:]]*<!--[[:space:]]*(diagram_type:[[:space:]]*(component|sequence|state|flow)|machine-maintenance:[^-]+)[[:space:]]*-->[[:space:]]*$/) {
        print FNR ":authoring HTML comment remains in covered body"; exit
      }
      if (line ~ /<!--[[:space:]]*/) next
      lower=tolower(line)
      if (lower ~ /<[^>]*(owner|path|command|test|deploy|term|title|date|time|commit|session|version|language|evidence|reason|scope|result|slug|domain|area|state|file|section|task|hash|name|condition|action|proof|repo|project|invariant|child|view|feature|count|score|role|record|failure|pitfall|debt|product|architecture|runtime|current|target|source|review|gate|rollback|recover|observe|verify|safe|unsafe|目录|术语|标题|日期|所有者|路径|证据|理由|范围|状态|文件|小节|任务|仓库|不变量|一句|一段|动作|结果|代码|反例|兄弟)[^>]*>/ ||
          line ~ /<(YYYY|NNNN|ISO-|≤)[^>]*>/ ||
          lower ~ /(^|[^[:alnum:]_])(path\/to|src\/path|tests\/path|command-or-|command-test-or-|nn-<domain>)([^[:alnum:]_]|$)/) {
        print FNR ":protocol placeholder remains in prose or code"; exit
      }
      if (!in_code) {
        gsub(/`[^`]*`/, "", line)
        gsub(/<\/?(a|div|span|img|table|thead|tbody|tr|th|td|details|summary|br|sub|sup|kbd|code)([[:space:]][^>]*)?>/, "", line)
        if (line ~ /<[^>]+>/) { print FNR ":angle-bracket template token remains"; exit }
      }
      if (line ~ /(TODO:[[:space:]]|FIXME|review-needed|starter skeleton|to be filled|fill this|TBD:|待补充|（待补充）|YYYY-MM-DD)/) {
        print FNR ":starter token remains"; exit
      }
      if (line ~ /^\|/ && line !~ /^\|[[:space:]:|-]+(\|[[:space:]:|-]+)+\|?[[:space:]]*$/ && line ~ /\|[[:space:]]*\|/) {
        print FNR ":empty required table cell remains"; exit
      }
      if (line ~ /^\|[[:space:]]*(0000|EXAMPLE|示例)[[:space:]]*\|/) {
        print FNR ":template example row remains"; exit
      }
    }
  ' "$md_file")
  if [[ -n "$hit" ]]; then
    add_fail "[COVERED-PLACEHOLDER] covered $label body contains unresolved template/starter residue: $md_file:$hit"
    COVERED_PLACEHOLDER_FAIL_COUNT=$((COVERED_PLACEHOLDER_FAIL_COUNT + 1))
  fi
  # A clean file is a successful scan.  Without this explicit return, the
  # status of the final conditional can leak through this helper and, under
  # `set -e`, stop normal lint before diagnostics are rendered.
  return 0
}
scan_covered_placeholders() { # $1=dir $2=label
  local dir="$1" label="$2"
  [[ -d "$dir" ]] || return 0
  while IFS= read -r -d '' md_file; do
    scan_covered_placeholder_file "$md_file" "$label"
    [[ "$COVERED_PLACEHOLDER_FAIL_COUNT" -ge 20 ]] && break
  done < <(find "$dir" -name '*.md' -type f -print0 2>/dev/null || true)
  # `read -d ''` returns 1 at normal EOF.  Treat that as normal completion,
  # otherwise errexit aborts the whole lint after the first covered directory.
  return 0
}
COVERED_PLACEHOLDER_FAIL_COUNT=0
# The original gate predates v2.60 and remains active for the areas it already
# governed.  v2.60 broadens the same rule to routers, aggregates, and the new
# conditional/record owners; the scanner above selects the matching strictness.
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

if document_quality_v260_active; then
  any_area_covered=0
  for covered_area in product architecture process development testing benchmark deployment release operations security-and-compliance records decisions "research records" gotchas bugs tech-debt glossary; do
    area_is_covered "$covered_area" && any_area_covered=1
  done
  [[ "$any_area_covered" -eq 1 ]] && scan_covered_placeholder_file "$SSOT_DIR/README.md" root
  any_process_covered=0
  for covered_area in process development testing benchmark deployment release operations security-and-compliance; do
    area_is_covered "$covered_area" && any_process_covered=1
  done
  [[ "$any_process_covered" -eq 1 ]] && scan_covered_placeholder_file "$PROCESS_DIR/README.md" process
  area_is_covered benchmark && scan_covered_placeholders "$BENCHMARK_AREA_DIR" benchmark
  area_is_covered operations && scan_covered_placeholders "$OPERATIONS_DIR" operations
  area_is_covered security-and-compliance && scan_covered_placeholders "$SECURITY_COMPLIANCE_DIR" security-and-compliance
  any_records_covered=0
  for covered_area in records decisions "research records" gotchas bugs tech-debt; do
    area_is_covered "$covered_area" && any_records_covered=1
  done
  [[ "$any_records_covered" -eq 1 ]] && scan_covered_placeholder_file "$RECORDS_DIR/README.md" records
  area_is_covered "research records" && scan_covered_placeholders "$RESEARCH_AREA_DIR" research
fi
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
status_aggregate_summary_lines() {
  [[ -f "$STATUS_FILE" ]] || return
  # Aggregate contradictions belong to the declared stop/summary surfaces.
  # Do not scan Open Gaps or unrelated register rows: their job is precisely to
  # describe when a gap blocks, and words such as "only" / "只有" are normal
  # there. last_stop_review is accepted wherever legacy STATUS files place it.
  awk '
    function trim(v) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); return v }
    /^##[[:space:]]+/ {
      title=$0; sub(/^##[[:space:]]+/, "", title); title=trim(title)
      lower=tolower(title)
      in_summary=(lower == "stop review gate" || lower == "stop review summary" || lower == "status summary" || lower == "coverage summary" || lower == "summary" || title == "停止审查闸门" || title == "停止审查摘要" || title == "状态摘要" || title == "覆盖摘要" || title == "摘要")
      next
    }
    {
      lower=tolower($0)
      if (lower ~ /^\|[[:space:]]*last_stop_review[[:space:]]*\|/ || $0 ~ /^\|[[:space:]]*(最后停止审查|停止审查结论)[[:space:]]*\|/) {
        print NR ":" $0
        next
      }
      if (in_summary) print NR ":" $0
    }
  ' "$STATUS_FILE"
}
active_high_risk_record_count() {
  local count=0 activity
  bug_dir="$BUGS_DIR"
  if [[ -d "$bug_dir" ]]; then
    while IFS= read -r -d '' bug_file; do
      local head
      head=$(yaml_frontmatter "$bug_file")
      activity=$(record_effective_activity_state "$bug_file" bug)
      if [[ "$activity" == open || "$activity" == recurred || "$activity" == active ]] &&
         printf '%s\n' "$head" | grep -qiE '^severity:[[:space:]]*(critical|major|high)'; then
        count=$((count + 1))
      fi
    done < <(find "$bug_dir" -name '[0-9][0-9][0-9][0-9]-*.md' -type f -print0)
  fi
  debt_dir="$TECH_DEBT_DIR"
  if [[ -d "$debt_dir" ]]; then
    while IFS= read -r -d '' debt_file; do
      local head
      head=$(yaml_frontmatter "$debt_file")
      activity=$(record_effective_activity_state "$debt_file" tech-debt)
      if [[ "$activity" == active ]] &&
         printf '%s\n' "$head" | grep -qiE '^priority:[[:space:]]*(critical|high)'; then
        count=$((count + 1))
      fi
    done < <(find "$debt_dir" -name '[0-9][0-9][0-9][0-9]-*.md' -type f -print0)
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
    done < <(status_aggregate_summary_lines | grep -Ei '(remaining|no open gaps|zero remaining|当前无.*缺口|仅剩|只有.*DEBT)' || true)
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
record_head_has_deferral_signal() {
  # The record's own stable ID identifies the document; it does not assign a
  # future action or provide a retrigger. Exclude it before looking for a real
  # owner, closure condition, guard, next action, or linked owner record.
  yaml_frontmatter "$1" | sed '/^id:[[:space:]]*/d' | grep -qiE "$DEFERRAL_SIGNAL_RE"
}
record_is_active_for_deferral_scan() {
  local record_file="$1"
  local head state status failure_state repayment_state
  head=$(yaml_frontmatter "$record_file")
  status=$(printf '%s\n' "$head" | awk -F: '/^status:/ { gsub(/[ "`]/, "", $2); print tolower($2); exit }')
  state=$(printf '%s\n' "$head" | awk -F: '/^implementation_state:/ { gsub(/[ "`]/, "", $2); print tolower($2); exit }')
  failure_state=$(printf '%s\n' "$head" | awk -F: '/^failure_state:/ { gsub(/[ "`]/, "", $2); print tolower($2); exit }')
  repayment_state=$(printf '%s\n' "$head" | awk -F: '/^repayment_state:/ { gsub(/[ "`]/, "", $2); print tolower($2); exit }')
  [[ "$status" =~ ^(open|active|recurred)$ || "$failure_state" =~ ^(open|recurred)$ || "$repayment_state" == active || "$state" =~ ^(pending|partial|diverged)$ ]]
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
        if [[ "$SILENT_DEFERRAL_FAIL_COUNT" -ge 30 ]]; then
          return 0
        fi
      fi
    fi
  done <<< "$(strip_code_for_deferral_scan "$target_file")"
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
    if record_head_has_deferral_signal "$record_file"; then
      scan_deferral_lines "$record_file" "active record" 1
    else
      scan_deferral_lines "$record_file" "active record" 0
    fi
    [[ "$SILENT_DEFERRAL_FAIL_COUNT" -ge 30 ]] && break
  done < <(find "$record_dir" -name '*.md' -type f -print0)
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
    research_required_fields=(status kind created_on owner promotion_targets recheck_trigger)
    document_quality_v260_active && research_required_fields=(id record_status adoption_state kind created_on owner promotion_targets recheck_trigger)
    for field in "${research_required_fields[@]}"; do
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
    research_value_fields=(status kind created_on owner)
    document_quality_v260_active && research_value_fields=(id record_status adoption_state kind created_on owner)
    for field in "${research_value_fields[@]}"; do
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
