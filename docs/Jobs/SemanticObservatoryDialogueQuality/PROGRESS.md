# Semantic Observatory & Dialogue Quality Harness — current progress

**Status:** PLANNED — P0 baseline not yet implemented. **Parent goal remains NOT COMPLETE.**
**Revision audited:** ProjectHoomans main 0e2d5a23a36badef3a61d35c4a6cdc2d1336f017 (2026-10-26). At doc creation, origin/main and local main matched after explicit fetch; original working tree was clean. Reverify before implementation.

## Accepted foundation (not acceptance of this new goal)

- Existing production Core+Hoomans semantic worker, FlowEditor flow catalog, CodeBuilder approved writer, Studio Interaction Explorer/Flow graph, Conversation Inspector and headless --jsonl case replay are available in source.
- Existing Lua ResponseCatalog provides registered conditional variants, priority/specificity selection and bounded no-immediate-repeat history. Existing FlowEditor responsePoolCatalog enumerates pool ID/count only.
- Previous focused audit on the same HEAD: 23/23 Python tests passed via repository Python 3.12 virtual environment (Conversation Inspector, runtime graph, What's up, CodeBuilder consolidation); this is prior-run evidence, **not** fresh P0 or GUI acceptance. Shell-default Python 3.14 missing _tkinter is an environment limitation, not a semantic defect.
- Existing ContextualDialogueQuestFramework developer-side authoring work and SemanticInteractionLifecycle developer-side repairs are preserved as predecessors; their native game acceptance is independent and user-owned.

## Current gap

No accurate, bounded per-variant runtime catalog + source provenance; no production-selector decision explanations; no common human/agent quality coverage/compare report; no verified isolated LLM-generated variant proposal workflow. Full P0–P7 remains mandatory.

## Current phase: P0 — baseline and contracts

**Exact Next Chunk (P0A):** On the actual current checkout, inspect the worker FLOW_CATALOG and response selection/registration/realization/translation seams, identify canonical owner for (1) greeting opening, (2) wellbeing response, (3) companion FOLLOW response, and record a **real worker** baseline trace for representative EN/TL, allowed/denied contexts. Benchmark startup, catalog payload and targeted query/replay. Draft the smallest schema-versioned, read-only pool detail and explanation contract using the existing worker request queue. Prove preview/explain cannot mutate selection history, commands, Knowledge, NPC state, save files or watched media. Do not implement a new editor or rewrite flows.

**Immediate acceptance:** exact HEAD/Core SHA, commands and actual observed worker outputs for source→registered pool→selection→translation→final response/effects; documented side-effect boundary and baseline timings; focused existing tests reported honestly. If any prerequisite differs, update AUDIT/ARCHITECTURE and PROGRESS based on current code.

**After P0A:** continue P0 gate and then P1–P7 without waiting for another /goal. The roadmap's complete parent outcome is the only developer-side completion boundary.

## External/user-only boundary

Native PZ singleplayer/multiplayer acceptance remains user-owned after all code/harness/GUI/CLI/variant gates pass. No Workshop publication, native PZ launch or source-save edits are authorized by this goal. Do not claim READY FOR USER LIVE TEST while mandatory developer phases remain.
