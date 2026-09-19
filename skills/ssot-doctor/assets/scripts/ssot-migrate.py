#!/usr/bin/env python3
"""ssot-migrate.py -- migrate legacy lean STATUS schemas to the canonical
v2.60+ Appendix-A schemas, backfill missing record frontmatter keys, and
create the v2.63 append-only SSOT/HISTORY.md header when absent.

Why this exists: exact-schema checks hard-fail every row of a legacy 5-6
column table, which reports one migration debt as dozens of content defects.
Run this first; re-lint; what remains is real content debt, not schema debt.

Usage:
  ssot-migrate.py SSOT_DIR [--dry-run] [--status-only] [--records-only]

Rules:
- Table headers are rewritten to the canonical schema; each data row's cells
  are remapped through a keyword classifier. Multiple source columns landing
  on one canonical column are joined with '; '; unmapped columns are preserved
  into the Question/Reason/Evidence sink, never dropped.
- Lifecycle sections get generated stable IDs (GAP/ADJ/CAP-<today>-NN) when a
  row lacks a valid pattern ID; the displaced name stays in Affected scope.
- When only one of Responsible owner / Resolving route is mapped and its
  cells carry Markdown links or $ssot-* routes, the value fills both columns
  (a legacy owner-route column serves both contract surfaces).
- Cells with no source stay empty: migration fixes *shape*; the remaining
  FAILs are honest content debt, which is the point of migrating.
"""
import argparse
import datetime
import os
import re
import sys

SEP_RE = re.compile(r'^\|[\s:|-]+(\|[\s:|-]+)+\|?\s*$')
ID_RE = {'open gaps': 'GAP', 'open adjudications': 'ADJ', 'pending captures': 'CAP'}
ID_OK = re.compile(r'^(GAP|ADJ|CAP|SRC)-\d{8}-\d{2}$')
LINK_RE = re.compile(r'^\[.*\]\(.*\)|^\$ssot-')

CANONICAL = {
    'open gaps': ['ID', 'State', 'Affected scope / task', 'Question / missing evidence',
                  'Responsible owner', 'Blocking / retrigger condition', 'Resolving route',
                  'Closure / supersession evidence'],
    'open adjudications': ['ID', 'State', 'Affected scope / task', 'Question / missing evidence',
                           'Responsible owner', 'Blocking / retrigger condition', 'Resolving route',
                           'Closure / supersession evidence'],
    'pending captures': ['ID', 'Source', 'Proposed owner', 'Reason', 'Priority / trigger',
                         'Responsible owner', 'State', 'Closure evidence'],
    'stop review gate': ['Scope', 'Stop claim', 'Reviewer', 'Reviewer role', 'Reviewed at',
                         'Result', 'Evidence', 'Remaining changes', 'Authorises'],
}
SECTION_ALIASES = {
    'open gaps': 'open gaps', '开放缺口': 'open gaps',
    'open adjudications': 'open adjudications', '开放裁决': 'open adjudications', '开放裁决项': 'open adjudications',
    'pending captures': 'pending captures', '待吸收捕获': 'pending captures', '待捕获项': 'pending captures',
    'stop review gate': 'stop review gate', '停止审查闸门': 'stop review gate',
}
SINK = {'open gaps': 'Question / missing evidence',
        'open adjudications': 'Question / missing evidence',
        'pending captures': 'Reason',
        'stop review gate': 'Evidence'}

