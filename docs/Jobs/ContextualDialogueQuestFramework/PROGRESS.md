# Contextual Dialogue & Quest Framework — current progress

## S6 accepted — deterministic EN/TL and live-worker handoff

The unified Semantic Lab has completed the repository-verifiable roadmap
work. Its Build workflow, Dataset Library, reusable block registry, visual
Flow editor, declarative codeblocks, embedded CodeBuilder, headless CLI, and
real Lua worker now share the same authoring/build boundary. The remaining
native Project Zomboid SP/MP session, UI/world integration, and live external
PBrainZ validation are deliberately user-owned.

S6 evidence:

- `python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py' -q` — **203/203 passed in 80.888s**, including GUI startup, real Lua-worker conversations, worker restart, deterministic authoring, and the full accepted contextual matrix.
- `python3 -m unittest tools.semantic_harness.tests.test_dataset_review tools.semantic_harness.tests.test_semantic_translation_integration tools.semantic_harness.tests.test_phase6_performance -q` — **10/10 passed**, covering generated artifact determinism, EN/TL translation integration, and bounded performance/scope isolation.
- Workflow artifact hash comparison — **9/9 generated dialogue Lua/EN/TL/manifest artifacts unchanged**, with every current/expected SHA-256 pair equal and all preview statuses `unchanged`.
- `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` — **PASS** for Python 3.12.3, repository/Core paths, Tk/display, Lua 5.3, worker syntax, boot, PING, and CAPABILITIES.
- `./tools/semantic_harness/run_harness.sh --test pnc_semantic` — **4 pre-existing Lua smoke failures / 68 executed** in gift/inventory/local-route/state-response behavior; the Semantic Lab work changed no production Lua and did not alter the documented baseline.
- Python compilation and `git diff --check` — **PASS**; generated output paths remain clean in Git after the approved workflow generation.

**Current goal status:** **S6 accepted; the integrated Semantic Lab is READY
FOR USER LIVE TEST. Native Project Zomboid SP/MP and live external PBrainZ
validation remain user-owned.**

**ONE Next Chunk:** **USER LIVE TEST — launch the native Project Zomboid
workflow, inspect the Build workflow and Simulation tabs, and exercise the
generated EN/TL dialogue in the user-owned game environment.**

## S5 accepted — one in-app build-to-worker workflow

Semantic Lab now has a Build workflow tab inside the existing application. It
selects a generation-ready canonical dataset, composes reusable blocks from
the live production catalog, validates the dataset and block selection,
previews the existing Lua/EN/TL/manifest artifacts, requires an explicit
approval, delegates generation to the existing CodeBuilder writer, restarts
the existing Lua worker, and returns to the Simulation tab for real dialogue
inspection. The headless CLI and direct service callers use the same workflow
methods. WordNet remains available through the Dataset Library but is not
silently treated as a Lua-generating workflow source.

S5 evidence:

- `python3 -m unittest tools.semantic_harness.tests.test_codebuilder_consolidation tools.semantic_harness.tests.test_dataset_review tools.semantic_harness.tests.test_app -q` — **28/28 passed**, including workflow composition/preview, explicit approval gating, CLI routing, GUI startup, artifact parity, and actual worker restart/conversation behavior.
- `./tools/semantic_harness/run_harness.sh --no-gui --jsonl --workflow-preview common_interactions --workflow-blocks language.speech_act` — **PASS**, effect-free workflow preview ready for approval with 9 generated artifact paths.
- `./tools/semantic_harness/run_harness.sh --no-gui --jsonl --workflow-generate common_interactions --workflow-blocks language.speech_act --approve-workflow` — **PASS**, explicit approval generated 9 existing dialogue artifacts and reported `restartRequired=true`; all checked-in bytes remained unchanged.
- `./tools/semantic_harness/run_harness.sh --no-gui --jsonl --workflow-generate common_interactions --workflow-blocks language.speech_act` — **PASS as a safety check**, rejected without approval, wrote nothing, and returned exit code 2.
- The shared service, GUI, CLI, and direct-Codex boundary all delegate to the existing compiler/writer; no second interpreter, dataset store, artifact writer, translation layout, or gameplay authority was added.

## S4 accepted — reviewed build-time MASSIVE/SGD dataset adapters

