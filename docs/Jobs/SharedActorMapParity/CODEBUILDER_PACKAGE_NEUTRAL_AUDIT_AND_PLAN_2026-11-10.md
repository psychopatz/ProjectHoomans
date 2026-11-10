# Semantic CodeBuilder package-neutral audit and plan

Date: 2026-11-10
Scope: Project Hoomans Semantic Harness CodeBuilder, PsychopatzCore generated
semantic assets, DTCommon generated semantic assets, and the authoring/preview
paths that consume them.

## Audit conclusion

The CodeBuilder is not yet package-neutral. It has a partial Core routing seam,
but it is still a Project-Hoomans-centered compiler and writer. Adding
`DTCommon` as an owner today would either route it into the Project Hoomans
package or generate a registry that cannot be consumed independently.

The correct migration is to separate three contracts that are currently mixed:

1. shard ownership — which package owns the generated data module;
2. registry ownership — which package loads and exposes a generated aggregate;
3. repository/package configuration — where modules, translations, and
   manifests are written.

The runtime semantic engine remains Core-owned. Generated artifacts are data
and explicit package adapters; they must not become a second parser, router, or
conversation implementation in DTCommon or Project Hoomans.

## Evidence baseline

- The focused CodeBuilder/compiler baseline was **18/18** using the available
  `unittest` runner.
- `pytest` is not installed in this environment, so it was not used as a
  verification source.
- The architecture scan reports Project Hoomans production health **80.2/100**,
  with Semantics health **52.6/100** and pressure **100.0**, and Conversation
  health **60.9/100** and pressure **87.6**. These scores identify the area for
  bounded migration; they do not replace the source-level findings below.
- Codebase Memory coverage for the cited CodeBuilder files is metadata-matched
  with no recorded gaps. This remains a best-effort signal; the source reads
  below are authoritative for this audit.

## Findings

### 1. Unknown owners silently become Project Hoomans

`generation_ownership.py:30-35` maps only Core aliases explicitly and returns
`ProjectHoomans` for every other value. `document_owner()` and `source_owner()`
inherit that behavior. A future `DTCommon` source owner would therefore be
silently misclassified instead of rejected.

This is the highest-risk correctness defect because a successful build could
write valid-looking Lua into the wrong mod.

### 2. Only Core and Hoomans have package descriptors

`generation_ownership.py:9-27` hardcodes two owners, two module prefixes, two
Lua roots, and two translation roots. `owner_repository()` only has a Core
special case; all non-Core output resolves to the Project Hoomans repository.
There is no explicit DynamicTrading/DTCommon repository mapping.

The Core fallback also infers a sibling checkout at `base.parent /
psychopatzCore` when no explicit path or environment variable is supplied.
That is acceptable as a compatibility fallback for Core only, but it cannot be
the general repository-resolution mechanism for optional adopters.

### 3. Module routing is reverse-inferred from the generated prefix

`module_owner()` recognizes the Core prefix and treats every other generated
module as Hoomans. This makes routing depend on string shape rather than the
compiled owner report. Adding a third prefix would require another special
case and would still leave unknown modules unsafe.

The compiler already has per-report source ownership at
`conversation_compiler.py:1001-1011` and routes modules at
`conversation_compiler.py:1500-1523`; the missing piece is using an explicit
package descriptor at those boundaries.

### 4. The compiler prefix and schema remain PNC-specific

`conversation_compiler.py:44-55` defines PNC conversation schemas and a fixed
Project Hoomans runtime path. `render_conversation_runtime_plan()` at
`conversation_compiler.py:1381-1523` always starts from
`PNC/Semantics/Generated/Conversation` and only rewrites the path after
rendering.

This means the compiler can physically move a Core module after generation,
but it does not understand a DTCommon-owned generated package as a first-class
target.

### 5. Registry generation is one-sided

`build.py:211-301` writes all aggregate artifacts to Project Hoomans:

