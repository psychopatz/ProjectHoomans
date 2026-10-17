# Contextual Semantic Intelligence — progress

**Updated:** 2026-10-17. **Phase:** 0 — Semantic Lab correctness baseline. **Status:** 0A code proposed/committed on feature branch; **runtime acceptance remains OPEN**.

## Revision evidence

- Audited main: ProjectHoomans `c96cadda1570f59810552f9d3fc55d5c957ba670`; psychopatzCore `efac85a182c86fdb07e7da7ccd693e1a6e66ccc6`; PBrainZ `43cc879e673d8d0494d7e77b4ade28fd20a6d4c4`.
- Planning base: `7422dba0d4ea729d65af4284cca87c4af8d7693b` from job documentation branch. See feature branch commit history for implementation SHA.
- No local repository checkout and no complete Semantics production Lua dependencies were available in the authoring sandbox. Lua Semantic Lab, Project Zomboid SP/MP, and hosted CI **have not been executed** for this change. These gates are not passed.
- Static review established actual production context is created in `PNC_SemanticDialogueInput_ContextProjection.Build`, and the retained router context includes `dialogueSituation`.

## Implemented in branch; not yet accepted

- `tools/semantic_harness/scenario.py`: default NPC health/activity fields preserve legacy semantics; validates state shapes; explicit null/empty state can represent unknown.
- `tools/semantic_harness/lua/worker/Conversation.lua`: editable NPC health/activity/needs/conditionStats fed into existing `npcState` and snapshot fields with legacy `scenario.world` fallback only when a dedicated NPC state table is absent. Exposes the **production router's** `routedSituation` on each turn; no new fake semantic interpreter.
- `tools/semantic_harness/tests/test_wellbeing_projection.py`: new actual `LuaSemanticWorker` checks for healthy/injured/thirst/panic/unknown, legacy world mock compatibility, output safety, multi-turn replay and editable state persistence. The tests have not been executed; failures must be repaired against real behavior, not bypassed or marked passed.
- Core NLU, Project Hoomans response catalog, gameplay authority and PBrainZ are unchanged.

## ONE current Next Chunk — Phase 0A verification/repair

1. Safely integrate/rebase this feature branch when job docs reach target checkout; first check local changes and overlapping agents.
2. Run `tools/semantic_harness/run_harness.sh --doctor --doctor-json`. Check Lua executable and Core repo availability.
3. Run `python3 -m unittest tools.semantic_harness.tests.test_wellbeing_projection -v`, `python3 -m unittest discover -s tools/semantic_harness/tests -v`, and `tools/semantic_harness/run_harness.sh --test pnc_semantic`. Inspect actual `routedSituation`, IR, response, context and no-action traces. Fix any real-worker or test-contract errors, including false projections.
4. Collect reproducible baseline outputs for healthy, injured, urgent need and unknown NPC, plus two-turn dialogue. Record exact SHAs, Lua version, command and result in this file. Verify legacy default scenarios remain unchanged.
5. Mark Phase 0A accepted only when real production-worker behavior assertions and semantic regression tests pass; then set Phase 0B as the sole Next Chunk.

## Remaining roadmap

0B baseline characterization -> 1 wellbeing reactions -> 2 multi-turn -> 3 social -> 4 paraphrases -> 5 PBrainZ/groups -> 6 SP/MP + performance acceptance.

No new reaction arbiter or gameplay feature is claimed yet; code currently provides the truthful test foundation.
