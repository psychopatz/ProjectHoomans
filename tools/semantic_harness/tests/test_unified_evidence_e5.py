"""Three first-party relation families share providers, resolver and director."""
import unittest
from tools.semantic_harness.tests.test_unified_evidence_e0 import saved_worker, storage
from tools.semantic_harness.tests.test_unified_evidence_e4 import admission


class UnifiedEvidenceE5Tests(unittest.TestCase):
    def test_authoritative_npc_aid_grounds_gratitude(self):
        with saved_worker() as worker:
            before = storage(worker)
            after = storage(worker, emitHelp="gratitude")
            self.assertTrue(any(row["eventType"] == "provided_treated_wound"
                                for row in after["evidence"]["rows"]))
            self.assertEqual(after["relationship"]["approval"], 0)
            result = worker.input("thanks")
            self.assertEqual(admission(result)["selected"]["relation"], "gratitude")
            self.assertEqual(result["observation"]["interactionPlan"]["behaviorID"], "behavior.acknowledge_thanks")
            self.assertFalse(admission(worker.input("thanks"))["admitted"])
            self.assertEqual(before["roots"], storage(worker)["roots"])

    def test_open_offer_request_question_admit_replies(self):
        for opening, text in [("OFFER", "yes"), ("REQUEST", "no"), ("QUESTION", "okay")]:
            with self.subTest(opening=opening), saved_worker() as worker:
                worker.input("hello")
                storage(worker, openResponse=opening)
                result = worker.input(text)
                self.assertEqual(admission(result)["status"], "grounded")
                self.assertEqual(admission(result)["selected"]["relation"], "response")
                self.assertEqual(result["observation"]["interactionPlan"]["behaviorID"], "behavior.acknowledge_reply")

    def test_generated_acknowledgement_uses_the_same_admission(self):
        with saved_worker() as worker:
            worker.input("hello")
            storage(worker, openResponse="OFFER")
            result = worker.input("what time is it?")
            candidates = result["observation"]["suggestions"]["candidates"]
            frame = next(row["frame"] for row in candidates if row["id"] == "generated.acknowledge")
            clicked = worker.suggestion_click(frame)
            self.assertEqual(clicked["observation"]["ir"]["speechAct"], "ACKNOWLEDGE")
            self.assertEqual(admission(clicked)["selected"]["relation"], "response")

    def test_missing_antecedents_and_direction_remain_unresolved(self):
        for text in ["thanks", "yes", "no"]:
            with self.subTest(text=text), saved_worker() as worker:
                result = worker.input(text)
                self.assertFalse(admission(result)["admitted"])
        with saved_worker() as worker:
            storage(worker, project="treated_wound")  # player aided NPC, opposite direction
            self.assertFalse(admission(worker.input("thanks"))["admitted"])

    def test_player_scoped_presentation_exports_only_bounded_evidence(self):
        with saved_worker() as worker:
            worker.input("fuck you")
            before = storage(worker)
            result = storage(worker, presentation=True)
            self.assertEqual(before["serializedRecord"], result["serializedRecord"])
            projection = result["presentationEvidence"]
            self.assertLessEqual(len(projection["rows"]), 16)
            self.assertTrue(any(row["sourceTier"] == "TODAY" for row in projection["rows"]))
            self.assertTrue(any(row["sourceTier"] == "DURABLE" for row in projection["rows"]))
            for row in projection["rows"]:
                self.assertNotIn("rawText", row)
                self.assertNotIn("contextualRelevance", row)
