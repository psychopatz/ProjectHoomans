# Semantic Harness Architecture Audit

**Date:** 2026-10-21  
**Repository:** `psychopatz/ProjectHoomans`  
**Branch:** `main`  
**Audit scope:** `tools/semantic_harness`, with the former `tools/semantic_compiler` surface and the existing Lua worker boundary
**Baseline:** `8c6a604956c641e83854a8448b7962c950a1efa6`
**Current-state note:** This document records the pre-consolidation architecture and its historical slice notes. The 2026-10-23 cleanup supersedes its compatibility-facade recommendations: the old package and forwarding modules are removed, and the concrete CodeBuilder modules now live under `tools/semantic_harness/codebuilder/`.

## Executive result

At the recorded baseline, the Semantic Harness was behaviorally healthy but had several real responsibility-density hotspots. The first refactor target was the then-existing `tools/semantic_harness/codebuilder/compiler.py`, which contained three independent compilation pipelines and their renderers behind one module-level namespace.

The current `tools/semantic_harness/codebuilder` package is the single internal CodeBuilder implementation. The former `tools/semantic_compiler` package and the forwarding facades have been removed; callers use the concrete modules directly.

The initial audit pass was read-only. The first bounded refactor slice is now complete and is recorded below.

## Historical refactor progress — slice 1

At that historical baseline, commit `5ef6e453` extracted the WordNet lexicon/morphology pipeline into `tools/semantic_harness/codebuilder/lexicon_compiler.py`, while `codebuilder/compiler.py` remained the compatibility facade. That facade has since been retired.

Verification for this slice:

- Python compiler, dialogue, semantic-authoring, and consolidation tests: 35 passed.
- CodeBuilder, interaction-spec, CodeBlocks, visual-authoring, translation, parity, and dataset-adapter tests: 45 passed.
- Architecture affected-test selection: 4 direct and 8 transitive test targets.
- Post-scan: no new finding category; the compiler module dropped from 1,874 to 1,514 lines.

The next safe slice is the dialogue pipeline. It should be extracted only after preserving the shared normalization and Lua-rendering contracts used by the typed semantic pipeline.

## Historical refactor progress — slices 2–9

At the historical baseline, the remaining compiler pipelines and authoring/editor boundaries were split behind compatibility facades. The current cleanup completed the migration by removing those facades and updating repository callers to direct concrete modules.

- `13264b40`: dialogue dataset pipeline extracted to `dialogue_compiler.py`.
- `400072d1`: typed `pnc.semantic_authoring.v1` pipeline extracted to `semantic_definition_compiler.py`.
- `c500602e`: canonical source catalog extracted to `dataset_catalog.py`; `SemanticLabAuthoringService` remains the public facade.
- `84f179fb`: typed interaction preview/generation/workflow orchestration extracted to `interaction_generation.py`.
- `6fdf0470`: Flow Editor graph-model and coverage projections extracted to `flow_editor_model.py`.
- `67e801f6`: bounded undo/redo snapshot state extracted to `flow_editor_state.py`.
- `c258fd76`: canvas zoom/pan/drag/render controller extracted to `flow_editor_canvas.py`.
- `e286c3b2`: graph mutation, authoring prompts, validation, registration, and draft actions extracted to `flow_editor_actions.py`.
- `68919d5c`: dialogue validation, pattern, response, dataset, and rendering stages split into focused modules; `dialogue_compiler.py` is now a 56-line compatibility facade.

Verification for the completed modularization:

- Full Semantic Harness Python discovery: `274` passed, exit `0`, `171.441s`.
- Full embedded Lua harness: `853/853` passed, exit `0`, `16.23s`.
- Full embedded compiler suite: `16` passed, exit `0`.
- Final worker doctor: all required checks true, including worker syntax and `READY/PING/CAPABILITIES`, exit `0`.
- Final Kahlua verification: `2,947` Lua files scanned (`19` excluded), `0` Kahlua findings at `ERROR+`, exit `0`.
- Final token scan (`o200k_base`, threshold `2000`): `140` files scanned, `54` over threshold. Remaining over-threshold files are known UI/action/rendering or semantic-definition functions; the compiler facade itself is `630` tokens and the dialogue facade is `430` tokens.

## Final architecture comparison

The saved scoped baseline was `116` files / `53` production / `63` tests / `15,500` LOC, health `86.4`, coverage `68.1`, confidence `54.9`, and `43` findings. The final scoped scan is `130` files / `67` production / `63` tests / `16,148` LOC, health `90.2`, coverage `69.3`, confidence `55.8`, and `41` findings. CodeBuilder pressure fell from `20.3` to `18.9`; Flow Editor pressure fell from `28.8` to `13.4`. The final scan has no `LARGE_MODULE` finding; the remaining findings are 24 large functions, 6 silent-error paths, 6 unbounded loops, 4 coupling findings, and 1 global mutable-state finding outside these completed slices.

## Evidence

Architecture scan of the complete repository:

- 4,177 files scanned; 3,080 production files; 1,010 tests indexed.
- Production health: 89.7/100.
- Coverage: 76.2%; confidence: 61.2%.
- Highest subsystem pressure: Semantics 75.3/100; Composition 68.2/100.

Scoped Semantic Harness scan:

- 116 files; 53 production files; 63 test files; 15,500 scored LOC.
- Health: 86.4/100; coverage: 68.1%; confidence: 54.9%.
- Highest harness pressure: worker 40.8, process 35.9, GUI 28.8, CodeBuilder 20.3.
- The scanner found 43 findings: 24 large-function, 3 large-module, 6 silent-error-swallow, 6 unbounded-loop, 3 cross-subsystem-coupling, and 1 global-mutable-state finding.

Local tokenizer scan using `o200k_base` with a 2,000-token threshold identified 46 oversized files. The highest production candidates are:

| File | Lines | Tokens | Audit priority |
| --- | ---: | ---: | --- |
| `tools/semantic_harness/codebuilder/compiler.py` | 1,874 | 18,894 | P0 |
| `tools/semantic_harness/flow_editor.py` | 1,816 | 18,094 | P1 |
| `tools/semantic_harness/codebuilder/interaction_spec.py` | 952 | 9,243 | P1 |
| `tools/semantic_harness/codebuilder/service.py` | 1,035 | 7,747 | P1 |
| `tools/semantic_harness/workflow.py` | 654 | 6,851 | P2 |
| `tools/semantic_harness/gui.py` | 740 | 6,613 | P2 |
| `tools/semantic_harness/codebuilder/blocks.py` | 496 | 4,743 | P2 |
| `tools/semantic_harness/conversation_inspector.py` | 459 | 4,155 | P2 |

Test files also exceed the threshold, but they are not refactor targets by size alone. Shared test infrastructure should only be extracted when duplication or setup coupling is demonstrated.

## P0 — compiler responsibility density

`codebuilder/compiler.py` has three distinct pipelines:

1. **WordNet lexicon pipeline, approximately lines 1–472**
   - WordNet source/hash/license validation.
   - Synset and exception-file parsing.
   - Bounded verb morphology.
   - Lexicon compilation and Lua rendering.

2. **Dialogue dataset pipeline, approximately lines 473–1,410**
   - Dialogue source loading and metadata validation.
   - Pattern, negative-example, response-pool, translation, and plan validation.
   - Dialogue compilation.
   - Lua shard, manifest, and translation rendering.

3. **Typed semantic-authoring pipeline, approximately lines 1,420–1,874**
   - `pnc.semantic_authoring.v1` loading and validation.
   - Semantic frame, flow, response, capability, and collision checks.
   - Typed definition compilation.
   - Semantic Lua shard and manifest rendering.

The shared concerns are limited to bounded scalar validation, stable Lua value serialization, and deterministic shard handling. The pipelines do not need to share mutable state. This is a strong structural boundary, not a heuristic-only size finding.

The graph confirms that `_compile_dialogue_pattern` is reached through the canonical interaction/service/authoring paths, while `compile_semantic_definitions` is reached by `interaction_spec`, `SemanticLabAuthoringService`, `authoring`, the legacy build wrapper, and dataset-library validation. This makes an import-compatible facade important.

### Historical recommended compiler split

Move implementation behind the existing public module surface in this order:

1. `codebuilder/compiler_shared.py` — bounded Lua values, stable strings, shard primitives, and shared compile error types only.
2. `codebuilder/lexicon_compiler.py` — WordNet dataclasses, readers, morphology, `compile_wordnet`, and `render_lua`.
3. `codebuilder/dialogue_compiler.py` — dialogue source validation, compilation, dialogue renderers, and translation rendering.
4. `codebuilder/semantic_definition_compiler.py` — semantic source loading, typed flow/response validation, compilation, and semantic renderers.
5. The historical compatibility facade was intentionally retired after all repository callers were migrated. Do not recreate it for this legacy prototype.

Do not create a second compiler or change the canonical source format. `tools/semantic_harness/codebuilder/{lexicon_compiler,dialogue_dataset,semantic_definition_compiler}.py` are now the direct public implementation modules for repository callers; consolidation tests cover their current contracts.

## P1 — authoring service and interaction-spec boundary

`codebuilder/service.py` is the public facade for Tk, CLI, and direct callers, but it currently combines:

- canonical dataset catalog/load/search/write operations;
- CodeBlock catalog and validation;
- interaction graph editing and validation;
- interaction-spec and collection compilation;
- effect-free preview artifact construction;
- explicit generation and filesystem writes;
- legacy authoring adapters and external dataset promotion.

This is a valid orchestration boundary, but its implementation is too broad. Split behind the existing `SemanticLabAuthoringService` facade rather than changing callers:

- `dataset_catalog_service.py`: source catalog, loading, search, canonical document validation, and canonical writes;
- `interaction_generation_service.py`: typed spec/collection/workflow validation, preview, approval, and generation orchestration;
- `artifact_preview.py`: deterministic source/Lua/translation diff planning with no writes;
- `legacy_authoring_adapter.py`: compatibility calls into the existing `authoring.py` report shapes.

