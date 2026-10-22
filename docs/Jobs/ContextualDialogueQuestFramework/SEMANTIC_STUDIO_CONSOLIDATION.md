# Semantic Studio Consolidation — one application, embedded CodeBuilder

**Status:** S0 consolidation completed in the local worktree on 2026-10-23; the larger S1–S6 productization roadmap remains planned. Goal is to make `tools/semantic_harness` the sole developer-facing application for dataset import/review, reusable semantic blocks, flow/graph/code editing, compiler generation, production Lua simulation and regression verification. Do not build another GUI or keep an independent competing compiler workflow.

## Verified current fragmentation

- `tools/semantic_harness/`: the sole harness application, with `app.py`, `cli.py`, `ui/`, `studio/`, `runtime/`, `inspection/`, `testing/`, `codebuilder/`, tests and `run_harness.sh`.
- `tools/semantic_harness/codebuilder/`: the concrete CodeBuilder modules (`lexicon_compiler.py`, `dialogue_dataset.py`, `semantic_definition_compiler.py`, renderers, service and build entrypoint) plus the canonical reviewed inputs under `sources/*.json`. It is an internal headless subsystem, not a second package or application.
- All Python callers import those concrete modules directly. The old `tools/semantic_compiler` package and the former top-level forwarding modules have been removed; there are no compatibility shims or dual editable source copies.
- The remaining productization gap is inside the existing harness UI: Compile/Generate/Review dataset actions still need to become a fully browseable shared dataset/block/code editing workspace.
- Source `AGENTS.md` requires Build 42.20 executable Lua inside the versioned mod's `media` tree and portable assets and translations in approved `common/media` structure; existing compiler writes some translations under `common/media/translation`. **Audit actual production loading/translation conventions and reconcile this discrepancy in a separately measured packaging slice. Do not opportunistically change output paths during no-behavior-change consolidation.**

## Target dependency / ownership graph

```text
tools/semantic_harness/
  app.py / cli.py / run_harness.sh     # sole entrypoints, headless/GUI
  gui.py, ui/...                      # UI shell, dataset/block/graph/source/sim views
  authoring.py (thin façade only)     # routes authoring operations via one service
  studio/                             # versioned canonical editable definition
    service.py                        # load/edit/validate/preview/approve/generate/reload
    blocks.py, composition.py         # typed reusable block registry + graph contracts
    repository.py                     # catalog, imported defs, editor metadata, overrides
  codebuilder/                        # INTERNAL pure build subsystem
    compiler.py                       # moved existing compile/render algorithms unchanged
    build.py or cli.py                # invoked through Semantic Lab CLI
    artifacts.py, paths.py            # one manifest/path/atomic-write authority
    sources/                           # approved canonical lexical/dialogue/semantic seeds
    tests/
  datasets/                           # imports, provenance, review, mappings
  lua/, scenarios/, tests/            # current production worker and integration tests
```

This is a **target layout**, not an instruction to create empty files or restructure everything in one commit. Retain good existing boundaries. Core lexical parse, Hoomans policy, command/task/gift/quest authority and PZ packaging stay in their present owning runtime repositories.

## Non-negotiable architectural invariants

1. Only **one canonical authored model**: dataset-reviewed samples, semantic definitions, flow/action binding/gates, translated responses and graph layout metadata belong to a versioned editable specification. Lua/manifest/EN+TL files are deterministic derived artifacts. Graph and supported code editing operate on the same model.
2. Only **one compilation/rendering/writing authority** under Semantic Lab CodeBuilder. Tk, CLI and agent APIs call the same headless service; UI must not reimplement source writers/path generation, dialog validation or semantic routing.
3. CodeBuilder remains callable headlessly through Semantic Lab CLI for Codex/CI; no separate long-lived process or second graphical/compiler application.
4. There is no legacy compiler package or forwarding compatibility layer. All repository callers use the canonical Semantic Harness modules and source paths; external scripts must adopt those paths directly.
5. Never write staging directories inside a loaded PZ `media/` tree. Keep unapproved/temporary outputs external; approved generation uses safe atomic file replace, explicit manifests and source path review.
6. No duplicate parser or runtime interpreter: PsychopatzCore owns generic NLU/IR, Hoomans Lua owns flow/response and server gameplay. Build-time corpus examples are NOT bundled at runtime. Preview remains side-effect-free.
7. No arbitrary Lua callback in blocks, implicit gameplay handler inference, altered permission semantics, or action completion claimed from parser recognition. Preserve offline, EN/TL, multi-NPC/MP authority and optional PBrainZ contracts.

## Migration strategy — SMALL, AUDITABLE, REVERSIBLE

### S0A — Completed: freeze behavior and embed compiler core

