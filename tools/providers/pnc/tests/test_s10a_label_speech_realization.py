"""Acceptance for label-versus-speech separation and identity realization."""

from __future__ import annotations

import os
import tkinter as tk
import unittest
from pathlib import Path

from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.providers.pnc.runtime.worker import LuaSemanticWorker
from tools.providers.pnc.tests.gui_test_support import SemanticLabGuiTestCase
from tools.semantic_harness.runtime.config import HarnessConfig
from tools.semantic_harness.ui.suggestion_projection import (
    resolve_initiating_say,
    semantic_suggestion_title,
    validate_affordance_speech,
)

HOOMANS_ROOT = Path(__file__).resolve().parents[4]
WORKSHOP_ROOT = HOOMANS_ROOT.parent
CORE_ROOT = WORKSHOP_ROOT / "psychopatzCore"


def _manifest_pnc_worker(scenario: dict | None = None) -> LuaSemanticWorker:
    config = HarnessConfig.discover(
        repository=HOOMANS_ROOT,
        core_repository=CORE_ROOT,
        profile="pnc",
    )
    return LuaSemanticWorker(
        merge({}, scenario or DEFAULT_SCENARIO),
        config=config,
    )


def _identity_candidates(worker: LuaSemanticWorker) -> dict[str, dict]:
    snap = worker.snapshot()
    rows = (snap.get("suggestions") or {}).get("candidates") or []
    return {
        row["id"]: row
        for row in rows
        if isinstance(row, dict)
        and row.get("id")
        in {
            "identity.choice.real_name",
            "identity.choice.lie_name",
            "identity.choice.refuse_name",
        }
    }


def _identity_requests(turn: dict) -> list[dict]:
    return [
        event.get("payload") or {}
        for event in (turn.get("dispatchTransport") or [])
        if isinstance(event, dict) and event.get("command") == "SemanticIdentityRequest"
    ]