Semantic Lab's embedded CodeBuilder now contains reviewed build-time adapters
for MASSIVE- and SGD-shaped sources. Each adapter requires a provenance and
license manifest, verifies the source SHA-256, reads only a bounded number of
records, and produces effect-free review candidates. Explicit reviewer
decisions can promote candidates into the existing canonical dialogue source,
but only when the manifest approves derived raw-text redistribution. The
adapters never write raw corpora to `Contents/mods/**/media`, package raw
records for Lua, create a second dataset store, or replace the existing
dialogue compiler.

S4 evidence:

- `python3 -m unittest tools.semantic_harness.tests.test_dataset_adapters -v` — **5/5 passed**, including MASSIVE/SGD normalization, bounded candidate shape, provenance-gated promotion through the existing compiler, runtime-media rejection, and headless Semantic Lab CLI routing.
- `python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py' -q` — **200/200 passed in 90.443s**, including actual Lua-worker conversations, GUI startup, and the existing Semantic Lab acceptance suites.
- `python3 -m unittest discover -s tools/semantic_compiler/tests -p 'test_*.py' -q` — **15/15 passed**; `python3 -m unittest tools.semantic_harness.tests.test_codebuilder_consolidation -q` — **9/9 passed**, preserving compiler/writer identity and artifact parity.
- `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` — **PASS** for Python 3.12.3, repository/Core paths, Tk/display, Lua 5.3, worker syntax, boot, PING, and CAPABILITIES.
- `./tools/semantic_harness/run_harness.sh --test pnc_semantic` — **4 pre-existing Lua smoke failures / 68 executed** in gift/inventory/local-route/state-response behavior; S4 changed no production Lua and did not alter the documented baseline.
- Python compilation and `git diff --check` — **PASS**.

The graph coverage check for the S4 files reported no recorded parse gaps,
but the new files were not tracked and edited files were metadata-changed in
the older 2026-10-07 generation; direct source reads and the executable tests
above are therefore the authority for this slice.

## S3 accepted — synchronized visual graph and codeblock editing

The existing Flow editor now has a deterministic `semantic.codeblocks.v1`
representation synchronized with the visual graph. It preserves complete node
definitions, emits explicit `flow` and `result` connection types, validates
bounded reachability and special targets, and supports bounded nested-flow
references against known registry IDs. Syncing is effect-free; applying a
document changes only the local draft and leaves production registration to
the existing Lua `Registry.Validate`/`Registry.Register` boundary. Nested
references remain explicit Semantic Lab authoring metadata because the current
production registry has no nested-flow execution contract; they are not
silently turned into runtime dispatch.

S3 evidence:

- `python3 -m unittest tools.semantic_harness.tests.test_codeblocks tools.semantic_harness.tests.test_semantic_blocks tools.semantic_harness.tests.test_flow_editor tools.semantic_harness.tests.test_app tools.semantic_harness.tests.test_codebuilder_consolidation -q` — **33/33 passed**, including typed result-edge round trips, special targets, nested-flow validation, headless validation, the live Flow editor, and GUI startup.
- `python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py' -q` — **195/195 passed**, including actual Lua-worker conversations and GUI startup.
- Production Lua round-trip proof — a generated FOLLOW flow converted to codeblocks and back with identical node definitions; the reconstructed draft passed the real Lua `Registry.Validate` contract.
- `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` — **PASS** for Python 3.12.3, repository/Core paths, Tk/display, Lua 5.3, worker syntax, boot, PING, and CAPABILITIES.
- `./tools/semantic_harness/run_harness.sh --test pnc_semantic` — **4 pre-existing Lua smoke failures** in gift/inventory/local-route/state-response behavior; S3 changed no production Lua and did not alter the documented baseline.
- Python compilation and `git diff --check` — **PASS**.

## S2 accepted — reusable Semantic Lab block registry

Semantic Lab now has a shared `SemanticBlockRegistry` inside CodeBuilder and a
Block registry tab in the existing application. It exposes bounded reusable
contracts for language, conditions, world facts, context, memory, dialogue
responses, gameplay actions, and quests. The live FlowEditor catalog supplies
registered speech acts, concepts, triggers, typed facts/events, action
bindings, quest bindings, and production ownership; canonical JSON supplies
reviewed response pools. Block selection validation is effect-free and fails
closed for unknown or duplicate IDs. The registry does not evaluate gates,
interpret NLU, dispatch actions, or create quest state.

S2 evidence:

