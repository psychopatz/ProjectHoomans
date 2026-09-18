"""Portable runtime discovery and bounded harness configuration."""

from __future__ import annotations

import os
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path


class ConfigurationError(RuntimeError):
    """Raised when a required harness runtime cannot be discovered."""


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
        candidates.extend([Path(__file__).resolve().parents[2], Path.cwd()])
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


def discover_lua(explicit: str | Path | None = None) -> Path:
    if explicit:
        candidates = [str(explicit)]
    else:
        environment = os.environ.get("PNC_HARNESS_LUA")
        candidates = [environment] if environment else []
        candidates.extend(["lua", "luajit"])
    for candidate in candidates:
        found = shutil.which(candidate)
        if found:
            return Path(found).resolve()
        path = Path(candidate).expanduser()
        if path.is_file() and path.stat().st_mode & 0o111:
            return path.resolve()
    raise ConfigurationError(
        "could not locate a Lua executable; set PNC_HARNESS_LUA or use --lua"
    )


def probe_lua(lua_bin: Path, timeout: float = 2.0) -> tuple[bool, str]:
    try:
        result = subprocess.run(
            [str(lua_bin), "-v"],
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        return False, str(error)
    output = (result.stdout or result.stderr or "").strip().splitlines()
    version = output[0] if output else "unknown Lua version"
    if result.returncode != 0:
        return False, f"{version} (exit {result.returncode})"
    return True, version


@dataclass(frozen=True)
class HarnessConfig:
    repository: Path
    core_repository: Path
    lua_bin: Path
    worker_script: Path
    hoomans_runtime: str = "42.20"
    core_runtime: str = "42.20"
    startup_timeout: float = 8.0
    request_timeout: float = 5.0
    shutdown_timeout: float = 1.0
    max_message_bytes: int = 256 * 1024

    @classmethod
    def discover(
        cls,
        *,
        repository: str | Path | None = None,
        core_repository: str | Path | None = None,
        lua_bin: str | Path | None = None,
        worker_script: str | Path | None = None,
        startup_timeout: float = 8.0,
        request_timeout: float = 5.0,
        shutdown_timeout: float = 1.0,
    ) -> "HarnessConfig":
        repo = discover_repository(repository)
        core = discover_core(repo, core_repository)
        lua = discover_lua(lua_bin)
        worker = Path(worker_script) if worker_script else Path(__file__).with_name("lua") / "worker.lua"
        worker = worker.expanduser().resolve()
        if not worker.is_file():
            raise ConfigurationError(f"Lua worker script does not exist: {worker}")
        if startup_timeout <= 0 or request_timeout <= 0 or shutdown_timeout <= 0:
            raise ConfigurationError("timeouts must be positive")
        return cls(
            repository=repo,
            core_repository=core,
            lua_bin=lua,
            worker_script=worker,
            hoomans_runtime=os.environ.get("PZ_TEST_HOOMANS_RUNTIME", "42.20"),
            core_runtime=os.environ.get("PZ_TEST_CORE_RUNTIME", "42.20"),
            startup_timeout=float(startup_timeout),
            request_timeout=float(request_timeout),
            shutdown_timeout=float(shutdown_timeout),
        )
