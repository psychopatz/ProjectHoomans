# Contextual Dialogue & Quest Framework — CURRENT state

**Updated:** 2026-10-19
**Inspected remote branch:** `docs/contextual-dialogue-quest-framework-20261018` @ `71162cb4f78cc4cd408a4a145486d5ebadc943c1`; PR #4 open/unmerged at verification. **Not a claim about the agent's actual local checkout**.
**Status:** **IN PROGRESS — S0 Semantic Studio consolidation** (new approved productization scope; no new production code changes/tests in this documentation commit).
**ONE Next Chunk:** **S0A — Embed existing semantic compiler within Semantic Lab CodeBuilder with byte-for-byte production artifact parity and legacy CLI compatibility.**

## Prior accepted foundation (preserved, NOT invalidated)

The previous `PROGRESS.md` has been archived verbatim in `HISTORY_C0_C6_20261019.md` and remains recoverable in Git at `71162cb4f78cc4cd408a4a145486d5ebadc943c1`. It records the action-flow/quest work and C0–C6 contextual conversation, small reviewed dataset codebuilding, Tk X11, worker, performance, EN/TL and optional-provider parity acceptance, ending READY FOR USER LIVE TEST for that **earlier scoped implementation**. Native PZ SP/MP and live external PBrainZ validation remain user-owned, unclaimed.

This new phase does not re-open those accepted runtime features or invite Codex to run PZ. The gap is the **fragmented authoring product**: `tools/semantic_harness` and `tools/semantic_compiler` are separate peer packages; harness authoring imports the independent compiler/writer while keeping overlapping output path/report logic; UI mostly relies on manual JSON file dialogs for compiler and dataset operations.

## Verified audit evidence

- Source: `tools/semantic_compiler/README.md`, `compiler.py`, `build.py`, three canonical reviewed JSON sources and tests.
- Harness: `tools/semantic_harness/authoring.py`, `flow_editor.py`, `gui.py`, `run_harness.sh`, worker and tests.
- `authoring.py` imports `tools.semantic_compiler.compiler` and `tools.semantic_compiler.build`; path roots and artifact report generation overlap with compiler writer.
- Screenshot shows Flow Editor, Compile source..., Generate source..., Review dataset..., Generate dialogue... buttons, not an integrated dataset library/typed visual+codeblock composer.
- Output directory layout must be audited against root AGENTS.md (including translation conventions). A no-behavior-change migration should not silently move runtime generated files.

**Unaccepted new work:** no embedded CodeBuilder, no single artifact writer, no in-app browsable/editable dataset library, no reusable typed block composition graph, no synchronized canonical code/graph editor and no demonstrated full in-app dataset→block→Lua worker authoring loop.

## EXACT Next Chunk S0A — one bounded implementation

1. Inspect real local checkout, branch/head/upstream and dirty/parallel agents' work; stop for actual ownership conflicts, not GUI CUA absence.
2. Audit all compiler/harness imports, CLIs, data-source paths, output manifests and dependency closures. Capture baseline hashes for reviewed build modes, current tracked Lua + EN/TL/manifest artifacts, and real worker context/command behavior.
3. Embed the existing compiler modules and, when safe, canonical reviewed source inputs under `tools/semantic_harness/codebuilder/`, routing harness authoring and CLI through those modules. Keep only thin legacy import/CLI shims for verified callers; no duplicate parser/render/write implementation.
4. Require **byte-identical, deterministic generated production artifacts** with unchanged paths/IDs/translation keys before accepting S0A. Test all available build modes, including explicit checks/skips for unavailable WordNet archive. No write staging directories in watched PZ media.
5. Run focused compiler/harness tests, doctor, fresh Lua worker and one multi-turn/context + companion command + gift/quest + EN/TL regression, syntax checks and `git diff --check`; real Tk startup/mouse when available. Do not claim native PZ/SP/MP or CUA pass.
6. Commit safe coherent code/tests/docs; record exact SHA/commands/hash comparison and ONE next chunk `S0B — Unified authoring/build service` if accepted; otherwise retain S0A with concrete failed assertion.

**S0A exit condition:** one embedded CodeBuilder under Semantic Lab, no duplicated build engine/source of truth, old documented CLI behavior preserved via wrappers as needed, and deterministic byte parity + actual worker behavior verified. Merely moving directories or passing JSON schema checks does not pass.

## Productization roadmap

`SEMANTIC_STUDIO_CONSOLIDATION.md` and `ROADMAP.md` define S0A→S0B→S1 Dataset Library→S2 typed semantic block registry→S3 graph/code composer→S4 licensed corpora→S5 complete approved generation/reload workflow→S6 UX/performance handoff.

User alone runs actual Project Zomboid and manages Steam Workshop publication/install; no such steps are authorized for Codex by this goal.
