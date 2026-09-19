"""Command-line client for the real-Lua semantic dialogue harness."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

from .config import ConfigurationError
from .rendering import print_result as _print_result
from .runner import ConflictLedger, load_case, run_case
from .scenario import load_scenario
from .worker import HarnessError, LuaSemanticWorker

PARSER_DESCRIPTION = "Tkinter chat UI and CLI for the real-Lua semantic dialogue harness."


def cli(arguments: argparse.Namespace) -> int:
    try:
        worker_kwargs = {
            "lua_bin": arguments.lua,
            "repository": Path(arguments.repository) if arguments.repository else None,
            "core_repository": Path(arguments.core_repository) if arguments.core_repository else None,
            "startup_timeout": arguments.startup_timeout,
            "request_timeout": arguments.timeout,
            "shutdown_timeout": arguments.shutdown_timeout,
        }
        if arguments.case:
            report = run_case(load_case(Path(arguments.case)), **worker_kwargs)
            _print_result(report.as_dict(), arguments.jsonl)
            return 0 if report.conflicts == [] else 3
        scenario = load_scenario(Path(arguments.scenario) if arguments.scenario else None)
        if arguments.language:
            scenario.setdefault("runtime", {})["language"] = arguments.language.upper()
        with LuaSemanticWorker(
            scenario,
            **worker_kwargs,
        ) as worker:
            ledger = ConflictLedger() if arguments.audit else None
            if arguments.snapshot:
                _print_result(worker.snapshot(), arguments.jsonl)
            for value in arguments.input:
                result = worker.input(value)
                if ledger is not None:
                    ledger.add(result)
                _print_result(result, arguments.jsonl)
            if arguments.interactive:
                for line in sys.stdin:
                    value = line.strip()
                    if value:
                        result = worker.input(value)
                        if ledger is not None:
                            ledger.add(result)
                        _print_result(result, arguments.jsonl)
            if arguments.audit:
                conflicts = ledger.report() if ledger is not None else []
                _print_result(
                    {"type": "audit", "ok": not conflicts, "conflicts": conflicts},
                    arguments.jsonl,
                )
    except (HarnessError, ConfigurationError, OSError, ValueError) as error:
        print(f"semantic harness error: {error}", file=sys.stderr)
        return 2
    return 0


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=PARSER_DESCRIPTION)
    parser.add_argument("--scenario", help="JSON scenario file")
    parser.add_argument("--case", help="JSON replay case with scenario and inputs")
    parser.add_argument("--lua", help="Lua executable; defaults to PNC_HARNESS_LUA, lua, or luajit")
    parser.add_argument("--repository", help="Project Hoomans repository")
    parser.add_argument("--core-repository", help="PsychopatzCore repository")
    parser.add_argument("--no-gui", "--cli", dest="no_gui", action="store_true", help="run inputs and print JSON")
    parser.add_argument("--interactive", action="store_true", help="read one conversation input per stdin line")
    parser.add_argument("--jsonl", action="store_true", help="emit compact one-record-per-line JSON")
    parser.add_argument("--audit", action="store_true", help="emit a bounded conflict audit after turns")
    parser.add_argument("--doctor", action="store_true", help="run bounded headless runtime diagnostics")
    parser.add_argument("--doctor-json", action="store_true", help="emit doctor diagnostics as one JSON record")
    parser.add_argument("--snapshot", action="store_true")
    parser.add_argument("--language", choices=("EN", "TL"), help="production translation language")
    parser.add_argument("--input", action="append", default=[], help="chat input; repeatable")
    parser.add_argument("--timeout", type=float, default=5.0, help="per-request timeout in seconds")
    parser.add_argument("--startup-timeout", type=float, default=8.0, help="worker startup timeout in seconds")
    parser.add_argument("--shutdown-timeout", type=float, default=1.0, help="worker shutdown timeout in seconds")
    return parser