1. Inspect the local working tree, `AGENTS.md`, callers of the old compiler package, build flags, literal/default paths, tests, and generated artifact manifests.
2. Capture a *read-only baseline* of all current compiler modes: `--wordnet-home`, `--dialogue-source`, `--semantic-source`, default flags and supported overrides. Where external WordNet is unavailable, report that lane SKIPPED, not false PASS. Record byte-level SHA-256 of tracked generated Lua/JSON/manifests and typical outputs/worker observations. Never silently regenerate tracked files just to "freeze" evidence.
3. Move/copy **existing compiler algorithms and build services** under `tools/semantic_harness/codebuilder/` with minimal import/path adjustments, then route current Semantic Lab `authoring.py` and CLI via embedded modules. Move the three canonical reviewed source JSON inputs to `codebuilder/sources/` only when callsites/tests/defaults support it; no dual editable copies.
4. Migrate verified callers directly to the embedded modules and remove the legacy package. No compatibility shim or standalone GUI is retained.
5. Validate equality: old vs new compile outputs for same inputs, including source/module names, EN/TL, translation manifests, shard order, hashes and flow IDs; deterministic repeated run and clean git diff; unaffected PZ worker real Lua conversations (FOLLOW/STAY/GIFT/needs/quest plus one EN/TL case), no double dispatch.
6. Run focused old+new Python codebuilder/harness tests, doctor/worker boot, syntax / Kahlua and translation checks; GUI startup/X11 regression if available. Provide exact SHA, counts and proofs; keep user-owned native PZ/Workshop untouched.
7. Update only this job's PROGRESS with evidence and ONE next chunk **S0B** if accepted, otherwise keep S0A with concrete defect. Commit narrow coherent code/tests/docs after verifying Git ownership.

The completed S0A migration moved the concrete implementation and canonical JSON sources under CodeBuilder, updated repository imports/package data/generated provenance comments, removed the legacy package and forwarding facades, and preserved generated artifact tests. S0B remains the next work item.

### S0B — Unified authoring and artifact service

Consolidate `authoring.py` preview/generation and `build.py` output writing/path computation into a single headless service with `Load/Discover/Validate/PreviewDiff/GenerateApproved/ReloadWorker`; one canonical schema/path source, per-operation report and no hidden writes. Compiler CLI and Tk use the same API. Confirm deterministic output and pure preview. Retire redundant adapters only after tests.

### S1 — Integrated Dataset Library

Browse existing actual `common_interactions`, `semantic_definitions`, WordNet reviews, concept/pattern IDs, external dataset provenance, EN/TL coverage and approval status directly *inside Semantic Lab*. Must support in-app search, inspect, edit a reviewed candidate (without external manual JSON picker), collision result, and links to generated registered Lua flow. Corpus imports remain review- and license-gated and outside runtime; initially ship zero new massive data.

### S2 — Typed reusable semantic block registry

Blocks for language/pattern, context/focus/agenda, fact, condition, dialogue plan/response, memory reference, registered action, quest status and transitions. Descriptors have namespaced ID, version, typed ports, inputs/outputs, provider ownership and pure/effectful classification; nested reusable subgraphs supported. No block contains arbitrary Lua callback. The same block used in two composed flows must have one implementation/definition.

### S3 — Visual + code-style composer

Semantic Lab supports block palette, hierarchical reusable flows, add/delete/connect, typed edge validation, graph auto-layout/search and synchronized codeblock-style editor for supported declarative grammar. One canonical definition survives save/round-trip and generated source diffs. Unsupported handwritten Lua is preserved and safely marked non-round-trippable, never stripped or eval'd.

### S4 — Actual licensed corpus adapters

Add versioned optional MASSIVE/SGD(-style) ingestion into embedded `datasets/` subsystem only after S1–S3 support browsing/editing/review; fixed snapshots, licenses, checksums, EN/TL mapping, adversarial negatives and collision checks. Unsupported data stays marked unmapped, no unsafe automatic permission, no raw corpus in mod.

### S5 — Fully integrated generation loop

Author from dataset + blocks → validate via registered Core/flow contracts → preview exact file diff → explicitly approve → write correct modular Lua/translations/manifests → restart real worker → click result and inspect IR/context/binding/response/effects. Rebuilding unchanged spec must be byte-stable; source edits/overlays survive regeneration.

### S6 — Product acceptance, scale and handoff

Demonstrate one new contextual dialogue *entirely in Semantic Lab*, mixing at least two reusable modules and one registered fact/action route, with EN/TL, safe ambiguity, negative permission, real Lua source reload, trace and performance. No release of live PZ/MP or Workshop; these remain user-owned.

## Evidence classification

- **Earlier accepted**: C0–C6 existing worker/compiler/X11 features, according to preceding PROGRESS at `71162cb4f78cc4cd408a4a145486d5ebadc943c1`, archived in `HISTORY_C0_C6_20261019.md`.
- **Source verified**: two Python packages and overlapping import/path concerns at this SHA.
- **Planned and not tested**: migration, canonical studio editor/block registry, large actual corpus imports, unified source writer, redesigned browse/edit UI.