- `PNC/.../Registry.lua`;
- `PNC/.../Manifest.lua`;
- the static suggestions module;
- all generated conversation translations and the translation manifest.

Individual Core-owned modules may be written into Core, but the only aggregate
registry still lives under PNC and requires those Core modules from the
Hoomans-side registry. Core and DTCommon receive no package-local registry or
manifest contract.

This is the current split-system risk: physical data ownership and runtime
registration ownership are not represented separately.

### 6. Translation output is always Project Hoomans-owned

`conversation_translation_bundles()` aggregates translations without an owner
partition. `build.py:281-299` then writes every bundle beneath
`Contents/mods/ProjectHoomans/common/media/translation`.

The `translation_root()` helper exists in `generation_ownership.py`, but the
conversation writer does not use it. A DTCommon source would therefore produce
translations in the wrong package even if its Lua shard were routed correctly.

### 7. Capability discovery only scans Project Hoomans

`semantic_definition_compiler.py:65-75` scans only
`Contents/mods/ProjectHoomans/*/media/lua/**/PNC_Semantic*.lua`.

DTCommon capabilities such as `DT.trade` are outside that search
root. A package-neutral semantic flow compiler cannot validate DT capabilities
through the current discovery function, and the default capability set is also
PNC-specific (`semantic_definition_compiler.py:44-51`).

The fix should make capability catalogs an explicit package input, with source
scanning retained only as an adopter-specific adapter. The compiler must not
guess capability ownership from one mod's filename convention.

### 8. Semantic definition ownership has a Project Hoomans default

`semantic_definition_compiler.py:238-245` defaults a flow owner to
`ProjectHoomans`, and `compile_semantic_definitions()` validates only that the
owner is text. This allows an omitted or misspelled owner to pass through until
the later routing fallback sends it to Hoomans.

Owner normalization and validation must happen once at the package boundary,
with an explicit manifest default for legacy Hoomans shards and an error for
unknown owners.

### 9. Authoring previews still describe all output as Hoomans output

`interaction_generation.py:233-251` calls the aggregate artifacts
`hoomans_artifacts` and hardcodes the Hoomans translation root. The service
reports generated content modules as
`PNC/Semantics/Generated/Conversation/...` at `service.py:425-462` and builds
structural diffs against the Hoomans shared root at `service.py:860-885`.

The lower-level writer has partial Core routing, but the editor/preview
contract does not expose the owning package. This will make a successful
DTCommon edit look like a Hoomans edit in the UI and can produce incomplete
approval/write sets.

### 10. Current tests cover the partial seam, not the target topology

`test_generation_ownership.py` proves Core and Hoomans module routing, but it
does not cover:

- DTCommon owner normalization and repository resolution;
- unknown-owner rejection;
- package-local registry and manifest generation;
- package-local translation manifests;
- capability discovery across optional packages;
- Project Hoomans disabled with DTAbstract/DTCommon still buildable;
- DTCommon disabled with Project Hoomans/Core still buildable.

The existing 18-test baseline should remain green while adding these matrix
tests.

## Target contract

### Package descriptor

Introduce one data-driven descriptor per supported package. Each descriptor
must contain:

- canonical owner ID and accepted aliases;
- explicit repository path input and environment key;
- packaged shared Lua root;
- generated module prefix;
- aggregate registry module and Lua namespace;
- translation root and translation manifest location;
- capability catalog inputs;
- whether the package is a producer, an aggregate consumer, or both.

The initial descriptors are:

| Package | Generated Lua root | Generated module prefix | Translation root |
| --- | --- | --- | --- |
| PsychopatzCore | `PsychopatzCore/common/media/lua/shared` | `PsychopatzCore/Semantics/Generated/Conversation` | `PsychopatzCore/common/media/translation` |
| ProjectHoomans | `ProjectHoomans/common/media/lua/shared` | `PNC/Semantics/Generated/Conversation` | `ProjectHoomans/common/media/translation` |
| DTCommon | `DTCommon/common/media/lua/shared` | `DTCommon/Semantics/Generated/Conversation` | `DTCommon/common/media/translation` |

