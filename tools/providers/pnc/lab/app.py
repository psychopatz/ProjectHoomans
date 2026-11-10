"""Tkinter chat UI and CLI for the real-Lua semantic dialogue harness."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Sequence

if __package__ in {None, ""}:
    # Preserve direct execution of this provider-owned lab entrypoint.
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
    from tools.providers.pnc.lab.cli import AUTHORING_OPERATIONS, CLI_OPERATIONS, _parser, cli
    from tools.semantic_harness.testing.doctor import run_doctor
    from tools.providers.pnc.lab.ui.shell import SemanticHarnessApp, run_gui
    from tools.semantic_harness.process import install_shutdown_handler
    from tools.semantic_harness.inspection.rendering import pretty, print_result as _print_result
else:
    from .cli import AUTHORING_OPERATIONS, CLI_OPERATIONS, _parser, cli
    from tools.semantic_harness.testing.doctor import run_doctor
    from .ui.shell import SemanticHarnessApp, run_gui
    from tools.semantic_harness.process import install_shutdown_handler
    from tools.semantic_harness.inspection.rendering import pretty, print_result as _print_result


def main(argv: Sequence[str] | None = None) -> int:
    install_shutdown_handler()
    arguments = _parser().parse_args(argv)
    if arguments.doctor or arguments.doctor_json:
        return run_doctor(
            repository=arguments.repository,
            core_repository=arguments.core_repository,
            lua_bin=arguments.lua,
            profile=arguments.profile,
            startup_timeout=arguments.startup_timeout,
            request_timeout=arguments.timeout,
            json_output=arguments.doctor_json,
        )
    if not arguments.gui and (
        arguments.no_gui
        or any(
            getattr(arguments, operation, None)
            for operation in (*AUTHORING_OPERATIONS, *CLI_OPERATIONS)
        )
    ):
        return cli(arguments)
    return run_gui(arguments)


if __name__ == "__main__":
    raise SystemExit(main())
