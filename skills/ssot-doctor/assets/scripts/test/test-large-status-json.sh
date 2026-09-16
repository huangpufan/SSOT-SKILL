#!/usr/bin/env bash
# Oversized register cells must produce a JSON diagnostic, not a SIGPIPE crash.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LINT="${SSOT_LINT_UNDER_TEST:-$SCRIPT_DIR/../ssot-lint.sh}"
TEMPLATE="$SCRIPT_DIR/../../../../ssot-bootstrap/assets/templates/en/status.md"
if [[ ! -f "$TEMPLATE" ]]; then
  TEMPLATE="$SCRIPT_DIR/../../../../ssot-bootstrap/assets/templates/status.md"
fi
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/SSOT"

python3 - "$TEMPLATE" "$WORK/SSOT/STATUS.md" <<'PY'
import pathlib
import sys

text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
text = text.replace("<ssot-preflight-protocol-version>", "2.60")
text = text.replace("<ssot-preflight-协议版本>", "2.60")
text = text.replace("<commit-sha>", "untracked")
lines = []
for line in text.splitlines():
    if line.startswith("| Q") and line[3:5].isdigit():
        # Exceed pipe buffers independently of their platform-specific size.
        cell = "[owner](owner.md) " + "x" * 16384
        line = "| " + " | ".join([line.split("|")[1].strip(), "applicable"] + [cell] * 4) + " |"
    lines.append(line)
pathlib.Path(sys.argv[2]).write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

for attempt in 1 2 3; do
  code=0
  bash "$LINT" --json "$WORK/SSOT" > "$WORK/result.json" 2> "$WORK/stderr" || code=$?
  # Invalid cells are deliberate: the supported result is a diagnostic FAIL.
  if [[ "$code" != 2 ]]; then
    echo "FAIL: large STATUS JSON attempt $attempt exited $code instead of 2" >&2
    cat "$WORK/stderr" >&2
    exit 1
  fi
  python3 - "$WORK/result.json" <<'PY'
import json
import pathlib
import sys

result = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert isinstance(result, dict), "Expected a JSON diagnostic object"
PY
done
echo "PASS: large STATUS emits valid JSON diagnostics on all three attempts"