The DTCommon descriptor must be supplied explicitly by the DynamicTrading
checkout path. It must not be inferred by assuming a sibling directory.

### Manifest ownership

Extend the manifest contract with an explicit `defaultOwner` and an explicit
aggregate `registryOwner`. Existing Project Hoomans shards that omit a source
owner use the manifest's `defaultOwner=ProjectHoomans`; a DTCommon manifest
uses `defaultOwner=DTCommon`.

Shard-level `source.owner` continues to override the default. Any owner not in
the descriptor catalog is a hard compiler error. The compiled model and every
location/report must retain both `shardOwner` and `registryOwner` so physical
and aggregate ownership cannot be confused.

### Generated registry contract

The registry renderer must receive a package descriptor rather than emit PNC
globals unconditionally. A generated aggregate must declare its owner,
schema, fingerprint, loaded modules, and source ownership in a data-only
manifest.

For the compatibility phase, Project Hoomans may continue to aggregate
Core-owned modules in its existing PNC registry. That relationship must be
explicit in the manifest and report; it must not be implemented by treating
all non-Core modules as Hoomans. DTCommon receives its own registry artifact
and does not load a Project Hoomans registry.

The runtime consumer migration can then register generated data with the
Core semantic registry. The generated registry is an adapter/data catalog,
not a second semantic engine.

## Implementation plan

### Phase 0 — freeze the contract and add rejection tests

1. Add the descriptor shape and canonical owner aliases.
2. Make `normalize_owner()` reject unknown non-empty owners and make missing
   owners resolve only through an explicit manifest default.
3. Add tests for Core, Project Hoomans, DTCommon, unknown owners, and missing
   explicit DTCommon repository configuration.
4. Record the existing 18/18 baseline and do not regenerate production output
   during this phase.

Gate: a synthetic DTCommon shard cannot silently appear under PNC.

#### Phase 0 implementation status — 2026-11-10

Phase 0 is implemented in the CodeBuilder authoring layer:

- `PackageDescriptor` now defines Core, Project Hoomans, and DTCommon aliases,
  generated Lua roots, conversation prefixes, translation roots, registry
  module/namespace metadata, and repository configuration keys.
- Owner normalization is fail-closed. Missing owners are accepted only when a
  caller supplies an explicit default; unknown owners raise
  `OwnerConfigurationError` instead of becoming Project Hoomans.
- DTCommon repository resolution requires an explicit repository argument or
  `PZ_TEST_DYNAMIC_TRADING_REPOSITORY`; it is never inferred as a sibling
  checkout.
- The active Hoomans Conversation manifest now records explicit
  `defaultOwner=ProjectHoomans` and `registryOwner=ProjectHoomans`, preserving
  legacy owner omissions through a visible manifest contract.
- Focused CodeBuilder/compiler verification is now **22/22**. The test suite
  covers the three-package routing fixture, unknown-owner rejection, missing
  DTCommon repository rejection, and invalid manifest ownership.

This phase intentionally does not generate a DTCommon source pack or alter
the current production registry/translation writer. Those are Phase 1/2
changes and remain gated on descriptor-driven writer and aggregate ownership
work.

#### Phase 1 implementation status — 2026-11-10

The first Phase 1 routing slice is implemented:

- `_write_routed_modules()` now delegates every generated module to
  `module_target()` instead of maintaining a Core/Project Hoomans root map.
- Conversation output cleanup, aggregate registry/manifest placement, and
  translation placement resolve through the manifest `registryOwner` and its
  package descriptor. The current Project Hoomans manifest remains byte/path
  compatible at its existing destination.
- `--dynamic-trading-repository` is available on the CodeBuilder build CLI and
  the Semantic Lab CLI. The authoring service passes that optional repository
  through previews and approved writes, including generated-path reports.
