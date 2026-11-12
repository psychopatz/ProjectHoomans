#!/usr/bin/env python3
"""Generate a conservative inventory of the Project Hoomans test estate.

This is an inventory/reporting tool, not a second test framework.  It records
maintained tests, fixtures, workers, runners, and shared harness code so that
family-level rationalization has an auditable starting point.  Executable
tests default to UNKNOWN_KEEP; a name match is never treated as deletion
evidence.
"""

from __future__ import annotations

import argparse
import ast
from collections import Counter, defaultdict
from datetime import datetime, timezone
import json
import re
import subprocess
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[1]
CORE_ROOT = ROOT.parent / "psychopatzCore"

CLASSIFICATIONS = {
    "KEEP_CANONICAL",
    "KEEP_BOUNDARY_SPECIFIC",
    "MERGE",
    "MOVE_TO_FOCUSED",
    "MOVE_TO_ACCEPTANCE",
    "DELETE_DUPLICATE",
    "DELETE_SUPERSEDED",
    "REPAIR",
    "UNKNOWN_KEEP",
}

LUA_ASSERTION_RE = re.compile(
    r"\bT\.(?:equal|notEqual|truthy|falsy|contains|near|same|finish|error|raises)\s*\("
)
LUA_ASSERT_RE = re.compile(r"\bassert(?:\s*\.|\s*\()")
PY_ASSERTION_RE = re.compile(
    r"\b(?:assert|fail|assert[A-Z][A-Za-z0-9_]*)\s*\("
)
SUBJECT_RE = re.compile(
    r"(?:T\.(?:load|read|path)|dofile|require)\s*\(\s*['\"]([^'\"]+)['\"]"
)
MEDIA_PATH_RE = re.compile(r"(?:media/lua|tools/providers/pnc)[^'\"\s)]+")
BOUNDARY_TOKENS = (
    "authority",
    "client",
    "death",
    "identity",
    "incarnation",
    "inventory",
    "live",
    "migration",
    "mp",
    "network",
    "npc",
    "persistence",
    "presence",
    "reconnect",
    "relationship",
    "semantic",
    "server",
    "sp",
    "transition",
)

DOMAIN_RULES = (
    ("semantic", ("semantic", "dialogue", "llm", "marketsense")),
    ("conversation", ("conversation", "talk", "response", "speech")),
    ("inventory", ("inventory", "item", "gift", "equipment", "trade")),
    ("faction_community", ("faction", "community", "settlement", "colony")),
    ("mp_network", ("mp", "network", "replica", "multiclient", "reconnect")),
    ("facility_building", ("facility", "building", "construction", "site")),
    ("abstract_world_traversal", ("abstract", "traversal", "travel", "world", "path", "journey")),
    ("combat_zombies", ("combat", "zombie", "melee", "firearm", "aggro", "threat")),
    ("presence_body", ("presence", "body", "corpse", "death", "puppet", "wound")),
    ("map", ("map", "sector", "perception", "nearby", "water")),
    ("companion", ("companion", "follower", "recruit")),
    ("tasking_work", ("task", "work", "job", "duty", "camp", "sleep")),
    ("fishing_scavenge", ("fishing", "fish", "scavenge", "resource", "supply")),
    ("animation", ("animation", "scene", "voice", "appearance", "visual")),
    ("persistence", ("persist", "save", "migration", "import", "reload", "roundtrip")),
    ("compatibility", ("compat", "adapter", "bandit", "necroa", "projectalife")),
    ("player_client_server", ("player", "client", "server", "authority", "presence_boundary")),
    ("npc_actor_lifecycle", ("npc", "actor", "identity", "incarnation", "lifecycle")),
)

