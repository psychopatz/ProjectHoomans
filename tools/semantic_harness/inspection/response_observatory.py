"""Bounded response-quality evidence from isolated *production Lua* worker cases.

Every row owns a disposable fixture worker. We do not implement a Python
response selector, write game saves, or merge cases' selection histories.
"""
from __future__ import annotations

from collections.abc import Callable
import hashlib
from pathlib import Path
import re
import subprocess
from typing import Any

from .conversation_inspector import build_conversation_inspector
from ..runtime.scenario import DEFAULT_SCENARIO, merge
from ..runtime.worker import LuaSemanticWorker

MAX_CASES = 8
MAX_UTTERANCES = 4


def run_quality_matrix(
    cases: list[dict[str, Any]],
    *,
    worker_factory: Callable[[dict[str, Any]], LuaSemanticWorker] = LuaSemanticWorker,
) -> dict[str, Any]:
    """Replay fixture cases through the same Lua runner as existing Semantic Lab."""
    if not isinstance(cases, list):
        raise ValueError("matrix cases must be a list")
    rows: list[dict[str, Any]] = []
    for index, case in enumerate(cases[:MAX_CASES]):
        if not isinstance(case, dict):
            raise ValueError("matrix case must be an object")
        overrides = case.get("scenario") or {}
        if not isinstance(overrides, dict):
            raise ValueError("matrix scenario must be an object")
        language = str(case.get("language", "EN")).upper()
        if language not in ("EN", "TL"):
            raise ValueError("matrix language must be EN or TL")
        utterances = case.get("utterances", [case.get("utterance", "hello")])
        if not isinstance(utterances, list) or not 1 <= len(utterances) <= MAX_UTTERANCES:
            raise ValueError("matrix requires 1 to 4 utterances per case")
        if any(not isinstance(text, str) or not 1 <= len(text) <= 200
               for text in utterances):
            raise ValueError("matrix utterance length must be 1 to 200 characters")
        scenario = merge(DEFAULT_SCENARIO, overrides)
        scenario.setdefault("runtime", {})["language"] = language
        with worker_factory(scenario) as worker:
            last = {}
            for utterance in utterances:
                last = worker.input(utterance)
            inspector = build_conversation_inspector(last)
        messages = [
            message["payload"] for message in last.get("messages", [])
            if message.get("speaker") == "npc"
            and isinstance(message.get("payload"), dict)
        ]
        keys = [str(message.get("key") or "") for message in messages]
        texts = [str(message.get("text") or "") for message in messages]
        effects = inspector.get("effects", {}).get("sideEffects", {})
        actions = effects.get("actionCount", 0)
        expected = case.get("expected") or {}
        if not isinstance(expected, dict):
            raise ValueError("matrix expected must be an object")
        checks: dict[str, bool] = {}
        if "lastKey" in expected:
            checks["lastKey"] = bool(keys) and keys[-1] == expected["lastKey"]
        if "maxActions" in expected:
            checks["maxActions"] = actions <= int(expected["maxActions"])
        if "minActions" in expected:
            checks["minActions"] = actions >= int(expected["minActions"])
        if "accepted" in expected:
            checks["accepted"] = last.get("accepted") is expected["accepted"]
        rows.append({
            "index": index, "label": str(case.get("label") or f"case-{index + 1}")[:96],
            "language": language, "sourceKind": "FIXTURE",
            "workerKind": "production_lua", "utterances": utterances,
            "responseKeys": keys[-4:], "responseTexts": texts[-4:],
            "actions": actions,
            "transportCount": effects.get("transportCount", 0),
            "accepted": last.get("accepted"),
            "checks": checks,
            "status": "PASS" if checks and all(checks.values())
                else "FAIL" if checks else "OBSERVED_ONLY",
        })
    return {
        "ok": len(cases) <= MAX_CASES
        and all(row["status"] != "FAIL" for row in rows),
        "type": "response_quality_matrix", "schemaVersion": 1,
        "sourceKind": "FIXTURE", "totalRequested": len(cases),
        "caseCount": len(rows), "truncated": len(cases) > MAX_CASES,
        "passed": sum(row["status"] == "PASS" for row in rows),
        "failed": sum(row["status"] == "FAIL" for row in rows),
        "observedOnly": sum(row["status"] == "OBSERVED_ONLY" for row in rows),
        "cases": rows,
    }


def source_evidence_from_paths(
    repository: Path, core: Path,
) -> dict[str, Any]:
    """Read-only checkout revisions plus hashes of the inspected engine seams.

    Git HEAD alone does not describe uncommitted edits; the byte hashes do.
    This is *not* a verified per-pool owning-source attribution.
    """
    def revision(directory: Path) -> str:
        done = subprocess.run(
            ["git", "-C", str(directory), "rev-parse", "HEAD"],
            capture_output=True, text=True, timeout=2, check=False,
        )
        return done.stdout.strip() if done.returncode == 0 else "UNKNOWN"

    files = (
        repository / "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/PNC_SemanticDialogueResponseCatalog_Selection.lua",
        repository / "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/PNC_SemanticDialogueResponseCatalog_Core.lua",
        repository / "tools/semantic_harness/lua/worker/FlowEditor.lua",
    )
    hashes = {}
    for path in files:
        hashes[path.name] = (
            hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file()
            else "UNKNOWN"
        )
    return {
        "repositoryHEAD": revision(repository),
        "coreHEAD": revision(core),
        "inspectedSeamSHA256": hashes,
        "perPoolSourceOwnerVerified": False,
    }


def source_evidence(worker: LuaSemanticWorker) -> dict[str, Any]:
    return source_evidence_from_paths(
        worker.config.repository, worker.config.core_repository
    )


