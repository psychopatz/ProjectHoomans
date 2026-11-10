# Core Semantic Harness Migration Progress

## Status

Active. Phase 0 baseline/ownership freeze is complete.

## Verified current truth

- The goal is multi-repository: Project Hoomans, PsychopatzCore, and Dynamic Trading.
- All repositories are on `main` and already contain unrelated or prior dirty changes.
- Project Hoomans still owns the large executable Semantic Lab under `tools/semantic_harness`, including packaging, launcher, UI, CodeBuilder, tests, and provider-specific Lua.
- PsychopatzCore currently owns only a partial provider-neutral harness kernel and does not yet package the complete harness.
- Dynamic Trading still has a provider package under `tools/semantic_harness`, even though it is not a complete duplicate harness.
- Existing Core bridge modules and adopter launchers are transitional and are not acceptable final architecture.
- Exact repository HEADs, branch names, dirty-entry counts, worktree counts, and harness inventories are recorded in `BASELINE.md`.

## Evidence

Static audit and targeted source inspection completed before this goal was created. Existing focused tests were recorded in the prior audit, but the post-cutover matrix has not been rerun.

## Immediate Next Chunk

Add the Core package/entrypoint scaffold without changing unrelated runtime behavior, then begin provider-neutral tooling extraction.

## Not yet verified

- Complete Core package installation and standalone launch.
- Provider extraction and profile independence.
- Shared identity/suggestion/radio ownership after cutover.
- Absence of both adopter harness directories.
