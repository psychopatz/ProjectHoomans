"""Production-worker acceptance for the Phase 0A weather gate bridge."""

from __future__ import annotations

import unittest

from tools.semantic_harness.scenario import DEFAULT_SCENARIO, merge
from tools.semantic_harness.worker import LuaSemanticWorker


class ContextualWeatherGateTests(unittest.TestCase):
    def _turn(self, weather: str, language: str = "EN") -> dict:
        scenario = merge(
            DEFAULT_SCENARIO,
            {"world": {"weather": weather}, "runtime": {"language": language}},
        )
        with LuaSemanticWorker(scenario) as worker:
            return worker.input("is it raining")

    def test_real_worker_selects_true_false_and_unknown_gate_branches(self) -> None:
        expected = {
            "rain": ("PASS", "weather_rain_true", "raining"),
            "clear": ("FAIL", "weather_rain_false", "clear"),
            "unknown": ("UNKNOWN", "weather_rain_unknown", "unknown"),
        }
        for weather, (status, reason, node) in expected.items():
            with self.subTest(weather=weather):
                turn = self._turn(weather)
                observation = turn["observation"]
                flow = observation["flow"]

                self.assertEqual(observation["ir"]["pattern"], "pnc.question.weather")
                self.assertEqual(flow["flowId"], "weather_context")
                self.assertEqual(flow["fromNodeId"], "weather_gate")
                self.assertEqual(flow["toNodeId"], node)
                self.assertEqual(flow["gateStatus"], status)
                self.assertEqual(flow["gateReason"], reason)
                self.assertEqual(flow["status"], "retired")
                self.assertEqual(flow["activeAfter"], [])
                self.assertEqual(observation["sideEffects"]["actions"], [])
                self.assertEqual(observation["sideEffects"]["transport"], [])
                self.assertTrue(observation["sideEffects"]["none"])
                self.assertEqual(turn["transport"], [])
                self.assertEqual(turn["toolCalls"], [])
                self.assertEqual(
                    observation["response"]["sourceFlowID"],
                    "weather_context",
                )
                self.assertIn(
                    weather == "rain"
                    and "raining"
                    or weather == "clear"
                    and "clear"
                    or "confirm",
                    observation["response"]["text"],
                )

    def test_weather_flow_renders_real_tl_translation(self) -> None:
        turn = self._turn("rain", "TL")
        response = turn["observation"]["response"]
        self.assertEqual(response["translationKey"], "UI_PNC_Conversation_Semantic_FlowWeatherRaining")
        self.assertTrue(response["translated"])
        self.assertNotEqual(response["text"], response["fallback"])

    def test_weather_gate_preview_is_pure_and_exposes_gate(self) -> None:
        scenario = merge(
            DEFAULT_SCENARIO,
            {"world": {"weather": "unknown"}},
        )
        with LuaSemanticWorker(scenario) as worker:
            preview = worker.preview("is it raining")
            after_preview = worker.snapshot()
            repeated = worker.preview("is it raining")
            after_repeated_preview = worker.snapshot()

        flow = preview["observation"]["flow"]
        self.assertEqual(flow["gateStatus"], "UNKNOWN")
        self.assertEqual(flow["gateReason"], "weather_rain_unknown")
        self.assertEqual(flow["toNodeId"], "unknown")
        self.assertEqual(preview["messages"], [])
        self.assertEqual(preview["transport"], [])
        self.assertEqual(preview["toolCalls"], [])
        self.assertEqual(preview["contextBefore"], preview["contextAfter"])
        self.assertEqual(
            repeated["contextBefore"], repeated["contextAfter"]
        )
        self.assertEqual(
            after_preview["context"], after_repeated_preview["context"]
        )


if __name__ == "__main__":
    unittest.main()
