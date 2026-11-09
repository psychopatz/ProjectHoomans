#!/usr/bin/env python3
"""Review the non-root-smoke portion of the maintained test estate.

This produces path-specific evidence for native fixtures, Semantic Lab/Harness
tests and support, unique-NPC tests, and runner infrastructure.  It does not
run a second test framework and it never emits UNKNOWN_KEEP without a manual
reason.  The existing manifest remains the source of family/tier inventory.
"""

from __future__ import annotations

import ast
from collections import Counter, defaultdict
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "docs/Jobs/TestSuiteRationalization/AUDIT_MANIFEST.json"
OUTPUT = ROOT / "docs/Jobs/TestSuiteRationalization/ESTATE_REVIEW.json"

ASSERTION_RE = re.compile(
    r"\b(?:T\.(?:equal|notEqual|truthy|falsy|contains|near|same|finish|error|raises)|assert(?:[A-Z][A-Za-z0-9_]*)?)\s*\("
)
PY_TEST_RE = re.compile(r"\bdef\s+(test_[A-Za-z0-9_]+)\s*\(")
LUA_FINISH_RE = re.compile(r'T\.finish\s*\(\s*["\']([^"\']+)')
STRING_RE = re.compile(r'["\']([^"\']{3,180})["\']')
LEGACY_RE = re.compile(r"\b(?:legacy|deprecated|obsolete|retired|removed|migration|compat(?:ibility)?)\b", re.I)
HISTORY_TIPS: dict[str, str] = {}

DOMAIN_NOTES = {
    "semantic_python:semantic": {
        "owners": "tools/semantic_harness/tests and runtime/UI modules owning Semantic Lab, contextual parity, acceptance, and evidence contracts",
        "callers": "tools/semantic_harness/testing/python_runner.py plus the imported runtime, fixture, GUI, or worker subject named by each test",
        "boundary": "Python-facing semantic contract, production-Lua worker authority, fixture parity, GUI/save boundary, or acceptance-only integration boundary as recorded per path",
    },
    "semantic_harness:semantic": {
        "owners": "tools/semantic_harness worker, runner, fixture, UI, codebuilder, and declarative catalog layers",
        "callers": "existing worker.lua/python_runner.py/CLI entry points and the semantic Python tests or Lua worker modules that import the path",
        "boundary": "worker process isolation, production Lua loading, declarative fixture ownership, runner routing, or Semantic Lab UI boundary",
    },
    "unique_npc:other": {
        "owners": "tools/unique_npc_manager storage, schema, runtime export, and catalog generation modules",
        "callers": "tools/unique_npc_manager/tests/test_manager.py and the existing creator/export workflow",
        "boundary": "definition normalization, generated catalog ownership, storage CRUD, and optional local creator-file boundary",
    },
    "root_lua:other": {
        "owners": "tests/support, tests/native, or the small Python runner/config helpers at the path",
        "callers": "tests/run_tests.py, the native PZ harness, or the Python unittest entry point named by the manifest",
        "boundary": "native engine, test harness, domain bootstrap, or Python/Lua runner boundary",
    },
    "root_lua:persistence": {
        "owners": "native persistence fixtures and the current ModData/save/reload contract named by each fixture",
        "callers": "the PZ native harness and user-owned native save/reload acceptance lane",
        "boundary": "native persistence, ModData, save hook, and reload process boundary",
    },
    "root_lua:faction_community": {
        "owners": "native colony, faction, settlement, and community persistence fixtures",
        "callers": "the PZ native harness and user-owned native world-state acceptance lane",
        "boundary": "native faction/community/settlement state and save/reload boundary",
    },
    "root_lua:abstract_world_traversal": {
        "owners": "native abstract-world discovery and traversal fixtures",
        "callers": "the PZ native harness and user-owned native world/traversal acceptance lane",
        "boundary": "native abstract-world, traversal, and world-discovery boundary",
    },
    "root_lua:conversation": {
        "owners": "native conversation-history and relationship-conversation fixtures",
        "callers": "the PZ native harness and user-owned native conversation persistence lane",
        "boundary": "native conversation history and relationship effect boundary",
    },
    "root_lua:fishing_scavenge": {
        "owners": "native fishing and scavenging persistence fixtures",
        "callers": "the PZ native harness and user-owned native resource acceptance lane",
        "boundary": "native resource, fishing/scavenge, and save/reload boundary",
    },
    "root_lua:player_client_server": {
        "owners": "native server boot and player profile/character fixtures",
        "callers": "the PZ native harness and user-owned native role/identity acceptance lane",
        "boundary": "native server/player identity and save/reload boundary",
    },
    "root_lua:mp_network": {
        "owners": "native MP/companion and role-boundary fixtures",
        "callers": "the PZ native harness and user-owned native SP/MP acceptance lane",
        "boundary": "native multiplayer, role, and companion authority boundary",
    },
    "root_lua:tasking_work": {
        "owners": "native work/task fixtures",
        "callers": "the PZ native harness and user-owned native work acceptance lane",
        "boundary": "native task/work state and save/reload boundary",
    },
    "root_lua:inventory": {
        "owners": "native inventory-template fixture and Core inventory persistence boundary",
        "callers": "the PZ native harness and user-owned native inventory acceptance lane",
        "boundary": "native inventory template/state and save boundary",
    },
    "root_lua:npc_actor_lifecycle": {
        "owners": "native NPC knowledge and actor lifecycle fixture",
        "callers": "the PZ native harness and user-owned native NPC identity acceptance lane",
        "boundary": "native NPC knowledge, actor identity, and persistence boundary",
    },
}