COLUMN_KEYWORDS = [
    ('id', ['id', '编号', '标识', '序号']),
    ('state', ['state', 'status', '状态']),
    ('affected', ['affected', 'scope', 'task', '影响范围', '任务影响', '影响', '范围', '任务', '区域']),
    ('question', ['question', 'missing', '说明', '结果', '问题', '缺失', '描述']),
    ('owner', ['responsible', 'owner', '负责', '归属']),
    ('blocking', ['blocking', 'retrigger', '何时阻断', '阻断', '阻塞', '触发', 'next trigger']),
    ('route', ['route', 'resolving', '路由', '路径', '解决']),
    ('closure', ['closure', 'supersession', '关闭', '终结', '取代', '替代']),
    ('source', ['source', '来源']),
    ('proposed', ['proposed', '建议', '提议']),
    ('reason', ['reason', '原因', '理由']),
    ('priority', ['priority', '优先级']),
    ('claim', ['claim', 'stop claim', '声明']),
    ('reviewer_role', ['reviewer role', 'role', '角色']),
    ('reviewer', ['reviewer', '审查人']),
    ('reviewed', ['reviewed at', 'reviewed', '日期', '时间']),
    ('result', ['result', '结论']),
    ('evidence', ['evidence', '证据', 'artifact']),
    ('remaining', ['remaining', '剩余']),
    ('authorises', ['authorises', 'authorizes', '授权']),
]
CANON_TO_KEY = {
    'ID': 'id', 'State': 'state', 'Affected scope / task': 'affected',
    'Question / missing evidence': 'question', 'Responsible owner': 'owner',
    'Blocking / retrigger condition': 'blocking', 'Resolving route': 'route',
    'Closure / supersession evidence': 'closure', 'Closure evidence': 'closure', 'Source': 'source',
    'Proposed owner': 'proposed', 'Reason': 'reason', 'Priority / trigger': 'priority',
    'Scope': 'scope', 'Stop claim': 'claim', 'Reviewer': 'reviewer',
    'Reviewer role': 'reviewer_role', 'Reviewed at': 'reviewed', 'Result': 'result',
    'Evidence': 'evidence', 'Remaining changes': 'remaining', 'Authorises': 'authorises',
}

# Localized canonical headers: a table whose columns already carry the right
# semantics in the right positions is canonical — language does not make it
# legacy. Positional check: header at index i must alias canonical column i.
HEADER_ALIASES = {
    'ID': ['id', '编号'],
    'State': ['state', 'status', '状态'],
    'Affected scope / task': ['受影响范围或任务', '影响范围或任务', '影响范围', '区域或任务'],
    'Question / missing evidence': ['问题或缺失证据', '缺失证据', '问题'],
    'Responsible owner': ['责任所有者', '责任人', '负责人'],
    'Blocking / retrigger condition': ['阻断或复核触发条件', '阻断或触发条件', '阻断条件'],
    'Resolving route': ['解决路由', '解决路径'],
    'Closure / supersession evidence': ['闭合或取代证据', '闭合或替代证据'],
    'Closure evidence': ['闭合证据'],
    'Source': ['来源'],
    'Proposed owner': ['建议所有者', '建议归属'],
    'Reason': ['原因', '理由'],
    'Priority / trigger': ['优先级或触发条件', '优先级或触发'],
    'Scope': ['范围', '区域'],
    'Stop claim': ['停止结论', '停止声明', '停止主张'],
    'Reviewer': ['评审者', '审查者'],
    'Reviewer role': ['评审者角色', '审查者角色'],
    'Reviewed at': ['评审时间', '审查时间', '评审日期'],
    'Result': ['结果', '结论'],
    'Evidence': ['证据'],
    'Remaining changes': ['剩余改动', '剩余变更'],
    'Authorises': ['授权对象', '授权'],
}


def is_canonical_header(header_cells, canon_cols):
    if len(header_cells) != len(canon_cols):
        return False
    for cell, canon in zip(header_cells, canon_cols):
        low = cell.lower().strip('` ')
        if low != canon.lower() and low not in HEADER_ALIASES.get(canon, []):
            return False
    return True


def split_row(line):
    return [c.strip() for c in line.strip().strip('|').split('|')]


def classify_cell(cell):
    low = cell.lower().strip('` ')
    for key, words in COLUMN_KEYWORDS:
        for w in words:
            if low == w or low.startswith(w + ' ') or low.endswith(' ' + w):
                return key
    return None


def col_values(rows, idx):
    return [r[idx] for r in rows if idx < len(r) and r[idx]]


