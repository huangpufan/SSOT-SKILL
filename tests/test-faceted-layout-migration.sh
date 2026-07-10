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
assert_equal() { [[ "$2" == "$3" ]] && pass "$1" || fail "$1 ('$2' != '$3')"; }
digest_files() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$@"
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$@"
  else
    echo "no SHA-256 digest command found" >&2
    return 127
  fi
}
tree_digest() {
  find "$1" -type f | LC_ALL=C sort | while IFS= read -r file; do
    digest_files "$file"
  done
}

make_legacy_ssot() {
  local root="$1"
  mkdir -p "$root/SSOT/product/capabilities" \
           "$root/SSOT/architecture/domains/runtime" \
           "$root/SSOT/testing" \
           "$root/SSOT/decisions" \
           "$root/SSOT/tech-debt" \
           "$root/SSOT/research"
  printf '# SSOT\n\n- [product](product/README.md)\n- [product with title](product/README.md "Title")\n- [product directory](product/)\n- [product guide](<product/guide with space.md>)\n- [product reference][product-root]\n- [arch](architecture/README.md)\n- [runtime](architecture/domains/runtime/README.md)\n- [testing](testing/README.md)\n\n[product-root]: product/README.md "Product root"\n\nLiteral: `SSOT/product/README.md`\nUnrelated literal: `SSOT/productivity/README.md`\nLonger token: `NOTSSOT/product/README.md`\nExternal URL: https://example.test/SSOT/product/README.md\n' > "$root/SSOT/README.md"
  printf '# Product\n\n[Architecture](../architecture/README.md)\n' > "$root/SSOT/product/README.md"
  printf '# PRD\n\n[Architecture](../architecture/README.md)\n' > "$root/SSOT/product/prd.md"
  printf '# Guide\n' > "$root/SSOT/product/guide with space.md"
  printf '# Architecture\n\n[Product](../product/README.md)\n' > "$root/SSOT/architecture/README.md"
  printf '# Domain index\n\n[Runtime](runtime/README.md)\n' > "$root/SSOT/architecture/domains/README.md"
  printf '# Runtime\n\n[Architecture root](../../README.md)\n' > "$root/SSOT/architecture/domains/runtime/README.md"
  printf '# Testing\n\n[Architecture](../architecture/README.md)\n' > "$root/SSOT/testing/README.md"
  printf '# Decisions\n' > "$root/SSOT/decisions/README.md"
  printf '# Tech debt\n' > "$root/SSOT/tech-debt/README.md"
  printf '# Research\n' > "$root/SSOT/research/README.md"
}

echo "=== test-faceted-layout-migration ==="

echo "== S0 canonical tree is an exact dry-run no-op =="
T="$WORK_ROOT/canonical-no-op"
mkdir -p "$T/SSOT/01-product"
printf '# SSOT\n\n[product](01-product/README.md)\n' > "$T/SSOT/README.md"
printf '# Product\n' > "$T/SSOT/01-product/README.md"
before="$(digest_files "$T/SSOT/README.md" "$T/SSOT/01-product/README.md")"
out="$(python3 "$MIGRATE" --dry-run "$T/SSOT" 2>&1)"
code=$?
after="$(digest_files "$T/SSOT/README.md" "$T/SSOT/01-product/README.md")"
assert_exit "canonical dry-run exits 0" "$code" "0"
assert_equal "canonical dry-run reports exact no-op" "$out" "faceted-layout migration: no changes needed"
assert_equal "canonical dry-run preserves bytes" "$after" "$before"

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
assert_grep "inline link title is preserved" "$T/SSOT/README.md" '[product with title](./01-product/README.md "Title")'
assert_grep "directory link keeps trailing slash" "$T/SSOT/README.md" "[product directory](./01-product/)"
assert_grep "angle link updated and preserved" "$T/SSOT/README.md" "[product guide](<./01-product/guide with space.md>)"
assert_grep "reference definition updated with title preserved" "$T/SSOT/README.md" '[product-root]: ./01-product/README.md "Product root"'
assert_grep "root domain link updated to numbered domain" "$T/SSOT/README.md" "[runtime](./02-architecture/01-runtime/README.md)"
assert_grep "literal SSOT path updated" "$T/SSOT/README.md" "SSOT/01-product/README.md"
assert_grep "literal shared prefix is not rewritten" "$T/SSOT/README.md" "SSOT/productivity/README.md"
assert_grep "literal longer left token is not rewritten" "$T/SSOT/README.md" "NOTSSOT/product/README.md"
assert_grep "external URL path is not rewritten" "$T/SSOT/README.md" "https://example.test/SSOT/product/README.md"
assert_grep "moved product link recalculated" "$T/SSOT/01-product/prd.md" "[Architecture](../02-architecture/README.md)"
assert_grep "moved testing link recalculated" "$T/SSOT/03-process/testing/README.md" "[Architecture](../../02-architecture/README.md)"
assert_grep "domain arch-root link recalculated" "$T/SSOT/02-architecture/01-runtime/README.md" "[Architecture root](../README.md)"
before="$(tree_digest "$T/SSOT")"
second_out="$(python3 "$MIGRATE" "$T/SSOT" 2>&1)"
second_code=$?
after="$(tree_digest "$T/SSOT")"
assert_exit "second migration exits 0" "$second_code" "0"
assert_equal "second migration reports exact no-op" "$second_out" "faceted-layout migration: no changes needed"
assert_equal "second migration preserves bytes" "$after" "$before"

echo "== S3 conflict is explicit and non-mutating =="
T="$WORK_ROOT/conflict"
mkdir -p "$T/SSOT/product" "$T/SSOT/01-product"
printf '# Product\n' > "$T/SSOT/product/README.md"
printf '# Existing canonical product\n' > "$T/SSOT/01-product/README.md"
before="$(tree_digest "$T/SSOT")"
out="$(python3 "$MIGRATE" "$T/SSOT" 2>&1)"
code=$?
after="$(tree_digest "$T/SSOT")"
assert_exit "conflict exits 2" "$code" "2"
assert_grep "conflict names target" <(printf '%s\n' "$out") "target exists"
assert_file "legacy source kept after conflict" "$T/SSOT/product/README.md"
assert_file "canonical target kept after conflict" "$T/SSOT/01-product/README.md"
assert_equal "conflict preserves all file bytes" "$after" "$before"

echo
echo "=== RESULT: pass=$PASS fail=$FAIL ==="
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
