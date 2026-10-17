# Contextual Semantic Intelligence — progress

**Updated:** 2026-10-17. **Phase:** 0 — Semantic Lab correctness baseline. **Status:** Phase 0B baseline-matrix gate accepted; Phase 1A is the sole Next Chunk. Native SP/MP acceptance remains OPEN.

## Revision evidence

- Audited main: ProjectHoomans `c96cadda1570f59810552f9d3fc55d5c957ba670`; psychopatzCore `efac85a182c86fdb07e7da7ccd693e1a6e66ccc6`; PBrainZ `43cc879e673d8d0494d7e77b4ade28fd20a6d4c4`.
- Planning base: `7422dba0d4ea729d65af4284cca87c4af8d7693b`; initial implementation was `d948b9ee`, and the Phase 0A verification repair is `bddeaf3c`.
- The earlier source-only audit recorded that no local checkout or complete dependency closure was available at authoring time. That historical limitation is now cleared for Semantic Lab verification; native Project Zomboid SP/MP and hosted CI remain unexecuted.
- Static review established actual production context is created in `PNC_SemanticDialogueInput_ContextProjection.Build`, and the retained router context includes `dialogueSituation`.

## Implemented in branch; verified by the Phase 0A gate

- `tools/semantic_harness/scenario.py`: default NPC health/activity fields preserve legacy semantics; validates state shapes; explicit null/empty state can represent unknown.
- `tools/semantic_harness/lua/worker/Conversation.lua`: editable NPC health/activity/needs/conditionStats fed into existing `npcState` and snapshot fields with legacy `scenario.world` fallback only when a dedicated NPC state table is absent. Exposes the **production router's** `routedSituation` on each turn; no new fake semantic interpreter.
- `tools/semantic_harness/tests/test_wellbeing_projection.py`: actual `LuaSemanticWorker` checks for healthy/injured/thirst/panic/unknown, legacy world mock compatibility, output safety, multi-turn replay and editable state persistence. The real-worker suite now passes; the exact evidence is recorded below.
- Core NLU, Project Hoomans response catalog, gameplay authority and PBrainZ are unchanged.

## Phase 0A verification evidence — accepted for the Semantic Lab gate

