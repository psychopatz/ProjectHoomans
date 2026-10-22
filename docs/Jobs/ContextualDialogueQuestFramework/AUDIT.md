# Current architecture audit — Semantic Lab vs standalone semantic compiler

**Remote source examined 2026-10-19:** `71162cb4f78cc4cd408a4a145486d5ebadc943c1` on `docs/contextual-dialogue-quest-framework-20261018`, PR #4 open/unmerged. GitHub source + user GUI screenshot, **not** a local worktree or fresh test rerun.

| Concern | Source evidence | Result |
| --- | --- | --- |
| GUI application | `tools/semantic_harness/app.py`, `ui/shell.py`, `ui/flow_editor/`, `run_harness.sh` | One actual Tk application, persistent production Lua worker; compiler is NOT a second GUI |
| Embedded CodeBuilder | `tools/semantic_harness/codebuilder/{lexicon_compiler,dialogue_dataset,semantic_definition_compiler}.py`, `build.py`, `sources/*.json`, tests, README | One internal headless compiler/build subsystem under Semantic Harness; no peer-level package |
| Canonical imports | Harness callers import concrete CodeBuilder modules directly | No legacy compiler package or forwarding import layer remains |
| Duplicated orchestration | `codebuilder/authoring.py` and `codebuilder/build.py` own distinct authoring/build contracts; the Semantic Lab service routes callers to them | Remaining service consolidation opportunity; NOT proof that NLP compiler algorithms are duplicated |
| UI authoring | `ui/flow_editor/` and `studio/` expose compile/generate/review workflows and bounded reports | Real helper workflows, not yet an integrated dataset/block/code studio |
| Accepted runtime | Prior `PROGRESS.md` at this SHA reports G0–G3/C0–C6 Lua + compiler + X11 gates and READY FOR USER LIVE TEST | Preserve as historical previous-scope success, don't claim new UI requirements met |
| Asset layout | Root AGENTS.md: `42.20/media/` runtime Lua, portable content under common and translations under `common/media/lua/shared/Translate/<LANG>/*.json`; compiler `build.py` currently targets `common/media/translation/<LANG>/Conversation/Semantic/` | Verify actual bootstrap/installed layout and migrate only under a separate approved packaging fix, not during artifact-parity S0A |

## Findings and work classification

**Resolved architecture gap:** the former peer-level compiler directory and build-ownership split were consolidated. CodeBuilder is now an internal reusable subsystem in Semantic Lab. **Remaining usability gap:** dataset/definition selection still needs to become a searchable in-app dataset library with synchronized reusable block/code authoring. **Not established:** duplicate parsing engines or a separately launched compiler GUI; do not claim those exist.

**Not yet implemented:** the full dataset browse/edit GUI, typed semantic block composition, synchronized code editor and fully end-to-end in-app generation. The embedded CodeBuilder and direct canonical writer/module ownership are implemented.

**Historical acceptance:** prior `PROGRESS.md` archived verbatim in `HISTORY_C0_C6_20261019.md`; current goal opens an additional productization phase. **New phase test state:** the S0 migration-focused Python suite and build entry points were run locally; full byte-parity and GUI clickthrough worker regressions remain separate acceptance work.

## Required developer approach

Read `SEMANTIC_STUDIO_CONSOLIDATION.md`. S0A is complete; continue with the authoring service before designing the actual dataset explorer/semantic block composition. No native PZ or Workshop work by Codex.

## Source-backed product audit — 2026-10-19

At remote 36f0beb2dc8a280094307700d601adc60c93d07b: service.py validates selected block IDs then previews/generates unchanged original dataset sources, rather than instantiated typed connected block definitions. Flow editor set_catalog lists FlowRegistry flows only; INSULT is a real SocialCatalog/Policy/Actions/Response route but is not a registered flow there. WordNet JSON pins FETCH/FOLLOW extraction and source hashes; actual runtime aliases are generated Lua and loaded into PsychopatzCore, without PZ runtime WordNet URL or ZIP. MASSIVE/SGD-shaped adapter tests do not prove broad approved actual corpus generation. Generic ActionRejected may explain user's shown insult response when social transport unavailable; it is a hypothesis pending R0A real worker trace. 203 Python pass and four Lua smoke failures are previously recorded, not rerun in this docs-only update. See SEMANTIC_STUDIO_RECOVERY.md for acceptance.
