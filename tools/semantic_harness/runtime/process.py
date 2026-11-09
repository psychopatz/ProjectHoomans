"""Compatibility adapter to the Core-owned semantic worker client.

The Hoomans package keeps this import path for existing callers, but the
process lifecycle, protocol correlation, bounded diagnostics, and shutdown
handling now live in PsychopatzCore.
"""

from __future__ import annotations

import importlib
import os
import sys
from pathlib import Path
from typing import Any


def _load_core_process(core_repository: str | Path | None = None) -> Any:
    candidates: list[Path] = []
    if core_repository:
        candidates.append(Path(core_repository).expanduser().resolve())
    for name in (
        "SEMANTIC_HARNESS_CORE_REPOSITORY",
        "PNC_HARNESS_CORE_REPOSITORY",
    ):
        value = os.environ.get(name)
        if value:
            candidates.append(Path(value).expanduser().resolve())
    candidates.append(
        Path(__file__).resolve().parents[3].parent / "psychopatzCore"
    )
    for candidate in candidates:
        tools_root = candidate / "tools"
        package_root = tools_root / "semantic_harness"
        if not (package_root / "process.py").is_file():
            continue
        rendered = str(tools_root)
        if rendered not in sys.path:
            sys.path.insert(0, rendered)
        return importlib.import_module("semantic_harness.process")
    raise ImportError(
        "Core semantic harness process client is unavailable; checked: "
        + ", ".join(str(candidate) for candidate in candidates)
    )


_CORE_PROCESS = _load_core_process()
HarnessError = _CORE_PROCESS.HarnessError
install_shutdown_handler = _CORE_PROCESS.install_shutdown_handler


def _launch_spec(config: Any) -> Any:
    core_process = _load_core_process(config.core_repository)
    profile = str(getattr(config, "profile", "hoomans") or "hoomans").lower()
    environment = {
        # These legacy names are still required by the compatibility Hoomans
        # worker. Core's worker client itself uses neutral SEMANTIC_HARNESS_*
        # names and does not depend on these aliases.
        "PNC_HARNESS_REPOSITORY": str(config.repository),
        "PNC_HARNESS_CORE_REPOSITORY": str(config.core_repository),
        "PZ_TEST_REPOSITORY": str(config.repository),
        "PZ_TEST_CORE_REPOSITORY": str(config.core_repository),
    }
    if getattr(config, "candidate_overlay_root", None) is not None:
        environment["PNC_HARNESS_CANDIDATE_OVERLAY_ROOT"] = str(
            config.candidate_overlay_root
        )
        environment["PNC_HARNESS_CANDIDATE_OVERLAY_MODULE"] = (
            config.candidate_overlay_module or ""
        )
    if getattr(config, "hoomans_runtime", None) is not None:
        environment["PZ_TEST_HOOMANS_RUNTIME"] = config.hoomans_runtime
    if getattr(config, "core_runtime", None) is not None:
        environment["PZ_TEST_CORE_RUNTIME"] = config.core_runtime
    if getattr(config, "dynamic_trading_repository", None) is not None:
        environment["PNC_HARNESS_DYNAMIC_TRADING_REPOSITORY"] = str(
            config.dynamic_trading_repository
        )
    if getattr(config, "dynamic_trading_runtime", None) is not None:
        environment["PZ_TEST_DYNAMIC_TRADING_RUNTIME"] = (
            config.dynamic_trading_runtime
        )

    worker_arguments = (
        (str(config.core_repository),)
        if profile == "core"
        else (str(config.repository), str(config.core_repository))
    )
    return core_process.WorkerLaunchSpec(
        lua_bin=config.lua_bin,
        worker_script=config.worker_script,
        core_repository=config.core_repository,
        working_directory=config.repository,
        profile=profile,
        worker_arguments=worker_arguments,
        environment=environment,
        startup_timeout=config.startup_timeout,
        request_timeout=config.request_timeout,
        shutdown_timeout=config.shutdown_timeout,
        max_message_bytes=config.max_message_bytes,
    )


class LuaProcess:
    """Preserve the Hoomans runtime API while delegating to Core."""

    def __init__(self, config: Any, activity_log: Any | None = None) -> None:
        self.config = config
        core_process = _load_core_process(config.core_repository)
        self._delegate = core_process.LuaProcess(
            _launch_spec(config),
            activity_log=activity_log,
        )

    @property
    def process(self) -> Any:
        return self._delegate.process

    @property
    def state(self) -> str:
        return self._delegate.state

    def status(self) -> dict[str, Any]:
        return self._delegate.status()

    def start(self) -> dict[str, Any]:
        return self._delegate.start()

    def request(
        self,
        command: str,
        payload: Any = None,
        *,
        timeout: float | None = None,
    ) -> dict[str, Any]:
        return self._delegate.request(command, payload, timeout=timeout)

    def close(self) -> None:
        self._delegate.close()

    def __enter__(self) -> "LuaProcess":
        self.start()
        return self

    def __exit__(self, *_: object) -> None:
        self.close()

    def __getattr__(self, name: str) -> Any:
        return getattr(self._delegate, name)
