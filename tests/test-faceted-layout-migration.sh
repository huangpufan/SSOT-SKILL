#!/usr/bin/env bash
# tests/test-faceted-layout-migration.sh -- v2.57 SSOT directory migration helper
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MIGRATE="$PROJECT_ROOT/skills/ssot-audit/assets/scripts/migrate-faceted-layout.py"
PASS=0
FAIL=0
WORK_ROOT="$(mktemp -d)"
trap 'rm -rf "$WORK_ROOT"' EXIT

pass() { echo "  ok   : $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL : $1"; FAIL=$((FAIL + 1)); }
assert_file() { [[ -f "$2" ]] && pass "$1" || fail "$1 (missing: $2)"; }
assert_dir() { [[ -d "$2" ]] && pass "$1" || fail "$1 (missing: $2)"; }
assert_no_path() { [[ ! -e "$2" ]] && pass "$1" || fail "$1 (should not exist: $2)"; }
assert_grep() { grep -qF "$3" "$2" 2>/dev/null && pass "$1" || fail "$1 (missing '$3' in $2)"; }
assert_exit() { [[ "$2" == "$3" ]] && pass "$1" || fail "$1 (exit $2 != $3)"; }

make_legacy_ssot() {
  local root="$1"
  mkdir -p "$root/SSOT/product/capabilities" \
           "$root/SSOT/architecture/domains/runtime" \
           "$root/SSOT/testing" \
           "$root/SSOT/decisions" \
           "$root/SSOT/tech-debt" \
           "$root/SSOT/research"
  printf '# SSOT\n\n- [product](product/README.md)\n- [arch](architecture/README.md)\n- [runtime](architecture/domains/runtime/README.md)\n- [testing](testing/README.md)\n\nLiteral: `SSOT/product/README.md`\n' > "$root/SSOT/README.md"
  printf '# Product\n\n[Architecture](../architecture/README.md)\n' > "$root/SSOT/product/README.md"
  printf '# PRD\n\n[Architecture](../architecture/README.md)\n' > "$root/SSOT/product/prd.md"
  printf '# Architecture\n\n[Product](../product/README.md)\n' > "$root/SSOT/architecture/README.md"
  printf '# Domain index\n\n[Runtime](runtime/README.md)\n' > "$root/SSOT/architecture/domains/README.md"
  printf '# Runtime\n\n[Architecture root](../../README.md)\n' > "$root/SSOT/architecture/domains/runtime/README.md"
  printf '# Testing\n\n[Architecture](../architecture/README.md)\n' > "$root/SSOT/testing/README.md"
  printf '# Decisions\n' > "$root/SSOT/decisions/README.md"
  printf '# Tech debt\n' > "$root/SSOT/tech-debt/README.md"
  printf '# Research\n' > "$root/SSOT/research/README.md"
}

echo "=== test-faceted-layout-migration ==="

echo "== S1 dry-run leaves legacy tree untouched =="
T="$WORK_ROOT/dry-run"
mkdir -p "$T"
make_legacy_ssot "$T"
out="$(python3 "$MIGRATE" --dry-run "$T/SSOT" 2>&1)"
code=$?
assert_exit "dry-run exits 0" "$code" "0"
assert_grep "dry-run reports product move" <(printf '%s\n' "$out") "move SSOT/product -> SSOT/01-product"
assert_dir "dry-run keeps legacy product" "$T/SSOT/product"
assert_no_path "dry-run does not create canonical product" "$T/SSOT/01-product"

echo "== S2 migrate legacy tree to faceted layout =="
T="$WORK_ROOT/migrate"
mkdir -p "$T"
make_legacy_ssot "$T"
out="$(python3 "$MIGRATE" "$T/SSOT" 2>&1)"
code=$?
assert_exit "migration exits 0" "$code" "0"
assert_dir "product moved" "$T/SSOT/01-product"
assert_dir "architecture moved" "$T/SSOT/02-architecture"
assert_dir "testing moved under process" "$T/SSOT/03-process/testing"
assert_dir "decisions moved under records" "$T/SSOT/04-records/decisions"
assert_dir "tech debt moved under records" "$T/SSOT/04-records/tech-debt"
assert_dir "research moved under records" "$T/SSOT/04-records/research"
assert_dir "domain flattened and numbered" "$T/SSOT/02-architecture/01-runtime"
assert_file "legacy domain index preserved" "$T/SSOT/02-architecture/domain-index.md"
assert_no_path "legacy product removed" "$T/SSOT/product"
assert_no_path "legacy architecture removed" "$T/SSOT/architecture"
assert_grep "root link updated to canonical product" "$T/SSOT/README.md" "[product](./01-product/README.md)"
assert_grep "root domain link updated to numbered domain" "$T/SSOT/README.md" "[runtime](./02-architecture/01-runtime/README.md)"
assert_grep "literal SSOT path updated" "$T/SSOT/README.md" "SSOT/01-product/README.md"
assert_grep "moved product link recalculated" "$T/SSOT/01-product/prd.md" "[Architecture](../02-architecture/README.md)"
assert_grep "moved testing link recalculated" "$T/SSOT/03-process/testing/README.md" "[Architecture](../../02-architecture/README.md)"
assert_grep "domain arch-root link recalculated" "$T/SSOT/02-architecture/01-runtime/README.md" "[Architecture root](../README.md)"

echo "== S3 conflict is explicit and non-mutating =="
T="$WORK_ROOT/conflict"
mkdir -p "$T/SSOT/product" "$T/SSOT/01-product"
printf '# Product\n' > "$T/SSOT/product/README.md"
printf '# Existing canonical product\n' > "$T/SSOT/01-product/README.md"
out="$(python3 "$MIGRATE" "$T/SSOT" 2>&1)"
code=$?
assert_exit "conflict exits 2" "$code" "2"
assert_grep "conflict names target" <(printf '%s\n' "$out") "target exists"
assert_file "legacy source kept after conflict" "$T/SSOT/product/README.md"
assert_file "canonical target kept after conflict" "$T/SSOT/01-product/README.md"

echo
echo "=== RESULT: pass=$PASS fail=$FAIL ==="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
