# Contextual Dialogue & Quest Framework — current progress

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

**Current goal status:** **S1 accepted; S0A/S0B and prior C6 developer gates
remain preserved. Native Project Zomboid SP/MP plus live external PBrainZ
validation remain user-owned.**

**ONE Next Chunk:** **S2 — create the reusable semantic block registry inside
Semantic Lab for language, conditions, world facts, context, memory, dialogue
responses, gameplay actions, and quests, with bounded validation and reuse
metadata backed by the existing production contracts.**

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

**Updated:** 2026-10-19, after the S1 Dataset Library acceptance slice.

**Local implementation:** branch `codex/contextual-dialogue-quest-framework-0a`;
S0A, S0B, and S1 are accepted in the rebased local history. The earlier
acceptance commits were rewritten by this rebase; preserved source-history
references in the historical records refer to their pre-rebase commit IDs.

The previous `PROGRESS.md` has been archived verbatim in `HISTORY_C0_C6_20261019.md` and remains recoverable in Git at `71162cb4f78cc4cd408a4a145486d5ebadc943c1`. It records the action-flow/quest work and C0–C6 contextual conversation, small reviewed dataset codebuilding, Tk X11, worker, performance, EN/TL and optional-provider parity acceptance, ending READY FOR USER LIVE TEST for that **earlier scoped implementation**. Native PZ SP/MP and live external PBrainZ validation remain user-owned, unclaimed.

The prior user-live-test handoff is historical evidence and is superseded for
this consolidation goal by the single S2 chunk above; it was not re-run or
claimed as part of S1.

## Productization roadmap

`SEMANTIC_STUDIO_CONSOLIDATION.md` and `ROADMAP.md` define S0A→S0B→S1 Dataset Library→S2 typed semantic block registry→S3 graph/code composer→S4 licensed corpora→S5 complete approved generation/reload workflow→S6 UX/performance handoff.

User alone runs actual Project Zomboid and manages Steam Workshop publication/install; no such steps are authorized for Codex by this goal.
