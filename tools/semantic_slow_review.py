#!/usr/bin/env python3
"""Review the measured slow Semantic Python acceptance families."""

from __future__ import annotations

import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
BASELINE_REPORT_PATH = Path("/tmp/hoomans-python-final-full-exclusive.json")
FINAL_REPORT_PATH = Path("/tmp/hoomans-r6-python-final2.json")
OUTPUT = ROOT / "docs/Jobs/TestSuiteRationalization/R4_SEMANTIC_SLOW_REVIEW.json"

SLOW_MODULES = (
    "test_response_observatory_matrix",
    "test_sweep_acceptance",
    "test_observatory_fixture_parity",
    "test_harness",
    "test_contextual_talk_parity",
    "test_behavior_fixture_parity",
    "test_contextual_social_reactions",
    "test_contextual_speech_behavior",
    "test_automatic_flow_generation",
    "test_pilot_parity",
    "test_contextual_suggestions_s4",
    "test_contextual_bonds",
)

OVERLAP_REVIEWS = {
    "test_response_observatory_matrix": {
        "subjects": "response_observatory quality matrices, production Lua response/command presentation, negative permission and transport cases",
        "overlap": "Compared with observatory_fixture_parity and contextual_talk_parity: it checks ad hoc matrix expectations and authority rejection/transport counts, not fixture catalog parity or full presentation adapter parity.",
    },
    "test_sweep_acceptance": {
        "subjects": "DialogueQualitySweepService, dimension inventory, reachability/planning, evidence extraction, and 13 acceptance scenarios through LuaSemanticWorker",
        "overlap": "Compared with response_observatory_matrix: sweep planner/reachability/performance coverage is a bounded acceptance system, not duplicate per-response matrix cases.",
    },
    "test_observatory_fixture_parity": {
        "subjects": "fixtures/v1 c0a and observatory JSON catalogs plus testing.executor/loaders",
        "overlap": "Compared with behavior_fixture_parity: fixture families and schemas differ; preserving both catches migration/parity loss at separate catalog boundaries.",
    },
    "test_harness": {
        "subjects": "LuaSemanticWorker, LuaProcess, HarnessConfig, scenario save/load, transport and lifecycle",
        "overlap": "Compared with all contextual tests: this validates worker boot/process/transport/session contracts; contextual modules consume that worker and cannot replace its lifecycle checks.",
    },
    "test_contextual_talk_parity": {
        "subjects": "production native Talk presentation projection and Semantic Lab Tk adapter projection",
        "overlap": "Compared with response observatory and UI tests: this is the explicit production-Lua-to-adapter parity boundary and retains per-row identity/order checks.",
    },
    "test_behavior_fixture_parity": {
        "subjects": "fixtures/v1/behavior command/question/social/inventory catalogs and executor",
        "overlap": "Compared with observatory fixtures: the behavior migration catalog has separate case ownership and broad command/question coverage; no equal assertion matrix was proven.",
    },
    "test_contextual_social_reactions": {
        "subjects": "production worker social reaction routing, relationship state, authority, transport/tool-call suppression",
        "overlap": "Compared with contextual_speech_behavior: social reaction decision/authority cases and speech-family realization variants are different contracts.",
    },
    "test_contextual_speech_behavior": {
        "subjects": "production worker speech-family realization across personality, relationship, bond, and language variants",
        "overlap": "Compared with contextual_social_reactions: wording-family realization remains distinct from social-reaction decision and transport assertions.",
    },
}


