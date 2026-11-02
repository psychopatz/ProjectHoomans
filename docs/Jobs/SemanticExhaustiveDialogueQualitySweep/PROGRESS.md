# Semantic Exhaustive Dialogue Quality Sweep — current progress

**Parent goal status: IN PROGRESS.**

## Current repository baseline

- ProjectHoomans local main: 3b597b97273f91d819127c76f3cd8f29de110719 before this documentation commit.
- Worktree was clean at audit start.
- After explicit fetch, local main was **17 commits ahead of origin/main, 0 behind**.
- Preserve the existing unpublished local history; do not rewrite/sync it destructively.
- No native Project Zomboid, source-save mutation or Workshop operation occurred during planning.

## Phase state

| Phase | State | Current evidence |
| --- | --- | --- |
| P0 — Source audit / contract freeze | **COMPLETE (planning)** | Current Test Subsystem, Observatory, matrix limits, dimension catalogs and trace fields audited at baseline HEAD; gaps recorded in AUDIT.md. |
| P1 — Evidence + dimension inventory | **NOT STARTED** | No new sweep-specific evidence schema/service exists yet. |
| P2 — Buckets + planner | **NOT STARTED** | Existing generic matrix expansion is not yet a broad coverage planner. |
| P3 — Batch/resume | **NOT STARTED** | No large sweep manifest/resume system yet. |
| P4 — Reachability/provenance frontier | **NOT STARTED** | Existing coverage helpers are bounded/manual; no sweep frontier. |
| P5 — Quality flags/clusters | **NOT STARTED** | No dedicated dialogue-quality analyzer/cluster report. |
| P6 — CLI/review/UI | **NOT STARTED** | No sweep CLI workflow or Simulation Quality Sweep surface. |
| P7 — Integrated acceptance | **NOT STARTED** | Requires P1–P6. |

## Preserved accepted foundations

Do not regress or rebuild:

- completed docs/Jobs/SemanticTestSubsystem/ architecture and fixture runner;
- completed docs/Jobs/SemanticObservatoryDialogueQuality/ production observability/source/Simulation contracts;
- LuaSemanticWorker as execution authority;
- existing Conversation Inspector projections;
- existing Simulation control/persona catalogs;
- existing CodeBuilder/Dialogue Content canonical source ownership;
- existing GUI isolation and Simulation-vs-Studio ownership rules.

## Immediate Next Chunk — P1A/P1B foundation

Implement the smallest coherent foundation that proves the future sweeper can be production-backed:

1. define pnc.semantic-dialogue-quality-evidence.v1, or reconcile the name with existing schema conventions, for a compact per-rendered-sentence evidence row;
2. build it by joining an already executed real-worker turn through current Observatory/Conversation Inspector data—do not reimplement selection;
3. include deterministic case identity, changed parameter vector, final text, semantic template/variant, realization family/variant, phrase/translation identity, relevant persona/relationship/bond summary, selection/source fingerprints and bounded authority/effect summary;
4. expose a lazy case/turn handle for full inspector replay rather than embedding the full trace;
5. add production-backed dimension inventory extraction from simulation_control_catalog() / persona_catalog() with type/options/path/source/prerequisite metadata;
6. prove at least needs, personality, traits, relationship/bond/identity trust and authority controls are discoverable or explicitly diagnosed;
7. add focused tests for deterministic row output, boundedness, UNKNOWN provenance, read-only control rejection and prerequisite handling;
8. run representative real-worker integration and record exact results here.

Do **not** begin the GUI before the machine-readable evidence/dimension contracts are accepted.

## Remaining mandatory gap after Next Chunk

P2–P7 remain mandatory. After P1 acceptance the agent must continue automatically into semantic buckets/planning, batch/resume, reachability, quality flags/clustering, CLI/review/Simulation UI and integrated performance/regression acceptance.

## Stop rules

Do not report the parent goal complete because:

- P1 passes;
- one 64-case batch runs;
- one bad sentence such as family is detected;
- a quality report is generated;
- CLI works before GUI;
- GUI works before performance/regression gates.

Stop only at complete developer-side acceptance, a genuine blocker after all safe independent work, or an explicitly user-owned native gate after all implementation work is done.
