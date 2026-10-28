"""Final storage, source-isolation and bounded query acceptance."""
from copy import deepcopy
import json
import time
import unittest
from tools.semantic_harness.tests.test_unified_evidence_e0 import saved_worker, storage, byte_size

FORBIDDEN = {"semanticEvidence", "contextualAdmission", "contextualRelevance", "transcript",
             "rawText", "normalizedText", "utterancePlan", "interactionPlan", "generatedChoices",
             "realizedText", "behaviorRelevance"}


def keys(value):
    if isinstance(value, dict):
        return set(value).union(*(keys(item) for item in value.values()))
    if isinstance(value, list):
        return set().union(*(keys(item) for item in value))
    return set()


def capture_stress():
    with saved_worker() as worker:
        source = deepcopy(worker.source_snapshot.to_dict())
        before = worker._request("TEST_EVIDENCE_STRESS")
        first = worker._request("TEST_EVIDENCE_STRESS", {"count": 128, "seedMeaningful": True})
        second = worker._request("TEST_EVIDENCE_STRESS", {"start": 128, "count": 128})
        repeated = worker._request("TEST_EVIDENCE_STRESS", {"repeatPair": True})
        start = time.perf_counter()
        bench = worker._request("TEST_EVIDENCE_STRESS", {"queryIterations": 200})
        elapsed = time.perf_counter() - start
        rolled = storage(worker, advanceDays=1)
        immutable = source == worker.source_snapshot.to_dict()
        summaries = []
        for label, sample in [("before", before), ("128", first), ("256", second), ("repeat", repeated)]:
            summaries.append({"stage": label, "counts": sample["counts"],
                "npcSerializedJSONBytes": byte_size(sample["serializedRecord"]),
                "playerRegistryJSONBytes": byte_size(sample["playerRecord"]),
                "compactJSONBytes": byte_size(sample.get("memory")), "roots": sample["roots"]})
        report = {"schema": "unified-evidence.storage.v1", "serialization": "canonical JSON of production serialized NPC and owning player registry records",
            "samples": summaries, "sourceSnapshotUnchanged": immutable,
            "benchmark": {"iterations": 200, "wallSecondsIncludingRPC": elapsed,
                "rows": len(bench["evidence"]["rows"]), "providers": len(bench["evidence"]["providers"])},
            "rollover": {"shortRemoved": not (rolled.get("memory") or {}).get("s"),
                "topicsRemoved": not (rolled.get("memory") or {}).get("t"),
                "durableCount": len((rolled.get("memory") or {}).get("l", [])) // 4}}
        return report, [before, first, second, repeated], bench, rolled


class UnifiedEvidenceE7Tests(unittest.TestCase):
    def test_busy_conduct_provider_cannot_hide_durable_closing_fact(self):
        from tools.semantic_harness.tests.test_unified_evidence_e4 import admission
        with saved_worker() as worker:
            worker._request("TEST_EVIDENCE_STRESS", {"count": 128, "seedMeaningful": True})
            self.assertTrue(admission(worker.input("im sorry"))["admitted"])
            storage(worker, advanceDays=1, clearSession=True)
            result = worker.input("im sorry")
            frame = result["observation"]["director"]["pragmatic"]
            self.assertTrue(any(row["providerID"] == "projecthoomans.conduct" for row in frame["evidence"]["rows"]))
            self.assertTrue(any(row["eventType"] == "semantic_apologize" for row in frame["evidence"]["rows"]))
            self.assertFalse(frame["contextualAdmission"]["admitted"])

    def test_targeted_query_preserves_rare_durable_relation_under_unrelated_pressure(self):
        from tools.semantic_harness.tests.test_unified_evidence_e4 import admission
        with saved_worker() as worker:
            worker.input("fuck you")
            raw = storage(worker)["serializedRecord"]
        with saved_worker(raw) as worker:
            storage(worker, advanceDays=1)
            snapshot = storage(worker, fillUnrelated=18, presentation=True)
            rows = snapshot["presentationEvidence"]["rows"]
            self.assertTrue(any("repair" in row["relations"]["opens"] for row in rows))
            self.assertTrue(any("gratitude" in row["relations"]["opens"] for row in rows))
            result = admission(worker.input("im sorry"))
            self.assertTrue(result["admitted"])
            self.assertEqual(result["selected"]["sourceTier"], "DURABLE")

    def test_live_semantic_pipeline_does_not_persist_derived_or_realized_payloads(self):
        with saved_worker() as worker:
            source = deepcopy(worker.source_snapshot.to_dict())
            worker.input("fuck you")
            worker.input("im sorry")
            storage(worker, emitHelp="persistent-boundary")
            worker.input("thanks")
            snapshot = worker._request("TEST_EVIDENCE_STRESS")
            for owner in [snapshot["serializedRecord"], snapshot["playerRecord"]]:
                self.assertFalse(keys(owner) & FORBIDDEN)
                serialized = json.dumps(owner).lower()
                self.assertNotIn("im sorry", serialized)
                self.assertNotIn("i hear you.", serialized)
                self.assertNotIn("what are you referring to?", serialized)
            self.assertEqual(source, worker.source_snapshot.to_dict())

    def test_lab_diagnostics_expose_independent_evidence_signals(self):
        from tools.semantic_harness.ui.interaction_inspector import interaction_summary
        with saved_worker() as worker:
            worker.input("fuck you")
            result = worker.input("im sorry")
            summary = interaction_summary(result["observation"])
        for label in ["contextual admission:", "retention salience:", "confidence:",
                      "effective strength:", "recency hours:", "contextual relevance:", "priority:", "semantic relations:"]:
            self.assertIn(label, summary)
        self.assertIn("[SESSION]", summary)
        self.assertIn("[TODAY]", summary)
        self.assertIn("[DURABLE]", summary)

    def test_storage_pressure_plateaus_and_queries_remain_read_only(self):
        report, samples, bench, rolled = capture_stress()
        before, first, second, repeated = samples
        self.assertTrue(report["sourceSnapshotUnchanged"])
        for sample in samples:
            for key, maximum in {"today": 8, "durable": 6, "relationship": 20, "conduct": 64, "journal": 80, "topicPlayers": 4}.items():
                self.assertLessEqual(sample["counts"][key], maximum)
            for owner in [sample["serializedRecord"], sample["playerRecord"]]:
                self.assertFalse(keys(owner) & FORBIDDEN, keys(owner) & FORBIDDEN)
            self.assertEqual(sample["roots"], before["roots"])
        self.assertEqual(second["counts"]["relationship"], 20)
        self.assertEqual(second["counts"]["conduct"], 64)
        for sample in [first, second, repeated]:
            self.assertIn(1101, sample["memory"]["s"][::3])
            self.assertIn(1101, sample["memory"]["l"][::4])
            s, l = sample["memory"]["s"], sample["memory"]["l"]
            self.assertEqual(len(set(zip(s[::3], s[1::3]))), len(s) // 3)
            self.assertEqual(len(set(zip(l[::4], l[1::4]))), len(l) // 4)
            self.assertTrue(all(0 < mask <= sample["limits"]["topicMask"] for mask in sample["memory"]["t"][1::2]))
        self.assertEqual(first["counts"], second["counts"])
        self.assertLess(abs(byte_size(second["serializedRecord"]) - byte_size(first["serializedRecord"])), 5000)
        self.assertLess(abs(byte_size(second["playerRecord"]) - byte_size(first["playerRecord"])), 5000)
        self.assertEqual(repeated["serializedRecord"], bench["serializedRecord"])
        self.assertEqual(repeated["playerRecord"], bench["playerRecord"])
        self.assertLessEqual(len(bench["evidence"]["rows"]), 16)
        self.assertLessEqual(len(bench["evidence"]["providers"]), 16)
        self.assertLess(report["benchmark"]["wallSecondsIncludingRPC"], 5)
        self.assertTrue(report["rollover"]["shortRemoved"])
        self.assertTrue(report["rollover"]["topicsRemoved"])
        self.assertLessEqual(report["rollover"]["durableCount"], 6)