class S10ALabelSpeechRealWorkerTests(unittest.TestCase):
    def test_truthful_identity_choice_realizes_bound_name_and_preserves_authority(
        self,
    ) -> None:
        with _manifest_pnc_worker() as worker:
            worker.input("who are you")
            choices = _identity_candidates(worker)
            real = choices["identity.choice.real_name"]
            display = real.get("display") or {}
            frame = real.get("frame") or {}

            self.assertEqual(display.get("label"), "Say your real name")
            initiating_say = resolve_initiating_say(real, frame)
            self.assertIsNotNone(initiating_say)
            self.assertNotEqual(initiating_say, "Say your real name")
            self.assertIn("Patrick Patz", initiating_say or "")
            self.assertEqual(frame.get("intent"), "INFORM")
            self.assertEqual(frame.get("subject"), "IDENTITY")
            self.assertEqual(
                (frame.get("slots") or {}).get("identityClaim"),
                {"mode": "canonical", "name": "Patrick Patz"},
            )

            turn = worker.suggestion_click(frame)
            ir = (turn.get("result") or {}).get("ir") or {}
            self.assertEqual(turn.get("input"), initiating_say)
            self.assertEqual(ir.get("intent"), "INFORM")
            self.assertEqual(ir.get("subject"), "IDENTITY")
            self.assertEqual(
                (ir.get("slots") or {}).get("identityClaim"),
                {"mode": "canonical", "name": "Patrick Patz"},
            )
            reqs = _identity_requests(turn)
            self.assertEqual(len(reqs), 1)
            self.assertEqual(reqs[0].get("claimMode"), "canonical")
            self.assertEqual(reqs[0].get("claimedName"), "Patrick Patz")
            npc_text = " ".join(
                str(((m.get("payload") or {}).get("fallback")) or "")
                for m in (turn.get("messages") or [])
            )
            self.assertIn("Patrick", npc_text)
            self.assertEqual(
                (turn.get("relationshipAfter") or {}).get("identityTrust"),
                "trusted",
            )

    def test_generated_alias_and_refusal_branches_remain_distinct(self) -> None:
        with _manifest_pnc_worker() as worker:
            worker.input("who are you")
            choices = _identity_candidates(worker)
            lie = choices["identity.choice.lie_name"]
            lie_frame = lie.get("frame") or {}
            lie_claim = (lie_frame.get("slots") or {}).get("identityClaim") or {}
            lie_name = str(lie_claim.get("name") or "")
            self.assertEqual((lie.get("display") or {}).get("label"), "Lie about your name")
            self.assertEqual(lie_claim.get("mode"), "generated")
            self.assertTrue(lie_name)
            self.assertNotEqual(lie_name, "Patrick Patz")
            lie_say = resolve_initiating_say(lie, lie_frame) or ""
            self.assertNotEqual(lie_say, "Lie about your name")
            self.assertIn(lie_name, lie_say)

            lie_turn = worker.suggestion_click(lie_frame)
            lie_reqs = _identity_requests(lie_turn)
            self.assertEqual(len(lie_reqs), 1)
            self.assertEqual(lie_reqs[0].get("claimMode"), "generated")
            self.assertEqual(lie_reqs[0].get("claimedName"), lie_name)

        with _manifest_pnc_worker() as worker:
            worker.input("who are you")
            choices = _identity_candidates(worker)
            refuse = choices["identity.choice.refuse_name"]
            refuse_frame = refuse.get("frame") or {}
            self.assertEqual((refuse.get("display") or {}).get("label"), "Don't tell your name")
            self.assertEqual(refuse_frame.get("intent"), "REFUSE")
            self.assertEqual(refuse_frame.get("subject"), "IDENTITY")
            refuse_say = resolve_initiating_say(refuse, refuse_frame) or ""
            self.assertNotEqual(refuse_say, "Don't tell your name")

            refuse_turn = worker.suggestion_click(refuse_frame)
            refuse_ir = (refuse_turn.get("result") or {}).get("ir") or {}
            self.assertEqual(refuse_ir.get("intent"), "REFUSE")
            self.assertEqual(refuse_ir.get("subject"), "IDENTITY")
            refuse_reqs = _identity_requests(refuse_turn)
            self.assertEqual(len(refuse_reqs), 1)
            self.assertEqual(refuse_reqs[0].get("kind"), "identity_evasion")

    def test_repeated_realization_varies_wording_with_invariant_semantics(self) -> None:
        custom_scenario = merge(
            DEFAULT_SCENARIO,
            {
                "player": {
                    "forename": "Elena",
                    "surname": "Vance",
                    "displayName": "Elena Vance",
                }
            },
        )
        utts: list[str] = []
        with _manifest_pnc_worker(custom_scenario) as worker:
            for prompt in ("who are you", "are you sure you're okay", "wait a second", "so who are you"):
                worker.input(prompt)
                snap = worker.snapshot()
                rows = (snap.get("suggestions") or {}).get("candidates") or []
                for row in rows:
                    if row.get("id") == "identity.choice.real_name":
                        frame = row.get("frame") or {}
                        say = resolve_initiating_say(row, frame) or ""
                        self.assertIn("Elena Vance", say)
                        self.assertEqual(frame.get("intent"), "INFORM")
                        self.assertEqual(frame.get("subject"), "IDENTITY")
                        self.assertEqual(
                            (frame.get("slots") or {}).get("identityClaim"),
                            {"mode": "canonical", "name": "Elena Vance"},
                        )
                        utts.append(say)
            self.assertGreaterEqual(len(set(utts)), 2)

    def test_validation_rejects_missing_initiating_say_without_label_fallback(self) -> None:
        missing_say_row = {
            "id": "broken.choice",
            "display": {"label": "Say something secret"},
            "frame": {
                "kind": "semantic_click_frame",
                "intent": "INFORM",
                "subject": "IDENTITY",
                "labelFallback": "Say something secret",
            },
        }
        self.assertEqual(semantic_suggestion_title(missing_say_row), "Say something secret")
        self.assertIsNone(resolve_initiating_say(missing_say_row, missing_say_row["frame"]))
        valid, reason = validate_affordance_speech(missing_say_row, missing_say_row["frame"])
        self.assertFalse(valid)
        self.assertEqual(reason, "initiating_say_required")

        intentional_same_row = {
            "id": "authored.same",
            "display": {"label": "Follow me.", "utterance": "Follow me."},
            "frame": {
                "kind": "semantic_click_frame",
                "intent": "REQUEST",
                "action": "FOLLOW",
                "labelFallback": "Follow me.",
                "utteranceFallback": "Follow me.",
            },
        }
        ok_same, reason_same = validate_affordance_speech(
            intentional_same_row, intentional_same_row["frame"]
        )
        self.assertTrue(ok_same)
        self.assertEqual(reason_same, "valid_initiating_say")


