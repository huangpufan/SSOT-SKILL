#!/usr/bin/env python3
"""Regression tests for skills/ssot-doctor/assets/scripts/ssot-check.py.

Each test builds a small SSOT/ tree in a temporary directory, runs the real
checker as a subprocess, and asserts on its exit code and output. Run:
    python3 tests/test-ssot-check.py
"""

import hashlib
import os
import subprocess
import sys
import tempfile
import textwrap
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHECKER = os.path.join(ROOT, "skills", "ssot-doctor", "assets", "scripts", "ssot-check.py")

README = """\
---
ssot_format: 3
language: en
---

# Demo

Demo is a tiny service.

## Map

- [Architecture](architecture.md)

## Invariants

| ID | Kind | Rule | Explained in | Status | Source |
|---|---|---|---|---|---|
| INV-01 | product promise | A retry never charges twice | [Retries](architecture.md#failure-and-recovery) | confirmed | user, 2026-05-02 |

## Open questions

None yet.
"""

ARCHITECTURE = """\
# Architecture

## Failure and recovery

Retries are idempotent.
"""


def tree_digest(path):
    digest = hashlib.sha256()
    for directory, subdirs, files in sorted(os.walk(path)):
        subdirs.sort()
        for name in sorted(files):
            full = os.path.join(directory, name)
            digest.update(full.encode())
            try:
                with open(full, "rb") as handle:
                    digest.update(handle.read())
            except PermissionError:  # unreadable fixture: size and mtime still reveal writes
                info = os.stat(full)
                digest.update(f"{info.st_size}:{info.st_mtime_ns}".encode())
        digest.update(directory.encode())
    return digest.hexdigest()


class CheckerTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = os.path.realpath(self.tmp.name)
        self.ssot = os.path.join(self.repo, "SSOT")
        os.makedirs(self.ssot)

    def tearDown(self):
        for directory, _, files in os.walk(self.repo):
            for name in files:
                os.chmod(os.path.join(directory, name), 0o644)
        self.tmp.cleanup()

    def write(self, relative, content, mode="w", encoding="utf-8"):
        path = os.path.join(self.ssot, relative)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        if mode == "wb":
            with open(path, "wb") as handle:
                handle.write(content)
        else:
            with open(path, "w", encoding=encoding) as handle:
                handle.write(textwrap.dedent(content))
        return path

    def valid(self):
        self.write("README.md", README)
        self.write("architecture.md", ARCHITECTURE)

    def run_checker(self, *args):
        before = tree_digest(self.repo)
        result = subprocess.run([sys.executable, CHECKER, *(args or [self.ssot])],
                                capture_output=True, text=True, cwd=self.repo)
        self.assertEqual(before, tree_digest(self.repo), "checker must never write")
        return result.returncode, result.stdout + result.stderr

    def assert_clean(self):
        code, out = self.run_checker()
        self.assertEqual(code, 0, out)
        self.assertNotIn("ERROR", out)
        return out

    def assert_error(self, fragment):
        code, out = self.run_checker()
        self.assertEqual(code, 1, out)
        self.assertIn(fragment, out)
        self.assertIn("ssot-check: FAIL - ", out)
        return out

    # --- entry point and format marker ---------------------------------
    def test_valid_tree_passes(self):
        self.valid()
        out = self.assert_clean()
        self.assertIn("ssot-check: PASS - 0 error(s), 0 warning(s)", out)

    def test_missing_readme(self):
        self.write("architecture.md", ARCHITECTURE)
        self.assert_error("missing SSOT/README.md")

    def test_missing_format_marker(self):
        self.write("README.md", "# Demo\n")
        self.assert_error("ssot_format: 3")

    def test_missing_language(self):
        self.write("README.md", README.replace("language: en\n", ""))
        self.write("architecture.md", ARCHITECTURE)
        self.assert_error("language:")

    def test_v2_layout_is_reported_not_failed(self):
        self.write("README.md", "# Old\n")
        self.write("STATUS.md", "# Status\n")
        out = self.assert_clean()
        self.assertIn("v2 layout", out)

    def test_v2_ledger_left_after_migration_warns(self):
        self.valid()
        self.write("HISTORY.md", "# History\n")
        out = self.assert_clean()
        self.assertIn("v2 ledger left after migration", out)

    def test_bootstrap_progress_is_reported(self):
        self.valid()
        self.write("BOOTSTRAP.md", "# SSOT setup in progress\n")
        self.assertIn("bootstrap is unfinished", self.assert_clean())

    def test_help_and_usage_errors(self):
        code, out = self.run_checker("--help")
        self.assertEqual(code, 0, out)
        self.assertIn("Usage", out)
        code, out = self.run_checker("a", "b")
        self.assertEqual(code, 2, out)

    def test_missing_directory_is_usage_error(self):
        code, out = self.run_checker(os.path.join(self.repo, "nope"))
        self.assertEqual(code, 2, out)

    # --- links and anchors ------------------------------------------------
    def test_broken_file_link(self):
        self.valid()
        self.write("gotchas.md", "# Gotchas\n\nSee [the guide](missing.md).\n")
        self.assert_error("broken link: missing.md")

    def test_broken_anchor(self):
        self.valid()
        self.write("gotchas.md", "# Gotchas\n\nSee [retries](architecture.md#no-such-heading).\n")
        self.assert_error("missing heading anchor")

    def test_github_slugs_for_cjk_punctuation_and_duplicates(self):
        self.valid()
        self.write("zh.md", """\
            # 中文

            ## GOT-0015：Codex 正文 text chunk 不是 Markdown 段落

            ## Current / 当前存在

            ## Notes

            ## Notes
            """)
        self.write("links.md", """\
            # Links

            [a](zh.md#got-0015codex-正文-text-chunk-不是-markdown-段落)
            [b](zh.md#current--当前存在)
            [c](zh.md#notes-1)
            [d](zh.md#%E4%B8%AD%E6%96%87)
            """)
        self.assert_clean()

    def test_truncated_cjk_anchor_is_caught(self):
        self.valid()
        self.write("zh.md", "# 中文\n\n## 不是 Markdown 段落或完整消息\n")
        self.write("links.md", "# Links\n\n[a](zh.md#不是-markdown-段落)\n")
        self.assert_error("missing heading anchor")

    def test_link_forms(self):
        self.valid()
        os.makedirs(os.path.join(self.ssot, "notes"))
        self.write("notes/a(b).md", "# A\n")
        self.write("forms.md", """\
            # Forms

            [parens](notes/a(b).md) [dq](architecture.md "title") [angle](<architecture.md>)
            """)
        self.assert_clean()
        self.write("forms.md", "# Forms\n\n[sq](missing.md 'title')\n")
        self.assert_error("broken link: missing.md")

    def test_link_after_a_multiline_comment_is_checked(self):
        self.valid()
        self.write("notes.md", "# Notes\n\n<!-- start\nhidden [x](ignored.md)\n--> [y](missing.md)\n")
        out = self.assert_error("broken link: missing.md")
        self.assertNotIn("ignored.md", out)

    def test_heading_anchors_ignore_comments_and_include_setext(self):
        self.valid()
        self.write("target.md", "# Target\n\n<!--\n# Hidden\n-->\n\nSetext Title\n============\n\n| a | b |\n|---|---|\n")
        self.write("links.md", "# Links\n\n[ok](target.md#setext-title)\n")
        self.assert_clean()
        self.write("links.md", "# Links\n\n[bad](target.md#hidden)\n")
        self.assert_error("missing heading anchor")

    def test_backslash_escapes_in_links(self):
        self.valid()
        self.write("notes.md", "# Notes\n\n[arch](architecture\\.md)\n")
        self.assert_clean()

    def test_reviewed_through_outside_git_is_incomplete(self):
        self.valid()
        self.write("README.md", README.replace("language: en\n", "language: en\nreviewed_through: abcdef1\n"))
        code, out = self.run_checker()
        self.assertEqual(code, 3, out)
        self.assertIn("not inside a git work tree", out)

    def test_comment_opener_inside_inline_code_is_text(self):
        self.valid()
        self.write("gotchas.md", "# Gotchas\n\nMermaid rejects `<!--` comments.\n\n[missing](does-not-exist.md)\n")
        self.assert_error("broken link: does-not-exist.md")

    def test_footnotes_are_not_links(self):
        self.valid()
        self.write("research.md", "# Research\n\nSee the test.[^1]\n\n[^1]: See the 2026 load test in PR 812.\n")
        self.assert_clean()

    def test_bom_and_emphasis_in_headings(self):
        self.write("README.md", "\ufeff" + README)
        self.write("architecture.md", ARCHITECTURE + "\n## The _important_ part\n")
        self.write("links.md", "# L\n\n[x](architecture.md#the-important-part)\n")
        self.assert_clean()

    def test_link_leaving_the_repository_warns(self):
        self.valid()
        self.write("notes.md", "# Notes\n\n[sibling](../../other-repo/WORK.md)\n")
        self.assertIn("link leaves the repository", self.assert_clean())

    def test_links_in_code_are_ignored(self):
        self.valid()
        self.write("notes.md", "# Notes\n\n`[x](missing.md)`\n\n```\n[y](missing.md)\n```\n")
        self.assert_clean()

    def test_external_and_repo_links(self):
        self.valid()
        os.makedirs(os.path.join(self.repo, "src"))
        with open(os.path.join(self.repo, "src", "app.py"), "w") as handle:
            handle.write("print(1)\n")
        self.write("notes.md", "# Notes\n\n[site](https://example.com) [code](../src/app.py)\n")
        self.assert_clean()

    def test_line_anchor_warns_or_fails_past_end(self):
        self.valid()
        self.write("notes.md", "# Notes\n\n[ok](architecture.md#L3) [bad](architecture.md#L99)\n")
        out = self.assert_error("line anchor past end of file")
        self.assertIn("line anchors drift", out)

    # --- invariants register ----------------------------------------------
    def invariant_row(self, row):
        self.write("README.md", README.replace(
            "| INV-01 | product promise | A retry never charges twice | [Retries](architecture.md#failure-and-recovery) | confirmed | user, 2026-05-02 |",
            row))
        self.write("architecture.md", ARCHITECTURE)

    def test_bad_invariant_status(self):
        self.invariant_row("| INV-01 | process rule | Rule | [R](architecture.md) | approved | user |")
        self.assert_error("must be confirmed, candidate, or retired")

    def test_duplicate_invariant_id(self):
        self.invariant_row("| INV-01 | process rule | A | [R](architecture.md) | confirmed | user |\n"
                           "| INV-01 | process rule | B | [R](architecture.md) | candidate | inferred |")
        self.assert_error("duplicate invariant ID INV-01")

    def test_invariant_needs_link_and_source(self):
        self.invariant_row("| INV-02 |  | Rule | see code | confirmed |  |")
        out = self.assert_error("needs a link")
        self.assertIn("needs a source", out)
        self.assertIn("needs a kind", out)

    def test_invariant_explained_outside_ssot_fails(self):
        with open(os.path.join(self.repo, "AGENTS.md"), "w") as handle:
            handle.write("# Agents\n")
        self.invariant_row("| INV-01 | process rule | Rule | [AGENTS](../AGENTS.md) | confirmed | user |")
        self.assert_error("must live inside SSOT/")

    def test_invariant_anchor_in_readme_is_inside_ssot(self):
        self.invariant_row("| INV-01 | process rule | Rule | [Below](#open-questions) | confirmed | user |")
        self.assert_clean()

    def test_escaped_pipe_in_cell(self):
        self.invariant_row(r"| INV-01 | process rule | Use a \| b only | [R](architecture.md) | confirmed | user |")
        self.assert_clean()

    def test_commented_example_rows_are_ignored(self):
        self.invariant_row("<!-- | INV-9 | example | x | maybe | |  -->")
        self.assert_clean()

    def test_wrong_column_count_is_rejected(self):
        self.write("README.md", README.replace(
            "| ID | Kind | Rule | Explained in | Status | Source |\n|---|---|---|---|---|---|",
            "| ID | Kind | Rule | Explained in | Status | Source | Extra |\n|---|---|---|---|---|---|---|"))
        self.write("architecture.md", ARCHITECTURE)
        self.assert_error("needs 6 columns")

    def test_backticked_id_and_status_are_valid(self):
        self.invariant_row("| `INV-01` | process rule | Rule | [R](architecture.md) | `confirmed` | user |")
        self.assert_clean()

    def test_missing_separator_row_is_an_error(self):
        self.write("README.md", README.replace("|---|---|---|---|---|---|\n", ""))
        self.write("architecture.md", ARCHITECTURE)
        self.assert_error("needs a separator row")

    def test_four_backtick_fence_hides_inner_fences(self):
        self.valid()
        self.write("notes.md", "# Notes\n\n````markdown\n```\n[x](missing.md)\n```\n[y](missing.md)\n````\n")
        self.assert_clean()

    def test_invariant_table_under_a_subheading_is_checked(self):
        self.write("README.md", README.replace(
            "| ID | Kind | Rule |", "### Delivery\n\n| ID | Kind | Rule |").replace("| confirmed | user, 2026-05-02 |",
                                                                          "| maybe | user, 2026-05-02 |"))
        self.write("architecture.md", ARCHITECTURE)
        self.assert_error("must be confirmed, candidate, or retired")

    def test_invariant_explanation_via_symlink_outside_ssot_fails(self):
        outside = os.path.join(self.repo, "outside")
        os.makedirs(outside)
        with open(os.path.join(outside, "rules.md"), "w") as handle:
            handle.write("# Rules\n")
        os.symlink(outside, os.path.join(self.ssot, "linked"))
        self.invariant_row("| INV-01 | process rule | Rule | [R](linked/rules.md) | confirmed | user |")
        self.assert_error("must live inside SSOT/")

    def test_invariant_table_without_outer_pipes_is_checked(self):
        self.write("README.md", README.replace(
            "| ID | Kind | Rule | Explained in | Status | Source |\n|---|---|---|---|---|---|\n"
            "| INV-01 | product promise | A retry never charges twice | [Retries](architecture.md#failure-and-recovery) | confirmed | user, 2026-05-02 |",
            "ID | Kind | Rule | Explained in | Status | Source\n---|---|---|---|---|---\n"
            "INV-01 | process rule | R | [R](architecture.md) | nonsense | user"))
        self.write("architecture.md", ARCHITECTURE)
        self.assert_error("must be confirmed, candidate, or retired")

    def test_separator_must_match_header_width(self):
        self.write("README.md", README.replace("|---|---|---|---|---|---|", "|---|---|"))
        self.write("architecture.md", ARCHITECTURE)
        self.assert_error("needs a separator row")

    def test_numbered_invariants_heading_is_still_checked(self):
        self.write("README.md", README.replace("## Invariants", "## 4. Invariants").replace(
            "| confirmed | user, 2026-05-02 |", "| approved-by-bot | user, 2026-05-02 |"))
        self.write("architecture.md", ARCHITECTURE)
        self.assert_error("must be confirmed, candidate, or retired")

    def test_list_shaped_register_is_an_error(self):
        self.write("README.md", README.split("## Invariants")[0] +
                   "## Invariants\n\n- INV-01 (approved by bot): see [AGENTS](architecture.md)\n")
        self.write("architecture.md", ARCHITECTURE)
        self.assert_error("must be written as a table")

    def test_reference_style_explanation_link(self):
        self.invariant_row("| INV-01 | process rule | Rule | [R][arch] | confirmed | user |")
        self.write("README.md", (self.ssot and open(os.path.join(self.ssot, "README.md")).read())
                   + "\n[arch]: architecture.md\n")
        self.assert_clean()

    def test_missing_invariants_section_warns(self):
        self.write("README.md", README.split("## Invariants")[0])
        self.write("architecture.md", ARCHITECTURE)
        self.assertIn("no Invariants section", self.assert_clean())

    # --- reviewed_through --------------------------------------------------
    def test_reviewed_through_placeholder_warns(self):
        self.valid()
        self.write("README.md", README.replace("language: en\n", "language: en\nreviewed_through: <commit>\n"))
        self.assertIn("template placeholder", self.assert_clean())

    def test_reviewed_through_must_exist(self):
        self.valid()
        subprocess.run(["git", "init", "-q", self.repo], check=True)
        subprocess.run(["git", "-C", self.repo, "-c", "user.name=t", "-c", "user.email=t@t", "add", "-A"], check=True)
        subprocess.run(["git", "-C", self.repo, "-c", "user.name=t", "-c", "user.email=t@t",
                        "commit", "-q", "-m", "init"], check=True)
        head = subprocess.run(["git", "-C", self.repo, "rev-parse", "--short", "HEAD"],
                              capture_output=True, text=True, check=True).stdout.strip()
        self.write("README.md", README.replace("language: en\n", f"language: en\nreviewed_through: {head}\n"))
        self.assertNotIn("reviewed_through", self.assert_clean())
        self.write("README.md", README.replace("language: en\n", "language: en\nreviewed_through: deadbeef\n"))
        self.assertIn("is not a commit in this repository", self.assert_clean())

    def test_reviewed_through_rejects_moving_refs_and_strips_comments(self):
        self.valid()
        self.write("README.md", README.replace("language: en\n", "language: en\nreviewed_through: HEAD\n"))
        self.assert_error("must be a commit SHA")
        self.write("README.md", README.replace("language: en\n", "language: en\nreviewed_through: <commit>  # optional\n"))
        self.assertIn("template placeholder", self.assert_clean())

    def test_reviewed_through_off_the_current_history_warns(self):
        self.valid()
        run = lambda *a: subprocess.run(["git", "-C", self.repo, "-c", "user.name=t", "-c", "user.email=t@t", *a],
                                        capture_output=True, text=True, check=True).stdout.strip()
        run("init", "-q")
        run("add", "-A")
        run("commit", "-q", "-m", "one")
        run("checkout", "-q", "-b", "side")
        self.write("gotchas.md", "# Gotchas\n")
        run("add", "-A")
        run("commit", "-q", "-m", "side")
        side = run("rev-parse", "--short", "HEAD")
        run("checkout", "-q", "-")
        self.write("README.md", README.replace("language: en\n", f"language: en\nreviewed_through: {side}\n"))
        self.assertIn("not an ancestor of HEAD", self.assert_clean())

    # --- budgets, encoding, and tool failures -----------------------------
    def test_budget_counts_characters_not_bytes(self):
        self.valid()
        self.write("README.md", README.replace("Demo is a tiny service.", "中" * 3000))
        self.assertNotIn("reading budget", self.assert_clean())
        self.write("README.md", README.replace("Demo is a tiny service.", "中" * 9000))
        self.assertIn("reading budget", self.assert_clean())

    def test_readme_budget_does_not_count_invariant_rows(self):
        rows = "\n".join(f"| INV-{n:02d} | process rule | {'规则说明' * 40} | [R](architecture.md) | confirmed | user |"
                         for n in range(1, 60))
        self.invariant_row(rows)
        self.assertNotIn("reading budget", self.assert_clean())

    def test_undecodable_file_warns_without_crashing(self):
        self.valid()
        self.write("latin.md", "# Caf\xe9\n".encode("latin-1"), mode="wb")
        self.assertIn("not valid UTF-8", self.assert_clean())

    @unittest.skipIf(hasattr(os, "geteuid") and os.geteuid() == 0, "root can read unreadable directories")
    def test_unreadable_directory_is_not_a_pass(self):
        self.valid()
        self.write("private/notes.md", "# Notes\n\n[x](missing.md)\n")
        os.chmod(os.path.join(self.ssot, "private"), 0)
        try:
            code, out = self.run_checker()
        finally:
            os.chmod(os.path.join(self.ssot, "private"), 0o755)
        self.assertEqual(code, 3, out)
        self.assertIn("UNCHECKED", out)
        self.assertIn("ssot-check: INCOMPLETE - ", out)
        self.assertNotIn("ssot-check: PASS", out)

    def test_multi_part_invariant_ids_are_valid(self):
        self.invariant_row("| CLAUDE-MAXIM-1 | process rule | Rule | [R](architecture.md) | confirmed | user |\n"
                           "| CORE-RULE-2 | process rule | Rule | [R](architecture.md) | confirmed | user |")
        self.assert_clean()

    def test_invariant_columns_must_be_in_order(self):
        self.write("README.md", README.replace("| ID | Kind | Rule | Explained in | Status | Source |",
                                               "| ID | Kind | Rule | Explained in | Source | Status |"))
        self.write("architecture.md", ARCHITECTURE)
        self.assert_error("columns must be, in order")

    def test_chinese_invariant_headers_are_accepted(self):
        self.write("README.md", README.replace("| ID | Kind | Rule | Explained in | Status | Source |",
                                               "| ID | 类型 | 规则 | 解释位置 | 状态 | 来源 |"))
        self.write("architecture.md", ARCHITECTURE)
        self.assert_clean()

    def test_git_failure_is_not_reported_as_a_missing_commit(self):
        self.valid()
        subprocess.run(["git", "init", "-q", self.repo], check=True)
        self.write("README.md", README.replace("language: en\n", "language: en\nreviewed_through: deadbeef\n"))
        broken = os.path.join(self.repo, "broken-gitconfig")
        with open(broken, "w") as handle:
            handle.write("[core\n")
        before = tree_digest(self.repo)
        result = subprocess.run([sys.executable, CHECKER, self.ssot], capture_output=True, text=True,
                                env=dict(os.environ, GIT_CONFIG_GLOBAL=broken))
        self.assertEqual(before, tree_digest(self.repo))
        self.assertNotIn("is not a commit", result.stdout)
        self.assertEqual(result.returncode, 3, result.stdout)

    def test_query_string_is_not_part_of_the_path(self):
        self.valid()
        self.write("notes.md", "# Notes\n\n[raw](architecture.md?plain=1#failure-and-recovery)\n")
        self.assert_clean()

    @unittest.skipIf(hasattr(os, "geteuid") and os.geteuid() == 0, "root can read unreadable files")
    def test_tool_failure_has_its_own_exit_code(self):
        self.valid()
        path = self.write("locked.md", "# Locked\n")
        os.chmod(path, 0)
        code, out = self.run_checker()
        self.assertEqual(code, 3, out)
        self.assertIn("ssot-check: INCOMPLETE - ", out)


if __name__ == "__main__":
    unittest.main(verbosity=1)
