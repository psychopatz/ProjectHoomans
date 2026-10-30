from __future__ import annotations

import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class CoherentConversationC3C4Tests(unittest.TestCase):
    def test_pending_question_contextualizes_short_disagreement(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            worker.input("hello there")
            result = worker.input("not really")

        ir = result["result"]["ir"]
        frame = ir["extensions"]["discourseFrame"]
        self.assertEqual(ir["intent"], "DISAGREE")
        self.assertEqual(ir["subject"], "greeting")
        self.assertEqual(ir["extensions"]["topic"], "greeting")
        self.assertEqual(frame["topic"], "greeting")
        self.assertEqual(frame["topicSource"], "pending_interaction")
        self.assertEqual(frame["subjectSource"], "pending_interaction")
        self.assertEqual(frame["replyTo"]["kind"], "pending_interaction")
        self.assertEqual(frame["replyTo"]["flowID"], "greeting")
        self.assertGreater(frame["contextualSupport"], 0)
        self.assertEqual(
            result["result"]["candidateDiagnostics"]["reason"],
            "contextual_discourse_candidate",
        )
        flow = result["result"]["decision"]["flow"]
        self.assertEqual(flow["topic"], "greeting")

    def test_skepticism_uses_same_contextual_reply_path(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            worker.input("hello there")
            result = worker.input("yeah right")

        ir = result["result"]["ir"]
        frame = ir["extensions"]["discourseFrame"]
        self.assertEqual(ir["intent"], "DISAGREE")
        self.assertTrue(ir["modifiers"]["skeptical"])
        self.assertEqual(ir["subject"], "greeting")
        self.assertEqual(frame["replyTo"]["kind"], "pending_interaction")
        self.assertEqual(frame["topic"], "greeting")

    def test_standalone_disagreement_is_not_given_fake_reply_context(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            result = worker.input("not really")

        frame = result["result"]["ir"]["extensions"]["discourseFrame"]
        self.assertIsNone(frame.get("replyTo"))
        self.assertEqual(frame["contextualSupport"], 0)

    def test_unresolved_mutation_is_clarified_before_dispatch(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            result = worker.input("give me waterr")

        ir = result["result"]["ir"]
        decision = result["result"]["decision"]
        self.assertEqual(ir["action"], "GIVE")
        self.assertTrue(ir["object"]["unresolved"])
        self.assertEqual(decision["branch"], "ASK_CLARIFICATION")
        risk = decision["diagnostics"]["riskAssessment"]
        self.assertFalse(risk["accepted"])
        self.assertEqual(risk["riskClass"], "mutating")
        self.assertEqual(risk["reason"], "unresolved_action_reference")
        self.assertEqual(risk["unresolvedField"], "object")
        self.assertFalse(result["observation"]["sideEffects"]["dispatchTransportCount"])

    def test_resolved_exact_mutation_remains_admitted(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            result = worker.input("give me water")

        ir = result["result"]["ir"]
        decision = result["result"]["decision"]
        self.assertEqual(ir["action"], "GIVE")
        self.assertFalse(ir["object"]["unresolved"])
        risk = decision["diagnostics"]["riskAssessment"]
        self.assertTrue(risk["accepted"])
        self.assertEqual(risk["reason"], "strict_mutation_admitted")
        self.assertEqual(decision["branch"], "COMMAND_ACCEPTED")

    def test_recovered_mutating_candidate_never_becomes_authoritative(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            result = worker.input("followme")

        ir = result["result"]["ir"]
        diagnostics = result["result"]["candidateDiagnostics"]
        self.assertIsNone(ir.get("action"))
        rejection = next(
            row
            for row in diagnostics["rejections"]
            if row["patternID"] == "pnc.command.follow"
        )
        self.assertEqual(rejection["reason"], "recovered_mutating_action")

    def test_fuzzy_nonmutating_social_language_remains_usable(self) -> None:
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            result = worker.input("yeah rigt")

        ir = result["result"]["ir"]
        decision = result["result"]["decision"]
        self.assertEqual(ir["intent"], "DISAGREE")
        self.assertEqual(ir["provenance"]["candidatePass"], "fuzzy")
        self.assertEqual(decision["branch"], "SOCIAL_ACKNOWLEDGED")
        self.assertTrue(decision["diagnostics"]["riskAssessment"]["accepted"])


if __name__ == "__main__":
    unittest.main()
