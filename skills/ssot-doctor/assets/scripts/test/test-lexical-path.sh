#!/usr/bin/env bash
# Missing components and links must retain lexical path spelling on GNU and BSD.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LINT="${SSOT_LINT_UNDER_TEST:-$SCRIPT_DIR/../ssot-lint.sh}"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
python3 - "$LINT" "$WORK/helper.sh" <<'PY_HELPER'
import pathlib
import re
import sys
text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
match = re.search(r"^lexical_path\(\) \{\n.*?^\}", text, re.M | re.S)
assert match, "Missing lexical normalization helper"
pathlib.Path(sys.argv[2]).write_text(match.group(0) + "\n", encoding="utf-8")
PY_HELPER
# shellcheck disable=SC1091
source "$WORK/helper.sh"
mkdir -p "$WORK/actual/nested" "$WORK/root"
ln -s "$WORK/actual/nested" "$WORK/root/link"
cd "$WORK/root"
check_path() {
  local input="$1" expected="$2" actual
  actual=$(lexical_path "$input")
  [[ "$actual" == "$expected" ]] || {
    printf 'FAIL: lexical spelling differs for %s\n' "$input" >&2
    return 1
  }
  # Where GNU flags exist, also compare their original semantics.
  if realpath -m -s / >/dev/null 2>&1; then
    [[ "$actual" == "$(realpath -m -s "$input")" ]] || return 1
  fi
}
check_path . "$WORK/root"
check_path missing/../file "$WORK/root/file"
check_path ../missing/./child "$WORK/missing/child"
check_path 'name with space/../café.md' "$WORK/root/café.md"
check_path link "$WORK/root/link"
check_path link/.. "$WORK/root"
check_path link/../missing "$WORK/root/missing"
check_path /missing/parent/../../child /child
check_path /../../child /child
check_path //missing///child /missing/child
check_path ///missing/./child/ /missing/child
if lexical_path '' >/dev/null 2>&1; then
  echo 'FAIL: empty path must be rejected' >&2
  exit 1
fi
[[ "$(realpath link)" != "$(lexical_path link)" ]] || {
  echo 'FAIL: link fixture must distinguish canonical and lexical paths' >&2
  exit 1
}
echo 'PASS: lexical normalization preserves missing paths and link spelling'
