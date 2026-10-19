# Current architecture audit — Semantic Lab vs standalone semantic compiler

**Remote source examined 2026-10-19:** `71162cb4f78cc4cd408a4a145486d5ebadc943c1` on `docs/contextual-dialogue-quest-framework-20261018`, PR #4 open/unmerged. GitHub source + user GUI screenshot, **not** a local worktree or fresh test rerun.

| Concern | Source evidence | Result |
| --- | --- | --- |
| GUI application | `tools/semantic_harness/app.py`, `gui.py`, `flow_editor.py`, `run_harness.sh` | One actual Tk application, persistent production Lua worker; compiler is NOT a second GUI |
| Standalone compiler | `tools/semantic_compiler/compiler.py`, `build.py`, JSON reviewed sources, tests, README with independent `python3 tools/semantic_compiler/build.py` commands | A second peer-level Python package and CLI/build pipeline |
| Cross-import | `semantic_harness/authoring.py` imports compiler parsing/rendering and `build.py` writer from `tools.semantic_compiler` | Compiler is used as library today, but authoring/report/path ownership split |
| Duplicated orchestration | `semantic_harness/authoring.py` defines `SEMANTIC_RELATIVE_ROOT`, `TRANSLATION_RELATIVE_ROOT`, `DIALOGUE_OUTPUT_RELATIVE_PATH`, `_planned_paths`; compiler `build.py` owns `DEFAULT_OUTPUT`, `DEFAULT_DIALOGUE_OUTPUT`, `write_*_output`, manifest writing | Overlapping configuration/orchestration; NOT proof that NLP compiler algorithms are duplicated |
| UI authoring | Flow Editor `compile_source()`, `generate_source()`, `review_dataset()`, `generate_dataset()` call Tk file picker and show report summary | Real helper workflows, not integrated dataset/block/code studio |
| Accepted runtime | Prior `PROGRESS.md` at this SHA reports G0–G3/C0–C6 Lua + compiler + X11 gates and READY FOR USER LIVE TEST | Preserve as historical previous-scope success, don't claim new UI requirements met |
| Asset layout | Root AGENTS.md: `42.20/media/` runtime Lua, portable content under common and translations under `common/media/lua/shared/Translate/<LANG>/*.json`; compiler `build.py` currently targets `common/media/translation/<LANG>/Conversation/Semantic/` | Verify actual bootstrap/installed layout and migrate only under a separate approved packaging fix, not during artifact-parity S0A |

## Findings and work classification

**Confirmed architecture gap:** two peer-level tool directories and build ownership split. User's desired CodeBuilder is an internal reusable subsystem in Semantic Lab. **Confirmed usability gap:** dataset/definition selection by external JSON picker rather than searchable in-app dataset library and synchronized reusable block/code authoring. **Not established:** duplicate parsing engines or a separately launched compiler GUI; do not claim those exist.

**Not yet implemented:** embedded CodeBuilder, one canonical writer/configuration/authoring source-of-truth, dataset browse/edit GUI, typed semantic block composition, synchronized code editor and fully end-to-end in-app generation.

**Historical acceptance:** prior `PROGRESS.md` archived verbatim in `HISTORY_C0_C6_20261019.md`; current goal opens an additional productization phase. **New phase test state:** no new source edits, compiler artifact parity tests, GUI clickthrough or worker regressions executed by this docs change.

## Required developer approach

Read `SEMANTIC_STUDIO_CONSOLIDATION.md`. Start with S0A no-behavior-change migration; avoid a bulk folder move that reflows translations/normalization, breaks CLI consumers or overwrites manually authored definitions. Then unify authoring service before designing actual dataset explorer/semantic block composition. No native PZ or Workshop work by Codex.

## Source-backed product audit — 2026-10-19

At remote 36f0beb2dc8a280094307700d601adc60c93d07b: service.py validates selected block IDs then previews/generates unchanged original dataset sources, rather than instantiated typed connected block definitions. Flow editor set_catalog lists FlowRegistry flows only; INSULT is a real SocialCatalog/Policy/Actions/Response route but is not a registered flow there. WordNet JSON pins FETCH/FOLLOW extraction and source hashes; actual runtime aliases are generated Lua and loaded into PsychopatzCore, without PZ runtime WordNet URL or ZIP. MASSIVE/SGD-shaped adapter tests do not prove broad approved actual corpus generation. Generic ActionRejected may explain user's shown insult response when social transport unavailable; it is a hypothesis pending R0A real worker trace. 203 Python pass and four Lua smoke failures are previously recorded, not rerun in this docs-only update. See SEMANTIC_STUDIO_RECOVERY.md for acceptance.