- `python3 -m unittest tools.semantic_harness.tests.test_semantic_blocks tools.semantic_harness.tests.test_codebuilder_consolidation tools.semantic_harness.tests.test_app tools.semantic_harness.tests.test_flow_editor -q` — **29/29 passed**, including static/live category coverage, production action/quest/fact/event values, effect-free selection validation, CLI routing, and GUI startup with the Block registry tab.
- `python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py' -q` — **191/191 passed**, including actual Lua-worker conversations and GUI startup.
- `./tools/semantic_harness/run_harness.sh --no-gui --jsonl --list-blocks` — **PASS**, returned 28 static reusable block/type records across all eight categories.
- `./tools/semantic_harness/run_harness.sh --no-gui --jsonl --search-blocks memory` — **PASS**, returned the registered knowledge and gossip contracts.
- `./tools/semantic_harness/run_harness.sh --no-gui --jsonl --validate-blocks conditions.gate,memory.gossip` — **PASS**, valid and effect-free with no writes or dispatch.
- Actual Lua-worker catalog/conversation probe — **PASS**: live production catalog produced **61** bounded blocks; FOLLOW resolved to the existing `pnc:companion.follow` binding; `Keep close behind me` produced `FOLLOW` with exactly one `CompanionCommand` transport.
- `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` — **PASS** for Python 3.12.3, repository/Core paths, Tk/display, Lua 5.3, worker syntax, boot, PING, and CAPABILITIES.
- `./tools/semantic_harness/run_harness.sh --test pnc_semantic` — **4 pre-existing Lua smoke failures** in gift/inventory/local-route/state-response behavior; S2 changed no production Lua and did not alter the documented baseline.
- Python compilation and `git diff --check` — **PASS**.

## S1 accepted — Dataset Library inside Semantic Lab

Semantic Lab now contains a Dataset Library tab backed by the shared
`SemanticLabAuthoringService`. It catalogs the three existing canonical JSON
sources (`semantic_definitions`, `common_interactions`, and reviewed
`wordnet_concepts`), supports bounded search and source browsing, loads a
selected source into an editable JSON draft, validates it through the existing
CodeBuilder contracts, and writes only after explicit approval. The headless
CLI exposes the same catalog/search/show/validate service boundary. No second
dataset store, compiler, interpreter, Lua writer, translation layout, or
worker authority was introduced.

S1 evidence:

- `python3 -m unittest tools.semantic_harness.tests.test_codebuilder_consolidation tools.semantic_harness.tests.test_app tools.semantic_harness.tests.test_dataset_review tools.semantic_harness.tests.test_semantic_authoring_compiler -q` — **28/28 passed**, including canonical source catalog/search/validation, CLI routing, the GUI entrypoint with the Dataset Library tab, existing writer parity, and production-worker authoring coverage.
- `python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py' -q` — **187/187 passed**, including actual Lua-worker conversations and GUI startup.
- `./tools/semantic_harness/run_harness.sh --no-gui --jsonl --list-datasets` — **PASS**, returned all three existing canonical sources.
- `./tools/semantic_harness/run_harness.sh --no-gui --jsonl --search-datasets follow` — **PASS**, returned bounded semantic, dialogue, and lexicon matches.
- `./tools/semantic_harness/run_harness.sh --no-gui --jsonl --validate-dataset semantic_definitions` — **PASS**, effect-free validation reported `definitions=1`, `patterns=2`, and `flows=1` with no writes.
- `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` — **PASS** for Python 3.12.3, repository/Core paths, Tk/display, Lua 5.3, worker syntax, boot, PING, and CAPABILITIES.
- `./tools/semantic_harness/run_harness.sh --no-gui --jsonl --language TL --input 'Keep close behind me' --input 'Are you okay?' --input 'Can we talk about the weather' --audit` — **PASS** through the actual Lua worker: existing FOLLOW action transport remained one `CompanionCommand`, TL responses resolved, question turns remained non-mutating, `llmCalls=0`, and the final audit reported `ok=true` with no conflicts.
- `./tools/semantic_harness/run_harness.sh --test pnc_semantic` — **4 pre-existing Lua smoke failures** in gift/inventory/local-route/state-response behavior; S1 changed no production Lua and the failures match the documented baseline.
- `./tools/semantic_harness/run_harness.sh --test` — **17/843 Lua smoke cases remain failing**; the four semantic failures above are included in that baseline, with the remaining failures outside this Semantic Lab consolidation scope.
- Python compilation and `git diff --check` — **PASS**.

The graph coverage check for the changed Semantic Lab files reported no
recorded parse gaps, but marked the new files as not tracked and the edited
files as metadata-changed in the older 2026-10-07 generation; direct source
reads and the executable tests above are therefore the authority for S1.

