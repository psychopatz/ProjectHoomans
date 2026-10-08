#!/usr/bin/env python3
"""Parallel, failure-focused runner for isolated Project Hoomans Lua tests."""

from __future__ import annotations

import argparse
import json
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
sys.path.insert(0, str(ROOT))

from tools.semantic_harness.suite import (
    BoundedLuaTestRunner,
    install_suite_shutdown_handler,
    write_report,
)


@dataclass(frozen=True)
class Result:
    path: Path
    returncode: int
    output: str
    elapsed: float


def kahlua_backend(options: argparse.Namespace):
    """Load the opt-in generic harness through the Hoomans adapter boundary."""

    harness_root = options.kahlua_harness or os.environ.get("PZ_HEADLESS_HARNESS")
    profile = options.kahlua_profile or os.environ.get("PZ_HEADLESS_PROFILE")
    if not harness_root:
        raise RuntimeError(
            "Kahlua backend requires --kahlua-harness or PZ_HEADLESS_HARNESS"
        )
    if not profile:
        raise RuntimeError(
            "Kahlua backend requires --kahlua-profile or PZ_HEADLESS_PROFILE"
        )
    root = Path(harness_root).expanduser().resolve()
    if not root.is_dir():
        raise RuntimeError(f"Kahlua harness root does not exist: {root}")
    sys.path.insert(0, str(root / "src"))
    try:
        from pz_headless.integrations.project_hoomans import (
            ProjectHoomansKahluaBackend,
        )
    except ImportError as error:
        raise RuntimeError(f"cannot import Kahlua harness from {root}: {error}") from error
    return ProjectHoomansKahluaBackend(
        profile_path=Path(profile).expanduser().resolve(),
        allow_runtime_mismatch=options.allow_runtime_mismatch,
        java=options.kahlua_java,
        javac=options.kahlua_javac,
        max_output_bytes=options.max_output_bytes,
        max_memory_mb=options.kahlua_memory_mb,
    )


def run_kahlua_one(
    path: Path,
    backend: object,
    mode: str,
    timeout: float,
) -> Result:
    started = time.monotonic()
    report = backend.run_one(path.stem, path, mode, timeout)  # type: ignore[attr-defined]
    status = str(report.get("status"))
    returncode = 0 if status == "passed" else 2 if status == "incompatible" else 1
    return Result(
        path,
        returncode,
        json.dumps(report, ensure_ascii=False, indent=2),
        time.monotonic() - started,
    )


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


def run_one(
    path: Path,
    environment: dict[str, str],
    timeout: float,
    *,
    runner: BoundedLuaTestRunner | None = None,
    executable: str = "lua",
) -> Result:
    if runner is not None:
        bounded = runner.run_one(path, environment, timeout)
        return Result(path, bounded.returncode, bounded.output, bounded.elapsed)
    started = time.monotonic()
    try:
        completed = subprocess.run(
            [executable, str(path)],
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
    parser.add_argument(
        "--backend",
        choices=("portable", "kahlua"),
        default="portable",
        help="portable Lua smoke runner or exact-PZ-JAR Kahlua adapter",
    )
    parser.add_argument("--lua", default="lua", help="Lua executable for smoke tests")
    parser.add_argument(
        "--max-output-bytes",
        type=int,
        default=256 * 1024,
        help="maximum captured output per test when using the bounded harness runner",
    )
    parser.add_argument(
        "--legacy-runner",
        action="store_true",
        help="use the previous subprocess runner instead of the bounded harness runner",
    )
    parser.add_argument(
        "--harness-report",
        help="write the selected backend's structured JSON report",
    )
    parser.add_argument(
        "--kahlua-harness",
        help="pz-headless-harness root; defaults to PZ_HEADLESS_HARNESS",
    )
    parser.add_argument(
        "--kahlua-profile",
        help="immutable engine profile; defaults to PZ_HEADLESS_PROFILE",
    )
    parser.add_argument(
        "--kahlua-mode",
        choices=("server", "client"),
        default="server",
        help="authority fixture used for each Kahlua smoke test",
    )
    parser.add_argument("--kahlua-java", help="Java executable for the Kahlua backend")
    parser.add_argument("--kahlua-javac", help="javac executable for the Kahlua backend")
    parser.add_argument(
        "--kahlua-memory-mb",
        type=int,
        default=512,
        help="JVM heap limit for the Kahlua backend",
    )
    parser.add_argument(
        "--allow-runtime-mismatch",
        action="store_true",
        help="run Kahlua tests when the profile game version differs from mod runtimes",
    )
    return parser.parse_args(arguments)


def main(arguments: list[str] | None = None) -> int:
    install_suite_shutdown_handler()
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
        environment = test_environment(options.verbose) if options.backend == "portable" else {}
    except (OSError, RuntimeError) as error:
        print(f"Test environment error: {error}", file=sys.stderr)
        return 2

    started = time.monotonic()
    results: list[Result] = []
    workers = max(1, min(options.jobs, len(tests)))
    harness_runner = None
    kahlua_runner = None
    if options.backend == "kahlua":
        if options.legacy_runner:
            print("--legacy-runner is only valid with --backend portable", file=sys.stderr)
            return 2
        try:
            kahlua_runner = kahlua_backend(options)
        except (OSError, RuntimeError, ValueError) as error:
            print(f"Kahlua backend configuration error: {error}", file=sys.stderr)
            return 2
        if workers != 1:
            if options.verbose:
                print("Kahlua backend runs one bounded JVM process at a time")
            workers = 1
    elif not options.legacy_runner:
        try:
            harness_runner = BoundedLuaTestRunner(
                ROOT,
                executable=options.lua,
                max_output_bytes=options.max_output_bytes,
            )
        except ValueError as error:
            print(f"Harness runner configuration error: {error}", file=sys.stderr)
            return 2
    with ThreadPoolExecutor(max_workers=workers) as executor:
        if kahlua_runner is not None:
            futures = {
                executor.submit(
                    run_kahlua_one,
                    path,
                    kahlua_runner,
                    options.kahlua_mode,
                    options.timeout,
                ): path
                for path in tests
            }
        else:
            futures = {
                executor.submit(
                    run_one,
                    path,
                    environment,
                    options.timeout,
                    runner=harness_runner,
                    executable=options.lua,
                ): path
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
    if options.harness_report:
        report_path = Path(options.harness_report).expanduser()
        if kahlua_runner is not None:
            report_path.parent.mkdir(parents=True, exist_ok=True)
            report_path.write_text(
                json.dumps(kahlua_runner.report(), ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
        elif harness_runner is not None:
            write_report(harness_runner.report(), report_path)
        else:
            print("--harness-report requires a managed backend runner", file=sys.stderr)
            return 2
    if failures:
        print(f"FAIL {len(failures)}/{len(results)} executed in {elapsed:.2f}s")
        for result in failures:
            print(f"\n--- {result.path.name} ({result.elapsed:.2f}s) ---")
            print(bounded_output(result.output, options.max_output_lines))
        return 2 if any(result.returncode == 2 for result in failures) else 1
    print(f"PASS {len(results)}/{len(tests)} in {elapsed:.2f}s ({workers} workers)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
