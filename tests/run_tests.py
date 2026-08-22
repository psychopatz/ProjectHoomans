#!/usr/bin/env python3
"""Parallel, failure-focused runner for isolated Project Hoomans Lua tests."""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TESTS = ROOT / "tests"
VERSION = re.compile(r"^\d+\.\d+$")


@dataclass(frozen=True)
class Result:
    path: Path
    returncode: int
    output: str
    elapsed: float


def newest_runtime(mod_root: Path) -> str:
    versions = [
        (tuple(int(part) for part in child.name.split(".")), child.name)
        for child in mod_root.iterdir()
        if child.is_dir() and VERSION.fullmatch(child.name)
    ]
    if not versions:
        raise RuntimeError(f"no numeric runtime directory under {mod_root}")
    return max(versions)[1]


def core_repository() -> Path:
    override = os.environ.get("PZ_TEST_CORE_REPOSITORY")
    if override:
        return Path(override).expanduser().resolve()
    sibling = ROOT.parent / "psychopatzCore"
    if not sibling.is_dir():
        raise RuntimeError(
            "PsychopatzCore repository not found; set PZ_TEST_CORE_REPOSITORY")
    return sibling.resolve()


def test_environment(verbose: bool) -> dict[str, str]:
    core = core_repository()
    environment = os.environ.copy()
    environment.update({
        "PZ_TEST_REPOSITORY": str(ROOT),
        "PZ_TEST_HOOMANS_RUNTIME": newest_runtime(
            ROOT / "Contents/mods/ProjectHoomans"),
        "PZ_TEST_CORE_RUNTIME": newest_runtime(
            core / "Contents/mods/PsychopatzCore"),
        "PZ_TEST_CORE_REPOSITORY": str(core),
        "PZ_TEST_VERBOSE": "1" if verbose else "0",
    })
    return environment


def discover(filters: list[str]) -> list[Path]:
    tests = sorted(TESTS.glob("*_smoke.lua"))
    if filters:
        lowered = [value.casefold() for value in filters]
        tests = [path for path in tests
                 if any(value in path.stem.casefold() for value in lowered)]
    return tests


def run_one(path: Path, environment: dict[str, str], timeout: float) -> Result:
    started = time.monotonic()
    try:
        completed = subprocess.run(
            ["lua", str(path)],
            cwd=ROOT, env=environment,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, timeout=timeout, check=False,
        )
        return Result(path, completed.returncode, completed.stdout,
                      time.monotonic() - started)
    except subprocess.TimeoutExpired as error:
        output = (error.stdout or "") + f"\nTIMEOUT after {timeout:g}s\n"
        return Result(path, 124, output, time.monotonic() - started)


def bounded_output(output: str, maximum_lines: int) -> str:
    lines = output.rstrip().splitlines()
    if len(lines) <= maximum_lines:
        return "\n".join(lines)
    omitted = len(lines) - maximum_lines
    return f"... {omitted} earlier lines omitted ...\n" + "\n".join(lines[-maximum_lines:])


def parse_args(arguments: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("filters", nargs="*", help="case-insensitive test-name filters")
    parser.add_argument("--jobs", type=int, default=min(4, os.cpu_count() or 1))
    parser.add_argument("--timeout", type=float, default=30.0, help="seconds per test")
    parser.add_argument("--max-output-lines", type=int, default=80)
    parser.add_argument("--fail-fast", action="store_true")
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--verbose", action="store_true")
    return parser.parse_args(arguments)


def main(arguments: list[str] | None = None) -> int:
    options = parse_args(arguments or sys.argv[1:])
    tests = discover(options.filters)
    if options.list:
        for path in tests:
            print(path.relative_to(ROOT))
        return 0
    if not tests:
        print("No matching Lua tests.", file=sys.stderr)
        return 2
    try:
        environment = test_environment(options.verbose)
    except (OSError, RuntimeError) as error:
        print(f"Test environment error: {error}", file=sys.stderr)
        return 2

    started = time.monotonic()
    results: list[Result] = []
    workers = max(1, min(options.jobs, len(tests)))
    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = {
            executor.submit(run_one, path, environment, options.timeout): path
            for path in tests
        }
        for future in as_completed(futures):
            result = future.result()
            results.append(result)
            if options.verbose:
                state = "PASS" if result.returncode == 0 else "FAIL"
                print(f"{state} {result.path.stem} {result.elapsed:.2f}s")
                if result.output.strip():
                    print(bounded_output(result.output, options.max_output_lines))
            if options.fail_fast and result.returncode != 0:
                for pending in futures:
                    pending.cancel()
                break

    results.sort(key=lambda item: item.path.name)
    failures = [result for result in results if result.returncode != 0]
    elapsed = time.monotonic() - started
    if failures:
        print(f"FAIL {len(failures)}/{len(results)} executed in {elapsed:.2f}s")
        for result in failures:
            print(f"\n--- {result.path.name} ({result.elapsed:.2f}s) ---")
            print(bounded_output(result.output, options.max_output_lines))
        return 1
    print(f"PASS {len(results)}/{len(tests)} in {elapsed:.2f}s ({workers} workers)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
