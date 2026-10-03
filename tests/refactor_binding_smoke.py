#!/usr/bin/env python3
"""Detect private Lua helper leaks introduced by module splits.

Lua ``local`` bindings are file-scoped.  A split module that calls a helper
without importing it compiles the name as an ``_ENV`` lookup, which later
fails as ``Object tried to call nil``.  This smoke test compares those bytecode
lookups with private ``local function`` declarations in sibling files.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MOD_ROOT = ROOT / "Contents/mods/ProjectHoomans"
VERSION = re.compile(r"^\d+\.\d+$")
LOCAL_FUNCTION = re.compile(
    r"^\s*local\s+function\s+([A-Za-z_]\w*)\s*\(",
    re.MULTILINE,
)
ENV_READ = re.compile(
    r"\[(\d+)\].*?GETTABUP\s+\d+\s+\d+\s+-?\d+"
    r".*?;\s*_ENV\s+\"([^\"]+)\""
)


@dataclass(frozen=True)
class Finding:
    path: Path
    line: int
    name: str
    owner: Path


def newest_runtime() -> Path:
    runtimes = [
        child
        for child in MOD_ROOT.iterdir()
        if child.is_dir() and VERSION.fullmatch(child.name)
    ]
    if not runtimes:
        raise RuntimeError(f"no numeric runtime under {MOD_ROOT}")
    return max(runtimes, key=lambda path: tuple(map(int, path.name.split("."))))


def git_paths(*arguments: str) -> set[Path]:
    result = subprocess.run(
        ["git", "-C", str(ROOT), *arguments],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    )
    return {ROOT / line for line in result.stdout.splitlines() if line}


def changed_lua_files(runtime: Path) -> set[Path]:
    changed = git_paths("diff", "--name-only")
    changed |= git_paths("diff", "--cached", "--name-only")
    return {
        path
        for path in changed
        if path.is_file()
        and path.suffix == ".lua"
        and path.is_relative_to(runtime)
    }


def local_functions(path: Path) -> set[str]:
    source = path.read_text(encoding="utf-8", errors="replace")
    return set(LOCAL_FUNCTION.findall(source))


def bytecode_reads(path: Path, luac: str) -> tuple[list[tuple[int, str]], str | None]:
    result = subprocess.run(
        [luac, "-l", "-p", str(path)],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        return [], result.stderr.strip() or "luac failed"
    return [
        (int(line), name)
        for line, name in ENV_READ.findall(result.stdout)
    ], None


def scan(runtime: Path, focus: set[Path], luac: str) -> tuple[list[Finding], list[str]]:
    files = sorted(runtime.rglob("*.lua"))
    helpers: dict[Path, set[str]] = {
        path: local_functions(path) for path in files
    }
    owners: dict[tuple[Path, str], list[Path]] = defaultdict(list)
    for path, names in helpers.items():
        for name in names:
            owners[(path.parent, name)].append(path)

    findings: set[Finding] = set()
    compile_errors: list[str] = []
    for path in sorted(focus):
        reads, error = bytecode_reads(path, luac)
        if error:
            compile_errors.append(f"{path}: {error}")
            continue
        for line, name in reads:
            if name in helpers[path]:
                continue
            sibling_owners = [
                owner for owner in owners[(path.parent, name)] if owner != path
            ]
            for owner in sibling_owners:
                findings.add(Finding(path, line, name, owner))
    return sorted(findings, key=lambda finding: (finding.path, finding.line, finding.name)), compile_errors


def parse_args(arguments: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--all",
        action="store_true",
        help="scan every Lua file instead of only Git-changed files",
    )
    parser.add_argument("--luac", default="luac", help="Lua compiler executable")
    return parser.parse_args(arguments)


def main(arguments: list[str] | None = None) -> int:
    options = parse_args(arguments or sys.argv[1:])
    try:
        runtime = newest_runtime()
    except (OSError, RuntimeError) as error:
        print(f"refactor binding smoke setup failed: {error}", file=sys.stderr)
        return 2

    focus = set(runtime.rglob("*.lua")) if options.all else changed_lua_files(runtime)
    if not focus:
        print("PASS refactor binding smoke: no changed Lua files")
        return 0

    findings, compile_errors = scan(runtime, focus, options.luac)
    print(
        f"Scanned {len(focus)} changed Lua files under {runtime.name}"
        if not options.all
        else f"Scanned {len(focus)} Lua files under {runtime.name}"
    )
    if compile_errors:
        print("\nCompile errors:")
        for error in compile_errors:
            print(f"- {error}")
    if findings:
        print(f"\nFAIL: {len(findings)} cross-file private helper reference(s)")
        for finding in findings:
            print(
                f"- {finding.path.relative_to(runtime)}:{finding.line}: "
                f"`{finding.name}` is read as a global, but is local to "
                f"{finding.owner.relative_to(runtime)}"
            )
    if compile_errors or findings:
        return 1
    print("PASS refactor binding smoke: no cross-file private helper leaks")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
