#!/usr/bin/env python3
"""Audit repeated root-Lua contract families without changing their runner.

The report is deliberately conservative: it identifies repeated setup and
subject candidates, then records why a merge or deletion is or is not safe.
Validation remains the existing tests/run_tests.py runner.
"""

from __future__ import annotations

from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
TEST_ROOT = ROOT / "tests"
OUTPUT = ROOT / "docs/Jobs/TestSuiteRationalization/R2_REPEATED_CONTRACT_AUDIT.json"
ASSERTION_RE = re.compile(
    r"\bT\.(?:equal|notEqual|truthy|falsy|contains|near|same|finish|error|raises)\s*\("
)
ASSERT_RE = re.compile(r"\bassert(?:\s*\.|\s*\()")
FINISH_RE = re.compile(r'T\.finish\s*\(\s*["\']([^"\']+)')
LITERAL_LOAD_RE = re.compile(
    r'(?:T\.(?:load|read)|dofile|require)\s*\(\s*["\']([^"\']+)["\']'
)


def metrics(path: Path) -> dict[str, int]:
    source = path.read_text(encoding="utf-8", errors="ignore")
    return {
        "loc": source.count("\n") + 1,
        "bytes": len(source.encode("utf-8")),
        "assertionCalls": len(ASSERTION_RE.findall(source)) + len(ASSERT_RE.findall(source)),
    }


def setup_fingerprint(path: Path) -> str:
    source = path.read_text(encoding="utf-8", errors="ignore")
    prefix = "\n".join(source.splitlines()[:45])
    normalized = re.sub(r"\s+", " ", prefix).strip()
    return hashlib.sha256(normalized.encode("utf-8")).hexdigest()[:16]


def file_record(path: Path) -> dict[str, object]:
    source = path.read_text(encoding="utf-8", errors="ignore")
    literals = sorted(set(LITERAL_LOAD_RE.findall(source)))
    return {
        "path": str(path.relative_to(ROOT)),
        "finishIDs": FINISH_RE.findall(source),
        "literalSubjects": literals[:40],
        "setupFingerprint": setup_fingerprint(path),
        "metrics": metrics(path),
    }


def group(name: str, paths: list[Path], disposition: str, evidence: list[str]) -> dict[str, object]:
    records = [file_record(path) for path in sorted(paths)]
    fingerprints = Counter(record["setupFingerprint"] for record in records)
    finish_ids = [finish for record in records for finish in record["finishIDs"]]
    subject_sets = Counter(" | ".join(record["literalSubjects"]) for record in records)
    return {
        "name": name,
        "fileCount": len(records),
        "loc": sum(record["metrics"]["loc"] for record in records),
        "bytes": sum(record["metrics"]["bytes"] for record in records),
        "assertionCalls": sum(record["metrics"]["assertionCalls"] for record in records),
        "distinctFinishIDs": len(set(finish_ids)),
        "distinctSubjectSets": len(subject_sets),
        "repeatedSetupFingerprints": {
            fingerprint: count for fingerprint, count in fingerprints.items() if count > 1
        },
        "records": records,
        "disposition": disposition,
        "evidence": evidence,
    }


def runner_validation() -> dict[str, object]:
    command = ["python3", "tests/run_tests.py", "--jobs", "4", "--timeout", "30"]
    result = subprocess.run(
        command,
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        check=False,
    )
    lines = result.stdout.strip().splitlines()
    return {
        "command": " ".join(command),
        "returncode": result.returncode,
        "result": lines[-1] if lines else "no runner output",
    }


def build() -> dict[str, object]:
    root_paths = sorted(TEST_ROOT.glob("*_smoke.lua"))
    presence = [path for path in root_paths if "presence_boundary" in path.stem]
    inventory = [path for path in root_paths if "inventory" in path.stem]
    mp_network = [
        path for path in root_paths
        if any(token in path.stem for token in ("mp", "network", "replica", "reconnect"))
    ]
    persistence = [
        path for path in root_paths
        if any(token in path.stem for token in ("persist", "save", "migration", "reload", "roundtrip"))
    ]
    npc_foundation = [path for path in root_paths if "npc_foundation" in path.stem]
    return {
        "schemaVersion": 1,
        "phase": "R2",
        "scope": "root tests/*_smoke.lua repeated contract families",
        "runner": "tests/run_tests.py (existing runner)",
        "validation": runner_validation(),
        "groups": [
            group(
                "presence-boundary",
                presence,
                "KEEP_BOUNDARY_SPECIFIC",
                [
                    "85 files expose distinct explicit finish IDs; the other 22 are still isolated and identified by their runner path. Every file inspects a concrete entry/provider ownership, load order, public facade, or internal-boundary contract.",
                    "The repeated loop shape is a diagnostic aid, not equivalent coverage: provider ownership, public functions, auto-load behavior, and role-specific seams differ by production entry point.",
                    "No safe merge preserves per-file module ownership and failure identity without creating an opaque boundary mega-test; no deletion gate is met.",
                ],
            ),
            group(
                "inventory",
                inventory,
                "KEEP_CANONICAL or KEEP_BOUNDARY_SPECIFIC per R1 path record",
                [
                    "Inventory files cover separate item state, equipment, UI, transfer, rollback, replication, persistence, and ownership outcomes.",
                    "Shared item-shaped fixtures do not prove the same client/server/Core authority or lifecycle contract; per-case diagnostics remain valuable.",
                    "The high-density family has no proven parity-equivalent deletion or table-driven replacement in the current runner.",
                ],
            ),
            group(
                "mp-network",
                mp_network,
                "KEEP_BOUNDARY_SPECIFIC per R1 path record",
                [
                    "MP/network candidates cross distinct client, server, replica, reconnect, death, snapshot, cleanup, and authority boundaries.",
                    "Imperative authority tests are retained because fixture-level shape checks cannot prove role admission or mutation ownership.",
                    "No merge is accepted when it would share mutable role state or hide a per-boundary failure identity.",
                ],
            ),
            group(
                "persistence-and-migration",
                persistence,
                "KEEP_BOUNDARY_SPECIFIC or KEEP_CANONICAL per R1 path record",
                [
                    "Persistence candidates cover roundtrip, repair, supported migration, import, reset, scale, identity, relationship, inventory, and travel contracts.",
                    "Still-supported schema/migration paths are explicitly retained; similarity of serialized fields is not deletion proof.",
                    "No merge or deletion passed all four deletion gates; the current process isolation is required for clean global state.",
                ],
            ),
            group(
                "npc-foundation-and-adopter",
                npc_foundation,
                "KEEP_CANONICAL; fixture extraction deferred",
                [
                    "The shared parity baseline is loaded by multiple focused tests, but those tests intentionally assert different identity, inventory, knowledge, migration, presentation, provider, and cross-adopter contracts.",
                    "The baseline file is itself an executable regression with assertions; extracting it into a support fixture would require moving its assertions and re-proving every dependent process boundary.",
                    "The current T.load baseline reuse is explicit and searchable; no test file is deleted or silently converted into an opaque mega-test without parity evidence.",
                ],
            ),
        ],
        "actions": {
            "merges": 0,
            "deletions": 0,
            "tierMoves": 0,
            "fixtureConsolidations": 0,
            "reason": "R2 review found repeated syntactic shapes but no evidence-proven redundant coverage. Preserve authority-boundary and isolation guarantees; continue with R3 legacy cross-reference and R4 Semantic Python tier review.",
        },
    }


if __name__ == "__main__":
    OUTPUT.write_text(json.dumps(build(), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUTPUT}")
