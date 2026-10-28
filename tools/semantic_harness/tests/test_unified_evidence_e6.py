"""A removable future mechanic registers data without editing shared algorithms."""
from hashlib import sha256
from pathlib import Path
import unittest
from tools.semantic_harness.runtime.config import discover_newest_runtime
from tools.semantic_harness.tests.test_unified_evidence_e0 import saved_worker, storage

ROOT = Path(__file__).resolve().parents[3]
MOD = ROOT / "Contents/mods/ProjectHoomans"
ALGORITHMS = [MOD / discover_newest_runtime(MOD) / "media/lua/shared/PNC/Semantics" / name
              for name in ["PNC_SemanticInteractionEvidence.lua", "PNC_SemanticInteractionEvidenceAdapters.lua",
                           "PNC_SemanticInteractionRelations.lua", "PNC_SemanticPragmaticResolver.lua"]]


def hashes():
    return {path.name: sha256(path.read_bytes()).hexdigest() for path in ALGORITHMS}


class UnifiedEvidenceE6Tests(unittest.TestCase):
    def test_future_commitment_uses_all_tiers_existing_owners_and_content(self):
        before_hashes = hashes()
        for tier in ["SESSION", "TODAY", "DURABLE"]:
            with self.subTest(tier=tier), saved_worker() as worker:
                worker.input("hello")
                roots = storage(worker)["roots"]
                def invoke(**payload):
                    return worker._request("TEST_FUTURE_EVIDENCE", {"tier": tier, **payload})
                result = invoke(recordAct="FIXTURE_PROMISE")
                self.assertEqual(result["admission"]["status"], "grounded")
                self.assertEqual(result["admission"]["selected"]["sourceTier"], tier)
                self.assertEqual(result["interactionPlan"]["behaviorID"], "behavior.fixture_commitment")
                self.assertTrue(result["realizedText"])
                self.assertEqual(result["utterancePlanKind"], "semantic_utterance_plan")
                self.assertTrue(result["registered"])
                invoke(recordAct="FIXTURE_FULFILL")
                self.assertFalse(invoke()["admission"]["admitted"])
                invoke(recordAct="FIXTURE_PROMISE", serial=2)
                self.assertTrue(invoke(queryAct="FIXTURE_BREACH")["admission"]["admitted"])
                invoke(recordAct="FIXTURE_BREACH", queryAct="FIXTURE_EXPLAIN")
                self.assertTrue(invoke(queryAct="FIXTURE_EXPLAIN")["admission"]["admitted"])
                repair = invoke(queryAct="APOLOGIZE")
                self.assertTrue(repair["admission"]["admitted"])
                self.assertEqual(repair["interactionPlan"]["behaviorID"], "behavior.reconcile")
                invoke(recordAct="FIXTURE_EXPLAIN", queryAct="FIXTURE_EXPLAIN")
                self.assertFalse(invoke(queryAct="FIXTURE_EXPLAIN")["admission"]["admitted"])
                invoke(recordAct="FIXTURE_REPAIR", queryAct="APOLOGIZE")
                self.assertFalse(invoke(queryAct="APOLOGIZE")["admission"]["admitted"])
                before = storage(worker)
                invoke(queryAct="FIXTURE_FULFILL")
                after = storage(worker)
                self.assertEqual(before["serializedRecord"], after["serializedRecord"])
                self.assertEqual(roots, after["roots"])
        self.assertEqual(before_hashes, hashes())
