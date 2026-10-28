"""Generic contextual admission and visible repair through production Lua."""
import unittest
from tools.semantic_harness.tests.test_unified_evidence_e0 import saved_worker, storage


def admission(result):
    return result["observation"]["director"]["pragmatic"]["contextualAdmission"]


class UnifiedEvidenceE4Tests(unittest.TestCase):
    def test_reset_session_repeat_and_newer_grievance(self):
        with saved_worker() as worker:
            result = worker.input("im sorry")
            self.assertEqual(result["observation"]["ir"]["intent"], "APOLOGIZE")
            self.assertEqual(admission(result)["status"], "unresolved")
            self.assertEqual(result["observation"]["interactionPlan"]["behaviorID"], "behavior.clarify_context")
            worker.input("fuck you")
            result = worker.input("im sorry")
            self.assertEqual(admission(result)["status"], "grounded")
            self.assertEqual(result["observation"]["interactionPlan"]["behaviorID"], "behavior.reconcile")
            self.assertFalse(admission(worker.input("im sorry"))["admitted"])
            worker.input("fuck you")
            self.assertTrue(admission(worker.input("im sorry"))["admitted"])

    def test_serialized_today_and_durable_repair(self):
        with saved_worker() as worker:
            worker.input("fuck you")
            raw = storage(worker)["serializedRecord"]
        with saved_worker(raw) as worker:
            result = worker.input("im sorry")
            self.assertEqual(admission(result)["status"], "grounded")
            self.assertEqual(admission(result)["selected"]["sourceTier"], "TODAY")
        with saved_worker() as worker:
            storage(worker, addMemory="abandoned_in_combat")
            storage(worker, advanceDays=1)
            self.assertEqual(admission(worker.input("im sorry"))["selected"]["sourceTier"], "DURABLE")