def review_variant_proposal(
    worker: LuaSemanticWorker, proposal: dict[str, Any],
) -> dict[str, Any]:
    """Text-only preflight. Never writes or promotes content to authority."""
    if not isinstance(proposal, dict):
        raise ValueError("variant proposal must be a JSON object")
    pool_id = proposal.get("poolID")
    if not isinstance(pool_id, str):
        raise ValueError("variant proposal requires poolID")
    expected = proposal.get("expectedContentFingerprint")
    if not isinstance(expected, str) or not expected.startswith("catalog-v1:"):
        raise ValueError("variant proposal needs baseline content fingerprint")
    entries = proposal.get("variants")
    if not isinstance(entries, list) or not 1 <= len(entries) <= 16:
        raise ValueError("variant proposal needs 1 to 16 existing variant IDs")
    details = worker.response_pool_detail(pool_id, limit=16)
    if expected != details["contentFingerprint"]:
        return {
            "ok": False, "type": "response_variant_proposal_review",
            "schemaVersion": 1, "reason": "stale_baseline",
            "currentContentFingerprint": details["contentFingerprint"],
            "writes": 0,
        }
    by_id = {row["id"]: row for row in details["variants"]}
    seen = set()
    errors: list[str] = []
    diffs = []
    proposed_text = set()
    for entry in entries:
        if not isinstance(entry, dict) or set(entry) != {"id", "EN", "TL"}:
            errors.append("only id, EN and TL are allowed; metadata edits forbidden")
            continue
        id_value = entry["id"]
        if not isinstance(id_value, str) or id_value not in by_id or id_value in seen:
            errors.append("unknown_or_duplicate_variant_id")
            continue
        seen.add(id_value)
        en, tl = entry["EN"], entry["TL"]
        if any(not isinstance(line, str) or not 1 <= len(line) <= 256
               for line in (en, tl)):
            errors.append("invalid_response_text_length")
            continue
        placeholders = lambda line: sorted(set(re.findall(r"%[1-9][0-9]*", line)))
        if placeholders(en) != placeholders(tl):
            errors.append("placeholder_parity_mismatch")
            continue
        if (en, tl) in proposed_text:
            errors.append("duplicate_proposed_translation_pair")
            continue
        proposed_text.add((en, tl))
        diffs.append({
            "variantID": id_value,
            "beforeFallbackEN": by_id[id_value]["fallback"],
            "proposedEN": en, "proposedTL": tl,
            "preservedWhen": by_id[id_value].get("when"),
            "preservedPriority": by_id[id_value].get("priority"),
            "preservedPlanSummary": by_id[id_value].get("planSummary"),
        })
    return {
        "ok": not errors, "schemaVersion": 1,
        "type": "response_variant_proposal_review",
        "poolID": pool_id, "contentFingerprint": expected,
        "errors": errors, "proposedChanges": diffs,
        "sourcePath": details.get("sourcePath", "UNKNOWN"),
        "canonicalOwnerVerified": False,
        "semanticReviewRequired": True,
        "isolatedLuaReplayCompleted": False,
        "approved": False, "writes": 0,
        "reason": "review_required" if not errors else "preflight_rejected",
    }


def compare_quality_reports(
    baseline: dict[str, Any], candidate: dict[str, Any],
) -> dict[str, Any]:
    """Compare two *reported* production-Lua fixture runs, without replaying.

    Source metadata remains attached and missing/untested cases stay unknown.
    """
    for report in (baseline, candidate):
        if (not isinstance(report, dict)
                or report.get("type") != "response_quality_matrix"
                or report.get("schemaVersion") != 1
                or report.get("sourceKind") != "FIXTURE"
                or not isinstance(report.get("cases"), list)
                or report.get("truncated", False)
                or len(report["cases"]) > MAX_CASES):
            raise ValueError("invalid, truncated, or unverified quality report")
    def indexed(rows):
        result = {}
        for case in rows:
            key = (case.get("label"), case.get("language"))
            if key in result or not all(key):
                raise ValueError("duplicate or incomplete comparison case")
            result[key] = case
        return result

    before, after = indexed(baseline["cases"]), indexed(candidate["cases"])
    changes = []
    skipped = []
    regressions = []
    for key in sorted(before.keys() | after.keys()):
        left, right = before.get(key), after.get(key)
        if left is None or right is None:
            skipped.append({"label": key[0], "language": key[1],
                            "reason": "not_run_in_both_reports"})
            continue
        changed = {}
        for field in ("responseKeys", "responseTexts", "actions",
                      "transportCount", "accepted", "status"):
            if left.get(field) != right.get(field):
                changed[field] = {
                    "baseline": left.get(field),
                    "candidate": right.get(field),
                }
        if changed:
            changes.append({"label": key[0], "language": key[1],
                            "diff": changed})
        if left.get("status") == "PASS" and right.get("status") == "FAIL":
            regressions.append({"label": key[0], "language": key[1],
                                "reason": "expected_assertion_regressed"})
    return {
        "ok": len(regressions) == 0 and not skipped,
        "type": "response_quality_comparison", "schemaVersion": 1,
        "comparisonKind": "stored_production_lua_fixture_reports",
        "baselineSourceEvidence": baseline.get("sourceEvidence", "UNKNOWN"),
        "candidateSourceEvidence": candidate.get("sourceEvidence", "UNKNOWN"),
        "comparedCaseCount": len(before.keys() & after.keys()),
        "changes": changes, "regressions": regressions, "skipped": skipped,
        "notNativeAccepted": True, "notIsolatedCandidateSourceProof": True,
    }