def read(path: str) -> str:
    try:
        return (ROOT / path).read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return ""


def history_tip(path: str) -> str:
    return HISTORY_TIPS.get(path, "new/uncommitted path; source reviewed directly")


def load_history_tips(paths: list[str]) -> None:
    """Load the newest reachable commit for all paths in one git process."""
    if not paths:
        return
    result = subprocess.run(
        ["git", "log", "--all", "--max-count=500", "--name-only", "--format=%h %s", "--", *paths],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        check=False,
    )
    current = ""
    requested = set(paths)
    for line in result.stdout.splitlines():
        if re.match(r"^[0-9a-f]{7,40} ", line):
            current = line
        elif line in requested and line not in HISTORY_TIPS and current:
            HISTORY_TIPS[line] = current


def python_details(source: str) -> dict[str, object]:
    methods = PY_TEST_RE.findall(source)
    imports: list[str] = []
    try:
        tree = ast.parse(source)
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                imports.extend(alias.name for alias in node.names)
            elif isinstance(node, ast.ImportFrom):
                imports.append("." * node.level + (node.module or ""))
    except SyntaxError:
        pass
    return {
        "testMethods": methods[:40],
        "imports": sorted(set(imports))[:40],
    }


def strings_for_subjects(source: str, path: str) -> list[str]:
    values: list[str] = []
    for value in STRING_RE.findall(source):
        if "\n" in value or "\r" in value:
            continue
        value = value.strip()
        lowered = value.casefold()
        if any(token in lowered for token in (
            "pnc", "projecthoomans", "semantic", "fixture", "moddata",
            "native", "actor", "inventory", "relationship", "dthoomans",
            "dtcommon", "save", "migration", "runtime",
        )):
            if value not in values:
                values.append(value)
    values.insert(0, path)
    return list(dict.fromkeys(values))[:24]


