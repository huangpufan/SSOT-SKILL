#!/usr/bin/env python3
"""Exercise the installed STATUS migration command against consumer documents."""

import datetime
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


MIGRATE = Path(os.environ.get(
    "SSOT_STATUS_MIGRATOR",
    Path(__file__).resolve().parents[1] / "skills/ssot-doctor/assets/scripts/ssot-migrate.py",
))


class StatusMigrationTests(unittest.TestCase):
    def setUp(self):
        self.work = tempfile.TemporaryDirectory()
        self.addCleanup(self.work.cleanup)
        self.root = Path(self.work.name) / "SSOT"
        self.root.mkdir()
        self.status = self.root / "STATUS.md"

    def run_migration(self, source=None, *args):
        if source is not None:
            self.status.write_text(source, encoding="utf-8")
        result = subprocess.run(
            ["python3", str(MIGRATE), str(self.root), *args],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return self.status.read_text(encoding="utf-8")

    def table_rows(self, text, columns):
        lines = [line for line in text.splitlines() if line.startswith("|")]
        rows = [[cell.strip() for cell in line[1:-1].split("|")] for line in lines]
        for row in rows:
            self.assertEqual(len(row), columns, f"Malformed Markdown table: {lines}")
        return [dict(zip(rows[0], row)) for row in rows[2:]]

    def test_capture_keeps_proposed_and_responsible_owners_distinct(self):
        text = self.run_migration(
            "## Pending Captures\n\n"
            "| Source | Proposed owner | Responsible owner | Reason | Priority | State |\n"
            "|---|---|---|---|---|---|\n"
            "| session-1 | [dev](development/README.md) | Alice | retry rule | high | pending |\n"
        )
        row = self.table_rows(text, 8)[0]
        self.assertEqual(row["Proposed owner"], "[dev](development/README.md)")
        self.assertEqual(row["Responsible owner"], "Alice")
        self.assertEqual(row["Reason"], "retry rule")

    def test_capture_with_named_legacy_id_preserves_name(self):
        text = self.run_migration(
            "## Pending Captures\n\n"
            "| ID | Source | Reason |\n|---|---|---|\n"
            "| retry rule | session-1 | capture the rule |\n"
        )
        row = self.table_rows(text, 8)[0]
        self.assertRegex(row["ID"], r"^CAP-\d{8}-\d{2}$")
        self.assertIn("retry rule", row["Reason"])
        self.assertIn("capture the rule", row["Reason"])

    def test_review_keeps_scope_and_result_in_their_columns(self):
        text = self.run_migration(
            "## Stop Review Gate\n\n"
            "| Scope | Claim | Reviewer | Result |\n|---|---|---|---|\n"
            "| product | covered | reader-1 | no-more-required-changes |\n"
        )
        row = self.table_rows(text, 9)[0]
        self.assertEqual(row["Scope"], "product")
        self.assertEqual(row["Result"], "no-more-required-changes")
        self.assertEqual(row["Evidence"], "")

    def test_localized_columns_keep_their_meaning_when_reordered(self):
        text = self.run_migration(
            "## 待捕获项\n\n"
            "| 状态 | 来源 | 建议所有者 | 责任所有者 | 原因 | 优先级或触发条件 |\n"
            "|---|---|---|---|---|---|\n"
            "| pending | session-1 | 开发规范 | 张三 | 重试约定 | 再次超时 |\n"
        )
        row = self.table_rows(text, 8)[0]
        self.assertEqual(row["Proposed owner"], "开发规范")
        self.assertEqual(row["Responsible owner"], "张三")
        self.assertEqual(row["Priority / trigger"], "再次超时")

    def test_empty_section_does_not_consume_next_sections_table(self):
        source = (
            "## Open Gaps\n\nNo gaps.\n\n"
            "## Unrelated register\n\n| Name | Detail |\n|---|---|\n"
            "| billing | keep exactly |\n"
        )
        self.assertEqual(self.run_migration(source), source)

    def test_examples_in_fences_are_unchanged(self):
        source = (
            "# Examples\n\n```markdown\n## Open Gaps\n\n"
            "| Scope | Question |\n|---|---|\n| sample | example only |\n```\n"
            "\n## Open Gaps\n\n~~~markdown\n"
            "| Scope | Question |\n|---|---|\n| sample | example only |\n~~~\n"
        )
        self.assertEqual(self.run_migration(source), source)

    def test_generated_ids_do_not_collide_with_existing_rows(self):
        today = datetime.date.today().strftime("%Y%m%d")
        existing_id = f"GAP-{today}-01"
        text = self.run_migration(
            "## Open Gaps\n\n| ID | Scope | Question |\n|---|---|---|\n"
            f"| temporary | product | missing proof |\n| {existing_id} | runtime | timeout |\n"
        )
        rows = self.table_rows(text, 8)
        self.assertEqual(rows[1]["ID"], existing_id)
        self.assertNotEqual(rows[0]["ID"], existing_id)
        self.assertIn("temporary", rows[0]["Affected scope / task"])

    def test_id_and_escaped_pipe_content_survive_migration(self):
        text = self.run_migration(
            "## Open Gaps\n\n| ID | Scope | Question | Owner |\n|---|---|---|---|\n"
            "| `GAP-20260901-01` | product | `ready\\|waiting` | [dev](development/README.md) |\n"
        )
        self.assertIn("GAP-20260901-01", text)
        self.assertIn("| `ready\\|waiting` | [dev](development/README.md) |", text)
        self.assertNotIn("GAP-" + datetime.date.today().strftime("%Y%m%d"), text)

    def test_plain_owner_is_not_invented_as_a_resolving_route(self):
        text = self.run_migration(
            "## Open Gaps\n\n| Scope | Question | Owner |\n|---|---|---|\n"
            "| product | missing proof | Alice |\n"
        )
        row = self.table_rows(text, 8)[0]
        self.assertEqual(row["Responsible owner"], "Alice")
        self.assertEqual(row["Resolving route"], "")

    def test_link_owner_can_fill_legacy_route_and_second_run_is_exact_noop(self):
        text = self.run_migration(
            "## Open Gaps\n\n| Scope | Question | Owner | Extra |\n|---|---|---|---|\n"
            "| product | missing proof | [dev](development/README.md) | retained detail |\n"
        )
        row = self.table_rows(text, 8)[0]
        self.assertEqual(row["Responsible owner"], "[dev](development/README.md)")
        self.assertEqual(row["Resolving route"], row["Responsible owner"])
        self.assertIn("retained detail", row["Question / missing evidence"])
        before = {p.name: p.read_bytes() for p in self.root.iterdir()}
        self.run_migration()
        self.assertEqual(before, {p.name: p.read_bytes() for p in self.root.iterdir()})

    def test_dry_run_does_not_write_status_records_or_history(self):
        source = "## Open Gaps\n\n| Scope | Question |\n|---|---|\n| product | proof |\n"
        record = self.root / "04-records/decisions/0001-choice.md"
        record.parent.mkdir(parents=True)
        record.write_text("# Decision\n\nKeep this evidence.\n", encoding="utf-8")
        before = record.read_bytes()
        self.assertEqual(self.run_migration(source, "--dry-run"), source)
        self.assertEqual(record.read_bytes(), before)
        self.assertFalse((self.root / "HISTORY.md").exists())

    def test_existing_canonical_localized_table_is_unchanged(self):
        source = (
            "## 开放缺口\n\n"
            "| ID | 状态 | 影响范围 | 问题 | 负责人 | 阻断条件 | 解决路径 | 闭合或替代证据 |\n"
            "|---|---|---|---|---|---|---|---|\n"
            "| GAP-20260901-01 | gap | 产品 | 缺证据 | 张三 | 发布前 | $ssot-doctor | none: open |\n"
        )
        self.assertEqual(self.run_migration(source), source)

    def test_canonical_header_with_old_separator_is_repaired(self):
        source = (
            "## Pending Captures\n\n"
            "| ID | Source | Proposed owner | Reason | Priority / trigger | Responsible owner | State | Closure evidence |\n"
            "|---|---|---|\n"
            "| CAP-20260901-01 | session-1 | dev | retry rule | high | Alice | pending | none: open |\n"
        )
        row = self.table_rows(self.run_migration(source), 8)[0]
        self.assertEqual(row["ID"], "CAP-20260901-01")
        self.assertEqual(row["Reason"], "retry rule")

    def test_id_exhaustion_fails_without_partial_writes(self):
        today = datetime.date.today().strftime("%Y%m%d")
        source = "## Open Gaps\n\n| ID | Scope | Question |\n|---|---|---|\n"
        source += "".join(f"| GAP-{today}-{n:02d} | product | proof |\n" for n in range(1, 100))
        source += "| new gap | runtime | timeout |\n"
        self.status.write_text(source, encoding="utf-8")
        result = subprocess.run(["python3", str(MIGRATE), str(self.root)], capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("ID", result.stderr)
        self.assertEqual(self.status.read_text(encoding="utf-8"), source)
        self.assertFalse((self.root / "HISTORY.md").exists())

    def test_invalid_directory_and_conflicting_modes_fail_before_writes(self):
        for args in ((str(self.root / "absent"), "--dry-run"),
                     (str(self.root), "--status-only", "--records-only")):
            with self.subTest(args=args):
                result = subprocess.run(["python3", str(MIGRATE), *args], capture_output=True, text=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse((self.root / "HISTORY.md").exists())

    def test_record_backfill_preserves_body_existing_values_and_history(self):
        body = "# Chosen approach\n\nEvidence and rationale stay here.\n"
        record = self.root / "04-records/decisions/0001-choice.md"
        record.parent.mkdir(parents=True)
        record.write_text("---\nid: DEC-0001\nimplementation_state: implemented\n---\n" + body, encoding="utf-8")
        history = self.root / "HISTORY.md"
        history.write_text("Existing append-only history\n", encoding="utf-8")
        self.run_migration("# Status\n", "--status-only")
        self.assertNotIn("record_status:", record.read_text(encoding="utf-8"))
        self.run_migration(None, "--records-only")
        text = record.read_text(encoding="utf-8")
        self.assertIn("id: DEC-0001\n", text)
        self.assertIn("implementation_state: implemented\n", text)
        self.assertIn("record_status: active\n", text)
        self.assertTrue(text.endswith(body))
        self.assertEqual(history.read_text(encoding="utf-8"), "Existing append-only history\n")


if __name__ == "__main__":
    unittest.main()
