# Semantic Test Subsystem — current progress

**Status:** DOCUMENTED / IMPLEMENTATION NOT STARTED.
**Source audit reference:** local main HEAD `507fca06` on 2026-11-01, clean worktree at observation. Recheck current HEAD/status before execution; this is not a claim of up-to-date future repository state.

## Evidence
- 146 `tests/pnc_semantic*_smoke.lua` files, approximately 26,072 LOC; 146 use common test support; 115 call addPackagePaths; 145 include T.finish.
- Nine existing JSON fixture files split across Observatory and c0a.
- Existing production-backed LuaSemanticWorker and Semantic Lab Simulation/Observatory to reuse.
- No new test runs, GUI tests or native PZ testing performed for this documentation-only preparation.

## Phase status
P0–P7: NOT STARTED. Prior Observatory/other-job accepted work is reused, not reclassified as incomplete.

## Next Chunk — P0A
Inventory **all** semantic-related smoke, Python harness tests, fixtures and runners; verify runnable commands and current runtime baseline; produce a deduplicated coverage/ownership table, fixture-conversion classification and old-vs-new parity strategy. Prioritize local_response_questions, nlu, dialogue, identity collision, wellbeing and existing Observatory/C0A families. Do not delete tests or change production behavior during P0A.

## Remaining mandatory gap
Implement and accept every P1–P7 roadmap gate. The Next Chunk is only the starting point; proceed through the complete developer-side parent objective without additional user prompts, subject to genuine safety/technical blockers.