- Revisions: Project Hoomans `bddeaf3c` (`feat/contextual-semantic-harness-phase0a`), PsychopatzCore `0212491d2af3597cceaa7353e62f01ef54adca44`; `/usr/bin/lua5.3` Lua 5.3.6; Python 3.12.3 in `tools/semantic_harness/.venv`.
- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`: **PASS**. The real worker completed READY/PING/CAPABILITIES; Core repository and Lua executable were discovered; worker syntax parsed.
- Production manifest: **PASS**. The worker loaded the real PsychopatzCore semantic module, Project Hoomans catalog/policy/input entry, translation, inventory, identity, authority and network modules. The turn trace included `PNC/Semantics/PNC_SemanticDialogueInput.lua` and `PNC/Semantics/PNC_SemanticDialoguePolicy.lua`; `routedSituation` was read from the production router context after `Submit`.
- `python3 -m unittest tools.semantic_harness.tests.test_wellbeing_projection -v`: **PASS 6/6**. This includes healthy, injured, severe-thirst, panic, unknown/empty state, legacy world fallback, multi-turn replay, shape validation and nullable context snapshots.
- `python3 -m unittest discover -s tools/semantic_harness/tests -v`: **PASS 53/53**.
- `tools/semantic_harness/run_harness.sh --test pnc_semantic`: **PASS 66/66** in 1.94s; `python3 tests/run_tests.py pnc_semantic --harness-report /tmp/contextual-semantic-suite-phase0a.json`: **PASS 66/66**, report conflicts empty and no audit truncation.
- Real-worker baseline identifiers and observed outputs, all with utterance `wellbeing_okay: "Are you okay?"`, IR `QUESTION/WELLBEING`, pattern `pnc.question.wellbeing_okay`, confidence `0.99`, deterministic `QUESTION_RECEIVED`, `llmCalls=0`, empty `transport` and `toolCalls`, one NPC message, and no conflict:
  - `npc_state_healthy`: routed `healthState=healthy`, `activity.id=idle`, known needs `highest=thirst` at `urgency=normal`; response `semantic.question.wellbeing.default`, “I'm okay. How about you?”.
  - `npc_state_injured`: routed `healthState=injured`, `activity.id=treatment`, `busy=true`; response `semantic.question.wellbeing.injured`, “A little banged up, but I'll manage.”
  - `npc_state_severe_thirst`: routed `healthState=healthy`, `activity.id=fishing`, `needs.highest=thirst`, `urgency=emergency`; response `semantic.question.wellbeing.thirst`, requesting water.
  - `npc_state_unknown`: explicit null health/activity and empty needs/conditions remained absent/unknown in routed situation (`activity.id=unknown`, no `healthState`, no highest need/emotion); the existing default response still says “I'm okay”, a Phase 1 reaction-grounding limitation, not a projection pass.
  - `relationship_trusted` and `relationship_distrustful`: routed social facts remained distinct (`trusted`/friendly/0.9 familiarity versus `hostile`/withdrawn/0.1); the wellbeing response stayed neutral in Phase 0 because relationship reaction changes are later roadmap work.
  - `injured_follow_up`: in one persistent worker, `"What's wrong?"` advanced the real state to sequence 2 and returned deterministic `ASK_CLARIFICATION` with no action/provider call; this records the current Phase 2 continuity gap without claiming follow-up correctness.
- The repair preserves JSON object shape for first-turn `contextBefore` (`{"dialogue": null, "state": null}`) through the real worker protocol; it does not alter IR, policy, response catalog, gameplay authority, transport or PBrainZ behavior. Normal known needs retain the production weighted `highest` field while remaining `normal`, rather than being erased from the projection.
- Native SP: **NOT TESTED**. A Project Zomboid process was present, but no controlled in-game scenario was exercised and no game UI evidence is being promoted from the Semantic Lab mocks.
- Native MP: **NOT TESTED**. No controlled multiplayer session, server admission, lease validation or authoritative task result was exercised; harness `transport=[]` is not multiplayer evidence.

Phase 0A is accepted only for its documented Semantic Lab correctness baseline. The remaining native-game limitations and the Phase 1/2 semantic limitations stay open.

## Phase 0B verification evidence — accepted for the reviewed baseline gate

- `tools/semantic_harness/tests/test_contextual_baseline_matrix.py` at Project Hoomans `35c0e741` is the bounded reviewed matrix; the full observations are in `docs/Jobs/ContextualSemanticIntelligence/BASELINE_MATRIX.md`.
- `python3 -m unittest tools.semantic_harness.tests.test_contextual_baseline_matrix -v`: **PASS 3/3** in 2.30s on the final verification run.
- `tools/semantic_harness/run_harness.sh --cli --jsonl --case tools/semantic_harness/scenarios/identity_exchange_case.json`: **PASS** (`ok=true`), 2/2 turns accepted, `conflicts=[]`, no audit truncation; deterministic identity claim routing produced the existing `SemanticIdentityRequest`/`SemanticIdentityResult` boundary and bounded relationship adjustment.
- `python3 -m unittest discover -s tools/semantic_harness/tests -v`: **PASS 56/56** in 20.51s.
- `python3 -m unittest tools.semantic_harness.tests.test_wellbeing_projection -v`: **PASS 6/6** in 2.66s; `tools/semantic_harness/run_harness.sh --test pnc_semantic`: **PASS 66/66** in 1.92s.
- The matrix records greeting, injured wellbeing, fishing activity, time, identity exchange and injured wellbeing follow-up. All assertions read production IR/decision/context and traces from the real worker; deterministic cases used `llmCalls=0` and no unauthorized transport/tool effects. The wellbeing follow-up remains the observed `ASK_CLARIFICATION` continuity gap and was not repaired in Phase 0B.
- No reaction selector, catalog wording or gameplay behavior was changed in Phase 0B. The identity transport is the harness single-player boundary and is not native multiplayer evidence.
- Native SP: **NOT TESTED**. Native MP: **NOT TESTED**. No controlled Project Zomboid UI/session/server acceptance is being promoted from these mocks.

## ONE current Next Chunk — Phase 1A wellbeing contextual reaction pilot

1. Trace the existing `QUESTION/WELLBEING` catalog and policy conditions against the already reviewed healthy, injured, severe-thirst, panic/stressed and explicitly unknown states.
2. Use the existing production context and response paths first; add the narrowest behavior-preserving hook only if the real-worker evidence shows a missing contextual reaction. Do not invent facts for unknown state.
3. Add focused real-worker assertions for recognized same-utterance reaction differences, with zero PBrainZ calls and no gameplay side effects. Preserve the legacy world fixture and existing 66-test semantic coverage.
4. Keep native SP/MP explicitly open; do not begin multi-turn, social, paraphrase or PBrainZ phases until the Phase 1A gate is evidenced.

## Remaining roadmap

0B baseline characterization -> 1 wellbeing reactions -> 2 multi-turn -> 3 social -> 4 paraphrases -> 5 PBrainZ/groups -> 6 SP/MP + performance acceptance.

No new reaction arbiter or gameplay feature is claimed yet; code currently provides the truthful test foundation.