class S10ALabelSpeechTkJourneyTests(SemanticLabGuiTestCase):
    def test_tk_open_conversation_identity_exchange_click_and_restart_repeat(
        self,
    ) -> None:
        if not os.environ.get("DISPLAY"):
            self.skipTest("Tk display is unavailable")

        root = tk.Tk()
        app = self.make_gui_app(
            root,
            "--mods",
            "ProjectHoomans",
            "--provider-root",
            str(WORKSHOP_ROOT),
            "--core-repository",
            str(CORE_ROOT),
            "--hoomans-repository",
            str(HOOMANS_ROOT),
        )

        def run_identity_cycle(cycle_name: str) -> tuple[int, int]:
            self.wait_for_worker_ready(root, app, timeout=25.0)
            self.wait_for_operation(root, app, timeout=25.0)
            app.main_tabs.select(app.simulation_tab)

            app.open_conversation_button.invoke()
            self.wait_for_operation(root, app, timeout=20.0)

            app.input_var.set("who are you")
            app.submit()
            self.wait_for(
                root,
                lambda: not app.busy
                and any(
                    btn.winfo_ismapped()
                    and btn.cget("text") == "Say your real name"
                    for btn in app.suggestion_buttons
                ),
                f"[{cycle_name}] expected 'Say your real name' button in Response Channel",
                timeout=20.0,
            )

            real_index = next(
                idx
                for idx, btn in enumerate(app.suggestion_buttons)
                if btn.winfo_ismapped() and btn.cget("text") == "Say your real name"
            )
            button = app.suggestion_buttons[real_index]
            self.assertEqual(button.cget("text"), "Say your real name")

            selected_row = app.suggestion_rows[real_index]
            expected_say = resolve_initiating_say(
                selected_row, selected_row.get("frame")
            )
            self.assertIsNotNone(expected_say)
            self.assertIn("Patrick Patz", expected_say or "")
            self.assertNotEqual(expected_say, "Say your real name")

            transcript_before = app.transcript.get("1.0", "end-1c")
            button.invoke()
            self.wait_for(
                root,
                lambda: not app.busy
                and len(app.transcript.get("1.0", "end-1c")) > len(transcript_before),
                f"[{cycle_name}] expected transcript update after widget click",
                timeout=20.0,
            )

            transcript_after = app.transcript.get("1.0", "end-1c")
            delta = transcript_after[len(transcript_before):]
            self.assertIn("PLAYER:", delta)
            self.assertIn("Patrick Patz", delta)
            self.assertNotIn("PLAYER: Say your real name", delta)

            last_resp = app.last_response or {}
            ir = (last_resp.get("result") or {}).get("ir") or {}
            self.assertEqual(ir.get("intent"), "INFORM")
            self.assertEqual(ir.get("subject"), "IDENTITY")
            self.assertEqual(
                (ir.get("slots") or {}).get("identityClaim"),
                {"mode": "canonical", "name": "Patrick Patz"},
            )
            self.assertEqual(
                (last_resp.get("relationshipAfter") or {}).get("identityTrust"),
                "trusted",
            )

            catalog = app.session.submit(lambda w: w.flow_catalog()).result(
                timeout=15.0
            )
            flow_payload = catalog.value
            return (
                len(flow_payload.get("flows") or []),
                len(flow_payload.get("responsePoolCatalog") or []),
            )

        try:
            counts_before = run_identity_cycle("initial")
            app.restart()
            counts_after = run_identity_cycle("restarted")
            self.assertEqual(counts_before, counts_after)
        finally:
            app.close()


if __name__ == "__main__":
    unittest.main()
