"""Exercise register boundaries through the actual lint CLI, without claiming
that these deliberately incomplete consumers pass semantic reader review.
"""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(os.environ.get('SSOT_TEST_ROOT', Path(__file__).resolve().parents[1]))
LINT = ROOT / 'skills/ssot-doctor/assets/scripts/ssot-lint.sh'
AREAS = {
    'product': '01-product', 'architecture': '02-architecture',
    'process': '03-process', 'records': '04-records', 'glossary': 'glossary',
    **{name: f'03-process/{name}' for name in (
        'development', 'testing', 'benchmark', 'deployment', 'release',
        'operations', 'security-and-compliance')},
    **{name: f'04-records/{name}' for name in (
        'decisions', 'gotchas', 'bugs', 'tech-debt')},
    'research records': '04-records/research',
}


class LintBoundaryTest(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.ssot = Path(temporary.name) / 'SSOT'
        self.ssot.mkdir()
        (self.ssot / 'README.md').write_text('# Repository\n\nReview fixture.\n')
        for path in AREAS.values():
            owner = self.ssot / path / 'README.md'
            owner.parent.mkdir(parents=True, exist_ok=True)
            owner.write_text('# Owner\n\nThis page routes work in its own area.\n\n'
                             'It provides a stable route for the register checks.\n')
        (self.ssot / '.bootstrap').mkdir()
        (self.ssot / '.bootstrap/review.md').write_text('# Scoped review fixture\n')
        self.extra = []
        self.overrides = {}
        self.depths = {}
        self.reviews = []

    def route(self, area):
        return f'[Owner]({AREAS[area.split("/")[0]]}/README.md)'

    def lint(self):
        rows = [(area, self.overrides.get(area, 'gap'), self.route(area))
                for area in AREAS] + self.extra
        text = '''# Status

| Field | Value |
|---|---|
| tracked_commit | none |
| tracked_session | none |
| tracked_skill_version | `2.80` |
| documentation_language | en |
| documentation_language_evidence | README.md |
| coverage_result | in_progress |

## Area Status

| Area | Status | Notes | Coverage depth |
|---|---|---|---|
'''
        for area, status, note in rows:
            text += f'| {area} | {status} | {note} | {self.depths.get(area, "")} |\n'
        text += '''
## Stop Review Gate

| Scope | Stop claim | Reviewer | Reviewer role | Reviewed at | Result | Evidence | Remaining changes | Authorises |
|---|---|---|---|---|---|---|---|---|
'''
        for area, state in self.reviews:
            text += (f'| {area} | {state} | fixture | scoped-self-review | 2026-10-03 | '
                     'no-more-required-changes | [Review](.bootstrap/review.md) | none | '
                     f'area:{area}:{state} |\n')
        (self.ssot / 'STATUS.md').write_text(text)
        before = {p: p.read_bytes() for p in self.ssot.rglob('*.md')}
        result = subprocess.run(['bash', str(LINT), '--json', str(self.ssot)],
                                capture_output=True, text=True, timeout=30)
        self.assertIn(result.returncode, (0, 1, 2), result.stderr)
        data = json.loads(result.stdout)
        self.assertEqual(before, {p: p.read_bytes() for p in self.ssot.rglob('*.md')})
        return data

    def area_failures(self):
        return [s for s in self.lint()['fails']
                if '[AREA-STATUS]' in s or '[STATUS-AGGREGATE]' in s
                or ('[STATUS-EXACT-SCHEMA]' in s and 'stop-review' in s)]

    def test_every_baseline_area_accepts_one_level_scope(self):
        self.extra = [(f'{area}/sample', 'gap', self.route(area)) for area in AREAS]
        self.assertEqual(self.area_failures(), [])

    def test_reviewed_scoped_claims_use_parent_owner(self):
        for state in ('partial', 'covered'):
            with self.subTest(state=state):
                self.extra = [('architecture/import', state, self.route('architecture'))]
                self.reviews = [('architecture/import', state)]
                self.assertEqual(self.area_failures(), [])

    def test_scoped_claim_requires_its_own_review(self):
        for state in ('partial', 'covered'):
            with self.subTest(state=state):
                self.extra = [('architecture/import', state, self.route('architecture'))]
                self.reviews = [('architecture', state)]
                self.assertTrue(any('scoped stop review' in s for s in self.area_failures()))

    def test_partial_scope_cannot_hide_missing_owner(self):
        (self.ssot / '02-architecture/README.md').unlink()
        self.extra = [('architecture/import', 'partial', '[Gap](README.md)')]
        self.reviews = [('architecture/import', 'partial')]
        self.assertTrue(any('canonical owner README' in s for s in self.area_failures()))

    def test_scoped_non_applicability_inherits_area_policy(self):
        self.extra = [('research records/survey', 'not_applicable',
                       'No research workflow in this scope; ' + self.route('research records'))]
        self.assertEqual(self.area_failures(), [])
        self.extra = [('architecture/import', 'not_applicable',
                       'No runtime found; ' + self.route('architecture'))]
        self.assertTrue(any('always-applicable' in s for s in self.area_failures()))

    def test_unknown_and_recursive_scopes_stay_invalid(self):
        self.extra = [(area, 'gap', '[Owner](README.md)') for area in (
            'architecture/import/leaf', 'invented/sample', 'x-extra/sample')]
        failures = self.area_failures()
        for area, _, _ in self.extra:
            self.assertTrue(any(f"unknown Area token '{area}'" in s for s in failures))

    def test_parent_cannot_outrun_a_gapped_scope(self):
        self.overrides['architecture'] = 'partial'
        self.extra = [('architecture/import', 'gap', self.route('architecture'))]
        self.assertTrue(any('weakest scoped-child' in s for s in self.area_failures()))

    def test_parent_depth_cannot_outrun_child(self):
        self.extra = [('architecture/import', 'gap', self.route('architecture'))]
        self.depths = {'architecture': 'deep', 'architecture/import': 'sampled'}
        self.assertTrue(any('deeper than' in s for s in self.area_failures()))

    def test_non_applicable_scope_is_neutral_for_covered_parent(self):
        self.overrides['testing'] = 'covered'
        self.depths['testing'] = 'deep'
        self.extra = [('testing/ui', 'not_applicable',
                       'No user interface; ' + self.route('testing'))]
        self.assertEqual(self.area_failures(), [])

    def test_non_applicable_parent_cannot_hide_applicable_scope(self):
        self.overrides['testing'] = 'not_applicable'
        self.extra = [('testing/cli', 'gap', self.route('testing'))]
        self.assertTrue(any('applicable or unresolved scope' in s for s in self.area_failures()))

    def test_documented_stop_claims_match_exact_register_schema(self):
        self.reviews = [('review-sample', claim) for claim in (
            'covered', 'partial', 'converged', 'passed', 'done', 'no-op',
            'single-level', 'stop-split', 'tracked_commit', 'tracked_session',
            'tracked_skill_version', 'protocol-upgrade', 'documentation_language')]
        self.assertEqual(self.area_failures(), [])
        self.reviews = [('review-sample', 'invented-claim')]
        self.assertTrue(any('invalid claim/role/result' in s for s in self.area_failures()))


if __name__ == '__main__':
    unittest.main()
