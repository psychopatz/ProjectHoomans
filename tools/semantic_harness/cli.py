"""Command-line client for the real-Lua semantic dialogue harness."""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

from .config import ConfigurationError
from .codebuilder.service import SemanticLabAuthoringService
from .rendering import print_result as _print_result
from .runner import ConflictLedger, load_case, run_case
from .scenario import load_scenario
from .worker import HarnessError, LuaSemanticWorker

PARSER_DESCRIPTION = "Tkinter chat UI and CLI for the real-Lua semantic dialogue harness."
AUTHORING_OPERATIONS = (
    "compile_source",
    "generate_source",
    "review_dataset",
    "generate_dataset",
    "list_datasets",
    "search_datasets",
    "show_dataset",
    "validate_dataset",
    "list_blocks",
    "search_blocks",
    "validate_blocks",
    "validate_codeblocks",
)


def _resolve_authoring_source(
    service: SemanticLabAuthoringService,
    value: str,
) -> Path:
    source = Path(value).expanduser()
    if not source.is_absolute():
        source = service.repository / source
    return source.resolve()


def _run_authoring_operation(
    arguments: argparse.Namespace,
    service: SemanticLabAuthoringService,
) -> dict | None:
    if arguments.list_datasets:
        return {
            "ok": True,
            "type": "dataset_library",
            "sources": service.list_dataset_sources(),
        }
    if arguments.search_datasets is not None:
        return {
            "ok": True,
            "type": "dataset_search",
            "query": arguments.search_datasets,
            "results": service.search_dataset(arguments.search_datasets),
        }
    if arguments.show_dataset:
        source_id = arguments.show_dataset
        source = next(
            (item for item in service.list_dataset_sources() if item["id"] == source_id),
            None,
        )
        if source is None:
            raise ValueError(f"unknown canonical dataset source: {source_id}")
        return {
            "ok": True,
            "type": "dataset",
            "source": source,
            "entries": service.search_dataset("", source_id=source_id, limit=64),
        }
    if arguments.validate_dataset:
        source_id = arguments.validate_dataset
        return service.preview_dataset_edit(
            source_id,
            service.load_dataset_document(source_id),
        )
    if arguments.list_blocks:
        return service.list_semantic_blocks()
    if arguments.search_blocks is not None:
        return {
            "ok": True,
            "type": "semantic_block_search",
            "query": arguments.search_blocks,
            "results": service.search_semantic_blocks(arguments.search_blocks),
        }
    if arguments.validate_blocks is not None:
        block_ids = [
            value.strip()
            for value in arguments.validate_blocks.split(",")
            if value.strip()
        ]
        return service.validate_semantic_blocks(block_ids)
    if arguments.validate_codeblocks:
        return service.validate_codeblock_source(
            _resolve_authoring_source(service, arguments.validate_codeblocks)
        )
    if arguments.compile_source:
        return service.preview_semantic_source(
            _resolve_authoring_source(service, arguments.compile_source)
        )
    if arguments.generate_source:
        return service.generate_semantic_source(
            _resolve_authoring_source(service, arguments.generate_source)
        )
    if arguments.review_dataset:
        return service.preview_dialogue_source(
            _resolve_authoring_source(service, arguments.review_dataset)
        )
    if arguments.generate_dataset:
        return service.generate_dialogue_source(
            _resolve_authoring_source(service, arguments.generate_dataset)
        )
    return None


def cli(arguments: argparse.Namespace) -> int:
    try:
        repository = Path(arguments.repository) if arguments.repository else None
        authoring_service = SemanticLabAuthoringService(
            repository=repository,
            runtime_root=repository,
        )
        authoring_report = _run_authoring_operation(arguments, authoring_service)
        if authoring_report is not None:
            _print_result(authoring_report, arguments.jsonl)
            return 0 if authoring_report.get("ok") is True else 2
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
    authoring = parser.add_mutually_exclusive_group()
    authoring.add_argument(
        "--compile-source",
        metavar="PATH",
        help="preview one canonical semantic source through the embedded CodeBuilder",
    )
    authoring.add_argument(
        "--generate-source",
        metavar="PATH",
        help="write one approved canonical semantic source through the embedded CodeBuilder",
    )
    authoring.add_argument(
        "--review-dataset",
        metavar="PATH",
        help="preview one reviewed dialogue dataset through the embedded CodeBuilder",
    )
    authoring.add_argument(
        "--generate-dataset",
        metavar="PATH",
        help="write one approved dialogue dataset through the embedded CodeBuilder",
    )
    authoring.add_argument(
        "--list-datasets",
        action="store_true",
        help="list canonical datasets available in the Semantic Lab Dataset Library",
    )
    authoring.add_argument(
        "--search-datasets",
        metavar="QUERY",
        help="search canonical dataset entries through the Semantic Lab Dataset Library",
    )
    authoring.add_argument(
        "--show-dataset",
        metavar="SOURCE_ID",
        help="show bounded entries for a canonical Dataset Library source",
    )
    authoring.add_argument(
        "--validate-dataset",
        metavar="SOURCE_ID",
        help="validate the current canonical Dataset Library source without writing",
    )
    authoring.add_argument(
        "--list-blocks",
        action="store_true",
        help="list reusable Semantic Lab blocks and their production contracts",
    )
    authoring.add_argument(
        "--search-blocks",
        metavar="QUERY",
        help="search reusable Semantic Lab blocks",
    )
    authoring.add_argument(
        "--validate-blocks",
        metavar="IDS",
        help="validate comma-separated reusable block IDs without writing or dispatching",
    )
    authoring.add_argument(
        "--validate-codeblocks",
        metavar="PATH",
        help="validate a declarative semantic.codeblocks.v1 file without writing or dispatching",
    )
    parser.add_argument("--doctor", action="store_true", help="run bounded headless runtime diagnostics")
    parser.add_argument("--doctor-json", action="store_true", help="emit doctor diagnostics as one JSON record")
    parser.add_argument("--snapshot", action="store_true")
    parser.add_argument("--language", choices=("EN", "TL"), help="production translation language")
    parser.add_argument("--input", action="append", default=[], help="chat input; repeatable")
    parser.add_argument("--timeout", type=float, default=5.0, help="per-request timeout in seconds")
    parser.add_argument("--startup-timeout", type=float, default=8.0, help="worker startup timeout in seconds")
    parser.add_argument("--shutdown-timeout", type=float, default=1.0, help="worker shutdown timeout in seconds")
    return parser