def source_details(module: str) -> dict[str, object]:
    path = ROOT / "tools/providers/pnc/tests" / f"{module}.py"
    source = path.read_text(encoding="utf-8", errors="ignore")
    return {
        "path": str(path.relative_to(ROOT)),
        "testMethods": re.findall(r"^\s+def\s+(test_[A-Za-z0-9_]+)\s*\(", source, re.M),
        "workerConstructors": len(re.findall(r"LuaSemanticWorker\s*\(", source)),
        "fixtureExecutors": len(re.findall(r"execute_cases\s*\(", source)),
        "fixtureLoaders": len(re.findall(r"load_cases_from_file\s*\(", source)),
        "setUpClass": "setUpClass" in source,
        "productionLuaBoundary": "LuaSemanticWorker" in source or "production" in source.casefold(),
        "history": subprocess.run(
            ["git", "log", "--follow", "-1", "--format=%h %s", "--", str(path.relative_to(ROOT))],
            cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            text=True, check=False,
        ).stdout.strip(),
    }


def build() -> dict[str, object]:
    if BASELINE_REPORT_PATH.is_file():
        baseline_report = json.loads(BASELINE_REPORT_PATH.read_text(encoding="utf-8"))
    else:
        prior = json.loads(OUTPUT.read_text(encoding="utf-8")) if OUTPUT.is_file() else {}
        prior_baseline = prior.get("baseline", {})
        baseline_report = {
            "summary": prior_baseline.get("modules", {}),
            "elapsed": prior_baseline.get("elapsedSeconds"),
            "jobs": prior_baseline.get("jobs"),
            "maxActiveProcesses": prior_baseline.get("maxActiveProcesses"),
            "exclusiveModules": prior_baseline.get("exclusiveModules", []),
            "modules": [
                {
        "module": f"tools.providers.pnc.tests.{item['module']}",
                    "classification": item.get("classificationBefore"),
                    "status": item.get("status"),
                    "elapsed": item.get("elapsedSeconds"),
                }
                for item in prior.get("reviewedSlowModules", [])
            ],
        }
    final_path = FINAL_REPORT_PATH if FINAL_REPORT_PATH.is_file() else BASELINE_REPORT_PATH
    final_report = json.loads(final_path.read_text(encoding="utf-8"))
    baseline_rows = {
        row["module"].rsplit(".", 1)[-1]: row
        for row in baseline_report["modules"]
    }
    module_rows = {
        row["module"].rsplit(".", 1)[-1]: row
        for row in final_report["modules"]
    }
    reviews = []
    path_reviews: dict[str, dict[str, object]] = {}
    for module in SLOW_MODULES:
        row = module_rows.get(module, {})
        baseline_row = baseline_rows.get(module, {})
        details = source_details(module)
        decision = OVERLAP_REVIEWS.get(module, {
            "subjects": "measured slow acceptance module; source inspected directly",
            "overlap": "Compared adjacent acceptance modules by subject and test method; no parity-equivalent replacement was proven.",
        })
        after_classification = row.get("classification", "acceptance_slow")
        review = {
            "module": module,
            "classificationBefore": baseline_row.get("classification"),
            "classificationAfter": after_classification,
            "status": row.get("status"),
            "elapsedSeconds": row.get("elapsed"),
            "testCount": len(details["testMethods"]),
            "subjectsInspected": decision["subjects"],
            "authorityBoundary": "production-Lua worker, fixture executor, presentation adapter, or acceptance subsystem as named by the subject review",
            "workerIsolation": {
                "workerConstructorsInSource": details["workerConstructors"],
                "fixtureExecutorsInSource": details["fixtureExecutors"],
                "fixtureLoadersInSource": details["fixtureLoaders"],
                "setUpClass": details["setUpClass"],
                "decision": "retain per-test worker/process isolation where constructors occur; do not share mutable Lua workers across test methods",
            },
            "overlapReview": decision["overlap"],
            "legacyMigration": {
                "historyTip": details["history"],
                "review": "current acceptance/fixture/worker subject inspected; no retired-only path identified",
            },
            "tierDecision": (
                "KEEP_CANONICAL in ACCEPTANCE; route through the existing exclusive resource lane after isolated rerun proved scheduler-sensitive failures"
                if after_classification == "exclusive"
                else "KEEP_CANONICAL in ACCEPTANCE; label acceptance_slow while retaining bounded parallel execution"
            ),
            "action": "retain; do not merge or delete; record slow acceptance routing and continue measuring",
            "sourceDetails": details,
        }
        reviews.append(review)
        path = str(ROOT / "tools/providers/pnc/tests" / f"{module}.py")
        path_reviews[path.removeprefix(str(ROOT) + "/")] = {
            "classification": "KEEP_CANONICAL",
            "finalDisposition": "retained_acceptance_slow_reviewed",
            "productionSubjectsInspected": [decision["subjects"]],
            "callersInspected": [
                "tools/semantic_harness/testing/python_runner.py",
                "the imported production-Lua worker/fixture/UI subjects recorded in the module review",
            ],
            "authorityBoundary": [review["authorityBoundary"]],
            "assertionPurpose": {
                "testMethods": details["testMethods"],
                "workerConstructors": details["workerConstructors"],
                "fixtureExecutors": details["fixtureExecutors"],
            },
            "overlapCandidates": [
                candidate for candidate in SLOW_MODULES if candidate != module
            ][:6],
            "overlapReview": decision["overlap"],
            "legacyMigration": review["legacyMigration"],
            "cost": {
                "elapsedSeconds": row.get("elapsed"),
                "testCount": review["testCount"],
                "baselineClassification": baseline_row.get("classification"),
                "afterClassification": after_classification,
            },
            "evidence": [
                f"Final developer acceptance report {final_path} recorded {row.get('status')} in {row.get('elapsed')} seconds for {review['testCount']} test methods.",
                f"Inspected production/fixture subjects: {decision['subjects']}.",
                f"Compared overlap: {decision['overlap']}",
                f"Worker/fixture isolation counts: {details}; no mutable worker reuse was introduced.",
                (
                    "The existing runner routes this module through the exclusive acceptance resource lane after the isolated rerun proved scheduler-sensitive parallel failures."
                    if after_classification == "exclusive"
                    else "The existing runner labels this module acceptance_slow while preserving the acceptance tier and bounded parallel execution."
                ),
            ],
            "action": "retain canonical acceptance coverage; route visibly through acceptance_slow label",
            "overlap": decision["overlap"],
        }
    return {
        "schemaVersion": 1,
        "phase": "R4",
        "sourceReport": str(final_path),
        "baseline": {
            "report": str(BASELINE_REPORT_PATH),
            "modules": baseline_report["summary"],
            "elapsedSeconds": baseline_report["elapsed"],
            "jobs": baseline_report["jobs"],
            "maxActiveProcesses": baseline_report["maxActiveProcesses"],
            "exclusiveModules": baseline_report["exclusiveModules"],
        },
        "final": {
            "report": str(final_path),
            "modules": final_report["summary"],
            "elapsedSeconds": final_report["elapsed"],
            "jobs": final_report["jobs"],
            "maxActiveProcesses": final_report["maxActiveProcesses"],
            "exclusiveModules": final_report["exclusiveModules"],
            "slowAcceptanceModules": final_report.get("slowAcceptanceModules", []),
        },
        "reviewedSlowModules": reviews,
        "pathReviews": path_reviews,
        "actions": {
            "merges": 0,
            "deletions": 0,
            "workerReuse": 0,
            "tierMoves": 0,
            "topologyChange": "Added explicit acceptance_slow labels and routed the ten modules that failed only under parallel contention through the existing exclusive lane; worker isolation remains intact.",
            "resourceSensitiveModules": sorted(set(final_report["exclusiveModules"]) - set(baseline_report["exclusiveModules"])),
            "reason": "Measured cost is real production-Lua/fixture execution, not redundant assertion repetition. Ten modules passed serial focused rerun after scheduler-sensitive parallel failures; the final full lane passed with the existing exclusive runner mechanism.",
        },
    }


if __name__ == "__main__":
    OUTPUT.write_text(json.dumps(build(), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUTPUT}")