- A synthetic DTCommon writer fixture proves a DTCommon module is written to
  the DynamicTrading checkout rather than Project Hoomans.
- Duplicate UI preview artifacts are collapsed by `(repository, relative path)`
  so the generated aggregate UI artifact remains the authoritative preview
  entry.

Phase 1 still does not parameterize the compiler's PNC module prefix or render
a DTCommon-owned registry namespace. Those are the Phase 2 aggregate/compiler
changes; accepting DTCommon source shards before that gate would still be
premature.

### Phase 1 — route modules and repositories through descriptors

1. Replace `module_owner()` reverse inference with report/descriptor routing.
2. Add explicit `dynamic_trading_repository`/DTCommon configuration to the
   CLI and authoring service.
3. Make `module_target()`, shared roots, and translation roots descriptor
   driven.
4. Preserve the existing Core fallback only behind the Core descriptor.

Gate: a temporary three-repository fixture receives each module in its own
package, with no stale cross-package path.

### Phase 2 — make compiler and registry generation package-aware

1. Parameterize the generated prefix in the conversation compiler and remove
   hardcoded PNC prefixes from runtime-plan and discovery-index creation.
2. Partition reports by shard owner while retaining an explicit aggregate
   registry owner.
3. Render package-local registry/manifest modules with descriptor namespace
   and package-specific require paths.
4. Keep the current Project Hoomans registry output byte-compatible where the
   compatibility gate requires it, except for new owner metadata.

Gate: Core, Hoomans, and DTCommon registry fixtures load only their declared
modules and report the correct owner/fingerprint.

### Phase 3 — route translations and capability catalogs

1. Partition translation bundles by owning package and use each descriptor's
   translation root.
2. Generate one translation manifest per package without overwriting another
   package's manifest.
3. Replace the Hoomans-only capability scan with descriptor-provided catalog
   inputs; include DTCommon's declared capability IDs.
4. Remove PNC-specific defaults from the generic semantic compiler while
   retaining a Project Hoomans adapter for existing sources.

Gate: DTCommon translation and `dynamictrading.*` capability fixtures compile
without Project Hoomans present.

### Phase 4 — migrate authoring and preview consumers

1. Thread package descriptors through `SemanticLabAuthoringService` and
   `SemanticInteractionAuthoring`.
2. Replace `hoomans_artifacts`, hardcoded generated-module labels, and fixed
   Hoomans diff roots with owner-tagged artifact records.
3. Make approval/write reports include repository, owner, relative path,
   fingerprint, and generated module.
4. Add DTCommon preview-only and approved-write tests using a temporary
   repository fixture.

Gate: the editor can preview a DTCommon change without proposing a Hoomans
write, and a Hoomans edit does not write Core/DTCommon artifacts.

### Phase 5 — generated DTCommon semantic pack and consumer migration

1. Add a DTCommon-owned manifest/source set for concepts, patterns, dialogue
   blocks, translations, and capability/action metadata.
2. Generate data-only DTCommon artifacts and bind action effects through the
   existing DTCommon runtime adapter.
3. Register generated DTCommon data through Core's semantic pack/registry
   contract; do not introduce a DTCommon parser or conversation service.
4. Keep DTHoomans and DTAbstract presence/access behavior unchanged.

Gate: DTAbstract-only, DTHoomans-only, Project-Hoomans-only, and combined
loads all either register their available packs or degrade cleanly without
missing-module errors.

### Phase 6 — remove compatibility routing

After all package matrix gates pass:

1. remove the implicit non-Core-to-Hoomans fallback;
2. migrate PNC consumers away from generated compatibility assumptions;
3. remove obsolete duplicate/generated registry paths;
4. update docs and generated-output inventories;
5. run the full semantic harness and relevant DynamicTrading/Core suites.

No legacy loader should remain as a second active path. Compatibility during
the migration must be an explicit adapter with a removal gate, not another
owner-specific implementation.

