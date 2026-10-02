#!/usr/bin/env bash
# Exercise adapter boundaries through the real lint CLI, not an extracted parser.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 - "${SSOT_LINT_UNDER_TEST:-$SCRIPT_DIR/../ssot-lint.sh}" <<'PY'
import hashlib
import json
import pathlib
import subprocess
import sys
import tempfile

lint = pathlib.Path(sys.argv[1]).resolve()
begin = '<!-- SSOT-SKILL:BEGIN -->\n'
end = '<!-- SSOT-SKILL:END -->\n'
marker = '<!-- SSOT-generated | generated_at: 2026-05-29 -->\n'
route = 'Use $ssot-preflight and read SSOT/README.md.\n'
local = '# Local rules\n' + ''.join(f'Local rule {n}.\n' for n in range(60))
short_block = begin + route + end
cases = [
    ('legacy-short', marker + route, None),
    ('legacy-long', marker + route + local, 'exceeds 50 lines'),
    ('mixed-with-file-marker', marker + short_block + local, None),
    ('mixed-with-block-only', local + short_block, None),
    ('oversized-block', local + begin + route * 51 + end, 'exceeds 50 lines'),
    ('missing-end', marker + begin + route + local, 'boundary'),
    ('orphan-end', local + end, 'boundary'),
    ('reversed-boundaries', end + route + begin, 'boundary'),
    ('duplicate-blocks', short_block + local + short_block, 'boundary'),
    ('nested-blocks', begin + short_block + end, 'boundary'),
    ('malformed-boundary', '<!-- SSOT-SKILL:BEGIN\n' + route + end, 'boundary'),
    ('fenced-example', chr(96) * 3 + 'md\n' + short_block + chr(96) * 3 + '\n' + local, None),
    ('indented-fence-before-duplicates', '    ' + chr(96) * 3 + '\n\n' + short_block * 2, 'boundary'),
    ('invalid-fence-before-duplicates', chr(96) * 3 + 'example' + chr(96) + 'literal\n\n' + short_block * 2, 'boundary'),
    ('indented-marker-example', ''.join('    ' + line for line in short_block.splitlines(keepends=True)) + '\n' + short_block, None),
    ('long-fence-example', chr(96) * 4 + 'md\n' + short_block + chr(96) * 3 + '\n' + chr(96) * 4 + '\n' + short_block, None),
    ('tilde-fence-example', '~~~md\n' + short_block + '~~~\n' + short_block, None),
]
for width in (1, 2, 3):
    padding = ' ' * width + '\t'
    example = ''.join(padding + line for line in short_block.splitlines(keepends=True))
    cases.append((f'mixed-indent-{width}-marker-example', example + '\n' + short_block, None))
failed = []
with tempfile.TemporaryDirectory(prefix='ssot-adapter-blocks-') as temp:
    root = pathlib.Path(temp)
    ssot = root / 'SSOT'
    ssot.mkdir()
    # Deliberately small legacy consumer; unrelated lint findings are retained
    # in the JSON, while these tests assert the public adapter diagnostics.
    (ssot / 'README.md').write_text('# Navigation\n', encoding='utf-8')
    (ssot / 'STATUS.md').write_text(
        '| tracked_skill_version | 2.19 |\n| coverage_result | in_progress |\n',
        encoding='utf-8',
    )
    digest = hashlib.sha256((ssot / 'README.md').read_bytes()).hexdigest()[:12]
    current_hash = f'<!-- SSOT-source: SSOT/README.md@{digest} -->\n'
    stale_hash = '<!-- SSOT-source: SSOT/README.md@000000000000 -->\n'
    cases.extend([
        ('bounded-current-source', marker + current_hash + short_block + local, None),
        ('bounded-stale-source', marker + stale_hash + short_block + local, 'source file changed'),
        ('fenced-stale-source-example', chr(96) * 3 + 'md\n' + stale_hash + chr(96) * 3 + '\n' + current_hash + short_block, None),
        ('fenced-current-source-example', chr(96) * 3 + 'md\n' + current_hash + chr(96) * 3 + '\n' + stale_hash + short_block, 'source file changed'),
        ('inline-stale-source-example', 'Example: ' + chr(96) + stale_hash.strip() + chr(96) + '\n' + current_hash + short_block, None),
        ('inline-current-source-example', 'Example: ' + chr(96) + current_hash.strip() + chr(96) + '\n' + stale_hash + short_block, 'source file changed'),
    ])
    for name, content, expected in cases:
        adapter = root / 'AGENTS.md'
        adapter.write_text(content, encoding='utf-8')
        before = adapter.read_bytes()
        result = subprocess.run(
            ['bash', str(lint), '--json', str(ssot)],
            text=True, capture_output=True, check=False,
        )
        if result.returncode not in (0, 1, 2):
            raise AssertionError(f'{name}: lint invocation failed: {result.stderr}')
        report = json.loads(result.stdout)
        diagnostics = [
            msg for key in ('warns', 'fails') for msg in report[key]
            if '[ADAPTER]' in msg or 'SSOT-generated thin adapter' in msg
        ]
        good = (not diagnostics if expected is None else
                len(diagnostics) == 1 and expected in diagnostics[0])
        good = good and adapter.read_bytes() == before
        if good:
            print(f'PASS: {name}')
        else:
            failed.append(name)
            print(f'FAIL: {name}: expected {expected!r}, got {diagnostics!r}')
if failed:
    raise SystemExit(f'{len(failed)} adapter cases failed: {", ".join(failed)}')
print(f'PASS: {len(cases)} adapter CLI cases; all input files unchanged')
PY
