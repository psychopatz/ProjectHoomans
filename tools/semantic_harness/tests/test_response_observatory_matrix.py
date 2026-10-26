"""Grounded multi-language production-Lua Observatory checks."""
from __future__ import annotations

import os
from pathlib import Path
import subprocess
import sys
import tempfile
import json
import unittest

from tools.semantic_harness.inspection.response_candidate import preview_authored_variant
from tools.semantic_harness.inspection.response_observatory import (
    run_quality_matrix, compare_quality_reports, review_variant_proposal,
)


class ResponseQualityMatrixTests(unittest.TestCase):
    def test_greeting_and_companion_actions_en_tl(self):
        result = run_quality_matrix([
            {"label": "EN greeting", "language": "EN",
             "utterance": "hello",
             "expected": {"lastKey": "semantic.flow.greeting.opening.question.default",
                          "maxActions": 0}},
            {"label": "TL greeting", "language": "TL",
             "utterance": "hello",
             "expected": {"lastKey": "semantic.flow.greeting.opening.question.default",
                          "maxActions": 0}},
            {"label": "follow request", "language": "EN",
             "utterance": "follow me",
             "expected": {"minActions": 1, "accepted": True}},
        ])
        self.assertTrue(result["ok"])
        self.assertEqual(result["passed"], 3)
        self.assertFalse(result["truncated"])
        self.assertNotEqual(
            result["cases"][0]["responseTexts"][-1],
            result["cases"][1]["responseTexts"][-1],
        )
        self.assertEqual(result["cases"][2]["transportCount"], 1)

    def test_goodbye_root_closes_while_typed_goodbye_does_not(self):
        from tools.semantic_harness.inspection.response_observatory import (
            run_quality_matrix,
        )
        cases = [
            {"label": "root farewell", "language": "TL",
             "interaction": {"kind": "conversation_root_choice",
                             "choiceID": "goodbye"},
             "expected": {"lastKey": "response.goodbye",
                          "conversationClosed": True, "maxActions": 0}},
            {"label": "typed ambiguity", "language": "TL",
             "utterance": "goodbye",
             "expected": {"lastKey": "semantic.ask_clarification",
                          "conversationClosed": False, "maxActions": 0}},
        ]
        result = run_quality_matrix(cases)
        self.assertEqual(result["passed"], 2, result)
        self.assertTrue(result["cases"][0]["conversationClosed"])
        self.assertFalse(result["cases"][1]["conversationClosed"])
        with self.assertRaisesRegex(ValueError, "conversation root choice unavailable"):
            run_quality_matrix([{
                "interaction": {"kind": "conversation_root_choice",
                                "choiceID": "not_a_registered_choice"},
            }])

    def test_observation_is_not_falsely_accepted(self):
        result = run_quality_matrix([{"utterance": "goodbye"}])
        self.assertEqual(result["passed"], 0)
        self.assertEqual(result["observedOnly"], 1)
        self.assertEqual(result["cases"][0]["status"], "OBSERVED_ONLY")

    def test_negative_expectation_is_reported_as_failure(self):
        result = run_quality_matrix([
            {"utterance": "hello", "expected": {"minActions": 1}},
        ])
        self.assertFalse(result["ok"])
        self.assertEqual(result["failed"], 1)

    def test_command_rejections_are_server_declared_not_accepted_effects(self):
        root = Path(__file__).resolve().parents[3]
        path = (root / "tools/semantic_harness/fixtures"
                / "observatory_permission_rejections_en_tl.json")
        matrix = run_quality_matrix(json.loads(path.read_text())["cases"])
        self.assertTrue(matrix["ok"], matrix)
        self.assertEqual(matrix["passed"], 4)
        self.assertEqual(matrix["failed"], 0)
        for case in matrix["cases"]:
            self.assertEqual(case["executionStatus"], "rejected")
            self.assertIs(case["commandAccepted"], False)
            self.assertEqual(case["rejectionReason"], "permission_denied")
            self.assertEqual(case["actions"], 1)
            self.assertEqual(case["actionCountKind"], "attempted_dispatch")
            self.assertEqual(case["transportCount"], 1)
            self.assertEqual(case["commandDecisionKind"],
                             "CONFIGURED_FIXTURE_NETWORK_REPLY")
            self.assertFalse(case["nativeServerAuthorityVerified"])
            self.assertTrue(all(case["checks"].values()), case)

    def test_matrix_rejects_unknown_unsupported_or_unbounded_assertions(self):
        with self.assertRaisesRegex(ValueError, "unsupported matrix expectation"):
            run_quality_matrix([
                {"utterance": "hello", "expected": {
                    "maxActions": 0, "unexpectedAlwaysTrue": True}}
            ])
        with self.assertRaisesRegex(ValueError, "invalid bounded matrix count"):
            run_quality_matrix([
                {"utterance": "hello", "expected": {"maxActions": -2}}
            ])
        with self.assertRaisesRegex(ValueError, "invalid boolean matrix expectation"):
            run_quality_matrix([
                {"utterance": "hello", "expected": {"commandAccepted": "false"}}
            ])

    def test_safe_proposal_preflight_never_changes_loaded_pool(self):
        from tools.semantic_harness.runtime.worker import LuaSemanticWorker
        from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            original = worker.response_pool_detail(
                "semantic.flow.greeting.opening", limit=16)
            candidate = {
                "poolID": original["poolID"],
                "expectedContentFingerprint": original["contentFingerprint"],
                "variants": [{
                    "id": "semantic.flow.greeting.opening.default",
                    "EN": "Hi there, friend.", "TL": "Kumusta, kaibigan.",
                }],
            }
            good = review_variant_proposal(worker, candidate)
            self.assertTrue(good["ok"])
            self.assertFalse(good["approved"])
            self.assertEqual(good["writes"], 0)
            self.assertTrue(good["canonicalOwnerVerified"])
            self.assertEqual(
                original["contentFingerprint"],
                worker.response_pool_detail(original["poolID"])["contentFingerprint"],
            )
            candidate["variants"][0]["priority"] = 99
            rejected = review_variant_proposal(worker, candidate)
            self.assertFalse(rejected["ok"])
            self.assertIn("metadata edits forbidden", rejected["errors"][0])
            del candidate["variants"][0]["priority"]
            candidate["expectedContentFingerprint"] = "catalog-v1:0"
            self.assertEqual(review_variant_proposal(worker, candidate)["reason"],
                             "stale_baseline")

    def test_isolated_candidate_changes_real_lua_in_en_tl_not_gameplay(self):
        from tools.semantic_harness.runtime.worker import LuaSemanticWorker
        from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
        repository = Path(__file__).resolve().parents[3]
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            original = worker.response_pool_detail(
                "semantic.flow.greeting.opening", limit=16)
        proposal = {
            "poolID": original["poolID"],
            "expectedContentFingerprint": original["contentFingerprint"],
            "variants": [{
                "id": "semantic.flow.greeting.opening.default",
                "EN": "Welcome back. Good to see you.",
                "TL": "Maligayang balik. Mabuti at nakita kita.",
            }],
            "case": {"utterance": "hello"},
        }
        report = preview_authored_variant(proposal, repository=repository)
        self.assertTrue(report["ok"])
        self.assertTrue(report["canonicalOwnerVerified"])
        self.assertTrue(report["candidateOverlayCleaned"])
        self.assertFalse(report["approved"])
        self.assertEqual(report["writesToProduction"], 0)
        self.assertNotEqual(report["baselineFingerprint"],
                            report["candidateFingerprint"])
        self.assertEqual([case["language"] for case in report["languageCases"]],
                         ["EN", "TL"])
        self.assertTrue(all(case["status"] == "PASS"
                            for case in report["languageCases"]))
        self.assertEqual(report["sourcePath"], original["sourcePath"])
        self.assertTrue(report["checks"]["unchangedGameplayEffects"])
        self.assertEqual(set(report["translationSourceSHA256"]), {"EN", "TL"})
        self.assertTrue(all(len(value) == 64 for value
                            in report["translationSourceSHA256"].values()))
        self.assertIsNone(report["sourceSHA256GuardMatched"])
        proposal["expectedSourceSHA256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "stale_source_sha256"):
            preview_authored_variant(proposal, repository=repository)
        proposal["expectedSourceSHA256"] = report["sourceSHA256"]
        pinned = preview_authored_variant(proposal, repository=repository)
        self.assertTrue(pinned["sourceSHA256GuardMatched"])
        self.assertEqual(pinned["writesToProduction"], 0)
        proposal.pop("expectedSourceSHA256")
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            after = worker.response_pool_detail(original["poolID"], limit=16)
        self.assertEqual(original["contentFingerprint"],
                         after["contentFingerprint"])

        proposal["expectedContentFingerprint"] = "catalog-v1:stale"
        with self.assertRaisesRegex(ValueError, "stale_baseline"):
            preview_authored_variant(proposal, repository=repository)
        proposal["expectedContentFingerprint"] = original["contentFingerprint"]
        proposal["variants"][0]["id"] = "unregistered.fake.variant"
        with self.assertRaisesRegex(ValueError, "preflight_rejected"):
            preview_authored_variant(proposal, repository=repository)

    def test_checked_in_greeting_promotion_changes_text_only(self):
        from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
        from tools.semantic_harness.runtime.worker import LuaSemanticWorker

        expected = {
            "EN": "Hey there. Good to see you.",
            "TL": "Uy, mabuti at nakita kita.",
        }
        old = {
            "EN": "Hello. Good to see you.",
            "TL": "Kumusta. Mabuti at nakita kita.",
        }
        owner = (
            "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/"
            "Semantics/SemanticDialogueResponseCatalog/"
            "PNC_SemanticDialogueResponseCatalog_FlowGreeting.lua"
        )
        for language in ("EN", "TL"):
            with self.subTest(language=language), LuaSemanticWorker(
                DEFAULT_SCENARIO
            ) as worker:
                detail = worker.response_pool_detail(
                    "semantic.flow.greeting.opening", limit=16
                )
                variant = next(
                    row
                    for row in detail["variants"]
                    if row["id"] == "semantic.flow.greeting.opening.default"
                )
                self.assertEqual(detail["sourceKind"], "AUTHORED_LUA")
                self.assertEqual(detail["sourcePath"], owner)
                self.assertEqual(variant["priority"], 0)
                self.assertEqual(variant["when"], [])
                self.assertEqual(
                    variant["planSummary"],
                    {
                        "dialogueAct": "GREETING_OPENING",
                        "firstTurnID": "greeting",
                        "kind": "dialogue_act_plan",
                        "offerCount": 1,
                        "segmentCount": 2,
                        "topic": "WELLBEING",
                        "turnCount": 2,
                    },
                )
                explanation = worker.explain_response_selection(
                    "semantic.flow.greeting.opening",
                    {"npcID": "p6-promoted", "socialStyle": "neutral"},
                    "p6-promoted",
                )
                self.assertEqual(
                    explanation["selectedID"],
                    "semantic.flow.greeting.opening.default",
                )
                worker.set_language(language)
                turn = worker.input("hello")
                result = turn["result"]
                decision = result["decision"]
                response = decision["response"]
                selected = next(
                    message
                    for message in turn["messages"]
                    if message.get("payload", {}).get("semanticTemplateID")
                    == "semantic.flow.greeting.opening.default"
                )
                self.assertEqual(selected["payload"]["text"], expected[language])
                self.assertNotEqual(selected["payload"]["text"], old[language])
                self.assertTrue(result["accepted"])
                self.assertEqual(decision["branch"], "GREET_ACKNOWLEDGED")
                self.assertEqual(
                    response["selectionID"],
                    "semantic.flow.greeting.opening.default",
                )
                self.assertEqual(
                    response["sourcePoolID"], "semantic.flow.greeting.opening"
                )
                self.assertEqual(
                    response["templateID"],
                    "semantic.flow.greeting.opening.default",
                )
                self.assertEqual(response["sourceFlowID"], "greeting")
                self.assertEqual(response["flowTransition"], "start")
                self.assertEqual(turn["transport"], [])
                self.assertIsNone(result.get("actionResult"))

    def test_rejects_generated_owner_as_edit_source(self):
        from tools.semantic_harness.runtime.worker import LuaSemanticWorker
        from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
        repository = Path(__file__).resolve().parents[3]
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            original = worker.response_pool_detail(
                "semantic.generated.simple_command.follow.queued", limit=16)
        proposal = {
            "poolID": original["poolID"],
            "expectedContentFingerprint": original["contentFingerprint"],
            "variants": [{"id": original["variants"][0]["id"],
                          "EN": "I can follow.", "TL": "Susunod ako."}],
            "case": {"utterance": "follow me"},
        }
        with self.assertRaisesRegex(ValueError, "no verified canonical authored"):
            preview_authored_variant(proposal, repository=repository)

    def test_manifest_translation_keys_are_unique_after_follow_wait_fix(self):
        root = Path(__file__).resolve().parents[3]
        media = root / "Contents/mods/ProjectHoomans/common/media/translation"
        manifest = json.loads((media / "manifests/Conversation.json").read_text())
        for language in ("EN", "TL"):
            with self.subTest(language=language):
                occurrence = {}
                for rel in manifest["languages"][language]:
                    data = json.loads((media / rel).read_text(encoding="utf-8"))
                    for key in data:
                        occurrence.setdefault(key, []).append(rel)
                for suffix in ("FollowQueued", "StayQueued", "FollowRejected",
                               "StayRejected", "FollowFailed", "StayFailed"):
                    key = "UI_PNC_Conversation_Semantic_Generated" + suffix
                    self.assertEqual(len(occurrence.get(key, [])), 1,
                                     (language, key, occurrence.get(key)))

    def test_en_tl_follow_wait_use_production_catalog_not_english_fallback(self):
        from tools.semantic_harness.runtime.worker import LuaSemanticWorker
        from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
        for language in ("EN", "TL"):
            for utterance in ("follow me", "wait here"):
                with self.subTest(language=language, utterance=utterance):
                    scenario = merge(DEFAULT_SCENARIO, {
                        "runtime": {"language": language},
                    })
                    with LuaSemanticWorker(scenario) as worker:
                        turn = worker.input(utterance)
                    npc = [message["payload"]["text"]
                           for message in turn["messages"]
                           if message.get("speaker") == "npc"]
                    fallback = [
                        item for item in turn.get("translation", {}).get(
                            "lookups", [])
                        if item.get("fallbackUsed") is True
                    ]
                    self.assertFalse(fallback, fallback)
                    if language == "TL":
                        self.assertTrue(any(
                            "susundan" in text or "mananatili" in text
                            for text in npc
                        ), npc)

    def test_bundled_real_lua_context_matrices(self):
        from tools.semantic_harness.inspection.response_observatory import run_quality_matrix
        root = Path(__file__).resolve().parents[3]
        for filename in (
            "observatory_core_en_tl.json",
            "observatory_health_authority_en_tl.json",
            "observatory_lifecycle_en_tl.json",
        ):
            with self.subTest(matrix=filename):
                path = root / "tools/semantic_harness/fixtures" / filename
                result = run_quality_matrix(json.loads(path.read_text())["cases"])
                expected = 8
                self.assertEqual(result["caseCount"], expected)
                self.assertEqual(result["passed"], expected, result["cases"])
                self.assertEqual(result["failed"], 0)
                self.assertFalse(result["truncated"])

    def test_comparison_flags_regressions_and_missing_cases(self):
        row = {
            "label": "Greeting EN", "language": "EN",
            "status": "PASS", "responseKeys": ["a"],
            "responseTexts": ["hi"], "actions": 0,
            "transportCount": 0, "accepted": True,
        }
        base = {
            "type": "response_quality_matrix", "schemaVersion": 1,
            "sourceKind": "FIXTURE", "truncated": False,
            "cases": [row],
        }
        candidate = json.loads(json.dumps(base))
        candidate["cases"][0]["responseTexts"] = ["different"]
        candidate["cases"][0]["status"] = "FAIL"
        compare = compare_quality_reports(base, candidate)
        self.assertFalse(compare["ok"])
        self.assertEqual(len(compare["regressions"]), 1)
        self.assertIn("responseTexts", compare["changes"][0]["diff"])
        candidate["cases"] = []
        self.assertEqual(len(compare_quality_reports(base, candidate)["skipped"]), 1)

    def test_comparison_accepts_equivalent_complete_reports(self):
        base = {
            "type": "response_quality_matrix",
            "schemaVersion": 1,
            "sourceKind": "FIXTURE",
            "truncated": False,
            "cases": [
                {
                    "label": "Greeting EN",
                    "language": "EN",
                    "status": "PASS",
                    "responseKeys": ["a"],
                    "responseTexts": ["hi"],
                    "actions": 0,
                    "transportCount": 0,
                    "accepted": True,
                }
            ],
        }
        equivalent = json.loads(json.dumps(base))
        comparison = compare_quality_reports(base, equivalent)
        self.assertTrue(comparison["ok"], comparison)
        self.assertEqual(comparison["changes"], [])
        self.assertEqual(comparison["regressions"], [])
        self.assertEqual(comparison["skipped"], [])

    def test_cli_reports_bounded_error_with_nonzero_exit(self):
        root = Path(__file__).resolve().parents[3]
        completed = subprocess.run(
            [
                sys.executable,
                "-m",
                "tools.semantic_harness",
                "--no-gui",
                "--jsonl",
                "--response-pool",
                "semantic.flow.greeting.opening",
                "--response-limit",
                "17",
            ],
            cwd=root,
            capture_output=True,
            text=True,
            timeout=20,
        )
        self.assertEqual(completed.returncode, 2)
        self.assertIn("invalid_page", completed.stderr)
        self.assertEqual(completed.stdout, "")

    def test_invalid_language_and_large_case_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "language"):
            run_quality_matrix([{"language": "XX"}])
        with self.assertRaisesRegex(ValueError, "utterance"):
            run_quality_matrix([{"utterance": "a" * 201}])

    def test_cli_catalog_and_explain_use_real_lua(self):
        root = Path(__file__).resolve().parents[3]
        base = [sys.executable, "-m", "tools.semantic_harness",
                "--no-gui", "--jsonl"]
        list_response = subprocess.run(
            base + ["--response-pools", "greeting", "--response-limit", "2"],
            cwd=root, capture_output=True, text=True, timeout=20,
        )
        self.assertEqual(list_response.returncode, 0, list_response.stderr)
        catalog = json.loads(list_response.stdout)
        self.assertLessEqual(len(catalog["pools"]), 2)
        self.assertIn("registryRevision", catalog)
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "context.json"
            path.write_text(json.dumps(
                {"worldContext": {"weather": {"raining": True}},
                 "npcID": "obs-cli"}))
            explain = subprocess.run(
                base + ["--explain-response-pool",
                        "semantic.flow.greeting.opening",
                        "--response-context-file", str(path)],
                cwd=root, capture_output=True, text=True, timeout=20,
            )
        self.assertEqual(explain.returncode, 0, explain.stderr)
        self.assertEqual(
            json.loads(explain.stdout)["selectedID"],
            "semantic.flow.greeting.opening.rain",
        )