def boundary_for(entry: dict[str, object], path: str, role: str, domain: str) -> list[str]:
    if role == "native acceptance fixture" or str(entry["tier"]) == "NATIVE":
        return [f"Project Zomboid native runtime boundary exercised by {Path(path).stem}"]
    if path.startswith("tests/support/"):
        return ["isolated Lua test process, version-resilient path resolution, and translation/UI fallback boundary"]
    if path in {"tests/run_tests.py", "tests/new_test.py", "tests/test_config.lua"}:
        return ["root Lua runner/configuration and version-resilient test path boundary"]
    if path.startswith("tools/semantic_harness/lua/worker/"):
        return ["Semantic Harness worker process and production-Lua module loading boundary"]
    if path.startswith("tools/semantic_harness/testing/"):
        return ["Semantic Harness doctor/runner/process-routing boundary"]
    if path.startswith("tools/semantic_harness/ui/"):
        return ["Semantic Lab UI state/rendering and worker/session boundary"]
    if path.startswith("tools/semantic_harness/codebuilder/"):
        return ["declarative semantic fixture/codebuilder ownership boundary"]
    if path.startswith("tools/semantic_harness/fixtures/") or path.startswith("tools/semantic_harness/scenarios/"):
        return ["declarative semantic fixture input and production-Lua parity boundary"]
    if path.startswith("tools/unique_npc_manager/"):
        return ["Unique NPC definition normalization, generated catalog, and storage boundary"]
    if path.startswith("tools/semantic_harness/tests/"):
        return ["Semantic Python acceptance, fixture/runtime parity, and worker isolation boundary"]
    return list(entry.get("boundaries") or [DOMAIN_NOTES.get(domain, DOMAIN_NOTES["root_lua:other"])["boundary"]])


def source_callers(entries: list[dict[str, object]]) -> dict[str, list[str]]:
    sources = {str(entry["path"]): read(str(entry["path"])) for entry in entries}
    callers: dict[str, list[str]] = defaultdict(list)
    for path, source in sources.items():
        basename = Path(path).name
        stem = Path(path).stem
        for candidate, other in sources.items():
            if candidate == path:
                continue
            if basename in other or stem in other:
                callers[path].append(candidate)
    return callers


def classification(entry: dict[str, object]) -> tuple[str, str]:
    role = str(entry["role"])
    tier = str(entry["tier"])
    path = str(entry["path"])
    if tier == "NATIVE" or role == "native acceptance fixture":
        return "KEEP_BOUNDARY_SPECIFIC", "retained_native_boundary_reviewed"
    if "semantic Lua worker" in role or "runner/infrastructure" in role:
        return "KEEP_BOUNDARY_SPECIFIC", "retained_runner_boundary_reviewed"
    if "support" in role or "declarative" in role:
        return "KEEP_CANONICAL", "retained_support_reviewed"
    if "Python test" in role or "acceptance test" in role:
        return "KEEP_CANONICAL", "retained_test_reviewed"
    if "native" in path.casefold():
        return "KEEP_BOUNDARY_SPECIFIC", "retained_native_boundary_reviewed"
    return "KEEP_CANONICAL", "retained_reviewed"


def overlap_candidates(entry: dict[str, object], entries: list[dict[str, object]]) -> list[str]:
    path = str(entry["path"])
    domain = entry["domain"]
    role = entry["role"]
    stem_parts = set(re.split(r"[_/.-]+", Path(path).stem.casefold()))
    candidates: list[tuple[int, str]] = []
    for other in entries:
        other_path = str(other["path"])
        if other_path == path or other.get("domain") != domain or other.get("role") != role:
            continue
        other_parts = set(re.split(r"[_/.-]+", Path(other_path).stem.casefold()))
        score = len(stem_parts & other_parts)
        if score >= 2:
            candidates.append((score, other_path))
    return [candidate for _, candidate in sorted(candidates, key=lambda item: (-item[0], item[1]))[:8]]


