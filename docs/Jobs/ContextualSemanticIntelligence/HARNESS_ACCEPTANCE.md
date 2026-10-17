# Semantic Lab — mandatory implementation acceptance

**Key requirement:** The existing `tools/semantic_harness/` is the primary *conversation behavior* test instrument. It must load and invoke actual Project Hoomans/PsychopatzCore production Lua. Small isolated Lua tests and JSON case files are supplementary, not substitutes. Real in-game SP/MP validation is still required for game-native edges.

## Prior source-verified limitations to address first

- `lua/worker/Conversation.lua` currently hard-codes `entry.snapshot.healthState = "healthy"` and `activeBehavior = "idle"`. It projects hunger/thirst/fatigue and stress/boredom/panic from `scenario.world` into NPC context. Support editable NPC state without breaking existing scenario defaults; confirm production expected shape.
- `runner.py` `run_case` only builds turn records and `ConflictLedger` checks duplicates/sequence/malformed records. An `ok` result and zero conflicts do **not** assert good dialogue or correct NPC facts. Add explicit assertions in `tools/semantic_harness/tests/` against worker results and messages.
- The worker models only a narrow production semantic dependency closure and mocks native UI/network; source inspection does not prove current runtime startup or full-game behavior.

## Mandatory loop for each behavior chunk

1. Inspect current HEAD, Core checkout revision and `tools/semantic_harness/README.md`; collect doctor result first.
2. Construct a minimal editable scenario with one change to an actual NPC state (healthy/injured, urgent thirst, relationship, activity, emotional urgency). Inspect `contextBefore`, IR and decision to prove projection reaches the actual `PNC.Semantics.DialogueInput.Submit` route.
3. Run one-turn input with no LLM. Assert `accepted`, expected IR intent/subject, the reaction/decision/response key and factual content, zero unwanted `toolCalls`/`transport`, and `llmCalls = 0`. Assert source module path present in `loadedModules`.
4. Run same input with changed context, proving an **appropriate behavioral difference**, not only arbitrary text randomization. Verify conditions and no facts invented.
5. Run multi-turn input in *one persistent worker session*. Assert `contextBefore`/`contextAfter`, follow-up resolution, correct addressee, stable sequence and no duplicate effect.
6. Run case replay with `--audit` or `--case`; treat non-empty conflicts and `audit_truncated` as failing evidence, and separately run semantic assertions (replay alone is not a language-correctness test).
7. Run focused Lua smoke tests and Semantic Lab unittest suite, then broader tests impacted by this change.
8. Validate real Project Zomboid SP/MP behavior for the relevant production slice; if unavailable, mark it not tested rather than promoting mock evidence.

## Commands — run from ProjectHoomans repository root

    tools/semantic_harness/run_harness.sh --doctor --doctor-json

    tools/semantic_harness/run_harness.sh --no-gui --jsonl --audit --input "Are you okay?"

    tools/semantic_harness/run_harness.sh --cli --jsonl --case tools/semantic_harness/scenarios/identity_exchange_case.json

    python3 -m unittest discover -s tools/semantic_harness/tests -v

    tools/semantic_harness/run_harness.sh --test pnc_semantic

    python3 tests/run_tests.py pnc_semantic --harness-report /tmp/contextual-semantic-suite.json

The input above is a **probe**, not a claimed passing expected answer. Supply a scenario via `--scenario` for each actual acceptance case. `PNC_HARNESS_LUA` and `PNC_HARNESS_CORE_REPOSITORY` select dependencies if not autodetected. Do not run concurrent agents against a single shared interactive worker process. Isolate worker sessions and output paths per agent.

## Test matrix and assertions

| Case | Real-worker assertion | No-go conditions |
| --- | --- | --- |
| Healthy + wellbeing query | Appropriate neutral/healthy grounded response using actual projected state | Treating absent health as healthy |
| Injured + same query | Injured response, no invented injury cause | Still projecting healthy; hidden mock path |
| Severe thirst + same query | Need disclosure from actual NPC projected need | World fixture mutated but NPC context unchanged |
| Unknown/partial state | Clarify/express uncertainty when evidence missing | Invented wound/need |
| Trusted vs distrustful | Same facts, guarded difference in tone or reaction | Invented relationship/category |
| "What's wrong?" follow-up | Refers to NPC's actual preceding disclosure | Unrelated branch or overwritten speaker |
| "Can I help?" follow-up | Dialogue continuity, no automatic task | Unauthorized job or inventory transfer |
| Preview twice, process once | Preview leaves sequence/effects unchanged | Duplicate event or premature commitment completion |
| Two concurrent NPCs (later phase) | Distinct speaker/recipient contexts | Context bleed |
| Fuzzy input/commands | No extra command from unsupported correction | Task side effect |
| Provider unavailable | Deterministic offline answer | Network/provider dependency |

Programmatic tests should inspect returned `result.ir`, `result.decision`, `messages[].payload`, `contextBefore`, `contextAfter`, `transport`, `toolCalls`, `llmCalls` and `loadedModules`; where a meaningful field is missing, minimally extend harness output to expose *production truth*, not a fabricated expected value.

## Acceptance record format

Every chunk's `PROGRESS.md` evidence entry must include exact Project Hoomans and Core SHAs, command, environment/Lua version, result (pass/fail/skipped), module manifest validation, scenario/utterance identifiers, changed expected behavior, actual output/diagnostics, and separately `native-SP`/`native-MP` status. No test count, CI status or performance value may be invented. Scenario JSON is legitimate fixture input; JSON-only fixtures without production Lua execution and explicit semantic assertions never close a gate.