EVIDENCE_BACKED_REPAIRS = {
    "tests/pnc_companion_commands_smoke.lua": {
        "evidence": [
            "6fa916ba expanded command phrase families; current rejection pool retains the semantic rejection ID and site-safety meaning across authored variants",
            "focused and root Lua suites pass after adapting the assertion to the current authored meaning set",
        ],
        "overlap": "later presentation assertions already cover missing-site explanation; this assertion remains the semantic response-pool boundary",
        "action": "repair stale single-word expectation to accept the current authored safety/exposure vocabulary",
    },
    "tests/pnc_semantic_harness_worker_modules_smoke.lua": {
        "evidence": [
            "9c6e90c7 intentionally changed aligned Lua/Python protocol bounds from 512 KiB to 1 MiB",
            "Lua protocol smoke and Python protocol tests pass with the current 1 MiB contract",
        ],
        "overlap": "Python and Lua protocol tests cover the same bound from their respective sides; both remain canonical boundary checks",
        "action": "repair stale Lua expectation to the current aligned protocol contract",
    },
    "tests/pnc_semantic_horde_command_ack_smoke.lua": {
        "evidence": [
            "6fa916ba replaced the former horde acknowledgement wording with the current generated phrase families",
            "semantic IDs, reaction-style routing, invalid-command rejection, and ordinary command path remain asserted",
        ],
        "overlap": "no deletion; response-pool identity and authority checks are complementary to the current phrase realization",
        "action": "repair stale authored wording expectations while retaining semantic routing assertions",
    },
    "tests/pnc_semantic_horde_tactical_prompt_smoke.lua": {
        "evidence": [
            "6fa916ba/9c6e90c7 expanded authored combat phrase families; current shaken prompt is non-profanity horde wording",
            "typed COMBAT offers, encounter identity, lifecycle projection, and click-to-IR authority remain asserted",
        ],
        "overlap": "the changed phrase assertion does not replace the stronger typed-offer and authority-boundary checks",
        "action": "repair stale profanity-only expectation to the current authored prompt wording",
    },
    "tests/pnc_semantic_local_route_smoke.lua": {
        "evidence": [
            "f544e901 expanded generated knowledge and greeting phrase families; current fishing/weather responses are authored variants",
            "local deterministic routing, provider suppression, topic state, provenance, and no-LLM assertions remain intact",
        ],
        "overlap": "phrase wording remains a current content contract; routing and provider-boundary assertions are not merged or removed",
        "action": "repair stale canonical wording expectations to current generated content",
    },
}

CANONICAL_BOUNDARY_ENTRIES = {
    "tests/refactor_binding_smoke.py": {
        "evidence": [
            "--all scans every maintained 42.20 Lua file for file-scoped helper leaks",
            "the scan caught and validated a real split ownership defect in the first P1 repair batch",
        ],
        "overlap": "no equivalent high-level fixture proves Lua file-scope/private-helper binding",
        "action": "retain as the canonical static refactor-boundary check; run changed-file mode for fast feedback and --all in broader validation",
    },
}

SUPERSEDED_ENTRIES = {
    "tools/providers/pnc/tests/test_contextual_dynamic_trading.py": {
        "evidence": [
            "ProjectHoomans commit 8f4ca4a4 removed the Hoomans trade graph and routes trader Talk through the shared opener",
            "DynamicTrading commit 246df5b5 moved shared trader ownership to DTCommon and retained only DTHoomans caravan referral content",
            "replacement ownership and parity families passed 5/5 focused modules",
        ],
        "overlap": "all four cases required the retired projecthoomans:trade provider/category; replacement tests cover the current DTCommon owner and Hoomans referral boundary",
        "action": "delete superseded module after equal-or-stronger replacement and removed-production-path proof",
    },
}


