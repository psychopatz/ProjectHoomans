# Progress — Modular Semantic Harness and Mod Manager

**Status:** COMPLETE — developer-side acceptance complete.
**Primary repository:** ProjectHoomans.
**Participant repositories:** psychopatzCore, DynamicTrading.
**Branch policy:** existing `main` branches; no new branch.

## Current truth

- PsychopatzCore owns the manifest-driven `ModManager`, activation-plan
  schema, preset catalog, route resolution, diagnostics, CLI, and generic Lua
  worker protocol.
- Project Hoomans and Dynamic Trading declare provider capabilities,
  dependencies, materialization modes, Lua modules, runtime metadata, and
  environment templates in v2 manifests.
- The old PNC generic runtime configuration and Core hardcoded repository
  layout helper were removed; PNC now consumes Core's `HarnessConfig`.
- Core resolves custom selections using the highest materialization mode shared
  by all selected providers, so `--mods DTAbstract` selects `abstract`.
- Provider-specific environment aliases are manifest data; Core resolves only
  generic templates and does not branch on adopter IDs.
- Existing unrelated dirty files are present in all three repositories and
  must remain untouched.

## Implementation checkpoint

Core now owns the manifest-driven manager, activation plan, preset catalog,
route resolution, diagnostics, CLI, and generic Lua worker protocol. PNC and
Dynamic Trading v2 manifests declare provider capabilities, dependencies,
materialization modes, Lua modules, runtime metadata, and environment templates.
The PNC generic runtime configuration and Core repository-layout helper were
removed; PNC consumes Core's `HarnessConfig`. Custom selections choose the
highest materialization mode shared by all selected providers.

## Next chunk

No implementation work remains for this goal. A future goal may optimize the
slow aggregate PNC integration collection independently.

## Validation ledger

| Evidence | Status |
| --- | --- |
| Repository status/branch/worktree inspection | CODE_VERIFIED |
| Current provider tree and manifest inventory | CODE_VERIFIED |
| Focused baseline and migration tests | CODE_VERIFIED |
| Core manifest/resolver implementation | CODE_VERIFIED |
| Selection matrix execution | CODE_VERIFIED |
| Installed/wheel launch | CODE_VERIFIED |
| Full PNC aggregate discovery | BOUNDED_SLOW — collection exceeded 120s at `test_automatic_flow_generation`; that module passes individually under a 60s bound |
| Architecture audit and Codebase Memory refresh | CODE_VERIFIED |