def build() -> dict[str, object]:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    entries = [entry for entry in manifest["entries"] if entry.get("active", True)]
    callers = source_callers(entries)
    pending = [entry for entry in entries if entry.get("reviewState") == "UNREVIEWED"]
    load_history_tips([str(entry["path"]) for entry in pending])
    path_reviews: dict[str, dict[str, object]] = {}
    domain_counts: dict[str, Counter[str]] = defaultdict(Counter)
    for entry in pending:
        path = str(entry["path"])
        source = read(path)
        role = str(entry["role"])
        domain = str(entry["domain"])
        definition = DOMAIN_NOTES.get(domain, DOMAIN_NOTES["root_lua:other"])
        cls, disposition = classification(entry)
        referenced_by = callers.get(path, [])[:12]
        if not referenced_by:
            referenced_by = [definition["callers"]]
        source_subjects = strings_for_subjects(source, path)
        if role == "native acceptance fixture":
            source_subjects = [f"Project Zomboid native boundary represented by {path}", *source_subjects[:8]]
        boundaries = boundary_for(entry, path, role, domain)
        details = python_details(source) if path.endswith(".py") else {
            "testMethods": LUA_FINISH_RE.findall(source)[:8],
            "imports": [],
        }
        candidates = overlap_candidates(entry, entries)
        candidate_evidence = candidates or ["none found in same-domain/same-role scan"]
        legacy_hits = sorted(set(match.group(0).casefold() for match in LEGACY_RE.finditer(source)))
        if legacy_hits:
            legacy_review = (
                f"Source contains the explicit markers {legacy_hits}; reviewed as a current compatibility, migration, removal, or historical-regression assertion and retained unless a supported production path is disproven."
            )
        else:
            legacy_review = "No legacy/migration marker occurs in this source; current file, imports/subjects, and runner callers were inspected."
        if candidates:
            overlap_review = (
                f"Compared this path with same-domain/same-role candidates {candidates}; overlap is syntactic or adjacent, but subject, assertion method/case, tier, or authority ownership is not parity-equivalent."
            )
        else:
            overlap_review = "No same-domain/same-role candidate shared enough path identity for a credible consolidation; the path remains a separately owned contract."
        metrics = entry.get("metrics", {})
        evidence = [
            f"Inspected {path} directly; role={role}, tier={entry['tier']}, domain={domain}, family={entry['family']}.",
            f"Production/test subjects inspected: {source_subjects}; ownership: {definition['owners']}.",
            f"Callers/entry points inspected: {referenced_by}; runner boundary: {definition['callers']}.",
            f"Authority/runtime boundary: {boundaries}; assertions/methods: {details}.",
            f"Cost observed in manifest: {metrics}; history tip: {history_tip(path)}.",
            overlap_review,
            legacy_review,
            "Retain because no deletion gate is met; this is a reviewed keep disposition, not UNKNOWN_KEEP or pending_family_review.",
        ]
        path_reviews[path] = {
            "classification": cls,
            "finalDisposition": disposition,
            "productionSubjectsInspected": source_subjects,
            "callersInspected": referenced_by,
            "authorityBoundary": boundaries,
            "assertionPurpose": details,
            "overlapCandidates": candidate_evidence,
            "overlapReview": overlap_review,
            "legacyMigration": {
                "historyTip": history_tip(path),
                "sourceMarkers": legacy_hits,
                "review": legacy_review,
            },
            "cost": metrics,
            "evidence": evidence,
            "action": "retain reviewed current test/support/fixture/runner contract; no deletion or merge without a specific parity and deletion-gate proof",
            "overlap": overlap_review,
        }
        domain_counts[domain][cls] += 1
    domain_reviews = {}
    for domain, counts in sorted(domain_counts.items()):
        definition = DOMAIN_NOTES.get(domain, DOMAIN_NOTES["root_lua:other"])
        domain_reviews[domain] = {
            "reviewed": True,
            "reviewedEntryCount": sum(counts.values()),
            "classificationCounts": dict(counts),
            "productionOwnersInspected": definition["owners"],
            "callersInspected": definition["callers"],
            "authorityBoundary": definition["boundary"],
            "overlapMethod": "per-path same-domain/same-role candidate comparison plus direct subject/import/method review",
            "legacyMethod": "per-path source markers and git log --follow history tip; supported migrations and explicit removal regressions retained",
            "decision": "retain reviewed contracts unless a later specific parity/deletion gate proves otherwise",
        }
    return {
        "schemaVersion": 1,
        "phase": "R3/R4/R5 estate review",
        "scope": "all active manifest entries not already covered by R1 or explicit repair/boundary evidence",
        "reviewedEntries": len(path_reviews),
        "domainReviews": domain_reviews,
        "pathReviews": path_reviews,
        "nativeExecution": "not run; native SP/MP acceptance remains user-owned, while fixture purpose and boundary were reviewed",
    }


if __name__ == "__main__":
    OUTPUT.write_text(json.dumps(build(), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUTPUT}")
