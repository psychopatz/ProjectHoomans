"""Production-Lua regression coverage for identity/wellbeing collisions."""

from __future__ import annotations

import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


class SemanticIdentityWellbeingCollisionTests(unittest.TestCase):
    @staticmethod
    def message_text(turn: dict) -> str:
        messages = turn.get("messages", [])
        if not messages:
            return ""
        payload = messages[0].get("payload", {})
        return payload.get("fallback") or payload.get("text") or ""

    @staticmethod
    def pending_exchange(turn: dict) -> dict | None:
        return turn["contextAfter"]["dialogue"].get("pendingIdentityExchange")

    @staticmethod
    def identity_requests(turn: dict, kind: str | None = None) -> list[dict]:
        requests = [
            event for event in turn["transport"]
            if event.get("command") == "SemanticIdentityRequest"
        ]
        if kind is not None:
            requests = [
                event for event in requests
                if event.get("payload", {}).get("kind") == kind
            ]
        return requests

    def assert_no_identity_effect(self, turn: dict) -> None:
        self.assertEqual(turn["transport"], [])
        self.assertEqual(turn["toolCalls"], [])
        self.assertEqual(turn["relationshipBefore"], turn["relationshipAfter"])
        self.assertEqual(turn["relationshipAfter"]["identityTrust"], "unknown")

    def test_wellbeing_and_need_reports_do_not_become_identity_claims(self) -> None:
        cases = (
            (
                "im fine thanks",
                "pnc.state.self_wellbeing_im_plain_fine_thanks",
                "WELLBEING",
            ),
            (
                "I'm fine, thank you",
                "pnc.state.self_wellbeing_im_fine_thank_you",
                "WELLBEING",
            ),
            (
                "I'm hungry",
                "pnc.state.self_hunger_im",
                "HUNGER",
            ),
        )
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            worker.input("who are you")
            for text, pattern, subject in cases:
                with self.subTest(text=text):
                    turn = worker.input(text)
                    ir = turn["result"]["ir"]
                    self.assertEqual(ir["provenance"]["pattern"], pattern)
                    self.assertEqual(ir["intent"], "INFORM")
                    self.assertEqual(ir["subject"], subject)
                    self.assertEqual(
                        turn["result"]["decision"]["branch"],
                        "SELF_STATE_RECEIVED",
                    )
                    self.assertEqual(len(turn["messages"]), 1)
                    self.assert_no_identity_effect(turn)
                    self.assertEqual(
                        self.pending_exchange(turn),
                        {"kind": "PLAYER_NAME", "requestedAt": 1},
                    )

    def test_questions_are_safe_interruptions_while_name_is_pending(self) -> None:
        for text, pattern, subject in (
            ("Are you okay?", "pnc.question.wellbeing_okay", "WELLBEING"),
            ("what time is it", "pnc.question.time", "TIME"),
        ):
            with self.subTest(text=text):
                with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
                    worker.input("who are you")
                    turn = worker.input(text)
                ir = turn["result"]["ir"]
                self.assertEqual(ir["provenance"]["pattern"], pattern)
                self.assertEqual(ir["intent"], "QUESTION")
                self.assertEqual(ir["subject"], subject)
                self.assertEqual(
                    turn["result"]["decision"]["branch"],
                    "QUESTION_RECEIVED",
                )
                self.assertEqual(len(turn["messages"]), 1)
                self.assert_no_identity_effect(turn)
                self.assertEqual(
                    self.pending_exchange(turn),
                    {"kind": "PLAYER_NAME", "requestedAt": 1},
                )

    def test_authoritative_true_name_claims_still_work(self) -> None:
        for text, pattern in (
            ("I'm Patrick", "pnc.identity.self_name_im"),
            ("My name is Patrick", "pnc.identity.my_name_is"),
        ):
            with self.subTest(text=text):
                with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
                    worker.input("who are you")
                    turn = worker.input(text)
                ir = turn["result"]["ir"]
                self.assertEqual(ir["provenance"]["pattern"], pattern)
                self.assertTrue(ir["socialContext"]["identityClaim"])
                self.assertEqual(
                    turn["result"]["decision"]["branch"],
                    "IDENTITY_CLAIM_RECEIVED",
                )
                self.assertEqual(len(self.identity_requests(turn, "identity_claim")), 1)
                self.assertEqual(turn["relationshipAfter"]["identityTrust"], "trusted")
                self.assertEqual(turn["relationshipAfter"]["approval"], 1)
                self.assertEqual(turn["relationshipAfter"]["respect"], 2)
                self.assertIsNone(self.pending_exchange(turn))

    def test_false_explicit_name_claim_remains_authoritatively_rejected(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            worker.input("who are you")
            turn = worker.input("I'm Patricia")
        ir = turn["result"]["ir"]
        self.assertTrue(ir["socialContext"]["identityClaim"])
        self.assertEqual(
            turn["result"]["decision"]["branch"],
            "IDENTITY_CLAIM_RECEIVED",
        )
        self.assertEqual(len(self.identity_requests(turn, "identity_claim")), 1)
        self.assertEqual(turn["relationshipAfter"]["identityTrust"], "untrustworthy")
        self.assertEqual(turn["relationshipAfter"]["approval"], -4)
        self.assertEqual(turn["relationshipAfter"]["respect"], -6)
        self.assertIn("isn't your exact name", self.message_text(turn))
        self.assertIsNone(self.pending_exchange(turn))

    def test_explicit_refusal_remains_identity_evasion(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            worker.input("who are you")
            turn = worker.input("no")
        self.assertEqual(
            turn["result"]["decision"]["branch"],
            "IDENTITY_NAME_EVASION",
        )
        self.assertEqual(len(self.identity_requests(turn, "identity_evasion")), 1)
        self.assertEqual(turn["relationshipAfter"]["identityTrust"], "untrustworthy")
        self.assertEqual(turn["relationshipAfter"]["approval"], -2)
        self.assertEqual(turn["relationshipAfter"]["respect"], -3)
        self.assertIsNone(self.pending_exchange(turn))

    def test_identity_interruption_can_resume_without_penalty(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            first = worker.input("who are you")
            interruption = worker.input("Are you okay?")
            resumed = worker.input("I'm Patrick")
        self.assertEqual(
            self.pending_exchange(first),
            {"kind": "PLAYER_NAME", "requestedAt": 1},
        )
        self.assertEqual(
            self.pending_exchange(interruption),
            {"kind": "PLAYER_NAME", "requestedAt": 1},
        )
        self.assert_no_identity_effect(interruption)
        self.assertEqual(
            resumed["result"]["decision"]["branch"],
            "IDENTITY_CLAIM_RECEIVED",
        )
        self.assertEqual(len(self.identity_requests(resumed, "identity_claim")), 1)
        self.assertEqual(resumed["relationshipAfter"]["identityTrust"], "trusted")
        self.assertIsNone(self.pending_exchange(resumed))

    def test_repeated_preview_has_no_effects(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            worker.input("who are you")
            before = worker.snapshot()
            previews = [worker.preview("im fine thanks") for _ in range(2)]
            after = worker.snapshot()

        for preview in previews:
            self.assertEqual(preview["type"], "preview")
            self.assertEqual(
                preview["result"]["ir"]["provenance"]["pattern"],
                "pnc.state.self_wellbeing_im_plain_fine_thanks",
            )
            self.assertEqual(
                preview["result"]["decision"]["branch"],
                "SELF_STATE_RECEIVED",
            )
            self.assertEqual(preview["contextBefore"], preview["contextAfter"])
            self.assertEqual(preview["transport"], [])
            self.assertEqual(preview["toolCalls"], [])
            self.assertEqual(preview["messages"], [])
            self.assertEqual(
                preview["relationshipBefore"], preview["relationshipAfter"]
            )
        self.assertEqual(previews[0]["contextBefore"], previews[1]["contextBefore"])
        self.assertEqual(before["scenario"], after["scenario"])
        self.assertEqual(before["context"], after["context"])
        self.assertEqual(before["relationship"], after["relationship"])
        self.assertEqual(before["transport"], after["transport"])


if __name__ == "__main__":
    unittest.main()
