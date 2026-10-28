"""Revision baseline: production Lua semantics, detached synthetic saved record."""
from copy import deepcopy
import json
import unittest

from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


def saved_worker(raw=None):
    worker = LuaSemanticWorker(deepcopy(DEFAULT_SCENARIO))
    fixture = worker._request("TEST_PRODUCTION_INVENTORY_FIXTURE", {"mode": "SEED_ONLY"})
    if raw is not None:
        fixture["record"] = raw
    scenario = deepcopy(DEFAULT_SCENARIO)
    if raw is not None:
        scenario["conversation"]["id"] = "evidence-replay:" + str(raw.get("recordRevision", 1))
    scenario["npc"]["id"] = scenario["npc"]["npcID"] = fixture["record"]["id"]
    worker.import_source(scenario, source="SAVE", mode="offline_save",
                         source_id="fixture:unified-evidence-e0",
                         provider_payloads={"ProjectHoomans": {
                             "rawRecords": {"npc": fixture["record"]}}})
    return worker


def storage(worker, **payload):
    return worker._request("TEST_EVIDENCE_STORAGE", payload)


def byte_size(value):
    # Transport-independent canonical JSON measurement of production serialized
    # tables; this is not a claim about Java binary ModData allocation overhead.
    return len(json.dumps(value, sort_keys=True, separators=(",", ":")).encode())


def turn(worker, text):
    result = worker.input(text)
    observation = result["observation"]
    return {"intent": observation["ir"]["intent"],
            "confidence": observation["ir"]["confidence"],
            "response": observation["response"].get("text"),
            "pragmatic": (result["result"].get("decision") or {}).get("pragmatic"),
            "director": (observation.get("interactionPlan") or {}).get("behaviorID"),
            "action": observation.get("actionResult"),
            "sessionShape": {key: (len(value) if isinstance(value, (dict, list))
                                    else type(value).__name__)
                for key, value in result.get("contextAfter", {}).get("dialogue", {}).items()}}


def capture():
    report = {"schema": "unified-evidence.e0.v1", "cases": {}}
    with saved_worker() as worker:
        worker.open_conversation()
        before = storage(worker)
        report["cases"]["reset_apology"] = turn(worker, "im sorry")
        report["cases"]["insult"] = turn(worker, "fuck you")
        report["cases"]["session_apology"] = turn(worker, "im sorry")
        after = storage(worker)
        worker.close_conversation()
        worker.open_conversation()
        report["cases"]["today_apology"] = turn(worker, "im sorry")
        reopened = storage(worker)
        report["storage"] = {"before": before.get("memory"),
            "after": after.get("memory"), "limits": after["limits"],
            "recordBytesBefore": byte_size(before["serializedRecord"]),
            "recordBytesAfter": byte_size(after["serializedRecord"]),
            "rootsBefore": before["roots"], "rootsAfter": after["roots"]}
        report["storage"]["afterReopen"] = reopened.get("memory")
        with saved_worker(after["serializedRecord"]) as replay:
            report["cases"]["serialized_today_apology"] = turn(replay, "im sorry")
            report["storage"]["serializedTodayRecall"] = storage(replay).get("memory")
    with saved_worker() as worker:
        storage(worker, project="saved_from_incapacitation", permanent=True)
        old = storage(worker)
        rolled = storage(worker, advanceDays=1)
        report["durable"] = {"before": old.get("memory"), "after": rolled.get("memory"),
                             "recall": turn(worker, "im sorry")}
    with saved_worker() as worker:
        before = storage(worker, saturate=True)
        event = turn(worker, "fuck you")
        after = storage(worker)
        report["saturated"] = {"turn": event,
            "memoryBefore": before.get("memory"), "memoryAfter": after.get("memory"),
            "count": len(after["relationship"].get("memories", [])),
            "recordByteDelta": byte_size(after["serializedRecord"]) - byte_size(before["serializedRecord"])}
    return report


class UnifiedEvidenceE0Tests(unittest.TestCase):
    def test_revision_baseline_is_measured_in_production_worker(self):
        report = capture()
        self.assertEqual(report["cases"]["reset_apology"]["intent"], "APOLOGIZE")
        self.assertEqual(report["cases"]["insult"]["intent"], "INSULT")
        self.assertEqual(report["storage"]["limits"],
                         {"today": 8, "compactDurable": 6, "relationship": 20, "conduct": 64})
        self.assertEqual(report["saturated"]["count"], 20)
        self.assertTrue(report["durable"]["after"].get("l"))
        self.assertFalse(report["durable"]["after"].get("s"))


if __name__ == "__main__":
    unittest.main()
