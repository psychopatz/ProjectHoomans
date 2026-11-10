"""Portable runtime discovery and bounded harness configuration."""

from __future__ import annotations

import os
import sys
from dataclasses import dataclass
from pathlib import Path


_CORE_TOOLS = Path(__file__).resolve().parents[3].parent / "psychopatzCore" / "tools"
if str(_CORE_TOOLS) not in sys.path:
    sys.path.insert(0, str(_CORE_TOOLS))

from semantic_harness.process import WorkerLaunchSpec
from semantic_harness.protocol import DEFAULT_MAX_MESSAGE_BYTES


from semantic_harness.runtime_discovery import (
    ConfigurationError,
    RUNTIME_DIRECTORY_PATTERN,
    discover_lua,
    discover_newest_runtime,
    probe_lua,
)

def discover_dynamic_trading_repository(
    repository: str | Path,
) -> Path | None:
    """Find the optional Dynamic Trading sibling without making it required."""

    explicit = os.environ.get("PNC_HARNESS_DYNAMIC_TRADING_REPOSITORY")
    candidates = [Path(explicit)] if explicit else []
    candidates.append(
        Path(repository).expanduser().resolve().parent / "DynamicTrading"
    )
    for candidate in candidates:
        resolved = candidate.expanduser().resolve()
        if (resolved / "Contents/mods/DTCommon").is_dir():
            return resolved
    return None


def discover_dynamic_trading_runtime(
    repository: str | Path,
) -> str | None:
    """Return a version shared by both optional Dynamic Trading modules."""

    root = Path(repository).expanduser().resolve()
    module_roots = [
        root / "Contents/mods/DTCommon",
        root / "Contents/mods/DTHoomans",
    ]
    if not all(path.is_dir() for path in module_roots):
        return None

    version_sets = []
    for module_root in module_roots:
        version_sets.append(
            {
                child.name
                for child in module_root.iterdir()
        if child.is_dir() and RUNTIME_DIRECTORY_PATTERN.fullmatch(child.name)
            }
        )
    compatible = set.intersection(*version_sets)
    if not compatible:
        raise ConfigurationError(
            "Dynamic Trading modules do not share a numeric runtime under "
            f"{root}"
        )
    return max(
        compatible,
        key=lambda value: tuple(int(part) for part in value.split(".")),
    )


def _looks_like_repository(path: Path) -> bool:
    return (path / "Contents/mods/ProjectHoomans").is_dir()


def _looks_like_core(path: Path) -> bool:
    return (path / "Contents/mods/PsychopatzCore").is_dir()


def discover_repository(explicit: str | Path | None = None) -> Path:
    if explicit:
        candidates = [Path(explicit)]
    else:
        environment = os.environ.get("PNC_HARNESS_REPOSITORY")
        candidates = [Path(environment)] if environment else []
        # The implementation now lives under ``runtime/``; keep discovery
        # anchored at the repository root rather than at ``tools/``.
        candidates.extend([Path(__file__).resolve().parents[3], Path.cwd()])
    for candidate in candidates:
        resolved = candidate.expanduser().resolve()
        if _looks_like_repository(resolved):
            return resolved
    rendered = ", ".join(str(path.expanduser()) for path in candidates)
    raise ConfigurationError(
        "could not locate Project Hoomans repository; checked: " + rendered
    )


def discover_core(repository: Path, explicit: str | Path | None = None) -> Path:
    if explicit:
        candidates = [Path(explicit)]
    else:
        environment = os.environ.get("PNC_HARNESS_CORE_REPOSITORY")
        candidates = [Path(environment)] if environment else []
        workshop_root = os.environ.get("PNC_HARNESS_WORKSHOP_ROOT")
        if workshop_root:
            candidates.append(Path(workshop_root) / "psychopatzCore")
        candidates.extend([repository.parent / "psychopatzCore", Path.cwd() / "psychopatzCore"])
    for candidate in candidates:
        resolved = candidate.expanduser().resolve()
        if _looks_like_core(resolved):
            return resolved
    rendered = ", ".join(str(path.expanduser()) for path in candidates)
    raise ConfigurationError(
        "could not locate PsychopatzCore repository; checked: " + rendered
    )