def run_git(*arguments: str, cwd: Path = ROOT) -> str:
    try:
        result = subprocess.run(
            ["git", *arguments],
            cwd=cwd,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return ""
    return result.stdout.strip()


def tracked_files() -> list[Path]:
    raw = run_git("ls-files", "-z")
    if not raw:
        return []
    return [Path(item) for item in raw.split("\0") if item]


def in_scope(path: Path) -> bool:
    parts = path.parts
    if not parts:
        return False
    if parts[0] == "tests":
        return True
    if parts[:3] == ("tools", "unique_npc_manager", "tests"):
        return True
    return parts[:2] == ("tools", "semantic_harness")


def read_text(path: Path) -> str:
    try:
        return (ROOT / path).read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return ""


def python_metrics(source: str) -> dict[str, int]:
    metrics = {"testMethods": 0, "testClasses": 0, "assertionCalls": 0}
    metrics["assertionCalls"] = len(PY_ASSERTION_RE.findall(source))
    try:
        tree = ast.parse(source)
    except SyntaxError:
        return metrics
    for node in ast.walk(tree):
        if isinstance(node, ast.ClassDef) and (
            node.name.startswith("Test") or any(
                isinstance(base, ast.Name) and base.id == "TestCase"
                for base in node.bases
            )
        ):
            metrics["testClasses"] += 1
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and (
            node.name.startswith("test")
        ):
            metrics["testMethods"] += 1
    return metrics


def lua_metrics(source: str) -> dict[str, int]:
    return {
        "assertionCalls": len(LUA_ASSERTION_RE.findall(source))
        + len(LUA_ASSERT_RE.findall(source)),
        "testMethods": 1 if "T.finish" in source else 0,
        "testClasses": 0,
    }


def subjects(source: str) -> list[str]:
    values = list(SUBJECT_RE.findall(source))
    values.extend(MEDIA_PATH_RE.findall(source))
    result: list[str] = []
    for value in values:
        if value not in result:
            result.append(value)
        if len(result) >= 24:
            break
    return result


def family_for(path: Path) -> str:
    stem = path.stem
    if path.parts[:2] == ("tools", "semantic_harness"):
        if path.parts[2:3] == ("tests",) and stem.startswith("test_"):
            return "semantic/python/" + stem[5:]
        if path.parts[2:4] == ("lua", "worker"):
            return "semantic/worker/" + stem
        if path.parts[2:3] in {"fixtures", "scenarios"}:
            return "semantic/fixture/" + stem
        return "semantic/support/" + "/".join(path.parts[2:-1] or (stem,))
    if path.parts[:3] == ("tools", "unique_npc_manager", "tests"):
        return "unique_npc_manager/" + stem
    if path.parts[:2] == ("tests", "native"):
        normalized = re.sub(
            r"_(?:native_(?:reload|write)_smoke|native_smoke|live_scenario|smoke)$",
            "",
            stem,
        )
        return "native/" + normalized
    if path.parts[:1] == ("tests",):
        normalized = re.sub(
            r"_(?:presence_boundary|smoke|test)$", "", stem
        )
        return "lua/" + normalized
    return "unclassified/" + stem


def role_runner_tier(path: Path) -> tuple[str, str, str, bool]:
    parts = path.parts
    name = path.name
    if parts[:2] == ("tests", "native"):
        return "native acceptance fixture", "PZ native harness / user-owned", "NATIVE", True
    if parts[:1] == ("tests",) and name.endswith("_smoke.lua"):
        return "lua test", "tests/run_tests.py", "DEFAULT", True
    if parts[:1] == ("tests",) and path.suffix == ".py":
        return "Python test or runner", "python -m unittest discover -s tests", "FAST", name.startswith("test_")
    if parts[:3] == ("tools", "unique_npc_manager", "tests"):
        return "Python test", "python -m unittest discover -s tools/unique_npc_manager/tests", "FAST", name.startswith("test_")
    if parts[:2] == ("tools", "semantic_harness"):
        area = parts[2] if len(parts) > 2 else ""
        if area == "tests" and name.startswith("test_"):
            return "semantic Python acceptance test", "psychopatzCore/tools/semantic_harness/testing/python_runner.py", "ACCEPTANCE", True
        if area in {"fixtures", "scenarios"} or path.suffix == ".json":
            return "declarative semantic fixture", "existing semantic harness callers", "ACCEPTANCE", False
        if area == "lua" and len(parts) > 3 and parts[3] == "worker":
            return "semantic Lua worker", "existing semantic Python harness", "ACCEPTANCE", False
        if area in {"testing", "testing-infra"} or name in {"run_harness.sh", "__main__.py"}:
            return "shared runner/infrastructure", "existing semantic harness runners", "FAST", False
        return "semantic harness support", "existing semantic harness runners", "ACCEPTANCE", False
    return "maintained support", "repository-specific runner", "FOCUSED", False


def boundaries(path: Path, source: str) -> list[str]:
    haystack = (str(path) + "\n" + source).casefold()
    found = [token for token in BOUNDARY_TOKENS if token in haystack]
    if path.parts[:2] == ("tests", "native"):
        found.append("native runtime")
    return list(dict.fromkeys(found)) or ["not inferred; inspect family"]


def domain_for(path: Path, source: str) -> str:
    """Return an initial routing domain; review evidence must refine it."""
    if path.parts[:1] == ("tests",):
        # Root suite routing starts from the test family name. Production
        # subjects/callers are recorded separately during domain review; using
        # the entire source here would classify every cross-domain smoke file
        # by incidental T.load strings and hide the actual review backlog.
        haystack = path.stem.casefold()
    elif path.parts[:3] == ("tools", "unique_npc_manager", "tests"):
        haystack = path.stem.casefold()
    else:
        haystack = (str(path) + "\n" + source).casefold()
    if path.parts[:2] == ("tools", "semantic_harness"):
        prefix = "semantic_python" if path.parts[2:3] == ("tests",) else "semantic_harness"
    elif path.parts[:1] == ("tests",):
        prefix = "root_lua"
    elif path.parts[:3] == ("tools", "unique_npc_manager", "tests"):
        prefix = "unique_npc"
    else:
        prefix = "support"
    for domain, tokens in DOMAIN_RULES:
        if any(token in haystack for token in tokens):
            return prefix + ":" + domain
    return prefix + ":other"


def initial_classification(role: str, native: bool) -> tuple[str, str, str, str]:
    return (
        "UNREVIEWED",
        "",
        "perform production-subject, boundary, overlap, legacy, and cost review",
        "pending_family_review",
    )


def repo_state(root: Path) -> dict[str, Any]:
    upstream = run_git("rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}")
    ahead_behind = run_git("rev-list", "--left-right", "--count", "HEAD...@{u}") if upstream else ""
    status = run_git("status", "--porcelain=v1")
    worktrees = []
    current: dict[str, str] = {}
    for line in run_git("worktree", "list", "--porcelain").splitlines():
        if line.startswith("worktree "):
            if current:
                worktrees.append(current)
            current = {"path": line[9:]}
        elif line.startswith("HEAD "):
            current["head"] = line[5:]
        elif line.startswith("branch "):
            current["branch"] = line[7:]
    if current:
        worktrees.append(current)
    core_state = {}
    if CORE_ROOT.is_dir():
        core_state = {
            "root": str(CORE_ROOT),
            "head": run_git("rev-parse", "HEAD", cwd=CORE_ROOT),
            "branch": run_git("rev-parse", "--abbrev-ref", "HEAD", cwd=CORE_ROOT),
            "status": run_git("status", "--porcelain=v1", cwd=CORE_ROOT).splitlines(),
        }
    return {
        "root": str(root),
        "branch": run_git("rev-parse", "--abbrev-ref", "HEAD"),
        "head": run_git("rev-parse", "HEAD"),
        "upstream": upstream,
        "aheadBehind": ahead_behind,
        "status": status.splitlines(),
        "worktrees": worktrees,
        "core": core_state,
    }


def load_lua_reports(paths: Iterable[Path]) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    for report_path in paths:
        try:
            report = json.loads(report_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        for item in report.get("results", []):
            path = item.get("path")
            if not path:
                continue
            try:
                relative = str(Path(path).resolve().relative_to(ROOT))
            except ValueError:
                relative = str(path)
            result[relative] = {
                "status": item.get("status"),
                "elapsedSeconds": item.get("elapsed"),
                "timedOut": item.get("timedOut", False),
            }
    return result


def load_review_ledger() -> dict[str, Any]:
    path_reviews: dict[str, Any] = {}
    domain_reviews: dict[str, Any] = {}
    ledger_paths = (
        ROOT / "docs/Jobs/TestSuiteRationalization/R1_ROOT_DOMAIN_REVIEW.json",
        ROOT / "docs/Jobs/TestSuiteRationalization/ESTATE_REVIEW.json",
        ROOT / "docs/Jobs/TestSuiteRationalization/R4_SEMANTIC_SLOW_REVIEW.json",
    )
    for ledger_path in ledger_paths:
        try:
            value = json.loads(ledger_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if not isinstance(value, dict):
            continue
        ledger_paths_value = value.get("pathReviews")
        ledger_domains_value = value.get("domainReviews")
        if isinstance(ledger_paths_value, dict):
            path_reviews.update(ledger_paths_value)
        if isinstance(ledger_domains_value, dict):
            domain_reviews.update(ledger_domains_value)
    return {
        "pathReviews": path_reviews,
        "domainReviews": domain_reviews,
    }


def build_manifest(lua_reports: Iterable[Path]) -> dict[str, Any]:
    entries: list[dict[str, Any]] = []
    family_paths: defaultdict[str, list[str]] = defaultdict(list)
    reports = load_lua_reports(lua_reports)
    review_ledger = load_review_ledger()
    path_reviews = review_ledger["pathReviews"]
    for path in tracked_files():
        if not in_scope(path):
            continue
        source = read_text(path)
        active = (ROOT / path).is_file()
        role, runner, tier, executable = role_runner_tier(path)
        family = family_for(path)
        domain = domain_for(path, source)
        classification, overlap, action, disposition = initial_classification(
            role, path.parts[:2] == ("tests", "native")
        )
        review_state = "UNREVIEWED"
        classification = "UNREVIEWED"
        overlap = ""
        action = "perform production-subject, boundary, overlap, legacy, and cost review"
        disposition = "pending_family_review"
        repair = EVIDENCE_BACKED_REPAIRS.get(str(path))
        evidence: list[str] = []
        if repair:
            review_state = "REVIEWED"
            classification = "REPAIR"
            overlap = repair["overlap"]
            action = repair["action"]
            disposition = "retained_repaired"
            evidence = list(repair["evidence"])
        canonical = CANONICAL_BOUNDARY_ENTRIES.get(str(path))
        if canonical:
            review_state = "REVIEWED"
            classification = "KEEP_BOUNDARY_SPECIFIC"
            overlap = canonical["overlap"]
            action = canonical["action"]
            disposition = "retained_canonical"
            evidence = list(canonical["evidence"])
        superseded = SUPERSEDED_ENTRIES.get(str(path))
        if superseded:
            review_state = "REVIEWED"
            classification = "DELETE_SUPERSEDED"
            overlap = superseded["overlap"]
            action = superseded["action"]
            disposition = "deleted_superseded"
            evidence = list(superseded["evidence"])
        ledger_review = path_reviews.get(str(path))
        if isinstance(ledger_review, dict):
            ledger_classification = str(ledger_review.get("classification", "UNREVIEWED"))
            if ledger_classification in CLASSIFICATIONS and ledger_classification != "UNREVIEWED":
                review_state = "REVIEWED"
                classification = ledger_classification
                overlap = str(ledger_review.get("overlap", ""))
                action = str(ledger_review.get("action", ""))
                disposition = str(ledger_review.get("finalDisposition", "retained_reviewed"))
            else:
                review_state = "UNREVIEWED"
                classification = "UNREVIEWED"
                overlap = ""
                action = "perform production-subject, boundary, overlap, legacy, and cost review"
                disposition = "pending_family_review"
            ledger_evidence = ledger_review.get("evidence", [])
            evidence = list(ledger_evidence) if isinstance(ledger_evidence, list) else []
        metrics = (
            lua_metrics(source)
            if path.suffix == ".lua"
            else python_metrics(source)
            if path.suffix == ".py"
            else {"testMethods": 0, "testClasses": 0, "assertionCalls": 0}
        )
        entry: dict[str, Any] = {
            "path": str(path),
            "maintained": active,
            "family": family,
            "domain": domain,
            "role": role,
            "runner": runner,
            "tier": tier,
            "executableTest": executable,
            "reviewState": review_state,
            "subjects": subjects(source),
            "boundaries": boundaries(path, source),
            "classification": classification,
            "overlap": overlap,
            "action": action,
            "finalDisposition": disposition,
            "evidence": evidence,
            "metrics": metrics,
        }
        if str(path) in reports:
            entry["baseline"] = reports[str(path)]
        if isinstance(ledger_review, dict):
            entry["review"] = ledger_review
        elif canonical:
            entry["review"] = {
                "classification": "KEEP_BOUNDARY_SPECIFIC",
                "finalDisposition": "retained_canonical",
                "productionSubjectsInspected": [
                    "maintained 42.20 Lua estate file-scoped helper ownership"
                ],
                "callersInspected": [
                    "tests/refactor_binding_smoke.py changed-file mode",
                    "tests/refactor_binding_smoke.py --all broad static mode",
                ],
                "authorityBoundary": [
                    "static cross-file private-helper binding and module ownership"
                ],
                "assertionPurpose": {
                    "scan": "all maintained 42.20 Lua files",
                    "findingType": "cross-file private helper reference",
                },
                "overlapCandidates": [
                    "no equivalent high-level fixture proves Lua file-scope/private-helper binding"
                ],
                "overlapReview": canonical["overlap"],
                "legacyMigration": {
                    "historyTip": "first P1 repair batch caught a real split-ownership defect",
                    "sourceMarkers": [],
                    "review": "static ownership check remains current and is not a retired migration shim",
                },
                "cost": {
                    "assertionCalls": metrics["assertionCalls"],
                    "tier": "FOCUSED",
                },
                "evidence": list(canonical["evidence"]),
                "action": canonical["action"],
                "overlap": canonical["overlap"],
            }
        entries.append(entry)
        family_paths[family].append(str(path))

    family_entries = []
    for family in sorted(family_paths):
        members = [entry for entry in entries if entry["family"] == family]
        classifications = {entry["classification"] for entry in members}
        domains = sorted({entry["domain"] for entry in members})
        review_states = {entry["reviewState"] for entry in members}
        if "UNREVIEWED" in review_states:
            review_state = "UNREVIEWED"
            review_status = "UNREVIEWED"
        else:
            review_state = "REVIEWED"
            if "REPAIR" in classifications:
                review_status = "reviewed_repaired"
            elif "DELETE_SUPERSEDED" in classifications:
                review_status = "reviewed_deleted_superseded"
            elif "KEEP_BOUNDARY_SPECIFIC" in classifications:
                review_status = "reviewed_boundary_specific"
            elif "KEEP_CANONICAL" in classifications:
                review_status = "reviewed_canonical"
            else:
                review_status = "reviewed_unknown_keep"
        evidence = []
        for entry in members:
            for item in entry["evidence"]:
                if item not in evidence:
                    evidence.append(item)
        subjects_seen = []
        boundaries_seen = []
        for entry in members:
            for item in entry["subjects"]:
                if item not in subjects_seen:
                    subjects_seen.append(item)
            for item in entry["boundaries"]:
                if item not in boundaries_seen:
                    boundaries_seen.append(item)
        family_entries.append({
            "family": family,
            "paths": family_paths[family],
            "domains": domains,
            "domain": domains[0] if len(domains) == 1 else "mixed",
            "runners": sorted({entry["runner"] for entry in members}),
            "tiers": sorted({entry["tier"] for entry in members}),
            "classifications": sorted(classifications),
            "executableTests": sum(entry["executableTest"] for entry in members),
            "assertionCalls": sum(entry["metrics"]["assertionCalls"] for entry in members),
            "subjects": subjects_seen,
            "boundaries": boundaries_seen,
            "reviewEvidence": evidence,
            "reviewState": review_state,
            "reviewStatus": review_status,
        })

    active_entries = [entry for entry in entries if entry["maintained"]]
    active_families = {
        entry["family"] for entry in active_entries
    }
    role_counts = Counter(entry["role"] for entry in entries)
    tier_counts = Counter(entry["tier"] for entry in entries)
    active_role_counts = Counter(entry["role"] for entry in active_entries)
    active_tier_counts = Counter(entry["tier"] for entry in active_entries)
    classification_counts = Counter(entry["classification"] for entry in entries)
    review_state_counts = Counter(entry["reviewState"] for entry in entries)
    family_review_state_counts = Counter(
        family["reviewState"] for family in family_entries
    )
    domain_progress: dict[str, dict[str, Any]] = {}
    for family in family_entries:
        domain = family["domain"]
        progress = domain_progress.setdefault(domain, {
            "families": 0,
            "activeFamilies": 0,
            "reviewedFamilies": 0,
            "unreviewedFamilies": 0,
            "classifications": Counter(),
        })
        progress["families"] += 1
        if any(
            (ROOT / path).is_file() for path in family["paths"]
        ):
            progress["activeFamilies"] += 1
        if family["reviewState"] == "UNREVIEWED":
            progress["unreviewedFamilies"] += 1
        else:
            progress["reviewedFamilies"] += 1
        progress["classifications"].update(family["classifications"])
    for progress in domain_progress.values():
        progress["classifications"] = dict(
            sorted(progress["classifications"].items())
        )
    return {
        "schemaVersion": 1,
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "purpose": "P0 complete maintained test-estate inventory; conservative baseline for family review",
        "deletionGate": [
            "production path is gone",
            "equal or stronger coverage proves the same runtime and authority boundary",
            "all meaningful assertions have migrated with parity",
            "coverage exists only for removed compatibility or migration behavior",
        ],
        "repository": repo_state(ROOT),
        "inventoryScope": [
            "tracked tests/** files, including isolated Lua, native fixtures, Python tests, support, and runners",
            "tracked tools/providers/pnc/** files, including Python tests, fixtures, scenarios, Lua workers, runners, and support",
            "tracked tools/unique_npc_manager/tests/** files",
        ],
        "runners": [
            {"name": "tests/run_tests.py", "tier": "DEFAULT", "selectors": ["name filters", "--domain from R1_ROOT_DOMAIN_REVIEW.json"], "isolation": "one bounded Lua process per test; worker pool default 4"},
            {"name": "python semantic acceptance runner", "tier": "ACCEPTANCE", "isolation": "one Python subprocess per module; parallel and exclusive lanes"},
            {"name": "python unittest discover (root)", "tier": "FAST", "isolation": "single process unless caller isolates"},
            {"name": "native PZ harness fixtures", "tier": "NATIVE", "isolation": "native runtime; user-owned SP/MP acceptance"},
            {"name": "refactor binding smoke (--all)", "tier": "FOCUSED", "isolation": "static cross-file binding scan"},
        ],
        "counts": {
            "trackedScopeFiles": len(entries),
            "activeScopeFiles": len(active_entries),
            "deletedEntries": len(entries) - len(active_entries),
            "families": len(family_entries),
            "activeFamilies": len(active_families),
            "roles": dict(sorted(role_counts.items())),
            "activeRoles": dict(sorted(active_role_counts.items())),
            "tiers": dict(sorted(tier_counts.items())),
            "activeTiers": dict(sorted(active_tier_counts.items())),
            "classifications": dict(sorted(classification_counts.items())),
            "reviewStates": dict(sorted(review_state_counts.items())),
            "familyReviewStates": dict(sorted(family_review_state_counts.items())),
            "reviewedFamilies": sum(
                family["reviewState"] == "REVIEWED"
                and any(
                    (ROOT / path).is_file() for path in family["paths"]
                )
                for family in family_entries
            ),
            "unreviewedFamilies": sum(
                family["reviewState"] == "UNREVIEWED"
                for family in family_entries
                if any(
                    (ROOT / path).is_file() for path in family["paths"]
                )
            ),
            "pendingFamilyReview": sum(
                family["reviewStatus"] == "UNREVIEWED"
                for family in family_entries
                if any(
                    (ROOT / path).is_file() for path in family["paths"]
                )
            ),
            "executableEntries": sum(entry["executableTest"] for entry in entries),
            "activeExecutableEntries": sum(
                entry["executableTest"] for entry in active_entries
            ),
            "assertionCalls": sum(entry["metrics"]["assertionCalls"] for entry in entries),
        },
        "domainProgress": dict(sorted(domain_progress.items())),
        "reviewLedgerDomains": review_ledger["domainReviews"],
        "families": family_entries,
        "entries": sorted(entries, key=lambda entry: entry["path"]),
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=ROOT / "docs/Jobs/TestSuiteRationalization/AUDIT_MANIFEST.json",
    )
    parser.add_argument(
        "--lua-report",
        action="append",
        type=Path,
        default=[],
        help="bounded Lua runner JSON report to attach per-test baseline status",
    )
    return parser.parse_args()


def main() -> int:
    options = parse_args()
    manifest = build_manifest(options.lua_report)
    output = options.output if options.output.is_absolute() else ROOT / options.output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        f"Wrote {output} ({manifest['counts']['trackedScopeFiles']} files, "
        f"{manifest['counts']['families']} families, "
        f"{manifest['counts']['executableEntries']} executable entries)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
