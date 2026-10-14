#!/usr/bin/env python3
"""Static regression smoke test for the Project Hoomans body lifecycle.

This is deliberately not the Project Hoomans Lua test harness and does not
start Project Zomboid.  It checks the source-level contracts that protect the
relog/restored-zombie path, then asks ``luac`` to parse the affected modules.
Live-game evidence is still required to prove that a particular restored
IsoZombie was removed and that materialization did not create a duplicate.
"""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MOD_ROOT = ROOT / "Contents" / "mods" / "ProjectHoomans"
VERSION_PATTERN = re.compile(r"^\d+\.\d+$")

RELATIVE_FILES = {
    "live_bodies": (
        "media/lua/shared/PNC/Core/Presence/PNC_BodyLifecycle/"
        "PNC_BodyLifecycle_LiveBodies.lua"
    ),
    "serialize": (
        "media/lua/shared/PNC/Core/Persistence/PNC_Persistence/"
        "PNC_Persistence_Serialize.lua"
    ),
    "deserialize": (
        "media/lua/shared/PNC/Core/Persistence/PNC_Persistence/"
        "PNC_Persistence_DeserializeFinalization.lua"
    ),
    "startup_coordinator": (
        "media/lua/shared/PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_"
        "Startup/PNC_BodyLifecycle_Startup_Coordinator.lua"
    ),
    "husk_reaper": (
        "media/lua/shared/PNC/Core/Presence/PNC_BodyLifecycle/"
        "PNC_BodyLifecycle_HuskReaper.lua"
    ),
    "startup_identity": (
        "media/lua/shared/PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_"
        "Startup/PNC_BodyLifecycle_Startup_Identity.lua"
    ),
    "record_cleanup": (
        "media/lua/shared/PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_"
        "Startup/PNC_BodyLifecycle_Startup_RecordCleanup.lua"
    ),
}

LUA_PARSE_FILES = (
    "live_bodies",
    "serialize",
    "deserialize",
    "startup_coordinator",
    "husk_reaper",
    "startup_identity",
    "record_cleanup",
)


def newest_runtime() -> Path:
    candidates = [
        child
        for child in MOD_ROOT.iterdir()
        if child.is_dir() and VERSION_PATTERN.fullmatch(child.name)
    ]
    if not candidates:
        raise RuntimeError(f"no numeric ProjectHoomans runtime under {MOD_ROOT}")
    return max(
        candidates,
        key=lambda path: tuple(int(part) for part in path.name.split(".")),
    )


def compact(source: str) -> str:
    """Make source-contract checks tolerant of line wrapping/indentation."""

    return re.sub(r"\s+", " ", source)


def check_contains(
    failures: list[str], label: str, source: str, needle: str
) -> None:
    if needle not in source:
        failures.append(f"{label}: missing `{needle}`")


def check_order(
    failures: list[str],
    label: str,
    source: str,
    *needles: str,
) -> None:
    positions = [source.find(needle) for needle in needles]
    if any(position < 0 for position in positions):
        missing = [
            needle for needle, position in zip(needles, positions) if position < 0
        ]
        failures.append(f"{label}: missing `{missing[0]}`")
    elif positions != sorted(positions):
        failures.append(f"{label}: lifecycle order is not preserved")


