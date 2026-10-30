"""Keep executable-dispatch evidence distinct from the complete wire log."""
from pathlib import Path
import json
import subprocess
import unittest

from tools.semantic_harness.runtime.config import discover_lua
from tools.semantic_harness.runtime.scenario import DEFAULT_SCENARIO
from tools.semantic_harness.runtime.worker import LuaSemanticWorker


class TransportEvidenceTests(unittest.TestCase):
    def test_partition_keeps_facts_and_fails_closed_for_unknown_commands(self):
        worker = Path(__file__).resolve().parents[1] / "lua"
        script = r'''
            package.path = WORKER_PATH .. "/?.lua;" .. package.path
            local Evidence = require "worker/TransportEvidence"
            local raw = {
                { command = "SemanticInteractionLifecycle", payload = { act = "REQUEST" } },
                { command = "CompanionCommand", payload = { commandID = "follow" } },
                { command = "UnknownFutureCommand" },
                { payload = {} },
            }
            local record = Evidence.annotate({ transport = raw })
            assert(record.transport == raw and #raw == 4)
            assert(#record.factTransport == 1)
            assert(record.factTransport[1] == raw[1])
            assert(#record.dispatchTransport == 3)
            assert(record.dispatchTransport[1] == raw[2])
            assert(record.dispatchTransport[2] == raw[3])
            assert(record.dispatchTransport[3] == raw[4])
            local dispatch, facts = Evidence.partition(nil)
            assert(#dispatch == 0 and #facts == 0)
        '''
        result = subprocess.run(
            [str(discover_lua()), "-e", script.replace("WORKER_PATH", json.dumps(str(worker)))],
            capture_output=True, text=True, timeout=5,
        )
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_real_turn_retains_lifecycle_payload_and_one_gameplay_dispatch(self):
        with LuaSemanticWorker(DEFAULT_SCENARIO) as worker:
            follow = worker.input("Follow me")
            vague = worker.input("yeah rigt")
        self.assertEqual(len(follow["dispatchTransport"]), 1)
        self.assertEqual(follow["dispatchTransport"][0]["command"], "CompanionCommand")
        self.assertEqual(len(follow["factTransport"]), 1)
        fact = follow["factTransport"][0]
        self.assertEqual(fact["command"], "SemanticInteractionLifecycle")
        self.assertEqual(fact["payload"]["interaction"]["act"], "REQUEST")
        self.assertIn(fact, follow["transport"])
        self.assertEqual(len(follow["transport"]), 2)
        self.assertEqual(vague["dispatchTransport"], [])
        self.assertEqual(len(vague["factTransport"]), 1)
        effects = vague["observation"]["sideEffects"]
        self.assertTrue(effects["noGameplayEffects"])
        self.assertFalse(effects["none"], "fact traffic remains observable")
        self.assertEqual(effects["transportCount"], 1)
        self.assertEqual(effects["factTransportCount"], 1)
        self.assertEqual(effects["dispatchTransportCount"], 0)