@unittest.skipUnless(os.environ.get("DISPLAY"), "real Tk needs X11/Xvfb")
class ObservatoryTkTests(unittest.TestCase):
    def test_explore_is_static_and_selection_belongs_to_simulation(self):
        import tkinter as tk
        from tkinter import ttk
        from tkinter.scrolledtext import ScrolledText
        from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
        from tools.semantic_harness.runtime.worker import LuaSemanticWorker
        from tools.semantic_harness.studio.observatory_pane import (
            SemanticObservatoryPane,
        )

        root = tk.Tk()
        root.withdraw()
        try:
            with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
                def run(operation, callback):
                    callback(operation(worker))
                    return True
                pane = SemanticObservatoryPane(
                    root, tk, ttk, ScrolledText, run)
                self.assertEqual(
                    [pane.tabs.tab(tab, "text") for tab in pane.tabs.tabs()],
                    ["Registered responses"],
                )
                self.assertFalse(hasattr(pane, "context_var"))
                self.assertFalse(hasattr(pane, "test_utterance"))
                self.assertIn(
                    "Use Simulation → Inspect for context-specific selection explanations.",
                    pane.views["Explore"].get("1.0", "end"),
                )
                pane.filter_var.set("greeting")
                pane.refresh()
                self.assertEqual(len(pane.pools.get_children()), 3)
                pane.pools.selection_set("semantic.flow.greeting.opening")
                pane._selected()
                self.assertIn("semantic.flow.greeting.opening.rain",
                    pane.views["Catalog"].get("1.0", "end"))
        finally:
            root.destroy()

    def test_review_widget_previews_isolated_real_lua_candidate(self):
        import tkinter as tk
        from tkinter import ttk
        from tkinter.scrolledtext import ScrolledText
        from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
        from tools.semantic_harness.runtime.worker import LuaSemanticWorker
        from tools.semantic_harness.studio.observatory_pane import (
            SemanticObservatoryPane,
        )
        repository = Path(__file__).resolve().parents[3]
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            detail = worker.response_pool_detail(
                "semantic.flow.greeting.opening", limit=16)
        proposal = {
            "poolID": detail["poolID"],
            "expectedContentFingerprint": detail["contentFingerprint"],
            "variants": [{
                "id": "semantic.flow.greeting.opening.default",
                "EN": "Hello. Good to see you.",
                "TL": "Kumusta. Mabuti at nakita kita.",
            }],
            "case": {"utterance": "hello"},
        }
        with tempfile.TemporaryDirectory(prefix="observatory-ui-proposal-") as folder:
            path = Path(folder) / "proposal.json"
            path.write_text(json.dumps(proposal), encoding="utf-8")
            class FileDialog:
                @staticmethod
                def askopenfilename(**_kwargs):
                    return str(path)
            root = tk.Tk()
            root.withdraw()
            try:
                review_parent = ttk.Frame(root)
                review_parent.grid(row=0, column=0, sticky="nsew")
                with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
                    def run(operation, callback):
                        callback(operation(worker))
                        return True
                    pane = SemanticObservatoryPane(
                        root, tk, ttk, ScrolledText, run,
                        repository=repository, filedialog=FileDialog,
                        review_parent=review_parent,
                    )
                    pane.preview_proposal()
                    text = pane.views["Review"].get("1.0", "end")
                    self.assertIn("EN — PASS", text)
                    self.assertIn("TL — PASS", text)
                    self.assertIn("Approval: NOT GRANTED", text)
                    self.assertIn("Production writes: 0", text)
                    self.assertTrue(pane.approve_button.winfo_exists())
                    self.assertTrue(pane.reject_button.winfo_exists())
                    pane.approve_candidate()
                    self.assertIn("Explicit review decision: APPROVE", pane.views["Review"].get("1.0", "end"))
            finally:
                root.destroy()


if __name__ == "__main__":
    unittest.main()
