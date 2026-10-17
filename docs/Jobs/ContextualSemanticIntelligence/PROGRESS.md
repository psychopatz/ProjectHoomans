# Contextual Semantic Intelligence — progress

**Updated:** 2026-10-17. **Phase:** 1 — Wellbeing contextual reaction pilot. **Status:** Phase 1A Semantic Lab gate accepted; Phase 1B is the sole Next Chunk. Native SP/MP acceptance remains OPEN.

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

## Phase 1A verification evidence — accepted for the Semantic Lab gate

- Implementation revision: Project Hoomans `2a74683a` (`feat/semantic: ground unknown wellbeing responses`); PsychopatzCore remains pinned at `0212491d2af3597cceaa7353e62f01ef54adca44`; `/usr/bin/lua5.3` Lua 5.3.6; Python 3.12.3 in `tools/semantic_harness/.venv`. The detailed evidence is in [`PHASE1A_WELLBEING.md`](PHASE1A_WELLBEING.md).
- The existing production path was retained: `QUESTION_RECEIVED` -> local response -> `resolveQuestion` -> `resolveWellbeing` -> response catalog selection. No second reaction arbiter or gameplay action was introduced.
- Missing health evidence is normalized to selector-only `healthState="unknown"` in `conditionContext`; the routed situation remains source-faithful and omits unavailable health. A separate one-variant unknown pool avoids expanding the already bounded generated wellbeing pool beyond its 16-variant limit. Known healthy, injured, urgent-thirst, panic and stress precedence remains on the existing catalog path.
- The same utterance, `Are you okay?`, now produces the contextual response identifiers `semantic.question.wellbeing.default`, `.unknown`, `.injured`, `.thirst`, `.panic` and `.stress` for the corresponding real-worker states. Unknown state no longer makes the unsupported “I'm okay” claim; its EN/TL translation key is `UI_PNC_Conversation_Semantic_QuestionWellbeingUnknown`.
- `tools/semantic_harness/run_harness.sh --doctor --doctor-json`: **PASS**. `python3 -m unittest tools.semantic_harness.tests.test_wellbeing_projection -v`: **PASS 6/6**. `python3 -m unittest discover -s tools/semantic_harness/tests -v`: **PASS 56/56**. `tools/semantic_harness/run_harness.sh --test pnc_semantic`: **PASS 66/66**. CLI report: **PASS 66/66**, `conflicts=[]`, `audit_truncated=null`, 198 events. Empty conflicts are protocol/replay observations, not semantic proof.
- `pz-verify` reported no new Kahlua or i18n errors in the changed catalog/presentation files. Its existing whole-file token-size warning on the response catalog and two existing identity fallback strings in the local-response file remain outside this bounded chunk; no monolith refactor was started.
- No PBrainZ call, transport effect, tool call or gameplay side effect occurred in the real-worker matrix (`llmCalls=0`); the unknown routed health field remained absent. Native SP: **NOT TESTED**. Native MP: **NOT TESTED**. No controlled Project Zomboid UI/session/server evidence is promoted.

## Phase 1B verification evidence — accepted for the Semantic Lab gate

- The audit found no new behavior boundary requiring a reaction-selector hook. resolveWellbeing owns only the unsupported-state guard; stronger need/emotion evidence returns to the existing wellbeing catalog, and Catalog.Select owns condition matching plus explicit priority scoring. The detailed decision and graph/source evidence are in [PHASE1B_SELECTOR_AUDIT.md](PHASE1B_SELECTOR_AUDIT.md).
- Added one focused real-worker regression method covering unknown health with urgent thirst, panic, and simultaneous panic-plus-thirst. The existing catalog returned thirst, panic, and panic respectively; panic precedence remains explicit through the existing priority values. No production selector or arbiter was added.
- python3 -m unittest tools.semantic_harness.tests.test_wellbeing_projection -v: PASS 7/7. python3 -m unittest discover -s tools/semantic_harness/tests -q: PASS 57/57. tools/semantic_harness/run_harness.sh --test pnc_semantic: PASS 66/66. CLI report: PASS 66/66, 198 events, conflicts=[], audit_truncated=null; these are protocol/replay observations, not semantic proof.
- The existing identity, gift, task and social coverage remained green through the broader Semantic Lab suite. Every new regression turn used llmCalls=0, with no transport events, tool calls or gameplay effects. Native SP: NOT TESTED. Native MP: NOT TESTED.

## ONE current Next Chunk — Phase 2 bounded multi-turn wellbeing baseline

1. Start with one bounded persistent-worker case for "Are you okay?" -> "What's wrong?", and inspect the existing pending-request/topic/entity context before changing behavior.
2. Add only the narrowest deterministic follow-up resolution needed for a factually grounded response; preserve speaker/target context and do not activate tasks or obligations.
3. Assert before/after context, sequence, idempotence/preview behavior where available, zero PBrainZ calls and no unauthorized transport/tool effects. Preserve all Phase 1 and existing semantic coverage.
4. Keep native SP/MP explicitly open; do not expand to social, paraphrase or PBrainZ phases until the Phase 2 bounded gate is evidenced.

## Remaining roadmap

0B baseline characterization -> 1 wellbeing reactions -> 2 multi-turn -> 3 social -> 4 paraphrases -> 5 PBrainZ/groups -> 6 SP/MP + performance acceptance.

No new reaction arbiter or gameplay feature is claimed yet; code currently provides the truthful test foundation.
