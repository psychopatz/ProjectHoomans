# Progress — Semantic Harness UI Runtime Parity

Status: implementation complete for the developer-side harness boundary.

## Recovered and migrated

- Restored the full Core-owned Semantic Lab composition from the old working
  implementation: Simulation, Quality Sweep, Studio, Log, World Browser,
  nested authoring/inspection panes, conversation/workbench controls,
  semantic trace, replay/regression controls, and layout persistence.
- Moved the full Python UI, Studio, inspection, testing, CodeBuilder,
  fixtures, and Core-facing runtime support into
  `psychopatzCore/tools/semantic_harness/`.
- Removed the duplicate provider-side `ProjectHoomans/tools/providers/pnc/lab`
  and `.../codebuilder` trees. PNC retains only provider adapters, production
  Lua worker modules, provider fixtures/content policy, and provider tests.
- Updated PNC tests and the provider manifest to consume Core-owned modules and
  the Core Conversation manifest. Core CodeBuilder now resolves its canonical
  source even when the selected provider repository is Project Hoomans.
- Made the GUI title and worker selection provider-neutral; `run_harness.sh`
  remains the single launcher and opens the GUI with no arguments.

## Verification evidence

- Core compileall: pass.
- Core harness tests: 56 pass.
- Migrated PNC CodeBuilder/UI boundary tests: 14 pass, 3 intentional skips.
- `core`, `dtabstract`, `dthoomans`, `pnc`, and `pnc-with-dthoomans` selection
  and headless ping checks: pass.
- PNC semantic input `what is your name`: accepted as identity question,
  produced semantic suggestions, and preserved the unknown identity state.
- Fresh bare Core GUI: window `Semantic Lab — core`, full tabbed UI, Lua worker
  ready.
- Fresh PNC GUI: window `Semantic Lab — pnc`, full tabbed UI, provider Lua
  worker ready.
- Fresh DTAbstract GUI: window `Semantic Lab — dtabstract`, Core worker ready.

## Known boundary

The PNC production runtime and Lua worker remain provider-owned by design; they
are not a second harness. Generic GUI, lifecycle, CodeBuilder, inspection,
testing, fixtures, provider discovery, and launcher ownership are Core-only.
Native Project Zomboid runtime validation remains user-owned and was not
launched.

Unrelated pre-existing dirty files in Project Hoomans, Core, and Dynamic
Trading were preserved.
