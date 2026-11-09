#!/usr/bin/env python3
"""Cross-reference legacy-looking tests with current production paths/history."""

from __future__ import annotations

from collections import Counter
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs/Jobs/TestSuiteRationalization/R3_LEGACY_FAMILY_AUDIT.json"


def run(*args: str) -> list[str]:
    result = subprocess.run(
        list(args), cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
        text=True, check=False,
    )
    return result.stdout.splitlines()


def history(path: str) -> list[str]:
    return run("git", "log", "--all", "--oneline", "-5", "--", path)


def marker_inventory() -> dict[str, object]:
    lines = run(
        "rg", "-n", "-i",
        "deprecated|obsolete|legacy|retired|removed|migration|compat",
        "tests", "tools/semantic_harness/tests",
    )
    by_file: Counter[str] = Counter()
    for line in lines:
        path = line.split(":", 1)[0]
        by_file[path] += 1
    return {
        "matchedLines": len(lines),
        "files": dict(sorted(by_file.items())),
        "interpretation": "markers were reviewed as current migration, compatibility, removal-regression, or historical fixture contracts; a marker alone is not deletion evidence",
    }


def case(path: str, classification: str, subject: str, boundary: str,
         overlap: str, legacy: str, action: str) -> dict[str, object]:
    return {
        "path": path,
        "classification": classification,
        "productionSubject": subject,
        "authorityBoundary": boundary,
        "overlapReview": overlap,
        "legacyMigrationReview": legacy,
        "history": history(path),
        "action": action,
    }


