# Semantic Observatory & Dialogue Quality Harness — current progress

**Status: READY FOR USER LIVE TEST.** The developer-side parent goal is complete on the existing `main` branch. Native Project Zomboid SP/MP verification and Workshop publication remain explicitly user-owned and were not run.

## Audited revisions

- ProjectHoomans: `3507e4b24a34d900d6e579356ef54c50f331d399` (`main` = `origin/main`).
- PsychopatzCore: `cf28189c57f7810f31d25c46c11eb88080f47baa` (`main` = `origin/main`).
- No source save, watched-media staging, native game launch, or Workshop operation was performed.

## Phase reconciliation

| Phase | State | Current evidence |
| --- | --- | --- |
| P0 — Baseline/contracts | **COMPLETE** | Production source→registration→selection→translation/final-response contracts, bounded queries, startup/no-write boundaries and baselines are established. |
| P1 — Runtime catalog | **COMPLETE** | Real Lua catalog/detail paging, conditions, priority, plans, revisions, translation/source metadata and CodeBuilder lineage are bounded and verified; genuinely unproven provenance remains `UNKNOWN`. |
| P2 — Explain/provenance | **COMPLETE** | Production matcher/scorer/history powers explain and coverage; read-only explain does not consume history; response-turn inspection now keeps semantic identity, rendered key, style and phrase identity separate. |
| P3 — Human surfaces | **COMPLETE** | Simulation is the only execution/context/regression workbench. Studio defaults to `Explore | Dialogue Content | Review`; structural tools are behind `Developer Tools…`; no Studio Test Lab or Coverage runner remains. |
| P4 — Grounded scenarios | **COMPLETE** | EN/TL matrices, grounded dialogue, authority/no-effect cases, companion Follow/Wait and P4A player-owned Leave Group production rehydration all pass. |
| P5 — Agent CLI | **COMPLETE** | Bounded catalog/detail/explain/turn/matrix/coverage/lineage/translation/proposal/compare JSON/JSONL paths and stale/unknown/error/scale checks pass through shared services. |
| P6 — Quality + phrase registry | **COMPLETE** | Canonical greeting promotion is preserved; the post-style Dialogue Content Registry and locked player-choice editing slice are accepted below. |
| P7 — Integrated acceptance | **READY FOR USER LIVE TEST** | Broad Python, native Lua, Tk/Xvfb, CodeBuilder, Kahlua and diff checks are green. Native SP/MP remains user-owned. |

## Accepted P4A Leave Group slice

`test_production_leave_group_p4a.py` passes **4/4** through the real production worker route and a disposable synthetic save: player-owned faction rehydration, mutation-free warning, confirmation through actual `PNC.ColonistDeparture`, departure/refugee transition, relationship and journal evidence, EN/TL presentation, unowned/other-owner rejection, and unchanged source-save bytes.

## Accepted P6 canonical greeting

The existing behavior-equivalent promotion remains authoritative:

- semantic variant: `semantic.flow.greeting.opening.default`;
- owner: `PNC_SemanticDialogueResponseCatalog_FlowGreeting.lua`;
- EN: `Hey there. Good to see you.`;
- TL: `Uy, mabuti at nakita kita.`;
- `when`, priority, two-turn plan, selected ID, authority, actions and transport remain unchanged in isolated EN/TL real-Lua replay.

## Accepted P6B Dialogue Content Registry

Canonical source: [semantic_dialogue_content.json](/home/psychopatz/Zomboid/Workshop/ProjectHoomans/tools/semantic_harness/codebuilder/sources/semantic_dialogue_content.json).

- CodeBuilder emits schema `pnc.semantic_dialogue_content.v1`, fingerprint `a88fc7a8413fb46853a21f1ba2e52685a79ca23c4f7fee68c65919c2a219ea41`, one greeting family, four styles, 12 paired EN/TL phrases and one `What's up` player choice.
- ResponseCatalog remains semantic/context ownership; SpeechRealization remains style ownership; the bounded phrase layer runs after both and exposes semantic variant, style and phrase ID independently.
- EN/TL translation artifacts contain ordinary string values only; phrase arrays are not passed to the translation API. The manifest includes both generated language files.
- Real Lua proves deterministic immediate-repeat avoidance, worker isolation/reset behavior, EN/TL phrase resolution, unchanged plan/action/transport/effect/authority output and no phrase history in save/ModData.
- Studio Dialogue Content edits only verified phrase text and player-facing landing/choice wording. `when`, priority, plan, action, route, hub ID, canonical concept, eligibility and authority remain locked; the default player label remains stable.

## Surface consolidation

- Simulation owns transcript/Response Channel, Open/Preview/Send, fixture/save-backed context, selection explanation, authority/effects, comparisons/regressions, graphs, world inspection and debug.
- Studio Explore unifies catalog, interaction, flow and verified source discovery without a scenario runner or context selector.
- Studio Review shows human-readable current/proposed EN/TL, source/fingerprint state, invariants, isolated real-Lua parity and explicit review controls.
- Flow Editor, raw canonical source editing, Block Contracts, Interaction Composer and Legacy Build Workflow are hidden behind `Developer Tools…`. Build Workflow is retained as a legacy retirement candidate because the audit found unique UI wiring; shared CodeBuilder/authoring services and CLI callers remain intact.
- The compact save-backed Simulation layout is verified at 1080×700 and 1280×800, while legacy diagnostic/fixture sash persistence remains compatible.

## Acceptance evidence

- `tools/semantic_harness/.venv/bin/python -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py' -f` — **624 tests OK, 2 expected skips**.
- `python3 tests/run_tests.py --jobs 4` — **889/889 native Lua tests PASS**.
- Dialogue Content CodeBuilder regeneration is idempotent; generated registry, EN/TL content files and manifest hashes were unchanged on a second build.
- `compileall` and `git diff --check` pass. PZ Verify Kahlua checks report zero errors for the changed production/worker/generated Lua files.
- Codebase-memory coverage returned no recorded gaps for the material implementation/test paths; dirty/untracked paths were also read directly as required.
- The C7G wall-clock test keeps a sub-300ms full-suite mean budget plus a 1s p95 guard because disposable-worker JSONL timing varies under suite scheduling; it does not alter runtime behavior or authority.

## Remaining user-owned gate

Run the native Project Zomboid SP (and MP where applicable) checklist: greeting/phrase rotation, EN/TL display, farewell, Follow/Wait/camp effects, hidden-name privacy, Leave Group authority and no UI/save/performance regression. No Workshop republish is required to close the developer-side goal.
