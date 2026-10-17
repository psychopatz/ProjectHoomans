# Contextual Dialogue & Quest Framework — current state

**Updated:** 2026-10-18
**Baseline inspected:** ProjectHoomans `main` at `a3eb2e4db553f9c03b7f66a6ff6717878e1668e0`
**Implementation branch:** `codex/contextual-dialogue-quest-framework-0a`
**Phase:** 1 — Graph editing foundations (selected; not implemented)
**Status:** Phase 0 / 0A ACCEPTED by developer evidence; native PZ acceptance remains user-owned.
**Last implementation commit:** `1a754dc8` (`feat(semantic): bridge weather gates into dialogue flows`)
**Next Chunk:** 1A — Extend the existing Semantic Lab `flow_editor.py` with bounded node CRUD and structural error inspection.

## Accepted foundation

- Semantic Lab loads the real Project Hoomans/PsychopatzCore Lua route through its persistent worker; the worker exposes IR, candidates, response, flow state, translation, and side effects.
- Production `ConversationRules` already owned reusable condition handlers. 0A added `Rules.EvaluateGateStatus` with compatibility-preserving PASS/FAIL/UNKNOWN semantics and a pure `pnc:weather` handler; no second parser or Python evaluator was added.
- Production semantic flow registry/kernel now validate a bounded node gate and route `onPass`/`onFail`/`onUnknown` through that existing evaluator.
- The new response-only `weather_context` flow uses the authoritative/read-only world snapshot: rain selects `raining`, clear selects `clear`, and missing weather selects `unknown`. Terminal branches do not create or interrupt flow sessions.
- EN and TL response catalog entries are checked-in under the existing translation shard and presentation-key map.

## 0A evidence

- Real worker input `is it raining` produced, for `world.weather=rain|clear|unknown`, respectively: `weather_context/weather_gate -> raining|clear|unknown`, gate `PASS/weather_rain_true`, `FAIL/weather_rain_false`, and `UNKNOWN/weather_rain_unknown`, with the corresponding rendered response.
- Every branch reported `status=retired`, no active flow after the turn, zero tool calls, zero transport records, zero action side effects, and no LLM calls. TL rain also rendered `UI_PNC_Conversation_Semantic_FlowWeatherRaining` with a translated value.
- Preview of the unknown branch was repeated and remained pure: no messages, transport, tool calls, or context transition; the worker observation still exposed the gate status/reason and selected node.
- `python3 -m unittest discover -s tools/semantic_harness/tests -v`: **108 OK**.
- `python3 tests/run_tests.py pnc_conversation_smoke pnc_semantic_dialogue_flow_smoke pnc_semantic_situation_smoke pnc_semantic_world_context_smoke pnc_semantic_local_response_questions_smoke`: **PASS 5/5**.
- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`: **ok**, including worker `READY/PING/CAPABILITIES`.
- `pz-verify` Kahlua checks for all changed production Lua files: **clean**; translation JSON and `git diff --check`: **clean**.
- The unrelated pre-existing `pnc_semantic_local_route_smoke` greeting-count failure was reproduced on untouched `main` `a3eb2e4d`; it is not attributed to 0A. The harness-only `tools/semantic_harness/lua/worker/RuntimeEnvironment.lua` retains its pre-existing `io.open` Kahlua warning.

## Remaining unaccepted work

- Graph CRUD/drag/link, undo/redo, synchronized code editing, and durable source persistence remain unimplemented.
- Cross-session contextual memory/commitments, authoritative quest lifecycle, personality/quest integration, performance bounds, GUI click-through, and native PZ SP/MP acceptance remain open.
- No Project Zomboid process, MP server, Steam Workshop upload, or native game acceptance was run.

## EXACT Next Chunk 1A

Extend the existing `tools/semantic_harness/flow_editor.py` and its current Lua registry worker contract with bounded add/rename/delete/duplicate/connect/disconnect operations, undo/redo, preserved layout, and structural error inspection. Prove one human/agent-created valid branch through the real Lua registry and reject a broken graph; do not create a second flow engine or JSON-only acceptance path. After 1A, update this file and `ROADMAP.md` with exact evidence and select precisely one next chunk.

## Git/publication note

The planning documentation came from PR #4 branch `docs/contextual-dialogue-quest-framework-20261018` (`737e1c19`). This implementation branch contains that documentation plus the 0A commit above. Workshop publication and native game testing remain user-owned.