## Verification matrix

- Existing focused CodeBuilder/compiler baseline: **18/18**.
- Descriptor unit tests: three owners, aliases, unknown/missing owner, and
  explicit repository resolution.
- Compiler fixtures: one owner, mixed shard owners, and wrong-owner rejection.
- Writer fixtures: three temporary repositories, no stale generated paths,
  package-local registries/manifests/translations.
- Capability fixtures: Core-only, Hoomans-only, DTCommon-only, and combined.
- Authoring fixtures: preview/write paths report the correct owner and target.
- Runtime regression: Project Hoomans semantic tests, Core semantic tests, and
  DynamicTrading conversation/trader suites.
- Native Project Zomboid load remains a later user-owned acceptance gate; this
  audit does not launch the game or publish Workshop content.

## Phase 2 implementation status — 2026-11-10

Phase 2 compiler/registry work is implemented and verified:

- Runtime-plan and discovery-index prefixes now come from the manifest's
  registry owner descriptor instead of a PNC-only prefix.
- Generated reports retain `shardOwner`, `registryOwner`, and the routed module
  path. Registry and manifest renderers emit descriptor-owned namespace,
  module, and owner metadata.
- Behavior and beat records now use their shard's canonical owner, so a
  DTCommon shard cannot emit Hoomans-owned record metadata while routing to
  DTCommon. Explicit record owners are still validated against the descriptor
  catalog.
- Semantic Lab content preview labels are descriptor-driven for the source
  shard, removing another PNC-only generated-module assumption.
- A temporary DTCommon registry fixture writes the package-local registry and
  manifest into the DynamicTrading checkout and does not create a Hoomans
  registry. The checked-in Hoomans Registry/Manifest artifacts were regenerated
  from the canonical compiler.
- Verification: affected CodeBuilder/authoring tests **39/39**, ownership plus
  continuation tests **19/19**, context-health tests **8/8**, semantic
  definition tests **2/2**, content-authority tests **5/5**, C7F precision
  tests **2/2**, and F4/observatory/pragmatic tests **9/9**. Python compile,
  `git diff --check`, and the architecture-audit diff passed; the architecture
  score remained **80.2/100** with **0 introduced findings**.

The remaining package-neutral boundary is Phase 3: route translation bundles
and manifests by owner, replace Hoomans-only capability discovery with
descriptor-provided catalogs, and add package matrix fixtures before enabling
a real DTCommon source pack.

## Phase 3 implementation status — 2026-11-10

The Phase 3 compiler slice is implemented; checked-in artifact regeneration is
waiting for a safe non-runtime window because Project Zomboid is currently
running and its media watcher must not observe in-place generated-file writes.

- Package descriptors now declare translation-manifest locations and
  capability catalog inputs. DTCommon declares `DT.trade` and its
  semantic-pack scan patterns; Hoomans retains its compatibility scan pattern.
- Capability discovery accepts explicit optional package repositories and
  merges descriptor-declared IDs with discovered IDs. Conversation shards,
  dataset previews, and interaction previews receive the same package map.
- Translation bundles now have an owner-partitioned API. The writer emits a
  Conversation translation directory and manifest per owning package; the
  existing flat bundle API remains for compatibility.
- Temporary package-neutral generation and preview verification passes with
  **196 generated artifacts unchanged** after a temp write. Focused ownership,
  compiler, and capability tests pass **51/51**.

After Project Zomboid stops, regenerate the checked-in Conversation output,
rerun the modular authoring preview suite, then run the Hoomans/Core/Dynamic
Trading package matrix. The generated semantic engine remains Core-owned;
DTCommon and Hoomans remain data/adapters with no second parser or runtime
conversation implementation.

## Current next chunk

Stop Project Zomboid, regenerate the checked-in Conversation output, rerun the
modular authoring preview suite, and execute the Hoomans/Core/Dynamic Trading
package matrix. Then continue with the DTCommon semantic source-pack fixture.
