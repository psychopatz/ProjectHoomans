# Harness acceptance — real production Lua, GUI and safety

## Golden rule

Accept a behavior only when Semantic Lab's *existing* LuaSemanticWorker loads real Project Hoomans/PsychopatzCore modules and the observation records the actual selected parser/IR candidate, flow before/after, gate decision, translated NPC response, and side effects. JSON schema validation, generated fixture counts, fake Python interpreter output or an empty conflict ledger alone are **not** acceptance.

## Required diagnostic fields and reproducible evidence

Capture base Git SHA, worker/Core source or manifest identity, language, scenario, input turns, NPC/player/speaker/addressee IDs, world/quest/personality facts and revisions, selected IR/intent, candidate arbitration, flow ID/from-to nodes, gate outcomes with reasons, responsePool/template/rendered text, pending references/memory provenance, request/result IDs, server-authoritative effects/transport and LLM calls. Preview must be idempotent and show zero action/quest mutations. Actual Submit and replay must distinguish admitted and rejected actions.

## Matrix

| Case | Expected proof |
| --- | --- |
| Baseline identity/wellbeing | "who are you" -> "are you okay" -> "im fine thanks" -> valid name preserves context; no false identity accusation/evasion, no extra commands |
| World fact gate | Same input with rain, clear and UNKNOWN weather changes eligible branch only when condition warrants; no fabricated weather claim |
| Time gate | In-game morning/evening and midnight wrap use actual world clock, not user's real clock; server commit rechecks stale client preview |
| NPC factual disclosure | Injured/thirsty/unknown state yields factual or qualified answer; no invented injury cause |
| Reference resolution | "I can get you bandages" -> "I'll bring some" resolves relevant item only with source; ambiguous "some" asks for clarification |
| Interruption/resume | Interrupted identity or quest offer can be resumed by the same pair, not accidentally by a different NPC |
| Memory | Significant acknowledged promise or quest status is available after conversation boundary; older nonexistent or expired memory is not hallucinated |
| Social and personality | Same safe request changes tone/willingness with approved profile, never leaks other NPC's knowledge or bypasses mandatory quest gate |
| Locked quest | Hidden/disabled/unknown prerequisites are also enforced for typed NLP request; no AcceptQuest or reward side effects |
| Accept and progress | Offer -> authorized accept -> actual delivery/verified event -> READY -> turn-in; progress is not inferred from player speech |
| Duplicate and multiplayer | Repeated AcceptQuest/SubmitTurnIn/events, reconnect, second player or second NPC cannot duplicate rewards or swap scope |
| Editor graph | Actual add/delete/rename/link/drag, validation errors, stable save/load/undo; no dangling references or silent data loss |
| Editor source | Supported code-graph round-trip, unsupported Lua safe refusal, exact source diff/restart reload via new worker process |
| Language and optional provider | EN and TL selected actual render/fallback; PBrainZ disabled deterministic path remains; enabled provider cannot alter quest authority |
| Performance | No idle O(all NPCs × all flows/quests) scan; bounded cached observation, event-driven objective updates, state size and worker latency recorded |

## Recommended verification commands (only run when source/toolchain exists)

- tools/semantic_harness/run_harness.sh --doctor --doctor-json
- python3 -m unittest tools.semantic_harness.tests.test_flow_editor -v
- python3 -m unittest tools.semantic_harness.tests.test_semantic_dialogue_flows -v
- python3 -m unittest discover -s tools/semantic_harness/tests -v
- tools/semantic_harness/run_harness.sh --test pnc_semantic
- Targeted new actual-Lua scenario/quest tests as implemented; B42 Kahlua syntax validation where Lua changes.

The commands above are planned regression gates, NOT newly run or passing tests. GUI button/mouse click-through must be separately recorded if available; otherwise mark PENDING, never PASS. Run a bounded real developer-side scenario for each new subsystem, not an explosion of near-duplicate synthetic JSON cases.

## Authority and human handoff

The Lua worker mocks engine/net/relationship edges, so its test evidence is **production semantic-module behavior under mocked boundaries**, not native PZ SP/MP authority. A later real-game checklist belongs to the user (SP/MP, multiple NPCs, saves/reloads, translation, performance, installed Core/Hoomans version). Codex must prepare a handoff and stop, not launch PZ or request Steam Workshop upload. Never use a client-side simulated quest result as proof that multiplayer admission worked.