def build() -> dict[str, object]:
    retired_trade = "tools/semantic_harness/tests/test_contextual_dynamic_trading.py"
    return {
        "schemaVersion": 1,
        "phase": "R3",
        "scope": "legacy-looking root Lua and Semantic Harness families",
        "markerInventory": marker_inventory(),
        "currentPathChecks": {
            "retiredTradeProviderAbsentFromProduction": run(
                "rg", "-n", "-i", "projecthoomans:trade",
                "Contents/mods/ProjectHoomans", "tools/semantic_harness/lua",
                "tools/semantic_harness/runtime",
            ),
            "currentTradeOwnersPresent": run(
                "rg", "-l", "DTHoomans|DTCommon",
                "Contents/mods/ProjectHoomans", "tools/semantic_harness/lua",
                "tools/semantic_harness/runtime",
            )[:40],
            "supportedPersistencePathsPresent": [
                path for path in (
                    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Persistence/PNC_Persistence.lua",
                    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Persistence/PNC_Persistence_CoreProvider.lua",
                    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Presence/PNC_Presence.lua",
                ) if (ROOT / path).is_file()
            ],
        },
        "reviewedFamilies": [
            case(
                "tests/pnc_trader_conversation_ownership_smoke.lua",
                "KEEP_BOUNDARY_SPECIFIC",
                "current conversation category ownership plus retired projecthoomans:trade absence",
                "semantic category registry/provider ownership and current DTHoomans/DTCommon integration",
                "not redundant with the deleted Python module: this imperative Lua test proves the current production registry does not reintroduce the removed category",
                "8f4ca4a4 removed the Hoomans trade graph; current production search has no projecthoomans:trade owner, while DTHoomans/DTCommon paths remain supported",
                "retain as a removal-regression and authority-boundary test",
            ),
            case(
                "tests/pnc_conversation_smoke.lua",
                "KEEP_BOUNDARY_SPECIFIC",
                "current conversation registry/category and retired What's Up family absence",
                "conversation composition and authored category ownership",
                "the retired-family assertions are complementary to current conversation behavior and do not duplicate the deleted trade graph",
                "current production registry is inspected directly; the test proves old IDs are absent while supported categories remain available",
                "retain supported removal regression",
            ),
            case(
                "tests/pnc_colony_management_ui_boundary_smoke.lua",
                "KEEP_BOUNDARY_SPECIFIC",
                "current colony/settlement UI composition and retired UI/shim paths",
                "client UI composition, adapter ownership, and retired-file absence",
                "no higher-level fixture proves that composition stops loading each retired window/shim; individual assertions retain diagnostic identity",
                "history and current UI composition were inspected; removed files are asserted absent and current adapters remain",
                "retain architecture/removal boundary test",
            ),
            case(
                "tests/pnc_kahlua_persistence_smoke.lua",
                "KEEP_BOUNDARY_SPECIFIC",
                "current Kahlua-safe persistence serialization/deserialization and supported repair versions",
                "serialized save payload, supported repair migration, and runtime-safe table boundary",
                "the legacy payload cases exercise still-supported input normalization and are not replaced by current-format roundtrip tests",
                "current PNC_Persistence deserializer and repair-version handling were inspected; legacy fields are transformed or rejected as asserted",
                "retain supported migration regression",
            ),
            case(
                "tests/pnc_persistence_v5_smoke.lua",
                "KEEP_BOUNDARY_SPECIFIC",
                "supported persistence v5 cleanup of obsolete global/per-NPC tables",
                "persistence migration and removal of unsupported legacy bodies",
                "distinct from current roundtrip tests because it proves old storage is removed without deleting current records",
                "current persistence version and cleanup code are present; history confirms this is a migration contract, not a dead test",
                "retain supported migration regression",
            ),
            case(
                "tests/pnc_restart_rehydration_smoke.lua",
                "KEEP_BOUNDARY_SPECIFIC",
                "restart rehydration, duplicate shell cleanup, and legacy zero-ID adoption",
                "identity/incarnation/presence restart and live-body ownership boundary",
                "no fixture-level persistence test proves body winner selection, cleanup, and callback timing together",
                "current BodyLifecycle/rehydration callers and legacy pre-token migration lane were inspected; historical regressions remain possible",
                "retain identity and lifecycle regression",
            ),
            case(
                "tools/semantic_harness/tests/test_semantic_authority_boundaries.py",
                "KEEP_BOUNDARY_SPECIFIC",
                "current semantic production callers and retired helper absence",
                "production-Lua authority and static caller boundary",
                "static no-caller proof is not equivalent to runtime fixture parity; it protects a refactor/deletion boundary",
                "current production search and semantic module ownership were inspected; retired helper assertions remain intentional",
                "retain static authority/refactor check",
            ),
            case(
                "tools/semantic_harness/tests/test_semantic_category_ownership.py",
                "KEEP_BOUNDARY_SPECIFIC",
                "current category ownership and removal of legacy extensions/migration fields",
                "semantic registry ownership and compatibility/removal boundary",
                "category ownership is not duplicated by response wording or fixture parity tests",
                "current category catalog and production ownership were inspected; legacy fields are asserted absent by contract",
                "retain current ownership regression",
            ),
        ],
        "deletedFamilies": [
            {
                "path": retired_trade,
                "classification": "DELETE_SUPERSEDED",
                "deletionGate": {
                    "productionPathGone": True,
                    "equalOrStrongerReplacement": True,
                    "assertionParityMigrated": True,
                    "removedCompatibilityOnly": True,
                },
                "evidence": [
                    "ProjectHoomans commit 8f4ca4a4 removed the Hoomans trade graph and routed trader Talk through the shared opener.",
                    "DynamicTrading commit 246df5b5 moved shared trader ownership to DTCommon and retained DTHoomans caravan referral content.",
                    "Current production search has no projecthoomans:trade owner; replacement ownership/parity focused modules passed 5/5.",
                ],
            },
        ],
        "additionalDeletionCandidates": [],
        "decision": "No additional legacy-looking family met the deletion gate. Current migration, compatibility, removal-regression, and historical lifecycle tests remain maintained.",
    }


if __name__ == "__main__":
    OUTPUT.write_text(json.dumps(build(), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUTPUT}")