**S0A update (2026-10-19):** The existing semantic compiler is now embedded
under `tools/semantic_harness/codebuilder/`. Its reviewed JSON inputs remain
single-source under `tools/semantic_compiler/`; the legacy Python modules are
thin compatibility wrappers. Semantic Lab authoring and headless authoring
operations use the embedded CodeBuilder, with no second compiler, writer, or
runtime interpreter.

S0A evidence:

- `python3 -m unittest discover -s tools/semantic_compiler/tests -p 'test_*.py' -q` — **15/15 passed**.
- `python3 -m unittest tools.semantic_harness.tests.test_codebuilder_consolidation -v` — **5/5 passed**, including legacy/embedded API identity, dialogue and semantic writer parity, checked-in generated Lua/manifest bytes, and headless CLI/GUI routing.
- `python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py' -q` — **184/184 passed**, including actual Lua-worker conversations and authoring/worker restart tests.
- `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` — **PASS** for Python, repository/Core paths, Tk/display, Lua 5.3, worker syntax, boot, PING, and CAPABILITIES.
- `./tools/semantic_harness/run_harness.sh --test pnc_semantic` — **4 pre-existing Lua smoke failures** in gift/inventory/local-route/state-response behavior; no Lua source changed in S0A, and the failures match the documented baseline rather than being promoted to green.
- `git diff --check`, Python compilation, direct and module legacy build `--help`, and embedded CodeBuilder direct `--help` — **PASS**.

The requested `SEMANTIC_STUDIO_CONSOLIDATION.md` and documentation commit
`a76a2edbac7e` were unavailable in the local checkout; the available
architecture, workbench, compiler, pipeline, roadmap, runbook, acceptance,
and historical documents were used instead. Native Project Zomboid SP/MP and
live external PBrainZ remain user-owned.

## S0B accepted — one shared authoring/build service

`SemanticLabAuthoringService` now binds one repository/runtime configuration
and is used by the Tk Semantic Lab, headless authoring CLI, and direct
Python/Codex callers. It delegates to the existing authoring reports and the
embedded CodeBuilder; module-level authoring functions remain compatibility
helpers, not a second pipeline. The service does not change compiler
algorithms, parser contracts, output paths, translation manifests, or worker
authority.

S0B evidence:

- `python3 -m unittest tools.semantic_harness.tests.test_codebuilder_consolidation tools.semantic_harness.tests.test_app tools.semantic_harness.tests.test_dataset_review tools.semantic_harness.tests.test_semantic_authoring_compiler -q` — **26/26 passed**.
- `python3 -m unittest discover -s tools/semantic_harness/tests -p 'test_*.py' -q` — **185/185 passed** after service routing.
- `./tools/semantic_harness/run_harness.sh --no-gui --jsonl --compile-source tools/semantic_compiler/semantic_definitions.json` — **PASS**, effect-free canonical preview through the shared service.
- `./tools/semantic_harness/run_harness.sh --doctor --doctor-json` — **PASS**.

**Updated:** 2026-10-19, after the S6 live-worker handoff acceptance slice.

**Local implementation:** branch `codex/contextual-dialogue-quest-framework-0a`;
S0A, S0B, and S1–S6 are accepted in the rebased local history. The earlier
acceptance commits were rewritten by this rebase; preserved source-history
references in the historical records refer to their pre-rebase commit IDs.

The previous `PROGRESS.md` has been archived verbatim in `HISTORY_C0_C6_20261019.md` and remains recoverable in Git at `71162cb4f78cc4cd408a4a145486d5ebadc943c1`. It records the action-flow/quest work and C0–C6 contextual conversation, small reviewed dataset codebuilding, Tk X11, worker, performance, EN/TL and optional-provider parity acceptance, ending READY FOR USER LIVE TEST for that **earlier scoped implementation**. Native PZ SP/MP and live external PBrainZ validation remain user-owned, unclaimed.

The prior user-live-test handoff is historical evidence and is superseded for
this consolidation goal by the single user-live-test chunk above; it was not
re-run or claimed as part of S6.

## Productization roadmap

`SEMANTIC_STUDIO_CONSOLIDATION.md` and `ROADMAP.md` define S0A→S0B→S1 Dataset Library→S2 typed semantic block registry→S3 graph/code composer→S4 licensed corpora→S5 complete approved generation/reload workflow→S6 UX/performance handoff.

User alone runs actual Project Zomboid and manages Steam Workshop publication/install; no such steps are authorized for Codex by this goal.