@dataclass(frozen=True)
class HarnessConfig:
    repository: Path
    core_repository: Path
    lua_bin: Path
    worker_script: Path
    profile: str = "hoomans"
    provider_ids: tuple[str, ...] = ("PsychopatzCore", "ProjectHoomans")
    materialization_mode: str = "physical"
    hoomans_runtime: str | None = None
    core_runtime: str | None = None
    dynamic_trading_repository: Path | None = None
    dynamic_trading_runtime: str | None = None
    startup_timeout: float = 8.0
    request_timeout: float = 5.0
    shutdown_timeout: float = 1.0
    max_message_bytes: int = DEFAULT_MAX_MESSAGE_BYTES
    candidate_overlay_root: Path | None = None
    candidate_overlay_module: str | None = None

    @classmethod
    def discover(
        cls,
        *,
        repository: str | Path | None = None,
        core_repository: str | Path | None = None,
        lua_bin: str | Path | None = None,
        worker_script: str | Path | None = None,
        profile: str = "hoomans",
        startup_timeout: float = 8.0,
        request_timeout: float = 5.0,
        shutdown_timeout: float = 1.0,
    ) -> "HarnessConfig":
        profile = str(profile or "hoomans").strip().lower()
        if profile not in {"hoomans", "core"}:
            raise ConfigurationError(
                f"unsupported Hoomans harness profile: {profile}; "
                "supported profiles are hoomans and core"
            )
        repo = discover_repository(repository)
        core = discover_core(repo, core_repository)
        lua = discover_lua(lua_bin)
        worker = (
            Path(worker_script)
            if worker_script
            else (
                core / "tools" / "semantic_harness" / "lua" / "worker.lua"
                if profile == "core"
                else Path(__file__).resolve().parents[1] / "lua" / "worker.lua"
            )
        )
        worker = worker.expanduser().resolve()
        if not worker.is_file():
            raise ConfigurationError(f"Lua worker script does not exist: {worker}")
        if startup_timeout <= 0 or request_timeout <= 0 or shutdown_timeout <= 0:
            raise ConfigurationError("timeouts must be positive")
        hoomans_runtime = None
        if profile == "hoomans":
            hoomans_runtime = os.environ.get("PZ_TEST_HOOMANS_RUNTIME") or (
                discover_newest_runtime(repo / "Contents/mods/ProjectHoomans")
            )
        core_runtime = os.environ.get("PZ_TEST_CORE_RUNTIME") or (
            discover_newest_runtime(core / "Contents/mods/PsychopatzCore")
        )
        dynamic_trading_repository = None
        dynamic_trading_runtime = None
        if profile == "hoomans":
            dynamic_trading_repository = discover_dynamic_trading_repository(repo)
            dynamic_trading_runtime = os.environ.get(
                "PZ_TEST_DYNAMIC_TRADING_RUNTIME"
            )
            if dynamic_trading_runtime is None and dynamic_trading_repository:
                dynamic_trading_runtime = discover_dynamic_trading_runtime(
                    dynamic_trading_repository
                )
        if profile == "core":
            provider_ids = ("PsychopatzCore",)
            materialization_mode = "none"
        else:
            provider_ids = ("PsychopatzCore", "ProjectHoomans")
            materialization_mode = "physical"
            if dynamic_trading_repository is not None and dynamic_trading_runtime:
                provider_ids += ("DTCommon", "DTHoomans")
        return cls(
            repository=repo,
            core_repository=core,
            lua_bin=lua,
            worker_script=worker,
            profile=profile,
            provider_ids=provider_ids,
            materialization_mode=materialization_mode,
            hoomans_runtime=hoomans_runtime,
            core_runtime=core_runtime,
            dynamic_trading_repository=dynamic_trading_repository,
            dynamic_trading_runtime=dynamic_trading_runtime,
            startup_timeout=float(startup_timeout),
            request_timeout=float(request_timeout),
            shutdown_timeout=float(shutdown_timeout),
        )


def build_worker_launch_spec(config: HarnessConfig) -> WorkerLaunchSpec:
    """Build the generic Core client spec from Hoomans adapter policy.

    Repository-specific environment aliases and worker argument selection are
    intentionally kept here.  Process lifecycle and neutral provider metadata
    are owned by PsychopatzCore's ``WorkerLaunchSpec``/``LuaProcess``.
    """

    profile = str(config.profile or "hoomans").strip().lower()
    environment = {
        "PNC_HARNESS_REPOSITORY": str(config.repository),
        "PNC_HARNESS_CORE_REPOSITORY": str(config.core_repository),
        "PZ_TEST_REPOSITORY": str(config.repository),
        "PZ_TEST_CORE_REPOSITORY": str(config.core_repository),
    }
    if config.candidate_overlay_root is not None:
        environment["PNC_HARNESS_CANDIDATE_OVERLAY_ROOT"] = str(
            config.candidate_overlay_root
        )
        environment["PNC_HARNESS_CANDIDATE_OVERLAY_MODULE"] = (
            config.candidate_overlay_module or ""
        )
    if config.hoomans_runtime is not None:
        environment["PZ_TEST_HOOMANS_RUNTIME"] = config.hoomans_runtime
    if config.core_runtime is not None:
        environment["PZ_TEST_CORE_RUNTIME"] = config.core_runtime
    if config.dynamic_trading_repository is not None:
        environment["PNC_HARNESS_DYNAMIC_TRADING_REPOSITORY"] = str(
            config.dynamic_trading_repository
        )
    if config.dynamic_trading_runtime is not None:
        environment["PZ_TEST_DYNAMIC_TRADING_RUNTIME"] = (
            config.dynamic_trading_runtime
        )

    worker_arguments = (
        (str(config.core_repository),)
        if profile == "core"
        else (str(config.repository), str(config.core_repository))
    )
    return WorkerLaunchSpec(
        lua_bin=config.lua_bin,
        worker_script=config.worker_script,
        core_repository=config.core_repository,
        working_directory=config.repository,
        profile=profile,
        provider_ids=config.provider_ids,
        materialization_mode=config.materialization_mode,
        worker_arguments=worker_arguments,
        environment=environment,
        startup_timeout=config.startup_timeout,
        request_timeout=config.request_timeout,
        shutdown_timeout=config.shutdown_timeout,
        max_message_bytes=config.max_message_bytes,
    )