def main() -> int:
    failures: list[str] = []
    runtime = newest_runtime()
    sources: dict[str, str] = {}
    paths: dict[str, Path] = {}

    print(f"Project Hoomans body lifecycle source smoke ({runtime.name})")

    for name, relative in RELATIVE_FILES.items():
        path = runtime / relative
        paths[name] = path
        if not path.is_file():
            failures.append(f"{name}: source file not found: {path}")
            continue
        sources[name] = compact(path.read_text(encoding="utf-8"))

    live = sources.get("live_bodies", "")
    check_contains(
        failures,
        "detached hint capture",
        live,
        "local function captureDetachedBodyHint(record)",
    )
    check_contains(
        failures,
        "detached hint export",
        live,
        "Internal.CaptureDetachedBodyHint = captureDetachedBodyHint",
    )
    check_contains(
        failures,
        "detach preserves population identity",
        live,
        "record.liveBodyPopulationID = nil",
    )
    detach_start = live.find("function Internal.detachLiveBody")
    detach_source = live[detach_start:] if detach_start >= 0 else ""
    check_order(
        failures,
        "detach captures before clearing",
        detach_source,
        "captureDetachedBodyHint(record)",
        "record.runtime.bodyLease = nil",
        "record.liveBodyInstanceID = nil",
        "record.liveBodyPopulationID = nil",
    )

    serialize = sources.get("serialize", "")
    for needle in (
        "runtime.lastLiveBodyInstanceID",
        "runtime.lastLiveBodyPopulationID",
        "runtime.lastLiveBodyOnlineID",
        "runtime.lastLiveBodyLease",
        "populationId = populationID",
        "if instanceID == nil and populationID == nil",
    ):
        check_contains(failures, "body-hint persistence", serialize, needle)

    deserialize = sources.get("deserialize", "")
    check_contains(
        failures,
        "body-hint restore accepts population identity",
        deserialize,
        "bodyHint.instanceID ~= nil or bodyHint.populationId ~= nil",
    )
    for needle in (
        "record.runtime.startupBodyHint =",
        "record.runtime.lastLiveBodyInstanceID =",
        "record.runtime.lastLiveBodyPopulationID =",
    ):
        check_contains(failures, "body-hint restore", deserialize, needle)

    coordinator = sources.get("startup_coordinator", "")
    check_order(
        failures,
        "startup ledger seeding precedes cleanup",
        coordinator,
        "function Lifecycle.RunStartupBodyCleanupNow",
        "Lifecycle.SeedHuskLedgerFromRecords(now)",
        "Lifecycle.PumpStartupBodyCleanup(now, true)",
    )

    reaper = sources.get("husk_reaper", "")
    for needle in (
        "sameLedgerPosition(entry, zombie)",
        "tostring(entry.reason or \"\") ~= \"startup_seed\"",
        "queuedIdentity.outfitID",
        "isMarkedBody(record.zombie)",
        "local detached =",
        "Lifecycle.IdentityAudit.RecordRemoval",
        "\"husk_reaper_removal\"",
        "return detached",
    ):
        check_contains(failures, "husk revalidation/removal", reaper, needle)

    identity = sources.get("startup_identity", "")
    for needle in (
        "zombie.isDead",
        "zombie.isReanimatedPlayer",
        "ownership.IsForeignOwned",
        "Internal.IsProtectedBody = isProtectedBody",
    ):
        check_contains(failures, "protected-body guard", identity, needle)

    cleanup = sources.get("record_cleanup", "")
    check_order(
        failures,
        "ordinary zombie fail-closed path",
        cleanup,
        "if reason then",
        "elseif unresolved then",
        "never delete it as a naked-position shortcut",
    )
    check_contains(
        failures,
        "ordinary zombie remains blocked",
        cleanup,
        "blockReason = blockReason or \"unresolved_unmarked_body\"",
    )

    luac = shutil.which("luac")
    if luac:
        for name in LUA_PARSE_FILES:
            path = paths.get(name)
            if not path or not path.is_file():
                continue
            result = subprocess.run(
                [luac, "-p", str(path)],
                capture_output=True,
                text=True,
                check=False,
            )
            if result.returncode != 0:
                detail = (result.stderr or result.stdout).strip().splitlines()
                failures.append(
                    f"{name}: luac parse failed"
                    + (f" ({detail[-1]})" if detail else "")
                )
        print(f"  parsed {len(LUA_PARSE_FILES)} Lua lifecycle modules with luac")
    else:
        print("  SKIP: luac is not installed; source-contract checks still ran")

    if failures:
        print(f"SMOKE FAIL ({len(failures)} issue(s))", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        return 1

    print("SMOKE PASS: lifecycle hardening contracts are present")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
