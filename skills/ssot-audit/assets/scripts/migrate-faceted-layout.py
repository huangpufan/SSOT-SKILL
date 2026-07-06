#!/usr/bin/env python3
"""Migrate a consumer SSOT directory to the canonical faceted layout.

The v2.57 physical layout is:

  SSOT/01-product/
  SSOT/02-architecture/
  SSOT/03-process/{development,testing,benchmark,deployment,release}/
  SSOT/04-records/{decisions,gotchas,bugs,tech-debt,research}/
  SSOT/glossary/

Legacy unnumbered top-level directories are still readable by older projects,
but protocol upgrades should run this helper before advancing
`tracked_skill_version` past v2.57.
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path


TOP_LEVEL_MOVES = [
    ("product", "01-product"),
    ("architecture", "02-architecture"),
    ("development", "03-process/development"),
    ("testing", "03-process/testing"),
    ("benchmark", "03-process/benchmark"),
    ("deployment", "03-process/deployment"),
    ("release", "03-process/release"),
    ("decisions", "04-records/decisions"),
    ("gotchas", "04-records/gotchas"),
    ("bugs", "04-records/bugs"),
    ("tech-debt", "04-records/tech-debt"),
    ("research", "04-records/research"),
]

LINK_RE = re.compile(r"\]\(([^)]+)\)")


@dataclass(frozen=True)
class Move:
    src: Path
    dst: Path


def is_empty_dir(path: Path) -> bool:
    return path.is_dir() and not any(path.iterdir())


def display(path: Path, root: Path) -> str:
    try:
        return str(path.relative_to(root))
    except ValueError:
        return str(path)


def next_domain_prefix(used: set[int]) -> int:
    value = 1
    while value in used:
        value += 1
    used.add(value)
    return value


def build_moves(ssot_dir: Path) -> list[Move]:
    moves: list[Move] = []

    for old, new in TOP_LEVEL_MOVES:
        src = ssot_dir / old
        dst = ssot_dir / new
        if src.exists() and src.resolve() != dst.resolve():
            moves.append(Move(src=src, dst=dst))

    arch_dir = ssot_dir / "02-architecture"
    domains_dir = ssot_dir / "architecture" / "domains"
    if not domains_dir.exists():
        domains_dir = arch_dir / "domains"
    if domains_dir.exists():
        used: set[int] = set()
        if arch_dir.exists():
            existing_arch_children = arch_dir.iterdir()
        else:
            existing_arch_children = ()
        for existing in existing_arch_children:
            if existing.is_dir() and existing.name != "domains":
                match = re.match(r"^(\d{2})-", existing.name)
                if match:
                    used.add(int(match.group(1)))

        for domain in sorted(domains_dir.iterdir(), key=lambda p: p.name):
            if domain.name in {"README.md", "_manifest.md"}:
                continue
            if not domain.is_dir():
                continue
            if re.match(r"^\d{2}-", domain.name):
                target_name = domain.name
            else:
                target_name = f"{next_domain_prefix(used):02d}-{domain.name}"
            moves.append(Move(src=domain, dst=arch_dir / target_name))

        domain_index = domains_dir / "README.md"
        if domain_index.exists():
            moves.append(Move(src=domain_index, dst=arch_dir / "domain-index.md"))

    return moves


def mapped_path(path: Path, moves: list[Move]) -> Path:
    resolved = path.resolve(strict=False)
    best: Move | None = None
    for move in moves:
        src_resolved = move.src.resolve(strict=False)
        try:
            resolved.relative_to(src_resolved)
        except ValueError:
            continue
        if best is None or len(src_resolved.parts) > len(best.src.resolve(strict=False).parts):
            best = move
    if best is None:
        return path
    rel = resolved.relative_to(best.src.resolve(strict=False))
    return best.dst.resolve(strict=False) / rel


def validate_moves(moves: list[Move], ssot_dir: Path) -> list[str]:
    errors: list[str] = []
    destinations: dict[Path, Path] = {}
    for move in moves:
        if not move.src.exists():
            continue
        dst = move.dst.resolve(strict=False)
        src = move.src.resolve(strict=False)
        if dst in destinations:
            errors.append(
                f"destination conflict: {display(move.dst, ssot_dir)} is mapped from "
                f"both {display(destinations[dst], ssot_dir)} and {display(move.src, ssot_dir)}"
            )
        destinations[dst] = move.src
        if move.dst.exists() and src != dst:
            if is_empty_dir(move.src):
                continue
            errors.append(
                f"target exists; resolve before migration: {display(move.dst, ssot_dir)} "
                f"(source {display(move.src, ssot_dir)})"
            )
    return errors


def split_target(target: str) -> tuple[str, str]:
    if "#" in target:
        base, suffix = target.split("#", 1)
        return base, "#" + suffix
    return target, ""


def should_skip_link(target: str) -> bool:
    return (
        not target
        or target.startswith("#")
        or re.match(r"^[a-zA-Z][a-zA-Z0-9+.-]*:", target) is not None
        or target.startswith("//")
        or target.startswith("<")
    )


def resolve_target(file_path: Path, repo_root: Path, target: str) -> Path:
    if target.startswith("SSOT/"):
        return repo_root / target
    return (file_path.parent / target).resolve(strict=False)


def rel_link(from_file: Path, to_path: Path) -> str:
    rel = os.path.relpath(to_path, from_file.parent)
    if not rel.startswith("."):
        rel = "./" + rel
    return rel.replace(os.sep, "/")


def rewrite_markdown_links(text: str, old_file: Path, new_file: Path, repo_root: Path, moves: list[Move]) -> str:
    def repl(match: re.Match[str]) -> str:
        target = match.group(1)
        base, suffix = split_target(target)
        if should_skip_link(base):
            return match.group(0)
        old_target = resolve_target(old_file, repo_root, base)
        new_target = mapped_path(old_target, moves)
        new_base = rel_link(new_file, new_target)
        return f"]({new_base}{suffix})"

    return LINK_RE.sub(repl, text)


def rewrite_literal_paths(text: str, moves: list[Move], repo_root: Path) -> str:
    replacements: list[tuple[str, str]] = []
    for move in moves:
        src_rel = display(move.src, repo_root).replace(os.sep, "/")
        dst_rel = display(move.dst, repo_root).replace(os.sep, "/")
        replacements.append((src_rel + "/", dst_rel + "/"))
        replacements.append((src_rel, dst_rel))

    # Longest first so architecture/domains/foo is rewritten before architecture.
    for old, new in sorted(replacements, key=lambda item: len(item[0]), reverse=True):
        text = text.replace(old, new)
    return text


def planned_file_rewrites(ssot_dir: Path, repo_root: Path, moves: list[Move]) -> list[tuple[Path, Path, str]]:
    rewrites: list[tuple[Path, Path, str]] = []
    for old_file in sorted(ssot_dir.rglob("*.md")):
        new_file = mapped_path(old_file, moves)
        original = old_file.read_text(encoding="utf-8")
        rewritten = rewrite_markdown_links(original, old_file, new_file, repo_root, moves)
        rewritten = rewrite_literal_paths(rewritten, moves, repo_root)
        if rewritten != original or new_file != old_file:
            rewrites.append((old_file, new_file, rewritten))
    return rewrites


def remap_source_after_top_moves(src: Path, top_moves: list[Move]) -> Path:
    for move in top_moves:
        try:
            rel = src.resolve(strict=False).relative_to(move.src.resolve(strict=False))
        except ValueError:
            continue
        return move.dst.resolve(strict=False) / rel
    return src


def apply_one_move(src: Path, dst: Path) -> None:
    if not src.exists():
        return
    if dst.exists() and is_empty_dir(src):
        src.rmdir()
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(str(src), str(dst))


def apply_moves(moves: list[Move], ssot_dir: Path) -> None:
    top_moves = [move for move in moves if move.src.parent.resolve(strict=False) == ssot_dir.resolve(strict=False)]
    nested_moves = [move for move in moves if move not in top_moves]

    for move in top_moves:
        apply_one_move(move.src, move.dst)

    for move in sorted(nested_moves, key=lambda m: len(m.src.parts), reverse=True):
        src = move.src
        if not src.exists():
            src = remap_source_after_top_moves(src, top_moves)
        if not src.exists():
            continue
        apply_one_move(src, move.dst)

    # Clean up empty legacy containers after domain flattening.
    for empty in [ssot_dir / "02-architecture" / "domains"]:
        if is_empty_dir(empty):
            empty.rmdir()


def apply_rewrites(rewrites: list[tuple[Path, Path, str]]) -> None:
    for _old_file, new_file, content in rewrites:
        if new_file.exists():
            new_file.write_text(content, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Migrate SSOT/ to the v2.57 faceted physical layout.")
    parser.add_argument("ssot_dir", nargs="?", default="SSOT", help="Path to the consumer SSOT directory")
    parser.add_argument("--dry-run", action="store_true", help="Print planned moves and rewrites without changing files")
    args = parser.parse_args()

    ssot_dir = Path(args.ssot_dir).resolve()
    if not ssot_dir.is_dir():
        print(f"ERROR: SSOT directory not found: {ssot_dir}", file=sys.stderr)
        return 3
    repo_root = ssot_dir.parent

    moves = build_moves(ssot_dir)
    errors = validate_moves(moves, ssot_dir)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 2

    rewrites = planned_file_rewrites(ssot_dir, repo_root, moves)

    if not moves and not rewrites:
        print("faceted-layout migration: no changes needed")
        return 0

    for move in moves:
        print(f"move {display(move.src, repo_root)} -> {display(move.dst, repo_root)}")
    for old_file, new_file, _content in rewrites:
        print(f"rewrite {display(mapped_path(old_file, moves), repo_root)}")

    if args.dry_run:
        return 0

    apply_moves(moves, ssot_dir)
    apply_rewrites(rewrites)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
