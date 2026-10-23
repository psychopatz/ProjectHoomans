"""Tkinter chat UI and CLI for the real-Lua semantic dialogue harness."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Sequence

if __package__ in {None, ""}:
    # Preserve direct `python tools/semantic_harness/app.py` execution.
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
    from tools.semantic_harness.cli import AUTHORING_OPERATIONS, CLI_OPERATIONS, _parser, cli
    from tools.semantic_harness.testing.doctor import run_doctor
    from tools.semantic_harness.ui.shell import SemanticHarnessApp, run_gui
    from tools.semantic_harness.runtime.process import install_shutdown_handler
    from tools.semantic_harness.inspection.rendering import pretty, print_result as _print_result
else:
    from .cli import AUTHORING_OPERATIONS, CLI_OPERATIONS, _parser, cli
    from .testing.doctor import run_doctor
    from .ui.shell import SemanticHarnessApp, run_gui
    from .runtime.process import install_shutdown_handler
    from .inspection.rendering import pretty, print_result as _print_result


def main(argv: Sequence[str] | None = None) -> int:
    install_shutdown_handler()
    arguments = _parser().parse_args(argv)
    if arguments.doctor or arguments.doctor_json:
        return run_doctor(
            repository=arguments.repository,
            core_repository=arguments.core_repository,
            lua_bin=arguments.lua,
            startup_timeout=arguments.startup_timeout,
            request_timeout=arguments.timeout,
            json_output=arguments.doctor_json,
        )
    if arguments.no_gui or any(
        getattr(arguments, operation, None)
        for operation in (*AUTHORING_OPERATIONS, *CLI_OPERATIONS)
    ):
        return cli(arguments)
    return run_gui(arguments)


if __name__ == "__main__":
    raise SystemExit(main())
