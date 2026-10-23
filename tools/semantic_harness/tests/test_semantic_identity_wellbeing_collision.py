"""Production-Lua regression coverage for identity/wellbeing collisions."""

from __future__ import annotations

import unittest
from pathlib import Path

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.testing.runner import load_case, run_case
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


ORIGINAL_TRACE_CASE = (
    Path(__file__).resolve().parents[1]
    / "scenarios"
    / "identity_wellbeing_original_trace_case.json"
)
CANDIDATE_ELIGIBILITY_CASE = (
    Path(__file__).resolve().parents[1]
    / "scenarios"
    / "candidate_eligibility_case.json"
)


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

    def test_pending_identity_presents_three_deterministic_choice_frames(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            turn = worker.input("who are you")

        candidates = turn["observation"]["suggestions"]["candidates"]
        self.assertEqual(
            [candidate["id"] for candidate in candidates],
            [
                "identity.choice.real_name",
                "identity.choice.refuse_name",
                "identity.choice.lie_name",
            ],
        )
        self.assertEqual(
            candidates[0]["frame"]["extensions"]["identityClaimMode"],
            "canonical",
        )
        self.assertEqual(candidates[1]["frame"]["intent"], "REFUSE")
        self.assertEqual(
            candidates[1]["frame"]["extensions"]["identityResponseStyle"],
            "rude",
        )
        alias = candidates[2]["frame"]["slots"]["identityClaim"]["name"]
        self.assertTrue(alias)
        self.assertEqual(
            candidates[2]["frame"]["extensions"]["identityClaimMode"],
            "generated",
        )
        self.assertEqual(
            turn["contextAfter"]["dialogue"]["pendingIdentityExchange"],
            {"kind": "PLAYER_NAME", "requestedAt": 1},
        )

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
        self.assertEqual(self.message_text(turn), "I don't believe you.")
        self.assertIsNone(self.pending_exchange(turn))

    def test_lie_choice_submits_generated_alias_and_uses_disbelief_response(self) -> None:
        with LuaSemanticWorker(merge({}, DEFAULT_SCENARIO)) as worker:
            turn = worker.input("who are you")
            lie = next(
                candidate
                for candidate in turn["observation"]["suggestions"]["candidates"]
                if candidate["id"] == "identity.choice.lie_name"
            )
            alias = lie["frame"]["slots"]["identityClaim"]["name"]
            turn = worker.suggestion_click(lie["frame"])

        requests = self.identity_requests(turn, "identity_claim")
        self.assertEqual(len(requests), 1)
        self.assertEqual(requests[0]["payload"]["claimedName"], alias)
        self.assertEqual(
            turn["result"]["decision"]["branch"],
            "IDENTITY_CLAIM_RECEIVED",
        )
        self.assertEqual(turn["relationshipAfter"]["identityTrust"], "untrustworthy")
        self.assertEqual(self.message_text(turn), "I don't believe you.")
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

    def test_original_identity_wellbeing_conversation_trace(self) -> None:
        run = run_case(load_case(ORIGINAL_TRACE_CASE))
        self.assertEqual(run.conflicts, [])
        self.assertEqual(
            [turn["input"] for turn in run.turns],
            ["who are you", "are you okay", "im fine thanks", "My name is Patrick"],
        )

        required_modules = {
            "PsychopatzCore/Semantics/PsychopatzSemantic.lua",
            "PNC/Translation/PNC_TranslationBootstrap.lua",
            "PNC/Semantics/PNC_SemanticDialoguePolicy.lua",
            "PNC/Semantics/PNC_SemanticDialogueInput_Presentation.lua",
            "PNC/Semantics/PNC_SemanticIdentityExchange.lua",
        }
        for turn in run.turns:
            self.assertTrue(turn["accepted"], turn.get("reason"))
            self.assertEqual(turn["llmCalls"], 0)
            self.assertTrue(required_modules.issubset(set(turn["loadedModules"])))
            self.assertEqual(turn["translation"]["language"], "EN")
            self.assertEqual(len(turn["messages"]), 1)
            message = turn["messages"][0]["payload"]
            self.assertTrue(message.get("key"))
            self.assertTrue(message.get("text"))

        first, wellbeing_question, wellbeing_answer, identity_claim = run.turns
        self.assertIsNone(first["contextBefore"]["state"])
        self.assertIsNone(first["contextBefore"]["dialogue"])
        self.assertEqual(
            first["result"]["ir"]["intent"],
            "QUESTION",
        )
        self.assertEqual(first["result"]["ir"]["subject"], "IDENTITY")
        self.assertEqual(
            first["result"]["ir"]["provenance"]["pattern"],
            "pnc.question.identity",
        )
        self.assertEqual(first["result"]["decision"]["branch"], "QUESTION_RECEIVED")
        self.assertTrue(
            first["result"]["decision"]["response"]["templateID"].startswith(
                "semantic.question.identity."
            )
        )
        self.assertEqual(first["transport"], [])
        self.assertEqual(first["toolCalls"], [])
        self.assertEqual(first["relationshipBefore"], first["relationshipAfter"])
        self.assertEqual(
            self.pending_exchange(first),
            {"kind": "PLAYER_NAME", "requestedAt": 1},
        )

        self.assertEqual(wellbeing_question["result"]["ir"]["intent"], "QUESTION")
        self.assertEqual(wellbeing_question["result"]["ir"]["subject"], "WELLBEING")
        self.assertEqual(
            wellbeing_question["result"]["ir"]["provenance"]["pattern"],
            "pnc.question.wellbeing_okay",
        )
        self.assertEqual(
            wellbeing_question["result"]["decision"]["branch"],
            "QUESTION_RECEIVED",
        )
        self.assertTrue(
            wellbeing_question["result"]["decision"]["response"]["templateID"].startswith(
                "semantic.question.wellbeing."
            )
        )
        self.assert_no_identity_effect(wellbeing_question)
        self.assertEqual(
            self.pending_exchange(wellbeing_question),
            {"kind": "PLAYER_NAME", "requestedAt": 1},
        )

        self.assertEqual(wellbeing_answer["result"]["ir"]["intent"], "INFORM")
        self.assertEqual(wellbeing_answer["result"]["ir"]["subject"], "WELLBEING")
        self.assertEqual(
            wellbeing_answer["result"]["ir"]["provenance"]["pattern"],
            "pnc.state.self_wellbeing_im_plain_fine_thanks",
        )
        self.assertEqual(
            wellbeing_answer["result"]["decision"]["branch"],
            "SELF_STATE_RECEIVED",
        )
        self.assertTrue(
            wellbeing_answer["result"]["decision"]["response"]["templateID"].startswith(
                "semantic.self_state.wellbeing"
            )
        )
        self.assert_no_identity_effect(wellbeing_answer)
        self.assertEqual(
            self.pending_exchange(wellbeing_answer),
            {"kind": "PLAYER_NAME", "requestedAt": 1},
        )

        self.assertEqual(identity_claim["result"]["ir"]["intent"], "INFORM")
        self.assertEqual(identity_claim["result"]["ir"]["subject"], "IDENTITY")
        self.assertEqual(
            identity_claim["result"]["ir"]["provenance"]["pattern"],
            "pnc.identity.my_name_is",
        )
        self.assertEqual(
            identity_claim["result"]["decision"]["branch"],
            "IDENTITY_CLAIM_RECEIVED",
        )
        self.assertEqual(
            identity_claim["result"]["decision"]["response"]["templateID"],
            "semantic.identity.exchange",
        )
        self.assertEqual(
            [
                event["command"]
                for event in identity_claim["transport"]
                if event.get("direction") in {"client_to_server", "server_to_client"}
            ],
            ["SemanticIdentityRequest", "SemanticIdentityResult"],
        )
        self.assertEqual(
            {call["name"] for call in identity_claim["toolCalls"]},
            {"SemanticIdentityRequest", "AdjustRelationship"},
        )
        self.assertEqual(
            identity_claim["relationshipAfter"]["identityTrust"],
            "trusted",
        )
        self.assertEqual(identity_claim["relationshipAfter"]["approval"], 1)
        self.assertEqual(identity_claim["relationshipAfter"]["respect"], 2)
        self.assertEqual(identity_claim["relationshipAfter"]["familiarity"], 6)
        self.assertEqual(identity_claim["relationshipAfter"]["revision"], 2)
        self.assertIsNone(self.pending_exchange(identity_claim))
        self.assertTrue(
            any(
                lookup["key"] == "UI_PNC_Conversation_Semantic_IdentityExchangeConfirmed"
                and lookup["kind"] == "trFormat"
                and lookup["fallbackUsed"] is False
                for lookup in identity_claim["translation"]["lookups"]
            )
        )


    def test_real_worker_rejects_fuzzy_mutating_candidate(self) -> None:
        run = run_case(load_case(CANDIDATE_ELIGIBILITY_CASE))
        self.assertEqual(run.conflicts, [])
        self.assertEqual(len(run.turns), 1)
        turn = run.turns[0]
        result = turn["result"]
        self.assertEqual(result["decision"]["branch"], "ASK_CLARIFICATION")
        self.assertTrue(result["ir"]["diagnostics"]["noMatch"])
        diagnostics = result["candidateDiagnostics"]
        self.assertEqual(diagnostics["reason"], "no_eligible_candidate")
        self.assertEqual(diagnostics["rejectedCount"], 1)
        self.assertEqual(
            diagnostics["rejections"][0]["reason"],
            "fuzzy_mutating_action",
        )
        self.assertEqual(
            diagnostics["rejections"][0]["patternID"],
            "pnc.command.follow",
        )
        self.assertEqual(turn["transport"], [])
        self.assertEqual(turn["toolCalls"], [])
        self.assertIsNone(result.get("actionResult"))
        self.assertEqual(
            turn["relationshipBefore"], turn["relationshipAfter"]
        )


if __name__ == "__main__":
    unittest.main()