def migrate_section(lines, start, section, changes):
    canon_cols = CANONICAL[section]
    canon_keys = [CANON_TO_KEY[c] for c in canon_cols]
    header_idx = start
    while header_idx < len(lines) and not lines[header_idx].lstrip().startswith('|'):
        header_idx += 1
    if header_idx >= len(lines):
        return start
    header_cells = split_row(lines[header_idx])
    if is_canonical_header(header_cells, canon_cols):
        return header_idx + 1  # already canonical (any documentation language)

    # collect data rows (skip separators) until the table ends
    rows, end = [], header_idx + 1
    while end < len(lines):
        line = lines[end]
        if not line.lstrip().startswith('|'):
            break
        if not SEP_RE.match(line):
            cells = split_row(line)
            if any(cells):
                rows.append((end, cells))
        end += 1

    # assign each source column to a canonical key (first wins; extras join)
    col_to_key = [classify_cell(c) for c in header_cells]
    if 'id' not in col_to_key and 'id' in canon_keys and col_to_key and col_to_key[0] is None:
        # a name-like first column is scope content, not an ID
        col_to_key[0] = 'affected' if 'affected' not in col_to_key else 'question'
    # owner/route duality: if only one is present and its data is link-like,
    # the legacy column serves both contract surfaces
    if 'owner' in canon_keys and 'route' in canon_keys:
        for have, want in (('owner', 'route'), ('route', 'owner')):
            if have in col_to_key and want not in col_to_key:
                idx = col_to_key.index(have)
                vals = col_values([c for _, c in rows], idx)
                if vals and sum(1 for v in vals if LINK_RE.match(v)) * 2 >= len(vals):
                    col_to_key[idx] = want
                break
    prefix = ID_RE.get(section)
    today = datetime.date.today().strftime('%Y%m%d')
    seq = 0

    lines[header_idx] = '| ' + ' | '.join(canon_cols) + ' |'
    changes.append(f'{section}: header -> canonical {len(canon_cols)} columns')
    for line_idx, cells in rows:
        buckets = {k: [] for k in canon_keys}
        leftover = []
        for j, cell in enumerate(cells):
            k = col_to_key[j] if j < len(col_to_key) else None
            if k in buckets:
                if cell:
                    buckets[k].append(cell)
            elif cell:
                leftover.append(cell)
        out = {}
        for k, cname in zip(canon_keys, canon_cols):
            out[cname] = '; '.join(buckets[k])
        if leftover:
            sink = SINK[section]
            out[sink] = (out[sink] + '; ' if out[sink] else '') + '; '.join(leftover)
        # valid stable ID or generated one; displaced value goes to Affected
        if 'ID' in out:
            if not ID_OK.match(out['ID']):
                displaced = out['ID']
                seq += 1
                out['ID'] = f'{prefix}-{today}-{seq:02d}'
                if displaced:
                    aff = 'Affected scope / task'
                    out[aff] = (displaced + '; ' + out[aff]) if out[aff] else displaced
        # owner/route dual-fill
        if 'Responsible owner' in out and 'Resolving route' in out:
            if out['Responsible owner'] and not out['Resolving route']:
                out['Resolving route'] = out['Responsible owner']
            elif out['Resolving route'] and not out['Responsible owner']:
                out['Responsible owner'] = out['Resolving route']
        lines[line_idx] = '| ' + ' | '.join(out[c] for c in canon_cols) + ' |'
    return end


def migrate_status(path, dry_run):
    with open(path, encoding='utf-8') as f:
        lines = f.read().splitlines()
    i, changed = 0, []
    while i < len(lines):
        m = re.match(r'^##\s+(.+?)\s*$', lines[i])
        if m:
            sec = SECTION_ALIASES.get(m.group(1).lower(), SECTION_ALIASES.get(m.group(1)))
            if sec:
                i = migrate_section(lines, i + 1, sec, changed)
                continue
        i += 1
    if not changed:
        return False
    if not dry_run:
        with open(path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines) + '\n')
    return True


def file_date(path):
    try:
        return datetime.date.fromtimestamp(os.path.getmtime(path)).isoformat()
    except OSError:
        return '1970-01-01'