`interaction_spec.py` should be audited separately before splitting. Its likely seams are graph normalization/editing, graph validation/topology, and canonical interaction materialization. Do not split merely by line count: the typed graph contract and its rejection behavior are the important unit.

## P1 — Flow Editor

`flow_editor.py` is 1,816 lines / 18,094 tokens and mixes Tk widget construction, graph canvas rendering, draft mutation, history, node/edge editing, catalog selection, compile/generate actions, reports, and file persistence.

Recommended seams:

- `flow_editor_state.py`: draft model, selection, history, undo/redo, and declarative edits;
- `flow_editor_canvas.py`: coordinate transforms, zoom/pan, hit testing, node/edge rendering;
- `flow_editor_actions.py`: validation, compile, generation, dataset review, and report projection;
- retain a thin `FlowEditorPane` adapter for Tk event wiring.

The graph model and CodeBlock validation must remain shared with the existing Semantic Lab workflow. Do not introduce a second graph model.

## P2 — workflow, GUI, and worker follow-up

`workflow.py` is a smaller but still mixed UI/controller module: palette selection, graph mutation, composition, validation, preview, approval, and generation. It should be migrated only after the compiler and service contracts stabilize.

`gui.py` is an application orchestrator with 15 direct subsystem dependencies. The coupling is acceptable for a composition root if it remains policy-free. Move screen-specific callbacks into controller adapters before reducing imports; do not turn the GUI into a new service layer.

The Lua worker has independent runtime concerns:

- `ProductionModules.load` spans 366 lines and should be separated by module-loading phase only after runtime parity tests exist.
- `OutputProjection.observation` and `CommandRouter.dispatch` are large but are protocol boundaries; preserve response shapes first.
- `Protocol.lua` has scanner-reported unbounded parser loops. Verify explicit termination on malformed input before refactoring.
- `process.py` has a deliberate `queue.Full` swallow while reporting a failed response. It should have an explicit bounded diagnostic policy, but that is a behavior change and is outside this audit-only pass.

## Historical dependency and compatibility hazards

- The former `tools.semantic_compiler.compiler` wrapper and the former `codebuilder/compiler.py` facade were retired after their repository callers were migrated.
- `codebuilder/build.py`, `codebuilder/authoring.py`, `interaction_spec.py`, and interaction-generation code import concrete compiler functions directly.
- Private helper imports were audited during migration; do not restore a broad facade just to preserve prototype-only names.
- Generated Lua, EN/TL assets, manifests, deterministic hashes, explicit-approval behavior, and effect-free previews are compatibility contracts.
- The worker is a real Core+Hoomans integration boundary. Python module splits must not alter Lua load order, generated module names, worker protocol, or response projection.
- Avoid introducing a shared “god” utility module while splitting. Shared modules should contain only serialization, bounded validation primitives, or explicit contracts.

## Safe migration sequence

1. Freeze the current baseline with the existing focused/full Python and Lua suites; save an architecture-audit baseline.
2. Add contract tests for direct compiler exports, deterministic artifact bytes, translation manifests, and any private helper still required by current code.
3. Extract the WordNet pipeline into its direct module. Run compiler, consolidation, Kahlua, and artifact-regeneration tests.
4. Extract the dialogue pipeline. Run dialogue dataset, translation, interaction-spec, and worker acceptance tests.
5. Extract the typed semantic pipeline. Run V1 visual authoring, semantic authoring, non-backstory interaction, and worker tests.
6. Split service internals behind `SemanticLabAuthoringService`; use affected-test selection after each change.
7. Split Flow Editor state/canvas/actions only after the service contract is stable.
8. Audit and migrate worker transport/projection modules separately; keep runtime changes out of the compiler refactor.
9. Rescan architecture, compare against the saved baseline, and only accept changes that reduce responsibility coupling without changing behavior.

## Verification commands used

```bash
python3 /home/psychopatz/Desktop/Projects/Zomboid-devSkills/.agents/skills/architecture-audit/architecture_audit.py scan /home/psychopatz/Zomboid/Workshop/ProjectHoomans --framework project_zomboid
python3 /home/psychopatz/Desktop/Projects/Zomboid-devSkills/.agents/skills/architecture-audit/architecture_audit.py scan /home/psychopatz/Zomboid/Workshop/ProjectHoomans/tools/semantic_harness --framework project_zomboid --json
python3 /home/psychopatz/Desktop/Projects/Zomboid-devSkills/.agents/skills/file-token-bloat-detector/scripts/file_token_bloat_scan.py tools/semantic_harness --threshold 2000 --json
```

The graph index was ready at generation `2026-10-20T16:15:18Z`, with no recorded parse-partial or skipped source files for the audited paths. This is a best-effort coverage signal, not proof of completeness.

## Audit disposition

The compiler is ready for a bounded, behavior-preserving extraction as the next refactor chunk. Start with the compatibility facade and contract tests, then extract one pipeline at a time. Do not refactor the worker or GUI in the same chunk.
