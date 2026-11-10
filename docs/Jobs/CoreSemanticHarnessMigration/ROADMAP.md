# Core Semantic Harness Migration

## Objective

Make PsychopatzCore the sole owner and distributor of the Semantic Harness and the provider-neutral semantic foundations used by Project Hoomans/PNC, Dynamic Trading/DT, and future mods.

The final state has no `tools/semantic_harness` directory in Project Hoomans or Dynamic Trading. Product-specific adapters and content remain in their owning repositories, but outside the harness namespace.

## Scope

- Core-owned harness: worker lifecycle, protocol, runtime/session tools, CodeBuilder, inspection, UI/studio, testing, Kahlua verification, generic fixtures, and generic Lua worker.
- Core-owned semantic foundations: identity knowledge, deterministic nickname derivation, semantic suggestions, world-discovery events, radio contracts, and shared conversation metadata.
- PNC provider: Project Hoomans-specific Lua/Python adapters, fixtures, content, and policy under an explicit provider package.
- DT provider: DTCommon, DTAbstract, DTHoomans adapters, fixtures, content, and policy under an explicit provider package.
- Explicit profiles: `core`, `pnc`, `dtabstract`, `dthoomans`, and `combined`.

## Phases and gates

### Phase 0 — Baseline and ownership freeze

Record the three repository HEADs, dirty work fingerprints, current generated outputs, import/path inventory, and profile/test baselines. Supersede the incremental migration assumptions in the Core migration roadmap. No unrelated dirty work may be staged.

Gate: current ownership map and preservation boundary are recorded.

### Phase 1 — Core harness package

Complete `psychopatzCore/tools/semantic_harness` by moving provider-neutral Hoomans tooling into Core. Add Core packaging and the single `semantic-lab` entrypoint. Preserve one implementation of each worker, runtime, CodeBuilder, inspection, UI, and test service.

Gate: Core-only harness starts and runs its focused Python/Kahlua tests without either adopter repository.

### Phase 2 — Provider extraction

Move PNC-specific harness code to `ProjectHoomans/tools/providers/pnc/`. Move DT-specific code from `DynamicTrading/tools/semantic_harness/` to `DynamicTrading/tools/providers/dt/`. Provider registrars and manifests are explicit; Core does not import adopters by name.

Gate: PNC and DT profiles resolve through Core while neither adopter contains a harness package.

### Phase 3 — Shared semantic foundations

Move or complete Core-owned identity, nickname, knowledge visibility, static suggestion, world-discovery, and radio contracts. Keep PNC and DT facts/content in provider packages. Ensure the identity display contract remains progressive and formats a fully known identity as `Firstname Surname (Nickname)`.

Gate: Core, PNC, DTAbstract, DTHoomans, and combined profiles use the same semantic contracts without duplicated registries or state owners.

### Phase 4 — Caller and artifact cutover

Update launchers, tests, semantic review tools, source manifests, generated outputs, Lua package paths, and profile loading. Remove Hoomans bridge modules and harness-only packaging once all callers use Core.

Gate: deterministic generated artifacts are reproduced from Core and all provider tests use the Core harness.

### Phase 5 — Hard deletion and verification

Delete both adopter `tools/semantic_harness` trees, obsolete launchers/package metadata, compatibility bridges, and stale import paths. Run the complete profile matrix and static deletion scans.

Gate: no adopter harness directory, no duplicate harness package, no bridge, no cross-provider dependency, no DTAbstract dependency on PNC, and no PNC dependency on DT.

## Completion criteria

The developer-side migration is complete only when all phases pass, exact phase-owned changes are locally committed in participant repositories before the primary repository, and the final Core/PNC/DT profile and regression matrix is green. No push, Workshop publication, or native Project Zomboid session is part of this goal.