def read_frontmatter(path):
    with open(path, encoding='utf-8') as f:
        lines = f.read().splitlines()
    if not lines or lines[0].strip() != '---':
        return None, lines
    for j in range(1, len(lines)):
        if lines[j].strip() == '---':
            return lines[1:j], lines
    return None, lines


def fm_keys(fm):
    keys = set()
    for line in fm or []:
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):', line)
        if m:
            keys.add(m.group(1))
    return keys


def backfill_record(path, required, defaults, dry_run):
    fm, lines = read_frontmatter(path)
    present = fm_keys(fm)
    missing = [k for k in required if k not in present]
    if not missing:
        return False
    inserts = []
    for k in missing:
        v = defaults.get(k, 'unknown')
        if k == 'id':
            m = re.match(r'^(\d{4})', os.path.basename(path))
            v = m.group(1) if m else 'unknown'
        if k in ('created_on', 'updated_on'):
            v = file_date(path)
        inserts.append(f'{k}: {v}')
    if fm is None:
        new_lines = ['---'] + inserts + ['---'] + lines
    else:
        new_lines = ['---'] + fm + inserts + ['---'] + lines[len(fm) + 2:]
    if not dry_run:
        with open(path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(new_lines) + '\n')
    return True


HISTORY_HEADER = (
    '# SSOT History\n\n'
    '| Date | Commit | Actor | Result | Touched | Note |\n'
    '|---|---|---|---|---|---|\n'
)


def ensure_history(root, dry_run):
    path = os.path.join(root, 'HISTORY.md')
    if os.path.isfile(path):
        return False
    if not dry_run:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(HISTORY_HEADER)
    return True


DECISION_REQ = ['id', 'record_status', 'implementation_state', 'created_on', 'introduced_in', 'updated_on']
DECISION_DEF = {'record_status': 'active', 'implementation_state': 'pending',
                'introduced_in': '"unknown-migrated"'}
RESEARCH_REQ = ['id', 'record_status', 'adoption_state', 'kind', 'created_on', 'owner',
                'promotion_targets', 'recheck_trigger']
RESEARCH_DEF = {'record_status': 'draft', 'adoption_state': 'candidate', 'kind': 'poc',
                'owner': '"unknown-migrated"',
                'promotion_targets': '"not_applicable: migrated; review targets"',
                'recheck_trigger': '"manual review after migration"'}


def main():
    ap = argparse.ArgumentParser(description='Migrate legacy SSOT schemas to canonical v2.60+ shape.')
    ap.add_argument('ssot_dir')
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('--status-only', action='store_true')
    ap.add_argument('--records-only', action='store_true')
    a = ap.parse_args()
    root = a.ssot_dir.rstrip('/')
    status = os.path.join(root, 'STATUS.md')
    did = []
    if not a.records_only and os.path.isfile(status):
        if migrate_status(status, a.dry_run):
            did.append(f'{status}: rewrote non-canonical STATUS tables')
    if not a.records_only:
        if ensure_history(root, a.dry_run):
            did.append(f'{root}/HISTORY.md: created append-only batch log header')
    if not a.status_only:
        for sub, req, defs in ((('decisions',), DECISION_REQ, DECISION_DEF),
                               (('research',), RESEARCH_REQ, RESEARCH_DEF)):
            for base in (os.path.join(root, '04-records', *sub), os.path.join(root, *sub)):
                if not os.path.isdir(base):
                    continue
                for name in sorted(os.listdir(base)):
                    if not re.match(r'^\d{4}-.+\.md$', name):
                        continue
                    p = os.path.join(base, name)
                    if backfill_record(p, req, defs, a.dry_run):
                        did.append(f'{p}: backfilled missing frontmatter keys')
    mode = '[dry-run] ' if a.dry_run else ''
    if did:
        print(f'{mode}migration applied ({len(did)} change(s)):')
        for d in did:
            print(f'  - {d}')
        print('Review placeholder values marked unknown-migrated before re-lint.')
    else:
        print(f'{mode}nothing to migrate; schemas already canonical or absent')


if __name__ == '__main__':
    sys.exit(main())
